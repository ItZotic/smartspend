import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (!context.mounted) {
                return;
              }
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to SmartSpend!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
