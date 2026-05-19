import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, CowFirebaseData> _fireData = {};
  bool _loading = true;

  double get _totalMilk =>
      _fireData.values.fold(0.0, (s, c) => s + c.dailyMilkKg);
  int get _totalSessions =>
      _fireData.values.fold(0, (s, c) => s + c.sessionsToday);
  double get _avgMilk =>
      _fireData.isEmpty ? 0.0 : _totalMilk / _fireData.length;
  String get _lastUpdate {
    if (_fireData.isEmpty) return '--';
    final times = _fireData.values
        .map((c) => c.lastUpdated)
        .where((t) => t != '--')
        .toList();
    return times.isEmpty
        ? '--'
        : times.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await FirebaseService.instance.fetchAllCows();
    if (mounted) {
      setState(() {
        _fireData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimary,
      backgroundColor: kCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),

          _buildSectionTitle('Production du Jour', Icons.water_drop_outlined),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Total lait',
            value: _loading ? '…' : '${_totalMilk.toStringAsFixed(1)} kg',
            icon: Icons.water_drop_outlined,
            subtitle: 'Somme des productions journalières',
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Sessions de traite',
            value: _loading ? '…' : '$_totalSessions',
            icon: Icons.schedule_outlined,
            subtitle: "Nombre total de traites aujourd'hui",
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Moyenne / vache',
            value: _loading ? '…' : '${_avgMilk.toStringAsFixed(1)} kg',
            icon: Icons.analytics_outlined,
            subtitle: 'Production moyenne par animal',
          ),
          const SizedBox(height: 20),

          _buildSectionTitle("Conditions d'Élevage", Icons.thermostat),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Température',
            value: '18 °C',
            icon: Icons.thermostat_outlined,
            subtitle: "Température ambiante de l'étable",
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Humidité relative',
            value: '82 %',
            icon: Icons.water_outlined,
            subtitle: 'Hygrométrie intérieure',
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Pression atmosphérique',
            value: '1 004 hPa',
            icon: Icons.speed_outlined,
            subtitle: 'Baromètre externe',
          ),
          const SizedBox(height: 10),
          _buildMetricCard(
            label: 'Ammoniac (NH₃)',
            value: '6 ppm',
            icon: Icons.science_outlined,
            subtitle: 'Concentration en gaz ammoniac',
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Activité des Vaches', Icons.pets),
          const SizedBox(height: 10),
          _buildCowActivitySection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header card (gradient) ─────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
            color: kPrimary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading ? 'Chargement…' : '${_totalMilk.toStringAsFixed(1)} kg',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "lait produit aujourd'hui",
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white54, strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(Icons.inventory_2_outlined, '${_fireData.length} vaches'),
              _badge(Icons.update, 'Màj : $_lastUpdate'),
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

  // ── Section title (like besoins screen) ───────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kGold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ],
    );
  }

  // ── Metric card (matches besoins component card exactly) ──────────────────
  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required String subtitle,
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
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
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
            subtitle,
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

  // ── Cow activity rows ──────────────────────────────────────────────────────
  Widget _buildCowActivitySection() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: kPrimary),
        ),
      );
    }

    if (_fireData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
        ),
        child: Center(
          child: Text(
            'Aucune donnée Firebase disponible',
            style: GoogleFonts.nunito(
              color: kTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _fireData.entries.map((e) {
        final name = e.key;
        final data = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: kSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              // Name + sessions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.sessionsToday} séance(s) · ${data.lastUpdated}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Milk value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.dailyMilkKg.toStringAsFixed(2)} kg',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kGold,
                    ),
                  ),
                  Text(
                    'lait/j',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
