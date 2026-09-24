// lib/features/mission/data/mappers/renseignements_generaux_mapper.dart
import 'package:inspec_app/models/renseignements_generaux.dart';
import '../../domain/entities/renseignements_generaux_entity.dart';

class RenseignementsGenerauxMapper {
  static RenseignementsGenerauxEntity toEntity(RenseignementsGeneraux model) {
    return RenseignementsGenerauxEntity(
      missionId: model.missionId,
      etablissement: model.etablissement,
      installation: model.installation,
      activite: model.activite,
      dateDebut: model.dateDebut,
      dateFin: model.dateFin,
      dureeJours: model.dureeJours,
      verificationType: model.verificationType,
      registreControle: model.registreControle,
      compteRendu: List<String>.from(model.compteRendu),
      accompagnateurs: List<Map<String, String>>.from(
        model.accompagnateurs.map(
          (m) => m.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
        ),
      ),
      verificateurs: List<Map<String, String>>.from(
        model.verificateurs.map(
          (m) => m.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
        ),
      ),
      updatedAt: model.updatedAt,
      nomSite: model.nomSite,
      formationHabilitationElectrique: model.habilitationElectriqueEffective,
      activiteSurSite: model.activiteSurSite,
      classementReglementaire: model.classementReglementaire,
      classementReglementaireType: model.classementReglementaireType,
      classementReglementaireCategorie: model.classementReglementaireCategorie,
      recepteurRapport: model.recepteurRapport,
      lieuIntervention: model.lieuIntervention,
      dateRapport: model.dateRapport,
      recepteurCivilite: model.recepteurCivilite,
      recepteurNom: model.recepteurNom,
      recepteurFonction: model.recepteurFonction,
      recepteurEmail: model.recepteurEmail,
      recepteurTelephone: model.recepteurTelephone,
    );
  }

  static RenseignementsGeneraux toModel(RenseignementsGenerauxEntity entity) {
    return RenseignementsGeneraux(
      missionId: entity.missionId,
      etablissement: entity.etablissement,
      installation: entity.installation,
      activite: entity.activite,
      dateDebut: entity.dateDebut,
      dateFin: entity.dateFin,
      dureeJours: entity.dureeJours,
      verificationType: entity.verificationType,
      registreControle: entity.registreControle,
      compteRendu: List<String>.from(entity.compteRendu),
      accompagnateurs: List<Map<String, String>>.from(
        entity.accompagnateurs.map(
          (m) => m.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
        ),
      ),
      verificateurs: List<Map<String, String>>.from(
        entity.verificateurs.map(
          (m) => m.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
        ),
      ),
      updatedAt: entity.updatedAt,
      nomSite: entity.nomSite,
      formationHabilitationElectrique: entity.formationHabilitationElectrique,
      activiteSurSite: entity.activiteSurSite,
      classementReglementaire: entity.classementReglementaire,
      classementReglementaireType: entity.classementReglementaireType,
      classementReglementaireCategorie: entity.classementReglementaireCategorie,
      recepteurRapport: entity.recepteurRapport ?? entity.recepteurFonction,
      lieuIntervention: entity.lieuIntervention,
      dateRapport: entity.dateRapport,
      recepteurCivilite: entity.recepteurCivilite,
      recepteurNom: entity.recepteurNom,
      recepteurFonction: entity.recepteurFonction,
      recepteurEmail: entity.recepteurEmail,
      recepteurTelephone: entity.recepteurTelephone,
    );
  }
}
