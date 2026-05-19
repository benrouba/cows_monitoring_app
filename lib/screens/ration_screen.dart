import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/cow_data.dart';
import '../models/feed.dart';
import '../services/firebase_service.dart';
import '../services/ration_calculator.dart';
import '../theme.dart' hide kDisplayStyle, kSectionTitle;

// Local overrides for section titles (larger than global _sectionTitle)
TextStyle get _sectionTitle => GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
    );

// ─── Screen ─────────────────────────────────────────────────────────────────
class RationScreen extends StatefulWidget {
  const RationScreen({super.key, required this.cow});

  final CowData cow;

  @override
  State<RationScreen> createState() => _RationScreenState();
}

class _RationScreenState extends State<RationScreen>
    with SingleTickerProviderStateMixin {
  double? _liveMilkKg;
  bool _isLoadingFirebase = true;
  bool _hasFirebaseData = false;
  RationResult? _ration;

  // Pulsing animation controller for the LIVE badge
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double get _effectivePl => _liveMilkKg ?? widget.cow.plKgJour;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    _loadFirebase();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadFirebase() async {
    setState(() {
      _isLoadingFirebase = true;
    });

    try {
      final data = await FirebaseService.instance.fetchCow(widget.cow.name);
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _liveMilkKg = data.dailyMilkKg;
          _hasFirebaseData = true;
          _isLoadingFirebase = false;
        });
      } else {
        setState(() {
          _liveMilkKg = null;
          _hasFirebaseData = false;
          _isLoadingFirebase = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liveMilkKg = null;
        _hasFirebaseData = false;
        _isLoadingFirebase = false;
      });
    }

    _recalcRation();
  }

  void _recalcRation() {
    final effectiveCow = widget.cow.copyWith(plKgJour: _effectivePl);
    final result = RationCalculator.generate(effectiveCow);
    if (mounted) {
      setState(() => _ration = result);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _loadFirebase,
        color: kPrimary,
        backgroundColor: kCardBg,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParamsSection(),
                    const SizedBox(height: 20),
                    _buildNeedsSection(),
                    const SizedBox(height: 20),
                    _buildRationSection(),
                    const SizedBox(height: 20),
                    _buildBalanceSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SliverAppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      floating: false,
      backgroundColor: kPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Rafraîchir les données',
          onPressed: _loadFirebase,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 12),
        title: Text(
          widget.cow.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left info column
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          widget.cow.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.cow.race} · ${widget.cow.pv.toStringAsFixed(0)} kg',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Production badge row
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: kGoldLight,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_effectivePl.toStringAsFixed(1)} kg/j',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kGoldLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Firebase status badge
                        if (_isLoadingFirebase)
                          _buildShimmerBadge()
                        else if (_hasFirebaseData)
                          _buildLiveBadge(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Right: large cow icon
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FaIcon(
                      FontAwesomeIcons.cow,
                      color: Colors.white.withOpacity(0.18),
                      size: 80,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE Firebase',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.greenAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Chargement…',
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Colors.white.withOpacity(0.65),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ─── Section 1 — Paramètres ────────────────────────────────────────────────
  Widget _buildParamsSection() {
    final cow = widget.cow;
    return _SectionCard(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        leading: const Icon(Icons.tune, color: kSecondary),
        title: Text(
          'Paramètres de la vache',
          style: _sectionTitle.copyWith(fontSize: 16),
        ),
        iconColor: kSecondary,
        collapsedIconColor: kTextSecondary,
        children: [
          const Divider(height: 1, color: kBorderColor),
          _buildInfoRow('Poids vif (PV)', '${cow.pv.toStringAsFixed(0)} kg'),
          _buildInfoRow(
              'Poids vide (PV × 0.87)', '${cow.pvVide.toStringAsFixed(0)} kg'),
          _buildInfoRow('NEC', cow.nec.toStringAsFixed(1)),
          _buildInfoRow('Âge', '${cow.ageMois} mois'),
          _buildInfoRow('Semaine de gestation', 'S${cow.semG}'),
          _buildInfoRow(
              'Production lait', '${cow.plKgJour.toStringAsFixed(1)} kg/j'),
          _buildInfoRow('TB', '${cow.tb.toStringAsFixed(1)} g/L'),
          _buildInfoRow('TP', '${cow.tp.toStringAsFixed(1)} g/L'),
          _buildInfoRow('Activité (Iact)', cow.iact.toStringAsFixed(2)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: kTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 2 — Besoins ──────────────────────────────────────────────────
  Widget _buildNeedsSection() {
    final ration = _ration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: kGold, size: 22),
            const SizedBox(width: 8),
            Text('Besoins Calculés', style: _sectionTitle),
          ],
        ),
        const SizedBox(height: 12),
        if (ration == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: kPrimary),
            ),
          )
        else ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: _buildEnergyCard(ration.energy, ration.protein)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildProteinCard(ration.protein, ration.energy)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCICard(ration.ci),
        ],
      ],
    );
  }

  Widget _buildEnergyCard(EnergyNeeds energy, ProteinNeeds protein) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Énergie (UFL)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildNeedRow('Entretien', energy.entretien, 'UFL', 2),
          _buildNeedRow('Croissance', energy.croissance, 'UFL', 2),
          _buildNeedRow('Production', energy.production, 'UFL', 2),
          if (energy.gestation > 0)
            _buildNeedRow('Gestation', energy.gestation, 'UFL', 2),
          const Divider(height: 1, color: kBorderColor, thickness: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  '${energy.total.toStringAsFixed(2)} UFL',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: kGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinCard(ProteinNeeds protein, EnergyNeeds energy) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: kSecondary.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: kSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.science, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Protéines (g PDI)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildNeedRow('Entretien', protein.entretien, 'g', 1),
          _buildNeedRow('Croissance', protein.croissance, 'g', 1),
          _buildNeedRow('Production', protein.production, 'g', 1),
          const Divider(height: 1, color: kBorderColor, thickness: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  '${protein.total.toStringAsFixed(1)} g',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: kGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedRow(String label, double value, String unit, int decimals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${value.toStringAsFixed(decimals)} $unit',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: kTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCICard(double ci) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: kSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Capacité d\'ingestion : ${ci.toStringAsFixed(1)} kg MS/j',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3 — Ration proposée ──────────────────────────────────────────
  Widget _buildRationSection() {
    final ration = _ration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.grass, color: kSecondary, size: 22),
            const SizedBox(width: 8),
            Text('Ration Proposée', style: _sectionTitle),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Basée sur ${_effectivePl.toStringAsFixed(1)} kg lait/j',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: kTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 14),
        if (ration == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: kPrimary),
            ),
          )
        else
          _buildFeedList(ration),
      ],
    );
  }

  Widget _buildFeedList(RationResult ration) {
    final fourrages =
        ration.feeds.where((f) => f.feed.isFourrage).toList();
    final concentres =
        ration.feeds.where((f) => !f.feed.isFourrage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fourrages
        if (fourrages.isNotEmpty) ...[
          _buildCategoryDivider('Fourrages', Icons.grass, kSecondary),
          const SizedBox(height: 8),
          ...fourrages.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildFeedCard(f),
              )),
        ],
        // Concentrés
        if (concentres.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildCategoryDivider('Concentrés', Icons.grain, kGold),
          const SizedBox(height: 8),
          ...concentres.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildFeedCard(f),
              )),
        ],
        const SizedBox(height: 6),
        _buildTotalRow(ration),
      ],
    );
  }

  Widget _buildCategoryDivider(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: color.withOpacity(0.25),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedCard(FeedAllocation f) {
    final bool isFourrage = f.feed.isFourrage;
    final Color barColor = isFourrage ? kSecondary : kGold;
    final Color badgeColor = isFourrage ? kSecondary : kGold;
    final IconData feedIcon = isFourrage ? Icons.grass : Icons.grain;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Left colored bar
            Container(
              width: 4,
              color: barColor,
            ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // Leading badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(feedIcon, color: badgeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Center info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.feed.label,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${f.kgMs.toStringAsFixed(2)} kg MS · ${f.kgFrais.toStringAsFixed(1)} kg frais',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trailing values
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${f.uflProvided.toStringAsFixed(2)} UFL',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${f.pdiProvided.toStringAsFixed(0)} g PDI',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(RationResult ration) {
    final double fillRatio =
        (ration.totalMsKg / ration.ci).clamp(0.0, 1.0);

    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total MS',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextSecondary,
                  ),
                ),
                Text(
                  '${ration.totalMsKg.toStringAsFixed(1)} / ${ration.ci.toStringAsFixed(1)} kg MS (CI)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fillRatio,
                minHeight: 7,
                backgroundColor: kBorderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  fillRatio < 0.9
                      ? kErrorColor
                      : fillRatio > 1.05
                          ? kGold
                          : kPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(fillRatio * 100).toStringAsFixed(0)}% de la capacité d\'ingestion',
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: kTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 4 — Bilan ────────────────────────────────────────────────────
  Widget _buildBalanceSection() {
    final ration = _ration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.balance, color: kGold, size: 22),
            const SizedBox(width: 8),
            Text('Bilan Nutritionnel', style: _sectionTitle),
          ],
        ),
        const SizedBox(height: 14),
        if (ration == null)
          const Center(
            child: CircularProgressIndicator(color: kPrimary),
          )
        else ...[
          _buildCoverageBar(
            'Énergie (UFL)',
            ration.uflCovered,
            ration.energy.total,
            'UFL',
          ),
          const SizedBox(height: 14),
          _buildCoverageBar(
            'Protéines (g PDI)',
            ration.pdiCovered,
            ration.protein.total,
            'g',
          ),
          const SizedBox(height: 16),
          _buildRecommendationBox(ration),
        ],
      ],
    );
  }

  Widget _buildCoverageBar(
    String label,
    double covered,
    double needed,
    String unit,
  ) {
    final double ratio = needed > 0 ? covered / needed : 0;
    final double percent = ratio * 100;
    final double progressValue = (ratio / 1.2).clamp(0.0, 1.0);

    // Color logic
    Color barColor;
    String statusText;
    if (percent >= 90 && percent <= 110) {
      barColor = kPrimary;
      statusText = '${percent.toStringAsFixed(0)}% — Couverture optimale ✓';
    } else if (percent > 110 && percent <= 125) {
      barColor = kGold;
      statusText = '${percent.toStringAsFixed(0)}% — Légèrement excédentaire';
    } else if (percent < 90) {
      barColor = kErrorColor;
      statusText =
          '${percent.toStringAsFixed(0)}% — Couverture insuffisante ✗';
    } else {
      barColor = kErrorColor;
      statusText = '${percent.toStringAsFixed(0)}% — Excès important ⚠';
    }

    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  '${covered.toStringAsFixed(2)} / ${needed.toStringAsFixed(2)} $unit',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 9,
                backgroundColor: kBorderColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationBox(RationResult ration) {
    final double energyPct = ration.energy.total > 0
        ? (ration.uflCovered / ration.energy.total) * 100
        : 0;
    final double proteinPct = ration.protein.total > 0
        ? (ration.pdiCovered / ration.protein.total) * 100
        : 0;

    final bool isOptimal = (energyPct >= 90 && energyPct <= 115) &&
        (proteinPct >= 90 && proteinPct <= 115);

    final String recommendation;
    final IconData recIcon;
    final Color recColor;

    if (isOptimal) {
      recommendation =
          'La ration est bien équilibrée. Les apports en énergie et en protéines couvrent les besoins de la vache de manière optimale. Maintenez cette ration.';
      recIcon = Icons.check_circle_outline;
      recColor = kPrimary;
    } else if (energyPct < 90) {
      recommendation =
          'La couverture énergétique est insuffisante (${energyPct.toStringAsFixed(0)}%). Envisagez d\'augmenter la part de concentrés énergétiques (maïs grain, orge) ou la quantité d\'ensilage de maïs.';
      recIcon = Icons.warning_amber_outlined;
      recColor = kErrorColor;
    } else if (proteinPct < 90) {
      recommendation =
          'L\'apport protéique est déficitaire (${proteinPct.toStringAsFixed(0)}%). Augmentez la part de tourteau de soja ou de colza pour couvrir les besoins en PDI.';
      recIcon = Icons.warning_amber_outlined;
      recColor = kErrorColor;
    } else if (energyPct > 125) {
      recommendation =
          'Excès énergétique important (${energyPct.toStringAsFixed(0)}%). Réduisez les concentrés pour éviter les risques d\'acidose et une surcharge pondérale.';
      recIcon = Icons.info_outline;
      recColor = kGold;
    } else {
      recommendation =
          'La ration est légèrement déséquilibrée. Ajustez les proportions fourrages/concentrés pour optimiser les couverts énergétiques et protéiques.';
      recIcon = Icons.info_outline;
      recColor = kGold;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSurface, kCardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: recColor.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(recIcon, color: recColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: kTextPrimary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widget ─────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
