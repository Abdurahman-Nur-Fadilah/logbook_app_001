import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';

  LogController() { loadFromDisk(); }

  void addLog(String title, String desc) {
    final newLog = LogModel(title: title, description: desc, date: DateTime.now().toString());
    logsNotifier.value = [...logsNotifier.value, newLog];
    saveToDisk();
  }

  void updateLog(int index, String title, String desc) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = LogModel(title: title, description: desc, date: DateTime.now().toString());
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

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
    final String encodedData = serializeLogs();  // Gunakan fungsi baru
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      deserializeLogs(data);  // Gunakan fungsi baru
    }
  }
}
