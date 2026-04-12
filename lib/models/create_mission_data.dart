// lib/models/create_mission_data.dart
import 'package:inspec_app/models/mission.dart';

class CreateMissionData {
  String nomClient;
  String? activiteClient;
  String? adresseClient;
  String? dgResponsable;
  DateTime? dateIntervention;
  DateTime? dateRapport;
  String? natureMission;
  String? periodicite;
  int? dureeMissionJours;
  List<String> accompagnateurs;
  List<Map<String, dynamic>> verificateurs;

  // Documents (optionnels)
  bool docCahierPrescriptions;
  bool docNotesCalculs;
  bool docSchemasUnifilaires;
  bool docPlanMasse;
  bool docPlansArchitecturaux;
  bool docDeclarationsCe;
  bool docListeInstallations;
  bool docPlanLocauxRisques;
  bool docRapportAnalyseFoudre;
  bool docRapportEtudeFoudre;
  bool docRegistreSecurite;
  bool docRapportDerniereVerif;
  bool docAutre;

  CreateMissionData({
    required this.nomClient,
    this.activiteClient,
    this.adresseClient,
    this.dgResponsable,
    this.dateIntervention,
    this.dateRapport,
    this.natureMission,
    this.periodicite,
    this.dureeMissionJours,
    this.accompagnateurs = const [],
    this.verificateurs = const [],
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
    this.docAutre = false,
  });

  Mission toMission(String id, String currentUserMatricule) {
    return Mission(
      id: id,
      nomClient: nomClient,
      activiteClient: activiteClient,
      adresseClient: adresseClient,
      dgResponsable: dgResponsable,
      dateIntervention: dateIntervention,
      dateRapport: dateRapport,
      natureMission: natureMission,
      periodicite: periodicite,
      dureeMissionJours: dureeMissionJours,
      accompagnateurs: accompagnateurs,
      verificateurs: verificateurs,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'en_attente',
      docCahierPrescriptions: docCahierPrescriptions,
      docNotesCalculs: docNotesCalculs,
      docSchemasUnifilaires: docSchemasUnifilaires,
      docPlanMasse: docPlanMasse,
      docPlansArchitecturaux: docPlansArchitecturaux,
      docDeclarationsCe: docDeclarationsCe,
      docListeInstallations: docListeInstallations,
      docPlanLocauxRisques: docPlanLocauxRisques,
      docRapportAnalyseFoudre: docRapportAnalyseFoudre,
      docRapportEtudeFoudre: docRapportEtudeFoudre,
      docRegistreSecurite: docRegistreSecurite,
      docRapportDerniereVerif: docRapportDerniereVerif,
      docAutre: docAutre,
    );
  }
}