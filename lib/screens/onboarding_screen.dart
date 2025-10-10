import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const OnboardingScreen({
    super.key,
    required this.currentPage,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Onboarding Page ${currentPage + 1}',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentPage > 0)
                  TextButton(onPressed: onBack, child: const Text('Back')),
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: onNext, child: const Text('Next')),
                const SizedBox(width: 20),
                TextButton(onPressed: onSkip, child: const Text('Skip')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
