import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final int uid;

  const HomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Authenticated successfully',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('UID: $uid', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
