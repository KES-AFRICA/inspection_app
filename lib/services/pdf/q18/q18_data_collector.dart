// lib/services/pdf/q18/q18_data_collector.dart

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/intervenants_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/canonical_risk_family_registry.dart';
import 'package:inspec_app/services/statistics/global_assessment_engine.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

/// Collecteur et préparateur certifié des données du rapport Q18 (APSAD D18).
///
/// Fonctionne en lecture seule stricte sur la base de données locale (Hive)
/// et s'alimente directement sur les moteurs statistiques canoniques de KES.
class Q18DataCollector {
  /// Collecte et produit un [Q18DataSnapshot] immuable pour une mission donnée.
  static Q18DataSnapshot collect(String missionId) {
    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      throw Exception('Mission introuvable pour l\'id: $missionId');
    }

    final renseignements = HiveService.getRenseignementsGenerauxByMissionId(missionId);
    final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
    final foudre = HiveService.getFoudreObservationsByMissionId(missionId);
    final currentUser = HiveService.getCurrentUser();

    // 1. Dates & Références officielles
    final effectiveReportDate = mission.dateRapport ?? renseignements?.dateRapport ?? DateTime.now();
    final String anneeStr = effectiveReportDate.year.toString();
    final String shortId = mission.id.length >= 4 ? mission.id.substring(0, 4).toUpperCase() : '0001';
    final String numeroRapportQ18 = 'KES/IP/Q18/$anneeStr/$shortId';
    final String numeroRapportVerifElec = 'KES/IP/VE/$anneeStr/$shortId';
    
    // Échéance périodique annuelle : 1 an après la fin de la vérification (ou date intervention)
    final dateRefVisite = renseignements?.dateFin ?? renseignements?.dateDebut ?? mission.dateIntervention ?? effectiveReportDate;
    final dateProchaineVisite = DateTime(dateRefVisite.year + 1, dateRefVisite.month, dateRefVisite.day);

    final lieuIntervention = renseignements?.lieuIntervention?.trim().isNotEmpty == true
        ? renseignements!.lieuIntervention!.trim()
        : (mission.nomSite?.trim().isNotEmpty == true ? mission.nomSite!.trim() : 'Douala');

    // 1.1 Inspecteurs JSA (SSOT)
    final intervenantsNoms = IntervenantsService.getMissionIntervenantsNoms(
      missionId,
      mission: mission,
      rg: renseignements,
      uppercase: true,
    );

    // 1.2 Résolution temporelle de la visite de vérification
    final dateFormat = DateFormat('dd/MM/yyyy');
    final String dateVisiteLabel;
    final String dateVisiteValue;
    if (renseignements?.dateDebut != null && renseignements?.dateFin != null) {
      final dDebut = renseignements!.dateDebut!;
      final dFin = renseignements.dateFin!;
      final bool isSameDay = dDebut.year == dFin.year && dDebut.month == dFin.month && dDebut.day == dFin.day;
      if (isSameDay) {
        dateVisiteLabel = 'Date de la visite de vérification';
        dateVisiteValue = 'Le ${dateFormat.format(dDebut)}';
      } else {
        dateVisiteLabel = 'Dates des visites de vérification';
        dateVisiteValue = 'Du ${dateFormat.format(dDebut)} au ${dateFormat.format(dFin)}';
      }
    } else if (mission.dateIntervention != null) {
      dateVisiteLabel = 'Date de la visite de vérification';
      dateVisiteValue = 'Le ${dateFormat.format(mission.dateIntervention!)}';
    } else {
      dateVisiteLabel = 'Date de la visite de vérification';
      dateVisiteValue = 'Le ${dateFormat.format(effectiveReportDate)}';
    }

    final clientName = mission.nomClient.trim().isNotEmpty
        ? mission.nomClient.trim()
        : (renseignements != null && renseignements.etablissement.trim().isNotEmpty
            ? renseignements.etablissement.trim()
            : 'Non renseigné');

    final siteName = mission.nomSite?.trim().isNotEmpty == true
        ? mission.nomSite!.trim()
        : (renseignements != null && renseignements.nomSite.trim().isNotEmpty
            ? renseignements.nomSite.trim()
            : (renseignements != null && renseignements.etablissement.trim().isNotEmpty
                ? renseignements.etablissement.trim()
                : 'Non renseigné'));

