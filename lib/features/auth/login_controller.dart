// login_controller.dart
class LoginController {
  // Data user lengkap dengan uid, role, dan teamId
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

  void resetFailedAttempts() => _failedAttempts = 0;
  bool isLockedOut() => _failedAttempts >= 3;
}