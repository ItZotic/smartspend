import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:smartspend/firebase_options.dart';
import 'package:smartspend/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSpend',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginScreen(),
      routes: {
        '/main_menu': (context) => const MainMenuScreen(),
      },
    );
  }
}
