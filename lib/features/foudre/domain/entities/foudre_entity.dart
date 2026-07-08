// lib/features/foudre/domain/entities/foudre_entity.dart

class FoudreEntity {
  final dynamic id;
  final String missionId;
  final String observation;
  final int niveauPriorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoudreEntity({
    this.id,
    required this.missionId,
    required this.observation,
    required this.niveauPriorite,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(niveauPriorite >= 1 && niveauPriorite <= 3,
            'Le niveau de priorité doit être compris entre 1 et 3');
}
