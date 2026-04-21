// lib/models/classement_zone.dart
import 'package:hive/hive.dart';

part 'classement_zone.g.dart';

@HiveType(typeId: 46) // Utiliser un nouvel ID (après 45)
class ClassementZone extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String nomZone; // Nom de la zone

  @HiveField(2)
  String origineClassement; // Par défaut "KES I&P"

  // Influences externes - AF, BE, AE, AD, AG
  @HiveField(3)
  String? af;

  @HiveField(4)
  String? be;

  @HiveField(5)
  String? ae;

  @HiveField(6)
  String? ad;

  @HiveField(7)
  String? ag;

  // Indices calculés automatiquement
  @HiveField(8)
  String? ip;

  @HiveField(9)
  String? ik;

  @HiveField(10)
  DateTime updatedAt;

  // Type de zone (MT ou BT) - utile pour le filtrage
  @HiveField(11)
  String typeZone; // 'MT' ou 'BT'

  ClassementZone({
    required this.missionId,
    required this.nomZone,
    this.origineClassement = 'KES I&P',
    this.af,
    this.be,
    this.ae,
    this.ad,
    this.ag,
    this.ip,
    this.ik,
    required this.updatedAt,
    this.typeZone = 'BT',
  });

  factory ClassementZone.create({
    required String missionId,
    required String nomZone,
    String typeZone = 'BT',
  }) {
    return ClassementZone(
      missionId: missionId,
      nomZone: nomZone,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeZone: typeZone,
    );
  }

  // Méthode pour calculer automatiquement IP et IK
  void calculerIndices() {
    ip = _calculerIP();
    ik = _calculerIK();
  }

  String? _calculerIP() {
    if (ae == null || ad == null) return null;
    
    final aeNum = _extraireNumAE(ae!);
    final adNum = _extraireNumAD(ad!);
    
    if (aeNum == null || adNum == null) return null;
    
    return 'IP${aeNum}${adNum}';
  }

  String? _calculerIK() {
    if (ag == null) return null;
    
    switch (ag!) {
      case 'AG1': return 'IK02';
      case 'AG2': return 'IK07';
      case 'AG3': return 'IK08';
      case 'AG4': return 'IK10';
      default: return null;
    }
  }

  int? _extraireNumAE(String ae) {
    switch (ae) {
      case 'AE1': return 2;
      case 'AE2': return 3;
      case 'AE3': return 4;
      case 'AE4': return 5;
      default: return null;
    }
  }

  int? _extraireNumAD(String ad) {
    switch (ad) {
      case 'AD1': return 0;
      case 'AD2': return 1;
      case 'AD3': return 2;
      case 'AD4': return 3;
      case 'AD5': return 4;
      case 'AD6': return 5;
      case 'AD7': return 6;
      case 'AD8': return 7;
      case 'AD9': return 8;
      default: return null;
    }
  }

  // Vérifier si le classement est complet
  bool get estComplet => af != null && be != null && ae != null && ad != null && ag != null;
}