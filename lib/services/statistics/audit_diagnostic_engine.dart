// lib/services/statistics/audit_diagnostic_engine.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/audit_installations_electriques.dart';
import '../../models/foudre.dart';
import '../hive_service.dart';
import '../dispositions_constructives_registry.dart';

/// Item de diagnostic individuel pour audit ligne à ligne avec traçabilité complète.
class AuditDiagnosticItem {
  final String objectType;              // "Local MT", "Local BT", "Cellule MT", "Transformateur MT/BT", "Groupe Électrogène", "Coffret", "Armoire", "TGBT", "Inverseur", "Foudre"
  final String objectName;              // Nom de l'objet
  final String objectId;                // Hash mémoire ou ID unique de l'instance
  final String tableName;               // Type de tableau
  final String verificationPoint;       // Point de vérification
  final String rawConformity;           // "oui", "non", "na", "sans_objet", "true", "false"
  final bool isNonConforme;             // Vrai si retenu dans les non-conformités
  final String retrievedCriticality;    // "Critique", "Majeure", "Mineure", "Non spécifiée"
  final int? retrievedPriority;         // Priorité (1, 2, 3)
  final String? retrievedNormativeRef;  // Référence normée
  final String? retrievedRiskFamily;    // Famille de risque
  final String modelAccessPath;         // Chemin exact dans les modèles Hive

  AuditDiagnosticItem({
    required this.objectType,
    required this.objectName,
    required this.objectId,
    required this.tableName,
    required this.verificationPoint,
    required this.rawConformity,
    required this.isNonConforme,
    required this.retrievedCriticality,
    this.retrievedPriority,
    this.retrievedNormativeRef,
    this.retrievedRiskFamily,
    required this.modelAccessPath,
  });

  Map<String, dynamic> toJson() => {
    'objectType': objectType,
    'objectName': objectName,
    'objectId': objectId,
    'tableName': tableName,
    'verificationPoint': verificationPoint,
    'rawConformity': rawConformity,
    'isNonConforme': isNonConforme,
    'retrievedCriticality': retrievedCriticality,
    'retrievedPriority': retrievedPriority,
    'retrievedNormativeRef': retrievedNormativeRef,
    'retrievedRiskFamily': retrievedRiskFamily,
    'modelAccessPath': modelAccessPath,
  };
}

/// Rapport Technique Global d'Analyse et de Validation du Moteur de Diagnostic.
class AuditValidationReport {
  final String missionId;
  final int countLocauxMT;
  final int countLocauxBT;
  final int countCellules;
  final int countTransformateurs;
  final int countGroupesElectrogenes;
  final int countEquipements;
  final int countTotalTableauxInspectes;
  final int countTotalLignesAnalysees;
  final int countLignesOui;
  final int countLignesSansObjet;
  final int countLignesNon;
  final int countCritiques;
  final int countMajeures;
  final int countMineures;
  final int countNonSpecifiees;
  final List<AuditDiagnosticItem> diagnosticItems;

