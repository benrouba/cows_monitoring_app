import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../theme.dart';

class IngestionScreen extends StatelessWidget {
  final CowData cow;
  const IngestionScreen({super.key, required this.cow});

  @override
  Widget build(BuildContext context) {
    // ── INRA capacité d'ingestion ──────────────────────────────────────────
    final ciBase = 0.022 * cow.pv + 0.3 * cow.plKgJour;

    // Correction NEC : f_NEC = 1 - 0.04 × (NEC - 3.0)
    final fNec = 1.0 - 0.04 * (cow.nec - 3.0);

    // Correction gestation (dernier trimestre, SemG > 34) : −10 %
    final fGest = cow.semG > 34 ? 0.90 : 1.0;

    // Correction âge (vache jeune < 36 mois) : CI réduite
    final fAge = cow.ageMois < 36
        ? (0.70 + 0.010 * cow.ageMois).clamp(0.70, 1.0)
        : 1.0;

    final ciCorr = ciBase * fNec * fGest * fAge;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          "Capacité d'Ingestion",
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kPrimary, kSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: kPrimary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CI = ${ciCorr.toStringAsFixed(2)} kg MS/j',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'PV ${cow.pv.toStringAsFixed(0)} kg'
                  ' · Lait ${cow.plKgJour.toStringAsFixed(1)} kg/j'
                  ' · NEC ${cow.nec.toStringAsFixed(1)}',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          // ── CI de base ──────────────────────────────────────────────────
          _buildCard(
            icon: Icons.calculate_outlined,
            label: 'CI de base',
            value: '${ciBase.toStringAsFixed(2)} kg MS/j',
            formula: '0.022 × PV + 0.3 × PL',
          ),
          const SizedBox(height: 10),

          // ── Correction NEC ───────────────────────────────────────────────
          _buildCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Correction NEC',
            value: '× ${fNec.toStringAsFixed(3)}',
            formula: '1 − 0.04 × (NEC − 3.0)',
            highlight: fNec < 0.96 || fNec > 1.04,
          ),
          const SizedBox(height: 10),

          // ── Correction gestation ─────────────────────────────────────────
          _buildCard(
            icon: Icons.pregnant_woman,
            label: 'Correction gestation',
            value: '× ${fGest.toStringAsFixed(2)}',
            formula: cow.semG > 34
                ? 'Dernier trimestre (SemG > 34) → −10 %'
                : 'Aucune (SemG ≤ 34)',
            highlight: fGest < 1.0,
          ),
          const SizedBox(height: 10),

          // ── Correction âge ───────────────────────────────────────────────
          _buildCard(
            icon: Icons.timeline,
            label: 'Correction âge',
            value: '× ${fAge.toStringAsFixed(3)}',
            formula: cow.ageMois < 36
                ? 'Jeune vache (< 36 mois) : 0.70 + 0.010 × âge_mois'
                : 'Adulte (≥ 36 mois) → pas de correction',
            highlight: fAge < 1.0,
          ),
          const SizedBox(height: 10),

          // ── Divider ──────────────────────────────────────────────────────
          const Divider(thickness: 1.5),
          const SizedBox(height: 8),

          // ── CI corrigée ──────────────────────────────────────────────────
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
                  Text('CI corrigée',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary)),
                  Text('${ciCorr.toStringAsFixed(2)} kg MS/j',
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kGold)),
                ]),
          ),
          const SizedBox(height: 14),

          // ── Note pédagogique ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: kSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La capacité d\'ingestion représente la quantité maximale'
                    ' de matière sèche (MS) que la vache peut consommer par jour.'
                    ' Elle conditionne l\'apport en énergie et protéines via la ration.',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
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

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    required String formula,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlight ? kGold.withValues(alpha: 0.6) : kBorderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: kPrimary, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary))),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: highlight ? kGold : kGold)),
        ]),
        const SizedBox(height: 6),
        Text(formula,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: kTextSecondary)),
      ]),
    );
  }
}
