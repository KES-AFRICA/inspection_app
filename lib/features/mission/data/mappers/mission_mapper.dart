// lib/features/mission/data/mappers/mission_mapper.dart
import 'package:inspec_app/models/mission.dart';
import '../../domain/entities/mission_entity.dart';

class MissionMapper {
  static MissionEntity toEntity(Mission model) {
    return MissionEntity(
      id: model.id,
      nomClient: model.nomClient,
      activiteClient: model.activiteClient,
      adresseClient: model.adresseClient,
      logoClient: model.logoClient,
      accompagnateurs: model.accompagnateurs,
      verificateurs: model.verificateurs,
      dgResponsable: model.dgResponsable,
      dateIntervention: model.dateIntervention,
      dateRapport: model.dateRapport,
      natureMission: model.natureMission,
      periodicite: model.periodicite,
      dureeMissionJours: model.dureeMissionJours,
      docCahierPrescriptions: model.docCahierPrescriptions,
      docNotesCalculs: model.docNotesCalculs,
      docSchemasUnifilaires: model.docSchemasUnifilaires,
      docPlanMasse: model.docPlanMasse,
      docPlansArchitecturaux: model.docPlansArchitecturaux,
      docDeclarationsCe: model.docDeclarationsCe,
      docListeInstallations: model.docListeInstallations,
      docPlanLocauxRisques: model.docPlanLocauxRisques,
      docRapportAnalyseFoudre: model.docRapportAnalyseFoudre,
      docRapportEtudeFoudre: model.docRapportEtudeFoudre,
      docRegistreSecurite: model.docRegistreSecurite,
      docRapportDerniereVerif: model.docRapportDerniereVerif,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      status: model.status,
      descriptionInstallationsId: model.descriptionInstallationsId,
      auditInstallationsElectriquesId: model.auditInstallationsElectriquesId,
      docAutre: model.docAutre,
      classementLocauxId: model.classementLocauxId,
      foudreIds: model.foudreIds,
      mesuresEssaisId: model.mesuresEssaisId,
      renseignementsGenerauxId: model.renseignementsGenerauxId,
      nomSite: model.nomSite,
      jsaId: model.jsaId,
      schemaOption: model.schemaOption,
      autresDocuments: model.autresDocuments,
      installation: model.installation,
    );
  }
  static Mission toModel(MissionEntity entity) {
    final model = Mission(
      id: entity.id,
      nomClient: entity.nomClient,
      activiteClient: entity.activiteClient,
      adresseClient: entity.adresseClient,
      logoClient: entity.logoClient,
      accompagnateurs: entity.accompagnateurs,
      verificateurs: entity.verificateurs,
      dgResponsable: entity.dgResponsable,
      dateIntervention: entity.dateIntervention,
      dateRapport: entity.dateRapport,
      natureMission: entity.natureMission,
      periodicite: entity.periodicite,
      dureeMissionJours: entity.dureeMissionJours,
      docCahierPrescriptions: entity.docCahierPrescriptions,
      docNotesCalculs: entity.docNotesCalculs,
      docSchemasUnifilaires: entity.docSchemasUnifilaires,
      docPlanMasse: entity.docPlanMasse,
      docPlansArchitecturaux: entity.docPlansArchitecturaux,
      docDeclarationsCe: entity.docDeclarationsCe,
      docListeInstallations: entity.docListeInstallations,
      docPlanLocauxRisques: entity.docPlanLocauxRisques,
      docRapportAnalyseFoudre: entity.docRapportAnalyseFoudre,
      docRapportEtudeFoudre: entity.docRapportEtudeFoudre,
      docRegistreSecurite: entity.docRegistreSecurite,
      docRapportDerniereVerif: entity.docRapportDerniereVerif,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      status: entity.status,
      descriptionInstallationsId: entity.descriptionInstallationsId,
      auditInstallationsElectriquesId: entity.auditInstallationsElectriquesId,
      docAutre: entity.docAutre,
      classementLocauxId: entity.classementLocauxId,
      foudreIds: entity.foudreIds,
      mesuresEssaisId: entity.mesuresEssaisId,
      nomSite: entity.nomSite,
      jsaId: entity.jsaId,
      schemaOption: entity.schemaOption,
      autresDocuments: List<String>.from(entity.autresDocuments),
      installation: entity.installation,
    );
    
    // renseignementsGenerauxId n'est pas présent dans le constructeur de Mission
    model.renseignementsGenerauxId = entity.renseignementsGenerauxId;
    
    return model;
  }
}
