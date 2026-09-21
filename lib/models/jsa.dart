import 'package:hive/hive.dart';

part 'jsa.g.dart';

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 1 : Opération & Équipe
// ───────────────────────────────────────────────────
@HiveType(typeId: 40)
class JSAInspecteur {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String prenom;

  @HiveField(2)
  String signature;

  @HiveField(3)
  String? matricule;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? role;

  JSAInspecteur({
    required this.nom,
    required this.prenom,
    this.signature = '',
    this.matricule,
    this.email,
    this.role,
  });

  /// Nom complet formaté
  String get fullName => '$prenom $nom'.trim();
}

class JSAUtils {
  /// Normalise une chaîne pour comparaison (insensible à la casse, espaces multiples réduits)
  static String normalize(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// Normalise un nom et prénom d'inspecteur pour la comparaison (insensible à la casse, espaces unifiés)
  static String normalizeInspectorName(String nom, [String prenom = '']) {
    return '$prenom $nom'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  /// Détermine si deux inspecteurs représentent la même identité technique
  static bool isSameInspector(
    JSAInspecteur existing, {
    required String nom,
    required String prenom,
    String? matricule,
    String? email,
  }) {
    // 1. Clé prioritaire : Matricule stable
    if (matricule != null && matricule.trim().isNotEmpty &&
        existing.matricule != null && existing.matricule!.trim().isNotEmpty) {
      if (normalize(existing.matricule!) == normalize(matricule)) {
        return true;
      }
    }

    // 2. Clé secondaire : Email professionnel
    if (email != null && email.trim().isNotEmpty &&
        existing.email != null && existing.email!.trim().isNotEmpty) {
      if (normalize(existing.email!) == normalize(email)) {
        return true;
      }
    }

    // 3. Clé de repli : Nom et prénom normalisés
    final keyExisting = normalizeInspectorName(existing.nom, existing.prenom);
    final keyCandidate = normalizeInspectorName(nom, prenom);
    if (keyExisting.isNotEmpty && keyExisting == keyCandidate) {
      return true;
    }

    // Cas où le nom contient à la fois prénom et nom
    if (keyExisting.isNotEmpty && normalize(existing.nom) == keyCandidate) {
      return true;
    }
    if (normalize(nom) == keyExisting) {
      return true;
    }

    return false;
  }

  /// Vérifie si un inspecteur est déjà présent dans la liste (insensible à la casse ou par identifiant)
  static bool hasInspector(
    List<JSAInspecteur> list,
    String nom, [
    String prenom = '',
    String? matricule,
    String? email,
  ]) {
    final cleanNom = nom.trim();
    final cleanPrenom = prenom.trim();
    if (cleanNom.isEmpty && cleanPrenom.isEmpty && (matricule == null || matricule.trim().isEmpty)) {
      return false;
    }

    return list.any((i) => isSameInspector(
      i,
      nom: cleanNom,
      prenom: cleanPrenom,
      matricule: matricule,
      email: email,
    ));
  }

  /// Ajoute un inspecteur s'il n'est pas déjà présent (idempotent, insensible à la casse)
  /// Conserve la casse originale transmise lors de l'ajout et enrichit les champs manquants
  static bool addInspectorIfAbsent(
    List<JSAInspecteur> list,
    String nom,
    String prenom, {
    String signature = '',
    String? matricule,
    String? email,
    String? role,
  }) {
    final cleanNom = nom.trim();
    final cleanPrenom = prenom.trim();
    final cleanMatricule = matricule?.trim();
    final cleanEmail = email?.trim();
    final cleanRole = role?.trim();

    if (cleanNom.isEmpty && cleanPrenom.isEmpty && (cleanMatricule == null || cleanMatricule.isEmpty)) {
      return false;
    }

    final index = list.indexWhere((i) => isSameInspector(
      i,
      nom: cleanNom,
      prenom: cleanPrenom,
      matricule: cleanMatricule,
      email: cleanEmail,
    ));

    if (index >= 0) {
      // Déjà présent : enrichir les champs manquants sans créer de doublon
      final existing = list[index];
      if ((existing.matricule == null || existing.matricule!.isEmpty) &&
          cleanMatricule != null && cleanMatricule.isNotEmpty) {
        existing.matricule = cleanMatricule;
      }
      if ((existing.email == null || existing.email!.isEmpty) &&
          cleanEmail != null && cleanEmail.isNotEmpty) {
        existing.email = cleanEmail;
      }
      if ((existing.role == null || existing.role!.isEmpty) &&
          cleanRole != null && cleanRole.isNotEmpty) {
        existing.role = cleanRole;
      }
      if (existing.signature.isEmpty && signature.isNotEmpty) {
        existing.signature = signature;
      }
      return false; // Pas d'ajout supplémentaire
    }

    list.add(JSAInspecteur(
      nom: cleanNom,
      prenom: cleanPrenom,
      signature: signature,
      matricule: cleanMatricule?.isNotEmpty == true ? cleanMatricule : null,
      email: cleanEmail?.isNotEmpty == true ? cleanEmail : null,
      role: cleanRole?.isNotEmpty == true ? cleanRole : null,
    ));
    return true;
  }
}

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 2 : Plan d'urgence
// ───────────────────────────────────────────────────
@HiveType(typeId: 41)
class JSAPlanUrgence {
  @HiveField(0, defaultValue: false)
  bool voiesIssuesIdentifiees;

  @HiveField(1, defaultValue: false)
  bool zonesRassemblementIdentifiees;

  @HiveField(2, defaultValue: false)
  bool consignesSecuriteInternes;

  @HiveField(3, defaultValue: '')
  String personneContactClient;

  @HiveField(4, defaultValue: '')
  String personneContactKES;

  JSAPlanUrgence({
    this.voiesIssuesIdentifiees = false,
    this.zonesRassemblementIdentifiees = false,
    this.consignesSecuriteInternes = false,
    this.personneContactClient = '',
    this.personneContactKES = '',
  });
}

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 3 : Dangers
// ───────────────────────────────────────────────────
@HiveType(typeId: 42)
class JSADangers {
  // Environnementaux
  @HiveField(0)
  bool chocElectrique = false;
  @HiveField(1)
  bool bruit = false;
  @HiveField(2)
  bool stressThermique = false;
  @HiveField(3)
  bool eclairageInadapte = false;
  @HiveField(4)
  bool zoneCirculationMalDefinie = false;
  @HiveField(5)
  bool solAccidente = false;
  @HiveField(6)
  bool emissionGazPoussiere = false;
  @HiveField(7)
  bool espaceConfine = false;
  @HiveField(8)
  String autreEnvironnement = '';

  // Physiques
  @HiveField(9)
  bool chuteObjets = false;
  @HiveField(10)
  bool coactivite = false;
  @HiveField(11)
  bool portCharge = false;
  @HiveField(12)
  bool expositionProduitsChimiques = false;
  @HiveField(13)
  bool chuteHauteur = false;
  @HiveField(14)
  bool electrification = false;
  @HiveField(15)
  bool incendiesExplosion = false;
  @HiveField(16)
  bool mauvaisesPostures = false;
  @HiveField(17)
  bool chutePlainPied = false;
  @HiveField(18)
  String autrePhysique = '';

  JSADangers();
}

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 4 : Exigences générales (EPC)
// ───────────────────────────────────────────────────
@HiveType(typeId: 43)
class JSAExigencesGenerales {
  @HiveField(0)
  bool signaletiqueSecurite = false;
  @HiveField(1)
  bool ficheDonneeSecuriteDisponible = false;
  @HiveField(2)
  bool uneMinuteMaSecurite = false;
  @HiveField(3)
  bool balise = false;
  @HiveField(4)
  bool zoneTravailPropre = false;
  @HiveField(5)
  bool toolboxMeeting = false;
  @HiveField(6)
  bool permisTravail = false;
  @HiveField(7)
  bool extincteurs = false;
  @HiveField(8)
  bool outilsMaterielsIsolants = false;
  @HiveField(9)
  bool boitePharmacie = false;
  @HiveField(10)
  String autre = '';

  JSAExigencesGenerales();
}

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 5 : EPI
// ───────────────────────────────────────────────────
@HiveType(typeId: 44)
class JSAEPI {
  @HiveField(0)
  bool casqueSecurite = false;
  @HiveField(1)
  bool bouchonsOreille = false;
  @HiveField(2)
  bool lunettesProtection = false;
  @HiveField(3)
  bool harnaisSecurite = false;
  @HiveField(4)
  bool chaussureSecurite = false;
  @HiveField(5)
  bool masqueSecurite = false;
  @HiveField(6)
  bool combinaisonLongueManche = false;
  @HiveField(7)
  bool gantsIsolants = false;
  @HiveField(8)
  bool cacheNez = false;
  @HiveField(9)
  bool gilet = false;
  @HiveField(10)
  String autre = '';

  JSAEPI();
}

// ───────────────────────────────────────────────────
// SOUS-CATÉGORIE 6 : Vérification finale
// ───────────────────────────────────────────────────
@HiveType(typeId: 45)
class JSAVerificationFinale {
  @HiveField(0)
  bool travailTermineNA = false;
  @HiveField(1)
  bool travailTermineApplicable = false;
  @HiveField(2)
  bool consignationCadenasRetireNA = false;
  @HiveField(3)
  bool consignationCadenasRetireApplicable = false;
  @HiveField(4)
  bool absenceConsignataireProcedureNA = false;
  @HiveField(5)
  bool absenceConsignataireProcedureApplicable = false;
  @HiveField(6)
  bool consignataireAbsentProcedureAppliqueeNA = false;
  @HiveField(7)
  bool consignataireAbsentProcedureAppliqueeApplicable = false;
  @HiveField(8)
  bool materielEnleveZoneNettoyeeNA = false;
  @HiveField(9)
  bool materielEnleveZoneNettoyeeApplicable = false;
  @HiveField(10)
  bool risquesSupprimesEquipementPretNA = false;
  @HiveField(11)
  bool risquesSupprimesEquipementPretApplicable = false;
  @HiveField(12)
  String autresPoints = '';
  @HiveField(13)
  String donneurOrdreSignature = '';
  @HiveField(14)
  String chargeAffairesSignature = '';

  JSAVerificationFinale();
}

// ───────────────────────────────────────────────────
// MODÈLE PRINCIPAL JSA
// ───────────────────────────────────────────────────
@HiveType(typeId: 39)
class JSA extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String operationEffectuer;

  @HiveField(2)
  List<JSAInspecteur> inspecteurs;

  @HiveField(3)
  JSAPlanUrgence planUrgence;

  @HiveField(4)
  JSADangers dangers;

  @HiveField(5)
  JSAExigencesGenerales exigencesGenerales;

  @HiveField(6)
  JSAEPI epi;

  @HiveField(7)
  JSAVerificationFinale verificationFinale;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9, defaultValue: 0)
  int currentSubCategory; // 0-5

  @HiveField(10)
  DateTime? createdAt;

  JSA({
    required this.missionId,
    this.operationEffectuer = '',
    List<JSAInspecteur>? inspecteurs,
    JSAPlanUrgence? planUrgence,
    JSADangers? dangers,
    JSAExigencesGenerales? exigencesGenerales,
    JSAEPI? epi,
    JSAVerificationFinale? verificationFinale,
    DateTime? updatedAt,
    this.createdAt,
    this.currentSubCategory = 0,
  })  : inspecteurs = inspecteurs ?? [],
        planUrgence = planUrgence ?? JSAPlanUrgence(),
        dangers = dangers ?? JSADangers(),
        exigencesGenerales = exigencesGenerales ?? JSAExigencesGenerales(),
        epi = epi ?? JSAEPI(),
        verificationFinale = verificationFinale ?? JSAVerificationFinale(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  factory JSA.create(String missionId) {
    final now = DateTime.now().toUtc();
    return JSA(missionId: missionId, createdAt: now, updatedAt: now);
  }
}