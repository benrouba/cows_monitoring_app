import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../theme.dart';

class BesoinsProteiquesScreen extends StatelessWidget {
  final CowData cow;
  const BesoinsProteiquesScreen({super.key, required this.cow});

  @override
  Widget build(BuildContext context) {
    final pv075 = pow(cow.pv, 0.75).toDouble();
    final besEntretien = 3.25 * pv075;
    final besCroissance = 4.22 - (0.01 * cow.ageMois);
    final besProduction = (cow.plKgJour * cow.tp) / 0.64;
    final total = besEntretien + besCroissance + besProduction;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          "Besoins Protéiques",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card — gradient
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, kSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total : ${total.toStringAsFixed(1)} g PDI",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Production: ${cow.plKgJour.toStringAsFixed(1)} kg/j · PV: ${cow.pv} kg",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Entretien
          _buildComponentCard(
            icon: Icons.home_outlined,
            label: "Entretien",
            value: "${besEntretien.toStringAsFixed(1)} g PDI",
            formula: "3.25 × PV^0.75",
          ),
          const SizedBox(height: 10),

          // Croissance
          _buildComponentCard(
            icon: Icons.trending_up,
            label: "Croissance",
            value: "${besCroissance.toStringAsFixed(2)} g PDI",
            formula: "4.22 − (0.01 × âge_mois)",
          ),
          const SizedBox(height: 10),

          // Production
          _buildComponentCard(
            icon: Icons.water_drop_outlined,
            label: "Production",
            value: "${besProduction.toStringAsFixed(1)} g PDI",
            formula: "(PL × TP) / 0.64",
          ),
          const SizedBox(height: 10),

          // Divider
          const Divider(thickness: 1.5),
          const SizedBox(height: 8),

          // Total card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  "${total.toStringAsFixed(1)} g PDI",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildComponentCard({
    required IconData icon,
    required String label,
    required String value,
    required String formula,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formula,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
