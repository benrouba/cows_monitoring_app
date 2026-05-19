import 'dart:math';
import '../models/cow_data.dart';
import '../models/feed.dart';

class EnergyNeeds {
  final double entretien;
  final double croissance;
  final double production;
  final double gestation;

  const EnergyNeeds({
    required this.entretien,
    required this.croissance,
    required this.production,
    required this.gestation,
  });

  double get total => entretien + croissance + production + gestation;
}

class ProteinNeeds {
  final double entretien;
  final double croissance;
  final double production;

  const ProteinNeeds({
    required this.entretien,
    required this.croissance,
    required this.production,
  });

  double get total => entretien + croissance + production;
}

class RationResult {
  final EnergyNeeds energy;
  final ProteinNeeds protein;
  final double ci;
  final List<FeedAllocation> feeds;

  const RationResult({
    required this.energy,
    required this.protein,
    required this.ci,
    required this.feeds,
  });

  double get uflCovered => feeds.fold(0.0, (s, f) => s + f.uflProvided);
  double get pdiCovered => feeds.fold(0.0, (s, f) => s + f.pdiProvided);
  double get totalMsKg  => feeds.fold(0.0, (s, f) => s + f.kgMs);

  double get energyCoverage  => energy.total  > 0 ? uflCovered / energy.total  : 0;
  double get proteinCoverage => protein.total > 0 ? pdiCovered / protein.total : 0;
}

class RationCalculator {
  // ---------- Besoins énergétiques (UFL) ----------

  static double besEntretien(double pv, double iact) =>
      0.041 * pow(pv, 0.75) * iact;

  static double besCroissance(double ageMois) =>
      3.25 - (0.018 * ageMois);

  static double besProduction(double pl, double tb, double tp) =>
      pl * (0.44 + (0.0055 * (tb - 40)) + (0.00033 * (tp - 31)));

  static double besGestation(double pvVide, double semG) {
    if (semG <= 0) return 0.0;
    return 0.00072 * pow(pvVide, 0.75) * exp(0.016 * semG);
  }

  // ---------- Besoins protéiques (g PDI) ----------

  static double besProtEntretien(double pv) => 3.25 * pow(pv, 0.75);

  static double besProtCroissance(double ageMois) => 4.22 - (0.01 * ageMois);

  static double besProtProduction(double pl, double tp) => (pl * tp) / 0.64;

  // ---------- Capacité d'ingestion (kg MS) ----------

  static double capaciteIngestion(double pv, double pl) =>
      0.022 * pv + 0.3 * pl;

  // ---------- Génération de ration ----------

  static RationResult generate(CowData cow) {
    // Energy needs
    final energy = EnergyNeeds(
      entretien:  besEntretien(cow.pv, cow.iact),
      croissance: besCroissance(cow.ageMois.toDouble()),
      production: besProduction(cow.plKgJour, cow.tb, cow.tp),
      gestation:  besGestation(cow.pvVide, cow.semG.toDouble()),
    );

    // Protein needs
    final protein = ProteinNeeds(
      entretien:  besProtEntretien(cow.pv),
      croissance: besProtCroissance(cow.ageMois.toDouble()),
      production: besProtProduction(cow.plKgJour, cow.tp),
    );

    final ci = capaciteIngestion(cow.pv, cow.plKgJour);

    // Base fourrages: 55% ensilage maïs + 15% foin de prairie
    final ensilageMs = ci * 0.55;
    final foinMs     = ci * 0.15;

    double ufCovered  = ensilageMs * Feed.ensilageMais.uflPerKgMs
                      + foinMs     * Feed.foinPrairie.uflPerKgMs;
    double pdiCovered = ensilageMs * Feed.ensilageMais.pdiePerKgMs
                      + foinMs     * Feed.foinPrairie.pdiePerKgMs;

    // Remaining concentrate budget (30% of CI)
    double concBudget = ci * 0.30;

    // Step 1 — fill protein gap with tourteau de soja (max 30% of concBudget)
    double ufGap  = energy.total  - ufCovered;
    double pdiGap = protein.total - pdiCovered;

    double sojaMs = 0.0;
    if (pdiGap > 0) {
      sojaMs = (pdiGap / Feed.tourteauSoja.pdiePerKgMs)
          .clamp(0.0, concBudget * 0.40);
      ufCovered  += sojaMs * Feed.tourteauSoja.uflPerKgMs;
      pdiCovered += sojaMs * Feed.tourteauSoja.pdiePerKgMs;
      ufGap = energy.total - ufCovered;
      concBudget -= sojaMs;
    }

    // Step 2 — fill energy gap with maïs grain
    double maisMs = 0.0;
    if (ufGap > 0) {
      maisMs = (ufGap / Feed.maisGrain.uflPerKgMs).clamp(0.0, concBudget);
    }

    final feeds = <FeedAllocation>[
      FeedAllocation(feed: Feed.ensilageMais, kgMs: ensilageMs),
      FeedAllocation(feed: Feed.foinPrairie,  kgMs: foinMs),
      if (sojaMs > 0.01)
        FeedAllocation(feed: Feed.tourteauSoja, kgMs: sojaMs),
      if (maisMs > 0.01)
        FeedAllocation(feed: Feed.maisGrain,    kgMs: maisMs),
    ];

    return RationResult(energy: energy, protein: protein, ci: ci, feeds: feeds);
  }
}
