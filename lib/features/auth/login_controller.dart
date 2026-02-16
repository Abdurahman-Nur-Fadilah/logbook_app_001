// login_controller.dart
class LoginController {
  final Map<String, String> _users = {
    "admin": "123",
    "user": "password",
    "fadil": "gero",
  };

  int _failedAttempts = 0;

  int get failedAttempts => _failedAttempts;

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    if (_users.containsKey(username) && _users[username] == password) {
      _failedAttempts = 0; // Reset counter jika login berhasil
      return true;
    } else {
      _failedAttempts++; // Tambah counter jika login gagal
      return false;
    }
  }

  void resetFailedAttempts() {
    _failedAttempts = 0;
  }

  bool isLockedOut() {
    return _failedAttempts >= 3;
  }
}
