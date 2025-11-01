import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Make sure these filenames are ALL lowercase
import 'login.dart';
import 'register.dart';
import 'main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSpend',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(), // ✅ class LoginScreen
        '/register': (context) =>
            const RegisterScreen(), // ✅ class RegisterScreen
        '/main_menu': (context) =>
            const MainMenuScreen(), // ✅ class MainMenuScreen
      },
    );
  }
}
