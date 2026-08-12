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
/// (Cellule & TransformateurMTBT) et complétée par les descriptions historiques pour le rapport PDF.
class InstallationDescriptionPdfData {
  final List<InstallationDescriptionPdfRow> mtRows;
  final List<InstallationDescriptionPdfRow> btRows;

  InstallationDescriptionPdfData({
    required this.mtRows,
    required this.btRows,
  });

  /// Construit la représentation normalisée directement depuis l'Audit (entités réelles)
  /// et la Description (items historiques / manuels)
  factory InstallationDescriptionPdfData.fromDescription({
    required DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
  }) {
    final mtRows = <InstallationDescriptionPdfRow>[];
    final btRows = <InstallationDescriptionPdfRow>[];
    final processedCelluleIds = <String>{};
    final processedTransfoIds = <String>{};

    // ── 1. EXTRACTION DIRECTE DEPUIS LES ENTITÉS RÉELLES DE L'AUDIT ──
    if (audit != null) {
      // a. Extraction des Cellules MT réelles
      final cellulesAudit = _collectAllCellules(audit);
      for (int i = 0; i < cellulesAudit.length; i++) {
        final c = cellulesAudit[i];
        if (c.syncId != null && c.syncId!.isNotEmpty) {
          processedCelluleIds.add(c.syncId!);
        }
        mtRows.add(_createRowFromCellule(c, mtRows.length + 1));
      }

      // b. Extraction des Transformateurs MT/BT réels
      final transfosAudit = _collectAllTransformateurs(audit);
      for (int i = 0; i < transfosAudit.length; i++) {
        final t = transfosAudit[i];
        if (t.syncId != null && t.syncId!.isNotEmpty) {
          processedTransfoIds.add(t.syncId!);
        }
        btRows.add(_createRowFromTransformateur(t, btRows.length + 1));
      }
    }

    // ── 2. INTÉGRATION DES ITEMS MANUELS ET HISTORIQUES DE DESCRIPTION ──
    if (desc != null) {
      // a. Items MT historiques ou manuels sans Cellule d'audit liée
      final itemsMT = List<InstallationItem>.from(desc.alimentationMoyenneTension);
      itemsMT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsMT) {
        final auditCelluleId = item.data['auditCelluleId'];
        if (auditCelluleId == null ||
            auditCelluleId.isEmpty ||
            !processedCelluleIds.contains(auditCelluleId)) {
          mtRows.add(_normalizeItemRow(item, mtRows.length + 1, 'MT'));
        }
      }

      // b. Items BT historiques ou manuels sans Transformateur d'audit lié
      final itemsBT = List<InstallationItem>.from(desc.alimentationBasseTension);
      itemsBT.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var item in itemsBT) {
        final auditTransfoId = item.data['auditTransformateurId'];
        if (auditTransfoId == null ||
            auditTransfoId.isEmpty ||
            !processedTransfoIds.contains(auditTransfoId)) {
          btRows.add(_normalizeItemRow(item, btRows.length + 1, 'BT'));
        }
      }
    }

    return InstallationDescriptionPdfData(mtRows: mtRows, btRows: btRows);
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
    if (c.presenceIacm != null && c.presenceIacm!.isNotEmpty) {
      addField('PRESENCE IACM', c.presenceIacm!);
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

    addField('PUISSANCE TRANSFORMATEUR (KVA)', t.puissanceAssignee);
    addField('Puissance Transformateur', t.puissanceAssignee);
    addField('TYPE DE TRANSFORMATEUR', t.typeTransformateur);
    addField('Type de transformateur', t.typeTransformateur);
    addField('INTENSITE NOMINALE', t.intensiteNominale ?? '');
    addField('Intensité nominale', t.intensiteNominale ?? '');
    addField('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', t.calibreDisjoncteur ?? '');
    addField('Calibre Du Disjoncteur Sortie Transformateur', t.calibreDisjoncteur ?? '');
    addField('SECTION DU CABLE', t.sectionCables ?? '');
    addField('Section Du Cable', t.sectionCables ?? '');
    addField('TENSION MT/BT', t.tensionPrimaireSecondaire);
    addField('Tension', t.tensionPrimaireSecondaire);
    addField('COUPLAGE', t.couplage ?? '');
    addField('Couplage', t.couplage ?? '');
    addField('TYPE DE RESEAU', t.typeReseau ?? '');
    addField('Type de réseau', t.typeReseau ?? '');
    addField('PCC AMONT EN MVA', t.pccAmont ?? '');
    addField('PCC amont', t.pccAmont ?? '');
    addField('UCC EN %', t.puissanceUcc ?? '');
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

  /// Normalisation de secours pour les items manuels ou historiques
  static InstallationDescriptionPdfRow _normalizeItemRow(
      InstallationItem item, int rowIndex, String sectionKey) {
    final Map<String, String> normMap = {};

    for (final entry in item.data.entries) {
      if (entry.value.trim().isNotEmpty) {
        normMap[entry.key] = entry.value.trim();
        normMap[InstallationFieldsRegistry.normalizeKey(entry.key)] = entry.value.trim();
      }
    }

    if (sectionKey == 'MT') {
      _mapFieldIfMissing(normMap, 'TYPE DE CELLULE', [
        'TYPE DE CELLULE',
        'Type De Cellule',
        'type',
        'Type',
        'Type de cellule',
        'Gamme De Cellule',
        'gamme',
      ]);
      _mapFieldIfMissing(normMap, 'TENSION DE SERVICE (kV)', [
        'TENSION DE SERVICE (kV)',
        'Tension de service',
        'tensionService',
        'Tension de service (kV)',
        'TENSION DE SERVICE',
      ]);
      _mapFieldIfMissing(normMap, 'TENSION ASSIGNEE(KV)', [
        'TENSION ASSIGNEE(KV)',
        'Tension assignée',
        'tensionAssignee',
        'Tension assignée (kV)',
        'TENSION ASSIGNEE',
      ]);
      _mapFieldIfMissing(normMap, 'POUVOIR DE COUPURE ASSIGNE(KA)', [
        'POUVOIR DE COUPURE ASSIGNE(KA)',
        'Pouvoir de coupure assigné',
        'pouvoirCoupure',
        'Pouvoir de coupure',
        'Pouvoir de coupure assigné (kA)',
      ]);
      _mapFieldIfMissing(normMap, 'SECTION DU CABLE(mm2)', [
        'SECTION DU CABLE(mm2)',
        'SECTION DU CABLE (mm²)',
        'Section Du Cable',
        'sectionCables',
        'Section des cables',
        'Section cable',
      ]);
      _mapFieldIfMissing(normMap, 'NATURE DU RESEAU', [
        'NATURE DU RESEAU',
        'Nature Du Reseau',
        'natureReseau',
        'Nature reseau',
      ]);
    } else if (sectionKey == 'BT') {
      _mapFieldIfMissing(normMap, 'PUISSANCE TRANSFORMATEUR (KVA)', [
        'PUISSANCE TRANSFORMATEUR (KVA)',
        'Puissance Transformateur',
        'puissanceAssignee',
        'Puissance',
        'Puissance (kVA)',
      ]);
      _mapFieldIfMissing(normMap, 'TYPE DE TRANSFORMATEUR', [
        'TYPE DE TRANSFORMATEUR',
        'Type de transformateur',
        'typeTransformateur',
        'Type transfo',
        'Type',
      ]);
      _mapFieldIfMissing(normMap, 'INTENSITE NOMINALE', [
        'INTENSITE NOMINALE',
        'Intensité nominale',
        'intensiteNominale',
        'Intensite nominale',
        'Intensite',
      ]);
      _mapFieldIfMissing(normMap, 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', [
        'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR',
        'Calibre Du Disjoncteur Sortie Transformateur',
        'calibreDisjoncteur',
        'Calibre disjoncteur',
        'Calibre',
      ]);
      _mapFieldIfMissing(normMap, 'SECTION DU CABLE', [
        'SECTION DU CABLE',
        'Section Du Cable',
        'sectionCables',
        'Section des cables',
        'Section cable',
      ]);
      _mapFieldIfMissing(normMap, 'TENSION MT/BT', [
        'TENSION MT/BT',
        'Tension',
        'tensionPrimaireSecondaire',
        'Tension primaire / secondaire',
      ]);
      _mapFieldIfMissing(normMap, 'COUPLAGE', [
        'COUPLAGE',
        'Couplage',
        'couplage',
      ]);
      _mapFieldIfMissing(normMap, 'TYPE DE RESEAU', [
        'TYPE DE RESEAU',
        'Type de réseau',
        'typeReseau',
        'Type reseau',
      ]);
      _mapFieldIfMissing(normMap, 'PCC AMONT EN MVA', [
        'PCC AMONT EN MVA',
        'PCC amont',
        'pccAmont',
        'PCC amont (MVA)',
      ]);
      _mapFieldIfMissing(normMap, 'UCC EN %', [
        'UCC EN %',
        'Puissance UCC',
        'puissanceUcc',
        'UCC (%)',
      ]);
      _mapFieldIfMissing(normMap, 'IK3 MAX(KA)', [
        'IK3 MAX(KA)',
        'IK3 MAX',
        'ik3Max',
        'IK3 MAX (kA)',
      ]);
    }

    final rawId = item.data['auditCelluleId'] ??
        item.data['auditTransformateurId'] ??
        'row_${rowIndex}_${DateTime.now().microsecondsSinceEpoch}';

    return InstallationDescriptionPdfRow(
      index: rowIndex,
      rawId: rawId,
      normalizedFields: normMap,
    );
  }

  static void _mapFieldIfMissing(
      Map<String, String> map, String targetHeader, List<String> candidateKeys) {
    if (map.containsKey(targetHeader) && map[targetHeader]!.trim().isNotEmpty) return;

    for (final cand in candidateKeys) {
      if (map.containsKey(cand) && map[cand]!.trim().isNotEmpty) {
        map[targetHeader] = map[cand]!.trim();
        return;
      }
      final candNorm = InstallationFieldsRegistry.normalizeKey(cand);
      if (map.containsKey(candNorm) && map[candNorm]!.trim().isNotEmpty) {
        map[targetHeader] = map[candNorm]!.trim();
        return;
      }
    }
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
