// login_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_001/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscurePassword = true;
  bool _isLockedOut = false;
  int remainingSeconds = 0;
  Timer? _lockoutTimer;
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      remainingSeconds = 10; // Durasi lockout dalam detik
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          _isLockedOut = false;
          _controller.resetFailedAttempts();
          timer.cancel();
        }
      });
    });
  }

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Di sini kita kirimkan variabel 'user' ke parameter 'username' di CounterView
          builder: (context) => CounterView(username: user),
        ),
      );
    } else {
      if (_controller.isLockedOut()) {
      _startLockout(); // ← DIPANGGIL DI SINI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terlalu banyak percobaan gagal. Coba lagi dalam 10 detik.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login gagal! Percobaan ${_controller.failedAttempts}/3'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel(); // Cancel timer saat keluar halaman
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off
                ), 
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                }),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLockedOut ? null : _handleLogin,
              child: Text(
                _isLockedOut
                 ? "Locked Out (${remainingSeconds}s)" 
                : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
