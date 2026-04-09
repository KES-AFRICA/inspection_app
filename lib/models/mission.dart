import 'package:hive/hive.dart';

part 'mission.g.dart';

@HiveType(typeId: 1)
class Mission extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nomClient;

  @HiveField(2)
  String? activiteClient;

  @HiveField(3)
  String? adresseClient;

  @HiveField(4)
  String? logoClient;

  @HiveField(5)
  List<String>? accompagnateurs;

  @HiveField(6)
  List<Map<String, dynamic>>? verificateurs;

  @HiveField(7)
  String? dgResponsable;

  @HiveField(8)
  DateTime? dateIntervention;

  @HiveField(9)
  DateTime? dateRapport;

  @HiveField(10)
  String? natureMission;

  @HiveField(11)
  String? periodicite;

  @HiveField(12)
  int? dureeMissionJours;

  @HiveField(13)
  bool docCahierPrescriptions;

  @HiveField(14)
  bool docNotesCalculs;

  @HiveField(15)
  bool docSchemasUnifilaires;

  @HiveField(16)
  bool docPlanMasse;

  @HiveField(17)
  bool docPlansArchitecturaux;

  @HiveField(18)
  bool docDeclarationsCe;

  @HiveField(19)
  bool docListeInstallations;

  @HiveField(20)
  bool docPlanLocauxRisques;

  @HiveField(21)
  bool docRapportAnalyseFoudre;

  @HiveField(22)
  bool docRapportEtudeFoudre;

  @HiveField(23)
  bool docRegistreSecurite;

  @HiveField(24)
  bool docRapportDerniereVerif;

  @HiveField(25)
  DateTime createdAt;

  @HiveField(26)
  DateTime updatedAt;

  @HiveField(27)
  String status;

  @HiveField(28)
  String? descriptionInstallationsId;

  @HiveField(29)
  String? auditInstallationsElectriquesId;

  @HiveField(30)
  bool docAutre;

  @HiveField(31)
  String? classementLocauxId;

  @HiveField(32)
  List<String>? foudreIds;

  @HiveField(33)
  String? mesuresEssaisId; 

  @HiveField(34)
  String? renseignementsGenerauxId;

  Mission({
    required this.id,
    required this.nomClient,
    this.activiteClient,
    this.adresseClient,
    this.logoClient,
    this.accompagnateurs,
    this.verificateurs,
    this.dgResponsable,
    this.dateIntervention,
    this.dateRapport,
    this.natureMission,
    this.periodicite,
    this.dureeMissionJours,
    this.docCahierPrescriptions = false,
    this.docNotesCalculs = false,
    this.docSchemasUnifilaires = false,
    this.docPlanMasse = false,
    this.docPlansArchitecturaux = false,
    this.docDeclarationsCe = false,
    this.docListeInstallations = false,
    this.docPlanLocauxRisques = false,
    this.docRapportAnalyseFoudre = false,
    this.docRapportEtudeFoudre = false,
    this.docRegistreSecurite = false,
    this.docRapportDerniereVerif = false,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.descriptionInstallationsId,
    this.auditInstallationsElectriquesId,
    this.docAutre = false,
    this.classementLocauxId,
    this.foudreIds, 
    this.mesuresEssaisId,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      nomClient: json['nom_client'] ?? '',
      activiteClient: json['activite_client'],
      adresseClient: json['adresse_client'],
      logoClient: json['logo_client'],
      accompagnateurs: json['accompagnateurs'] != null
          ? List<String>.from(json['accompagnateurs'])
          : null,
      verificateurs: json['verificateurs'] != null
          ? List<Map<String, dynamic>>.from(
              json['verificateurs'].map((v) => Map<String, dynamic>.from(v)))
          : null,
      dgResponsable: json['dg_responsable'],
      dateIntervention: json['date_intervention'] != null
          ? DateTime.parse(json['date_intervention'])
          : null,
      dateRapport: json['date_rapport'] != null
          ? DateTime.parse(json['date_rapport'])
          : null,
      natureMission: json['nature_mission'],
      periodicite: json['periodicite'],
      dureeMissionJours: json['duree_mission_jours'],
      docCahierPrescriptions: json['doc_cahier_prescriptions'] ?? false,
      docNotesCalculs: json['doc_notes_calculs'] ?? false,
      docSchemasUnifilaires: json['doc_schemas_unifilaires'] ?? false,
      docPlanMasse: json['doc_plan_masse'] ?? false,
      docPlansArchitecturaux: json['doc_plans_architecturaux'] ?? false,
      docDeclarationsCe: json['doc_declarations_ce'] ?? false,
      docListeInstallations: json['doc_liste_installations'] ?? false,
      docPlanLocauxRisques: json['doc_plan_locaux_risques'] ?? false,
      docRapportAnalyseFoudre: json['doc_rapport_analyse_foudre'] ?? false,
      docRapportEtudeFoudre: json['doc_rapport_etude_foudre'] ?? false,
      docRegistreSecurite: json['doc_registre_securite'] ?? false,
      docRapportDerniereVerif: json['doc_rapport_derniere_verif'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
      descriptionInstallationsId: json['description_installations_id'],
      auditInstallationsElectriquesId: json['audit_installations_electriques_id'],
      docAutre: json['doc_autre'] ?? false,
      classementLocauxId: json['classement_locaux_id'],
      foudreIds: json['foudre_ids'] != null
          ? List<String>.from(json['foudre_ids'])
          : null,
      mesuresEssaisId: json['mesures_essais_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_client': nomClient,
      'activite_client': activiteClient,
      'adresse_client': adresseClient,
      'logo_client': logoClient,
      'accompagnateurs': accompagnateurs,
      'verificateurs': verificateurs,
      'dg_responsable': dgResponsable,
      'date_intervention': dateIntervention?.toIso8601String(),
      'date_rapport': dateRapport?.toIso8601String(),
      'nature_mission': natureMission,
      'periodicite': periodicite,
      'duree_mission_jours': dureeMissionJours,
      'doc_cahier_prescriptions': docCahierPrescriptions,
      'doc_notes_calculs': docNotesCalculs,
      'doc_schemas_unifilaires': docSchemasUnifilaires,
      'doc_plan_masse': docPlanMasse,
      'doc_plans_architecturaux': docPlansArchitecturaux,
      'doc_declarations_ce': docDeclarationsCe,
      'doc_liste_installations': docListeInstallations,
      'doc_plan_locaux_risques': docPlanLocauxRisques,
      'doc_rapport_analyse_foudre': docRapportAnalyseFoudre,
      'doc_rapport_etude_foudre': docRapportEtudeFoudre,
      'doc_registre_securite': docRegistreSecurite,
      'doc_rapport_derniere_verif': docRapportDerniereVerif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'description_installations_id': descriptionInstallationsId,
      'audit_installations_electriques_id': auditInstallationsElectriquesId,
      'doc_autre': docAutre,
      'classement_locaux_id': classementLocauxId,
      'foudre_ids': foudreIds,
      'mesures_essais_id': mesuresEssaisId,
    };
  }
}