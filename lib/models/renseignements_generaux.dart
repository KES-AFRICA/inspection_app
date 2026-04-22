// lib/models/renseignements_generaux.dart
import 'package:hive/hive.dart';

part 'renseignements_generaux.g.dart';

@HiveType(typeId: 34)
class RenseignementsGeneraux extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String etablissement;

  @HiveField(2)
  String installation;

  @HiveField(3)
  String activite;

  @HiveField(4)
  DateTime? dateDebut;

  @HiveField(5)
  DateTime? dateFin;

  @HiveField(6)
  int dureeJours;

  @HiveField(7)
  String? verificationType;

  @HiveField(8)
  String registreControle;

  @HiveField(9)
  List<String> compteRendu;

  @HiveField(10)
  List<Map<String, String>> accompagnateurs;

  @HiveField(11)
  List<Map<String, String>> verificateurs;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  String nomSite;

  RenseignementsGeneraux({
    required this.missionId,
    required this.etablissement,
    required this.installation,
    required this.activite,
    this.dateDebut,
    this.dateFin,
    this.dureeJours = 0,
    this.verificationType,
    this.registreControle = '',
    List<String>? compteRendu,
    List<Map<String, String>>? accompagnateurs,
    List<Map<String, String>>? verificateurs,
    required this.updatedAt,
    required this.nomSite,
  }) : compteRendu = compteRendu ?? [],  
       accompagnateurs = accompagnateurs ?? [],  
       verificateurs = verificateurs ?? [];  

  factory RenseignementsGeneraux.create(String missionId) {
    return RenseignementsGeneraux(
      missionId: missionId,
      etablissement: '',
      installation: '',
      activite: '',
      updatedAt: DateTime.now(),
      nomSite: '',
      compteRendu: [],  
      accompagnateurs: [],  
      verificateurs: [], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'etablissement': etablissement,
      'installation': installation,
      'activite': activite,
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'dureeJours': dureeJours,
      'verificationType': verificationType,
      'registreControle': registreControle,
      'compteRendu': compteRendu,
      'accompagnateurs': accompagnateurs,
      'verificateurs': verificateurs,
      'updatedAt': updatedAt.toIso8601String(),
      'nomSite': nomSite,
    };
  }
}