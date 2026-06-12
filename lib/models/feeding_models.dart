// feeding_models.dart — corrected to match server JSON exactly

// ── Cow data sent to server ────────────────────────────────────────────────
class FeedingCow {
  final String name;
  final Map<String, dynamic> profile;
  final double milkYieldKg;

  const FeedingCow({
    required this.name,
    required this.profile,
    required this.milkYieldKg,
  });

  double get pv => _toDouble(profile['pv']);
  double get nec => _toDouble(profile['nec']);
  int get semG => _toDouble(profile['semG']).round();
  double get tb => _toDouble(profile['tb']);
  double get tp => _toDouble(profile['tp']);
  double get iact => _toDouble(profile['iact']);
  int get ageMois => _toDouble(profile['ageMois']).round();
  String get race => profile['race']?.toString() ?? '';
  String get id => profile['id']?.toString() ?? '';

  Map<String, dynamic> toJson() => {
    'name': name,
    'profile': profile,
    'milk_yield_kg': milkYieldKg,
  };

  static double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── Ration result from optimize_ration() ──────────────────────────────────
// Server always returns this structure:
// {
//   "cost_usd_per_day": X,
//   "dmi_kg": X,
//   "ration_kg": { "straw": X, "treated_straw": X, "barley": X, "concentrate": X },
//   "nel_coverage_pct": X,
//   "cp_coverage_pct": X
// }
class RationResult {
  final double costUsdPerDay;
  final double dmiKg;
  final double strawKg;
  final double treatedStrawKg;
  final double barleyKg;
  final double concentrateKg;
  final double nelCoveragePct;
  final double cpCoveragePct;

  const RationResult({
    required this.costUsdPerDay,
    required this.dmiKg,
    required this.strawKg,
    required this.treatedStrawKg,
    required this.barleyKg,
    required this.concentrateKg,
    required this.nelCoveragePct,
    required this.cpCoveragePct,
  });

