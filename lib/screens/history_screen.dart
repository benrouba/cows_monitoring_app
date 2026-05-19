import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<SessionData> _sessions = [];
  Map<String, CowFirebaseData> _cows = {};
  bool _loading = true;
  bool _hasError = false;

  // Which date sections are expanded (today is expanded by default)
  final Set<String> _expandedDates = {};

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Last 7 days sorted descending, only dates that have sessions
  List<String> get _sortedDates {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final map = _groupedByDate;
    final dates = map.keys.where((d) {
      try {
        final parsed = DateTime.parse(d);
        return !parsed.isBefore(cutoff);
      } catch (_) {
        return true; // keep entries with unparseable dates
      }
    }).toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  // date → cow → sessions
  Map<String, Map<String, List<SessionData>>> get _groupedByDate {
    final map = <String, Map<String, List<SessionData>>>{};
    for (final s in _sessions) {
      final key = s.date.isNotEmpty ? s.date : 'Date inconnue';
      map.putIfAbsent(key, () => {}).putIfAbsent(s.cow, () => []).add(s);
    }
    for (final cowMap in map.values) {
      for (final list in cowMap.values) {
        list.sort((a, b) => a.sessionNum.compareTo(b.sessionNum));
      }
    }
    return map;
  }

  double get _totalMilkToday =>
      _cows.values.fold(0.0, (s, c) => s + c.dailyMilkKg);

  int get _totalSessionsToday =>
      _cows.values.fold(0, (s, c) => s + c.sessionsToday);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        FirebaseService.instance.fetchSessions(),
        FirebaseService.instance.fetchAllCows(),
      ]);
      if (!mounted) return;
      setState(() {
        _sessions = results[0] as List<SessionData>;
        _cows = results[1] as Map<String, CowFirebaseData>;
        _loading = false;
        // Today is expanded by default
        _expandedDates.add(_todayKey);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
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

          if (_loading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: kPrimary),
              ),
            ),
          ] else if (_hasError) ...[
            _buildErrorState(),
          ] else if (_sessions.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            _buildSectionTitle('Historique des séances', Icons.history_outlined),
            const SizedBox(height: 12),
            for (final date in _sortedDates)
              _buildDaySection(date),
          ],
        ],
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────
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
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _loading ? 'Chargement…' : '${_totalMilkToday.toStringAsFixed(2)} kg',
          style: GoogleFonts.playfairDisplay(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text("production laitière aujourd'hui",
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _badge(Icons.pets, '${_cows.length} vaches'),
          _badge(Icons.schedule_outlined, '$_totalSessionsToday séances auj.'),
          _badge(Icons.list_alt_outlined, '${_sessions.length} enregistrements'),
        ]),
      ]),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: kGold, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.playfairDisplay(
              fontSize: 16, fontWeight: FontWeight.w600, color: kPrimary)),
    ]);
  }

  // ── Collapsible day section ───────────────────────────────────────────────
  Widget _buildDaySection(String date) {
    final isToday = date == _todayKey;
    final isExpanded = _expandedDates.contains(date);
    final cowMap = _groupedByDate[date]!;
    final totalMilk =
        cowMap.values.expand((l) => l).fold(0.0, (s, sess) => s + sess.milkKg);
    final totalSessions =
        cowMap.values.fold(0, (s, l) => s + l.length);

    String dateLabel;
    if (isToday) {
      dateLabel = "Aujourd'hui";
    } else {
      try {
        final d = DateTime.parse(date);
        const months = [
          '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
          'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
        ];
        dateLabel = '${d.day} ${months[d.month]} ${d.year}';
      } catch (_) {
        dateLabel = date;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isToday
                ? kPrimary.withValues(alpha: 0.40)
                : kBorderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // ── Day header (tap to toggle) ─────────────────────────────────
            InkWell(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedDates.remove(date);
                } else {
                  _expandedDates.add(date);
                }
              }),
              child: Container(
                color: isToday
                    ? kPrimary.withValues(alpha: 0.07)
                    : kSurface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Icon(
                    isToday ? Icons.today : Icons.calendar_month_outlined,
                    color: isToday ? kPrimary : kTextSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateLabel,
                            style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isToday ? kPrimary : kTextPrimary)),
                        Text(
                          '$totalSessions séance(s) · ${cowMap.length} vache(s)',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text('${totalMilk.toStringAsFixed(2)} kg',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kGold)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: kTextSecondary, size: 20),
                  ),
                ]),
              ),
            ),

            // ── Expanded content: one card per cow ────────────────────────
            if (isExpanded) ...[
              const Divider(height: 1, color: kBorderColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  children: cowMap.entries
                      .map((e) => _buildCowGroup(e))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Per-cow group ─────────────────────────────────────────────────────────
  Widget _buildCowGroup(MapEntry<String, List<SessionData>> entry) {
    final cowName = entry.key;
    final sessions = entry.value;
    final cowData = _cows[cowName];
    final totalMilk = sessions.fold(0.0, (s, sess) => s + sess.milkKg);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Cow header
            Container(
              color: kSurface,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: kCardBg, shape: BoxShape.circle),
                  child: const Icon(Icons.pets, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cowName,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary)),
                      Text(
                          () {
                            final uid = cowData?.uid.isNotEmpty == true
                                ? cowData!.uid
                                : sessions.firstOrNull?.uid ?? '';
                            return 'RFID : ${uid.isNotEmpty ? uid : "—"}';
                          }(),
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: kTextSecondary),
                        ),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${totalMilk.toStringAsFixed(2)} kg',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kGold)),
                  Text('${sessions.length} séance(s)',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: kTextSecondary)),
                ]),
              ]),
            ),
            const Divider(height: 1, color: kBorderColor),

            // Session rows
            ...sessions.asMap().entries.map((e) {
              final i = e.key;
              final sess = e.value;
              return Column(children: [
                _buildSessionRow(sess),
                if (i < sessions.length - 1)
                  const Divider(height: 1, color: kBorderColor),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow(SessionData sess) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.10),
              shape: BoxShape.circle),
          child: Center(
            child: Text('${sess.sessionNum}',
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: kPrimary)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Séance n° ${sess.sessionNum}',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary)),
              Text(sess.time,
                  style:
                      GoogleFonts.nunito(fontSize: 12, color: kTextSecondary)),
            ],
          ),
        ),
        Row(children: [
          const Icon(Icons.water_drop, color: kSecondary, size: 15),
          const SizedBox(width: 4),
          Text('${sess.milkKg.toStringAsFixed(3)} kg',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: kGold)),
        ]),
      ]),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Column(children: [
        Icon(Icons.inbox_outlined, size: 64, color: kBorderColor),
        const SizedBox(height: 16),
        Text('Aucune séance enregistrée',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, color: kTextSecondary)),
        const SizedBox(height: 8),
        Text('Tirez vers le bas pour rafraîchir',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: kTextSecondary,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Column(children: [
        Icon(Icons.wifi_off_outlined, size: 64, color: kBorderColor),
        const SizedBox(height: 16),
        Text('Connexion Firebase impossible',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, color: kTextSecondary)),
        const SizedBox(height: 8),
        Text('Vérifiez votre connexion internet',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: kTextSecondary,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: Text('Réessayer',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