    final adresseSite = mission.adresseClient?.trim().isNotEmpty == true
        ? mission.adresseClient!.trim()
        : (lieuIntervention.isNotEmpty ? lieuIntervention : 'Non renseigné');

    final typeMission = mission.natureMission?.trim().isNotEmpty == true
        ? mission.natureMission!.trim()
        : (renseignements?.verificationType?.trim().isNotEmpty == true
            ? renseignements!.verificationType!.trim()
            : 'Vérification périodique');

    // 2. Inventaire des installations pour la Section 4
    final quantities = _collectQuantities(audit, description, foudre);

    // 3. Périmètre et exclusions pour la Section 5
    final perimetreData = _collectPerimetre(audit);

    // 4. Documents consultés pour la Section 6 (SSOT : docRapportQ18 ou autresDocuments)
    final bool hasQ18Precedent = mission.docRapportQ18 ||
        mission.autresDocuments.any((d) => d.toLowerCase().contains('q18'));
    final documentsConsultes = _collectDocumentsConsultes(mission, renseignements, description, hasQ18Precedent: hasQ18Precedent);


    // 5. Synthèse des dangers constatés pour la Section 10 & 11
    final inventory = MissionDomainInventoryEngine.buildInventory(missionId);
    final pertinentFindings = inventory.pertinentFindings;

    final dangers = <Q18DangerItem>[];
    final photoEntries = <PdfPhotoEntry>[];
    int countDangerAvere = 0;
    int countDegradation = 0;
    int countHorsPerimetre = 0;
    int countPointSensible = 0;

    int dangerIndex = 1;
    for (final finding in pertinentFindings) {
      final niveau = _mapFindingToQ18Level(finding);
      switch (niveau) {
        case Q18DangerLevel.dangerAvere:
          countDangerAvere++;
          break;
        case Q18DangerLevel.degradation:
          countDegradation++;
          break;
        case Q18DangerLevel.horsPerimetreApsad:
          countHorsPerimetre++;
          break;
        case Q18DangerLevel.pointSensible:
          countPointSensible++;
          break;
      }

      final canonicalRisk = CanonicalRiskFamilyRegistry.mapToCanonical(
        finding.riskFamily,
        verificationPoint: finding.verificationPoint,
      );

      final zoneName = finding.origin;
      final repName = finding.objectRepere ?? finding.objectName;
      final equipName = finding.objectName;

      dangers.add(
        Q18DangerItem(
          index: dangerIndex,
          zone: zoneName,
          repere: repName,
          designation: equipName,
          dangerConstate: finding.observationText.trim().isNotEmpty
              ? finding.observationText.trim()
              : finding.verificationPoint,
          familleDeRisque: canonicalRisk,
          niveau: niveau,
          photos: finding.photos,
        ),
      );

      // Collecte des photos associées pour la planche photographique (Section 16)
      if (finding.photos.isNotEmpty) {
        for (final photoPath in finding.photos) {
          if (photoPath.trim().isNotEmpty) {
            photoEntries.add(
              PdfPhotoEntry(
                filePath: photoPath.trim(),
                description: finding.observationText.trim().isNotEmpty
                    ? finding.observationText.trim()
                    : finding.verificationPoint,
                repere: repName,
                isObservation: true,
                badgeLabel: niveau.label,
                badgeBgColor: _getBadgeBgColor(niveau),
                badgeTextColor: _getBadgeTextColor(niveau),
              ),
            );
          }
        }
      }

      dangerIndex++;
    }

    // 6. Avis global et conclusion pour la Section 12 (aligné sur GlobalAssessmentEngine)
    final snapshot = ExecutiveSummarySnapshot.fromMission(missionId);
    final summary = MissionStatisticsCollector.collectSummary(missionId);
    final assessment = GlobalAssessmentEngine.analyze(summary: summary, snapshot: snapshot);
    final hasDangerAvere = countDangerAvere > 0;

    String appreciation;
    if (countDangerAvere == 0 && countDegradation == 0) {
      appreciation = 'Satisfaisant';
    } else if (countDangerAvere == 0) {
      appreciation = 'Acceptable';
    } else {
      appreciation = 'Insuffisant';
    }

