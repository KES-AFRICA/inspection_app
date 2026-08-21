import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';

/// Ligne de donnée normalisée pour un tableau de la Description des Installations dans le PDF
class InstallationDescriptionPdfRow {
  final int index;
  final String rawId;
  final Map<String, String> normalizedFields;

  InstallationDescriptionPdfRow({
    required this.index,
    required this.rawId,
    required this.normalizedFields,
  });

  /// Extrait la valeur d'une colonne PDF de manière tolérante aux clés anciennes,
  /// récentes, majuscules, minuscules, accents et unités.
  String getValueForColumn(String columnHeader, String sectionKey) {
    // 1. Match direct sur l'en-tête exact
    if (normalizedFields.containsKey(columnHeader) &&
        normalizedFields[columnHeader]!.trim().isNotEmpty) {
      return normalizedFields[columnHeader]!.trim();
    }

    // 2. Match sur la clé normalisée
    final targetNorm = InstallationFieldsRegistry.normalizeKey(columnHeader);
    if (normalizedFields.containsKey(targetNorm) &&
        normalizedFields[targetNorm]!.trim().isNotEmpty) {
      return normalizedFields[targetNorm]!.trim();
    }

    // 3. Fallback via le dictionnaire d'alias global
    final aliases = sectionKey == 'MT'
        ? InstallationDescriptionSyncService.celluleAliases
        : InstallationDescriptionSyncService.transfoAliases;

    final valAlias = InstallationDescriptionSyncService.getFieldWithAlias(
        normalizedFields, columnHeader, aliases);
    if (valAlias.isNotEmpty) return valAlias;

    // 4. Recherche tolérante par égalité normalisée
    for (final entry in normalizedFields.entries) {
      if (entry.value.trim().isEmpty) continue;
      final entryNorm = InstallationFieldsRegistry.normalizeKey(entry.key);
      if (entryNorm == targetNorm) {
        return entry.value.trim();
      }
    }

    return '-';
  }
}

/// Structure de données intermédiaire normalisée alimentée directement à partir des entités réelles d'audit
/// (Cellule & TransformateurMTBT) et synchronisées avec DescriptionInstallations pour le rapport PDF.
class InstallationDescriptionPdfData {
  final List<InstallationDescriptionPdfRow> mtRows;
  final List<InstallationDescriptionPdfRow> btRows;

  InstallationDescriptionPdfData({
    required this.mtRows,
    required this.btRows,
  });

