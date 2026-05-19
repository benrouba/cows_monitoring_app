import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../repositories/cow_repository.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import 'cowProfile_screen.dart';

class CowFormScreen extends StatefulWidget {
  final String cowName;
  final CowData? existing;

  const CowFormScreen({super.key, required this.cowName, this.existing});

  @override
  State<CowFormScreen> createState() => _CowFormScreenState();
}

class _CowFormScreenState extends State<CowFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _race;
  late final TextEditingController _uidCtrl;
  late final TextEditingController _pvCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _tbCtrl;
  late final TextEditingController _tpCtrl;
  DateTime? _selectedDate;
  late double _nec;
  late int _semG;
  late bool _isGestante;
  late double _iact;
  bool _saving = false;
  bool _loadingUid = true;
  bool _uidFromTag = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _race = e?.race.isNotEmpty == true ? e!.race : 'Holstein-Frisonne';
    _uidCtrl = TextEditingController(
        text: e != null && e.id != e.name ? e.id : '');
    _fetchTagUid();
    _pvCtrl = TextEditingController(
        text: e != null && e.pv > 0 ? e.pv.toStringAsFixed(0) : '');
    _ageCtrl = TextEditingController(
        text: e != null && e.ageMois > 0 ? (e.ageMois ~/ 12).toString() : '');
    _tbCtrl = TextEditingController(text: (e?.tb ?? 40.0).toStringAsFixed(1));
    _tpCtrl = TextEditingController(text: (e?.tp ?? 32.0).toStringAsFixed(1));
    _nec = e?.nec ?? 3.0;
    _semG = e?.semG ?? 0;
    _isGestante = (e?.semG ?? 0) > 0;
    _iact = e?.iact ?? 1.1;

    // Parse existing date "DD/MM/YYYY" → DateTime
    if (e != null && e.dateNaissance != '--' && e.dateNaissance.isNotEmpty) {
      try {
        final parts = e.dateNaissance.split('/');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchTagUid() async {
    try {
      final fireData =
          await FirebaseService.instance.fetchCow(widget.cowName);
      if (fireData != null && fireData.uid.isNotEmpty && mounted) {
        setState(() {
          _uidCtrl.text = fireData.uid;
          _uidFromTag = true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingUid = false);
  }

  @override
  void dispose() {
    _uidCtrl.dispose();
    _pvCtrl.dispose();
    _ageCtrl.dispose();
    _tbCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  String get _formattedDate {
    if (_selectedDate == null) return '--';
    final d = _selectedDate!;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 4)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
            surface: kCardBg,
            onSurface: kTextPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: kPrimary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ageYears = int.tryParse(_ageCtrl.text) ?? 4;
    final pv = double.tryParse(_pvCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final tb = double.tryParse(_tbCtrl.text.replaceAll(',', '.')) ?? 40.0;
    final tp = double.tryParse(_tpCtrl.text.replaceAll(',', '.')) ?? 32.0;

    final uid = _uidCtrl.text.trim().toUpperCase();
    final cowData = CowData(
      name: widget.cowName,
      id: uid.isEmpty ? widget.cowName : uid,
      race: _race,
      dateNaissance: _formattedDate,
      pv: pv,
      nec: _nec,
      plKgJour: 0.0,
      ageMois: ageYears * 12,
      semG: _isGestante ? _semG.clamp(1, 42) : 0,
      iact: _iact,
      tb: tb,
      tp: tp,
    );

    await CowRepository.instance.saveCow(cowData);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CowProfileScreen(
          name: cowData.name,
          id: cowData.id,
          age: ageYears,
          dateNaissance: cowData.dateNaissance,
          semaineGestation: cowData.semG,
          nec: cowData.nec,
          race: cowData.race,
          laitQuotidien: '0,0 kg/jour',
          poids: cowData.pv,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          widget.cowName,
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // ── Race & Date ───────────────────────────────────────────────
            _buildSectionLabel('Race & Identification'),
            _buildRFIDField(),
            const SizedBox(height: 10),
            _buildRaceDropdown(),
            const SizedBox(height: 10),
            _buildDatePicker(),
            const SizedBox(height: 20),

            // ── Paramètres physiques ──────────────────────────────────────
            _buildSectionLabel('Paramètres Physiques'),
            _buildTextField(_pvCtrl, 'Poids vif (PV) en kg', 'ex : 550',
                required: true, numeric: true),
            const SizedBox(height: 10),
            _buildTextField(_ageCtrl, 'Âge (années)', 'ex : 4',
                required: true, numeric: true),
            const SizedBox(height: 10),
            _buildNECSlider(),
            const SizedBox(height: 20),

            // ── Reproduction ──────────────────────────────────────────────
            _buildSectionLabel('Reproduction'),
            _buildGestationCard(),
            const SizedBox(height: 20),

            // ── Paramètres lait ───────────────────────────────────────────
            _buildSectionLabel('Paramètres du Lait'),
            _buildTextField(_tbCtrl, 'Taux butyreux (TB) g/L', 'défaut : 40',
                required: false, numeric: true),
            const SizedBox(height: 10),
            _buildTextField(_tpCtrl, 'Taux protéique (TP) g/L', 'défaut : 32',
                required: false, numeric: true),
            const SizedBox(height: 20),

            // ── Activité ──────────────────────────────────────────────────
            _buildSectionLabel("Coefficient d'Activité (Iact)"),
            _buildActivitySelector(),
            const SizedBox(height: 28),

            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [kPrimary, kSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.cowName,
            style: GoogleFonts.playfairDisplay(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          'Saisissez les informations zootechniques pour calculer'
          ' la ration alimentaire optimale.',
          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70),
        ),
      ]),
    );
  }

  Widget _buildRFIDField() {
    return Container(
      decoration: BoxDecoration(
        color: _uidFromTag ? kSurface : kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _uidFromTag ? kPrimary : kBorderColor,
          width: _uidFromTag ? 1.2 : 0.8,
        ),
      ),
      child: TextFormField(
        controller: _uidCtrl,
        readOnly: _uidFromTag,
        textCapitalization: TextCapitalization.characters,
        style: GoogleFonts.nunito(
          fontSize: 15,
          color: kTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
        decoration: InputDecoration(
          labelText: 'Identifiant RFID (UID)',
          hintText: 'ex : 8B1FA004',
          labelStyle: GoogleFonts.nunito(fontSize: 13, color: kTextSecondary),
          hintStyle: GoogleFonts.nunito(
              fontSize: 12, color: kTextSecondary.withValues(alpha: 0.55)),
          prefixIcon: const Icon(Icons.nfc, color: kPrimary),
          suffixIcon: _loadingUid
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kPrimary),
                  ),
                )
              : _uidFromTag
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(Icons.verified, color: kPrimary, size: 20),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Identifiant RFID requis' : null,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
            width: 3,
            height: 18,
            color: kGold,
            margin: const EdgeInsets.only(right: 10)),
        Text(label,
            style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kPrimary)),
      ]),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint, {
    required bool required,
    bool numeric = false,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      child: TextFormField(
        controller: ctrl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: GoogleFonts.nunito(
            fontSize: 14, color: kTextPrimary, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.nunito(fontSize: 13, color: kTextSecondary),
          hintStyle: GoogleFonts.nunito(
              fontSize: 12,
              color: kTextSecondary.withValues(alpha: 0.55)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null
            : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: hasDate ? kPrimary : kBorderColor,
                width: hasDate ? 1.2 : 0.8)),
        child: Row(children: [
          Icon(Icons.calendar_month_outlined,
              color: hasDate ? kPrimary : kTextSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasDate ? _formattedDate : 'Date de naissance (optionnel)',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasDate ? kTextPrimary : kTextSecondary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: kTextSecondary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildRaceDropdown() {
    const races = [
      'Holstein-Frisonne', 'Jersey', 'Montbéliarde',
      'Normande', 'Simmental', 'Tarentaise', 'Autre',
    ];
    return Container(
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _race,
          isExpanded: true,
          style: GoogleFonts.nunito(
              fontSize: 14,
              color: kTextPrimary,
              fontWeight: FontWeight.w600),
          dropdownColor: kCardBg,
          icon: const Icon(Icons.expand_more, color: kTextSecondary),
          items: races
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _race = v ?? _race),
        ),
      ),
    );
  }

  Widget _buildNECSlider() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Note d'état corporel (NEC)",
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600)),
          Text(_nec.toStringAsFixed(1),
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kGold)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: kPrimary,
            inactiveTrackColor: kBorderColor,
            thumbColor: kPrimary,
            overlayColor: kPrimary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: _nec,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: (v) => setState(() => _nec = v),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Maigre (1)',
              style: GoogleFonts.nunito(
                  fontSize: 10, color: kTextSecondary)),
          Text('Obèse (5)',
              style: GoogleFonts.nunito(
                  fontSize: 10, color: kTextSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildGestationCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Gestante',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700)),
          Switch(
            value: _isGestante,
            activeThumbColor: kPrimary,
            activeTrackColor: kPrimary.withValues(alpha: 0.45),
            onChanged: (v) => setState(() {
              _isGestante = v;
              if (!v) {
                _semG = 0;
              } else if (_semG < 1) {
                _semG = 1;
              }
            }),
          ),
        ]),
        if (_isGestante) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Semaine de gestation',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: kTextSecondary,
                    fontWeight: FontWeight.w600)),
            Text('S$_semG',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kGold)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kSecondary,
              inactiveTrackColor: kBorderColor,
              thumbColor: kSecondary,
              overlayColor: kSecondary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _semG.toDouble(),
              min: 1,
              max: 42,
              divisions: 41,
              onChanged: (v) => setState(() => _semG = v.round()),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildActivitySelector() {
    final options = [
      (1.0, 'Stabulation entravée', Icons.home_outlined),
      (1.1, 'Stabulation libre', Icons.agriculture_outlined),
      (1.2, 'Pâturage', Icons.grass),
    ];
    return Column(
      children: options.map((opt) {
        final (val, label, icon) = opt;
        final selected = _iact == val;
        return GestureDetector(
          onTap: () => setState(() => _iact = val),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color:
                  selected ? kPrimary.withValues(alpha: 0.07) : kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? kPrimary : kBorderColor,
                  width: selected ? 1.5 : 0.8),
            ),
            child: Row(children: [
              Icon(icon,
                  color: selected ? kPrimary : kTextSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: selected ? kPrimary : kTextPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500)),
              ),
              Text('× ${val.toStringAsFixed(1)}',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selected ? kGold : kTextSecondary)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [kGold, kGoldLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: kGold.withValues(alpha: 0.40),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('Enregistrer le profil',
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
        ),
      ),
    );
  }
}
