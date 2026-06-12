import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feeding_models.dart';
import '../services/feeding_service.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────
class FeedingPlansScreen extends StatefulWidget {
  const FeedingPlansScreen({super.key});

  @override
  State<FeedingPlansScreen> createState() => _FeedingPlansScreenState();
}

class _FeedingPlansScreenState extends State<FeedingPlansScreen> {
  final TextEditingController _serverUrlCtrl = TextEditingController(
    text: 'https://cow-farm-server.onrender.com/',
  );

  bool _loadingCows = true;
  List<FeedingCow> _cows = [];

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
    _loadCows();
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url =
        prefs.getString('server_url') ??
        'https://cow-farm-server.onrender.com/';
    if (mounted) setState(() => _serverUrlCtrl.text = url);
  }

  Future<void> _saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url.trim());
  }

  Future<void> _loadCows() async {
    setState(() => _loadingCows = true);
    final results = await Future.wait([
      FirebaseService.instance.fetchAllProfilesRaw(),
      FirebaseService.instance.fetchLatestMilkYields(),
    ]);
    final profiles = results[0] as Map<String, Map<String, dynamic>>;
    final milkYields = results[1] as Map<String, double>;
    final cows =
        profiles.entries
            .map(
              (e) => FeedingCow(
                name: e.key,
                profile: e.value,
                milkYieldKg: milkYields[e.key] ?? 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        _cows = cows;
        _loadingCows = false;
      });
    }
  }

  String get _serverUrl =>
      _serverUrlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _buildServerUrlField(),
          Material(
            color: kCardBg,
            child: TabBar(
              labelColor: kPrimary,
              unselectedLabelColor: kTextSecondary,
              indicatorColor: kPrimary,
              labelStyle: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Individuel'),
                Tab(text: 'Groupe'),
                Tab(text: 'Intelligent'),
              ],
            ),
          ),
          Expanded(
            child: _loadingCows
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  )
                : _cows.isEmpty
                ? _buildEmptyState()
                : TabBarView(
                    children: [
                      _IndividualTab(
                        cows: _cows,
                        serverUrl: _serverUrl,
                        onRefresh: _loadCows,
                      ),
                      _GroupTab(
                        cows: _cows,
                        serverUrl: _serverUrl,
                        onRefresh: _loadCows,
                      ),
                      _SmartTab(
                        cows: _cows,
                        serverUrl: _serverUrl,
                        onRefresh: _loadCows,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Server URL field ────────────────────────────────────────────────────
  Widget _buildServerUrlField() {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: _serverUrlCtrl,
        keyboardType: TextInputType.url,
        style: GoogleFonts.nunito(fontSize: 13, color: kTextPrimary),
        onChanged: (v) {
          _saveServerUrl(v);
          setState(() {});
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          labelText: 'URL du serveur',
          labelStyle: GoogleFonts.nunito(fontSize: 12, color: kTextSecondary),
          prefixIcon: const Icon(Icons.dns_outlined, color: kPrimary, size: 18),
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadCows,
      color: kPrimary,
      backgroundColor: kCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: kBorderColor),
                const SizedBox(height: 16),
                Text(
                  'Aucun profil de vache trouvé',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tirez vers le bas pour rafraîchir',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: kTextSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helper widgets ───────────────────────────────────────────────────

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

Widget _sectionHeading(String text, IconData icon, {Color color = kPrimary}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _kvRow(
  String label,
  String value, {
  bool bold = false,
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: kTextSecondary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: valueColor ?? (bold ? kGold : kTextPrimary),
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _rationFeedRows(RationResult r) {
  return Column(
    children: [
      _kvRow('Paille', '${r.strawKg.toStringAsFixed(3)} kg'),
      _kvRow('Paille traitée', '${r.treatedStrawKg.toStringAsFixed(3)} kg'),
      _kvRow('Orge', '${r.barleyKg.toStringAsFixed(3)} kg'),
      _kvRow('Concentré', '${r.concentrateKg.toStringAsFixed(3)} kg'),
      const Divider(height: 1, color: kBorderColor),
      _kvRow('MS totale', '${r.dmiKg.toStringAsFixed(3)} kg', bold: true),
    ],
  );
}

Widget _serverUnreachableSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Serveur inaccessible'),
      backgroundColor: kErrorColor,
    ),
  );
  return const SizedBox.shrink();
}

// ─── Tab 1 — Individual ───────────────────────────────────────────────────────
class _IndividualTab extends StatefulWidget {
  const _IndividualTab({
    required this.cows,
    required this.serverUrl,
    required this.onRefresh,
  });

  final List<FeedingCow> cows;
  final String serverUrl;
  final Future<void> Function() onRefresh;

  @override
  State<_IndividualTab> createState() => _IndividualTabState();
}

class _IndividualTabState extends State<_IndividualTab> {
  String? _selectedName;
  bool _loading = false;
  IndividualRationResult? _result;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.cows.first.name;
  }

  @override
  void didUpdateWidget(covariant _IndividualTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.cows.any((c) => c.name == _selectedName)) {
      _selectedName = widget.cows.isNotEmpty ? widget.cows.first.name : null;
      _result = null;
    }
  }

  FeedingCow? get _selectedCow {
    for (final c in widget.cows) {
      if (c.name == _selectedName) return c;
    }
    return null;
  }

  Future<void> _calculate() async {
    final cow = _selectedCow;
    if (cow == null) return;
    setState(() => _loading = true);
    try {
      final result = await FeedingService.instance.postIndividual(
        widget.serverUrl,
        cow,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _serverUnreachableSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cow = _selectedCow;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: kPrimary,
      backgroundColor: kCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildCowDropdown(),
          const SizedBox(height: 12),
          if (cow != null) _buildCowCard(cow),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_loading || cow == null) ? null : _calculate,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                'Calculer la ration optimale',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) _buildResultCard(_result!),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCowDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedName,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: kPrimary),
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
          items: widget.cows
              .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedName = v;
            _result = null;
          }),
        ),
      ),
    );
  }

  Widget _buildCowCard(FeedingCow cow) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  cow.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: kBorderColor),
            _kvRow('Poids', '${cow.pv.toStringAsFixed(3)} kg'),
            _kvRow('NEC', cow.nec.toStringAsFixed(1)),
            _kvRow('Gestation', '${cow.semG} semaines'),
            _kvRow(
              'Production laitière',
              '${cow.milkYieldKg.toStringAsFixed(2)} kg/jour',
            ),
            _kvRow('Race', cow.race.isNotEmpty ? cow.race : '—'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(IndividualRationResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Besoins', Icons.bolt),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _kvRow(
                  'NEL total',
                  '${r.nelTotal.toStringAsFixed(3)} Mcal/jour',
                  bold: true,
                ),
                _kvRow(
                  '  Entretien',
                  '${r.nelMaint.toStringAsFixed(3)} Mcal/jour',
                ),
                _kvRow('  Lait', '${r.nelMilk.toStringAsFixed(3)} Mcal/jour'),
                _kvRow(
                  '  Gestation',
                  '${r.nelGest.toStringAsFixed(3)} Mcal/jour',
                ),
                const Divider(height: 16, color: kBorderColor),
                _kvRow(
                  'MAT total',
                  '${r.cpReqG.toStringAsFixed(1)} g/jour',
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading(
          'Ration (kg/jour par vache)',
          Icons.grass,
          color: kSecondary,
        ),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _rationFeedRows(r.ration),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading('Bilan', Icons.balance, color: kGold),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _kvRow(
                  'Couverture NEL',
                  '${r.ration.nelCoveragePct.toStringAsFixed(1)}%',
                ),
                _kvRow(
                  'Couverture MAT',
                  '${r.ration.cpCoveragePct.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 2 — Group ──────────────────────────────────────────────────────────
class _GroupTab extends StatefulWidget {
  const _GroupTab({
    required this.cows,
    required this.serverUrl,
    required this.onRefresh,
  });

  final List<FeedingCow> cows;
  final String serverUrl;
  final Future<void> Function() onRefresh;

  @override
  State<_GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<_GroupTab> {
  final _strawCtrl = TextEditingController();
  final _treatedStrawCtrl = TextEditingController();
  final _barleyCtrl = TextEditingController();
  final _concentrateCtrl = TextEditingController();

  bool _loading = false;
  bool _infeasible = false;
  GroupRationResult? _result;

  static const _stockLabels = {
    'straw': 'Paille',
    'treated_straw': 'Paille traitée',
    'barley': 'Orge',
    'concentrate': 'Concentré',
  };

  @override
  void dispose() {
    _strawCtrl.dispose();
    _treatedStrawCtrl.dispose();
    _barleyCtrl.dispose();
    _concentrateCtrl.dispose();
    super.dispose();
  }

  double get _avgWeight => widget.cows.isEmpty
      ? 0
      : widget.cows.map((c) => c.pv).reduce((a, b) => a + b) /
            widget.cows.length;

  double get _avgMilk => widget.cows.isEmpty
      ? 0
      : widget.cows.map((c) => c.milkYieldKg).reduce((a, b) => a + b) /
            widget.cows.length;

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0.0;

  Future<void> _optimize() async {
    setState(() {
      _loading = true;
      _infeasible = false;
    });
    final stock = {
      'straw': _parse(_strawCtrl),
      'treated_straw': _parse(_treatedStrawCtrl),
      'barley': _parse(_barleyCtrl),
      'concentrate': _parse(_concentrateCtrl),
    };
    try {
      final result = await FeedingService.instance.postGroup(
        widget.serverUrl,
        widget.cows,
        stock,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on InfeasibleStockException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _infeasible = true;
        _result = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _serverUnreachableSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: kPrimary,
      backgroundColor: kCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeading(
            'Stock d\'aliments disponible',
            Icons.warehouse_outlined,
          ),
          _numberField(_strawCtrl, 'Paille (kg)'),
          const SizedBox(height: 10),
          _numberField(_treatedStrawCtrl, 'Paille traitée (kg)'),
          const SizedBox(height: 10),
          _numberField(_barleyCtrl, 'Orge (kg)'),
          const SizedBox(height: 10),
          _numberField(_concentrateCtrl, 'Concentré (kg)'),
          const SizedBox(height: 20),
          _sectionHeading(
            'Aperçu du troupeau',
            Icons.pets_outlined,
            color: kSecondary,
          ),
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _kvRow('Vaches', '${widget.cows.length}'),
                  _kvRow('Poids moyen', '${_avgWeight.toStringAsFixed(3)} kg'),
                  _kvRow(
                    'Lait moyen',
                    '${_avgMilk.toStringAsFixed(2)} kg/jour',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _optimize,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.tune),
              label: Text(
                'Optimiser la ration du groupe',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_infeasible) _buildInfeasibleWarning(),
          if (_result != null) _buildResult(_result!),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.nunito(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(fontSize: 13, color: kTextSecondary),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderColor),
        ),
      ),
    );
  }

  Widget _buildInfeasibleWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kGoldLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: kGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Stock insuffisant. Augmentez les quantités.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(GroupRationResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Ration par vache', Icons.grass, color: kSecondary),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _rationFeedRows(r.rationPerCow),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading(
          'Utilisation du stock',
          Icons.inventory_2_outlined,
          color: kGold,
        ),
        _SectionCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(0.8),
              },
              children: [
                TableRow(
                  children: [
                    _stockHeaderCell('Aliment'),
                    _stockHeaderCell('Utilisé (kg)'),
                    _stockHeaderCell('Restant (kg)'),
                    _stockHeaderCell('Utilisé %'),
                  ],
                ),
                for (final entry in _stockLabels.entries)
                  TableRow(
                    children: [
                      _stockCell(entry.value, bold: true),
                      _stockCell(
                        (r.stockUsage[entry.key]?.usedKg ?? 0).toStringAsFixed(
                          3,
                        ),
                      ),
                      _stockCell(
                        (r.stockUsage[entry.key]?.remainingKg ?? 0)
                            .toStringAsFixed(3),
                      ),
                      _stockCell(
                        '${(r.stockUsage[entry.key]?.usedPct ?? 0).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stockHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: kTextSecondary,
        ),
      ),
    );
  }

  Widget _stockCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: kTextPrimary,
        ),
      ),
    );
  }
}

