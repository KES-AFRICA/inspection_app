// lib/services/statistics/audit_finding.dart

import '../hive_service.dart';

/// Modèle d'item d'inventaire chiffré des installations et équipements
class EquipmentInventoryItem {
  final String label;
  final int count;

  EquipmentInventoryItem({
    required this.label,
    required this.count,
  });
}

/// Modèle d'occurrence individuelle d'inventaire représentant une ligne non conforme constatée.
class AuditFinding {
  final String id;
  final String missionId;

  // Localisation & Contexte
  final String origin;           // "Local MT", "Local BT", "Zone MT", "Zone BT", "Groupe Électrogène", "Foudre"
  final String objectType;       // "Local MT", "Local BT", "Cellule MT", "Transformateur MT/BT", "Coffret", "Armoire", "TGBT", "Inverseur", "Foudre"
  final String objectName;       // Nom de l'équipement ou du local
  final String? objectRepere;    // Repère équipement ou numéro de série
  final String tableName;        // "Dispositions constructives", "Conditions d'exploitation", "Points de vérification", "Cellule audit", etc.

  // Constat & Normes
  final String verificationPoint;// Libellé du point de contrôle
  final String observationText;  // Description détaillée de la non-conformité
  final String conformity;       // "non", "non conforme", "false"
  final String criticality;      // "Critique", "Majeure", "Mineure", "Non spécifiée"
  final int? priority;           // Priorité d'intervention (1, 2, 3)
  final String? riskFamily;      // Famille de risque
  final String? normativeReference; // Référence normée
  final List<String> photos;

  AuditFinding({
    required this.id,
    required this.missionId,
    required this.origin,
    required this.objectType,
    required this.objectName,
    this.objectRepere,
    required this.tableName,
    required this.verificationPoint,
    required this.observationText,
    required this.conformity,
    required this.criticality,
    this.priority,
    this.riskFamily,
    this.normativeReference,
    List<String>? photos,
  }) : photos = photos ?? [];
}

/// Modèle d'item du Top 10 des défauts
class TopDefectItem {
  final String title;
  final int count;
  final double percentage;

  TopDefectItem({
    required this.title,
    required this.count,
    required this.percentage,
  });
}

/// Modèle d'analyse par domaine de tension (MT vs BT)
class TensionDomainStats {
  final int mtCount;
  final int btCount;
  final int totalCount;
  final double mtPct;
  final double btPct;

  TensionDomainStats({
    required this.mtCount,
    required this.btCount,
    required this.totalCount,
    required this.mtPct,
    required this.btPct,
  });
}

/// Modèle d'item d'analyse par famille de risque
class RiskFamilyItem {
  final String name;
  final int count;
  final double percentage;

