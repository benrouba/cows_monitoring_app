import 'package:shared_preferences/shared_preferences.dart';
import '../models/cow_data.dart';
import '../services/firebase_service.dart';

class CowRepository {
  static final CowRepository instance = CowRepository._();
  CowRepository._();

  final Map<String, CowData> _cache = {};

  CowData? getCached(String name) => _cache[name];
  List<CowData> get allCached => _cache.values.toList();
  List<String> get cowNames => List.unmodifiable(_cache.keys.toList());

  // ── Initialisation ─────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Load saved cow names list from SharedPreferences (fast, offline)
    final savedNames = await _loadCowNamesList();
    for (final name in savedNames) {
      _cache[name] = await _loadFromPrefs(name);
    }

    // 2. Sync from Firebase in background (may discover new cows)
    _syncFromFirebase();
  }

  Future<void> _syncFromFirebase() async {
    try {
      final profiles = await FirebaseService.instance.fetchAllProfiles();
      bool changed = false;
      for (final entry in profiles.entries) {
        final name = entry.key;
        final remote = entry.value;
        if (!_cache.containsKey(name)) {
          _cache[name] = remote;
          changed = true;
        } else if (remote.isComplete && !(_cache[name]!.isComplete)) {
          _cache[name] = remote;
          await _saveToPrefs(remote);
          changed = true;
        }
      }
      if (changed) {
        await _saveCowNamesList(_cache.keys.toList());
      }
    } catch (_) {}
  }

  // ── Save ───────────────────────────────────────────────────────────────

  Future<void> saveCow(CowData cow) async {
    _cache[cow.name] = cow;
    await _saveCowNamesList(_cache.keys.toList());
    await _saveToPrefs(cow);
    FirebaseService.instance.saveCowProfile(cow).ignore();
  }

  // ── Cow names list helpers ─────────────────────────────────────────────

  Future<List<String>> _loadCowNamesList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cow_names_list') ?? '';
    if (raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> _saveCowNamesList(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cow_names_list', names.join(','));
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

  Future<CowData> _loadFromPrefs(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final p = 'cow_${name}_';
    return CowData(
      name: name,
      id: prefs.getString('${p}id') ?? name,
      race: prefs.getString('${p}race') ?? '',
      dateNaissance: prefs.getString('${p}dateNaissance') ?? '--',
      pv: prefs.getDouble('${p}pv') ?? 0.0,
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
