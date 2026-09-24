// lib/models/renseignements_generaux.dart
import 'package:hive/hive.dart';

part 'renseignements_generaux.g.dart';

@HiveType(typeId: 34)
class RenseignementsGeneraux extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String etablissement;

  @HiveField(2)
  String installation;

  @HiveField(3)
  String activite;

  @HiveField(4)
  DateTime? dateDebut;

  @HiveField(5)
  DateTime? dateFin;

  @HiveField(6)
  int dureeJours;

  @HiveField(7)
  String? verificationType;

  @HiveField(8)
  String registreControle;

  @HiveField(9)
  List<String> compteRendu;

  @HiveField(10)
  List<Map<String, String>> accompagnateurs;

  @HiveField(11)
  List<Map<String, String>> verificateurs;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  String nomSite;

  @HiveField(14)
  String? formationHabilitationElectrique;

  @HiveField(15)
  String? activiteSurSite;

  @HiveField(16)
  String? classementReglementaireType;

  @HiveField(17)
  String? classementReglementaireCategorie;

  @HiveField(18)
  String? classementReglementaire;

  @HiveField(20)
  DateTime? createdAt;

  @HiveField(21)
  String? recepteurRapport;

  @HiveField(22)
  String? lieuIntervention;

  @HiveField(23)
  DateTime? dateRapport;

  @HiveField(24)
  String? recepteurCivilite;

  @HiveField(25)
  String? recepteurNom;

  @HiveField(26)
  String? recepteurFonction;

  @HiveField(27)
  String? recepteurEmail;

  @HiveField(28)
  String? recepteurTelephone;

  RenseignementsGeneraux({
    required this.missionId,
    required this.etablissement,
    required this.installation,
    required this.activite,
    this.dateDebut,
    this.dateFin,
    this.dureeJours = 0,
    this.verificationType,
    this.registreControle = '',
    List<String>? compteRendu,
    List<Map<String, String>>? accompagnateurs,
    List<Map<String, String>>? verificateurs,
    required this.updatedAt,
    this.createdAt,
    required this.nomSite,
    String? formationHabilitationElectrique,
    this.activiteSurSite,
    this.classementReglementaire,
    this.classementReglementaireType,
    this.classementReglementaireCategorie,
    this.recepteurRapport,
    this.lieuIntervention,
    this.dateRapport,
    this.recepteurCivilite,
    this.recepteurNom,
    this.recepteurFonction,
    this.recepteurEmail,
    this.recepteurTelephone,
  }) : formationHabilitationElectrique = formationHabilitationElectrique ?? 'Inconnu',
       compteRendu = compteRendu ?? [],  
       accompagnateurs = accompagnateurs ?? [],  
       verificateurs = verificateurs ?? [];  

  String get habilitationElectriqueEffective =>
      (formationHabilitationElectrique == null || formationHabilitationElectrique!.trim().isEmpty)
          ? 'Inconnu'
          : formationHabilitationElectrique!;

  /// Fonction effective du récepteur (source de vérité : recepteurFonction, repli historique : recepteurRapport)
  String get effectiveRecepteurFonction {
    if (recepteurFonction != null && recepteurFonction!.trim().isNotEmpty) {
      return recepteurFonction!.trim();
    }
    if (recepteurRapport != null && recepteurRapport!.trim().isNotEmpty) {
      return recepteurRapport!.trim();
    }
    return '';
  }

  /// Nom effectif du récepteur
  String get effectiveRecepteurNom => recepteurNom?.trim() ?? '';

  /// Civilité effective du récepteur
  /// Si explicitement définie, renvoyée.
  /// Si non définie mais qu'une fonction ou un nom existe (ancienne mission), défaut 'Monsieur'.
  /// Si aucun récepteur n'est présent, renvoie null.
  String? get effectiveRecepteurCivilite {
    if (recepteurCivilite != null && recepteurCivilite!.trim().isNotEmpty) {
      return recepteurCivilite!.trim();
    }
    if (effectiveRecepteurFonction.isNotEmpty || (recepteurNom != null && recepteurNom!.trim().isNotEmpty)) {
      return 'Monsieur';
    }
    return null;
  }

  factory RenseignementsGeneraux.create(String missionId) {
    final now = DateTime.now().toUtc();
    return RenseignementsGeneraux(
      missionId: missionId,
      etablissement: '',
      installation: '',
      activite: '',
      updatedAt: now,
      createdAt: now,
      nomSite: '',
      formationHabilitationElectrique: 'Inconnu',
      compteRendu: [],  
      accompagnateurs: [],  
      verificateurs: [], 
      activiteSurSite: null,
      classementReglementaire: null,
      classementReglementaireType: null,
      classementReglementaireCategorie: null,
      recepteurRapport: null,
      lieuIntervention: null,
      dateRapport: null,
      recepteurCivilite: null,
      recepteurNom: null,
      recepteurFonction: null,
      recepteurEmail: null,
      recepteurTelephone: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'etablissement': etablissement,
      'installation': installation,
      'activite': activite,
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'dureeJours': dureeJours,
      'verificationType': verificationType,
      'registreControle': registreControle,
      'compteRendu': compteRendu,
      'accompagnateurs': accompagnateurs,
      'verificateurs': verificateurs,
      'updatedAt': updatedAt.toIso8601String(),
      'nomSite': nomSite,
      'formationHabilitationElectrique': habilitationElectriqueEffective,
      'activiteSurSite': activiteSurSite,
      'classementReglementaire': classementReglementaire,
      'classementReglementaireType': classementReglementaireType,
      'classementReglementaireCategorie': classementReglementaireCategorie,
      'recepteurRapport': recepteurRapport,
      'lieuIntervention': lieuIntervention,
      'dateRapport': dateRapport?.toIso8601String(),
      'recepteurCivilite': recepteurCivilite,
      'recepteurNom': recepteurNom,
      'recepteurFonction': recepteurFonction,
      'recepteurEmail': recepteurEmail,
      'recepteurTelephone': recepteurTelephone,
    };
  }
}