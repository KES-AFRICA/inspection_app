import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/utils/normative_reference_cleaner.dart';

class PdfLocationInfo {
  final String zoneName;
  final String repereName;
  final String equipmentName;

  const PdfLocationInfo({
    required this.zoneName,
    required this.repereName,
    required this.equipmentName,
  });
}



class PdfObsRecap {
  final String zoneName;
  final String localName;
  final String coffret;
  final String observation;
  final String refNorm;
  final String priorite;
  final String? repere;

  PdfObsRecap({
    String zoneName = '',
    String localName = '',
    String localisation = '',
    required this.coffret,
    required this.observation,
    required String refNorm,
    required this.priorite,
    this.repere,
  })  : zoneName = zoneName.trim().isNotEmpty
            ? zoneName.trim()
            : (localisation.contains('/')
                ? localisation.split('/')[0].trim()
                : ''),
        localName = localName.trim().isNotEmpty
            ? localName.trim()
            : (localisation.contains('/')
                ? localisation.split('/').sublist(1).join('/').trim()
                : (zoneName.trim().isEmpty ? localisation.trim() : '')),
        refNorm = NormativeReferenceCleaner.clean(refNorm).replaceAll(RegExp(r'§\s*'), 'art ');

  String get localisation => zoneName.isNotEmpty && localName.isNotEmpty
      ? '$zoneName / $localName'
      : (zoneName.isNotEmpty ? zoneName : localName);
}

class PdfObsEquipGroup {
  final String coffret;
  final List<PdfObsRecap> items;
  PdfObsEquipGroup({required this.coffret, required this.items});
}

class PdfObsLocalGroup {
  final String localName;
  final List<PdfObsEquipGroup> equipGroups;
  PdfObsLocalGroup({required this.localName, required this.equipGroups});
}

class PdfObsZoneGroup {
  final String zoneName;
  final List<PdfObsLocalGroup> localGroups;
  PdfObsZoneGroup({required this.zoneName, required this.localGroups});
}

class PdfObsGroup {
  final String local;
  final List<PdfObsRecap> items;
  PdfObsGroup({required this.local, required this.items});
}



