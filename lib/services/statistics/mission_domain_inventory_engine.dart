// lib/services/statistics/mission_domain_inventory_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../../models/mesures_essais.dart';
import '../dispositions_constructives_registry.dart';
import '../hive_service.dart';
import 'audit_finding.dart';
import 'canonical_defect_category_registry.dart';
import 'domain_entity_instance.dart';

/// Registre certifié de l'inventaire métier unifié d'une mission (`MissionDomainInventory`).
///
/// Contient 100 % des instances d'équipements et de locaux physiques enregistrés dans la mission,
/// leurs bilans de conformité et l'ensemble des constats de non-conformité (`AuditFinding`).
class MissionDomainInventory {
  final String missionId;
  final List<DomainEntityInstance> instances;
  final List<AuditFinding> allFindings;

  MissionDomainInventory({
    required this.missionId,
    required this.instances,
    required this.allFindings,
  });

  /// Non-conformités pertinentes pour l'ensemble du Résumé Exécutif.
  List<AuditFinding> get pertinentFindings {
    final list = allFindings.where((f) => f.hasValidNormativeReference).toList();
    return list.isNotEmpty ? list : allFindings;
  }

  /// Retourne toutes les instances d'une catégorie donnée.
  List<DomainEntityInstance> getInstancesByCategory(DomainObjectType cat) {
    return instances.where((i) => i.category == cat).toList();
  }

  /// Calcule l'élément de synthèse croisée pour une catégorie donnée.
  CategoryCrossItem getCategorySummary(DomainObjectType cat) {
    final catInstances = getInstancesByCategory(cat);
    final eqCount = catInstances.length;

    int totalPoints = 0;
    int compliant = 0;
    int nonCompliant = 0;
    int na = 0;
    int critique = 0;
    int majeure = 0;
    int mineure = 0;

    for (final inst in catInstances) {
      totalPoints += inst.totalCheckpoints;
      compliant += inst.compliantCheckpoints;
      if (inst.findings.isNotEmpty) {
        final instPertinentFindings = inst.findings.where((f) => f.hasValidNormativeReference).toList();
        nonCompliant += instPertinentFindings.length;
        critique += instPertinentFindings.where((f) => f.criticality == 'Critique').length;
        majeure += instPertinentFindings.where((f) => f.criticality == 'Majeure').length;
        mineure += instPertinentFindings.where((f) => f.criticality == 'Mineure').length;
      } else {
        nonCompliant += inst.nonCompliantCheckpoints;
        critique += inst.critiqueCount;
        majeure += inst.majeureCount;
        mineure += inst.mineureCount;
      }
    }

    final evaluated = compliant + nonCompliant;
    double rate = 100.0;
    if (evaluated > 0) {
      rate = (compliant / evaluated) * 100.0;
    } else if (totalPoints > 0) {
      rate = (compliant / totalPoints) * 100.0;
    }

    double density = eqCount > 0 ? nonCompliant / eqCount : 0.0;

    return CategoryCrossItem(
      categoryKey: cat.categoryKey,
      categoryName: cat.label,
      equipmentCount: eqCount,
      totalPointsEvaluated: totalPoints,
      compliantPointsCount: compliant,
      nonCompliantPointsCount: nonCompliant,
      naPointsCount: na,
      critiqueCount: critique,
      majeureCount: majeure,
      mineureCount: mineure,
      complianceRate: rate,
      density: density,
    );
  }

  /// Génère l'analyse croisée pour les 10 catégories métiers normalisées.
  /// Les prises de terre apparaissent en dernier dans la liste.
  List<CategoryCrossItem> getCrossCategoryAnalysis() {
    final canonicalCategories = [
      DomainObjectType.localMT,
      DomainObjectType.localBT,
      DomainObjectType.localGE,
      DomainObjectType.celluleMT,
      DomainObjectType.transformateurMTBT,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
      DomainObjectType.inverseur,
      DomainObjectType.priseTerre,
    ];

    final result = <CategoryCrossItem>[];
    for (final cat in canonicalCategories) {
      final summary = getCategorySummary(cat);
      if (summary.equipmentCount > 0 || summary.totalPointsEvaluated > 0) {
        result.add(summary);
      }
    }
    return result;
  }

  /// Génère l'inventaire chiffré des installations et équipements (sous-section IX du rapport PDF).
  /// Les prises de terre apparaissent en dernier dans la liste.
  List<EquipmentInventoryItem> getEquipmentInventorySummary() {
    final canonicalCategories = [
      DomainObjectType.localMT,
      DomainObjectType.localBT,
      DomainObjectType.localGE,
      DomainObjectType.celluleMT,
      DomainObjectType.transformateurMTBT,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
      DomainObjectType.inverseur,
      DomainObjectType.priseTerre,
    ];

    return canonicalCategories.map((cat) {
      final summary = getCategorySummary(cat);
      return EquipmentInventoryItem(
        label: cat.label,
        count: summary.equipmentCount,
      );
    }).toList();
  }

