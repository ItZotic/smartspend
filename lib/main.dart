import 'package:flutter/material.dart';
import 'package:smartspend/login.dart';
import 'screen/login.dart';

void main() {
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
    );
  }
}
