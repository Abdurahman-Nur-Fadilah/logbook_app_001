// login_controller.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController {
  static const String _sessionKey = 'user_session';

  static const List<Map<String, String>> _users = [
    {
      'username': 'admin',
      'password': '123',
      'uid': 'uid_001',
      'role': 'Ketua',
      'teamId': 'MEKTRA_KLP_01',
    },
    {
      'username': 'user',
      'password': 'password',
      'uid': 'uid_002',
      'role': 'Anggota',
      'teamId': 'MEKTRA_KLP_01',
    },
    {
      'username': 'fadil',
      'password': 'gero',
      'uid': 'uid_003',
      'role': 'Anggota',
      'teamId': 'MEKTRA_KLP_01',
    },
    {
      'username': 'teamb',
      'password': '123',
      'uid': 'uid_004',
      'role': 'Anggota',
      'teamId': 'MEKTRA_KLP_02',
    },
  ];

  int _failedAttempts = 0;
  int get failedAttempts => _failedAttempts;

  /// Login dan return Map user jika berhasil, null jika gagal
  Map<String, String>? login(String username, String password) {
    final user = _users.where(
      (u) => u['username'] == username && u['password'] == password,
    ).firstOrNull;

    if (user != null) {
      _failedAttempts = 0;
      return user;
    } else {
      _failedAttempts++;
      return null;
    }
  }

  /// Simpan session user ke SharedPreferences
  Future<void> saveSession(Map<String, String> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user));
  }

  /// Load session user dari SharedPreferences
  Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_sessionKey);
    if (data == null) return null;
    return Map<String, String>.from(jsonDecode(data));
  }

  /// Hapus session (logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  void resetFailedAttempts() => _failedAttempts = 0;
  bool isLockedOut() => _failedAttempts >= 3;
}