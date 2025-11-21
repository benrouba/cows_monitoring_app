import 'package:flutter/material.dart';

class FourragesScreen extends StatelessWidget {
  const FourragesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quantité de fourrages")),
      body: Center(
        child: Text("À calculer…", style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