  /// Construit la représentation normalisée pour le PDF en respectant :
  /// 1. L'ordre exact de la liste des descriptions de l'application (du plus ancien au plus récent).
  /// 2. Le filtrage strict : seules les descriptions correspondant à un équipement d'audit ACTIF sont affichées dans le PDF.
  factory InstallationDescriptionPdfData.fromDescription({
    required DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
  }) {
    final mtRows = <InstallationDescriptionPdfRow>[];
    final btRows = <InstallationDescriptionPdfRow>[];

    // Indexer les équipements d'audit actifs par leur syncId
    final activeCellulesMap = <String, Cellule>{};
    final activeTransfosMap = <String, TransformateurMTBT>{};

    if (audit != null) {
      for (var c in _collectAllCellules(audit)) {
        if (c.syncId != null && c.syncId!.isNotEmpty) {
          activeCellulesMap[c.syncId!] = c;
        }
      }
      for (var t in _collectAllTransformateurs(audit)) {
        if (t.syncId != null && t.syncId!.isNotEmpty) {
          activeTransfosMap[t.syncId!] = t;
        }
      }
    }

    final processedCelluleIds = <String>{};
    final processedTransfoIds = <String>{};

    // ── 1. CONSTRUCT DEPUIS LA LISTE DE DESCRIPTION (RESPECT DE L'ORDRE D'ORIGINE) ──
    if (desc != null) {
      // MT : Ordre du plus ancien au plus récent
      final itemsMT = List<InstallationItem>.from(desc.alimentationMoyenneTension);
      itemsMT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsMT) {
        final auditCelluleId = item.data['auditCelluleId'];
        if (auditCelluleId != null && activeCellulesMap.containsKey(auditCelluleId)) {
          final c = activeCellulesMap[auditCelluleId]!;
          mtRows.add(_createRowFromCelluleAndItem(c, item, mtRows.length + 1));
          processedCelluleIds.add(auditCelluleId);
        }
      }

      // BT : Ordre du plus ancien au plus récent
      final itemsBT = List<InstallationItem>.from(desc.alimentationBasseTension);
      itemsBT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsBT) {
        final auditTransfoId = item.data['auditTransformateurId'];
        if (auditTransfoId != null && activeTransfosMap.containsKey(auditTransfoId)) {
          final t = activeTransfosMap[auditTransfoId]!;
          btRows.add(_createRowFromTransformateurAndItem(t, item, btRows.length + 1));
          processedTransfoIds.add(auditTransfoId);
        }
      }
    }

    // ── 2. COMPLÉMENTATION POUR TOUT ÉQUIPEMENT ACTIF SANS ITEM DESCRIPTIF CORRESPONDANT ──
    if (audit != null) {
      for (var entry in activeCellulesMap.entries) {
        if (!processedCelluleIds.contains(entry.key)) {
          mtRows.add(_createRowFromCellule(entry.value, mtRows.length + 1));
        }
      }
      for (var entry in activeTransfosMap.entries) {
        if (!processedTransfoIds.contains(entry.key)) {
          btRows.add(_createRowFromTransformateur(entry.value, btRows.length + 1));
        }
      }
    }

    return InstallationDescriptionPdfData(mtRows: mtRows, btRows: btRows);
  }

  /// Construit une ligne de tableau PDF à partir d'une Cellule active et de son item descriptif
  static InstallationDescriptionPdfRow _createRowFromCelluleAndItem(
      Cellule c, InstallationItem item, int rowIndex) {
    final row = _createRowFromCellule(c, rowIndex);
    // Enrichir avec tout champ personnalisé présent dans item.data
    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty && !row.normalizedFields.containsKey(entry.key)) {
        row.normalizedFields[entry.key] = entry.value.trim();
        row.normalizedFields[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }
    return row;
  }

  /// Construit une ligne de tableau PDF à partir d'un TransformateurMTBT actif et de son item descriptif
  static InstallationDescriptionPdfRow _createRowFromTransformateurAndItem(
      TransformateurMTBT t, InstallationItem item, int rowIndex) {
    final row = _createRowFromTransformateur(t, rowIndex);
    // Enrichir avec tout champ personnalisé présent dans item.data
    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty && !row.normalizedFields.containsKey(entry.key)) {
        row.normalizedFields[entry.key] = entry.value.trim();
        row.normalizedFields[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }
    return row;
  }

  /// Construit une ligne de tableau PDF directement depuis les propriétés de l'entité Cellule
  static InstallationDescriptionPdfRow _createRowFromCellule(Cellule c, int rowIndex) {
    final normMap = <String, String>{};

    void addField(String headerKey, String value) {
      if (value.trim().isNotEmpty) {
        normMap[headerKey] = value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(headerKey)] = value.trim();
      }
    }

    addField('TYPE DE CELLULE', c.type);
    addField('Type De Cellule', c.type);
    addField('TENSION ASSIGNEE(KV)', c.tensionAssignee);
    addField('Tension assignée', c.tensionAssignee);
    addField('POUVOIR DE COUPURE ASSIGNE(KA)', c.pouvoirCoupure);
    addField('Pouvoir de coupure assigné', c.pouvoirCoupure);
    addField('SECTION DU CABLE(mm2)', c.sectionCables ?? '');
    addField('Section Du Cable', c.sectionCables ?? '');
    addField('NATURE DU RESEAU', c.natureReseau ?? '');
    addField('Nature Du Reseau', c.natureReseau ?? '');

    if (c.tensionService != null && c.tensionService!.isNotEmpty) {
      addField('TENSION DE SERVICE (kV)', c.tensionService!);
      addField('Tension de service', c.tensionService!);
    }
    if (c.gamme != null && c.gamme!.isNotEmpty) {
      addField('Gamme De Cellule', c.gamme!);
    }
    if (c.calibreDisjoncteur != null && c.calibreDisjoncteur!.isNotEmpty) {
      addField('Calibre Du Disjoncteur', c.calibreDisjoncteur!);
    }

    final observationsTxt = (c.observations ?? [])
        .map((o) => o.observation ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n');
    if (observationsTxt.isNotEmpty) {
      addField('Observations', observationsTxt);
      addField('OBSERVATIONS', observationsTxt);
    }

    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: c.syncId ?? 'cellule_$rowIndex',
      normalizedFields: normMap,
    );
  }

  /// Construit une ligne de tableau PDF directement depuis les propriétés de l'entité TransformateurMTBT
  static InstallationDescriptionPdfRow _createRowFromTransformateur(TransformateurMTBT t, int rowIndex) {
    final normMap = <String, String>{};

    void addField(String headerKey, String value) {
      if (value.trim().isNotEmpty) {
        normMap[headerKey] = value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(headerKey)] = value.trim();
      }
    }

    if (t.nom != null && t.nom!.trim().isNotEmpty) {
      addField('NOM DU TRANSFORMATEUR', t.nom!.trim());
      addField('Nom du transformateur', t.nom!.trim());
      addField('DESIGNATION', t.nom!.trim());
    }

    addField('PUISSANCE TRANSFORMATEUR (KVA)', t.puissanceAssignee);
    addField('PUISSANCE TRANSFORMATEUR(KVA)', t.puissanceAssignee);
    addField('Puissance Transformateur', t.puissanceAssignee);
    addField('TYPE DE TRANSFORMATEUR', t.typeTransformateur);
    addField('Type de transformateur', t.typeTransformateur);
    addField('INTENSITE NOMINALE', t.intensiteNominale ?? '');
    addField('INTENSITE NOMINALE (A)', t.intensiteNominale ?? '');
    addField('INTENSITE NOMINALE(A)', t.intensiteNominale ?? '');
    addField('Intensité nominale', t.intensiteNominale ?? '');
    addField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', t.calibreDisjoncteur ?? '');
    addField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR(A)', t.calibreDisjoncteur ?? '');
    addField('Calibre Du Disjoncteur Sortie Transformateur', t.calibreDisjoncteur ?? '');
    addField('SECTION DU CABLE', t.sectionCables ?? '');
    addField('SECTION DU CABLE(mm2)', t.sectionCables ?? '');
    addField('Section Du Cable', t.sectionCables ?? '');
    addField('TENSION MT/BT', t.tensionPrimaireSecondaire);
    addField('TENSION MT/BT(KV)', t.tensionPrimaireSecondaire);
    addField('Tension', t.tensionPrimaireSecondaire);
    addField('COUPLAGE', t.couplage ?? '');
    addField('Couplage', t.couplage ?? '');
    addField('TYPE DE RESEAU', t.typeReseau ?? '');
    addField('Type de réseau', t.typeReseau ?? '');
    addField('PCC AMONT EN MVA', t.pccAmont ?? '');
    addField('PCC AMONT(MVA)', t.pccAmont ?? '');
    addField('PCC amont', t.pccAmont ?? '');
    addField('UCC EN %', t.puissanceUcc ?? '');
    addField('UCC EN(%)', t.puissanceUcc ?? '');
    addField('Puissance UCC', t.puissanceUcc ?? '');
    addField('IK3 MAX(KA)', t.ik3Max ?? '');
    addField('IK3 MAX', t.ik3Max ?? '');

    final observationsTxt = (t.observations ?? [])
        .map((o) => o.observation ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n');
    if (observationsTxt.isNotEmpty) {
      addField('Observations', observationsTxt);
      addField('OBSERVATIONS', observationsTxt);
    }

    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: t.syncId ?? 'transfo_$rowIndex',
      normalizedFields: normMap,
    );
  }

  /// Helper interne pour collecter l'ensemble des Cellules de l'audit
  static List<Cellule> _collectAllCellules(AuditInstallationsElectriques audit) {
    final List<Cellule> res = [];
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      res.addAll(local.cellules);
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        res.addAll(local.cellules);
      }
    }
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        res.addAll(local.cellules);
      }
    }
    return res;
  }

  /// Helper interne pour collecter l'ensemble des Transformateurs de l'audit
  static List<TransformateurMTBT> _collectAllTransformateurs(AuditInstallationsElectriques audit) {
    final List<TransformateurMTBT> res = [];
    for (var local in audit.moyenneTensionLocaux) {
      local.migrateFromOldFields();
      res.addAll(local.transformateurs);
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        local.migrateFromOldFields();
        res.addAll(local.transformateurs);
      }
    }
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        res.addAll(local.transformateurs);
      }
    }
    return res;
  }
}
