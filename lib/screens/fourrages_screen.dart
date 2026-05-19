import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../models/feed.dart';
import '../theme.dart';

class FourragesScreen extends StatelessWidget {
  final CowData cow;
  const FourragesScreen({super.key, required this.cow});

  @override
  Widget build(BuildContext context) {
    // CI corrigée (same formula as IngestionScreen)
    final ciBase = 0.022 * cow.pv + 0.3 * cow.plKgJour;
    final fNec   = 1.0 - 0.04 * (cow.nec - 3.0);
    final fGest  = cow.semG > 34 ? 0.90 : 1.0;
    final fAge   = cow.ageMois < 36
        ? (0.70 + 0.010 * cow.ageMois).clamp(0.70, 1.0)
        : 1.0;
    final ci = ciBase * fNec * fGest * fAge;

    // ── Répartition recommandée ─────────────────────────────────────────
    // Fourrages : 70 % CI   (ensilage maïs 55 % + foin 15 %)
    // Concentrés: 30 % CI
    final ensilageMs = ci * 0.55;
    final foinMs     = ci * 0.15;
    final concMs     = ci * 0.30;

    final ensilageFrais = Feed.ensilageMais.msToFreshKg(ensilageMs);
    final foinFrais     = Feed.foinPrairie.msToFreshKg(foinMs);

    // Energy / protein from fourrages
    final ufFourrages  = ensilageMs * Feed.ensilageMais.uflPerKgMs
                       + foinMs     * Feed.foinPrairie.uflPerKgMs;
    final pdiFourrages = ensilageMs * Feed.ensilageMais.pdiePerKgMs
                       + foinMs     * Feed.foinPrairie.pdiePerKgMs;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          'Quantité de Fourrages',
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
                Text('${(ensilageMs + foinMs).toStringAsFixed(1)} kg MS/j',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('fourrages recommandés (70 % CI)',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                _headerBadge(
                    'CI totale : ${ci.toStringAsFixed(1)} kg MS/j'),
                const SizedBox(height: 6),
                _headerBadge(
                    'Concentrés : ${concMs.toStringAsFixed(1)} kg MS/j'),
              ],
            ),
          ),

          // ── Section fourrages ──────────────────────────────────────────
          _sectionTitle('Fourrages', Icons.grass, kSecondary),
          const SizedBox(height: 10),

          _buildFourrage(
            label: 'Ensilage de maïs',
            icon: Icons.grass,
            kgMs: ensilageMs,
            kgFrais: ensilageFrais,
            msPercent: 32,
            color: kSecondary,
            ufl: ensilageMs * Feed.ensilageMais.uflPerKgMs,
            pdi: ensilageMs * Feed.ensilageMais.pdiePerKgMs,
          ),
          const SizedBox(height: 10),

          _buildFourrage(
            label: 'Foin de prairie',
            icon: Icons.eco,
            kgMs: foinMs,
            kgFrais: foinFrais,
            msPercent: 85,
            color: const Color(0xFF7CB342),
            ufl: foinMs * Feed.foinPrairie.uflPerKgMs,
            pdi: foinMs * Feed.foinPrairie.pdiePerKgMs,
          ),
          const SizedBox(height: 16),

          // ── Apports des fourrages ──────────────────────────────────────
          _sectionTitle('Apports des fourrages', Icons.analytics_outlined, kGold),
          const SizedBox(height: 10),

          _buildCard(
            icon: Icons.bolt,
            label: 'Énergie apportée',
            value: '${ufFourrages.toStringAsFixed(2)} UFL',
            subtitle: 'Énergie issue des fourrages seuls',
          ),
          const SizedBox(height: 10),
          _buildCard(
            icon: Icons.science_outlined,
            label: 'Protéines apportées',
            value: '${pdiFourrages.toStringAsFixed(0)} g PDI',
            subtitle: 'PDI issus des fourrages seuls',
          ),
          const SizedBox(height: 16),

          // ── Concentrés restants ────────────────────────────────────────
          _sectionTitle('Concentrés disponibles', Icons.grain, kGold),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(children: [
              const Icon(Icons.grain, color: kGold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Part concentrés (30 % CI)',
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      'À compléter pour couvrir les besoins résiduels'
                      ' en énergie et protéines.',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: kTextSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              Text('${concMs.toStringAsFixed(1)} kg MS',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kGold)),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Note ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: kSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Le ratio fourrages/concentrés de 70/30 assure un bon'
                  ' fonctionnement du rumen (pH stable) tout en soutenant'
                  ' une production laitière élevée. Consultez la ration'
                  ' alimentaire complète pour les calculs de couverture.',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: kTextSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _headerBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.playfairDisplay(
              fontSize: 15, fontWeight: FontWeight.w600, color: kPrimary)),
    ]);
  }

  Widget _buildFourrage({
    required String label,
    required IconData icon,
    required double kgMs,
    required double kgFrais,
    required int msPercent,
    required Color color,
    required double ufl,
    required double pdi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(children: [
          Container(width: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary)),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${kgMs.toStringAsFixed(2)} kg MS',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kGold)),
                      Text('${kgFrais.toStringAsFixed(1)} kg frais',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: kTextSecondary)),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _chip('MS $msPercent %', color),
                    const SizedBox(width: 6),
                    _chip('${ufl.toStringAsFixed(2)} UFL', kPrimary),
                    const SizedBox(width: 6),
                    _chip('${pdi.toStringAsFixed(0)} g PDI', kSecondary),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
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
                  color: kGold)),
        ]),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: kTextSecondary)),
      ]),
    );
  }
}
