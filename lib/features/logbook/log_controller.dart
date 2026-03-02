import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';
  String _searchQuery = '';

  static const List<String> categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

  Color getColorForCategory(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.yellow.shade200;
      case 'Pribadi':
        return Colors.green.shade200;
      case 'Urgent':
        return Colors.red.shade200;
      default:
        return Colors.white;
    }
  }

  LogController() { loadFromDisk(); }

  void addLog(String title, String desc, String category) {
    final newLog = LogModel(title: title, description: desc, date: DateTime.now().toString(), category: category);
    logsNotifier.value = [...logsNotifier.value, newLog];
    _filterLogs();
    saveToDisk();
  }

  void updateLog(LogModel oldLog, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final index = currentLogs.indexOf(oldLog);
    if (index != -1) {
      currentLogs[index] = LogModel(title: title, description: desc, date: oldLog.date, category: category);
      logsNotifier.value = currentLogs;
      _filterLogs();
      saveToDisk();
    }
  }

  void removeLog(LogModel log) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.remove(log);
    logsNotifier.value = currentLogs;
    _filterLogs();
    saveToDisk();
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

  // Fungsi baru: Mengubah List<LogModel> menjadi JSON String (serialization)
  String serializeLogs() {
    return jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
  }

  // Fungsi baru: Mengubah JSON String menjadi List<LogModel> (deserialization)
  void deserializeLogs(String jsonString) {
    final List decoded = jsonDecode(jsonString);
    logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = serializeLogs(); 
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      deserializeLogs(data); 
    }
    _filterLogs();
  }
}
