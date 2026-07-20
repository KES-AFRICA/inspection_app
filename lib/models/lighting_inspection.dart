import 'package:hive/hive.dart';

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

// ═══════════════════════════════════════════════════════════════
// ADAPTATEURS HIVE ÉCRITS MANUELLEMENT POUR L'INDÉPENDANCE
// ═══════════════════════════════════════════════════════════════

class LuminaireQuestionAnswerAdapter
    extends TypeAdapter<LuminaireQuestionAnswer> {
  @override
  final int typeId = 62;

  @override
  LuminaireQuestionAnswer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LuminaireQuestionAnswer(
      questionIndex: fields[0] as int,
      isConform: fields[1] as bool? ?? true,
      commentaire: fields[2] as String?,
      photoPaths: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, LuminaireQuestionAnswer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.questionIndex)
      ..writeByte(1)
      ..write(obj.isConform)
      ..writeByte(2)
      ..write(obj.commentaire)
      ..writeByte(3)
      ..write(obj.photoPaths);
  }
}

class NonConformingLuminaireAdapter
    extends TypeAdapter<NonConformingLuminaire> {
  @override
  final int typeId = 61;

  @override
  NonConformingLuminaire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NonConformingLuminaire(
      id: fields[0] as String,
      repereLocalisation: fields[1] as String?,
      answers: (fields[2] as List?)?.cast<LuminaireQuestionAnswer>(),
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NonConformingLuminaire obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repereLocalisation)
      ..writeByte(2)
      ..write(obj.answers)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}

class LightingInspectionAdapter extends TypeAdapter<LightingInspection> {
  @override
  final int typeId = 60;

  @override
  LightingInspection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LightingInspection(
      id: fields[0] as String,
      missionId: fields[1] as String,
      batimentLocal: fields[2] as String,
      typeLuminaire: fields[3] as String,
      dateVerification: fields[4] as DateTime,
      nbLuminairesConformes: fields[5] as int? ?? 0,
      nonConformingLuminaires:
          (fields[6] as List?)?.cast<NonConformingLuminaire>(),
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LightingInspection obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.missionId)
      ..writeByte(2)
      ..write(obj.batimentLocal)
      ..writeByte(3)
      ..write(obj.typeLuminaire)
      ..writeByte(4)
      ..write(obj.dateVerification)
      ..writeByte(5)
      ..write(obj.nbLuminairesConformes)
      ..writeByte(6)
      ..write(obj.nonConformingLuminaires)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }
}
