import 'package:flutter/material.dart';

class AdviceSetupView extends StatelessWidget {
  const AdviceSetupView({super.key});

  void _navigateToNextView(BuildContext context) {
    Navigator.pushNamed(context, '/subscriptions'); // Replace with actual route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied,
                  size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'No perteneces a ninguna organización!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Parece que no perteneces a ningún hotel, empieza creando uno ...!',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _navigateToNextView(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Empezar Set Up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}