  /// Statistiques par domaine de tension (MT vs BT).
  TensionDomainStats getTensionDomainStats() {
    int mt = 0;
    int bt = 0;

    for (final finding in pertinentFindings) {
      if (finding.tensionDomain == TensionDomain.mt) {
        mt++;
      } else {
        bt++;
      }
    }

    final tot = pertinentFindings.length;
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

  /// Top N des types de défauts récurrents.
  List<TopDefectItem> getTopDefects({int limit = 10}) {
    return getParetoAnalysis(limit: limit).items;
  }

  /// Analyse de Pareto mathématique dynamique sur les points de vérification (réponses "Non").
  ParetoAnalysisResult getParetoAnalysis({int limit = 10}) {
    final counts = <String, int>{};
    for (final f in pertinentFindings) {
      final key = CanonicalDefectCategoryRegistry.mapToCanonical(
        f.verificationPoint,
        riskFamily: f.riskFamily,
      );
      if (key.isNotEmpty) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final total = pertinentFindings.length;
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double runningCumul = 0.0;
    int paretoK = 0;
    double paretoCumulPct = 0.0;
    final topList = <TopDefectItem>[];

    for (int i = 0; i < sortedEntries.length && i < limit; i++) {
      final entry = sortedEntries[i];
      final pct = total > 0 ? (entry.value / total) * 100.0 : 0.0;
      runningCumul += pct;

      if (paretoK == 0 && (runningCumul >= 80.0 || i == sortedEntries.length - 1)) {
        paretoK = i + 1;
        paretoCumulPct = runningCumul;
      }

      topList.add(TopDefectItem(
        title: entry.key,
        count: entry.value,
        percentage: pct,
        cumulativePercentage: runningCumul,
      ));
    }

    if (paretoK == 0 && sortedEntries.isNotEmpty) {
      paretoK = sortedEntries.length;
      paretoCumulPct = runningCumul;
    }

    final totalDistinctCategories = counts.length;
    final summary = total > 0
        ? 'L\'analyse porte sur l\'intégralité des $total non-conformités relevées sur le site, regroupées sous $totalDistinctCategories catégories de défauts normalisées. Les $paretoK premières catégories concentrent à elles seules ${paretoCumulPct.toStringAsFixed(1).replaceAll('.', ',')} % du total des défaillances (seuil de 80 %).'
        : 'Aucune non-conformité recensée pour l\'analyse de Pareto.';

    return ParetoAnalysisResult(
      items: topList,
      totalOccurrences: total,
      paretoCategoryCount: paretoK,
      paretoCumulativePercentage: paretoCumulPct,
      summaryText: summary,
    );
  }

  /// Calcule dynamiquement les 2 catégories d'équipements générant le plus de non-conformités.
  TopNonConformityCategoriesResult getTopTwoNonConformityCategories() {
    final crossList = getCrossCategoryAnalysis();
    final totalNC = pertinentFindings.length;
    final totalEqSummary = getEquipmentInventorySummary().fold<int>(0, (sum, e) => sum + e.count);
    final totalEq = totalEqSummary > 0 ? totalEqSummary : instances.length;

    if (crossList.isEmpty || totalNC == 0) {
      return TopNonConformityCategoriesResult(
        label: 'Concentration Équipements',
        cat1Name: 'Équipements',
        combinedNC: 0,
        pctTotalNC: 0.0,
        combinedEquipments: 0,
        pctParc: 0.0,
        formattedValue: '0 NC (0,0 %), sur 0 équipement',
      );
    }

    final sorted = List<CategoryCrossItem>.from(crossList)
      ..sort((a, b) {
        final cmpNC = b.nonCompliantPointsCount.compareTo(a.nonCompliantPointsCount);
        if (cmpNC != 0) return cmpNC;
        final cmpCrit = b.critiqueCount.compareTo(a.critiqueCount);
        if (cmpCrit != 0) return cmpCrit;
        return a.categoryName.compareTo(b.categoryName);
      });

    final cat1 = sorted.first;
    if (sorted.length == 1 || sorted[1].nonCompliantPointsCount == 0) {
      final combinedNC = cat1.nonCompliantPointsCount;
      final pctNC = totalNC > 0 ? (combinedNC / totalNC) * 100 : 0.0;
      final combinedEq = cat1.equipmentCount;
      final pctParc = totalEq > 0 ? (combinedEq / totalEq) * 100 : 0.0;
      final labelStr = 'Concentration ${cat1.categoryName}';
      final valStr = '$combinedNC NC, soit ${pctNC.toStringAsFixed(1).replaceAll('.', ',')} % du total, sur $combinedEq équipement(s) (${pctParc.toStringAsFixed(1).replaceAll('.', ',')} % du parc)';
      return TopNonConformityCategoriesResult(
        label: labelStr,
        cat1Name: cat1.categoryName,
        combinedNC: combinedNC,
        pctTotalNC: pctNC,
        combinedEquipments: combinedEq,
        pctParc: pctParc,
        formattedValue: valStr,
      );
    }

    final cat2 = sorted[1];
    final combinedNC = cat1.nonCompliantPointsCount + cat2.nonCompliantPointsCount;
    final pctNC = totalNC > 0 ? (combinedNC / totalNC) * 100 : 0.0;
    final combinedEq = cat1.equipmentCount + cat2.equipmentCount;
    final pctParc = totalEq > 0 ? (combinedEq / totalEq) * 100 : 0.0;
    final labelStr = 'Concentration ${cat1.categoryName} + ${cat2.categoryName}';
    final valStr = '$combinedNC NC, soit ${pctNC.toStringAsFixed(1).replaceAll('.', ',')} % du total, sur $combinedEq équipements (${pctParc.toStringAsFixed(1).replaceAll('.', ',')} % du parc)';

    return TopNonConformityCategoriesResult(
      label: labelStr,
      cat1Name: cat1.categoryName,
      cat2Name: cat2.categoryName,
      combinedNC: combinedNC,
      pctTotalNC: pctNC,
      combinedEquipments: combinedEq,
      pctParc: pctParc,
      formattedValue: valStr,
    );
  }

  /// Analyse de Pareto mathématique dynamique sur les 10 catégories d'équipements/installations.
  CategoryParetoResult getCategoryParetoAnalysis() {
    final crossList = getCrossCategoryAnalysis();
    final totalNC = pertinentFindings.length;

    if (crossList.isEmpty || totalNC == 0) {
      return CategoryParetoResult(
        items: [],
        totalNonConformities: 0,
        paretoCategoryCount: 0,
        paretoCumulativePercentage: 0.0,
        summaryText: 'Aucune non-conformité recensée pour l\'analyse de Pareto par catégorie.',
      );
    }

    final sorted = List<CategoryCrossItem>.from(crossList)
      ..sort((a, b) {
        final cmpNC = b.nonCompliantPointsCount.compareTo(a.nonCompliantPointsCount);
        if (cmpNC != 0) return cmpNC;
        final cmpCrit = b.critiqueCount.compareTo(a.critiqueCount);
        if (cmpCrit != 0) return cmpCrit;
        return a.categoryName.compareTo(b.categoryName);
      });

    double runningCumul = 0.0;
    int paretoK = 0;
    double paretoCumulPct = 0.0;
    final paretoItems = <CategoryParetoItem>[];

    for (int i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      final pct = (item.nonCompliantPointsCount / totalNC) * 100.0;
      runningCumul += pct;

      if (paretoK == 0 && (runningCumul >= 80.0 || i == sorted.length - 1)) {
        paretoK = i + 1;
        paretoCumulPct = runningCumul;
      }

      paretoItems.add(CategoryParetoItem(
        categoryName: item.categoryName,
        categoryKey: item.categoryKey,
        nonConformitiesCount: item.nonCompliantPointsCount,
        equipmentCount: item.equipmentCount,
        percentage: pct,
        cumulativePercentage: runningCumul,
      ));
    }

    if (paretoK == 0 && sorted.isNotEmpty) {
      paretoK = sorted.length;
      paretoCumulPct = runningCumul;
    }

    final summary = 'Les $totalNC non-conformités relevées sur les 10 catégories d\'équipements ont été classées par fréquence décroissante. L\'analyse de Pareto ci-dessous met en évidence que les $paretoK principales catégories concentrent ${paretoCumulPct.toStringAsFixed(1).replaceAll('.', ',')} % du volume global des défauts.';

    return CategoryParetoResult(
      items: paretoItems,
      totalNonConformities: totalNC,
      paretoCategoryCount: paretoK,
      paretoCumulativePercentage: paretoCumulPct,
      summaryText: summary,
    );
  }

  /// Calcule dynamiquement la catégorie la plus dense en non-conformités par équipement.
  String getDensestCategoryFormatted() {
    final crossList = getCrossCategoryAnalysis().where((c) => c.equipmentCount > 0).toList();
    if (crossList.isEmpty) return 'Aucun équipement recensé (0,0 NC/équipement)';

    // Départage :
    // 1. Densité NC/équipement (décroissante)
    // 2. Volume total de NC (décroissant)
    // 3. Ordre métier canonique déterministe (conservé par la position dans crossList)
    crossList.sort((a, b) {
      final cmpDens = b.density.compareTo(a.density);
      if (cmpDens != 0) return cmpDens;
      return b.nonCompliantPointsCount.compareTo(a.nonCompliantPointsCount);
    });

    final densest = crossList.first;
    if (densest.nonCompliantPointsCount == 0) {
      return 'Toutes catégories conformes (0,0 NC/équipement)';
    }

    final critPct = densest.nonCompliantPointsCount > 0
        ? (densest.critiqueCount / densest.nonCompliantPointsCount) * 100
        : 0.0;
    return '${densest.categoryName} : ${densest.density.toStringAsFixed(1).replaceAll('.', ',')} NC/équipement (dont ${densest.critiqueCount} critique(s) sur ${densest.nonCompliantPointsCount} NC, soit ${critPct.toStringAsFixed(1).replaceAll('.', ',')} %)';
  }

  /// Statistiques par famille de risque.
  List<RiskFamilyItem> getRiskFamilyStats() {
    final counts = <String, int>{};
    for (final f in allFindings) {
      final family = f.riskFamily?.trim();
      if (family != null && family.isNotEmpty) {
        counts[family] = (counts[family] ?? 0) + 1;
      }
    }

    final total = counts.values.fold<int>(0, (sum, c) => sum + c);
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      return RiskFamilyItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Statistiques par catégorie d'installation.
  List<InstallationTypeItem> getInstallationTypeStats() {
    final counts = <String, int>{};
    for (final f in allFindings) {
      final type = f.objectType.trim();
      if (type.isNotEmpty) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }

    final total = allFindings.length;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final pct = total > 0 ? (e.value / total) * 100 : 0.0;
      return InstallationTypeItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  int get critiqueCount => allFindings.where((f) => f.criticality == 'Critique').length;
  int get majeureCount => allFindings.where((f) => f.criticality == 'Majeure').length;
  int get mineureCount => allFindings.where((f) => f.criticality == 'Mineure').length;
  int get classifiedCount => critiqueCount + majeureCount + mineureCount;
  double get pctCritique => classifiedCount > 0 ? (critiqueCount / classifiedCount) * 100 : 0.0;
  double get pctMajeure => classifiedCount > 0 ? (majeureCount / classifiedCount) * 100 : 0.0;
  double get pctMineure => classifiedCount > 0 ? (mineureCount / classifiedCount) * 100 : 0.0;
}

/// Moteur de Récensement et d'Inventaire Métier Centralisé (`MissionDomainInventoryEngine`).
///
/// Responsabilité Unique : Réaliser un parcours unique, déterministe et intelligent
/// de 100 % des objets métiers d'une mission et construire le registre certifié [MissionDomainInventory].
class MissionDomainInventoryEngine {
  static MissionDomainInventory buildInventory(String missionId) {
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

    final instances = <DomainEntityInstance>[];
    final allFindings = <AuditFinding>[];
    final seenFindingIds = <String>{};

    final visitedMTLocaux = <int>{};
    final visitedBTLocaux = <int>{};
    final visitedCoffrets = <int>{};
    final visitedCellules = <int>{};
    final visitedTransfos = <int>{};

    void addFinding(DomainEntityInstance instance, AuditFinding finding) {
      if (!seenFindingIds.contains(finding.id)) {
        seenFindingIds.add(finding.id);
        instance.findings.add(finding);
        allFindings.add(finding);
      }
    }

    if (audit != null) {
      // 1. MOYENNE TENSION : LOCAUX DIRECTS
      for (var lIdx = 0; lIdx < audit.moyenneTensionLocaux.length; lIdx++) {
        final local = audit.moyenneTensionLocaux[lIdx];
        local.migrateFromOldFields();
        _visitMTLocal(
          missionId: missionId,
          local: local,
          originNom: 'Local MT "${local.nom}"',
          parentZone: null,
          instances: instances,
          addFinding: addFinding,
          visitedMTLocaux: visitedMTLocaux,
          visitedCoffrets: visitedCoffrets,
          visitedCellules: visitedCellules,
          visitedTransfos: visitedTransfos,
        );
      }

      // 2. MOYENNE TENSION : ZONES
      for (var zIdx = 0; zIdx < audit.moyenneTensionZones.length; zIdx++) {
        final zone = audit.moyenneTensionZones[zIdx];
        for (var lIdx = 0; lIdx < zone.locaux.length; lIdx++) {
          final local = zone.locaux[lIdx];
          local.migrateFromOldFields();
          _visitMTLocal(
            missionId: missionId,
            local: local,
            originNom: 'Zone MT "${zone.nom}" / Local "${local.nom}"',
            parentZone: zone.nom,
            instances: instances,
            addFinding: addFinding,
            visitedMTLocaux: visitedMTLocaux,
            visitedCoffrets: visitedCoffrets,
            visitedCellules: visitedCellules,
            visitedTransfos: visitedTransfos,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffrets.length; eqIdx++) {
          final coffret = zone.coffrets[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            originNom: 'Zone MT "${zone.nom}"',
            parentZone: zone.nom,
            parentLocal: null,
            defaultTensionDomain: TensionDomain.mt,
            instances: instances,
            addFinding: addFinding,
            visitedCoffrets: visitedCoffrets,
          );
        }
      }

      // 3. BASSE TENSION : ZONES & LOCAUX
      for (var zIdx = 0; zIdx < audit.basseTensionZones.length; zIdx++) {
        final zone = audit.basseTensionZones[zIdx];
        for (var lIdx = 0; lIdx < zone.locaux.length; lIdx++) {
          final local = zone.locaux[lIdx];
          _visitBTLocal(
            missionId: missionId,
            local: local,
            originNom: 'Zone BT "${zone.nom}" / Local "${local.nom}"',
            parentZone: zone.nom,
            instances: instances,
            addFinding: addFinding,
            visitedBTLocaux: visitedBTLocaux,
            visitedCoffrets: visitedCoffrets,
            visitedCellules: visitedCellules,
            visitedTransfos: visitedTransfos,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffretsDirects.length; eqIdx++) {
          final coffret = zone.coffretsDirects[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            originNom: 'Zone BT "${zone.nom}"',
            parentZone: zone.nom,
            parentLocal: null,
            defaultTensionDomain: TensionDomain.bt,
            instances: instances,
            addFinding: addFinding,
            visitedCoffrets: visitedCoffrets,
          );
        }
      }
    }

    // 4. MODULE FOUDRE
    if (foudres.isNotEmpty) {
      for (var i = 0; i < foudres.length; i++) {
        final f = foudres[i];
        if (f.observation.trim().isNotEmpty) {
          final hash = identityHashCode(f);
          final inst = DomainEntityInstance(
            instanceId: 'foudre_inst_$hash',
            category: DomainObjectType.foudre,
            name: 'Installation Foudre ${i + 1}',
            tensionDomain: TensionDomain.bt,
            originPath: 'Module Foudre',
            rawModelRef: f,
          );

          final finding = AuditFinding(
            id: 'foudre_hash_${hash}_obs_$i',
            missionId: missionId,
            tensionDomain: TensionDomain.bt,
            origin: 'Module Foudre',
            objectType: DomainObjectType.foudre.normalizedObjectType,
            objectName: 'Installation Foudre',
            tableName: 'Observations Foudre',
            verificationPoint: 'Observation Foudre ${i + 1}',
            observationText: f.observation,
            conformity: 'non',
            criticality: 'Non spécifiée',
            priority: f.niveauPriorite,
          );

          inst.registerCheckpoint(conformity: 'non', criticality: 'Non spécifiée');
          addFinding(inst, finding);
          instances.add(inst);
        }
      }
    }

    // 5. PRISES DE TERRE (depuis MesuresEssais)
    try {
      final mesuresEssais = HiveService.getMesuresEssaisByMissionId(missionId);
      if (mesuresEssais != null && mesuresEssais.prisesTerre.isNotEmpty) {
        for (var i = 0; i < mesuresEssais.prisesTerre.length; i++) {
          final pt = mesuresEssais.prisesTerre[i];
          final ptHash = identityHashCode(pt);
          final ptName = pt.identification.isNotEmpty ? pt.identification : 'PT ${i + 1}';
          final ptInst = DomainEntityInstance(
            instanceId: 'prise_terre_$ptHash',
            category: DomainObjectType.priseTerre,
            name: ptName,
            tensionDomain: TensionDomain.bt,
            originPath: 'Mesures & Essais > Prises de terre > ${pt.localisation}',
            rawModelRef: pt,
          );

          // Chaque prise de terre est un « point » complet :
          // si elle a une observation renseignée avec une valeur de mesure, c'est un point évalué.
          if (pt.isComplete) {
            final obsLower = (pt.observation ?? '').trim().toLowerCase();
            if (obsLower.contains('non satisfaisant') || obsLower.contains('non conforme')) {
              ptInst.registerCheckpoint(conformity: 'non', criticality: 'Majeure');
              addFinding(
                ptInst,
                AuditFinding(
                  id: 'prise_terre_${ptHash}_nc',
                  missionId: missionId,
                  tensionDomain: TensionDomain.bt,
                  origin: 'Mesures & Essais > Prises de terre',
                  objectType: DomainObjectType.priseTerre.normalizedObjectType,
                  objectName: ptName,
                  tableName: 'Prises de terre',
                  verificationPoint: 'Valeur de résistance prise de terre',
                  observationText: '${pt.identification} — ${pt.localisation} : ${pt.valeurMesure ?? "?"} Ω — ${pt.observation}',
                  conformity: 'non',
                  criticality: 'Majeure',
                ),
              );
            } else {
              ptInst.registerCheckpoint(conformity: 'oui');
            }
          }

          instances.add(ptInst);
        }
      }
    } catch (_) {
      // En environnement de test sans Hive actif, ignorer.
    }

    return MissionDomainInventory(
      missionId: missionId,
      instances: instances,
      allFindings: allFindings,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITEUR MT
  // ──────────────────────────────────────────────────────────────

  static void _visitMTLocal({
    required String missionId,
    required MoyenneTensionLocal local,
    required String originNom,
    required String? parentZone,
    required List<DomainEntityInstance> instances,
    required Function(DomainEntityInstance, AuditFinding) addFinding,
    required Set<int> visitedMTLocaux,
    required Set<int> visitedCoffrets,
    required Set<int> visitedCellules,
    required Set<int> visitedTransfos,
  }) {
    final localHash = identityHashCode(local);
    if (visitedMTLocaux.contains(localHash)) return;
    visitedMTLocaux.add(localHash);

    final localType = local.type.isNotEmpty ? local.type : 'LOCAL_POSTE_HTA';

    final localInstance = DomainEntityInstance(
      instanceId: 'mt_local_$localHash',
      category: DomainObjectType.localMT,
      name: local.nom,
      tensionDomain: TensionDomain.mt,
      originPath: originNom,
      parentZone: parentZone,
      rawModelRef: local,
    );

    // Dispositions constructives
    for (var i = 0; i < local.dispositionsConstructives.length; i++) {
      final el = local.dispositionsConstructives[i];
      final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
      final crit = _resolveCriticalityString(el, localType: localType);
      localInstance.registerCheckpoint(conformity: confStr, criticality: crit);

      if (el.conforme == false && !el.estNA) {
        addFinding(
          localInstance,
          AuditFinding(
            id: 'mt_local_${localHash}_dc_$i',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: originNom,
            objectType: 'Local MT',
            objectName: local.nom,
            tableName: 'Dispositions constructives',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: crit,
            priority: el.priorite,
            normativeReference: el.referenceNormativeEffectiveFor(localType: localType),
            riskFamily: el.familleRisqueEffectiveFor(localType: localType),
            photos: el.photos,
          ),
        );
      }
    }

    // Conditions d'exploitation
    for (var i = 0; i < local.conditionsExploitation.length; i++) {
      final el = local.conditionsExploitation[i];
      final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
      final crit = _resolveCriticalityString(el, localType: localType);
      localInstance.registerCheckpoint(conformity: confStr, criticality: crit);

      if (el.conforme == false && !el.estNA) {
        addFinding(
          localInstance,
          AuditFinding(
            id: 'mt_local_${localHash}_ce_$i',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: originNom,
            objectType: 'Local MT',
            objectName: local.nom,
            tableName: 'Conditions d\'exploitation',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: crit,
            priority: el.priorite,
            normativeReference: el.referenceNormativeEffectiveFor(localType: localType),
            riskFamily: el.familleRisqueEffectiveFor(localType: localType),
            photos: el.photos,
          ),
        );
      }
    }

    instances.add(localInstance);

    // Cellules MT
    final cellulesToVisit = local.cellules.isNotEmpty
        ? local.cellules
        : (local.cellule != null ? [local.cellule!] : <Cellule>[]);

    for (var i = 0; i < cellulesToVisit.length; i++) {
      final cellule = cellulesToVisit[i];
      _visitCellule(
        missionId: missionId,
        cellule: cellule,
        celluleIndex: i,
        originNom: '$originNom > Cellule ${cellule.fonction}',
        parentZone: parentZone,
        parentLocal: local.nom,
        instances: instances,
        addFinding: addFinding,
        visitedCellules: visitedCellules,
        localType: localType,
      );
    }

    // Transformateurs MT/BT
    final transfosToVisit = local.transformateurs.isNotEmpty
        ? local.transformateurs
        : (local.transformateur != null ? [local.transformateur!] : <TransformateurMTBT>[]);

    for (var i = 0; i < transfosToVisit.length; i++) {
      final transfo = transfosToVisit[i];
      _visitTransformateur(
        missionId: missionId,
        transfo: transfo,
        transfoIndex: i,
        originNom: '$originNom > Transformateur ${i + 1}',
        parentZone: parentZone,
        parentLocal: local.nom,
        instances: instances,
        addFinding: addFinding,
        visitedTransfos: visitedTransfos,
        localType: localType,
      );
    }

    // Équipements dans ce local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        originNom: originNom,
        parentZone: parentZone,
        parentLocal: local.nom,
        defaultTensionDomain: TensionDomain.mt,
        instances: instances,
        addFinding: addFinding,
        visitedCoffrets: visitedCoffrets,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITEUR BT & GROUPE ÉLECTROGÈNE
  // ──────────────────────────────────────────────────────────────

  static void _visitBTLocal({
    required String missionId,
    required BasseTensionLocal local,
    required String originNom,
    required String? parentZone,
    required List<DomainEntityInstance> instances,
    required Function(DomainEntityInstance, AuditFinding) addFinding,
    required Set<int> visitedBTLocaux,
    required Set<int> visitedCoffrets,
    required Set<int> visitedCellules,
    required Set<int> visitedTransfos,
  }) {
    final localHash = identityHashCode(local);
    if (visitedBTLocaux.contains(localHash)) return;
    visitedBTLocaux.add(localHash);

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE' || local.nom.toLowerCase().contains('groupe');
    final category = isGE ? DomainObjectType.localGE : DomainObjectType.localBT;
    final typeObjetName = isGE ? 'Groupe Électrogène' : 'Local BT';

    final localInstance = DomainEntityInstance(
      instanceId: 'bt_local_$localHash',
      category: category,
      name: local.nom,
      tensionDomain: TensionDomain.bt,
      originPath: originNom,
      parentZone: parentZone,
      rawModelRef: local,
    );

    // Dispositions constructives
    if (local.dispositionsConstructives != null) {
      for (var i = 0; i < local.dispositionsConstructives!.length; i++) {
        final el = local.dispositionsConstructives![i];
        final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
        final crit = _resolveCriticalityString(el, localType: local.type);
        localInstance.registerCheckpoint(conformity: confStr, criticality: crit);

        if (el.conforme == false && !el.estNA) {
          addFinding(
            localInstance,
            AuditFinding(
              id: 'bt_local_${localHash}_dc_$i',
              missionId: missionId,
              tensionDomain: TensionDomain.bt,
              origin: originNom,
              objectType: typeObjetName,
              objectName: local.nom,
              tableName: 'Dispositions constructives',
              verificationPoint: el.elementControle,
              observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
              conformity: 'non',
              criticality: crit,
              priority: el.priorite,
              normativeReference: el.referenceNormativeEffectiveFor(localType: local.type),
              riskFamily: el.familleRisqueEffectiveFor(localType: local.type),
              photos: el.photos,
            ),
          );
        }
      }
    }

    // Conditions d'exploitation
    if (local.conditionsExploitation != null) {
      for (var i = 0; i < local.conditionsExploitation!.length; i++) {
        final el = local.conditionsExploitation![i];
        final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
        final crit = _resolveCriticalityString(el, localType: local.type);
        localInstance.registerCheckpoint(conformity: confStr, criticality: crit);

        if (el.conforme == false && !el.estNA) {
          addFinding(
            localInstance,
            AuditFinding(
              id: 'bt_local_${localHash}_ce_$i',
              missionId: missionId,
              tensionDomain: TensionDomain.bt,
              origin: originNom,
              objectType: typeObjetName,
              objectName: local.nom,
              tableName: 'Conditions d\'exploitation',
              verificationPoint: el.elementControle,
              observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
              conformity: 'non',
              criticality: crit,
              priority: el.priorite,
              normativeReference: el.referenceNormativeEffectiveFor(localType: local.type),
              riskFamily: el.familleRisqueEffectiveFor(localType: local.type),
              photos: el.photos,
            ),
          );
        }
      }
    }

    instances.add(localInstance);

    // Cellules éventuelles dans ce local
    for (var i = 0; i < local.cellules.length; i++) {
      final cellule = local.cellules[i];
      _visitCellule(
        missionId: missionId,
        cellule: cellule,
        celluleIndex: i,
        originNom: '$originNom > Cellule ${cellule.fonction}',
        parentZone: parentZone,
        parentLocal: local.nom,
        instances: instances,
        addFinding: addFinding,
        visitedCellules: visitedCellules,
        localType: local.type,
      );
    }

    // Transformateurs éventuels dans ce local
    for (var i = 0; i < local.transformateurs.length; i++) {
      final transfo = local.transformateurs[i];
      _visitTransformateur(
        missionId: missionId,
        transfo: transfo,
        transfoIndex: i,
        originNom: '$originNom > Transformateur ${i + 1}',
        parentZone: parentZone,
        parentLocal: local.nom,
        instances: instances,
        addFinding: addFinding,
        visitedTransfos: visitedTransfos,
        localType: local.type,
      );
    }

    // Équipements dans ce local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        originNom: originNom,
        parentZone: parentZone,
        parentLocal: local.nom,
        defaultTensionDomain: TensionDomain.bt,
        instances: instances,
        addFinding: addFinding,
        visitedCoffrets: visitedCoffrets,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITEURS CELLULE & TRANSFORMATEUR
  // ──────────────────────────────────────────────────────────────

  static void _visitCellule({
    required String missionId,
    required Cellule cellule,
    required int celluleIndex,
    required String originNom,
    required String? parentZone,
    required String? parentLocal,
    required List<DomainEntityInstance> instances,
    required Function(DomainEntityInstance, AuditFinding) addFinding,
    required Set<int> visitedCellules,
    String? localType,
  }) {
    final cellHash = identityHashCode(cellule);
    if (visitedCellules.contains(cellHash)) return;
    visitedCellules.add(cellHash);

    final itemLabel = 'Cellule ${celluleIndex + 1} (${cellule.fonction})';
    final instance = DomainEntityInstance(
      instanceId: 'cellule_$cellHash',
      category: DomainObjectType.celluleMT,
      name: itemLabel,
      tensionDomain: TensionDomain.mt,
      originPath: originNom,
      parentZone: parentZone,
      parentLocal: parentLocal,
      rawModelRef: cellule,
    );

    for (var j = 0; j < cellule.elementsVerifies.length; j++) {
      final el = cellule.elementsVerifies[j];
      final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
      final crit = _resolveCriticalityString(el, localType: localType);
      instance.registerCheckpoint(conformity: confStr, criticality: crit);

      if (el.conforme == false && !el.estNA) {
        addFinding(
          instance,
          AuditFinding(
            id: 'cell_${cellHash}_el_$j',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: originNom,
            objectType: 'Cellule MT',
            objectName: itemLabel,
            tableName: 'Tableau Cellule',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: crit,
            priority: el.priorite,
            normativeReference: el.referenceNormativeEffectiveFor(localType: localType),
            riskFamily: el.familleRisqueEffectiveFor(localType: localType),
            photos: el.photos,
          ),
        );
      }
    }

    if (instance.totalCheckpoints > 0 || instance.findings.isNotEmpty) {
      instances.add(instance);
    }
  }

  static void _visitTransformateur({
    required String missionId,
    required TransformateurMTBT transfo,
    required int transfoIndex,
    required String originNom,
    required String? parentZone,
    required String? parentLocal,
    required List<DomainEntityInstance> instances,
    required Function(DomainEntityInstance, AuditFinding) addFinding,
    required Set<int> visitedTransfos,
    String? localType,
  }) {
    final transfoHash = identityHashCode(transfo);
    if (visitedTransfos.contains(transfoHash)) return;
    visitedTransfos.add(transfoHash);

    final itemLabel = 'Transformateur ${transfoIndex + 1}';
    final instance = DomainEntityInstance(
      instanceId: 'transfo_$transfoHash',
      category: DomainObjectType.transformateurMTBT,
      name: itemLabel,
      tensionDomain: TensionDomain.mt,
      originPath: originNom,
      parentZone: parentZone,
      parentLocal: parentLocal,
      rawModelRef: transfo,
    );

    for (var j = 0; j < transfo.elementsVerifies.length; j++) {
      final el = transfo.elementsVerifies[j];
      final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
      final crit = _resolveCriticalityString(el, localType: localType);
      instance.registerCheckpoint(conformity: confStr, criticality: crit);

      if (el.conforme == false && !el.estNA) {
        addFinding(
          instance,
          AuditFinding(
            id: 'transfo_${transfoHash}_el_$j',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: originNom,
            objectType: 'Transformateur MT/BT',
            objectName: itemLabel,
            tableName: 'Tableau Transformateur',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: crit,
            priority: el.priorite,
            normativeReference: el.referenceNormativeEffectiveFor(localType: localType),
            riskFamily: el.familleRisqueEffectiveFor(localType: localType),
            photos: el.photos,
          ),
        );
      }
    }

    if (instance.totalCheckpoints > 0 || instance.findings.isNotEmpty) {
      instances.add(instance);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITEUR ÉQUIPEMENT (TGBT, Armoire, Coffret, Inverseur)
  // ──────────────────────────────────────────────────────────────

  static void _visitEquipement({
    required String missionId,
    required CoffretArmoire coffret,
    required String originNom,
    required String? parentZone,
    required String? parentLocal,
    TensionDomain defaultTensionDomain = TensionDomain.bt,
    required List<DomainEntityInstance> instances,
    required Function(DomainEntityInstance, AuditFinding) addFinding,
    required Set<int> visitedCoffrets,
  }) {
    final coffretHash = identityHashCode(coffret);
    if (visitedCoffrets.contains(coffretHash)) return;
    visitedCoffrets.add(coffretHash);

    final category = EquipmentClassifier.classify(coffret);
    final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
    // Utilisation du label normalisé canonique au lieu du type brut du modèle.
    // C'est la correction du bug TGBT : le type brut pouvait être "TGBT", "Tableau urbain réduit (TUR)", etc.
    // Le label normalisé est toujours déterministe : "TGBT", "Armoire", "Coffret", "Inverseur".
    final typeEquipementStr = category.normalizedObjectType;

    final instance = DomainEntityInstance(
      instanceId: 'eq_$coffretHash',
      category: category,
      name: coffret.nom,
      repere: coffretRepere,
      tensionDomain: defaultTensionDomain,
      originPath: originNom,
      parentZone: parentZone,
      parentLocal: parentLocal,
      rawModelRef: coffret,
    );

    // Points de vérification
    for (var i = 0; i < coffret.pointsVerification.length; i++) {
      final pv = coffret.pointsVerification[i];
      final conf = pv.conformite.trim().toLowerCase();
      final resolvedCriticality = _resolvePointVerificationCriticality(pv, coffret.type);

      instance.registerCheckpoint(conformity: conf, criticality: resolvedCriticality);

      if (_isNonConforme(pv.conformite)) {
        final resolvedNormRef = _resolvePointVerificationNormRef(pv, coffret.type);
        final resolvedRiskFamily = _resolvePointVerificationRiskFamily(pv, coffret.type);

        if (pv.observations != null && pv.observations!.isNotEmpty) {
          for (var j = 0; j < pv.observations!.length; j++) {
            final obs = pv.observations![j];
            final obsCriticality = (obs.criticite?.trim().isNotEmpty == true)
                ? _normalizeCriticalityLabel(obs.criticite!)
                : resolvedCriticality;

            addFinding(
              instance,
              AuditFinding(
                id: 'eq_${coffretHash}_pv_${i}_obs_$j',
                missionId: missionId,
                tensionDomain: defaultTensionDomain,
                origin: originNom,
                objectType: category.normalizedObjectType,
                objectName: coffret.nom,
                objectRepere: coffretRepere,
                tableName: 'Points de vérification',
                verificationPoint: pv.pointVerification,
                observationText: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                conformity: 'non',
                criticality: obsCriticality,
                priority: obs.priorite ?? pv.priorite,
                normativeReference: obs.referenceNormativeEffectiveFor() ?? resolvedNormRef,
                riskFamily: obs.familleRisqueEffectiveFor() ?? resolvedRiskFamily,
                photos: obs.photos.isNotEmpty ? obs.photos : pv.photos,
              ),
            );
          }
        } else {
          addFinding(
            instance,
            AuditFinding(
              id: 'eq_${coffretHash}_pv_$i',
              missionId: missionId,
              tensionDomain: defaultTensionDomain,
              origin: originNom,
              objectType: category.normalizedObjectType,
              objectName: coffret.nom,
              objectRepere: coffretRepere,
              tableName: 'Points de vérification',
              verificationPoint: pv.pointVerification,
              observationText: pv.observation?.isNotEmpty == true ? pv.observation! : pv.pointVerification,
              conformity: 'non',
              criticality: resolvedCriticality,
              priority: pv.priorite,
              normativeReference: resolvedNormRef,
              riskFamily: resolvedRiskFamily,
              photos: pv.photos,
            ),
          );
        }
      }
    }

    // Observations parafoudre enrichies
    if (coffret.presenceParafoudre && coffret.observationsParafoudreEnrichies != null) {
      for (var i = 0; i < coffret.observationsParafoudreEnrichies!.length; i++) {
        final el = coffret.observationsParafoudreEnrichies![i];
        final confStr = el.estNA ? 'na' : (el.conforme == true ? 'oui' : 'non');
        final crit = _resolveCriticalityString(el);
        instance.registerCheckpoint(conformity: confStr, criticality: crit);

        if (el.conforme == false && !el.estNA) {
          addFinding(
            instance,
            AuditFinding(
              id: 'eq_${coffretHash}_parafoudre_$i',
              missionId: missionId,
              tensionDomain: defaultTensionDomain,
              origin: originNom,
              objectType: category.normalizedObjectType,
              objectName: '${coffret.nom} (Parafoudre)',
              objectRepere: coffretRepere,
              tableName: 'Observations Parafoudre',
              verificationPoint: el.elementControle,
              observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
              conformity: 'non',
              criticality: crit,
              priority: el.priorite,
              normativeReference: el.referenceNormativeEffectiveFor(),
              riskFamily: el.familleRisqueEffectiveFor(),
              photos: el.photos,
            ),
          );
        }
      }
    }

    instances.add(instance);
  }

  // ──────────────────────────────────────────────────────────────
  //  RÉSOLUTION DE CRITICITÉ NORMÉE
  // ──────────────────────────────────────────────────────────────

  static String _resolveCriticalityString(ElementControle el, {String? localType}) {
    final criticiteStr = el.criticiteEffectiveFor(localType: localType);
    if (criticiteStr != null && criticiteStr.trim().isNotEmpty) {
      final s = criticiteStr.trim().toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    final directVal = el.criticite?.trim();
    if (directVal != null && directVal.isNotEmpty) {
      final s = directVal.toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    return 'Non spécifiée';
  }

  static String _resolvePointVerificationCriticality(PointVerification pv, String coffretType) {
    final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
    if (meta != null && meta.criticite.trim().isNotEmpty) {
      return _normalizeCriticalityLabel(meta.criticite);
    }
    final directVal = pv.criticite?.trim();
    if (directVal != null && directVal.isNotEmpty) {
      return _normalizeCriticalityLabel(directVal);
    }
    return 'Non spécifiée';
  }

  static String? _resolvePointVerificationNormRef(PointVerification pv, String coffretType) {
    if (pv.referenceNormative?.trim().isNotEmpty == true) {
      return DispositionsConstructivesRegistry.normalizeNormativeReference(pv.referenceNormative);
    }
    final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
    if (meta != null && meta.referenceNormative.trim().isNotEmpty) {
      return DispositionsConstructivesRegistry.normalizeNormativeReference(meta.referenceNormative);
    }
    return pv.referenceNormative;
  }

  static String? _resolvePointVerificationRiskFamily(PointVerification pv, String coffretType) {
    if (pv.familleRisque?.trim().isNotEmpty == true) {
      return pv.familleRisque;
    }
    final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
    if (meta != null && meta.familleRisque.trim().isNotEmpty) {
      return meta.familleRisque;
    }
    return null;
  }

  static String _normalizeCriticalityLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('critique')) return 'Critique';
    if (s.contains('majeur')) return 'Majeure';
    if (s.contains('mineur')) return 'Mineure';
    return 'Non spécifiée';
  }

  static bool _isNonConforme(String? conf) {
    if (conf == null) return false;
    final s = conf.trim().toLowerCase();
    return s == 'non' || s == 'non conforme' || s == 'non_conforme' || s == 'false';
  }
}
