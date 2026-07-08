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
  });
}
