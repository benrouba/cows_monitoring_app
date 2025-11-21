import 'package:flutter/material.dart';
import '../theme.dart';

class EnvCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const EnvCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: kBorderLight),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Icon(icon, color: kAccentGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kTextGray)),
        ],
      ),
    );
  }
}