// ─── Tab 3 — Smart ──────────────────────────────────────────────────────────
class _SmartTab extends StatefulWidget {
  const _SmartTab({
    required this.cows,
    required this.serverUrl,
    required this.onRefresh,
  });

  final List<FeedingCow> cows;
  final String serverUrl;
  final Future<void> Function() onRefresh;

  @override
  State<_SmartTab> createState() => _SmartTabState();
}

class _SmartTabState extends State<_SmartTab> {
  late int _nGroups;
  bool _loading = false;
  SmartResult? _result;

  @override
  void initState() {
    super.initState();
    final count = widget.cows.length;
    _nGroups = count >= 3 ? 3 : (count >= 2 ? count : 2);
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final result = await FeedingService.instance.postSmart(
        widget.serverUrl,
        _nGroups,
        widget.cows,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _serverUnreachableSnack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: kPrimary,
      backgroundColor: kCardBg,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeading('Nombre de groupes', Icons.groups_outlined),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(9, (i) => i + 2).map((n) {
              final enabled = n <= widget.cows.length;
              final selected = n == _nGroups;
              return ChoiceChip(
                label: Text('$n'),
                selected: selected,
                onSelected: enabled
                    ? (_) => setState(() => _nGroups = n)
                    : null,
                selectedColor: kPrimary,
                disabledColor: kSurface,
                backgroundColor: kSurface,
                labelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : (enabled
                            ? kTextPrimary
                            : kTextSecondary.withValues(alpha: 0.5)),
                ),
                side: BorderSide(color: selected ? kPrimary : kBorderColor),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Les vaches sont regroupées selon leur poids, leur production '
            'laitière et leurs besoins énergétiques. Chaque groupe reçoit '
            'sa propre ration.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: kTextSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _run,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                'Lancer le regroupement intelligent',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) ..._buildResults(_result!),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildResults(SmartResult r) {
    return [
      for (int i = 0; i < r.groups.length; i++) ...[
        _buildGroupCard(i, r.groups[i]),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildGroupCard(int index, SmartGroup g) {
    final ration = g.ration;
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Groupe ${index + 1} — ${g.cowNames.length} vaches',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: g.cowNames
                  .map(
                    (name) => Chip(
                      label: Text(name),
                      labelStyle: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: kSurface,
                      side: const BorderSide(color: kBorderColor),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 20, color: kBorderColor),
            _kvRow('Poids moyen', '${g.avgWeightKg.toStringAsFixed(3)} kg'),
            _kvRow(
              'Lait moyen',
              '${g.avgMilkYieldKg.toStringAsFixed(2)} kg/jour',
            ),
            _kvRow(
              'Besoin NEL',
              '${g.nelReqMcal.toStringAsFixed(3)} Mcal/jour',
            ),
            _kvRow('Besoin MAT', '${g.cpReqG.toStringAsFixed(1)} g/jour'),
            const Divider(height: 20, color: kBorderColor),
            if (ration != null)
              _rationFeedRows(ration)
            else
              Text(
                'Groupe non réalisable avec ce stock.',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kErrorColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
