// classement_locaux.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/services/hive_service.dart';

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

  @HiveField(13)
  String typeEmplacement; // 'zone' ou 'local'
  
  @HiveField(14)
  bool heriteDeZone; // true si le local hérite du classement de sa zone
  
  @HiveField(15)
  String? zoneParenteId;

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
    this.typeEmplacement = 'local', // Par défaut 'local' pour rétrocompatibilité
    this.heriteDeZone = false,
    this.zoneParenteId,
  });

  factory ClassementEmplacement.create({
    required String missionId,
    required String localisation,
    String? zone,
    String? typeLocal,
    String typeEmplacement = 'local',
    bool heriteDeZone = false,
    String? zoneParenteId,
  }) {
    return ClassementEmplacement(
      missionId: missionId,
      localisation: localisation,
      zone: zone,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeLocal: typeLocal,
      typeEmplacement: typeEmplacement,
      heriteDeZone: heriteDeZone,
      zoneParenteId: zoneParenteId,
    );
  }

  factory ClassementEmplacement.createZone({
    required String missionId,
    required String nomZone,
  }) {
    return ClassementEmplacement(
      missionId: missionId,
      localisation: nomZone,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeEmplacement: 'zone',
      heriteDeZone: false,
    );
  }

  // Créer un classement pour un local qui hérite de sa zone
  factory ClassementEmplacement.createLocalHeritant({
    required String missionId,
    required String nomLocal,
    required String zoneParente,
    required String zoneParenteId,
  }) {
    return ClassementEmplacement(
      missionId: missionId,
      localisation: nomLocal,
      zone: zoneParente,
      origineClassement: 'KES I&P',
      updatedAt: DateTime.now(),
      typeEmplacement: 'local',
      heriteDeZone: true,
      zoneParenteId: zoneParenteId,
    );
  }

  // Récupérer les valeurs effectives (en tenant compte de l'héritage)
  String? get afEffective {
    if (heriteDeZone && zoneParenteId != null) {
      // Récupérer depuis HiveService
      return HiveService.getClassementById(zoneParenteId!)?.af;
    }
    return af;
  }

  String? get beEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.be;
    }
    return be;
  }

  String? get aeEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.ae;
    }
    return ae;
  }

  String? get adEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.ad;
    }
    return ad;
  }

  String? get agEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.ag;
    }
    return ag;
  }

  String? get ipEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.ip;
    }
    return ip;
  }

  String? get ikEffective {
    if (heriteDeZone && zoneParenteId != null) {
      return HiveService.getClassementById(zoneParenteId!)?.ik;
    }
    return ik;
  }

  // Vérifier si c'est une zone
  bool get isZone => typeEmplacement == 'zone';
  
  // Vérifier si c'est un local
  bool get isLocal => typeEmplacement == 'local';

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