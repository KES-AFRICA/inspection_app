import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la collecte des entrées et du rendu du Sommaire dynamique
class PdfSommaireBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();
  static pw.MemoryImage? logoKesImage;
  static pw.MemoryImage? watermarkImage;

  static List<SommaireEntry> getSommaireEntriesForTesting({
    Mission? mission,
    AuditInstallationsElectriques? audit,
    MesuresEssais? mesures,
  }) {
    final dummyMission =
        mission ??
        Mission(
          id: 'test',
          nomClient: 'TEST',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'active',
        );
    return collectSommaireEntries(
      mission: dummyMission,
      rg: null,
      desc: null,
      audit: audit,
      mesures: mesures,
      foudres: [],
    );
  }

  static List<SommaireEntry> collectSommaireEntries({
    required Mission mission,
    required RenseignementsGeneraux? rg,
    required DescriptionInstallations? desc,
    required AuditInstallationsElectriques? audit,
    required MesuresEssais? mesures,
    required List<Foudre> foudres,
  }) {
    final entries = <SommaireEntry>[];

    // Intervenants et responsabilités (Page 2)
    entries.add(
      SommaireEntry(
        titre: "INTERVENANTS ET RESPONSABILITÉS",
        key: 'intervenants',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 0. Sommaire (Page 3)
    entries.add(
      SommaireEntry(
        titre: "SOMMAIRE",
        key: 'sommaire',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 1. Objet de la vérification
    entries.add(
      SommaireEntry(
        titre: "OBJET DE LA VÉRIFICATION",
        key: 'objet',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Références normatives et réglementaires",
        key: 'objet_normes',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2. Matériel utilisé",
        key: 'objet_materiel',
        level: 1,
      ),
    );

    // 2. Périmètre de la mission
    entries.add(
      SommaireEntry(
        titre: "PERIMETRE DE LA MISSION",
        key: 'perimetre',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 3. Rappel des responsabilités
    entries.add(
      SommaireEntry(
        titre: "RAPPEL DES RESPONSABILITÉS DE L'EMPLOYEUR",
        key: 'rappel',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Responsabilité et accompagnement",
        key: 'rappel_accompagnement',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2. Conditions de réalisation",
        key: 'rappel_conditions',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3. Vérifications complémentaires",
        key: 'rappel_complementaires',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "4. Surveillance et maintenance des installations électriques",
        key: 'rappel_maintenance',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre:
            "5. Formation du personnel intervenant sur les installations et à proximité",
        key: 'rappel_formation',
        level: 1,
      ),
    );

    // 4. Mesures de sécurité autour des installations
    entries.add(
      SommaireEntry(
        titre: "MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS",
        key: 'mesures_securite',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Technicien en maintenance des installations",
        key: 'mesures_technicien',
        level: 1,
      ),
    );

    // 5. Engagement de KES INSPECTIONS AND PROJECTS
    entries.add(
      SommaireEntry(
        titre: "ENGAGEMENT DE KES INSPECTIONS AND PROJECTS",
        key: 'mesures_engagement',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 5. Résumé Exécutif
    entries.add(
      SommaireEntry(
        titre: "RESUME EXECUTIF",
        key: 'resume_executif',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Contexte et périmètre de la mission",
        key: 'resume_executif_1_1',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2. Synthèse des résultats",
        key: 'resume_executif_1_2',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2.1. Indicateurs clés de la mission",
        key: 'resume_executif_1_2_1',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2.2. Criticité",
        key: 'resume_executif_1_2_2',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2.3. Facteurs de risque prépondérants",
        key: 'resume_executif_1_2_3',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3. Répartition des non-conformités",
        key: 'resume_executif_1_3',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3.1. Analyse Moyenne Tension (HTA)",
        key: 'resume_executif_1_3_1',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3.2. Analyse Basse Tension (BT)",
        key: 'resume_executif_1_3_2',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "4. Diversification des marques des appareillages de protection",
        key: 'resume_executif_1_4',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "5. Courbes et protections",
        key: 'resume_executif_1_5',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "6. Adéquation ICC / PDC",
        key: 'resume_executif_1_6',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "7. Proportion type de câble par section",
        key: 'resume_executif_1_7',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "8. Adéquation classement des zones et indices des équipements",
        key: 'resume_executif_1_8',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "9. Renforcement des compétences",
        key: 'resume_executif_1_9',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "10. Recommandations prioritaires hiérarchisées",
        key: 'resume_executif_1_10',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "11. Appréciation globale",
        key: 'resume_executif_1_11',
        level: 1,
      ),
    );

    // 6. Analyse Statistique
    entries.add(
      SommaireEntry(
        titre: "ANALYSE STATISTIQUE",
        key: 'analyse_statistique',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Répartition des non conformités par domaine de tension",
        key: 'stat_tension',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2. Non-conformités croisées par catégorie d'installation",
        key: 'stat_croisee',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2.1. Moyenne tension",
        key: 'stat_croisee_mt',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2.2. Basse tension",
        key: 'stat_croisee_bt',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3. Sécurité et traçabilité des tableaux Basse Tension",
        key: 'stat_securite_bt',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3.1. Identification des sources d’alimentation",
        key: 'stat_sources_alim',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3.2. Présence organe de coupure en tête d’installation",
        key: 'stat_coupure_tete',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3.3. Présence parafoudre",
        key: 'stat_parafoudres',
        level: 2,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "4. Statistique par type de défaut : analyse de Pareto (corrigée)",
        key: 'stat_pareto',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "5. Analyse comparative avec la visite précédente",
        key: 'stat_annee_passee',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "6. Synthèse de l'analyse statistique",
        key: 'stat_synthese',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "7. Recommandation pour le renforcement des capacités des agents d’entretien",
        key: 'stat_formation',
        level: 1,
      ),
    );

    // 7. Renseignements généraux
    entries.add(
      SommaireEntry(
        titre: "RENSEIGNEMENTS GÉNÉRAUX DE L'ÉTABLISSEMENT",
        key: 'renseignements',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Renseignements principaux",
        key: 'renseignements_principaux',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "2. Documents nécessaires à la vérification",
        key: 'renseignements_documents',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "3. Habilitation électrique du personnel d'intervention",
        key: 'renseignements_habilitation',
        level: 1,
      ),
    );

    // 8. Description des installations
    int descSubIdx = 1;
    entries.add(
      SommaireEntry(
        titre: "DESCRIPTION DES INSTALLATIONS",
        key: 'description',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Alimentation du site Moyen Tension",
        key: 'desc_alim_site_mt',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre:
            "${descSubIdx++}. Caractéristiques de l'alimentation moyenne tension",
        key: 'desc_mt',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre:
            "${descSubIdx++}. Caractéristiques de l'alimentation basse tension sortie transformateur",
        key: 'desc_bt',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Caractéristiques du groupe électrogène",
        key: 'desc_ge',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre:
            "${descSubIdx++}. Alimentation du groupe électrogène en carburant",
        key: 'desc_carburant',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Caractéristiques de l'inverseur",
        key: 'desc_inverseur',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Caractéristiques du stabilisateur",
        key: 'desc_stabilisateur',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Caractéristiques des onduleurs",
        key: 'desc_onduleurs',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Régime de neutre",
        key: 'desc_regime_neutre',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre:
            "${descSubIdx++}. Caractéristiques du Contrôleur Permanent d'Isolement (CPI)",
        key: 'desc_cpi',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Eclairage de sécurité",
        key: 'desc_eclairage',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Modifications apportées aux installations",
        key: 'desc_modifications',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Note de calcul des installations électriques",
        key: 'desc_note_calcul',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Présence de paratonnerre",
        key: 'desc_paratonnerre',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Registre de sécurité",
        key: 'desc_registre',
        level: 1,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "${descSubIdx++}. Zones et Locaux à risque",
        key: 'desc_locaux_risques',
        level: 1,
      ),
    );

    // 8.bis Synthèse récapitulative des équipements (si audit)
    if (audit != null) {
      entries.add(
        SommaireEntry(
          titre: "SYNTHÈSE RÉCAPITULATIVE DES ÉQUIPEMENTS",
          key: 'liste_recap_equipements',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "1. Équipements moyenne tension",
          key: 'liste_recap_equipements_mt',
          level: 1,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "2. Équipements basse tension",
          key: 'liste_recap_equipements_bt',
          level: 1,
        ),
      );
      final hasUnknown = hasUnknownSources(audit);
      if (hasUnknown) {
        entries.add(
          SommaireEntry(
            titre: "3. Équipements aux sources non identifiées",
            key: 'liste_recap_equipements_sources_inconnues',
            level: 1,
          ),
        );
      }
    }

    // 9. Liste récapitulative des observations (si audit)
    if (audit != null) {
      entries.add(
        SommaireEntry(
          titre: "SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS",
          key: 'liste_recap',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "1. Moyenne tension",
          key: 'liste_recap_mt',
          level: 1,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "2. Basse tension",
          key: 'liste_recap_bt',
          level: 1,
        ),
      );
    }

    // 10. Audit des installations (si audit)
    if (audit != null) {
      entries.add(
        SommaireEntry(
          titre: "AUDIT DES INSTALLATIONS ELECTRIQUES",
          key: 'audit',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
    }

    // 11. Classement
    entries.add(
      SommaireEntry(
        titre:
            "CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONES EN FONCTION DES INFLUENCES EXTERNES",
        key: 'classement',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 12. Foudre et surtension
    entries.add(
      SommaireEntry(
        titre: "FOUDRE ET SURTENSION",
        key: 'foudre',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );
    entries.add(
      SommaireEntry(
        titre: "1. Observation par équipement",
        key: 'foudre_equipements',
        level: 1,
      ),
    );

    // 13. Mesures et essais (si mesures)
    if (mesures != null) {
      entries.add(
        SommaireEntry(
          titre: "RESULTATS DES MESURES ET ESSAIS",
          key: 'mesures',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "I. CONDITIONS DE MESURE",
          key: 'mesures_conditions',
          level: 1,
          isBold: true,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "II. RÉSULTATS DES ESSAIS",
          key: 'mesures_resultats',
          level: 1,
          isBold: true,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "1. Prise de terre",
          key: 'mesures_terre',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "2. Essais de déclenchement des dispositifs différentiels",
          key: 'mesures_ddr',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre:
              "3. Essais de mesure d'isolement entre deux points d'un tronçon de câble",
          key: 'mesures_isolement',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "4. Test du Contrôleur Permanent d'Isolement (CPI)",
          key: 'mesures_cpi',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "5. Essais de démarrage automatique du groupe électrogène",
          key: 'mesures_demarrage',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre: "6. Test de fonctionnement de l'arrêt d'urgence",
          key: 'mesures_arret',
          level: 2,
        ),
      );
      entries.add(
        SommaireEntry(
          titre:
              "7. Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles",
          key: 'mesures_continuite',
          level: 2,
        ),
      );
    }

    // Signature du rapport
    entries.add(
      SommaireEntry(
        titre: "Signature du rapport",
        key: 'signature_rapport',
        level: 0,
        isBold: true,
        isUppercase: false,
      ),
    );

    // 14. Photos
    entries.add(
      SommaireEntry(
        titre: "PHOTOS",
        key: 'photos',
        level: 0,
        isBold: true,
        isUppercase: true,
      ),
    );

    // 15. Schéma des installations électriques (si Oui)
    final bool hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (hasSchema) {
      entries.add(
        SommaireEntry(
          titre: "SCHEMA DES INSTALLATIONS ELECTRIQUES",
          key: 'schema_installations',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      );
    }

    return entries;
  }

  // ──────────────────────────────────────────────────────────────
  //  SOMMAIRE (format Word avec points de liaison)
  // ──────────────────────────────────────────────────────────────




  static bool hasUnknownSources(AuditInstallationsElectriques? audit) {
    if (audit == null) return false;
    bool checkCoffret(CoffretArmoire c) {
      for (final a in c.alimentations) {
        if (a.effectiveSourceKnown == 'Inconnue') return true;
      }
      return false;
    }
    for (final l in audit.moyenneTensionLocaux) {
      for (final c in l.coffrets) {
        if (checkCoffret(c)) return true;
      }
    }
    for (final z in audit.moyenneTensionZones) {
      for (final c in z.coffrets) {
        if (checkCoffret(c)) return true;
      }
      for (final l in z.locaux) {
        for (final c in l.coffrets) {
          if (checkCoffret(c)) return true;
        }
      }
    }
    for (final z in audit.basseTensionZones) {
      for (final c in z.coffretsDirects) {
        if (checkCoffret(c)) return true;
      }
      for (final l in z.locaux) {
        for (final c in l.coffrets) {
          if (checkCoffret(c)) return true;
        }
      }
    }
    return false;
  }

  static void addSommairePages(
    pw.Document pdf,
    List<SommaireEntry> entries,
    Map<String, int> trackedPages, {
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    pw.Font? fontRegular,
    pw.Font? fontBold,
    pw.MemoryImage? logoKesImage,
    pw.MemoryImage? watermarkImage,
  }) {
    final fRegular = fontRegular ?? PdfSommaireBuilder.fontRegular;
    final fBold = fontBold ?? PdfSommaireBuilder.fontBold;
    final logo = logoKesImage ?? PdfSommaireBuilder.logoKesImage;
    final watermark = watermarkImage ?? PdfSommaireBuilder.watermarkImage;

    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: PdfReportStyles.buildInnerPageTheme(
          fontRegular: fRegular,
          fontBold: fBold,
          watermarkImage: watermark,
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => PdfReportStyles.buildPageHeaderWidget(
          logoKesImage: logo,
          fontRegular: fRegular,
          fontBold: fBold,
          nomClient: nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          PageTracker(
            key: 'sommaire',
            registry: trackedPages,
            offset: pageOffset,
            child: pw.Center(
              child: pw.Text(
                'SOMMAIRE',
                style: pw.TextStyle(
                  font: fBold,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfReportStyles.accentColor,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(width: double.infinity, height: 1.5, color: PdfReportStyles.accentColor),
          pw.SizedBox(height: 16),
          ...entries.map(
            (entry) => buildSommaireEntryLine(entry, trackedPages, fontRegular: fRegular, fontBold: fBold),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildSommaireEntryLine(
    SommaireEntry entry,
    Map<String, int> trackedPages, {
    pw.Font? fontRegular,
    pw.Font? fontBold,
  }) {
    final fRegular = fontRegular ?? PdfSommaireBuilder.fontRegular;
    final fBold = fontBold ?? PdfSommaireBuilder.fontBold;

    final double leftPadding = entry.level * 14.0;
    final double fontSize = entry.level == 0
        ? 8.5
        : (entry.level == 1 ? 8.0 : (entry.level == 2 ? 7.5 : 7.0));
    final pw.Font font = entry.isBold ? fBold : fRegular;
    final PdfColor color = PdfReportStyles.accentColor;

    final titleText = entry.isUppercase
        ? entry.titre.toUpperCase()
        : entry.titre;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4.0),
      child: pw.Stack(
        alignment: pw.Alignment.bottomRight,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 20.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (leftPadding > 0) pw.SizedBox(width: leftPadding),
                pw.Flexible(
                  child: pw.Text(
                    titleText.trim(),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: fontSize,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      canvas.setStrokeColor(PdfColors.grey400);
                      canvas.setLineWidth(0.8);
                      canvas.setLineDashPattern([1, 2.5]);
                      canvas.drawLine(0, 2, size.x, 2);
                      canvas.strokePath();
                    },
                  ),
                ),
              ],
            ),
          ),
          pw.Positioned(
            right: 0,
            bottom: 0,
            child: PageNumberText(
              keyName: entry.key,
              registry: trackedPages,
              style: pw.TextStyle(
                font: fBold,
                fontSize: fontSize,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
