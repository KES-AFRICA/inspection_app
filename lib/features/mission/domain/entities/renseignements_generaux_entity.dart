// lib/features/mission/domain/entities/renseignements_generaux_entity.dart

class RenseignementsGenerauxEntity {
  final String missionId;
  final String etablissement;
  final String installation;
  final String activite;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final int dureeJours;
  final String? verificationType;
  final String registreControle;
  final List<String> compteRendu;
  final List<Map<String, String>> accompagnateurs;
  final List<Map<String, String>> verificateurs;
  final DateTime updatedAt;
  final String nomSite;
  final String formationHabilitationElectrique;
  final String? activiteSurSite;
  final String? classementReglementaire;
  final String? classementReglementaireType;
  final String? classementReglementaireCategorie;
  final String? recepteurRapport;
  final String? lieuIntervention;
  final DateTime? dateRapport;
  final String? recepteurCivilite;
  final String? recepteurNom;
  final String? recepteurFonction;
  final String? recepteurEmail;
  final String? recepteurTelephone;

  const RenseignementsGenerauxEntity({
    required this.missionId,
    required this.etablissement,
    required this.installation,
    required this.activite,
    this.dateDebut,
    this.dateFin,
    this.dureeJours = 0,
    this.verificationType,
    this.registreControle = '',
    this.compteRendu = const [],
    this.accompagnateurs = const [],
    this.verificateurs = const [],
    required this.updatedAt,
    required this.nomSite,
    this.formationHabilitationElectrique = 'Inconnu',
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
  });
}
