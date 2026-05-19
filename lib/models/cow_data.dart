class CowData {
  final String name;
  final String id;
  final String race;
  final String dateNaissance;
  final double pv;        // poids vif kg
  final double nec;       // note d'état corporel
  final double plKgJour;  // production laitière kg/j
  final double iact;      // coefficient activité: 1.0 / 1.1 / 1.2
  final double tb;        // taux butyreux g/L
  final double tp;        // taux protéique g/L
  final int ageMois;      // âge en mois
  final int semG;         // semaine de gestation (0 = non gestante)

  const CowData({
    required this.name,
    required this.id,
    required this.race,
    required this.dateNaissance,
    required this.pv,
    required this.nec,
    required this.plKgJour,
    required this.ageMois,
    required this.semG,
    this.iact = 1.1,
    this.tb = 40.0,
    this.tp = 32.0,
  });

  double get pvVide => pv * 0.87;

  bool get isComplete => pv > 0 && race.isNotEmpty;

  CowData copyWith({
    double? plKgJour,
    double? iact,
    double? tb,
    double? tp,
  }) {
    return CowData(
      name: name,
      id: id,
      race: race,
      dateNaissance: dateNaissance,
      pv: pv,
      nec: nec,
      plKgJour: plKgJour ?? this.plKgJour,
      ageMois: ageMois,
      semG: semG,
      iact: iact ?? this.iact,
      tb: tb ?? this.tb,
      tp: tp ?? this.tp,
    );
  }

  /// Parses "18,5 L/jour" or "20.5" → 18.5
  static double parseLait(String s) {
    final clean = s
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }
}