    final avisSynthese = assessment.finalAppreciationText.trim().isNotEmpty
        ? assessment.finalAppreciationText.trim()
        : 'Les investigations effectuées mettent en évidence l\'état des installations '
            'au regard des risques d\'incendie et d\'explosion d\'origine électrique.';

    return Q18DataSnapshot(
      mission: mission,
      renseignements: renseignements,
      description: description,
      audit: audit,
      mesures: mesures,
      foudre: foudre,
      currentUser: currentUser,
      numeroRapportQ18: numeroRapportQ18,
      numeroRapportVerifElec: numeroRapportVerifElec,
      dateRapportEffective: effectiveReportDate,
      dateProchaineVisite: dateProchaineVisite,
      lieuIntervention: lieuIntervention,
      intervenantsNoms: intervenantsNoms,
      dateVisiteLabel: dateVisiteLabel,
      dateVisiteValue: dateVisiteValue,
      clientName: clientName,
      siteName: siteName,
      adresseSite: adresseSite,
      typeMission: typeMission,
      quantities: quantities,
      perimetreCouverts: perimetreData.couverts,
      exclusionsPerimetre: perimetreData.exclusions,
      documentsConsultes: documentsConsultes,
      dangers: dangers,
      countDangerAvere: countDangerAvere,
      countDegradation: countDegradation,
      countHorsPerimetre: countHorsPerimetre,
      countPointSensible: countPointSensible,
      hasDangerAvere: hasDangerAvere,
      hasQ18Precedent: hasQ18Precedent,
      appreciationGlobale: appreciation,
      avisSyntheseText: avisSynthese,
      photoEntries: photoEntries,
    );

  }

  /// Détermine le niveau APSAD D18 d'un constat d'audit.
  static Q18DangerLevel _mapFindingToQ18Level(AuditFinding finding) {
    final crit = finding.criticality.trim().toLowerCase();
    final risk = (finding.riskFamily ?? '').trim().toLowerCase();
    final point = finding.verificationPoint.trim().toLowerCase();
    final text = finding.observationText.trim().toLowerCase();
    final combined = '$risk $point $text';

    // Règle 1 : Si la criticité est formellement 'Critique', c'est un Danger avéré
    if (crit == 'critique') {
      return Q18DangerLevel.dangerAvere;
    }

    // Règle 2 : Détection des anomalies présentant un risque direct d'incendie ou d'explosion
    if (combined.contains('échauffement') ||
        combined.contains('point chaud') ||
        combined.contains('surcharge') ||
        combined.contains('incendie') ||
        combined.contains('explosion') ||
        combined.contains('conducteur nu') ||
        combined.contains('dénudé') ||
        combined.contains('court-circuit')) {
      return crit == 'mineure' ? Q18DangerLevel.degradation : Q18DangerLevel.dangerAvere;
    }

    // Règle 3 : Les anomalies 'Majeure' correspondent à une Dégradation
    if (crit == 'majeure') {
      return Q18DangerLevel.degradation;
    }

    // Règle 4 : Les anomalies purement documentaires ou d'affichage réglementaire
    if (combined.contains('registre') ||
        combined.contains('schéma') ||
        combined.contains('affichage') ||
        combined.contains('consigne') ||
        combined.contains('voyant')) {
      return Q18DangerLevel.horsPerimetreApsad;
    }

    // Règle 5 : Par défaut pour les observations mineures
    return Q18DangerLevel.pointSensible;
  }

  static PdfColor _getBadgeBgColor(Q18DangerLevel level) {
    switch (level) {
      case Q18DangerLevel.dangerAvere:
        return PdfColor.fromInt(0xFFC62828); // Rouge foncé
      case Q18DangerLevel.degradation:
        return PdfColor.fromInt(0xFFEF6C00); // Orange foncé
      case Q18DangerLevel.horsPerimetreApsad:
        return PdfColor.fromInt(0xFF1565C0); // Bleu institutionnel
      case Q18DangerLevel.pointSensible:
        return PdfColor.fromInt(0xFF2E7D32); // Vert sombre
    }
  }

  static PdfColor _getBadgeTextColor(Q18DangerLevel level) {
    return PdfColors.white;
  }

  /// Collecte les quantités réelles des installations pour la Section 4.
  static Q18InstallationsQuantities _collectQuantities(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? desc,
    List<Foudre>? foudre,
  ) {
    int nbLocauxHTA = 0;
    int nbTransfos = 0;
    final transfosPuissances = <String>[];
    int nbCellules = 0;
    int nbLocauxGE = 0;
    int nbLocauxBT = 0;
    int nbTGBT = 0;
    int nbArmoires = 0;
    int nbCoffrets = 0;
    int nbInverseurs = 0;

    int paraInverseurPresent = 0;
    int paraInverseurTotal = 0;
    int paraTGBTPresent = 0;
    int paraTGBTTotal = 0;
    int paraArmoirePresent = 0;
    int paraArmoireTotal = 0;
    int paraCoffretPresent = 0;
    int paraCoffretTotal = 0;

    if (audit != null) {
      // 1. Locaux HTA directs
      nbLocauxHTA += audit.moyenneTensionLocaux.length;
      for (final l in audit.moyenneTensionLocaux) {
        nbCellules += l.cellules.length;
        nbTransfos += l.transformateurs.length;
        for (final t in l.transformateurs) {
          if (t.puissanceAssignee.trim().isNotEmpty && t.puissanceAssignee.trim() != '-') {
            transfosPuissances.add(t.puissanceAssignee.trim());
          }
        }
      }

      // 2. Moyenne tension zones
      for (final z in audit.moyenneTensionZones) {
        nbLocauxHTA += z.locaux.length;
        for (final l in z.locaux) {
          nbCellules += l.cellules.length;
          nbTransfos += l.transformateurs.length;
          for (final t in l.transformateurs) {
            if (t.puissanceAssignee.trim().isNotEmpty && t.puissanceAssignee.trim() != '-') {
              transfosPuissances.add(t.puissanceAssignee.trim());
            }
          }
        }
      }

      // 3. Basse tension zones
      void inspectCoffret(CoffretArmoire c) {
        final t = c.type.trim().toUpperCase();
        final hasPara = c.presenceParafoudre;

        if (t == 'INVERSEUR') {
          nbInverseurs++;
          paraInverseurTotal++;
          if (hasPara) paraInverseurPresent++;
        } else if (t == 'TGBT') {
          nbTGBT++;
          paraTGBTTotal++;
          if (hasPara) paraTGBTPresent++;
        } else if (t == 'ARMOIRE') {
          nbArmoires++;
          paraArmoireTotal++;
          if (hasPara) paraArmoirePresent++;
        } else {
          nbCoffrets++;
          paraCoffretTotal++;
          if (hasPara) paraCoffretPresent++;
        }
      }

      for (final z in audit.basseTensionZones) {
        for (final c in z.coffretsDirects) {
          inspectCoffret(c);
        }
        for (final l in z.locaux) {
          final lType = l.type.trim().toUpperCase();
          if (lType == 'LOCAL_GE' || lType == 'LOCAL_GROUPE_ELECTROGENE') {
            nbLocauxGE++;
          } else {
            nbLocauxBT++;
          }
          for (final c in l.coffrets) {
            inspectCoffret(c);
          }
        }
      }

      // Coffrets BT dans locaux MT
      for (final l in audit.moyenneTensionLocaux) {
        for (final c in l.coffrets) {
          inspectCoffret(c);
        }
      }
      for (final z in audit.moyenneTensionZones) {
        for (final c in z.coffrets) {
          inspectCoffret(c);
        }
        for (final l in z.locaux) {
          for (final c in l.coffrets) {
            inspectCoffret(c);
          }
        }
      }
    }

    // Données GE depuis la description
    int nbGE = 0;
    final gePuissances = <String>[];
    if (desc != null && desc.groupeElectrogene.isNotEmpty) {
      nbGE = desc.groupeElectrogene.length;
      for (final item in desc.groupeElectrogene) {
        final puissance = item.data['PUISSANCE(KVA)'] ??
            item.data['Puissance (kVA)'] ??
            item.data['PUISSANCE'] ??
            item.data['Puissance'] ??
            item.data.entries
                .firstWhere(
                  (e) => e.key.toLowerCase().contains('puissance'),
                  orElse: () => const MapEntry('', ''),
                )
                .value;
        if (puissance.trim().isNotEmpty && puissance.trim() != '-') {
          gePuissances.add(puissance.trim());
        }
      }
    }

    // Paratonnerre
    bool hasParatonnerre = false;
    if (desc?.presenceParatonnerre?.toLowerCase() == 'oui' ||
        desc?.presenceParatonnerre?.toLowerCase() == 'présent') {
      hasParatonnerre = true;
    } else if (foudre != null && foudre.isNotEmpty) {
      for (final f in foudre) {
        if (f.observation.toLowerCase().contains('paratonnerre')) {
          hasParatonnerre = true;
          break;
        }
      }
    }

    String formatParaRatio(int present, int total) {
      if (total == 0) return 'Sans objet (0)';
      if (present == total) return 'Présent ($present/$total)';
      if (present == 0) return 'Absent (0/$total)';
      return 'Partiel ($present/$total)';
    }

    final transfoPuissStr = transfosPuissances.isNotEmpty
        ? transfosPuissances.toSet().join(', ')
        : (nbTransfos > 0 ? 'Non spécifiée' : 'N/A');

    final gePuissStr = gePuissances.isNotEmpty
        ? gePuissances.toSet().join(', ')
        : (nbGE > 0 ? 'Non spécifiée' : 'N/A');

    return Q18InstallationsQuantities(
      nbLocauxTechniquesHTA: nbLocauxHTA,
      nbTransformateurs: nbTransfos,
      transformateursPuissanceText: transfoPuissStr,
      nbCellules: nbCellules,
      nbLocauxGE: nbLocauxGE,
      nbGroupesElectrogenes: nbGE,
      groupesPuissanceText: gePuissStr,
      nbInverseurs: nbInverseurs,
      nbLocauxTechniquesBT: nbLocauxBT,
      nbTGBT: nbTGBT,
      nbArmoires: nbArmoires,
      nbCoffrets: nbCoffrets,
      presenceParatonnerre: hasParatonnerre,
      presenceParafoudreInverseur: formatParaRatio(paraInverseurPresent, paraInverseurTotal),
      presenceParafoudreTGBT: formatParaRatio(paraTGBTPresent, paraTGBTTotal),
      presenceParafoudreArmoire: formatParaRatio(paraArmoirePresent, paraArmoireTotal),
      presenceParafoudreCoffret: formatParaRatio(paraCoffretPresent, paraCoffretTotal),
      presenceCentralePhotovoltaique: 'Non renseigné',
    );
  }

  /// Collecte le périmètre d'audit et les exclusions (Section 5).
  static ({List<Q18PerimetreItem> couverts, List<Q18PerimetreItem> exclusions}) _collectPerimetre(
    AuditInstallationsElectriques? audit,
  ) {
    final couverts = <Q18PerimetreItem>[];
    final exclusions = <Q18PerimetreItem>[];

    if (audit != null) {
      // 1. Moyenne tension locaux
      for (final l in audit.moyenneTensionLocaux) {
        final eqList = <String>[];
        for (final c in l.cellules) {
          final cName = (c.nom != null && c.nom!.trim().isNotEmpty)
              ? c.nom!.trim()
              : (c.fonction.trim().isNotEmpty ? c.fonction.trim() : 'Cellule MT');
          eqList.add(cName);
        }
        for (final t in l.transformateurs) {
          final puiss = t.puissanceAssignee.trim().isNotEmpty ? ' (${t.puissanceAssignee.trim()} kVA)' : '';
          final tName = (t.nom != null && t.nom!.trim().isNotEmpty)
              ? t.nom!.trim()
              : (t.typeTransformateur.trim().isNotEmpty ? t.typeTransformateur.trim() : 'Transformateur');
          eqList.add('$tName$puiss');
        }
        for (final c in l.coffrets) {
          eqList.add(c.nom.trim().isNotEmpty ? c.nom.trim() : 'Coffret MT');
        }

        couverts.add(
          Q18PerimetreItem(
            zone: 'Poste MT',
            repere: l.nom.trim().isNotEmpty ? l.nom.trim() : 'Local MT',
            equipements: eqList.isNotEmpty ? eqList.join(', ') : 'Installations MT',
            isCouvert: true,
          ),
        );

        for (final c in l.coffrets) {
          if (!c.accessible) {
            exclusions.add(
              Q18PerimetreItem(
                zone: 'Poste MT',
                repere: c.repere?.trim().isNotEmpty == true ? c.repere!.trim() : l.nom.trim(),
                equipements: c.nom.trim().isNotEmpty ? c.nom.trim() : 'Coffret MT',
                isCouvert: false,
                motifExclusion: 'Inaccessible lors de la visite',
              ),
            );
          }
        }
      }

      // 2. Basse tension zones
      for (final z in audit.basseTensionZones) {
        final zName = z.nom.trim().isNotEmpty ? z.nom.trim() : 'Zone BT';

        for (final c in z.coffretsDirects) {
          final cName = c.nom.trim().isNotEmpty ? c.nom.trim() : 'Armoire / Coffret BT';
          final cRep = c.repere?.trim().isNotEmpty == true ? c.repere!.trim() : 'Général';

          if (c.accessible) {
            couverts.add(
              Q18PerimetreItem(
                zone: zName,
                repere: cRep,
                equipements: cName,
                isCouvert: true,
              ),
            );
          } else {
            exclusions.add(
              Q18PerimetreItem(
                zone: zName,
                repere: cRep,
                equipements: cName,
                isCouvert: false,
                motifExclusion: 'Inaccessible lors de la visite',
              ),
            );
          }
        }

        for (final l in z.locaux) {
          final lName = l.nom.trim().isNotEmpty ? l.nom.trim() : 'Local BT';
          final eqList = <String>[];
          for (final c in l.coffrets) {
            if (c.accessible) {
              eqList.add(c.nom.trim().isNotEmpty ? c.nom.trim() : 'Équipement BT');
            } else {
              exclusions.add(
                Q18PerimetreItem(
                  zone: zName,
                  repere: c.repere?.trim().isNotEmpty == true ? c.repere!.trim() : lName,
                  equipements: c.nom.trim().isNotEmpty ? c.nom.trim() : 'Équipement BT',
                  isCouvert: false,
                  motifExclusion: 'Inaccessible lors de la visite',
                ),
              );
            }
          }

          couverts.add(
            Q18PerimetreItem(
              zone: zName,
              repere: lName,
              equipements: eqList.isNotEmpty ? eqList.join(', ') : 'Installations BT',
              isCouvert: true,
            ),
          );
        }
      }
    }

    return (couverts: couverts, exclusions: exclusions);
  }

  /// Détermine la disponibilité des 6 documents de la Section 6.
  static List<Q18DocumentConsulteItem> _collectDocumentsConsultes(
    Mission mission,
    RenseignementsGeneraux? rens,
    DescriptionInstallations? desc, {
    required bool hasQ18Precedent,
  }) {
    // 1. Schémas unifilaires et de distribution de l'installation électrique
    final bool hasSchemas = mission.docSchemasUnifilaires;

    // 2. Carnet de bord / registre de maintenance électrique (Initialisé à Non)
    const bool hasCarnet = false;

    // 3. Rapport de la dernière vérification réglementaire
    final bool hasDernierRapport = mission.docRapportDerniereVerif;

    // 4. Rapport Q18 précédent, le cas échéant (dérivé de la source de vérité unique)

    // 5. Plans des locaux avec classement des zones à risque (ATEX, poussières, etc.)
    final bool hasPlansAtex = mission.docPlanLocauxRisques;

    // 6. Fiches techniques du matériel électrique sensible (Initialisé à Non)
    const bool hasFiches = false;

    return [
      Q18DocumentConsulteItem(
        index: 1,
        titre: 'Schémas unifilaires et de distribution de l\'installation électrique',
        isDisponible: hasSchemas,
      ),
      Q18DocumentConsulteItem(
        index: 2,
        titre: 'Carnet de bord / registre de maintenance électrique',
        isDisponible: hasCarnet,
      ),
      Q18DocumentConsulteItem(
        index: 3,
        titre: 'Rapport de la dernière vérification réglementaire',
        isDisponible: hasDernierRapport,
      ),
      Q18DocumentConsulteItem(
        index: 4,
        titre: 'Rapport Q18 précédent, le cas échéant',
        isDisponible: hasQ18Precedent,
      ),
      Q18DocumentConsulteItem(
        index: 5,
        titre: 'Plans des locaux avec classement des zones à risque (ATEX, poussières, etc.)',
        isDisponible: hasPlansAtex,
      ),
      Q18DocumentConsulteItem(
        index: 6,
        titre: 'Fiches techniques du matériel électrique sensible',
        isDisponible: hasFiches,
      ),
    ];
  }
}

