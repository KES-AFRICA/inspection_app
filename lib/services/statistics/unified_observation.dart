// lib/services/statistics/unified_observation.dart

enum AuditSourceCategory {
  moyenneTensionLocal,
  moyenneTensionZone,
  basseTensionZone,
  basseTensionLocal,
  groupeElectrogene,
  equipement,
  cellule,
  transformateur,
  foudre,
  autre,
}

enum AuditTableType {
  dispositionsConstructives,
  conditionsExploitation,
  celluleElements,
  transformateurElements,
  pointsVerification,
  observationsLibres,
  observationsParafoudre,
  foudre,
}

enum CriticalityLevel {
  none,      // Non spécifiée (ex: remarques libres ou points sans niveau de priorité)
  mineure,   // Niveau 1 / Mineur / Mineure
  majeure,   // Niveau 2 / Majeur / Majeure
  critique,  // Niveau 3 / Critique
}

class UnifiedObservation {
  final String id;
  final String missionId;
  final String localisation;        // Nom du local ou de la zone
  final String? batiment;            // Bâtiment si disponible
  final String? zoneNom;             // Zone parente si disponible
  final String itemNom;              // Nom du point contrôlé ou du coffret/équipement
  final String texteObservation;     // Libellé complet de l'observation
  final CriticalityLevel criticite;  // None, Mineure, Majeure, Critique
  final int? prioriteInt;            // 1, 2, 3 ou null
  final String? referenceNormative;  // Référence normative effective
  final String? familleRisque;       // Famille de risque effective
  final AuditSourceCategory sourceCategory;
  final AuditTableType tableType;
  final String typeObjet;            // Local, Cellule, Transformateur, GE, TGBT, Armoire, Coffret, Inverseur, etc.
  final String? repere;              // Repère équipement ou QR code
  final List<String> photos;

  UnifiedObservation({
    required this.id,
    required this.missionId,
    required this.localisation,
    this.batiment,
    this.zoneNom,
    required this.itemNom,
    required this.texteObservation,
    required this.criticite,
    this.prioriteInt,
    this.referenceNormative,
    this.familleRisque,
    required this.sourceCategory,
    required this.tableType,
    required this.typeObjet,
    this.repere,
    List<String>? photos,
  }) : photos = photos ?? [];

  static CriticalityLevel intToCriticality(int? priority) {
    if (priority == 3) return CriticalityLevel.critique;
    if (priority == 2) return CriticalityLevel.majeure;
    if (priority == 1) return CriticalityLevel.mineure;
    return CriticalityLevel.none;
  }

  static CriticalityLevel stringToCriticality(String? str) {
    if (str == null) return CriticalityLevel.none;
    final s = str.trim().toLowerCase();
    if (s == '3' || s.contains('critique')) return CriticalityLevel.critique;
    if (s == '2' || s.contains('majeur')) return CriticalityLevel.majeure;
    if (s == '1' || s.contains('mineur')) return CriticalityLevel.mineure;
    return CriticalityLevel.none;
  }
}
