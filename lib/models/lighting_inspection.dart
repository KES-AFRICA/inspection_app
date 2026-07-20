import 'package:hive/hive.dart';

part 'lighting_inspection.g.dart';

/// Réponse à une question individuelle du questionnaire luminaire non conforme (1 à 12)
@HiveType(typeId: 62)
class LuminaireQuestionAnswer extends HiveObject {
  @HiveField(0)
  final int questionIndex;

  @HiveField(1)
  bool isConform;

  @HiveField(2)
  String? commentaire;

  @HiveField(3)
  List<String> photoPaths;

  LuminaireQuestionAnswer({
    required this.questionIndex,
    this.isConform = true,
    this.commentaire,
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? [];

  Map<String, dynamic> toJson() => {
        'questionIndex': questionIndex,
        'isConform': isConform,
        'commentaire': commentaire,
        'photoPaths': photoPaths,
      };

  factory LuminaireQuestionAnswer.fromJson(Map<String, dynamic> json) =>
      LuminaireQuestionAnswer(
        questionIndex: json['questionIndex'] as int,
        isConform: json['isConform'] as bool? ?? true,
        commentaire: json['commentaire'] as String?,
        photoPaths: (json['photoPaths'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

/// Modèle d'un luminaire non conforme
@HiveType(typeId: 61)
class NonConformingLuminaire extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String? repereLocalisation;

  @HiveField(2)
  List<LuminaireQuestionAnswer> answers;

  @HiveField(3)
  DateTime createdAt;

  NonConformingLuminaire({
    required this.id,
    this.repereLocalisation,
    List<LuminaireQuestionAnswer>? answers,
    DateTime? createdAt,
  })  : answers = answers ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Nbre de critères non conformes
  int get nbNonConformities =>
      answers.where((a) => !a.isConform).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'repereLocalisation': repereLocalisation,
        'answers': answers.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory NonConformingLuminaire.fromJson(Map<String, dynamic> json) =>
      NonConformingLuminaire(
        id: json['id'] as String,
        repereLocalisation: json['repereLocalisation'] as String?,
        answers: (json['answers'] as List<dynamic>?)
                ?.map((e) =>
                    LuminaireQuestionAnswer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

/// Inspection d'éclairage pour un local/bâtiment d'une mission
@HiveType(typeId: 60)
class LightingInspection extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String missionId;

  @HiveField(2)
  String batimentLocal;

  @HiveField(3)
  String typeLuminaire;

  @HiveField(4)
  DateTime dateVerification;

  @HiveField(5)
  int nbLuminairesConformes;

  @HiveField(6)
  List<NonConformingLuminaire> nonConformingLuminaires;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  LightingInspection({
    required this.id,
    required this.missionId,
    required this.batimentLocal,
    required this.typeLuminaire,
    required this.dateVerification,
    this.nbLuminairesConformes = 0,
    List<NonConformingLuminaire>? nonConformingLuminaires,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : nonConformingLuminaires = nonConformingLuminaires ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Nombre de luminaires non conformes (champ calculé)
  int get nbLuminairesNonConformes => nonConformingLuminaires.length;

  /// Nombre total de luminaires contrôlés dans ce local
  int get nbTotalLuminaires => nbLuminairesConformes + nbLuminairesNonConformes;

  /// Statut global du local
  String get status =>
      nbLuminairesNonConformes == 0 ? 'Conforme' : 'Non conforme';

  Map<String, dynamic> toJson() => {
        'id': id,
        'missionId': missionId,
        'batimentLocal': batimentLocal,
        'typeLuminaire': typeLuminaire,
        'dateVerification': dateVerification.toIso8601String(),
        'nbLuminairesConformes': nbLuminairesConformes,
        'nonConformingLuminaires':
            nonConformingLuminaires.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LightingInspection.fromJson(Map<String, dynamic> json) =>
      LightingInspection(
        id: json['id'] as String,
        missionId: json['missionId'] as String,
        batimentLocal: json['batimentLocal'] as String,
        typeLuminaire: json['typeLuminaire'] as String,
        dateVerification: json['dateVerification'] != null
            ? DateTime.parse(json['dateVerification'] as String)
            : DateTime.now(),
        nbLuminairesConformes: json['nbLuminairesConformes'] as int? ?? 0,
        nonConformingLuminaires: (json['nonConformingLuminaires'] as List<dynamic>?)
                ?.map((e) =>
                    NonConformingLuminaire.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );
}
