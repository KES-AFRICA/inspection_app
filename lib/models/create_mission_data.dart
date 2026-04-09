// lib/models/create_mission_data.dart (simplifié)
import 'package:inspec_app/models/mission.dart';

class CreateMissionData {
  String nomClient;
  String? activiteClient;
  String? adresseClient;

  CreateMissionData({
    required this.nomClient,
    this.activiteClient,
    this.adresseClient,
  });

  Mission toMission(String id, String currentUserEmail) {
    return Mission(
      id: id,
      nomClient: nomClient,
      activiteClient: activiteClient,
      adresseClient: adresseClient,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'brouillon',  // Statut initial "brouillon"
      // Tous les autres champs sont initialisés par défaut
      accompagnateurs: [],
      verificateurs: [],
      docCahierPrescriptions: false,
      docNotesCalculs: false,
      docSchemasUnifilaires: false,
      docPlanMasse: false,
      docPlansArchitecturaux: false,
      docDeclarationsCe: false,
      docListeInstallations: false,
      docPlanLocauxRisques: false,
      docRapportAnalyseFoudre: false,
      docRapportEtudeFoudre: false,
      docRegistreSecurite: false,
      docRapportDerniereVerif: false,
      docAutre: false,
    );
  }

  
}