  AuditValidationReport({
    required this.missionId,
    required this.countLocauxMT,
    required this.countLocauxBT,
    required this.countCellules,
    required this.countTransformateurs,
    required this.countGroupesElectrogenes,
    required this.countEquipements,
    required this.countTotalTableauxInspectes,
    required this.countTotalLignesAnalysees,
    required this.countLignesOui,
    required this.countLignesSansObjet,
    required this.countLignesNon,
    required this.countCritiques,
    required this.countMajeures,
    required this.countMineures,
    required this.countNonSpecifiees,
    required this.diagnosticItems,
  });

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'parcours': {
      'locauxMT': countLocauxMT,
      'locauxBT': countLocauxBT,
      'cellules': countCellules,
      'transformateurs': countTransformateurs,
      'groupesElectrogenes': countGroupesElectrogenes,
      'equipements': countEquipements,
      'totalTableauxInspectes': countTotalTableauxInspectes,
      'totalLignesAnalysees': countTotalLignesAnalysees,
      'lignesOui': countLignesOui,
      'lignesSansObjet': countLignesSansObjet,
      'lignesNon': countLignesNon,
    },
    'criticitésRecensées': {
      'critique': countCritiques,
      'majeure': countMajeures,
      'mineure': countMineures,
      'nonSpécifiées': countNonSpecifiees,
    },
    'itemsDiagnosticNonConformes': diagnosticItems.where((e) => e.isNonConforme).map((e) => e.toJson()).toList(),
  };

  String exportJsonPretty() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  void printFullDiagnosticReport() {
    print('================================================================================');
    print('🔬 RAPPORT TECHNIQUE DE DIAGNOSTIC ET DE VALIDATION — MISSION: $missionId');
    print('================================================================================');
    print('📊 STATISTIQUES DE PARCOURS D\'INSTANCES :');
    print('  - Locaux MT parcourus        : $countLocauxMT');
    print('  - Locaux BT parcourus        : $countLocauxBT');
    print('  - Cellules MT parcourues     : $countCellules');
    print('  - Transformateurs parcourus  : $countTransformateurs');
    print('  - Groupes Électrogènes       : $countGroupesElectrogenes');
    print('  - Équipements (TGBT/Armoires) : $countEquipements');
    print('--------------------------------------------------------------------------------');
    print('📋 STATISTIQUES DE LIGNES ANALYSÉES :');
    print('  - Total tableaux inspectés  : $countTotalTableauxInspectes');
    print('  - Total lignes analysées    : $countTotalLignesAnalysees');
    print('  - Lignes "Oui" (Conformes)  : $countLignesOui');
    print('  - Lignes "Sans Objet" / NA  : $countLignesSansObjet');
    print('  - Lignes "Non" (Non-conf)   : $countLignesNon');
    print('--------------------------------------------------------------------------------');
    print('🚨 CRITICITÉS EFFECTIVES DES NON-CONFORMITÉS :');
    print('  - CRITIQUE  : $countCritiques');
    print('  - MAJEURE   : $countMajeures');
    print('  - MINEURE   : $countMineures');
    print('  - NON SPEC  : $countNonSpecifiees');
    print('================================================================================');
  }
}

/// Moteur de Diagnostic Exhaustif sans modification de code de production.
class AuditDiagnosticEngine {
  static AuditValidationReport runDiagnostic(String missionId) {
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

    int countLocauxMT = 0;
    int countLocauxBT = 0;
    int countCellules = 0;
    int countTransformateurs = 0;
    int countGroupesElectrogenes = 0;
    int countEquipements = 0;
    int countTotalTableauxInspectes = 0;

    int countTotalLignesAnalysees = 0;
    int countLignesOui = 0;
    int countLignesSansObjet = 0;
    int countLignesNon = 0;

    final diagnosticItems = <AuditDiagnosticItem>[];

    final visitedMTLocaux = <int>{};
    final visitedBTLocaux = <int>{};
    final visitedCoffrets = <int>{};

    if (audit != null) {
      // 1. LOCAUX MT DIRECTS
      for (var lIdx = 0; lIdx < audit.moyenneTensionLocaux.length; lIdx++) {
        final local = audit.moyenneTensionLocaux[lIdx];
        local.migrateFromOldFields();
        final localHash = identityHashCode(local);
        if (!visitedMTLocaux.contains(localHash)) {
          visitedMTLocaux.add(localHash);
          countLocauxMT++;

          final localType = local.type.isNotEmpty ? local.type : 'LOCAL_POSTE_HTA';

          // Dispositions Constructives
          if (local.dispositionsConstructives.isNotEmpty) countTotalTableauxInspectes++;
          for (var i = 0; i < local.dispositionsConstructives.length; i++) {
            countTotalLignesAnalysees++;
            final el = local.dispositionsConstructives[i];
            final conf = _parseConformity(el.conforme, el.estNA);
            if (conf == 'oui') countLignesOui++;
            else if (conf == 'sans_objet') countLignesSansObjet++;
            else if (conf == 'non') countLignesNon++;

            diagnosticItems.add(AuditDiagnosticItem(
              objectType: 'Local MT',
              objectName: local.nom,
              objectId: 'hash_$localHash',
              tableName: 'Dispositions constructives',
              verificationPoint: el.elementControle,
              rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
              isNonConforme: conf == 'non',
              retrievedCriticality: _resolveCriticalityString(el, localType: localType),
              retrievedPriority: el.priorite,
              retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: localType),
              retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: localType),
              modelAccessPath: 'audit.moyenneTensionLocaux[$lIdx].dispositionsConstructives[$i]',
            ));
          }

          // Conditions d'exploitation
          if (local.conditionsExploitation.isNotEmpty) countTotalTableauxInspectes++;
          for (var i = 0; i < local.conditionsExploitation.length; i++) {
            countTotalLignesAnalysees++;
            final el = local.conditionsExploitation[i];
            final conf = _parseConformity(el.conforme, el.estNA);
            if (conf == 'oui') countLignesOui++;
            else if (conf == 'sans_objet') countLignesSansObjet++;
            else if (conf == 'non') countLignesNon++;

            diagnosticItems.add(AuditDiagnosticItem(
              objectType: 'Local MT',
              objectName: local.nom,
              objectId: 'hash_$localHash',
              tableName: 'Conditions d\'exploitation',
              verificationPoint: el.elementControle,
              rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
              isNonConforme: conf == 'non',
              retrievedCriticality: _resolveCriticalityString(el, localType: localType),
              retrievedPriority: el.priorite,
              retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: localType),
              retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: localType),
              modelAccessPath: 'audit.moyenneTensionLocaux[$lIdx].conditionsExploitation[$i]',
            ));
          }

