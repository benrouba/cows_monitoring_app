import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cow_data.dart';

// ── Milk session from Firebase ─────────────────────────────────────────────

class SessionData {
  final String id;
  final String cow;
  final String uid;
  final double milkKg;
  final int sessionNum;
  final String time;
  final String date; // comes from the path key, not the JSON body

  const SessionData({
    required this.id,
    required this.cow,
    required this.uid,
    required this.milkKg,
    required this.sessionNum,
    required this.time,
    required this.date,
  });

  // date is passed explicitly because it lives in the path, not the JSON body
  factory SessionData.fromJson(
      String id, String date, Map<String, dynamic> json) {
    return SessionData(
      id: id,
      date: date,
      cow: json['cow']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      milkKg: (json['milk_kg'] as num?)?.toDouble() ?? 0.0,
      sessionNum: (json['session_num'] as num?)?.toInt() ?? 1,
      time: json['time']?.toString() ?? '--',
    );
  }
}

// ── Daily cow data from Firebase ──────────────────────────────────────────

class CowFirebaseData {
  final String uid;
  final double dailyMilkKg;
  final int sessionsToday; // JSON key is 'sessions'
  final String lastUpdated;

  const CowFirebaseData({
    required this.uid,
    required this.dailyMilkKg,
    required this.sessionsToday,
    required this.lastUpdated,
  });

  // Reads from /cows/{name}/history/{date} node
  factory CowFirebaseData.fromJson(Map<String, dynamic> json) {
    return CowFirebaseData(
      uid: json['uid']?.toString() ?? '',
      dailyMilkKg: (json['daily_milk_kg'] as num?)?.toDouble() ?? 0.0,
      sessionsToday: (json['sessions'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated']?.toString() ?? '--',
    );
  }
}

// ── Service ────────────────────────────────────────────────────────────────

class FirebaseService {
  static const FirebaseService instance = FirebaseService._();
  const FirebaseService._();

  static const _base =
      'https://cow-milk-system-default-rtdb.europe-west1.firebasedatabase.app';

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ── Milk data (read) ─────────────────────────────────────────────────────

  // Fetches today's history entry for a single cow.
  Future<CowFirebaseData?> fetchCow(String cowName) async {
    try {
      final uri =
          Uri.parse('$_base/cows/$cowName/history/$_todayKey.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          return CowFirebaseData.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  // Fetches today's history entry for every cow.
  // Structure: /cows/{name}/history/{date} → CowFirebaseData
  Future<Map<String, CowFirebaseData>> fetchAllCows() async {
    try {
      final today = _todayKey;
      final uri = Uri.parse('$_base/cows.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          final result = <String, CowFirebaseData>{};
          for (final entry in data.entries) {
            final cowName = entry.key;
            final cowNode = entry.value;
            if (cowNode is! Map<String, dynamic>) continue;
            final history = cowNode['history'];
            if (history is! Map<String, dynamic>) continue;
            final todayData = history[today];
            if (todayData is Map<String, dynamic>) {
              result[cowName] = CowFirebaseData.fromJson(todayData);
            }
          }
          return result;
        }
      }
    } catch (_) {}
    return {};
  }

  // ── Session history (read) ───────────────────────────────────────────────

  // Fetches all sessions. Structure: /sessions/{date}/{session_id} → SessionData
  Future<List<SessionData>> fetchSessions() async {
    try {
      final uri = Uri.parse('$_base/sessions.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          final list = <SessionData>[];
          for (final dateEntry in data.entries) {
            final date = dateEntry.key;
            final sessionsOnDate = dateEntry.value;
            if (sessionsOnDate is! Map<String, dynamic>) continue;
            for (final sessEntry in sessionsOnDate.entries) {
              if (sessEntry.value is Map<String, dynamic>) {
                list.add(SessionData.fromJson(
                  sessEntry.key,
                  date,
                  sessEntry.value as Map<String, dynamic>,
                ));
              }
            }
          }
          list.sort((a, b) => a.time.compareTo(b.time));
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  // ── Cow profiles (read / write) ──────────────────────────────────────────

  Future<void> saveCowProfile(CowData cow) async {
    try {
      final uri = Uri.parse('$_base/profiles/${cow.name}.json');
      await http
          .put(
            uri,
            body: jsonEncode({
              'id': cow.id,
              'race': cow.race,
              'dateNaissance': cow.dateNaissance,
              'pv': cow.pv,
              'nec': cow.nec,
              'ageMois': cow.ageMois,
              'semG': cow.semG,
              'iact': cow.iact,
              'tb': cow.tb,
              'tp': cow.tp,
            }),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<CowData?> fetchProfile(String name) async {
    try {
      final uri = Uri.parse('$_base/profiles/$name.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          return _profileFromJson(name, data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, CowData>> fetchAllProfiles() async {
    try {
      final uri = Uri.parse('$_base/profiles.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          return {
            for (final e in data.entries)
              if (e.value is Map<String, dynamic>)
                e.key: _profileFromJson(e.key, e.value as Map<String, dynamic>)
          };
        }
      }
    } catch (_) {}
    return {};
  }

  CowData _profileFromJson(String name, Map<String, dynamic> j) {
    return CowData(
      name: name,
      id: j['id']?.toString() ?? name,
      race: j['race']?.toString() ?? '',
      dateNaissance: j['dateNaissance']?.toString() ?? '--',
      pv: (j['pv'] as num?)?.toDouble() ?? 0.0,
      nec: (j['nec'] as num?)?.toDouble() ?? 3.0,
      ageMois: (j['ageMois'] as num?)?.toInt() ?? 48,
      semG: (j['semG'] as num?)?.toInt() ?? 0,
      iact: (j['iact'] as num?)?.toDouble() ?? 1.1,
      tb: (j['tb'] as num?)?.toDouble() ?? 40.0,
      tp: (j['tp'] as num?)?.toDouble() ?? 32.0,
      plKgJour: 0.0,
    );
  }
}
