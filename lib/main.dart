// main.dart
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Inisialisasi Hive
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');

  // Cek session tersimpan
  final session = await LoginController().loadSession();

  runApp(MyApp(savedSession: session));
}

class MyApp extends StatelessWidget {
  final Map<String, String>? savedSession;
  const MyApp({super.key, this.savedSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      // Kalau ada session tersimpan langsung ke LogView, kalau tidak ke Onboarding
      home: savedSession != null
          ? LogView(currentUser: savedSession!)
          : const OnboardingView(),
    );
  }
}