import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';

/// Service centralisé de synchronisation entre l'Audit des Installations 
/// (Cellules MT et Transformateurs MT/BT) et la Description des Installations.
class InstallationDescriptionSyncService {
  static const String _auditBox = 'audit_installations_electriques';

  /// Normalisation intelligente des clés (accents, casse, séparateurs)
  static String normalizeKey(String key) => InstallationFieldsRegistry.normalizeKey(key);

  /// Dictionnaire d'alias pour les champs de Cellules MT
  static final Map<String, String> _celluleAliases = {
    normalizeKey(InstallationFieldsRegistry.keyGammeCellule): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey('Gamme'): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey('Gamme de la cellule'): InstallationFieldsRegistry.keyGammeCellule,
    normalizeKey(InstallationFieldsRegistry.keyTypeCellule): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('TYPE DE CELLULE'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('Type'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('Type de cellule'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey(InstallationFieldsRegistry.keyTensionAssignee): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey(InstallationFieldsRegistry.keyTensionAssigneeMT): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey('Tension assignée (kV)'): InstallationFieldsRegistry.keyTensionAssigneeMT,
    normalizeKey(InstallationFieldsRegistry.keyTensionDeServiceMT): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('Tension de service'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('TENSION DE SERVICE (kV)'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey('Tension de service (kV)'): InstallationFieldsRegistry.keyTensionDeServiceMT,
    normalizeKey(InstallationFieldsRegistry.keyPouvoirCoupure): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey('POUVOIR DE COUPURE ASSIGNE(KA)'): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey('Pouvoir de coupure assigné (kA)'): InstallationFieldsRegistry.keyPouvoirCoupure,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurMT): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre disjoncteur'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableMT): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('SECTION DU CABLE(mm2)'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('SECTION DU CABLE (mm²)'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey(InstallationFieldsRegistry.keyNatureReseau): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey('NATURE DU RESEAU'): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey('Nature reseau'): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey(InstallationFieldsRegistry.keyPresenceIacm): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('Presence IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('OBSERVATIONS'): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Dictionnaire d'alias pour les champs de Transformateurs MT/BT
  static final Map<String, String> _transfoAliases = {
    normalizeKey(InstallationFieldsRegistry.keyPuissanceTransformateur): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('PUISSANCE TRANSFORMATEUR (KVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance (kVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey(InstallationFieldsRegistry.keyTypeTransformateur): InstallationFieldsRegistry.keyTypeTransformateur,
    normalizeKey('TYPE DE TRANSFORMATEUR'): InstallationFieldsRegistry.keyTypeTransformateur,
    normalizeKey(InstallationFieldsRegistry.keyIntensiteNominale): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('INTENSITE NOMINALE'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey('Intensite nominale (A)'): InstallationFieldsRegistry.keyIntensiteNominale,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurBT):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur Sortie'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableBT): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('SECTION DU CABLE'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey(InstallationFieldsRegistry.keyTensionPrimaireSecondaire): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('TENSION MT/BT'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire / secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire/secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey(InstallationFieldsRegistry.keyCouplage): InstallationFieldsRegistry.keyCouplage,
    normalizeKey('COUPLAGE'): InstallationFieldsRegistry.keyCouplage,
    normalizeKey(InstallationFieldsRegistry.keyTypeReseau): InstallationFieldsRegistry.keyTypeReseau,
    normalizeKey('TYPE DE RESEAU'): InstallationFieldsRegistry.keyTypeReseau,
    normalizeKey(InstallationFieldsRegistry.keyPccAmont): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey('PCC AMONT EN MVA'): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey('PCC amont (MVA)'): InstallationFieldsRegistry.keyPccAmont,
    normalizeKey(InstallationFieldsRegistry.keyPuissanceUcc): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey('UCC EN %'): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey('Puissance UCC (%)'): InstallationFieldsRegistry.keyPuissanceUcc,
    normalizeKey(InstallationFieldsRegistry.keyIk3Max): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey('IK3 MAX(KA)'): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey('IK3 MAX (kA)'): InstallationFieldsRegistry.keyIk3Max,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('OBSERVATIONS'): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Expose publiquement le dictionnaire d'alias pour les Cellules MT
  static Map<String, String> get celluleAliases => _celluleAliases;

  /// Expose publiquement le dictionnaire d'alias pour les Transformateurs MT/BT
  static Map<String, String> get transfoAliases => _transfoAliases;

  /// Recherche une valeur dans un dictionnaire de données avec alias tolérant
  static String getFieldWithAlias(
      Map<String, String>? data, String targetField, Map<String, String> aliases) {
    if (data == null || data.isEmpty) return '';

    // 1. Match exact par clé
    if (data.containsKey(targetField) && data[targetField]!.trim().isNotEmpty) {
      return data[targetField]!.trim();
    }

    final targetNorm = normalizeKey(targetField);
    final targetCanonical = aliases[targetNorm];

    for (final entry in data.entries) {
      if (entry.value.trim().isEmpty) continue;
      final entryNorm = normalizeKey(entry.key);
      
      // 2. Match par clé normalisée directe
      if (entryNorm == targetNorm) {
        return entry.value.trim();
      }
      
      // 3. Match via la clé canonique commune dans les alias
      if (targetCanonical != null) {
        final entryCanonical = aliases[entryNorm];
        if (entryCanonical == targetCanonical || entryNorm == normalizeKey(targetCanonical)) {
          return entry.value.trim();
        }
      } else if (aliases.containsKey(entryNorm) && normalizeKey(aliases[entryNorm]!) == targetNorm) {
        return entry.value.trim();
      }
    }

    return '';
  }

  /// Comparaison d'égalité profonde entre deux listes d'InstallationItem
  static bool _areItemListsEqual(List<InstallationItem> a, List<InstallationItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final itemA = a[i];
      final itemB = b[i];
      if (itemA.photoPaths.length != itemB.photoPaths.length) return false;
      for (int p = 0; p < itemA.photoPaths.length; p++) {
        if (itemA.photoPaths[p] != itemB.photoPaths[p]) return false;
      }
      if (itemA.data.length != itemB.data.length) return false;
      for (final entry in itemA.data.entries) {
        if (itemB.data[entry.key] != entry.value) return false;
      }
    }
    return true;
  }

  /// Synchronise l'ensemble de l'Audit des Installations vers la Description des Installations
  static Future<void> syncAuditToDescription(AuditInstallationsElectriques audit) async {
    try {
      final missionId = audit.missionId;
      final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
      
      DescriptionInstallations? desc = descBox.get(missionId);
      desc ??= descBox.values.firstWhere(
        (d) => d.missionId == missionId,
        orElse: () => DescriptionInstallations.create(missionId),
      );

      final oldMTA = List<InstallationItem>.from(desc.alimentationMoyenneTension);
      final oldBTA = List<InstallationItem>.from(desc.alimentationBasseTension);

      bool auditModifie = false;

      // 1. Synchronisation des Cellules MT -> alimentationMoyenneTension
      auditModifie |= await _syncCellules(audit, desc);

      // 2. Synchronisation des Transformateurs MT/BT -> alimentationBasseTension
      auditModifie |= await _syncTransformateurs(audit, desc);

      // Sauvegarde des modifications de l'audit si des syncId ont été générés
      if (auditModifie) {
        Box<AuditInstallationsElectriques> auditBox;
        if (Hive.isBoxOpen(_auditBox)) {
          auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
        } else {
          auditBox = await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
        }
        await auditBox.put(audit.key ?? missionId, audit);
      }

      final mtEqual = _areItemListsEqual(oldMTA, desc.alimentationMoyenneTension);
      final btEqual = _areItemListsEqual(oldBTA, desc.alimentationBasseTension);

      if (!mtEqual || !btEqual || descBox.get(missionId) == null) {
        desc.updatedAt = DateTime.now();
        await descBox.put(missionId, desc);
        if (kDebugMode) {
          print('✅ Synchronisation Audit ↔ Description enregistrée pour la mission $missionId');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Synchronisation Audit ↔ Description : Aucun changement (No-Op) pour $missionId');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur de synchronisation Audit ↔ Description: $e\n$st');
      }
    }
  }

  /// Mécanisme d'auto-réparation et de synchronisation idempotente pour une mission
  static Future<void> repairAndSyncDescriptions(String missionId) async {
    try {
      Box<AuditInstallationsElectriques> auditBox;
      if (Hive.isBoxOpen(_auditBox)) {
        auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
      } else {
        auditBox = await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
      }
      
      final audit = auditBox.values.firstWhere(
        (a) => a.missionId == missionId,
        orElse: () => auditBox.get(missionId) ?? AuditInstallationsElectriques(missionId: missionId, updatedAt: DateTime.now()),
      );
      
      await syncAuditToDescription(audit);
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur repairAndSyncDescriptions pour mission $missionId: $e\n$st');
      }
    }
  }

  /// Extraction de toutes les cellules dans tous les locaux (locaux MT directs, zones MT et zones BT)
  static List<Cellule> _collectAllCellulesMT(
      AuditInstallationsElectriques audit, List<bool> auditModifieRef) {
    final List<Cellule> cellules = [];

    void checkAndAddCellule(Cellule c) {
      if (c.syncId == null || c.syncId!.isEmpty) {
        c.syncId =
            'cellule_${DateTime.now().microsecondsSinceEpoch}_${cellules.length}';
        auditModifieRef[0] = true;
      }
      cellules.add(c);
    }

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      for (var cellule in local.cellules) {
        checkAndAddCellule(cellule);
      }
    }

    // 2. Locaux des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        for (var cellule in local.cellules) {
          checkAndAddCellule(cellule);
        }
      }
    }

    // 3. Locaux des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var cellule in local.cellules) {
          checkAndAddCellule(cellule);
        }
      }
    }

    return cellules;
  }

  /// Extraction de tous les transformateurs dans tous les locaux (locaux MT directs, zones MT et zones BT)
  static List<TransformateurMTBT> _collectAllTransformateursMT(
      AuditInstallationsElectriques audit, List<bool> auditModifieRef) {
    final List<TransformateurMTBT> transfos = [];

    void checkAndAddTransfo(TransformateurMTBT t) {
      if (t.syncId == null || t.syncId!.isEmpty) {
        t.syncId =
            'transfo_${DateTime.now().microsecondsSinceEpoch}_${transfos.length}';
        auditModifieRef[0] = true;
      }
      transfos.add(t);
    }

    // 1. Locaux MT directs
    for (var local in audit.moyenneTensionLocaux) {
      for (var transfo in local.transformateurs) {
        checkAndAddTransfo(transfo);
      }
    }

    // 2. Locaux des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        for (var transfo in local.transformateurs) {
          checkAndAddTransfo(transfo);
        }
      }
    }

    // 3. Locaux des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var transfo in local.transformateurs) {
          checkAndAddTransfo(transfo);
        }
      }
    }

    return transfos;
  }

  /// Synchronisation des cellules vers alimentationMoyenneTension
  static Future<bool> _syncCellules(
      AuditInstallationsElectriques audit, DescriptionInstallations desc) async {
    final List<bool> auditModifieRef = [false];
    final cellulesAudit = _collectAllCellulesMT(audit, auditModifieRef);
    final List<InstallationItem> itemsMiseAJour = [];

    // Conserver les items créés manuellement sans auditCelluleId
    for (var item in desc.alimentationMoyenneTension) {
      final auditCelluleId = item.data['auditCelluleId'];
      if (auditCelluleId == null || auditCelluleId.isEmpty) {
        itemsMiseAJour.add(item);
      }
    }

    // Mettre à jour / ajouter les cellules de l'audit
    for (var cellule in cellulesAudit) {
      final observationsTxt = (cellule.observations ?? [])
          .map((o) => o.observation ?? '')
          .where((s) => s.isNotEmpty)
          .join('\n');

      InstallationItem? itemExistant;
      try {
        itemExistant = desc.alimentationMoyenneTension.firstWhere(
            (item) => item.data['auditCelluleId'] == cellule.syncId);
      } catch (_) {}

      final Map<String, String> existingData = itemExistant?.data ?? {};

      String valGamme = cellule.gamme ??
          getFieldWithAlias(existingData, 'Gamme De Cellule', _celluleAliases);
      String valType = cellule.type.isNotEmpty
          ? cellule.type
          : getFieldWithAlias(existingData, 'TYPE DE CELLULE', _celluleAliases);
      String valTensionAssignee = cellule.tensionAssignee.isNotEmpty
          ? cellule.tensionAssignee
          : getFieldWithAlias(existingData, 'TENSION ASSIGNEE(KV)', _celluleAliases);
      String valTensionService = (cellule.tensionService != null && cellule.tensionService!.isNotEmpty)
          ? cellule.tensionService!
          : getFieldWithAlias(existingData, 'Tension de service', _celluleAliases);
      String valPouvoirCoupure = cellule.pouvoirCoupure.isNotEmpty
          ? cellule.pouvoirCoupure
          : getFieldWithAlias(existingData, 'POUVOIR DE COUPURE ASSIGNE(KA)', _celluleAliases);
      String valCalibre = cellule.calibreDisjoncteur ??
          getFieldWithAlias(existingData, 'Calibre Du Disjoncteur', _celluleAliases);
      String valSection = cellule.sectionCables ??
          getFieldWithAlias(existingData, 'SECTION DU CABLE(mm2)', _celluleAliases);
      String valNature = cellule.natureReseau ??
          getFieldWithAlias(existingData, 'NATURE DU RESEAU', _celluleAliases);
      String valIacm = cellule.presenceIacm ??
          getFieldWithAlias(existingData, 'PRESENCE IACM', _celluleAliases);

      final itemData = <String, String>{
        'auditCelluleId': cellule.syncId!,
        'Gamme De Cellule': valGamme,
        'Type De Cellule': valType,
        'TYPE DE CELLULE': valType,
        'Tension assignée': valTensionAssignee,
        'TENSION ASSIGNEE(KV)': valTensionAssignee,
        if (valTensionService.isNotEmpty) 'Tension de service': valTensionService,
        'Pouvoir de coupure assigné': valPouvoirCoupure,
        'POUVOIR DE COUPURE ASSIGNE(KA)': valPouvoirCoupure,
        'Calibre Du Disjoncteur': valCalibre,
        'Section Du Cable': valSection,
        'SECTION DU CABLE(mm2)': valSection,
        'Nature Du Reseau': valNature,
        'NATURE DU RESEAU': valNature,
        if (valNature == 'Aérien' || valIacm.isNotEmpty) 'PRESENCE IACM': valIacm,
        'Observations': observationsTxt,
        'OBSERVATIONS': observationsTxt,
      };

      if (itemExistant != null) {
        itemExistant.data = itemData;
        itemExistant.photoPaths = List.from(cellule.photos);
        itemsMiseAJour.add(itemExistant);
      } else {
        itemsMiseAJour.add(InstallationItem(
          data: itemData,
          photoPaths: List.from(cellule.photos),
          createdAt: DateTime.now(),
        ));
      }
    }

    itemsMiseAJour.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    desc.alimentationMoyenneTension = itemsMiseAJour;
    return auditModifieRef[0];
  }

  /// Synchronisation des transformateurs vers alimentationBasseTension
  static Future<bool> _syncTransformateurs(
      AuditInstallationsElectriques audit, DescriptionInstallations desc) async {
    final List<bool> auditModifieRef = [false];
    final transfosAudit = _collectAllTransformateursMT(audit, auditModifieRef);
    final List<InstallationItem> itemsMiseAJour = [];

    // Conserver les items créés manuellement sans auditTransformateurId
    for (var item in desc.alimentationBasseTension) {
      final auditTransfoId = item.data['auditTransformateurId'];
      if (auditTransfoId == null || auditTransfoId.isEmpty) {
        itemsMiseAJour.add(item);
      }
    }

    // Mettre à jour / ajouter les transformateurs de l'audit
    for (var transfo in transfosAudit) {
      final observationsTxt = (transfo.observations ?? [])
          .map((o) => o.observation ?? '')
          .where((s) => s.isNotEmpty)
          .join('\n');

      InstallationItem? itemExistant;
      try {
        itemExistant = desc.alimentationBasseTension.firstWhere(
            (item) => item.data['auditTransformateurId'] == transfo.syncId);
      } catch (_) {}

      final Map<String, String> existingData = itemExistant?.data ?? {};

      String valPuissance = transfo.puissanceAssignee.isNotEmpty
          ? transfo.puissanceAssignee
          : getFieldWithAlias(existingData, 'PUISSANCE TRANSFORMATEUR (KVA)', _transfoAliases);
      String valTypeTransfo = transfo.typeTransformateur.isNotEmpty
          ? transfo.typeTransformateur
          : getFieldWithAlias(existingData, 'TYPE DE TRANSFORMATEUR', _transfoAliases);
      String valIntensiteNominale = transfo.intensiteNominale ??
          getFieldWithAlias(existingData, 'INTENSITE NOMINALE', _transfoAliases);
      String valCalibre = transfo.calibreDisjoncteur ??
          getFieldWithAlias(
              existingData, 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', _transfoAliases);
      String valSection = transfo.sectionCables ??
          getFieldWithAlias(existingData, 'SECTION DU CABLE', _transfoAliases);
      String valTension = transfo.tensionPrimaireSecondaire.isNotEmpty
          ? transfo.tensionPrimaireSecondaire
          : getFieldWithAlias(existingData, 'TENSION MT/BT', _transfoAliases);
      String valCouplage = transfo.couplage ??
          getFieldWithAlias(existingData, 'COUPLAGE', _transfoAliases);
      String valTypeReseau = transfo.typeReseau ??
          getFieldWithAlias(existingData, 'TYPE DE RESEAU', _transfoAliases);
      String valPccAmont = transfo.pccAmont ??
          getFieldWithAlias(existingData, 'PCC AMONT EN MVA', _transfoAliases);
      String valPuissanceUcc = transfo.puissanceUcc ??
          getFieldWithAlias(existingData, 'UCC EN %', _transfoAliases);
      String valIk3Max = transfo.ik3Max ??
          getFieldWithAlias(existingData, 'IK3 MAX(KA)', _transfoAliases);

      final itemData = <String, String>{
        'auditTransformateurId': transfo.syncId!,
        'Puissance Transformateur': valPuissance,
        'PUISSANCE TRANSFORMATEUR (KVA)': valPuissance,
        'Type de transformateur': valTypeTransfo,
        'TYPE DE TRANSFORMATEUR': valTypeTransfo,
        'Intensité nominale': valIntensiteNominale,
        'INTENSITE NOMINALE': valIntensiteNominale,
        'Calibre Du Disjoncteur Sortie Transformateur': valCalibre,
        'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR': valCalibre,
        'Section Du Cable': valSection,
        'SECTION DU CABLE': valSection,
        'Tension': valTension,
        'TENSION MT/BT': valTension,
        'Couplage': valCouplage,
        'COUPLAGE': valCouplage,
        'Type de réseau': valTypeReseau,
        'TYPE DE RESEAU': valTypeReseau,
        'PCC amont': valPccAmont,
        'PCC AMONT EN MVA': valPccAmont,
        'Puissance UCC': valPuissanceUcc,
        'UCC EN %': valPuissanceUcc,
        'IK3 MAX': valIk3Max,
        'IK3 MAX(KA)': valIk3Max,
        'Observations': observationsTxt,
        'OBSERVATIONS': observationsTxt,
      };

      if (itemExistant != null) {
        itemExistant.data = itemData;
        itemExistant.photoPaths = List.from(transfo.photos);
        itemsMiseAJour.add(itemExistant);
      } else {
        itemsMiseAJour.add(InstallationItem(
          data: itemData,
          photoPaths: List.from(transfo.photos),
          createdAt: DateTime.now(),
        ));
      }
    }

    itemsMiseAJour.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    desc.alimentationBasseTension = itemsMiseAJour;
    return auditModifieRef[0];
  }
}
