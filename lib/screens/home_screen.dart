import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Home Screen', style: TextStyle(fontSize: 24)),
              ElevatedButton(
                onPressed: () => onNavigate('daily'),
                child: const Text('Go to Daily Records'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
