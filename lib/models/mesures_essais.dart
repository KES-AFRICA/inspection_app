// mesures_essais.dart
import 'package:hive/hive.dart';

part 'mesures_essais.g.dart';

@HiveType(typeId: 16)
class MesuresEssais extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  DateTime updatedAt;

  // ================= SECTION 1: CONDITIONS DE MESURE =================
  @HiveField(2)
  ConditionMesure conditionMesure;

  // ================= SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE =================
  @HiveField(3)
  EssaiDemarrageAuto essaiDemarrageAuto;

  // ================= SECTION 3: TEST D'ARRÊT D'URGENCE =================
  @HiveField(4)
  TestArretUrgence testArretUrgence;

  // ================= SECTION 4: PRISES DE TERRE =================
  @HiveField(5)
  List<PriseTerre> prisesTerre;

  // ================= SECTION 5: AVIS SUR LES MESURES =================
  @HiveField(6)
  AvisMesuresTerre avisMesuresTerre;

  // ================= SECTION 6: ESSAIS DÉCLENCHEMENT DIFFÉRENTIELS =================
  @HiveField(7)
  List<EssaiDeclenchementDifferentiel> essaisDeclenchement;

  // ================= SECTION 7: CONTINUITÉ ET RÉSISTANCE =================
  @HiveField(8)
  List<ContinuiteResistance> continuiteResistances;

  MesuresEssais({
    required this.missionId,
    required this.updatedAt,
    ConditionMesure? conditionMesure,
    EssaiDemarrageAuto? essaiDemarrageAuto,
    TestArretUrgence? testArretUrgence,
    List<PriseTerre>? prisesTerre,
    AvisMesuresTerre? avisMesuresTerre,
    List<EssaiDeclenchementDifferentiel>? essaisDeclenchement,
    List<ContinuiteResistance>? continuiteResistances,
  })  : conditionMesure = conditionMesure ?? ConditionMesure(),
        essaiDemarrageAuto = essaiDemarrageAuto ?? EssaiDemarrageAuto(),
        testArretUrgence = testArretUrgence ?? TestArretUrgence(),
        prisesTerre = prisesTerre ?? [],
        avisMesuresTerre = avisMesuresTerre ?? AvisMesuresTerre(),
        essaisDeclenchement = essaisDeclenchement ?? [],
        continuiteResistances = continuiteResistances ?? [];

  factory MesuresEssais.create(String missionId) {
    return MesuresEssais(
      missionId: missionId,
      updatedAt: DateTime.now(),
    );
  }

  // Méthode pour calculer le statut global
  Map<String, dynamic> calculerStatistiques() {

    int essaisReussis = essaisDeclenchement.where((essai) => essai.essai == 'B').length;
    int essaisNonReussis = essaisDeclenchement.where((essai) => essai.essai == 'M').length;
    int essaisNonEssayes = essaisDeclenchement.where((essai) => essai.essai == 'NE').length;

    return {
      'total_prises_terre': prisesTerre.length,
      'total_essais_differ': essaisDeclenchement.length,
      'essais_reussis': essaisReussis,
      'essais_non_reussis': essaisNonReussis,
      'essais_non_essayes': essaisNonEssayes,
      'total_continuites': continuiteResistances.length,
      'condition_mesure_renseignee': conditionMesure.observation != null && conditionMesure.observation!.isNotEmpty,
      'demarrage_auto_renseigne': essaiDemarrageAuto.observation != null && essaiDemarrageAuto.observation!.isNotEmpty,
      'arret_urgence_renseigne': testArretUrgence.observation != null && testArretUrgence.observation!.isNotEmpty,
      'avis_mesures_renseigne': avisMesuresTerre.observation != null && avisMesuresTerre.observation!.isNotEmpty,
    };
  }
}

// ================= SOUS-MODÈLES =================

// SECTION 1: CONDITIONS DE MESURE
@HiveType(typeId: 17)
class ConditionMesure {
  @HiveField(0)
  String? observation;

  ConditionMesure({this.observation});
}

// SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE DU GROUPE ÉLECTROGÈNE
@HiveType(typeId: 18)
class EssaiDemarrageAuto {
  @HiveField(0)
  String? observation;

  EssaiDemarrageAuto({this.observation});
}

// SECTION 3: TEST DE FONCTIONNEMENT DE L'ARRÊT D'URGENCE
@HiveType(typeId: 19)
class TestArretUrgence {
  @HiveField(0)
  String? observation;

  TestArretUrgence({this.observation});
}

// SECTION 4: PRISE DE TERRE (MODIFIÉ)
@HiveType(typeId: 20)
class PriseTerre {
  @HiveField(0)
  String localisation; // Ex: "Extérieur", "Local GE", "Local transformateur"

  @HiveField(1)
  String identification; // Ex: "PT1", "PT2", "PT3"

  // ✅ RENOMMÉ : conditionMesure → conditionPriseTerre
  @HiveField(2)
  String conditionPriseTerre; // Ex: "Barette ouverte", "Barette fermée"

  @HiveField(3)
  String naturePriseTerre; // Ex: "Boucle en fond de fouille"

  @HiveField(4)
  String methodeMesure; // Ex: "Impédance de boucle"

