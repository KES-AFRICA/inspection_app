// lib/services/statistics/mission_tree_visitor.dart

import '../../models/audit_installations_electriques.dart';
import '../../models/foudre.dart';
import '../hive_service.dart';
import 'unified_observation.dart';

/// Algorithme de Parcours Exhaustif (Phase 1 du Moteur Statistique).
/// Visite 100 % des occurrences d'instances physiquement enregistrées dans la mission
/// et produit un inventaire brut certifié (`AuditNonConformityRecord` / `UnifiedObservation`).
class MissionTreeVisitor {
  /// Parcourt l'ensemble de la mission et produit l'inventaire brut des occurrences non conformes.
  static List<UnifiedObservation> collectInventory(String missionId) {
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

    final inventory = <UnifiedObservation>[];
    final seenIds = <String>{};

    final processedMTLocaux = <int>{};
    final processedBTLocaux = <int>{};
    final processedCoffrets = <int>{};

    void addRecord(UnifiedObservation obs) {
      if (!seenIds.contains(obs.id)) {
        seenIds.add(obs.id);
        inventory.add(obs);
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
          zoneNom: null,
          addRecord: addRecord,
          processedMTLocaux: processedMTLocaux,
          processedCoffrets: processedCoffrets,
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
            zoneNom: zone.nom,
            addRecord: addRecord,
            processedMTLocaux: processedMTLocaux,
            processedCoffrets: processedCoffrets,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffrets.length; eqIdx++) {
          final coffret = zone.coffrets[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            localisation: zone.nom,
            zoneNom: zone.nom,
            sourceCat: AuditSourceCategory.moyenneTensionZone,
            addRecord: addRecord,
            processedCoffrets: processedCoffrets,
          );
        }
        for (var i = 0; i < zone.observationsLibres.length; i++) {
          final obs = zone.observationsLibres[i];
          if (obs.texte.trim().isNotEmpty) {
            final hash = identityHashCode(obs);
            addRecord(UnifiedObservation(
              id: 'mt_zone_${zIdx}_obs_hash_$hash',
              missionId: missionId,
              localisation: zone.nom,
              zoneNom: zone.nom,
              itemNom: 'Observation libre',
              texteObservation: obs.texte,
              criticite: CriticalityLevel.none,
              prioriteInt: null,
              sourceCategory: AuditSourceCategory.moyenneTensionZone,
              tableType: AuditTableType.observationsLibres,
              typeObjet: 'Zone MT',
              photos: obs.photos,
            ));
          }
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
            zoneNom: zone.nom,
            addRecord: addRecord,
            processedBTLocaux: processedBTLocaux,
            processedCoffrets: processedCoffrets,
          );
        }
        for (var eqIdx = 0; eqIdx < zone.coffretsDirects.length; eqIdx++) {
          final coffret = zone.coffretsDirects[eqIdx];
          _visitEquipement(
            missionId: missionId,
            coffret: coffret,
            localisation: zone.nom,
            zoneNom: zone.nom,
            sourceCat: AuditSourceCategory.basseTensionZone,
            addRecord: addRecord,
            processedCoffrets: processedCoffrets,
          );
        }
        for (var i = 0; i < zone.observationsLibres.length; i++) {
          final obs = zone.observationsLibres[i];
          if (obs.texte.trim().isNotEmpty) {
            final hash = identityHashCode(obs);
            addRecord(UnifiedObservation(
              id: 'bt_zone_${zIdx}_obs_hash_$hash',
              missionId: missionId,
              localisation: zone.nom,
              zoneNom: zone.nom,
              itemNom: 'Observation libre',
              texteObservation: obs.texte,
              criticite: CriticalityLevel.none,
              prioriteInt: null,
              sourceCategory: AuditSourceCategory.basseTensionZone,
              tableType: AuditTableType.observationsLibres,
              typeObjet: 'Zone BT',
              photos: obs.photos,
            ));
          }
        }
      }
    }

    // 4. MODULE FOUDRE
    for (var i = 0; i < foudres.length; i++) {
      final f = foudres[i];
      if (f.observation.trim().isNotEmpty) {
        final hash = identityHashCode(f);
        addRecord(UnifiedObservation(
          id: 'foudre_hash_${hash}_obs_$i',
          missionId: missionId,
          localisation: 'Installation Foudre',
          itemNom: 'Observation Foudre ${i + 1}',
          texteObservation: f.observation,
          criticite: UnifiedObservation.intToCriticality(f.niveauPriorite),
          prioriteInt: f.niveauPriorite,
          sourceCategory: AuditSourceCategory.foudre,
          tableType: AuditTableType.foudre,
          typeObjet: 'Foudre',
        ));
      }
    }

    return inventory;
  }

  // ──────────────────────────────────────────────────────────────
  //  RÉSOLUTION DE CRITICITÉ
  // ──────────────────────────────────────────────────────────────

  static CriticalityLevel _resolveCriticality(ElementControle el, {String? localType}) {
    final criticiteStr = el.criticiteEffectiveFor(localType: localType);
    if (criticiteStr != null && criticiteStr.trim().isNotEmpty) {
      final s = criticiteStr.trim().toLowerCase();
      if (s.contains('critique') || s == '3') return CriticalityLevel.critique;
      if (s.contains('majeur') || s == '2') return CriticalityLevel.majeure;
      if (s.contains('mineur') || s == '1') return CriticalityLevel.mineure;
    }
    // Fallback sur la priorité entière si aucune criticité textuelle n'est définie
    return UnifiedObservation.intToCriticality(el.priorite);
  }

  static bool _isNonConforme(String? conf) {
    if (conf == null) return false;
    final s = conf.trim().toLowerCase();
    return s == 'non' || s == 'non conforme' || s == 'non_conforme' || s == 'false';
  }

  // ──────────────────────────────────────────────────────────────
  //  VISITEURS PAR TYPE D'INSTANCE
  // ──────────────────────────────────────────────────────────────

  static void _visitMTLocal({
    required String missionId,
    required MoyenneTensionLocal local,
    String? zoneNom,
    required Function(UnifiedObservation) addRecord,
    required Set<int> processedMTLocaux,
    required Set<int> processedCoffrets,
  }) {
    final localHash = identityHashCode(local);
    if (processedMTLocaux.contains(localHash)) return;
    processedMTLocaux.add(localHash);

    final localType = local.type.isNotEmpty ? local.type : 'LOCAL_POSTE_HTA';

    // Dispositions constructives
    for (var i = 0; i < local.dispositionsConstructives.length; i++) {
      final el = local.dispositionsConstructives[i];
      if (el.conforme == false && !el.estNA) {
        addRecord(UnifiedObservation(
          id: 'mt_local_${localHash}_dc_$i',
          missionId: missionId,
          localisation: local.nom,
          zoneNom: zoneNom,
          itemNom: el.elementControle,
          texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          criticite: _resolveCriticality(el, localType: localType),
          prioriteInt: el.priorite,
          referenceNormative: el.referenceNormativeEffectiveFor(localType: localType),
          familleRisque: el.familleRisqueEffectiveFor(localType: localType),
          sourceCategory: AuditSourceCategory.moyenneTensionLocal,
          tableType: AuditTableType.dispositionsConstructives,
          typeObjet: 'Local MT',
          photos: el.photos,
        ));
      }
    }

    // Conditions d'exploitation
    for (var i = 0; i < local.conditionsExploitation.length; i++) {
      final el = local.conditionsExploitation[i];
      if (el.conforme == false && !el.estNA) {
        addRecord(UnifiedObservation(
          id: 'mt_local_${localHash}_ce_$i',
          missionId: missionId,
          localisation: local.nom,
          zoneNom: zoneNom,
          itemNom: el.elementControle,
          texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          criticite: _resolveCriticality(el, localType: localType),
          prioriteInt: el.priorite,
          referenceNormative: el.referenceNormativeEffectiveFor(localType: localType),
          familleRisque: el.familleRisqueEffectiveFor(localType: localType),
          sourceCategory: AuditSourceCategory.moyenneTensionLocal,
          tableType: AuditTableType.conditionsExploitation,
          typeObjet: 'Local MT',
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
          addRecord(UnifiedObservation(
            id: 'mt_local_${localHash}_cell_${i}_el_$j',
            missionId: missionId,
            localisation: local.nom,
            zoneNom: zoneNom,
            itemNom: '$itemLabel - ${el.elementControle}',
            texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            criticite: _resolveCriticality(el, localType: localType),
            prioriteInt: el.priorite,
            referenceNormative: el.referenceNormativeEffectiveFor(localType: localType),
            familleRisque: el.familleRisqueEffectiveFor(localType: localType),
            sourceCategory: AuditSourceCategory.cellule,
            tableType: AuditTableType.celluleElements,
            typeObjet: 'Cellule MT',
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
          addRecord(UnifiedObservation(
            id: 'mt_local_${localHash}_transfo_${i}_el_$j',
            missionId: missionId,
            localisation: local.nom,
            zoneNom: zoneNom,
            itemNom: '$itemLabel - ${el.elementControle}',
            texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            criticite: _resolveCriticality(el, localType: localType),
            prioriteInt: el.priorite,
            referenceNormative: el.referenceNormativeEffectiveFor(localType: localType),
            familleRisque: el.familleRisqueEffectiveFor(localType: localType),
            sourceCategory: AuditSourceCategory.transformateur,
            tableType: AuditTableType.transformateurElements,
            typeObjet: 'Transformateur MT/BT',
            photos: el.photos,
          ));
        }
      }
    }

    // Coffrets/Armoires/TGBT du local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        localisation: local.nom,
        zoneNom: zoneNom,
        sourceCat: AuditSourceCategory.moyenneTensionLocal,
        addRecord: addRecord,
        processedCoffrets: processedCoffrets,
      );
    }
  }

  static void _visitBTLocal({
    required String missionId,
    required BasseTensionLocal local,
    String? zoneNom,
    required Function(UnifiedObservation) addRecord,
    required Set<int> processedBTLocaux,
    required Set<int> processedCoffrets,
  }) {
    final localHash = identityHashCode(local);
    if (processedBTLocaux.contains(localHash)) return;
    processedBTLocaux.add(localHash);

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE';
    final sourceCat = isGE ? AuditSourceCategory.groupeElectrogene : AuditSourceCategory.basseTensionLocal;
    final typeObjetName = isGE ? 'Groupe Électrogène' : 'Local BT';

    // Dispositions constructives
    if (local.dispositionsConstructives != null) {
      for (var i = 0; i < local.dispositionsConstructives!.length; i++) {
        final el = local.dispositionsConstructives![i];
        if (el.conforme == false && !el.estNA) {
          addRecord(UnifiedObservation(
            id: 'bt_local_${localHash}_dc_$i',
            missionId: missionId,
            localisation: local.nom,
            zoneNom: zoneNom,
            itemNom: el.elementControle,
            texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            criticite: _resolveCriticality(el, localType: local.type),
            prioriteInt: el.priorite,
            referenceNormative: el.referenceNormativeEffectiveFor(localType: local.type),
            familleRisque: el.familleRisqueEffectiveFor(localType: local.type),
            sourceCategory: sourceCat,
            tableType: AuditTableType.dispositionsConstructives,
            typeObjet: typeObjetName,
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
          addRecord(UnifiedObservation(
            id: 'bt_local_${localHash}_ce_$i',
            missionId: missionId,
            localisation: local.nom,
            zoneNom: zoneNom,
            itemNom: el.elementControle,
            texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
            criticite: _resolveCriticality(el, localType: local.type),
            prioriteInt: el.priorite,
            referenceNormative: el.referenceNormativeEffectiveFor(localType: local.type),
            familleRisque: el.familleRisqueEffectiveFor(localType: local.type),
            sourceCategory: sourceCat,
            tableType: AuditTableType.conditionsExploitation,
            typeObjet: typeObjetName,
            photos: el.photos,
          ));
        }
      }
    }

    // Coffrets/Armoires/TGBT/Inverseurs dans ce local
    for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
      final coffret = local.coffrets[eqIdx];
      _visitEquipement(
        missionId: missionId,
        coffret: coffret,
        localisation: local.nom,
        zoneNom: zoneNom,
        sourceCat: sourceCat,
        addRecord: addRecord,
        processedCoffrets: processedCoffrets,
      );
    }
  }

  static void _visitEquipement({
    required String missionId,
    required CoffretArmoire coffret,
    required String localisation,
    String? zoneNom,
    required AuditSourceCategory sourceCat,
    required Function(UnifiedObservation) addRecord,
    required Set<int> processedCoffrets,
  }) {
    final coffretHash = identityHashCode(coffret);
    if (processedCoffrets.contains(coffretHash)) return;
    processedCoffrets.add(coffretHash);

    final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
    final typeEquipementStr = coffret.type.isNotEmpty ? coffret.type : 'Équipement';

    // Points de vérification non conformes
    for (var i = 0; i < coffret.pointsVerification.length; i++) {
      final pv = coffret.pointsVerification[i];
      if (_isNonConforme(pv.conformite)) {
        if (pv.observations != null && pv.observations!.isNotEmpty) {
          for (var j = 0; j < pv.observations!.length; j++) {
            final obs = pv.observations![j];
            final prio = obs.priorite ?? pv.priorite;
            final crit = _resolveCriticality(obs);
            addRecord(UnifiedObservation(
              id: 'eq_${coffretHash}_pv_${i}_obs_$j',
              missionId: missionId,
              localisation: localisation,
              zoneNom: zoneNom,
              itemNom: coffret.nom,
              texteObservation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
              criticite: crit,
              prioriteInt: prio,
              referenceNormative: obs.referenceNormativeEffectiveFor() ?? pv.referenceNormative,
              familleRisque: obs.familleRisqueEffectiveFor(),
              sourceCategory: AuditSourceCategory.equipement,
              tableType: AuditTableType.pointsVerification,
              typeObjet: typeEquipementStr,
              repere: coffretRepere,
              photos: obs.photos.isNotEmpty ? obs.photos : pv.photos,
            ));
          }
        } else {
          final crit = UnifiedObservation.intToCriticality(pv.priorite);
          addRecord(UnifiedObservation(
            id: 'eq_${coffretHash}_pv_$i',
            missionId: missionId,
            localisation: localisation,
            zoneNom: zoneNom,
            itemNom: coffret.nom,
            texteObservation: pv.observation?.isNotEmpty == true ? pv.observation! : pv.pointVerification,
            criticite: crit,
            prioriteInt: pv.priorite,
            referenceNormative: pv.referenceNormative,
            sourceCategory: AuditSourceCategory.equipement,
            tableType: AuditTableType.pointsVerification,
            typeObjet: typeEquipementStr,
            repere: coffretRepere,
            photos: pv.photos,
          ));
        }
      }
    }

    // Observations libres
    for (var i = 0; i < coffret.observationsLibres.length; i++) {
      final obs = coffret.observationsLibres[i];
      if (obs.texte.trim().isNotEmpty) {
        addRecord(UnifiedObservation(
          id: 'eq_${coffretHash}_libre_$i',
          missionId: missionId,
          localisation: localisation,
          zoneNom: zoneNom,
          itemNom: coffret.nom,
          texteObservation: obs.texte,
          criticite: CriticalityLevel.none,
          prioriteInt: null,
          sourceCategory: AuditSourceCategory.equipement,
          tableType: AuditTableType.observationsLibres,
          typeObjet: typeEquipementStr,
          repere: coffretRepere,
          photos: obs.photos,
        ));
      }
    }

    // Observations parafoudre enrichies
    if (coffret.presenceParafoudre) {
      if (coffret.observationsParafoudreEnrichies != null) {
        for (var i = 0; i < coffret.observationsParafoudreEnrichies!.length; i++) {
          final el = coffret.observationsParafoudreEnrichies![i];
          if (el.conforme == false && !el.estNA) {
            addRecord(UnifiedObservation(
              id: 'eq_${coffretHash}_parafoudre_$i',
              missionId: missionId,
              localisation: localisation,
              zoneNom: zoneNom,
              itemNom: '${coffret.nom} - Parafoudre',
              texteObservation: el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
              criticite: _resolveCriticality(el),
              prioriteInt: el.priorite,
              referenceNormative: el.referenceNormativeEffectiveFor(),
              familleRisque: el.familleRisqueEffectiveFor(),
              sourceCategory: AuditSourceCategory.equipement,
              tableType: AuditTableType.observationsParafoudre,
              typeObjet: typeEquipementStr,
              repere: coffretRepere,
              photos: el.photos,
            ));
          }
        }
      }
    }
  }
}
