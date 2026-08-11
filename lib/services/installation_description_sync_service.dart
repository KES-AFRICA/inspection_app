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
    normalizeKey('Type'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey('Type de cellule'): InstallationFieldsRegistry.keyTypeCellule,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurMT): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre disjoncteur'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey('Calibre'): InstallationFieldsRegistry.keyCalibreDisjoncteurMT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableMT): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableMT,
    normalizeKey(InstallationFieldsRegistry.keyNatureReseau): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey('Nature reseau'): InstallationFieldsRegistry.keyNatureReseau,
    normalizeKey(InstallationFieldsRegistry.keyPresenceIacm): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('Presence IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey('IACM'): InstallationFieldsRegistry.keyPresenceIacm,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Dictionnaire d'alias pour les champs de Transformateurs MT/BT
  static final Map<String, String> _transfoAliases = {
    normalizeKey(InstallationFieldsRegistry.keyPuissanceTransformateur): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey('Puissance (kVA)'): InstallationFieldsRegistry.keyPuissanceTransformateur,
    normalizeKey(InstallationFieldsRegistry.keyCalibreDisjoncteurBT):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur Sortie'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey('Calibre Disjoncteur'):
        InstallationFieldsRegistry.keyCalibreDisjoncteurBT,
    normalizeKey(InstallationFieldsRegistry.keySectionCableBT): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section cable'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey('Section des cables'): InstallationFieldsRegistry.keySectionCableBT,
    normalizeKey(InstallationFieldsRegistry.keyTensionPrimaireSecondaire): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire / secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey('Tension primaire/secondaire'): InstallationFieldsRegistry.keyTensionPrimaireSecondaire,
    normalizeKey(InstallationFieldsRegistry.keyObservations): InstallationFieldsRegistry.keyObservations,
    normalizeKey('Observation'): InstallationFieldsRegistry.keyObservations,
  };

  /// Recherche une valeur dans un dictionnaire de données avec alias tolérant
  static String getFieldWithAlias(
      Map<String, String>? data, String targetField, Map<String, String> aliases) {
    if (data == null || data.isEmpty) return '';

    if (data.containsKey(targetField) && data[targetField]!.isNotEmpty) {
      return data[targetField]!;
    }

    final targetNorm = normalizeKey(targetField);
    for (final entry in data.entries) {
      final entryNorm = normalizeKey(entry.key);
      if (entryNorm == targetNorm ||
          (aliases.containsKey(entryNorm) && aliases[entryNorm] == targetField)) {
        if (entry.value.isNotEmpty) return entry.value;
      }
    }
    return '';
  }

  /// Synchronise l'ensemble de l'Audit des Installations vers la Description des Installations
  static Future<void> syncAuditToDescription(AuditInstallationsElectriques audit) async {
    try {
      final missionId = audit.missionId;
      final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
      var desc = descBox.get(missionId);
      desc ??= DescriptionInstallations.create(missionId);

      bool auditModifie = false;

      // 1. Synchronisation des Cellules MT -> alimentationMoyenneTension
      auditModifie |= await _syncCellules(audit, desc);

      // 2. Synchronisation des Transformateurs MT/BT -> alimentationBasseTension
      auditModifie |= await _syncTransformateurs(audit, desc);

      // Sauvegarde des modifications de l'audit si des syncId ont été générés
      if (auditModifie) {
        final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
        await auditBox.put(audit.key, audit);
      }

      desc.updatedAt = DateTime.now();
      await descBox.put(missionId, desc);

      if (kDebugMode) {
        print('✅ Synchronisation Audit ↔ Description réussie pour la mission $missionId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur de synchronisation Audit ↔ Description: $e\n$st');
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

      // Traitement précis de la source de vérité :
      // Si la propriété dans l'objet Cellule est non-nulle, elle prévaut (permettant la mise à jour et l'effacement).
      // Le fallback getFieldWithAlias n'intervient que si la propriété d'origine est nulle (données legacy uninitialized).
      String valGamme = cellule.gamme ??
          getFieldWithAlias(existingData, 'Gamme De Cellule', _celluleAliases);
      String valType = cellule.type.isNotEmpty
          ? cellule.type
          : getFieldWithAlias(existingData, 'Type De Cellule', _celluleAliases);
      String valCalibre = cellule.calibreDisjoncteur ??
          getFieldWithAlias(existingData, 'Calibre Du Disjoncteur', _celluleAliases);
      String valSection = cellule.sectionCables ??
          getFieldWithAlias(existingData, 'Section Du Cable', _celluleAliases);
      String valNature = cellule.natureReseau ??
          getFieldWithAlias(existingData, 'Nature Du Reseau', _celluleAliases);
      String valIacm = cellule.presenceIacm ??
          getFieldWithAlias(existingData, 'PRESENCE IACM', _celluleAliases);

      final itemData = <String, String>{
        'auditCelluleId': cellule.syncId!,
        'Gamme De Cellule': valGamme,
        'Type De Cellule': valType,
        'Calibre Du Disjoncteur': valCalibre,
        'Section Du Cable': valSection,
        'Nature Du Reseau': valNature,
        if (valNature == 'Aérien' || valIacm.isNotEmpty) 'PRESENCE IACM': valIacm,
        'Observations': observationsTxt,
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

      // Traitement précis de la source de vérité :
      // Si la propriété est non-nulle, elle prévaut. Le fallback getFieldWithAlias n'intervient que sur données legacy nulles.
      String valPuissance = transfo.puissanceAssignee.isNotEmpty
          ? transfo.puissanceAssignee
          : getFieldWithAlias(existingData, 'Puissance Transformateur', _transfoAliases);
      String valCalibre = transfo.calibreDisjoncteur ??
          getFieldWithAlias(
              existingData, 'Calibre Du Disjoncteur Sortie Transformateur', _transfoAliases);
      String valSection = transfo.sectionCables ??
          getFieldWithAlias(existingData, 'Section Du Cable', _transfoAliases);
      String valTension = transfo.tensionPrimaireSecondaire.isNotEmpty
          ? transfo.tensionPrimaireSecondaire
          : getFieldWithAlias(existingData, 'Tension', _transfoAliases);

      final itemData = <String, String>{
        'auditTransformateurId': transfo.syncId!,
        'Puissance Transformateur': valPuissance,
        'Calibre Du Disjoncteur Sortie Transformateur': valCalibre,
        'Section Du Cable': valSection,
        'Tension': valTension,
        'Observations': observationsTxt,
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

    desc.alimentationBasseTension = itemsMiseAJour;
    return auditModifieRef[0];
  }
}