/// Builder responsable de la Liste Récapitulative des Observations (MT, BT, groupement par zone/local/équipement)
class PdfObservationsRecapBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsSmall = PdfReportStyles.fsSmall;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsH3 = PdfReportStyles.fsH3;

  static pw.Widget _subSectionBar(String title) => PdfReportStyles.subTitle(title);

  // Internal delegates for backward compatibility
  static PdfLocationInfo _resolveLocation(
    AuditInstallationsElectriques? audit, {
    String? localisationStr,
    String? coffretStr,
  }) => resolveLocation(audit, localisationStr: localisationStr, coffretStr: coffretStr);

  static List<pw.Widget> _buildListeRecapitulativeMulti(
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages,
  ) => buildListeRecapitulativeMulti(audit, trackedPages);

  static List<pw.Widget> _buildObsRecapTableMT(List<PdfObsRecap> obs) => buildObsRecapTableMT(obs);
  static List<pw.Widget> _buildObsRecapTableBT(List<PdfObsRecap> obs) => buildObsRecapTableBT(obs);
  static List<pw.Widget> _buildObsRecapTableBTFromGroups(
    List<PdfObsGroup> groups,
  ) => buildObsRecapTableBTFromGroups(groups);
  static List<PdfObsZoneGroup> _groupByZoneLocalEquip(List<PdfObsRecap> obs) => groupByZoneLocalEquip(obs);
  static List<pw.Widget> _buildObsRecapTableUnifie(List<PdfObsRecap> obs) => buildObsRecapTableUnifie(obs);
  static List<PdfObsGroup> _groupByLocal(List<PdfObsRecap> obs) => groupByLocal(obs);
  static List<PdfObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) => collectObservationsMT(audit);
  static List<PdfObsRecap> _collectObservationsBT(AuditInstallationsElectriques audit) => collectObservationsBT(audit);

  static PdfLocationInfo resolveLocation(
    AuditInstallationsElectriques? audit, {
    String? localisationStr,
    String? coffretStr,
  }) {
    String zoneName = '';
    String repereName = '';
    String equipmentName = coffretStr?.trim() ?? '';

    final locClean = localisationStr?.trim() ?? '';
    final coffretClean = coffretStr?.trim() ?? '';

    if (audit != null) {
      if (coffretClean.isNotEmpty) {
        for (final z in audit.basseTensionZones) {
          final zName = z.nom.trim();
          for (final c in z.coffretsDirects) {
            if (PdfEquipementsSynthesisBuilder.matchEquip(c, coffretClean)) {
              return PdfLocationInfo(
                zoneName: zName,
                repereName: '',
                equipmentName: c.nom.isNotEmpty ? c.nom : coffretClean,
              );
            }
          }
          for (final l in z.locaux) {
            final lName = l.nom.trim();
            for (final c in l.coffrets) {
              if (PdfEquipementsSynthesisBuilder.matchEquip(c, coffretClean)) {
                return PdfLocationInfo(
                  zoneName: zName,
                  repereName: lName,
                  equipmentName: c.nom.isNotEmpty ? c.nom : coffretClean,
                );
              }
            }
          }
        }
        for (final z in audit.moyenneTensionZones) {
          final zName = z.nom.trim();
          for (final c in z.coffrets) {
            if (PdfEquipementsSynthesisBuilder.matchEquip(c, coffretClean)) {
              return PdfLocationInfo(
                zoneName: zName,
                repereName: '',
                equipmentName: c.nom.isNotEmpty ? c.nom : coffretClean,
              );
            }
          }
          for (final l in z.locaux) {
            final lName = l.nom.trim();
            for (final c in l.coffrets) {
              if (PdfEquipementsSynthesisBuilder.matchEquip(c, coffretClean)) {
                return PdfLocationInfo(
                  zoneName: zName,
                  repereName: lName,
                  equipmentName: c.nom.isNotEmpty ? c.nom : coffretClean,
                );
              }
            }
          }
        }
        for (final l in audit.moyenneTensionLocaux) {
          final lName = l.nom.trim();
          for (final c in l.coffrets) {
            if (PdfEquipementsSynthesisBuilder.matchEquip(c, coffretClean)) {
              return PdfLocationInfo(
                zoneName: '',
                repereName: lName,
                equipmentName: c.nom.isNotEmpty ? c.nom : coffretClean,
              );
            }
          }
        }
      }

      if (locClean.isNotEmpty) {
        for (final z in audit.basseTensionZones) {
          final zName = z.nom.trim();
          for (final l in z.locaux) {
            final lName = l.nom.trim();
            if (PdfEquipementsSynthesisBuilder.matchName(lName, locClean)) {
              return PdfLocationInfo(
                zoneName: zName,
                repereName: lName,
                equipmentName: equipmentName,
              );
            }
          }
          if (PdfEquipementsSynthesisBuilder.matchName(zName, locClean)) {
            return PdfLocationInfo(
              zoneName: zName,
              repereName: '',
              equipmentName: equipmentName,
            );
          }
        }
        for (final z in audit.moyenneTensionZones) {
          final zName = z.nom.trim();
          for (final l in z.locaux) {
            final lName = l.nom.trim();
            if (PdfEquipementsSynthesisBuilder.matchName(lName, locClean)) {
              return PdfLocationInfo(
                zoneName: zName,
                repereName: lName,
                equipmentName: equipmentName,
              );
            }
          }
          if (PdfEquipementsSynthesisBuilder.matchName(zName, locClean)) {
            return PdfLocationInfo(
              zoneName: zName,
              repereName: '',
              equipmentName: equipmentName,
            );
          }
        }
        for (final l in audit.moyenneTensionLocaux) {
          final lName = l.nom.trim();
          if (PdfEquipementsSynthesisBuilder.matchName(lName, locClean)) {
            return PdfLocationInfo(
              zoneName: '',
              repereName: lName,
              equipmentName: equipmentName,
            );
          }
        }
      }
    }

    if (locClean.isNotEmpty) {
      if (locClean.toLowerCase().startsWith('zone ') || locClean.toLowerCase().startsWith('zone_')) {
        zoneName = locClean;
        repereName = '';
      } else {
        zoneName = '';
        repereName = locClean;
      }
    }

    return PdfLocationInfo(
      zoneName: zoneName,
      repereName: repereName,
      equipmentName: equipmentName,
    );
  }



  static List<pw.Widget> buildListeRecapitulativeMulti(
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages,
  ) {
    final widgets = <pw.Widget>[];

    widgets.add(
      PageTracker(
        key: 'liste_recap_mt',
        registry: trackedPages,
        child: _subSectionBar('1. Moyenne tension'),
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    final obsMT = _collectObservationsMT(audit);
    widgets.addAll(_buildObsRecapTableMT(obsMT));

    widgets.add(pw.NewPage());

    widgets.add(
      PageTracker(
        key: 'liste_recap_bt',
        registry: trackedPages,
        child: _subSectionBar('2. Basse tension'),
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    final obsBT = _collectObservationsBT(audit);
    widgets.addAll(_buildObsRecapTableBT(obsBT));

    return widgets;
  }

  static List<pw.Widget> buildObsRecapTableMT(List<PdfObsRecap> obs) {
    return _buildObsRecapTableUnifie(obs);
  }

  static List<pw.Widget> buildObsRecapTableBT(List<PdfObsRecap> obs) {
    return _buildObsRecapTableUnifie(obs);
  }

  static List<pw.Widget> buildObsRecapTableBTFromGroups(
    List<PdfObsGroup> groups,
  ) {
    final flatObs = groups.expand((g) => g.items).toList();
    return _buildObsRecapTableUnifie(flatObs);
  }

  static List<PdfObsZoneGroup> groupByZoneLocalEquip(List<PdfObsRecap> obs) {
    final zoneGroups = <PdfObsZoneGroup>[];

    for (final o in obs) {
      final zName = o.zoneName.trim();
      final lName = o.localName.trim();
      final cName = o.coffret.trim();

      var zGroup = zoneGroups.firstWhere(
        (zg) => zg.zoneName.toLowerCase() == zName.toLowerCase(),
        orElse: () {
          final zg = PdfObsZoneGroup(zoneName: zName, localGroups: []);
          zoneGroups.add(zg);
          return zg;
        },
      );

      var lGroup = zGroup.localGroups.firstWhere(
        (lg) => lg.localName.toLowerCase() == lName.toLowerCase(),
        orElse: () {
          final lg = PdfObsLocalGroup(localName: lName, equipGroups: []);
          zGroup.localGroups.add(lg);
          return lg;
        },
      );

      var eGroup = lGroup.equipGroups.firstWhere(
        (eg) => eg.coffret.toLowerCase() == cName.toLowerCase(),
        orElse: () {
          final eg = PdfObsEquipGroup(coffret: cName, items: []);
          lGroup.equipGroups.add(eg);
          return eg;
        },
      );

      eGroup.items.add(o);
    }

    return zoneGroups;
  }

  static List<pw.Widget> buildObsRecapTableUnifie(List<PdfObsRecap> obs) {
    if (obs.isEmpty) {
      return [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromHex('#475569'),
              width: 0.5,
            ),
          ),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            'Aucune observation',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: fsSmall,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    final zoneGroups = _groupByZoneLocalEquip(obs);
    final widgets = <pw.Widget>[];

    final subTableColumnWidths = const {
      0: pw.FlexColumnWidth(0.8), // N°
      1: pw.FlexColumnWidth(6.7), // Non-conformité - Préconisation
      2: pw.FlexColumnWidth(2.5), // Référence Normative
    };

    for (int zIdx = 0; zIdx < zoneGroups.length; zIdx++) {
      final zoneGroup = zoneGroups[zIdx];
      final rawZoneName = zoneGroup.zoneName.trim();
      final zoneText = rawZoneName.isNotEmpty ? rawZoneName.toUpperCase() : '-';

      // Espacement entre deux Zones distinctes
      if (widgets.isNotEmpty) {
        widgets.add(pw.SizedBox(height: 20));
      }

      // 3. RÈGLE : Le bloc ZONE est TOUJOURS présent, avec le texte "ZONE: XX", en majuscule et bien centré. Si pas de zone -> "ZONE: -"
      widgets.add(
        pw.Container(
          width: double.infinity,
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1E3A8A), // Dark Navy
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'ZONE: $zoneText',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9.0,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

      // 5. RÈGLE : Réduit l'espace qui sépare le bloc Zone du bloc Repère.
      widgets.add(pw.SizedBox(height: 2.5));

      for (int lIdx = 0; lIdx < zoneGroup.localGroups.length; lIdx++) {
        final localGroup = zoneGroup.localGroups[lIdx];
        final rawLocalName = localGroup.localName.trim();

        // 2. RÈGLE : Augmente l'espace entre deux repères.
        if (lIdx > 0) {
          widgets.add(pw.SizedBox(height: 16));
        }

        // 4. RÈGLE : Si zone sans repère -> dans le repère on met encore le nom de la zone. Texte centré.
        final String repereText = rawLocalName.isNotEmpty
            ? rawLocalName.toUpperCase()
            : (rawZoneName.isNotEmpty ? rawZoneName.toUpperCase() : '-');

        widgets.add(
          pw.Container(
            width: double.infinity,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF334155), // Slate Navy
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'REPÈRE: $repereText',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));

        for (int eIdx = 0; eIdx < localGroup.equipGroups.length; eIdx++) {
          final equipGroup = localGroup.equipGroups[eIdx];

          // 1. RÈGLE : Réduis l'espace entre les équipements d'un même repère.
          if (eIdx > 0) {
            widgets.add(pw.SizedBox(height: 3.5));
          }

          final equipName = equipGroup.coffret.isNotEmpty
              ? equipGroup.coffret
              : 'ÉQUIPEMENT SANS NOM';
          final obsCountStr = '${equipGroup.items.length} observation(s)';

          // Subtable indissociable par équipement
          final rows = <pw.TableRow>[];

          // LIGNE 0 : BANDEAU D'ÉQUIPEMENT (Fond Soft Blue #DBEAFE, Texte Gras Navy)
          rows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFDBEAFE),
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.SizedBox(),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'DÉSIGNATION : $equipName',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: PdfColor.fromInt(0xFF1E3A8A),
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    obsCountStr,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
                      color: PdfColor.fromInt(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          );

          // LIGNE 1 : EN-TÊTE DES COLONNES DU SOUS-TABLEAU (Fond Medium Blue #2E5F9A, Texte Blanc)
          rows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF2E5F9A),
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'N°',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Non-conformités & Préconisations',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Réf. Normative',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.left,
                  ),
                ),
              ],
            ),
          );

          // LIGNES 2..N : LIGNES D'OBSERVATIONS (Niveau 1 : Espacement compact)
          for (int itemIdx = 0; itemIdx < equipGroup.items.length; itemIdx++) {
            final o = equipGroup.items[itemIdx];
            final isEven = itemIdx % 2 == 0;
            final rowBg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC);
            final isLastObs = (itemIdx == equipGroup.items.length - 1);

            final obsBorder = pw.Border(
              bottom: isLastObs
                  ? pw.BorderSide.none
                  : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4),
            );

            rows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(color: rowBg),
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(border: obsBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '${itemIdx + 1}',
                      style: pw.TextStyle(font: fontBold, fontSize: fsSmall, color: PdfReportStyles.headerColor),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(border: obsBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      o.observation,
                      style: pw.TextStyle(font: fontRegular, fontSize: fsSmall),
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(border: obsBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      o.refNorm.isNotEmpty ? o.refNorm : '-',
                      style: pw.TextStyle(font: fontRegular, fontSize: fsSmall),
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                ],
              ),
            );
          }

          widgets.add(
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0),
                right: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0),
                top: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0),
                horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
                verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
              ),
              columnWidths: subTableColumnWidths,
              children: rows,
            ),
          );
        }
      }
    }

    return widgets;
  }

  static pw.Widget _obsHeaderCellMT(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: fsSmall,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static List<PdfObsGroup> groupByLocal(List<PdfObsRecap> obs) {
    final groups = <PdfObsGroup>[];
    for (final o in obs) {
      if (groups.isEmpty || groups.last.local != o.localisation) {
        groups.add(PdfObsGroup(local: o.localisation, items: [o]));
      } else {
        groups.last.items.add(o);
      }
    }
    return groups;
  }

  // ──────────────────────────────────────────────────────────────
  //  COLLECTE DES OBSERVATIONS
  // ──────────────────────────────────────────────────────────────

  static String _getNormativeReferenceForFreeObs(ObservationLibre obs) {
    if (obs.referenceNormative != null && obs.referenceNormative!.trim().isNotEmpty) {
      return obs.referenceNormative!.trim();
    }
    if (obs.pointVerificationKey != null && obs.pointVerificationKey!.trim().isNotEmpty) {
      final key = obs.pointVerificationKey!.trim();
      final item = DispositionsConstructivesRegistry.getMetadata(key) ??
          DispositionsConstructivesRegistry.getCoffretMetadata(key);
      if (item != null && item.referenceNormative.isNotEmpty) {
        return item.referenceNormative;
      }
    }
    return '';
  }

  static String _getCriticiteForFreeObs(ObservationLibre obs) {
    if (obs.criticite != null && obs.criticite!.trim().isNotEmpty) {
      return obs.criticite!.trim();
    }
    if (obs.pointVerificationKey != null && obs.pointVerificationKey!.trim().isNotEmpty) {
      final key = obs.pointVerificationKey!.trim();
      final item = DispositionsConstructivesRegistry.getMetadata(key) ??
          DispositionsConstructivesRegistry.getCoffretMetadata(key);
      if (item != null && item.criticite.isNotEmpty) {
        return item.criticite;
      }
    }
    return '';
  }

  static void _addCoffretObservations(
    List<PdfObsRecap> list,
    CoffretArmoire coffret,
    String localisation,
  ) {
    final coffretRepere = coffret.repere?.isNotEmpty == true
        ? coffret.repere
        : coffret.numeroEquipement;
    for (var pv in coffret.pointsVerification) {
      final conf = pv.conformite.toLowerCase().trim();
      if (conf == 'non' || conf == 'non conforme') {
        if (pv.observations != null && pv.observations!.isNotEmpty) {
          for (var obs in pv.observations!) {
            list.add(
              PdfObsRecap(
                localisation: localisation,
                coffret: coffret.nom,
                observation: obs.observation?.isNotEmpty == true
                    ? obs.observation!
                    : pv.pointVerification,
                refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                priorite: obs.priorite?.toString() ?? '',
                repere: coffretRepere,
              ),
            );
          }
        } else {
          list.add(
            PdfObsRecap(
              localisation: localisation,
              coffret: coffret.nom,
              observation: pv.observation ?? pv.pointVerification,
              refNorm: pv.referenceNormative ?? '',
              priorite: pv.priorite?.toString() ?? '',
              repere: coffretRepere,
            ),
          );
        }
      }
    }
    for (var obs in coffret.observationsLibres) {
      list.add(
        PdfObsRecap(
          localisation: localisation,
          coffret: coffret.nom,
          observation: obs.texte,
          refNorm: _getNormativeReferenceForFreeObs(obs),
          priorite: _getCriticiteForFreeObs(obs),
          repere: coffretRepere,
        ),
      );
    }
  }

  static List<PdfObsRecap> collectObservationsMT(
    AuditInstallationsElectriques audit,
  ) {
    final list = <PdfObsRecap>[];

    // 1. Moyenne tension locaux
    for (var local in audit.moyenneTensionLocaux) {
      for (var el in local.dispositionsConstructives) {
        if (el.conforme == false) {
          list.add(
            PdfObsRecap(
              localisation: local.nom,
              coffret: 'Dispositions constructives',
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.priorite?.toString() ?? '',
            ),
          );
        }
      }
      for (var el in local.conditionsExploitation) {
        if (el.conforme == false) {
          list.add(
            PdfObsRecap(
              localisation: local.nom,
              coffret: 'Conditions d\'exploitation',
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.priorite?.toString() ?? '',
            ),
          );
        }
      }
      // Cellules (MT)
      for (var i = 0; i < local.cellules.length; i++) {
        final cellule = local.cellules[i];
        final label = 'Cellule ${i + 1} — ${cellule.fonction}';
        for (var el in cellule.elementsVerifies) {
          if (el.conforme == false || el.estNA) {
            final obsStr = (el.observation != null && el.observation!.trim().isNotEmpty)
                ? el.observation!.trim()
                : ((el.elementControle.trim().isNotEmpty && !el.elementControle.trim().toLowerCase().startsWith('observation '))
                    ? el.elementControle.trim()
                    : '');
            list.add(
              PdfObsRecap(
                localisation: local.nom,
                coffret: label,
                observation: obsStr,
                refNorm: el.referenceNormative ?? '',
                priorite: el.conforme == false
                    ? (el.priorite?.toString() ?? '')
                    : 'NA',
              ),
            );
          }
        }
      }
      // Transformateurs (MT)
      for (var i = 0; i < local.transformateurs.length; i++) {
        final transfo = local.transformateurs[i];
        final label = 'Transformateur ${i + 1}';
        for (var el in transfo.elementsVerifies) {
          if (el.conforme == false || el.estNA) {
            final obsStr = (el.observation != null && el.observation!.trim().isNotEmpty)
                ? el.observation!.trim()
                : ((el.elementControle.trim().isNotEmpty && !el.elementControle.trim().toLowerCase().startsWith('observation '))
                    ? el.elementControle.trim()
                    : '');
            list.add(
              PdfObsRecap(
                localisation: local.nom,
                coffret: label,
                observation: obsStr,
                refNorm: el.referenceNormative ?? '',
                priorite: el.conforme == false
                    ? (el.priorite?.toString() ?? '')
                    : 'NA',
              ),
            );
          }
        }
      }
      // Coffrets MT uniquement (Cellule / Transformateur)
      for (var coffret in local.coffrets) {
        if (PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, local.nom);
        }
      }
      for (var obs in local.observationsLibres) {
        list.add(
          PdfObsRecap(
            localisation: local.nom,
            coffret: '',
            observation: obs.texte,
            refNorm: _getNormativeReferenceForFreeObs(obs),
            priorite: _getCriticiteForFreeObs(obs),
          ),
        );
      }
    }

    // 2. Moyenne tension zones
    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        if (PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, zone.nom);
        }
      }
      for (var local in zone.locaux) {
        for (var el in local.dispositionsConstructives) {
          if (el.conforme == false) {
            list.add(
              PdfObsRecap(
                localisation: '${zone.nom} / ${local.nom}',
                coffret: 'Dispositions constructives',
                observation: el.observation ?? el.elementControle,
                refNorm: el.referenceNormative ?? '',
                priorite: el.priorite?.toString() ?? '',
              ),
            );
          }
        }
        for (var coffret in local.coffrets) {
          if (PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
            _addCoffretObservations(list, coffret, '${zone.nom} / ${local.nom}');
          }
        }
        for (var obs in local.observationsLibres) {
          list.add(
            PdfObsRecap(
              localisation: '${zone.nom} / ${local.nom}',
              coffret: '',
              observation: obs.texte,
              refNorm: _getNormativeReferenceForFreeObs(obs),
              priorite: _getCriticiteForFreeObs(obs),
            ),
          );
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(
          PdfObsRecap(
            localisation: zone.nom,
            coffret: '',
            observation: obs.texte,
            refNorm: _getNormativeReferenceForFreeObs(obs),
            priorite: _getCriticiteForFreeObs(obs),
          ),
        );
      }
    }

    // 3. Coffrets MT (Cellule/Transformateur) situés dans les zones/locaux Basse Tension
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        if (PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, zone.nom);
        }
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
            _addCoffretObservations(list, coffret, '${zone.nom} / ${local.nom}');
          }
        }
      }
    }

    return list;
  }

  static List<PdfObsRecap> collectObservationsBT(
    AuditInstallationsElectriques audit,
  ) {
    final list = <PdfObsRecap>[];

    // 1. Basse tension zones & locaux
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        if (!PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, zone.nom);
        }
      }

      for (var local in zone.locaux) {
        if (local.dispositionsConstructives != null) {
          for (var el in local.dispositionsConstructives!) {
            if (el.conforme == false || el.estNA) {
              list.add(
                PdfObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: 'Dispositions constructives',
                  observation: el.observation ?? el.elementControle,
                  refNorm: el.referenceNormative ?? '',
                  priorite: el.conforme == false
                      ? (el.priorite?.toString() ?? '')
                      : 'NA',
                ),
              );
            }
          }
        }
        if (local.conditionsExploitation != null) {
          for (var el in local.conditionsExploitation!) {
            if (el.conforme == false) {
              list.add(
                PdfObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: 'Conditions d\'exploitation',
                  observation: el.observation ?? el.elementControle,
                  refNorm: el.referenceNormative ?? '',
                  priorite: el.priorite?.toString() ?? '',
                ),
              );
            }
          }
        }
        for (var coffret in local.coffrets) {
          if (!PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
            _addCoffretObservations(list, coffret, '${zone.nom} / ${local.nom}');
          }
        }
        for (var obs in local.observationsLibres) {
          list.add(
            PdfObsRecap(
              localisation: '${zone.nom} / ${local.nom}',
              coffret: '',
              observation: obs.texte,
              refNorm: _getNormativeReferenceForFreeObs(obs),
              priorite: _getCriticiteForFreeObs(obs),
            ),
          );
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(
          PdfObsRecap(
            localisation: zone.nom,
            coffret: '',
            observation: obs.texte,
            refNorm: _getNormativeReferenceForFreeObs(obs),
            priorite: _getCriticiteForFreeObs(obs),
          ),
        );
      }
    }

    // 2. Coffrets BT (TGBT, Inverseur, Armoire, Coffret) situés dans les locaux/zones Moyenne Tension
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        if (!PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, local.nom);
        }
      }
    }

    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        if (!PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
          _addCoffretObservations(list, coffret, zone.nom);
        }
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (!PdfEquipementsSynthesisBuilder.isMTEquipementCoffret(coffret)) {
            _addCoffretObservations(list, coffret, '${zone.nom} / ${local.nom}');
          }
        }
      }
    }

    return list;
  }


  static PdfObsRecap createObsRecapForTesting({
    String zoneName = '',
    String localName = '',
    String localisation = '',
    required String coffret,
    required String observation,
    required String refNorm,
    required String priorite,
    String? repere,
  }) {
    return PdfObsRecap(
      zoneName: zoneName,
      localName: localName,
      localisation: localisation,
      coffret: coffret,
      observation: observation,
      refNorm: refNorm,
      priorite: priorite,
      repere: repere,
    );
  }

  static List<PdfObsZoneGroup> groupByZoneLocalEquipForTesting(List<PdfObsRecap> obs) {
    return _groupByZoneLocalEquip(obs);
  }

  static List<pw.Widget> buildObsRecapTableUnifieForTesting(List<PdfObsRecap> obs) {
    return _buildObsRecapTableUnifie(obs);
  }


}
