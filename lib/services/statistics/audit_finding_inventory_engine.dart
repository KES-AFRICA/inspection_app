// lib/services/statistics/audit_finding_inventory_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../hive_service.dart';
import '../dispositions_constructives_registry.dart';
import 'audit_finding.dart';
import 'domain_entity_instance.dart';
import 'mission_domain_inventory_engine.dart';

class _CategoryTracker {
  final String categoryKey;
  final String categoryName;
  int equipmentCount = 0;
  int compliantPoints = 0;
  int nonCompliantPoints = 0;
  int naPoints = 0;
  int critiqueCount = 0;
  int majeureCount = 0;
  int mineureCount = 0;

  _CategoryTracker(this.categoryKey, this.categoryName);

  int get totalPointsEvaluated => compliantPoints + nonCompliantPoints + naPoints;

  double get complianceRate {
    final evaluated = compliantPoints + nonCompliantPoints;
    if (evaluated > 0) {
      return (compliantPoints / evaluated) * 100.0;
    }
    if (totalPointsEvaluated > 0) {
      return (compliantPoints / totalPointsEvaluated) * 100.0;
    }
    return 100.0;
  }

  double get density => equipmentCount > 0 ? nonCompliantPoints / equipmentCount : 0.0;

  CategoryCrossItem toCategoryCrossItem() {
    return CategoryCrossItem(
      categoryKey: categoryKey,
      categoryName: categoryName,
      equipmentCount: equipmentCount,
      totalPointsEvaluated: totalPointsEvaluated,
      compliantPointsCount: compliantPoints,
      nonCompliantPointsCount: nonCompliantPoints,
      naPointsCount: naPoints,
      critiqueCount: critiqueCount,
      majeureCount: majeureCount,
      mineureCount: mineureCount,
      complianceRate: complianceRate,
      density: density,
    );
  }
}

