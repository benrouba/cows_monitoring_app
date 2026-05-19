import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cow_data.dart';
import '../repositories/cow_repository.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import 'cow_form_screen.dart';
import 'cowProfile_screen.dart';

class CowsScreen extends StatefulWidget {
  const CowsScreen({super.key});

  @override
  State<CowsScreen> createState() => _CowsScreenState();
}

class _CowsScreenState extends State<CowsScreen> {
  Map<String, CowFirebaseData> _fireData = {};
  List<String> _cowNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cowNames = CowRepository.instance.cowNames.toList();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    Map<String, CowFirebaseData> liveData = {};
    Map<String, CowData> profiles = {};
    await Future.wait([
      FirebaseService.instance.fetchAllCows().then((d) => liveData = d),
      FirebaseService.instance.fetchAllProfiles().then((p) => profiles = p),
    ]);
    final names = <String>{
      ...CowRepository.instance.cowNames,
      ...liveData.keys,
      ...profiles.keys,
    }.toList()..sort();
    if (mounted) {
      setState(() {
        _fireData = liveData;
        _cowNames = names;
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
          _buildHeader(),
          const SizedBox(height: 16),
          ..._cowNames.map(_buildCowCard),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
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
            color: kPrimary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre Troupeau',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cowNames.length} vaches · Touchez pour saisir le profil',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          FaIcon(
            FontAwesomeIcons.cow,
            color: Colors.white.withValues(alpha: 0.30),
            size: 40,
          ),
        ],
      ),
    );
  }

  // ── Cow card ──────────────────────────────────────────────────────────────
  Widget _buildCowCard(String name) {
    final fireData = _fireData[name];
    final cowData = CowRepository.instance.getCached(name);
    final hasProfile = cowData != null && cowData.isComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _onCowTap(name, cowData, fireData, hasProfile),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 82,
                color: hasProfile ? kPrimary : kGold,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: hasProfile
                              ? kSurface
                              : kGoldLight.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.cow,
                            size: 22,
                            color: hasProfile ? kPrimary : kGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (hasProfile)
                              Text(
                                '${cowData.race} · ${cowData.pv.toStringAsFixed(0)} kg'
                                ' · ${cowData.ageMois ~/ 12} ans',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: kTextSecondary,
                                ),
                              )
                            else
                              Row(
                                children: [
                                  const Icon(Icons.edit_note,
                                      size: 13, color: kGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Saisir le profil zootechnique',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: kGold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Live milk value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimary),
                            )
                          else if (fireData != null)
                            Text(
                              '${fireData.dailyMilkKg.toStringAsFixed(2)} kg',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kGold,
                              ),
                            )
                          else
                            Text(
                              '--',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: kTextSecondary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            'lait/j',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        hasProfile ? Icons.chevron_right : Icons.arrow_forward,
                        color: kTextSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCowTap(
    String name,
    dynamic cowData,
    CowFirebaseData? fireData,
    bool hasProfile,
  ) {
    if (hasProfile) {
      final milk = fireData != null
          ? '${fireData.dailyMilkKg.toStringAsFixed(2)} kg/jour'
          : '${cowData.plKgJour.toStringAsFixed(1)} kg/jour';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CowProfileScreen(
            name: cowData.name,
            id: cowData.id,
            age: cowData.ageMois ~/ 12,
            dateNaissance: cowData.dateNaissance,
            semaineGestation: cowData.semG,
            nec: cowData.nec,
            race: cowData.race,
            laitQuotidien: milk,
            poids: cowData.pv,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CowFormScreen(cowName: name),
        ),
      ).then((_) => setState(() {})); // refresh after profile saved
    }
  }
}
