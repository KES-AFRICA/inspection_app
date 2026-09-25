// lib/services/pdf/q18/q18_data_collector.dart

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/canonical_risk_family_registry.dart';
import 'package:inspec_app/services/statistics/global_assessment_engine.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
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

    // 2. Inventaire des installations pour la Section 4
    final quantities = _collectQuantities(audit, description, foudre);

    // 3. Périmètre et exclusions pour la Section 5
    final perimetreData = _collectPerimetre(audit);

    // 4. Documents consultés pour la Section 6
    final documentsConsultes = _collectDocumentsConsultes(renseignements, description);

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
        if (l.cellules.isNotEmpty) eqList.add('${l.cellules.length} cellule(s) MT');
        if (l.transformateurs.isNotEmpty) eqList.add('${l.transformateurs.length} transfo(s)');
        if (l.coffrets.isNotEmpty) eqList.add('${l.coffrets.length} coffret(s)');

        couverts.add(
          Q18PerimetreItem(
            zone: 'Poste MT',
            repere: l.nom,
            equipements: eqList.isNotEmpty ? eqList.join(', ') : 'Installations MT',
            isCouvert: true,
          ),
        );

        for (final c in l.coffrets) {
          if (!c.accessible) {
            exclusions.add(
              Q18PerimetreItem(
                zone: 'Poste MT',
                repere: c.repere ?? c.nom,
                equipements: c.nom,
                isCouvert: false,
                motifExclusion: 'Inaccessible lors de la visite',
              ),
            );
          }
        }
      }

      // 2. Basse tension zones
      for (final z in audit.basseTensionZones) {
        for (final c in z.coffretsDirects) {
          if (!c.accessible) {
            exclusions.add(
              Q18PerimetreItem(
                zone: z.nom,
                repere: c.repere ?? c.nom,
                equipements: c.nom,
                isCouvert: false,
                motifExclusion: 'Inaccessible lors de la visite',
              ),
            );
          }
        }

        for (final l in z.locaux) {
          final eqList = <String>[];
          if (l.coffrets.isNotEmpty) eqList.add('${l.coffrets.length} équipement(s)');

          couverts.add(
            Q18PerimetreItem(
              zone: z.nom,
              repere: l.nom,
              equipements: eqList.isNotEmpty ? eqList.join(', ') : 'Installations BT',
              isCouvert: true,
            ),
          );

          for (final c in l.coffrets) {
            if (!c.accessible) {
              exclusions.add(
                Q18PerimetreItem(
                  zone: z.nom,
                  repere: c.repere ?? c.nom,
                  equipements: c.nom,
                  isCouvert: false,
                  motifExclusion: 'Inaccessible lors de la visite',
                ),
              );
            }
          }
        }
      }
    }

    return (couverts: couverts, exclusions: exclusions);
  }

  /// Détermine la disponibilité des 6 documents de la Section 6.
  static List<Q18DocumentConsulteItem> _collectDocumentsConsultes(
    RenseignementsGeneraux? rens,
    DescriptionInstallations? desc,
  ) {
    // 1. Schémas unifilaires
    final bool hasSchemas = desc?.noteCalcul?.trim().isNotEmpty == true &&
        desc!.noteCalcul!.trim().toLowerCase() != 'non' &&
        desc.noteCalcul!.trim().toLowerCase() != 'absent';

    // 2. Carnet de bord / registre
    final bool hasCarnet = rens?.registreControle.trim().isNotEmpty == true &&
        rens!.registreControle.trim().toLowerCase() != 'non';

    // 3. Rapport de la dernière vérification réglementaire
    final bool hasDernierRapport = rens?.compteRendu != null && rens!.compteRendu.isNotEmpty;

    // 4. Rapport Q18 précédent
    const bool hasQ18Precedent = false; // Non persisté dans KES

    // 5. Plans des locaux avec classement ATEX / risques
    final bool hasPlansAtex = desc?.registreSecurite?.trim().isNotEmpty == true &&
        desc!.registreSecurite!.trim().toLowerCase() != 'non';

    // 6. Fiches techniques
    final bool hasFiches = hasSchemas;

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
