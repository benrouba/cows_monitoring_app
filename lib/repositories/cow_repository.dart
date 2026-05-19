import 'package:shared_preferences/shared_preferences.dart';
import '../models/cow_data.dart';
import '../services/firebase_service.dart';

class CowRepository {
  static final CowRepository instance = CowRepository._();
  CowRepository._();

  final Map<String, CowData> _cache = {};

  static const List<String> knownCowNames = ['Bessie', 'Daisy', 'Molly'];

  CowData? getCached(String name) => _cache[name];

  List<CowData> get allCached => _cache.values.toList();

  // ── Initialisation ─────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Load from SharedPreferences (fast, offline)
    for (final name in knownCowNames) {
      final local = await _loadFromPrefs(name);
      if (local != null) _cache[name] = local;
    }

    // 2. Sync from Firebase in background (update cache if remote is newer)
    _syncFromFirebase();
  }

  Future<void> _syncFromFirebase() async {
    try {
      final profiles = await FirebaseService.instance.fetchAllProfiles();
      for (final entry in profiles.entries) {
        final name = entry.key;
        final remote = entry.value;
        if (remote.isComplete) {
          // Only update local if not already complete locally
          if (!(_cache[name]?.isComplete ?? false)) {
            _cache[name] = remote;
            await _saveToPrefs(remote);
          }
        }
      }
    } catch (_) {}
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> saveCow(CowData cow) async {
    _cache[cow.name] = cow;
    await _saveToPrefs(cow);                          // local first (fast)
    FirebaseService.instance.saveCowProfile(cow).ignore(); // async Firebase
  }

  // ── SharedPreferences helpers ──────────────────────────────────────────

  Future<void> _saveToPrefs(CowData cow) async {
    final prefs = await SharedPreferences.getInstance();
    final p = 'cow_${cow.name}_';
    await Future.wait([
      prefs.setString('${p}id', cow.id),
      prefs.setString('${p}race', cow.race),
      prefs.setString('${p}dateNaissance', cow.dateNaissance),
      prefs.setDouble('${p}pv', cow.pv),
      prefs.setDouble('${p}nec', cow.nec),
      prefs.setInt('${p}ageMois', cow.ageMois),
      prefs.setInt('${p}semG', cow.semG),
      prefs.setDouble('${p}iact', cow.iact),
      prefs.setDouble('${p}tb', cow.tb),
      prefs.setDouble('${p}tp', cow.tp),
    ]);
  }

  Future<CowData?> _loadFromPrefs(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final p = 'cow_${name}_';
    final pv = prefs.getDouble('${p}pv');
    if (pv == null || pv <= 0) return null;
    return CowData(
      name: name,
      id: prefs.getString('${p}id') ?? name,
      race: prefs.getString('${p}race') ?? '',
      dateNaissance: prefs.getString('${p}dateNaissance') ?? '--',
      pv: pv,
      nec: prefs.getDouble('${p}nec') ?? 3.0,
      ageMois: prefs.getInt('${p}ageMois') ?? 48,
      semG: prefs.getInt('${p}semG') ?? 0,
      iact: prefs.getDouble('${p}iact') ?? 1.1,
      tb: prefs.getDouble('${p}tb') ?? 40.0,
      tp: prefs.getDouble('${p}tp') ?? 32.0,
      plKgJour: 0.0,
    );
  }
}