/// Moteur de Récensement et d'Inventaire Unifié des Non-Conformités (`AuditFindingInventoryEngine`).
/// 
/// Responsabilité Unique : Déléguer à `MissionDomainInventoryEngine` pour garantir
/// une SOURCE UNIQUE DE VÉRITÉ absolue entre l'inventaire physique et les non-conformités.
class AuditFindingInventoryEngine {
  /// Génère l'inventaire brut exhaustif pour une mission donnée.
  static AuditFindingInventory buildInventory(String missionId) {
    final domainInventory = MissionDomainInventoryEngine.buildInventory(missionId);

    return AuditFindingInventory(
      missionId: missionId,
      findings: domainInventory.allFindings,
      crossCategoryItems: domainInventory.getCrossCategoryAnalysis(),
    );
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

  /// Normalise un libellé de criticité brut vers les trois valeurs canoniques.
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

  static void _incrementCriticality(_CategoryTracker tracker, String crit) {
    final s = crit.trim().toLowerCase();
    if (s.contains('critique')) {
      tracker.critiqueCount++;
    } else if (s.contains('majeur')) {
      tracker.majeureCount++;
    } else if (s.contains('mineur')) {
      tracker.mineureCount++;
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITATION DES INSTANCES PHYSIQUES
  // ──────────────────────────────────────────────────────────────

  static void _visitMTLocal({
    required String missionId,
    required MoyenneTensionLocal local,
    required String originNom,
    required Function(AuditFinding) addFinding,
    required Set<int> visitedMTLocaux,
    required Set<int> visitedCoffrets,
    required Map<String, _CategoryTracker> trackers,
  }) {
    final localHash = identityHashCode(local);
    if (visitedMTLocaux.contains(localHash)) return;
    visitedMTLocaux.add(localHash);

    trackers['local_mt']?.equipmentCount++;
    final localType = local.type.isNotEmpty ? local.type : 'LOCAL_POSTE_HTA';

    // Dispositions constructives
    for (var i = 0; i < local.dispositionsConstructives.length; i++) {
      final el = local.dispositionsConstructives[i];
      if (el.estNA) {
        trackers['local_mt']?.naPoints++;
      } else if (el.conforme == true) {
        trackers['local_mt']?.compliantPoints++;
      } else if (el.conforme == false) {
        trackers['local_mt']?.nonCompliantPoints++;
        final crit = _resolveCriticalityString(el, localType: localType);
        _incrementCriticality(trackers['local_mt']!, crit);

        addFinding(AuditFinding(
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
        ));
      }
    }

    // Conditions d'exploitation
    for (var i = 0; i < local.conditionsExploitation.length; i++) {
      final el = local.conditionsExploitation[i];
      if (el.estNA) {
        trackers['local_mt']?.naPoints++;
      } else if (el.conforme == true) {
        trackers['local_mt']?.compliantPoints++;
      } else if (el.conforme == false) {
        trackers['local_mt']?.nonCompliantPoints++;
        final crit = _resolveCriticalityString(el, localType: localType);
        _incrementCriticality(trackers['local_mt']!, crit);

        addFinding(AuditFinding(
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
        ));
      }
    }

    // Observations libres rattachées normativement
    for (var i = 0; i < local.observationsLibres.length; i++) {
      final obs = local.observationsLibres[i];
      if (obs.hasNormativeReference) {
        addFinding(AuditFinding(
          id: 'mt_local_${localHash}_obslib_$i',
          missionId: missionId,
          tensionDomain: TensionDomain.mt,
          origin: originNom,
          objectType: 'Local MT',
          objectName: local.nom,
          tableName: 'Observations libres',
          verificationPoint: obs.pointVerificationKey ?? 'Observation libre',
          observationText: obs.texte,
          conformity: 'non',
          criticality: obs.criticite ?? 'Majeure',
          priority: 3,
          normativeReference: obs.referenceNormative,
          riskFamily: obs.familleRisque,
          photos: obs.photos,
        ));
      }
    }

    // Cellules MT
    for (var i = 0; i < local.cellules.length; i++) {
      final cellule = local.cellules[i];
      trackers['cellule_mt']?.equipmentCount++;
      final itemLabel = 'Cellule ${i + 1} (${cellule.fonction})';
      for (var j = 0; j < cellule.elementsVerifies.length; j++) {
        final el = cellule.elementsVerifies[j];
        if (el.estNA) {
          trackers['cellule_mt']?.naPoints++;
        } else if (el.conforme == true) {
          trackers['cellule_mt']?.compliantPoints++;
        } else if (el.conforme == false) {
          trackers['cellule_mt']?.nonCompliantPoints++;
          final crit = _resolveCriticalityString(el, localType: localType);
          _incrementCriticality(trackers['cellule_mt']!, crit);

          addFinding(AuditFinding(
            id: 'mt_local_${localHash}_cell_${i}_el_$j',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: '$originNom > Cellule ${cellule.fonction}',
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
          ));
        }
      }
    }

    // Transformateurs MT/BT
    for (var i = 0; i < local.transformateurs.length; i++) {
      final transfo = local.transformateurs[i];
      trackers['transfo_mt_bt']?.equipmentCount++;
      final itemLabel = 'Transformateur ${i + 1}';
      for (var j = 0; j < transfo.elementsVerifies.length; j++) {
        final el = transfo.elementsVerifies[j];
        if (el.estNA) {
          trackers['transfo_mt_bt']?.naPoints++;
        } else if (el.conforme == true) {
          trackers['transfo_mt_bt']?.compliantPoints++;
        } else if (el.conforme == false) {
          trackers['transfo_mt_bt']?.nonCompliantPoints++;
          final crit = _resolveCriticalityString(el, localType: localType);
          _incrementCriticality(trackers['transfo_mt_bt']!, crit);

          addFinding(AuditFinding(
            id: 'mt_local_${localHash}_transfo_${i}_el_$j',
            missionId: missionId,
            tensionDomain: TensionDomain.mt,
            origin: '$originNom > Transformateur ${i + 1}',
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
          ));
        }
      }
    }

    // Équipements du local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        originNom: originNom,
        addFinding: addFinding,
        visitedCoffrets: visitedCoffrets,
        defaultTensionDomain: TensionDomain.mt,
        trackers: trackers,
      );
    }
  }

  static void _visitBTLocal({
    required String missionId,
    required BasseTensionLocal local,
    required String originNom,
    required Function(AuditFinding) addFinding,
    required Set<int> visitedBTLocaux,
    required Set<int> visitedCoffrets,
    required Map<String, _CategoryTracker> trackers,
  }) {
    final localHash = identityHashCode(local);
    if (visitedBTLocaux.contains(localHash)) return;
    visitedBTLocaux.add(localHash);

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE' || local.nom.toLowerCase().contains('groupe');
    final catKey = isGE ? 'local_ge' : 'local_bt';
    final typeObjetName = isGE ? 'Groupe Électrogène' : 'Local BT';

    trackers[catKey]?.equipmentCount++;

    // Dispositions constructives
    if (local.dispositionsConstructives != null) {
      for (var i = 0; i < local.dispositionsConstructives!.length; i++) {
        final el = local.dispositionsConstructives![i];
        if (el.estNA) {
          trackers[catKey]?.naPoints++;
        } else if (el.conforme == true) {
          trackers[catKey]?.compliantPoints++;
        } else if (el.conforme == false) {
          trackers[catKey]?.nonCompliantPoints++;
          final crit = _resolveCriticalityString(el, localType: local.type);
          _incrementCriticality(trackers[catKey]!, crit);

          addFinding(AuditFinding(
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
          ));
        }
      }
    }

    // Conditions d'exploitation
    if (local.conditionsExploitation != null) {
      for (var i = 0; i < local.conditionsExploitation!.length; i++) {
        final el = local.conditionsExploitation![i];
        if (el.estNA) {
          trackers[catKey]?.naPoints++;
        } else if (el.conforme == true) {
          trackers[catKey]?.compliantPoints++;
        } else if (el.conforme == false) {
          trackers[catKey]?.nonCompliantPoints++;
          final crit = _resolveCriticalityString(el, localType: local.type);
          _incrementCriticality(trackers[catKey]!, crit);

          addFinding(AuditFinding(
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
          ));
        }
      }
    }

    // Équipements dans ce local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        originNom: originNom,
        addFinding: addFinding,
        visitedCoffrets: visitedCoffrets,
        defaultTensionDomain: TensionDomain.bt,
        trackers: trackers,
      );
    }
  }

  static void _visitEquipement({
    required String missionId,
    required CoffretArmoire coffret,
    required String originNom,
    required Function(AuditFinding) addFinding,
    required Set<int> visitedCoffrets,
    TensionDomain defaultTensionDomain = TensionDomain.bt,
    required Map<String, _CategoryTracker> trackers,
  }) {
    final coffretHash = identityHashCode(coffret);
    if (visitedCoffrets.contains(coffretHash)) return;
    visitedCoffrets.add(coffretHash);

    // Utilisation du classificateur centralisé pour le type d'équipement
    final category = EquipmentClassifier.classify(coffret);
    String catKey = category.categoryKey;
    // Normaliser la clé pour les trackers existants
    if (catKey == 'transfo_mt_bt' || catKey == 'cellule_mt' || catKey == 'local_mt' || catKey == 'local_bt' || catKey == 'local_ge' || catKey == 'foudre' || catKey == 'prise_terre') {
      catKey = 'coffret'; // fallback pour catégories non-équipement (ne devrait pas arriver)
    }

    trackers[catKey]?.equipmentCount++;

    final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
    // Label normalisé déterministe au lieu du type brut du modèle
    final typeEquipementStr = category.normalizedObjectType;

    // Points de vérification
    for (var i = 0; i < coffret.pointsVerification.length; i++) {
      final pv = coffret.pointsVerification[i];
      final conf = pv.conformite?.trim().toLowerCase();

      if (conf == 'na' || conf == 's.o.' || conf == 'so') {
        trackers[catKey]?.naPoints++;
      } else if (conf == 'oui' || conf == 'true') {
        trackers[catKey]?.compliantPoints++;
      } else if (_isNonConforme(pv.conformite)) {
        trackers[catKey]?.nonCompliantPoints++;
        final resolvedCriticality = _resolvePointVerificationCriticality(pv, coffret.type);
        _incrementCriticality(trackers[catKey]!, resolvedCriticality);

        final resolvedNormRef = _resolvePointVerificationNormRef(pv, coffret.type);
        final resolvedRiskFamily = _resolvePointVerificationRiskFamily(pv, coffret.type);

        if (pv.observations != null && pv.observations!.isNotEmpty) {
          for (var j = 0; j < pv.observations!.length; j++) {
            final obs = pv.observations![j];
            final obsCriticality = (obs.criticite?.trim().isNotEmpty == true)
                ? _normalizeCriticalityLabel(obs.criticite!)
                : resolvedCriticality;
            addFinding(AuditFinding(
              id: 'eq_${coffretHash}_pv_${i}_obs_$j',
              missionId: missionId,
              tensionDomain: defaultTensionDomain,
              origin: originNom,
              objectType: typeEquipementStr,
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
            ));
          }
        } else {
          addFinding(AuditFinding(
            id: 'eq_${coffretHash}_pv_$i',
            missionId: missionId,
            tensionDomain: defaultTensionDomain,
            origin: originNom,
            objectType: typeEquipementStr,
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
          ));
        }
      }
    }

    // Observations parafoudre enrichies
    if (coffret.presenceParafoudre) {
      if (coffret.observationsParafoudreEnrichies != null) {
        for (var i = 0; i < coffret.observationsParafoudreEnrichies!.length; i++) {
          final el = coffret.observationsParafoudreEnrichies![i];
          if (el.conforme == false && !el.estNA) {
            addFinding(AuditFinding(
              id: 'eq_${coffretHash}_parafoudre_$i',
              missionId: missionId,
              tensionDomain: defaultTensionDomain,
              origin: originNom,
              objectType: typeEquipementStr,
              objectName: '${coffret.nom} (Parafoudre)',
              objectRepere: coffretRepere,
              tableName: 'Observations Parafoudre',
              verificationPoint: el.elementControle,
              observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
              conformity: 'non',
              criticality: _resolveCriticalityString(el),
              priority: el.priorite,
              normativeReference: el.referenceNormativeEffectiveFor(),
              riskFamily: el.familleRisqueEffectiveFor(),
              photos: el.photos,
            ));
          }
        }
      }
    }
  }
}