  RiskFamilyItem({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

/// Modèle d'item d'analyse par type d'installation / d'équipement
class InstallationTypeItem {
  final String name;
  final int count;
  final double percentage;

  InstallationTypeItem({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

/// Modèle d'item d'analyse croisée par catégorie d'équipement
class CategoryCrossItem {
  final String categoryName;
  final int equipmentCount;
  final int nonConformitiesCount;
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final double density; // nonConformitiesCount / equipmentCount

  CategoryCrossItem({
    required this.categoryName,
    required this.equipmentCount,
    required this.nonConformitiesCount,
    required this.critiqueCount,
    required this.majeureCount,
    required this.mineureCount,
    required this.density,
  });
}

/// Collection certifiée d'inventaire brut d'une mission.
class AuditFindingInventory {
  final String missionId;
  final List<AuditFinding> findings;

  AuditFindingInventory({
    required this.missionId,
    required this.findings,
  });

  int get totalFindings => findings.length;

  int get critiqueCount => findings.where((f) => f.criticality == 'Critique').length;
  int get majeureCount => findings.where((f) => f.criticality == 'Majeure').length;
  int get mineureCount => findings.where((f) => f.criticality == 'Mineure').length;
  int get unspecifiedCount => findings.where((f) => f.criticality != 'Critique' && f.criticality != 'Majeure' && f.criticality != 'Mineure').length;

  /// Nombre de findings possédant une criticité normative résolue (Critique, Majeure ou Mineure).
  int get classifiedCount => critiqueCount + majeureCount + mineureCount;

  /// Findings possédant une criticité normative résolue.
  List<AuditFinding> get classifiedFindings => findings.where(
    (f) => f.criticality == 'Critique' || f.criticality == 'Majeure' || f.criticality == 'Mineure'
  ).toList();

  double get pctCritique => classifiedCount > 0 ? (critiqueCount / classifiedCount) * 100 : 0.0;
  double get pctMajeure => classifiedCount > 0 ? (majeureCount / classifiedCount) * 100 : 0.0;
  double get pctMineure => classifiedCount > 0 ? (mineureCount / classifiedCount) * 100 : 0.0;

  /// Récupère le Top N des points de vérification les plus fréquemment non conformes.
  List<TopDefectItem> getTopDefects({int limit = 10}) {
    if (findings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in findings) {
      final point = f.verificationPoint.trim();
      if (point.isNotEmpty) {
        counts[point] = (counts[point] ?? 0) + 1;
      }
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = limit > 0 ? sortedEntries.take(limit).toList() : sortedEntries;
    final tot = classifiedCount > 0 ? classifiedCount : totalFindings;

    return topEntries.map((e) {
      final pct = tot > 0 ? (e.value / tot) * 100 : 0.0;
      return TopDefectItem(
        title: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Vérifie la cohérence stricte entre les points de vérification recensés et le nombre total d'occurrences.
  bool verifyDefectConsistency() {
    final allDefects = getTopDefects(limit: -1);
    final sumOccurrences = allDefects.fold<int>(0, (sum, item) => sum + item.count);
    return sumOccurrences == totalFindings;
  }

  /// Calcule la répartition des non-conformités par famille de risque.
  List<RiskFamilyItem> getRiskFamilyStats() {
    if (findings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in findings) {
      final family = (f.riskFamily?.trim().isNotEmpty == true)
          ? f.riskFamily!.trim()
          : 'Non spécifiée';
      counts[family] = (counts[family] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tot = totalFindings;

    return sortedEntries.map((e) {
      final pct = tot > 0 ? (e.value / tot) * 100 : 0.0;
      return RiskFamilyItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Calcule la répartition des non-conformités par type d'installation / d'équipement.
  List<InstallationTypeItem> getInstallationTypeStats() {
    if (findings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in findings) {
      final typeStr = f.objectType.trim().isNotEmpty ? f.objectType.trim() : 'Installation';
      counts[typeStr] = (counts[typeStr] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tot = totalFindings;

    return sortedEntries.map((e) {
      final pct = tot > 0 ? (e.value / tot) * 100 : 0.0;
      return InstallationTypeItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Calcule la répartition des non-conformités par domaine de tension (MT vs BT).
  TensionDomainStats getTensionDomainStats() {
    int mt = 0;
    int bt = 0;

    for (final f in findings) {
      final origLower = f.origin.toLowerCase();
      final typeLower = f.objectType.toLowerCase();

      if (origLower.contains('mt') ||
          typeLower.contains('mt') ||
          typeLower.contains('cellule') ||
          typeLower.contains('transformateur')) {
        mt++;
      } else {
        bt++;
      }
    }

    final tot = findings.length;
    final mtPct = tot > 0 ? (mt / tot) * 100 : 0.0;
    final btPct = tot > 0 ? (bt / tot) * 100 : 0.0;

    return TensionDomainStats(
      mtCount: mt,
      btCount: bt,
      totalCount: tot,
      mtPct: mtPct,
      btPct: btPct,
    );
  }

  /// Calcule l'analyse croisée par catégorie d'installation / d'équipement.
  List<CategoryCrossItem> getCrossCategoryAnalysis({
    int countMTLocaux = 0,
    int countCellules = 0,
    int countTransfos = 0,
    int countGELocaux = 0,
    int countBTLocaux = 0,
    int countTGBT = 0,
    int countArmoires = 0,
    int countCoffrets = 0,
    int countTableauxDivisionnaires = 0,
    int countPrisesTerre = 0,
  }) {
    // 1. Locaux MT
    final mtLocauxFindings = findings.where((f) => f.objectType == 'Local MT').toList();
    // 2. Cellules MT
    final celluleFindings = findings.where((f) => f.objectType == 'Cellule MT').toList();
    // 3. Transformateurs MT/BT
    final transfoFindings = findings.where((f) => f.objectType == 'Transformateur MT/BT').toList();
    // 4. Locaux GE
    final geLocauxFindings = findings.where((f) => f.objectType == 'Local BT' && (f.objectName.toLowerCase().contains('groupe') || f.origin.toLowerCase().contains('groupe'))).toList();
    // 5. Locaux BT
    final btLocauxFindings = findings.where((f) => f.objectType == 'Local BT' && !(f.objectName.toLowerCase().contains('groupe') || f.origin.toLowerCase().contains('groupe'))).toList();
    // 6. TGBT
    final tgbtFindings = findings.where((f) => f.objectType == 'TGBT').toList();
    // 7. Armoires
    final armoireFindings = findings.where((f) => f.objectType == 'Armoire').toList();
    // 8. Coffrets
    final coffretFindings = findings.where((f) => f.objectType == 'Coffret' || f.objectType == 'Inverseur').toList();
    // 9. Tableaux divisionnaires
    final tabDivFindings = findings.where((f) => f.origin.toLowerCase().contains('zone')).toList();
    // 10. Foudre / Terre
    final foudreFindings = findings.where((f) => f.objectType == 'Foudre').toList();

    CategoryCrossItem buildItem(String catName, int eqCount, List<AuditFinding> list) {
      final ncCount = list.length;
      final cCount = list.where((f) => f.criticality == 'Critique').length;
      final mCount = list.where((f) => f.criticality == 'Majeure').length;
      final minCount = list.where((f) => f.criticality == 'Mineure').length;
      final dens = eqCount > 0 ? ncCount / eqCount : 0.0;
      return CategoryCrossItem(
        categoryName: catName,
        equipmentCount: eqCount,
        nonConformitiesCount: ncCount,
        critiqueCount: cCount,
        majeureCount: mCount,
        mineureCount: minCount,
        density: dens,
      );
    }

    final items = <CategoryCrossItem>[];

    if (countMTLocaux > 0 || mtLocauxFindings.isNotEmpty) {
      items.add(buildItem('Locaux techniques Moyenne Tension', countMTLocaux > 0 ? countMTLocaux : 1, mtLocauxFindings));
    }
    if (countCellules > 0 || celluleFindings.isNotEmpty) {
      items.add(buildItem('Cellules MT', countCellules > 0 ? countCellules : 1, celluleFindings));
    }
    if (countTransfos > 0 || transfoFindings.isNotEmpty) {
      items.add(buildItem('Transformateurs MT/BT', countTransfos > 0 ? countTransfos : 1, transfoFindings));
    }
    if (countGELocaux > 0 || geLocauxFindings.isNotEmpty) {
      items.add(buildItem('Locaux techniques Groupe Électrogène', countGELocaux > 0 ? countGELocaux : 1, geLocauxFindings));
    }
    if (countBTLocaux > 0 || btLocauxFindings.isNotEmpty) {
      items.add(buildItem('Locaux techniques Basse Tension', countBTLocaux > 0 ? countBTLocaux : 1, btLocauxFindings));
    }
    if (countTGBT > 0 || tgbtFindings.isNotEmpty) {
      items.add(buildItem('TGBT', countTGBT > 0 ? countTGBT : 1, tgbtFindings));
    }
    if (countArmoires > 0 || armoireFindings.isNotEmpty) {
      items.add(buildItem('Armoires', countArmoires > 0 ? countArmoires : 1, armoireFindings));
    }
    if (countCoffrets > 0 || coffretFindings.isNotEmpty) {
      items.add(buildItem('Coffrets (nommés + TCL)', countCoffrets > 0 ? countCoffrets : 1, coffretFindings));
    }
    if (countTableauxDivisionnaires > 0 || tabDivFindings.isNotEmpty) {
      items.add(buildItem('Tableaux divisionnaires par zone', countTableauxDivisionnaires > 0 ? countTableauxDivisionnaires : 1, tabDivFindings));
    }
    if (countPrisesTerre > 0 || foudreFindings.isNotEmpty) {
      items.add(buildItem('Prises de terre mesurées', countPrisesTerre > 0 ? countPrisesTerre : 1, foudreFindings));
    }

    return items;
  }

  /// Affiche le diagnostic certifié d'inventaire dans la console système stdout (print).
  void printDiagnostic() {
    print('================================================================================');
    print('📊 INVENTAIRE EXHAUSTIF DES NON-CONFORMITÉS — MISSION: $missionId');
    print('================================================================================');
    print('🔍 Total des non-conformités recensées : $totalFindings');
    print('--------------------------------------------------------------------------------');
    print('🔴 CRITIQUE  : $critiqueCount (${pctCritique.toStringAsFixed(1)}%)');
    print('🟠 MAJEURE   : $majeureCount (${pctMajeure.toStringAsFixed(1)}%)');
    print('🔵 MINEURE   : $mineureCount (${pctMineure.toStringAsFixed(1)}%)');
    if (unspecifiedCount > 0) {
      print('⚪ AUTRES    : $unspecifiedCount (Observations sans criticité normée)');
    }
    print('================================================================================');
  }

  /// Imprime l'inventaire complet ligne par ligne dans la console système.
  void printFullInventoryDetails() {
    printDiagnostic();
    print('--- DÉTAIL LIGNE PAR LIGNE DES $totalFindings OCCURRENCES ---');
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      print('[#${i + 1}] [${f.criticality.toUpperCase()}] ${f.origin} > ${f.objectType} "${f.objectName}" > ${f.tableName} | Point: ${f.verificationPoint} | Constat: ${f.observationText}');
    }
    print('================================================================================');
  }

  /// Calcule l'inventaire chiffré de toutes les installations et équipements enregistrés dans la mission.
  static List<EquipmentInventoryItem> computeEquipmentInventory(String missionId) {
    int countCellules = 0;
    int countTransformateurs = 0;
    int countGroupesElectrogenes = 0;
    int countLocauxGE = 0;
    int countLocauxMT = 0;
    int countLocauxBT = 0;
    int countTGBT = 0;
    int countArmoires = 0;
    int countCoffrets = 0;
    int countPrisesTerre = 0;

    try {
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final me = HiveService.getMesuresEssaisByMissionId(missionId);

      if (me != null && me.prisesTerre.isNotEmpty) {
        countPrisesTerre = me.prisesTerre.length;
      }

      if (audit != null) {
        // Locaux MT
        for (final local in audit.moyenneTensionLocaux) {
          countLocauxMT++;
          countCellules += local.cellules.length;
          countTransformateurs += local.transformateurs.length;
          for (final coffret in local.coffrets) {
            final t = coffret.type.toUpperCase();
            if (t.contains('TGBT') || t.contains('T.G.B.T')) {
              countTGBT++;
            } else if (t.contains('ARMOIRE') || t.contains('TUR')) {
              countArmoires++;
            } else {
              countCoffrets++;
            }
          }
        }

        // Zones BT
        for (final zone in audit.basseTensionZones) {
          for (final local in zone.locaux) {
            if (local.type == 'LOCAL_GROUPE_ELECTROGENE') {
              countLocauxGE++;
              countGroupesElectrogenes++;
            } else {
              countLocauxBT++;
            }
            for (final coffret in local.coffrets) {
              final t = coffret.type.toUpperCase();
              if (t.contains('TGBT') || t.contains('T.G.B.T')) {
                countTGBT++;
              } else if (t.contains('ARMOIRE') || t.contains('TUR')) {
                countArmoires++;
              } else {
                countCoffrets++;
              }
            }
          }
          for (final coffret in zone.coffretsDirects) {
            final t = coffret.type.toUpperCase();
            if (t.contains('TGBT') || t.contains('T.G.B.T')) {
              countTGBT++;
            } else if (t.contains('ARMOIRE') || t.contains('TUR')) {
              countArmoires++;
            } else {
              countCoffrets++;
            }
          }
        }
      }

      // Fallback: Si MesuresEssais est vide, décompter la section Foudre si présente
      if (countPrisesTerre == 0) {
        final foudres = HiveService.getFoudreObservationsByMissionId(missionId);
        if (foudres.isNotEmpty) {
          countPrisesTerre = foudres.length;
        }
      }
    } catch (_) {
      // En environnement de test sans Hive actif, retour des totaux initialisés.
    }

    return [
      EquipmentInventoryItem(label: 'Cellules Moyenne Tension', count: countCellules),
      EquipmentInventoryItem(label: 'Transformateurs MT/BT', count: countTransformateurs),
      EquipmentInventoryItem(label: 'Groupes \u00e9lectrog\u00e8nes', count: countGroupesElectrogenes),
      EquipmentInventoryItem(label: 'Locaux techniques Groupe \u00c9lectrog\u00e8ne', count: countLocauxGE),
      EquipmentInventoryItem(label: 'Locaux techniques Moyenne Tension', count: countLocauxMT),
      EquipmentInventoryItem(label: 'Locaux techniques Basse Tension', count: countLocauxBT),
      EquipmentInventoryItem(label: 'TGBT', count: countTGBT),
      EquipmentInventoryItem(label: 'Armoires', count: countArmoires),
      EquipmentInventoryItem(label: 'Coffrets', count: countCoffrets),
      EquipmentInventoryItem(label: 'Prises de terre mesur\u00e9es', count: countPrisesTerre),
    ];
  }
}