  // Parses the direct output of optimize_ration on the server
  factory RationResult.fromJson(Map<String, dynamic> j) {
    final kg = (j['ration_kg'] as Map<String, dynamic>?) ?? {};
    return RationResult(
      costUsdPerDay: _d(j['cost_usd_per_day']),
      dmiKg: _d(j['dmi_kg']),
      strawKg: _d(kg['straw']),
      treatedStrawKg: _d(kg['treated_straw']),
      barleyKg: _d(kg['barley']),
      concentrateKg: _d(kg['concentrate']),
      nelCoveragePct: _d(j['nel_coverage_pct']),
      cpCoveragePct: _d(j['cp_coverage_pct']),
    );
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── POST /feeding/individual response ──────────────────────────────────────
// Server returns requirements fields directly:
// {
//   "requirements": {
//     "nel_req_mcal": X,
//     "nel_maint": X,
//     "nel_milk": X,
//     "nel_gest": X,
//     "cp_req_g": X
//   },
//   "cost_usd_per_day": X,   ← at top level (spread from optimize_ration)
//   "dmi_kg": X,
//   "ration_kg": { ... },
//   "nel_coverage_pct": X,
//   "cp_coverage_pct": X
// }
class IndividualRationResult {
  final double nelTotal;
  final double nelMaint;
  final double nelMilk;
  final double nelGest;
  final double cpReqG;
  final RationResult ration;

  const IndividualRationResult({
    required this.nelTotal,
    required this.nelMaint,
    required this.nelMilk,
    required this.nelGest,
    required this.cpReqG,
    required this.ration,
  });

  factory IndividualRationResult.fromJson(Map<String, dynamic> j) {
    final req = (j['requirements'] as Map<String, dynamic>?) ?? {};
    return IndividualRationResult(
      nelTotal: _d(req['nel_req_mcal']),
      nelMaint: _d(req['nel_maint']),
      nelMilk: _d(req['nel_milk']),
      nelGest: _d(req['nel_gest']),
      cpReqG: _d(req['cp_req_g']),
      ration: RationResult.fromJson(j), // top-level j has ration_kg, dmi_kg etc
    );
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── Stock usage entry (group feeding) ─────────────────────────────────────
class StockUsageEntry {
  final double usedKg;
  final double remainingKg;
  final double usedPct;

  const StockUsageEntry({
    required this.usedKg,
    required this.remainingKg,
    required this.usedPct,
  });
}

// ── POST /feeding/group response ──────────────────────────────────────────
// Server returns:
// {
//   "ration_per_cow": { cost_usd_per_day, dmi_kg, ration_kg: {...}, ... },
//   "total_daily_cost_usd": X,
//   "n_cows": X,
//   "stock_used_kg":      { straw, treated_straw, barley, concentrate },
//   "stock_remaining_kg": { straw, treated_straw, barley, concentrate },
//   "stock_used_pct":     { straw, treated_straw, barley, concentrate }
// }
class GroupRationResult {
  final int nCows;
  final double avgWeightKg;
  final double avgNelReq;
  final double avgCpReq;
  final RationResult rationPerCow;
  final double totalDailyCostUsd;
  final Map<String, StockUsageEntry> stockUsage;

  const GroupRationResult({
    required this.nCows,
    required this.avgWeightKg,
    required this.avgNelReq,
    required this.avgCpReq,
    required this.rationPerCow,
    required this.totalDailyCostUsd,
    required this.stockUsage,
  });

  factory GroupRationResult.fromJson(Map<String, dynamic> j) {
    // Ration is nested under 'ration_per_cow'
    final rationJson = (j['ration_per_cow'] as Map<String, dynamic>?) ?? {};

    // Stock usage comes as THREE separate maps — combine them
    final usedKg = (j['stock_used_kg'] as Map<String, dynamic>?) ?? {};
    final remainingKg =
        (j['stock_remaining_kg'] as Map<String, dynamic>?) ?? {};
    final usedPct = (j['stock_used_pct'] as Map<String, dynamic>?) ?? {};

    const feeds = ['straw', 'treated_straw', 'barley', 'concentrate'];
    final stockUsage = <String, StockUsageEntry>{
      for (final f in feeds)
        f: StockUsageEntry(
          usedKg: _d(usedKg[f]),
          remainingKg: _d(remainingKg[f]),
          usedPct: _d(usedPct[f]),
        ),
    };

    return GroupRationResult(
      nCows: (j['n_cows'] as num?)?.toInt() ?? 0,
      avgWeightKg: _d(j['avg_weight_kg']),
      avgNelReq: _d(j['avg_nel_req_mcal']),
      avgCpReq: _d(j['avg_cp_req_g']),
      rationPerCow: RationResult.fromJson(rationJson),
      totalDailyCostUsd: _d(j['total_daily_cost_usd']),
      stockUsage: stockUsage,
    );
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── POST /feeding/smart — single group ────────────────────────────────────
// Server returns each group as:
// {
//   "group_id": X,
//   "n_cows": X,
//   "cows": ["Bessie", "Daisy"],         ← NOT cow_names
//   "avg_weight_kg": X,
//   "avg_milk_yield_kg": X,              ← NOT avg_milk_kg
//   "nel_req_mcal": X,                   ← NOT nel_requirement
//   "cp_req_g": X,                       ← NOT cp_requirement
//   "ration": { cost_usd_per_day, dmi_kg, ration_kg: {...}, ... },
//   "feasible": true
// }
class SmartGroup {
  final int groupId;
  final List<String> cowNames;
  final double avgWeightKg;
  final double avgMilkYieldKg;
  final double nelReqMcal;
  final double cpReqG;
  final RationResult? ration;
  final bool feasible;

  const SmartGroup({
    required this.groupId,
    required this.cowNames,
    required this.avgWeightKg,
    required this.avgMilkYieldKg,
    required this.nelReqMcal,
    required this.cpReqG,
    required this.ration,
    required this.feasible,
  });

  factory SmartGroup.fromJson(Map<String, dynamic> j) {
    final rationJson = j['ration'] as Map<String, dynamic>?;
    return SmartGroup(
      groupId: (j['group_id'] as num?)?.toInt() ?? 0,
      cowNames: ((j['cows'] as List?) ?? []).map((e) => e.toString()).toList(),
      avgWeightKg: _d(j['avg_weight_kg']),
      avgMilkYieldKg: _d(j['avg_milk_yield_kg']),
      nelReqMcal: _d(j['nel_req_mcal']),
      cpReqG: _d(j['cp_req_g']),
      ration: rationJson != null ? RationResult.fromJson(rationJson) : null,
      feasible: (j['feasible'] as bool?) ?? false,
    );
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── POST /feeding/smart response ──────────────────────────────────────────
class SmartResult {
  final int nGroupsFormed;
  final int nCows;
  final List<SmartGroup> groups;
  final double totalDailyCostUsd;
  final double avgCostPerCowUsd;

  const SmartResult({
    required this.nGroupsFormed,
    required this.nCows,
    required this.groups,
    required this.totalDailyCostUsd,
    required this.avgCostPerCowUsd,
  });

  factory SmartResult.fromJson(Map<String, dynamic> j) => SmartResult(
    nGroupsFormed: (j['n_groups_formed'] as num?)?.toInt() ?? 0,
    nCows: (j['n_cows'] as num?)?.toInt() ?? 0,
    groups: ((j['groups'] as List?) ?? [])
        .map((e) => SmartGroup.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalDailyCostUsd: _d(j['total_daily_cost_usd']),
    avgCostPerCowUsd: _d(j['avg_cost_per_cow_usd']),
  );

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
}
