// classement_locaux.dart
import 'package:hive/hive.dart';

part 'classement_locaux.g.dart';

// lib/models/classement_locaux.dart

@HiveType(typeId: 14)
class ClassementEmplacement extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  String localisation; // Nom du local OU de la zone

  @HiveField(2)
  String? zone; // Zone parente (si c'est un local)

  @HiveField(3)
  String origineClassement; // "KES I&P" ou "Hérité de la zone X"

  // Influences externes
  @HiveField(4)
  String? af;
  @HiveField(5)
  String? be;
  @HiveField(6)
  String? ae;
  @HiveField(7)
  String? ad;
  @HiveField(8)
  String? ag;

  @HiveField(9)
  String? ip;
  @HiveField(10)
  String? ik;
  @HiveField(11)
  DateTime updatedAt;
  @HiveField(12)
  String? typeLocal; // Type du local ou "ZONE_MT" / "ZONE_BT"

  // ===== NOUVEAUX CHAMPS =====
  @HiveField(15)
  bool estZone; // true si c'est une zone, false si c'est un local

  @HiveField(16)
  String? heritageDe; // Nom de la zone dont il hérite (si héritage)

  @HiveField(17)
  bool heritageActive; // true si le local hérite de sa zone

  ClassementEmplacement({
    required this.missionId,
    required this.localisation,
    this.zone,
    this.origineClassement = 'KES I&P',
    this.af,
    this.be,
    this.ae,
    this.ad,
    this.ag,
    this.ip,
    this.ik,
    required this.updatedAt,
    this.typeLocal,
    this.estZone = false,
    this.heritageDe,
    this.heritageActive = false,
  });

  factory ClassementEmplacement.create({
    required String missionId,
    required String localisation,
    String? zone,
    String? typeLocal,
    bool estZone = false,
  }) {
    return ClassementEmplacement(
      missionId: missionId,
      localisation: localisation,
      zone: zone,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeLocal: typeLocal,
      estZone: estZone,
      heritageActive: false,
    );
  }

  // ===== NOUVEAU : Copier les valeurs d'un autre classement (héritage) =====
  void copierDepuis(ClassementEmplacement source) {
    af = source.af;
    be = source.be;
    ae = source.ae;
    ad = source.ad;
    ag = source.ag;
    ip = source.ip;
    ik = source.ik;
    origineClassement = 'Hérité de ${source.localisation}';
    heritageDe = source.localisation;
    heritageActive = true;
    updatedAt = DateTime.now();
  }

  // ===== NOUVEAU : Réinitialiser l'héritage (passer en mode spécifique) =====
  void desactiverHeritage() {
    heritageActive = false;
    heritageDe = null;
    origineClassement = 'KES I&P';
    updatedAt = DateTime.now();
  }

  // Méthode existante modifiée
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
}