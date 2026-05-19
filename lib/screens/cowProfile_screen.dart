import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../theme.dart';
import 'besoins_energetiques_screen.dart';
import 'besoins_proteiques_screen.dart';
import 'besoins_mineraux_screen.dart';
import 'ingestion_screen.dart';
import 'fourrages_screen.dart';
import 'ration_screen.dart';
import 'cow_form_screen.dart';

// Named record for a single info row
typedef _InfoRow = ({String label, String value, bool numeric});

class CowProfileScreen extends StatelessWidget {
  final String name;
  final String id;
  final int age;
  final String dateNaissance;
  final int semaineGestation;
  final double nec;
  final String race;
  final String laitQuotidien;
  final double poids;

  const CowProfileScreen({
    super.key,
    required this.name,
    required this.id,
    required this.age,
    required this.dateNaissance,
    required this.semaineGestation,
    required this.nec,
    required this.race,
    required this.laitQuotidien,
    required this.poids,
  });

  @override
  Widget build(BuildContext context) {
    final cowData = CowData(
      name: name,
      id: id,
      race: race,
      dateNaissance: dateNaissance,
      pv: poids,
      nec: nec,
      plKgJour: CowData.parseLait(laitQuotidien),
      ageMois: age * 12,
      semG: semaineGestation,
    );

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          name,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Modifier le profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CowFormScreen(cowName: name, existing: cowData),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          _buildHeaderCard(),
          const SizedBox(height: 16),

          // ── Identification section ───────────────────────────────────────
          _buildSection(
            title: 'Identification',
            icon: Icons.badge_outlined,
            rows: [
              (label: 'Nom', value: name, numeric: false),
              (label: 'ID', value: id, numeric: false),
              (label: 'Race', value: race, numeric: false),
              (label: 'Date de naissance', value: dateNaissance, numeric: false),
              (label: 'Âge', value: '$age ans', numeric: true),
            ],
          ),
          const SizedBox(height: 12),

          // ── Paramètres physiques ─────────────────────────────────────────
          _buildSection(
            title: 'Paramètres physiques',
            icon: Icons.monitor_weight_outlined,
            rows: [
              (label: 'Poids vif (PV)', value: '$poids kg', numeric: true),
              (
                label: "Note d'état corporel (NEC)",
                value: nec.toStringAsFixed(1),
                numeric: true
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Reproduction & production ────────────────────────────────────
          _buildSection(
            title: 'Reproduction & Production',
            icon: Icons.agriculture,
            rows: [
              (
                label: 'Gestation',
                value: semaineGestation > 0
                    ? 'Semaine $semaineGestation'
                    : 'Non gestante',
                numeric: semaineGestation > 0,
              ),
              (label: 'Production laitière', value: laitQuotidien, numeric: true),
            ],
          ),
          const SizedBox(height: 24),

          // ── Calculs nutritionnels header ─────────────────────────────────
          Row(
            children: [
              const Icon(Icons.science_outlined, color: kGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Calculs Nutritionnels',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ration alimentaire (full-width gradient card) ────────────────
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RationScreen(cow: cowData)),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.grass, size: 34, color: Colors.white),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ration Alimentaire',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculer la ration optimale · données Firebase',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),

          // ── 2-card row: Énergie + Protéines ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildNutrCard(
                  context,
                  'Besoins\nénergétiques',
                  Icons.bolt,
                  BesoinsEnergetiquesScreen(cow: cowData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutrCard(
                  context,
                  'Besoins\nprotéiques',
                  Icons.science,
                  BesoinsProteiquesScreen(cow: cowData),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 3-card row: Minéraux + Ingestion + Fourrages ─────────────────
          Row(
            children: [
              Expanded(
                child: _buildNutrCard(
                  context,
                  'Besoins\nminéraux',
                  Icons.grain,
                  BesoinsMinerauxScreen(cow: cowData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutrCard(
                  context,
                  "Capacité\nd'ingestion",
                  Icons.local_dining,
                  IngestionScreen(cow: cowData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutrCard(
                  context,
                  'Quantité\nfourrages',
                  Icons.grass,
                  FourragesScreen(cow: cowData),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header gradient card ──────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
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
            color: kPrimary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$race · $poids kg',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(Icons.water_drop, laitQuotidien),
              _badge(Icons.monitor_weight_outlined,
                  'NEC ${nec.toStringAsFixed(1)}'),
              if (semaineGestation > 0)
                _badge(Icons.pregnant_woman, 'S$semaineGestation'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Data section card (besoins component card style) ─────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            decoration: const BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorderColor),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.label,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: row.numeric ? kGold : kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < rows.length - 1)
                  const Divider(height: 1, color: kBorderColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Nutritional calc card (square tap card) ───────────────────────────────
  Widget _buildNutrCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: kPrimary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
