import 'package:flutter/material.dart';

class IngestionScreen extends StatelessWidget {
  const IngestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capacité d’ingestion")),
      body: Center(
        child: Text("À calculer…", style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