          // Cellules MT
          for (var cIdx = 0; cIdx < local.cellules.length; cIdx++) {
            final cellule = local.cellules[cIdx];
            countCellules++;
            if (cellule.elementsVerifies.isNotEmpty) countTotalTableauxInspectes++;
            for (var i = 0; i < cellule.elementsVerifies.length; i++) {
              countTotalLignesAnalysees++;
              final el = cellule.elementsVerifies[i];
              final conf = _parseConformity(el.conforme, el.estNA);
              if (conf == 'oui') countLignesOui++;
              else if (conf == 'sans_objet') countLignesSansObjet++;
              else if (conf == 'non') countLignesNon++;

              diagnosticItems.add(AuditDiagnosticItem(
                objectType: 'Cellule MT',
                objectName: '${local.nom} / Cellule ${cellule.fonction}',
                objectId: 'hash_${identityHashCode(cellule)}',
                tableName: 'Tableau Cellule',
                verificationPoint: el.elementControle,
                rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
                isNonConforme: conf == 'non',
                retrievedCriticality: _resolveCriticalityString(el, localType: localType),
                retrievedPriority: el.priorite,
                retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: localType),
                retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: localType),
                modelAccessPath: 'audit.moyenneTensionLocaux[$lIdx].cellules[$cIdx].elementsVerifies[$i]',
              ));
            }
          }

          // Transformateurs MT/BT
          for (var tIdx = 0; tIdx < local.transformateurs.length; tIdx++) {
            final transfo = local.transformateurs[tIdx];
            countTransformateurs++;
            if (transfo.elementsVerifies.isNotEmpty) countTotalTableauxInspectes++;
            for (var i = 0; i < transfo.elementsVerifies.length; i++) {
              countTotalLignesAnalysees++;
              final el = transfo.elementsVerifies[i];
              final conf = _parseConformity(el.conforme, el.estNA);
              if (conf == 'oui') countLignesOui++;
              else if (conf == 'sans_objet') countLignesSansObjet++;
              else if (conf == 'non') countLignesNon++;

              diagnosticItems.add(AuditDiagnosticItem(
                objectType: 'Transformateur MT/BT',
                objectName: '${local.nom} / Transformateur ${tIdx + 1}',
                objectId: 'hash_${identityHashCode(transfo)}',
                tableName: 'Tableau Transformateur',
                verificationPoint: el.elementControle,
                rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
                isNonConforme: conf == 'non',
                retrievedCriticality: _resolveCriticalityString(el, localType: localType),
                retrievedPriority: el.priorite,
                retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: localType),
                retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: localType),
                modelAccessPath: 'audit.moyenneTensionLocaux[$lIdx].transformateurs[$tIdx].elementsVerifies[$i]',
              ));
            }
          }

          // Coffrets dans ce local MT
          for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
            final coffret = local.coffrets[eqIdx];
            final coffretHash = identityHashCode(coffret);
            if (!visitedCoffrets.contains(coffretHash)) {
              visitedCoffrets.add(coffretHash);
              countEquipements++;
              _diagnoseEquipement(
                coffret: coffret,
                accessPathPrefix: 'audit.moyenneTensionLocaux[$lIdx].coffrets[$eqIdx]',
                locationName: local.nom,
                addDiagnosticItem: (item) {
                  countTotalLignesAnalysees++;
                  if (item.rawConformity == 'oui') countLignesOui++;
                  else if (item.rawConformity == 'sans_objet') countLignesSansObjet++;
                  else if (item.isNonConforme) countLignesNon++;
                  diagnosticItems.add(item);
                },
                incrementTableauxCount: () => countTotalTableauxInspectes++,
              );
            }
          }
        }
      }

      // 2. LOCAUX BT & ZONES BT
      for (var zIdx = 0; zIdx < audit.basseTensionZones.length; zIdx++) {
        final zone = audit.basseTensionZones[zIdx];
        for (var lIdx = 0; lIdx < zone.locaux.length; lIdx++) {
          final local = zone.locaux[lIdx];
          final localHash = identityHashCode(local);
          if (!visitedBTLocaux.contains(localHash)) {
            visitedBTLocaux.add(localHash);
            if (local.type == 'LOCAL_GROUPE_ELECTROGENE') {
              countGroupesElectrogenes++;
            } else {
              countLocauxBT++;
            }

            final objectTypeStr = local.type == 'LOCAL_GROUPE_ELECTROGENE' ? 'Groupe Électrogène' : 'Local BT';

            // Dispositions Constructives
            if (local.dispositionsConstructives != null) {
              if (local.dispositionsConstructives!.isNotEmpty) countTotalTableauxInspectes++;
              for (var i = 0; i < local.dispositionsConstructives!.length; i++) {
                countTotalLignesAnalysees++;
                final el = local.dispositionsConstructives![i];
                final conf = _parseConformity(el.conforme, el.estNA);
                if (conf == 'oui') countLignesOui++;
                else if (conf == 'sans_objet') countLignesSansObjet++;
                else if (conf == 'non') countLignesNon++;

                diagnosticItems.add(AuditDiagnosticItem(
                  objectType: objectTypeStr,
                  objectName: '${zone.nom} / ${local.nom}',
                  objectId: 'hash_$localHash',
                  tableName: 'Dispositions constructives',
                  verificationPoint: el.elementControle,
                  rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
                  isNonConforme: conf == 'non',
                  retrievedCriticality: _resolveCriticalityString(el, localType: local.type),
                  retrievedPriority: el.priorite,
                  retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: local.type),
                  retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: local.type),
                  modelAccessPath: 'audit.basseTensionZones[$zIdx].locaux[$lIdx].dispositionsConstructives[$i]',
                ));
              }
            }

            // Conditions d'exploitation
            if (local.conditionsExploitation != null) {
              if (local.conditionsExploitation!.isNotEmpty) countTotalTableauxInspectes++;
              for (var i = 0; i < local.conditionsExploitation!.length; i++) {
                countTotalLignesAnalysees++;
                final el = local.conditionsExploitation![i];
                final conf = _parseConformity(el.conforme, el.estNA);
                if (conf == 'oui') countLignesOui++;
                else if (conf == 'sans_objet') countLignesSansObjet++;
                else if (conf == 'non') countLignesNon++;

                diagnosticItems.add(AuditDiagnosticItem(
                  objectType: objectTypeStr,
                  objectName: '${zone.nom} / ${local.nom}',
                  objectId: 'hash_$localHash',
                  tableName: 'Conditions d\'exploitation',
                  verificationPoint: el.elementControle,
                  rawConformity: el.conforme == false ? 'non' : (el.estNA ? 'sans_objet' : 'oui'),
                  isNonConforme: conf == 'non',
                  retrievedCriticality: _resolveCriticalityString(el, localType: local.type),
                  retrievedPriority: el.priorite,
                  retrievedNormativeRef: el.referenceNormativeEffectiveFor(localType: local.type),
                  retrievedRiskFamily: el.familleRisqueEffectiveFor(localType: local.type),
                  modelAccessPath: 'audit.basseTensionZones[$zIdx].locaux[$lIdx].conditionsExploitation[$i]',
                ));
              }
            }

            // Coffrets dans ce local BT
            for (var eqIdx = 0; eqIdx < local.coffrets.length; eqIdx++) {
              final coffret = local.coffrets[eqIdx];
              final coffretHash = identityHashCode(coffret);
              if (!visitedCoffrets.contains(coffretHash)) {
                visitedCoffrets.add(coffretHash);
                countEquipements++;
                _diagnoseEquipement(
                  coffret: coffret,
                  accessPathPrefix: 'audit.basseTensionZones[$zIdx].locaux[$lIdx].coffrets[$eqIdx]',
                  locationName: '${zone.nom} / ${local.nom}',
                  addDiagnosticItem: (item) {
                    countTotalLignesAnalysees++;
                    if (item.rawConformity == 'oui') countLignesOui++;
                    else if (item.rawConformity == 'sans_objet') countLignesSansObjet++;
                    else if (item.isNonConforme) countLignesNon++;
                    diagnosticItems.add(item);
                  },
                  incrementTableauxCount: () => countTotalTableauxInspectes++,
                );
              }
            }
          }
        }

        // Équipements directs de la zone BT
        for (var eqIdx = 0; eqIdx < zone.coffretsDirects.length; eqIdx++) {
          final coffret = zone.coffretsDirects[eqIdx];
          final coffretHash = identityHashCode(coffret);
          if (!visitedCoffrets.contains(coffretHash)) {
            visitedCoffrets.add(coffretHash);
            countEquipements++;
            _diagnoseEquipement(
              coffret: coffret,
              accessPathPrefix: 'audit.basseTensionZones[$zIdx].coffretsDirects[$eqIdx]',
              locationName: zone.nom,
              addDiagnosticItem: (item) {
                countTotalLignesAnalysees++;
                if (item.rawConformity == 'oui') countLignesOui++;
                else if (item.rawConformity == 'sans_objet') countLignesSansObjet++;
                else if (item.isNonConforme) countLignesNon++;
                diagnosticItems.add(item);
              },
              incrementTableauxCount: () => countTotalTableauxInspectes++,
            );
          }
        }
      }
    }

    // 3. FOUDRE
    if (foudres.isNotEmpty) countTotalTableauxInspectes++;
    for (var i = 0; i < foudres.length; i++) {
      final f = foudres[i];
      if (f.observation.trim().isNotEmpty) {
        countTotalLignesAnalysees++;
        countLignesNon++;
        diagnosticItems.add(AuditDiagnosticItem(
          objectType: 'Foudre',
          objectName: 'Installation Foudre',
          objectId: 'foudre_hash_${identityHashCode(f)}',
          tableName: 'Observations Foudre',
          verificationPoint: 'Observation Foudre ${i + 1}',
          rawConformity: 'non',
          isNonConforme: true,
          retrievedCriticality: _criticalityFromInt(f.niveauPriorite),
          retrievedPriority: f.niveauPriorite,
          modelAccessPath: 'foudres[$i]',
        ));
      }
    }

    final nonConformes = diagnosticItems.where((e) => e.isNonConforme).toList();
    final countCritiques = nonConformes.where((e) => e.retrievedCriticality == 'Critique').length;
    final countMajeures = nonConformes.where((e) => e.retrievedCriticality == 'Majeure').length;
    final countMineures = nonConformes.where((e) => e.retrievedCriticality == 'Mineure').length;
    final countNonSpecifiees = nonConformes.where((e) => e.retrievedCriticality != 'Critique' && e.retrievedCriticality != 'Majeure' && e.retrievedCriticality != 'Mineure').length;

    return AuditValidationReport(
      missionId: missionId,
      countLocauxMT: countLocauxMT,
      countLocauxBT: countLocauxBT,
      countCellules: countCellules,
      countTransformateurs: countTransformateurs,
      countGroupesElectrogenes: countGroupesElectrogenes,
      countEquipements: countEquipements,
      countTotalTableauxInspectes: countTotalTableauxInspectes,
      countTotalLignesAnalysees: countTotalLignesAnalysees,
      countLignesOui: countLignesOui,
      countLignesSansObjet: countLignesSansObjet,
      countLignesNon: countLignesNon,
      countCritiques: countCritiques,
      countMajeures: countMajeures,
      countMineures: countMineures,
      countNonSpecifiees: countNonSpecifiees,
      diagnosticItems: diagnosticItems,
    );
  }

  static void _diagnoseEquipement({
    required CoffretArmoire coffret,
    required String accessPathPrefix,
    required String locationName,
    required Function(AuditDiagnosticItem) addDiagnosticItem,
    required VoidCallback incrementTableauxCount,
  }) {
    final coffretHash = identityHashCode(coffret);
    final typeEquipementStr = coffret.type.isNotEmpty ? coffret.type : 'Équipement';

    if (coffret.pointsVerification.isNotEmpty) incrementTableauxCount();
    for (var i = 0; i < coffret.pointsVerification.length; i++) {
      final pv = coffret.pointsVerification[i];
      final confRaw = pv.conformite.toLowerCase().trim();
      final isNon = confRaw == 'non' || confRaw == 'non conforme' || confRaw == 'false';
      final isSO = confRaw == 'na' || confRaw == 'sans_objet' || confRaw == 'n/a';

      if (pv.observations != null && pv.observations!.isNotEmpty) {
        for (var j = 0; j < pv.observations!.length; j++) {
          final obs = pv.observations![j];
          addDiagnosticItem(AuditDiagnosticItem(
            objectType: typeEquipementStr,
            objectName: '$locationName / ${coffret.nom}',
            objectId: 'hash_$coffretHash',
            tableName: 'Points de vérification',
            verificationPoint: pv.pointVerification,
            rawConformity: isNon ? 'non' : (isSO ? 'sans_objet' : 'oui'),
            isNonConforme: isNon,
            retrievedCriticality: _resolveCriticalityString(obs),
            retrievedPriority: obs.priorite ?? pv.priorite,
            retrievedNormativeRef: obs.referenceNormativeEffectiveFor() ?? pv.referenceNormative,
            retrievedRiskFamily: obs.familleRisqueEffectiveFor(),
            modelAccessPath: '$accessPathPrefix.pointsVerification[$i].observations[$j]',
          ));
        }
      } else {
        addDiagnosticItem(AuditDiagnosticItem(
          objectType: typeEquipementStr,
          objectName: '$locationName / ${coffret.nom}',
          objectId: 'hash_$coffretHash',
          tableName: 'Points de vérification',
          verificationPoint: pv.pointVerification,
          rawConformity: isNon ? 'non' : (isSO ? 'sans_objet' : 'oui'),
          isNonConforme: isNon,
          retrievedCriticality: _resolvePointVerificationCriticality(pv, coffret.type),
          retrievedPriority: pv.priorite,
          retrievedNormativeRef: pv.referenceNormative,
          modelAccessPath: '$accessPathPrefix.pointsVerification[$i]',
        ));
      }
    }
  }

  static String _parseConformity(bool? conforme, bool estNA) {
    if (estNA) return 'sans_objet';
    if (conforme == false) return 'non';
    return 'oui';
  }

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
      final s = directVal.toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
    if (meta != null && meta.criticite.trim().isNotEmpty) {
      final s = meta.criticite.trim().toLowerCase();
      if (s.contains('critique') || s == '3') return 'Critique';
      if (s.contains('majeur') || s == '2') return 'Majeure';
      if (s.contains('mineur') || s == '1') return 'Mineure';
    }
    return 'Non spécifiée';
  }

  static String _criticalityFromInt(int? priority) {
    if (priority == 3) return 'Critique';
    if (priority == 2) return 'Majeure';
    if (priority == 1) return 'Mineure';
    return 'Non spécifiée';
  }
}
