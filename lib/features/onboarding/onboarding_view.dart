import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _counter = 0;

  // List gambar sesuai urutan
  final List<String> _images = [
    'assets/images/luvyu.jpeg',
    'assets/images/letmiting.jpeg',
    'assets/images/besokaja.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tampilkan gambar sesuai counter
            Image.asset(
              _images[_counter],
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 24),
            Text(
              'Slide ${_counter + 1} of 3',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counter++;
                  if (_counter >= 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  }
                });
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}