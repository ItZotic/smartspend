import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartspend/services/theme_service.dart';

// ✅ Screens (Fixed imports based on your screenshot)
import 'login.dart';
import 'register.dart';
import 'main_menu.dart'; // It's in the same folder as main.dart
import 'forgot_password.dart';

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
    final themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartSpend',

          // Connect Theme Service
          themeMode: themeService.themeMode,

          // Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF2979FF),
            scaffoldBackgroundColor: const Color(0xFFF3F8FC),
            useMaterial3: true,
          ),

          // Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF2979FF),
            scaffoldBackgroundColor: const Color(0xFF031229),
            useMaterial3: true,
          ),

          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/main_menu': (context) => const MainMenuScreen(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
          },
        );
      },
    );
  }
}
