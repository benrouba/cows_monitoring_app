class Feed {
  final String key;
  final String label;
  final double uflPerKgMs;   // UFL per kg dry matter
  final double pdiePerKgMs;  // g PDIE per kg DM
  final double pdinPerKgMs;  // g PDIN per kg DM
  final double msRatio;      // DM fraction 0.0–1.0
  final bool isFourrage;

  const Feed({
    required this.key,
    required this.label,
    required this.uflPerKgMs,
    required this.pdiePerKgMs,
    required this.pdinPerKgMs,
    required this.msRatio,
    required this.isFourrage,
  });

  double msToFreshKg(double kgMs) => kgMs / msRatio;
  double freshToMs(double freshKg) => freshKg * msRatio;

  static const foinPrairie = Feed(
    key: 'foinPrairie',
    label: 'Foin de prairie',
    uflPerKgMs: 0.65,
    pdiePerKgMs: 72,
    pdinPerKgMs: 67,
    msRatio: 0.85,
    isFourrage: true,
  );

  static const ensilageMais = Feed(
    key: 'ensilageMais',
    label: 'Ensilage de maïs',
    uflPerKgMs: 0.92,
    pdiePerKgMs: 64,
    pdinPerKgMs: 58,
    msRatio: 0.32,
    isFourrage: true,
  );

  static const ensilageHerbe = Feed(
    key: 'ensilageHerbe',
    label: "Ensilage d'herbe",
    uflPerKgMs: 0.80,
    pdiePerKgMs: 95,
    pdinPerKgMs: 102,
    msRatio: 0.30,
    isFourrage: true,
  );

  static const orge = Feed(
    key: 'orge',
    label: 'Orge',
    uflPerKgMs: 1.10,
    pdiePerKgMs: 90,
    pdinPerKgMs: 91,
    msRatio: 0.87,
    isFourrage: false,
  );

  static const maisGrain = Feed(
    key: 'maisGrain',
    label: 'Maïs grain',
    uflPerKgMs: 1.13,
    pdiePerKgMs: 80,
    pdinPerKgMs: 74,
    msRatio: 0.86,
    isFourrage: false,
  );

  static const tourteauSoja = Feed(
    key: 'tourteauSoja',
    label: 'Tourteau de soja 48%',
    uflPerKgMs: 1.10,
    pdiePerKgMs: 290,
    pdinPerKgMs: 324,
    msRatio: 0.88,
    isFourrage: false,
  );

  static const tourteauColza = Feed(
    key: 'tourteauColza',
    label: 'Tourteau de colza',
    uflPerKgMs: 1.05,
    pdiePerKgMs: 235,
    pdinPerKgMs: 220,
    msRatio: 0.88,
    isFourrage: false,
  );
}

class FeedAllocation {
  final Feed feed;
  final double kgMs;

  const FeedAllocation({required this.feed, required this.kgMs});

  double get uflProvided => kgMs * feed.uflPerKgMs;
  double get pdiProvided => kgMs * feed.pdiePerKgMs;
  double get kgFrais => feed.msToFreshKg(kgMs);
}