  @HiveField(5)
  double? valeurMesure; // Ex: 10.93, 4.27, 187.5

  @HiveField(6)
  String? observation; // Ex: "Satisfaisant", "Non satisfaisant"

  PriseTerre({
    required this.localisation,
    required this.identification,
    required this.conditionPriseTerre,
    required this.naturePriseTerre,
    required this.methodeMesure,
    this.valeurMesure,
    this.observation,
  });

  factory PriseTerre.create({
    required String localisation,
    required String identification,
  }) {
    return PriseTerre(
      localisation: localisation,
      identification: identification,
      conditionPriseTerre: 'Barette fermée', // ✅ Valeur par défaut
      naturePriseTerre: 'Boucle en fond de fouille',
      methodeMesure: 'Impédance de boucle',
    );
  }

  // Méthode pour vérifier si la prise de terre est complète
  bool get isComplete {
    return valeurMesure != null && 
           observation != null && 
           observation!.isNotEmpty;
  }
}

// SECTION 5: AVIS SUR LES MESURES (analyse des résultats)
@HiveType(typeId: 21)
class AvisMesuresTerre {
  @HiveField(0)
  List<String> satisfaisants; // Liste des PT satisfaisants: ["PT1", "PT2", "PT3"]

  @HiveField(1)
  List<String> nonSatisfaisants; // Liste des PT non satisfaisants: ["PT3"]

  @HiveField(2)
  String? observation; // Ex: "Prévoir un plan d'exécution, Renforcer l'interconnexion..."

  AvisMesuresTerre({
    List<String>? satisfaisants,
    List<String>? nonSatisfaisants,
    this.observation,
  })  : satisfaisants = satisfaisants ?? [],
        nonSatisfaisants = nonSatisfaisants ?? [];
}

// SECTION 6: ESSAIS DE DÉCLENCHEMENT DES DISPOSITIFS DIFFÉRENTIELS
@HiveType(typeId: 22)
class EssaiDeclenchementDifferentiel {
  @HiveField(0)
  String localisation; // Local/zone récupéré depuis l'audit (ex: "Local transformateur")

  @HiveField(1)
  String? coffret; // Coffret spécifique dans le local (optionnel)

  @HiveField(2)
  String? designationCircuit; // Ex: "Circuit éclairage bureau"

  @HiveField(3)
  String typeDispositif; // "DDR", "RD", "IDR"

  @HiveField(4)
  double? reglageIAn; // En mA (ex: 30, 300)

  @HiveField(5)
  double? tempo; // En secondes

  @HiveField(6)
  double? isolement; // En MΩ

  @HiveField(7)
  String essai; // "B" (Bon), "M" (Mauvais), "NE" (Non essayé)

  @HiveField(8)
  String? observation;

  EssaiDeclenchementDifferentiel({
    required this.localisation,
    this.coffret,
    this.designationCircuit,
    required this.typeDispositif,
    this.reglageIAn,
    this.tempo,
    this.isolement,
    required this.essai,
    this.observation,
  });

  factory EssaiDeclenchementDifferentiel.create({
    required String localisation,
    required String designationCircuit,
  }) {
    return EssaiDeclenchementDifferentiel(
      localisation: localisation,
      designationCircuit: designationCircuit,
      typeDispositif: 'DDR',
      essai: 'NE', // Par défaut "Non essayé"
    );
  }

  // Méthode pour obtenir le texte complet du type de dispositif
  String get typeDispositifComplet {
    switch (typeDispositif) {
      case 'DDR': return 'Disjoncteur Différentiel';
      case 'RD': return 'Relais Différentiel';
      case 'IDR': return 'Interrupteur Différentiel';
      default: return typeDispositif;
    }
  }

  // Méthode pour obtenir le texte complet de l'essai
  String get essaiComplet {
    switch (essai) {
      case 'OK': return 'Bon fonctionnement';
      case 'NON OK': return 'Fonctionnement incorrect';
      case 'NE': return 'Non essayé';
      default: return essai;
    }
  }

  // Vérifier si l'essai est complet
  bool get isComplete {
    return essai != 'NE' &&
           typeDispositif.isNotEmpty;
  }
}

// SECTION 7: CONTINUITÉ ET RÉSISTANCE DES CONDUCTEURS DE PROTECTION
@HiveType(typeId: 23)
class ContinuiteResistance {
  @HiveField(0)
  String localisation; // Récupéré depuis l'audit

  @HiveField(1)
  String designationTableau; // Ex: "Tableau principal"

  @HiveField(2)
  String origineMesure; // Ex: "Borne terre → Barrette équipotentielle"

  @HiveField(3)
  String? observation;

  ContinuiteResistance({
    required this.localisation,
    required this.designationTableau,
    required this.origineMesure,
    this.observation,
  });

  factory ContinuiteResistance.create({
    required String localisation,
    required String designationTableau,
  }) {
    return ContinuiteResistance(
      localisation: localisation,
      designationTableau: designationTableau,
      origineMesure: '',
    );
  }

  // Vérifier si la mesure est complète
  bool get isComplete {
    return origineMesure.isNotEmpty && 
           (observation != null && observation!.isNotEmpty);
  }
}