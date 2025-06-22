import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/stock'),
              icon: const Icon(Icons.inventory),
              label: const Text('Accéder au Stock'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/geo'),
              icon: const Icon(Icons.location_on),
              label: const Text('Envoyer une géolocalisation'),
            ),
          ],
        ),
      ),
    );
  }
}
