// lib/services/statistics/audit_finding_inventory_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../hive_service.dart';
import '../dispositions_constructives_registry.dart';
import 'audit_finding.dart';

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
          );
        }
        // Note : les observations libres des zones sont exclues du périmètre statistique
        // (elles n'ont pas de criticité normative et ne sont pas des points de vérification).
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
          );
        }
        // Note : les observations libres des zones sont exclues du périmètre statistique.
      }
    }

    // 4. MODULE FOUDRE
    // Note : les observations foudre n'ont pas de criticité normative.
    // La priorité (niveauPriorite) est conservée mais n'est PAS confondue avec la criticité.
    for (var i = 0; i < foudres.length; i++) {
      final f = foudres[i];
      if (f.observation.trim().isNotEmpty) {
        final hash = identityHashCode(f);
        addFinding(AuditFinding(
          id: 'foudre_hash_${hash}_obs_$i',
          missionId: missionId,
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

    return AuditFindingInventory(
      missionId: missionId,
      findings: findings,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  RÉSOLUTION DE CRITICITÉ NORMÉE
  // ──────────────────────────────────────────────────────────────

  static String _resolveCriticalityString(ElementControle el, {String? localType}) {
    final directVal = el.criticite?.trim();
    if (directVal != null && directVal.isNotEmpty) {
      final s = directVal.toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    final criticiteStr = el.criticiteEffectiveFor(localType: localType);
    if (criticiteStr != null && criticiteStr.trim().isNotEmpty) {
      final s = criticiteStr.trim().toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    return 'Non spécifiée';
  }

  static String _resolvePointVerificationCriticality(PointVerification pv, String coffretType) {
    final directVal = pv.criticite?.trim();
    if (directVal != null && directVal.isNotEmpty) {
      return _normalizeCriticalityLabel(directVal);
    }
    final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
    if (meta != null && meta.criticite.trim().isNotEmpty) {
      return _normalizeCriticalityLabel(meta.criticite);
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
  }) {
    final localHash = identityHashCode(local);
    if (visitedMTLocaux.contains(localHash)) return;
    visitedMTLocaux.add(localHash);

    final localType = local.type.isNotEmpty ? local.type : 'LOCAL_POSTE_HTA';

    // Dispositions constructives
    for (var i = 0; i < local.dispositionsConstructives.length; i++) {
      final el = local.dispositionsConstructives[i];
      if (el.conforme == false && !el.estNA) {
        addFinding(AuditFinding(
          id: 'mt_local_${localHash}_dc_$i',
          missionId: missionId,
          origin: originNom,
          objectType: 'Local MT',
          objectName: local.nom,
          tableName: 'Dispositions constructives',
          verificationPoint: el.elementControle,
          observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          conformity: 'non',
          criticality: _resolveCriticalityString(el, localType: localType),
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
      if (el.conforme == false && !el.estNA) {
        addFinding(AuditFinding(
          id: 'mt_local_${localHash}_ce_$i',
          missionId: missionId,
          origin: originNom,
          objectType: 'Local MT',
          objectName: local.nom,
          tableName: 'Conditions d\'exploitation',
          verificationPoint: el.elementControle,
          observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          conformity: 'non',
          criticality: _resolveCriticalityString(el, localType: localType),
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
      final itemLabel = 'Cellule ${i + 1} (${cellule.fonction})';
      for (var j = 0; j < cellule.elementsVerifies.length; j++) {
        final el = cellule.elementsVerifies[j];
        if (el.conforme == false && !el.estNA) {
          addFinding(AuditFinding(
            id: 'mt_local_${localHash}_cell_${i}_el_$j',
            missionId: missionId,
            origin: '$originNom > Cellule ${cellule.fonction}',
            objectType: 'Cellule MT',
            objectName: cellule.fonction,
            tableName: 'Tableau Cellule',
            verificationPoint: '$itemLabel - ${el.elementControle}',
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: _resolveCriticalityString(el, localType: localType),
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
      final itemLabel = 'Transformateur ${i + 1}';
      for (var j = 0; j < transfo.elementsVerifies.length; j++) {
        final el = transfo.elementsVerifies[j];
        if (el.conforme == false && !el.estNA) {
          addFinding(AuditFinding(
            id: 'mt_local_${localHash}_transfo_${i}_el_$j',
            missionId: missionId,
            origin: '$originNom > Transformateur ${i + 1}',
            objectType: 'Transformateur MT/BT',
            objectName: 'Transformateur ${i + 1}',
            tableName: 'Tableau Transformateur',
            verificationPoint: '$itemLabel - ${el.elementControle}',
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: _resolveCriticalityString(el, localType: localType),
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
  }) {
    final localHash = identityHashCode(local);
    if (visitedBTLocaux.contains(localHash)) return;
    visitedBTLocaux.add(localHash);

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE';
    final typeObjetName = isGE ? 'Groupe Électrogène' : 'Local BT';

    // Dispositions constructives
    if (local.dispositionsConstructives != null) {
      for (var i = 0; i < local.dispositionsConstructives!.length; i++) {
        final el = local.dispositionsConstructives![i];
        if (el.conforme == false && !el.estNA) {
          addFinding(AuditFinding(
            id: 'bt_local_${localHash}_dc_$i',
            missionId: missionId,
            origin: originNom,
            objectType: typeObjetName,
            objectName: local.nom,
            tableName: 'Dispositions constructives',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: _resolveCriticalityString(el, localType: local.type),
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
        if (el.conforme == false && !el.estNA) {
          addFinding(AuditFinding(
            id: 'bt_local_${localHash}_ce_$i',
            missionId: missionId,
            origin: originNom,
            objectType: typeObjetName,
            objectName: local.nom,
            tableName: 'Conditions d\'exploitation',
            verificationPoint: el.elementControle,
            observationText: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            conformity: 'non',
            criticality: _resolveCriticalityString(el, localType: local.type),
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
      );
    }
  }

  static void _visitEquipement({
    required String missionId,
    required CoffretArmoire coffret,
    required String originNom,
    required Function(AuditFinding) addFinding,
    required Set<int> visitedCoffrets,
  }) {
    final coffretHash = identityHashCode(coffret);
    if (visitedCoffrets.contains(coffretHash)) return;
    visitedCoffrets.add(coffretHash);

    final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
    final typeEquipementStr = coffret.type.isNotEmpty ? coffret.type : 'Équipement';

    // Points de vérification non conformes
    // La criticité est TOUJOURS résolue via le libellé du point de vérification parent
    // en consultant le registre coffret (_coffretRegistry), PAS via le texte de l'observation.
    for (var i = 0; i < coffret.pointsVerification.length; i++) {
      final pv = coffret.pointsVerification[i];
      if (_isNonConforme(pv.conformite)) {
        // Résolution unique de la criticité pour CE point de vérification
        final resolvedCriticality = _resolvePointVerificationCriticality(pv, coffret.type);
        final resolvedNormRef = _resolvePointVerificationNormRef(pv, coffret.type);
        final resolvedRiskFamily = _resolvePointVerificationRiskFamily(pv, coffret.type);

        if (pv.observations != null && pv.observations!.isNotEmpty) {
          for (var j = 0; j < pv.observations!.length; j++) {
            final obs = pv.observations![j];
            // L'observation peut porter sa propre criticité explicite (saisie par l'inspecteur).
            // Sinon, on hérite de la criticité du point de vérification parent.
            final obsCriticality = (obs.criticite?.trim().isNotEmpty == true)
                ? _normalizeCriticalityLabel(obs.criticite!)
                : resolvedCriticality;
            addFinding(AuditFinding(
              id: 'eq_${coffretHash}_pv_${i}_obs_$j',
              missionId: missionId,
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

    // Note : les observations libres des équipements sont exclues du périmètre statistique
    // (elles n'ont pas de criticité normative et ne sont pas des points de vérification).

    // Observations parafoudre enrichies
    if (coffret.presenceParafoudre) {
      if (coffret.observationsParafoudreEnrichies != null) {
        for (var i = 0; i < coffret.observationsParafoudreEnrichies!.length; i++) {
          final el = coffret.observationsParafoudreEnrichies![i];
          if (el.conforme == false && !el.estNA) {
            addFinding(AuditFinding(
              id: 'eq_${coffretHash}_parafoudre_$i',
              missionId: missionId,
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
