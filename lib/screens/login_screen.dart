import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onLogin,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Login'),
        ),
      ),
    );
  }
}
