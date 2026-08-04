// lib/services/statistics/audit_finding_inventory_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../hive_service.dart';
import '../dispositions_constructives_registry.dart';
import 'audit_finding.dart';

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
/// Responsabilité Unique : Parcourir 100 % des instances enregistrées en mémoire dans la mission,
/// filtrer les constats non conformes et produire la collection d'inventaire brute certifiée (`AuditFindingInventory`).
class AuditFindingInventoryEngine {
  /// Génère l'inventaire brut exhaustif pour une mission donnée.
  static AuditFindingInventory buildInventory(String missionId) {
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

    final findings = <AuditFinding>[];
    final seenFindingIds = <String>{};

    final visitedMTLocaux = <int>{};
    final visitedBTLocaux = <int>{};
    final visitedCoffrets = <int>{};

    final categoryTrackers = <String, _CategoryTracker>{
      'local_mt': _CategoryTracker('local_mt', 'Locaux techniques Moyenne Tension'),
      'local_bt': _CategoryTracker('local_bt', 'Locaux techniques Basse Tension'),
      'local_ge': _CategoryTracker('local_ge', 'Locaux techniques Groupe Électrogène'),
      'cellule_mt': _CategoryTracker('cellule_mt', 'Cellules MT'),
      'transfo_mt_bt': _CategoryTracker('transfo_mt_bt', 'Transformateurs MT/BT'),
      'tgbt': _CategoryTracker('tgbt', 'TGBT'),
      'armoire': _CategoryTracker('armoire', 'Armoires'),
      'coffret': _CategoryTracker('coffret', 'Coffrets'),
      'inverseur': _CategoryTracker('inverseur', 'Inverseurs'),
    };

    void addFinding(AuditFinding finding) {
      if (!seenFindingIds.contains(finding.id)) {
        seenFindingIds.add(finding.id);
        findings.add(finding);
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
          originNom: 'Local MT ${local.nom}',
          addFinding: addFinding,
          visitedMTLocaux: visitedMTLocaux,
          visitedCoffrets: visitedCoffrets,
          trackers: categoryTrackers,
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
            addFinding: addFinding,
            visitedMTLocaux: visitedMTLocaux,
            visitedCoffrets: visitedCoffrets,
            trackers: categoryTrackers,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffrets.length; eqIdx++) {
          final coffret = zone.coffrets[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            originNom: 'Zone MT "${zone.nom}"',
            addFinding: addFinding,
            visitedCoffrets: visitedCoffrets,
            trackers: categoryTrackers,
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
            addFinding: addFinding,
            visitedBTLocaux: visitedBTLocaux,
            visitedCoffrets: visitedCoffrets,
            trackers: categoryTrackers,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffretsDirects.length; eqIdx++) {
          final coffret = zone.coffretsDirects[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            originNom: 'Zone BT "${zone.nom}"',
            addFinding: addFinding,
            visitedCoffrets: visitedCoffrets,
            trackers: categoryTrackers,
          );
        }
      }
    }

    // 4. MODULE FOUDRE
    for (var i = 0; i < foudres.length; i++) {
      final f = foudres[i];
      if (f.observation.trim().isNotEmpty) {
        final hash = identityHashCode(f);
        addFinding(AuditFinding(
          id: 'foudre_hash_${hash}_obs_$i',
          missionId: missionId,
          tensionDomain: TensionDomain.bt,
          origin: 'Module Foudre',
          objectType: 'Foudre',
          objectName: 'Installation Foudre',
          tableName: 'Observations Foudre',
          verificationPoint: 'Observation Foudre ${i + 1}',
          observationText: f.observation,
          conformity: 'non',
          criticality: 'Non spécifiée',
          priority: f.niveauPriorite,
        ));
      }
    }

    final crossCategoryItems = categoryTrackers.values
        .where((tr) => tr.equipmentCount > 0 || tr.totalPointsEvaluated > 0)
        .map((tr) => tr.toCategoryCrossItem())
        .toList();

    return AuditFindingInventory(
      missionId: missionId,
      findings: findings,
      crossCategoryItems: crossCategoryItems,
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

    final t = coffret.type.trim().toLowerCase();
    String catKey = 'coffret';
    if (t.contains('inverseur')) {
      catKey = 'inverseur';
    } else if (t.contains('tgbt') || t.contains('t.g.b.t')) {
      catKey = 'tgbt';
    } else if (t.contains('armoire') || t.contains('tur')) {
      catKey = 'armoire';
    }

    trackers[catKey]?.equipmentCount++;

    final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
    final typeEquipementStr = coffret.type.isNotEmpty ? coffret.type : 'Équipement';

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
