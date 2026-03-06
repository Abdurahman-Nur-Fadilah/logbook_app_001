import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);
  String _searchQuery = "";

  static const List<String> categories = ["Pekerjaan", "Pribadi", "Urgent"];

  Color getColorForCategory(String category) {
    switch (category) {
      case "Pekerjaan": return Colors.yellow.shade200;
      case "Pribadi": return Colors.green.shade200;
      case "Urgent": return Colors.red.shade200;
      default: return Colors.white;
    }
  }

  /// Format timestamp ke format lokal Indonesia
  String formatTimestamp(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return "Baru saja";
      if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
      if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";
      return DateFormat("d MMM yyyy", "id_ID").format(date);
    } catch (_) {
      return rawDate;
    }
  }

  LogController();

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );
    await MongoService().insertLog(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    _filterLogs();
  }

  Future<void> updateLog(LogModel oldLog, String title, String desc, String category) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: oldLog.date,
      category: category,
    );
    await MongoService().updateLog(updatedLog);
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final index = currentLogs.indexOf(oldLog);
    if (index != -1) {
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      _filterLogs();
    }
  }

  Future<void> removeLog(LogModel log) async {
    if (log.id == null) return;
    await MongoService().deleteLog(log.id!);
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.remove(log);
    logsNotifier.value = currentLogs;
    _filterLogs();
  }

  Future<void> loadFromCloud() async {
    final logs = await MongoService().getLogs();
    logsNotifier.value = logs;
    _filterLogs();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _filterLogs();
  }

  void _filterLogs() {
    if (_searchQuery.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value.where((log) =>
        log.title.toLowerCase().contains(_searchQuery) ||
        log.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }
  }

  bool get isSearchActive => _searchQuery.isNotEmpty;
}