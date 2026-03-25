import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  static const List<String> categories = ['Pribadi', 'Perusahaan', 'Urgent'];

  Color getColorForCategory(String category) {
    switch (category) {
      case 'Perusahaan': return Colors.yellow.shade200;
      case 'Urgent': return Colors.red.shade200;
      case 'Pribadi': return Colors.green.shade200;
      default: return Colors.white;
    }
  }

  LogController() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncPendingLogs();
      }
    });
  }

  String formatTimestamp(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  /// Sync hanya data yang belum tersync (isSynced == false)
  Future<void> _syncPendingLogs() async {
    final pending = _myBox.values.where((l) => !l.isSynced).toList();
    if (pending.isEmpty) return;

    for (final log in pending) {
      try {
        await MongoService().insertLog(log);

        // Update isSynced di Hive
        final keys = _myBox.keys.toList();
        final values = _myBox.values.toList();
        final idx = values.indexWhere((l) => l.id == log.id);
        if (idx != -1) await _myBox.put(keys[idx], log.copyWith(isSynced: true));

        await LogHelper.writeLog('SYNC: \${log.title} berhasil diupload ke Cloud', level: 2);
      } catch (e) {
        await LogHelper.writeLog('SYNC ERROR: \${log.title} gagal - \$e', level: 1);
      }
    }

    // Refresh notifier setelah sync
    logsNotifier.value = _myBox.values.toList();
  }

  /// LOAD: Offline-First
  Future<void> loadLogs() async {
    // Langkah 1: Tampilkan dari Hive (instan)
    logsNotifier.value = _myBox.values.toList();

    // Langkah 2: Sync dari Cloud (background)
    try {
      final cloudData = await MongoService().getLogs();

      // Ambil data pending lokal yang belum tersync
      final pendingLocal = _myBox.values.where((l) => !l.isSynced).toList();

      // Clear Hive dan isi dengan data cloud
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      // Tambahkan kembali data pending yang belum tersync
      for (final pending in pendingLocal) {
        final sudahAda = cloudData.any((c) => c.id == pending.id);
        if (!sudahAda) await _myBox.add(pending);
      }

      // Update notifier dengan gabungan cloud + pending lokal
      logsNotifier.value = _myBox.values.toList();

      await LogHelper.writeLog('SYNC: Data berhasil diperbarui dari Atlas', level: 2);
    } catch (e) {
      await LogHelper.writeLog('OFFLINE: Menggunakan data cache lokal', level: 2);
    }
  }

  /// ADD: Simpan ke Hive dulu (isSynced=false), lalu kirim ke Atlas
  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
    String category,
    bool isPublic,
  ) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      category: category,
      isPublic: isPublic,
      isSynced: false, // Belum tersync
    );

    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLog(newLog);

      // Update isSynced di Hive
      final keys = _myBox.keys.toList();
      final values = _myBox.values.toList();
      final idx = values.indexWhere((l) => l.id == newLog.id);
      if (idx != -1) await _myBox.put(keys[idx], newLog.copyWith(isSynced: true));

      // Update notifier
      final current = List<LogModel>.from(logsNotifier.value);
      final listIdx = current.indexWhere((l) => l.id == newLog.id);
      if (listIdx != -1) {
        current[listIdx] = newLog.copyWith(isSynced: true);
        logsNotifier.value = current;
      }

      await LogHelper.writeLog('SUCCESS: Data tersinkron ke Cloud', level: 2);
    } catch (e) {
      await LogHelper.writeLog('WARNING: Data tersimpan lokal, akan sinkron saat online', level: 1);
    }
  }

  /// UPDATE
  Future<void> updateLog(
    LogModel oldLog,
    String title,
    String desc,
    String category,
    bool isPublic,
  ) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: oldLog.date,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      category: category,
      isPublic: isPublic,
      isSynced: false,
    );

    final keys = _myBox.keys.toList();
    final values = _myBox.values.toList();
    final idx = values.indexWhere((l) => l.id == oldLog.id);
    if (idx != -1) await _myBox.put(keys[idx], updatedLog);

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final listIdx = currentLogs.indexWhere((l) => l.id == oldLog.id);
    if (listIdx != -1) {
      currentLogs[listIdx] = updatedLog;
      logsNotifier.value = currentLogs;
    }

    try {
      await MongoService().updateLog(updatedLog);

      // Update isSynced setelah berhasil
      final keys2 = _myBox.keys.toList();
      final values2 = _myBox.values.toList();
      final idx2 = values2.indexWhere((l) => l.id == updatedLog.id);
      if (idx2 != -1) await _myBox.put(keys2[idx2], updatedLog.copyWith(isSynced: true));

      await LogHelper.writeLog('SUCCESS: Update tersinkron ke Cloud', level: 2);
    } catch (e) {
      await LogHelper.writeLog('WARNING: Update tersimpan lokal, akan sinkron saat online', level: 1);
    }
  }

  /// DELETE
  Future<void> removeLog(LogModel log) async {
    if (log.id == null) return;

    final keys = _myBox.keys.toList();
    final values = _myBox.values.toList();
    final idx = values.indexWhere((l) => l.id == log.id);
    if (idx != -1) await _myBox.delete(keys[idx]);

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeWhere((l) => l.id == log.id);
    logsNotifier.value = currentLogs;

    try {
      await MongoService().deleteLog(log.id!);
      await LogHelper.writeLog('SUCCESS: Hapus tersinkron ke Cloud', level: 2);
    } catch (e) {
      await LogHelper.writeLog('WARNING: Hapus tersimpan lokal, akan sinkron saat online', level: 1);
    }
  }
}