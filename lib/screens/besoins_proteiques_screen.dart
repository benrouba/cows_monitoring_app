import 'package:flutter/material.dart';

class BesoinsProteiquesScreen extends StatelessWidget {
  const BesoinsProteiquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Besoins protéiques")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("Entretien", "À calculer…"),
          const SizedBox(height: 12),
          _buildSection("Production", "Croissance, lactation…"),
          const SizedBox(height: 12),
          _buildSection("Gestation", "À calculer…"),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String placeholder) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(placeholder, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
