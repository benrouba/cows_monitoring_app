import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../theme.dart';

class BesoinsMinerauxScreen extends StatelessWidget {
  final CowData cow;
  const BesoinsMinerauxScreen({super.key, required this.cow});

  @override
  Widget build(BuildContext context) {
    final pv075 = pow(cow.pv, 0.75).toDouble();

    // ── Calcium (Ca) g/j ─────────────────────────────────────────────────
    final caEnt  = 0.031 * pv075;
    final caProd = 1.22  * cow.plKgJour;
    final caGest = cow.semG > 0
        ? 0.012 * pow(cow.pvVide, 0.75) * exp(0.016 * cow.semG)
        : 0.0;
    final caTotal = caEnt + caProd + caGest;

    // ── Phosphore (P) g/j ─────────────────────────────────────────────────
    final pEnt   = 0.028 * pv075;
    final pProd  = 0.90  * cow.plKgJour;
    final pTotal = pEnt  + pProd;

    // ── Magnésium (Mg) g/j ───────────────────────────────────────────────
    final mgEnt   = 0.003 * cow.pv;
    final mgProd  = 0.14  * cow.plKgJour;
    final mgTotal = mgEnt + mgProd;

    // ── Sodium (Na) g/j ──────────────────────────────────────────────────
    final naEnt   = 0.022 * cow.pv;
    final naProd  = 0.63  * cow.plKgJour;
    final naTotal = naEnt + naProd;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          'Besoins Minéraux',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ────────────────────────────────────────────────────
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
                Text('Macro-éléments Minéraux',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Ca · P · Mg · Na  ·  PV ${cow.pv.toStringAsFixed(0)} kg'
                  ' · Lait ${cow.plKgJour.toStringAsFixed(1)} kg/j',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          // ── Calcium ───────────────────────────────────────────────────
          _buildMineralCard(
            symbol: 'Ca',
            name: 'Calcium',
            color: const Color(0xFF1565C0),
            entretien: caEnt,
            production: caProd,
            gestation: caGest,
            total: caTotal,
            formulaEnt: '0.031 × PV^0.75',
            formulaProd: '1.22 g/kg lait × PL',
            formulaGest: cow.semG > 0
                ? '0.012 × PV_vid^0.75 × e^(0.016 × SemG)'
                : null,
          ),
          const SizedBox(height: 12),

          // ── Phosphore ─────────────────────────────────────────────────
          _buildMineralCard(
            symbol: 'P',
            name: 'Phosphore',
            color: const Color(0xFF2E7D32),
            entretien: pEnt,
            production: pProd,
            gestation: 0,
            total: pTotal,
            formulaEnt: '0.028 × PV^0.75',
            formulaProd: '0.90 g/kg lait × PL',
          ),
          const SizedBox(height: 12),

          // ── Magnésium ─────────────────────────────────────────────────
          _buildMineralCard(
            symbol: 'Mg',
            name: 'Magnésium',
            color: const Color(0xFFC17900),
            entretien: mgEnt,
            production: mgProd,
            gestation: 0,
            total: mgTotal,
            formulaEnt: '0.003 × PV',
            formulaProd: '0.14 g/kg lait × PL',
          ),
          const SizedBox(height: 12),

          // ── Sodium ────────────────────────────────────────────────────
          _buildMineralCard(
            symbol: 'Na',
            name: 'Sodium',
            color: const Color(0xFF6A1B9A),
            entretien: naEnt,
            production: naProd,
            gestation: 0,
            total: naTotal,
            formulaEnt: '0.022 × PV',
            formulaProd: '0.63 g/kg lait × PL',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMineralCard({
    required String symbol,
    required String name,
    required Color color,
    required double entretien,
    required double production,
    required double gestation,
    required double total,
    required String formulaEnt,
    required String formulaProd,
    String? formulaGest,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: kSurface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(symbol,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text(name,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary)),
              const Spacer(),
              Text('${total.toStringAsFixed(1)} g/j',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kGold)),
            ]),
          ),
          const Divider(height: 1, color: kBorderColor),

          // Entretien row
          _subRow('Entretien', entretien, formulaEnt),
          const Divider(height: 1, color: kBorderColor),

          // Production row
          _subRow('Production', production, formulaProd),

          // Gestation row (only if >0)
          if (gestation > 0) ...[
            const Divider(height: 1, color: kBorderColor),
            _subRow(
                'Gestation', gestation, formulaGest ?? ''),
          ],

          // Total footer
          const Divider(height: 1, color: kBorderColor, thickness: 1.2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary)),
                  Text('${total.toStringAsFixed(2)} g/j',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: kGold)),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _subRow(String label, double value, String formula) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: kTextSecondary,
                    fontWeight: FontWeight.w600)),
            Text('${value.toStringAsFixed(2)} g',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary)),
          ]),
          if (formula.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(formula,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: kTextSecondary)),
          ],
        ],
      ),
    );
  }
}
