// lib/services/word_report_service.dart
import 'dart:io';
import 'package:docs_gee/docs_gee.dart';
import 'package:flutter/foundation.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

// ── Couleurs alignées sur le PDF ──
const _headerBg = 'E3EBF4';    // bleu clair header
const _altBg    = 'F7F9FC';    // gris alterné
const _red      = 'F44336';
const _orange   = 'FF9800';
const _green    = '4CAF50';

class WordReportService {

  // ═══════════════════════════════════════════════════════════════
  //  GÉNÉRATION PRINCIPALE
  // ═══════════════════════════════════════════════════════════════
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      final mission       = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final description   = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit         = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements   = HiveService.getEmplacementsByMissionId(missionId);
      final classementsZones = HiveService.getClassementsZonesByMissionId(missionId);
      final mesures       = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres       = HiveService.getFoudreObservationsByMissionId(missionId);
      final renseignements = HiveService.getRenseignementsGenerauxByMissionId(missionId);
      final currentUser   = HiveService.getCurrentUser();

      final allPhotos = <String>[];

      final doc = Document(
        title: 'Rapport d\'Audit Électrique - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        includeTableOfContents: true,
        tocTitle: 'SOMMAIRE',
        tocMaxLevel: 3,
      );

      // 1. Page de couverture
      _addCoverPage(doc, mission, renseignements);

      // 2. Rappel des responsabilités
      _addRappelResponsabilites(doc);

      // 3. Mesures de sécurité
      _addMesureSecurite(doc);

      // 4. Objet de la vérification
      _addObjetVerification(doc);

      // 5. Renseignements généraux
      _addRenseignementsGeneraux(doc, mission, renseignements);

      // 6. Description des installations
      _addDescriptionInstallations(doc, description, allPhotos);

      // 7. Liste récapitulative des observations
      if (audit != null) {
        _addListeRecapitulative(doc, audit);
      }

      // 8. Audit des installations électriques
      _addAuditInstallations(doc, audit, allPhotos);

      // 9. Classement des emplacements
      _addClassementEmplacements(doc, classements, classementsZones);

      // 10. Codification des influences externes
      _addCodificationInfluences(doc);

      // 11. Foudre
      _addObservationsFoudre(doc, foudres);

      // 12. Mesures et essais
      if (mesures != null) {
        _addMesuresEssais(doc, mesures, allPhotos);
      }

      // 13. Page de signature
      _addSignaturePage(doc, renseignements, currentUser?.fullName);

      // 14. Annexes photos
      if (allPhotos.isNotEmpty) {
        _addAnnexesPhotos(doc, allPhotos);
      }

      final bytes = DocxGenerator().generate(doc);
      final dir = await getTemporaryDirectory();
      final fileName =
          'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.docx'
              .replaceAll(RegExp(r'[<>:\"/\\|?*]'), '_')
              .replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (kDebugMode) print('✅ Rapport Word généré: ${file.path}');
      return file;
    } catch (e, st) {
      if (kDebugMode) print('❌ Erreur rapport Word: $e\n$st');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. PAGE DE COUVERTURE
  // ═══════════════════════════════════════════════════════════════
  static void _addCoverPage(Document doc, Mission mission, RenseignementsGeneraux? rg) {
    _sectionTitle(doc, 'RAPPORT D\'AUDIT ÉLECTRIQUE', center: true, level: 1);
    _sectionTitle(doc, 'KES INSPECTIONS AND PROJECTS', center: true, level: 2);
    doc.addParagraph(Paragraph.text(''));

    final nomSite = rg?.nomSite.isNotEmpty == true ? rg!.nomSite : (mission.nomSite ?? '');
    final rows = <TableRow>[
      _headerRow(['Informations', '']),
      _dataRow(['Client', mission.nomClient]),
      if (nomSite.isNotEmpty) _dataRow(['Site', nomSite]),
      if (mission.adresseClient != null) _dataRow(['Adresse', mission.adresseClient!]),
      _dataRow(['Date d\'intervention', _formatDate(mission.dateIntervention ?? DateTime.now())]),
      _dataRow(['Rapport généré le', _formatDate(DateTime.now())]),
      if (mission.natureMission != null) _dataRow(['Nature de la mission', mission.natureMission!]),
      if (mission.periodicite != null) _dataRow(['Périodicité', mission.periodicite!]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. RAPPEL DES RESPONSABILITÉS
  // ═══════════════════════════════════════════════════════════════
  static void _addRappelResponsabilites(Document doc) {
    _sectionTitle(doc, 'RAPPEL DES RESPONSABILITÉS DE L\'EMPLOYEUR', level: 1, pageBreak: true);

    _bodyText(doc,
      'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le présent rapport de vérification '
      'de vos installations électriques, établi à la suite des constats réalisés sur site. '
      'Ce document présente les observations effectuées par le vérificateur à partir des éléments '
      'et moyens mis à sa disposition. Il identifie les points de non-conformité constatés au regard '
      'des exigences réglementaires, et formule, le cas échéant, les recommandations techniques '
      'nécessaires à leur mise en conformité.');

    _subTitle(doc, 'Responsabilité et accompagnement');
    _bodyText(doc,
      'Dans le cadre de la mission, il appartient à l\'employeur de désigner une personne qualifiée '
      'et informée des installations, chargée d\'accompagner le vérificateur durant l\'intervention. '
      'Cette personne doit pouvoir faciliter l\'accès à l\'ensemble des locaux, appareillages et '
      'équipements à contrôler.\n\n'
      'L\'employeur reste responsable du bon fonctionnement, de la sécurité et de la disponibilité '
      'des installations tout au long de la vérification.');

    _subTitle(doc, 'Conditions de réalisation');
    _bodyText(doc, 'Afin d\'assurer le bon déroulement des opérations, l\'employeur doit :');
    _bullet(doc, 'Veiller à ce que la vérification soit réalisée dans des conditions de sécurité optimales ;');
    _bullet(doc, 'Mettre en œuvre les procédures nécessaires aux mises hors tension ;');
    _bullet(doc, 'Garantir au vérificateur l\'accès à l\'ensemble des équipements à contrôler.');

    _subTitle(doc, 'Vérifications complémentaires');
    _bodyText(doc,
      'Lorsque des éléments du poste ou de l\'installation n\'ont pu être contrôlés lors de la '
      'visite initiale, une intervention complémentaire pourra être programmée à la demande de l\'employeur.');

    _subTitle(doc, 'Surveillance & maintenance des installations électriques');
    _bodyText(doc,
      'La vérification de conformité des installations électriques ne constitue qu\'un des éléments '
      'concourant à la sécurité des personnes et des biens. Conformément à la norme et aux textes '
      'réglementaires applicables, le chef d\'établissement doit mettre en place une organisation '
      'pour les opérations de surveillance et la maintenance des installations électriques.');

    _subTitle(doc, 'Engagement de KES INSPECTIONS AND PROJECTS');
    _bodyText(doc,
      'KES INSPECTIONS AND PROJECTS s\'engage à réaliser ses vérifications dans le strict respect '
      'des normes et règlements applicables, avec le souci constant de la sécurité, de la fiabilité '
      'technique et de l\'impartialité des constats.');
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. MESURES DE SÉCURITÉ
  // ═══════════════════════════════════════════════════════════════
  static void _addMesureSecurite(Document doc) {
    _sectionTitle(doc, 'MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS', level: 1, pageBreak: true);

    _bodyText(doc, 'Suivant la réglementation applicable :');
    _bullet(doc, 'Article 5 - Arrêté 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail');
    _bullet(doc, 'NFC 18-510 : Opérations sur les ouvrages et installations électriques - Prévention du risque électrique');

    _bodyText(doc,
      'Le personnel doit avoir subi avec succès une formation en habilitation électrique en fonction '
      'du domaine de tension.');

    _bodyText(doc,
      'Il est rappelé que des dispositions de sécurité particulières et parfaitement définies doivent '
      'être prises par le chef de l\'établissement pour toute intervention de maintenance, réglage, '
      'nettoyage sur ou à proximité des installations électriques.\n\n'
      'L\'accès aux locaux et armoires électriques doit être interdit aux personnes non autorisées.');

    _subTitle(doc, 'Technicien en Maintenance Des Installations');
    _bodyText(doc, 'Il est fortement recommandé à l\'employeur de faire participer les employés à des séances de formations sur les modules suivants :');
    _bullet(doc, 'Connaissance des normes en électricité (NC 244 C15 00...)');
    _bullet(doc, 'Maintenance des installations électriques');
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. OBJET DE LA VÉRIFICATION
  // ═══════════════════════════════════════════════════════════════
  static void _addObjetVerification(Document doc) {
    _sectionTitle(doc, 'OBJET DE LA VÉRIFICATION', level: 1, pageBreak: true);

    _bodyText(doc,
      'La présente vérification a pour objet de s\'assurer que les installations électriques de '
      'l\'établissement sont conformes aux règles techniques et de sécurité en vigueur, en '
      'application des textes réglementaires et normatifs applicables.');

    _subTitle(doc, 'Normes et réglementations applicables');
    final normesRows = <TableRow>[
      _headerRow(['Référence', 'Désignation']),
      _dataRow(['NF C 15-100', 'Installations électriques à basse tension']),
      _dataRow(['NF C 13-100', 'Postes de livraison établis à l\'intérieur d\'un bâtiment']),
      _dataRow(['NF C 13-200', 'Installations électriques à haute tension']),
      _dataRow(['NF C 18-510', 'Opérations sur les ouvrages et installations électriques']),
      _dataRow(['NF EN 60439', 'Ensembles d\'appareillage à basse tension']),
      _dataRow(['IEC 60364', 'Installations électriques des bâtiments']),
    ];
    doc.addTable(Table(rows: normesRows, borders: TableBorders.all()));

    _subTitle(doc, 'Matériel de vérification utilisé');
    final materielRows = <TableRow>[
      _headerRow(['Appareil', 'Usage']),
      _dataRow(['Multimètre numérique', 'Mesure de tensions et courants']),
      _dataRow(['Contrôleur d\'isolement', 'Mesure de résistance d\'isolement']),
      _dataRow(['Testeur de différentiels', 'Test de déclenchement des DDR']),
      _dataRow(['Telluromètre', 'Mesure de résistance des prises de terre']),
      _dataRow(['Caméra thermique', 'Thermographie des installations']),
      _dataRow(['Pince ampèremétrique', 'Mesure des courants en charge']),
    ];
    doc.addTable(Table(rows: materielRows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. RENSEIGNEMENTS GÉNÉRAUX
  // ═══════════════════════════════════════════════════════════════
  static void _addRenseignementsGeneraux(
      Document doc, Mission mission, RenseignementsGeneraux? rg) {
    _sectionTitle(doc, 'RENSEIGNEMENTS GÉNÉRAUX DE L\'ÉTABLISSEMENT', level: 1, pageBreak: true);

    final nomSite = rg?.nomSite.isNotEmpty == true ? rg!.nomSite : (mission.nomSite ?? '');

    // Identification
    _subTitle(doc, 'Identification de l\'établissement');
    final idRows = <TableRow>[
      _headerRow(['Champ', 'Valeur']),
      _dataRow(['Nom du client', mission.nomClient]),
      if (nomSite.isNotEmpty) _dataRow(['Nom du site', nomSite]),
      if (rg?.etablissement.isNotEmpty == true) _dataRow(['Établissement', rg!.etablissement]),
      if (rg?.activite.isNotEmpty == true) _dataRow(['Activité', rg!.activite]),
      if (mission.adresseClient != null) _dataRow(['Adresse', mission.adresseClient!]),
      if (mission.dgResponsable != null) _dataRow(['DG / Responsable', mission.dgResponsable!]),
      if (rg?.installation.isNotEmpty == true) _dataRow(['Installation', rg!.installation]),
    ];
    doc.addTable(Table(rows: idRows, borders: TableBorders.all()));

    // Mission
    _subTitle(doc, 'Informations de la mission');
    final missionRows = <TableRow>[
      _headerRow(['Champ', 'Valeur']),
      _dataRow(['Date d\'intervention', _formatDate(mission.dateIntervention ?? DateTime.now())]),
      if (rg?.dateDebut != null) _dataRow(['Date début', _formatDate(rg!.dateDebut!)]),
      if (rg?.dateFin != null) _dataRow(['Date fin', _formatDate(rg!.dateFin!)]),
      if (mission.natureMission != null) _dataRow(['Nature de la mission', mission.natureMission!]),
      if (mission.periodicite != null) _dataRow(['Périodicité', mission.periodicite!]),
      if (rg?.verificationType != null) _dataRow(['Type de vérification', rg!.verificationType!]),
      if (rg?.dureeJours != null && rg!.dureeJours > 0)
        _dataRow(['Durée', '${rg.dureeJours} jour(s)']),
      if (mission.dateRapport != null)
        _dataRow(['Date du rapport', _formatDate(mission.dateRapport!)]),
    ];
    doc.addTable(Table(rows: missionRows, borders: TableBorders.all()));

    // Vérificateurs
    if (rg != null && rg.verificateurs.isNotEmpty) {
      _subTitle(doc, 'Équipe de vérification');
      final verifRows = <TableRow>[
        _headerRow(['Nom', 'Prénom', 'Fonction']),
        for (final v in rg.verificateurs)
          TableRow(cells: [
            TableCell.text(v['nom'] as String? ?? ''),
            TableCell.text(v['prenom'] as String? ?? ''),
            TableCell.text(v['fonction'] as String? ?? ''),
          ]),
      ];
      doc.addTable(Table(rows: verifRows, borders: TableBorders.all()));
    }

    // Accompagnateurs
    if (rg != null && rg.accompagnateurs.isNotEmpty) {
      _subTitle(doc, 'Accompagnateurs');
      final accRows = <TableRow>[
        _headerRow(['Nom', 'Prénom', 'Fonction']),
        for (final a in rg.accompagnateurs)
          TableRow(cells: [
            TableCell.text(a['nom'] as String? ?? ''),
            TableCell.text(a['prenom'] as String? ?? ''),
            TableCell.text(a['fonction'] as String? ?? ''),
          ]),
      ];
      doc.addTable(Table(rows: accRows, borders: TableBorders.all()));
    }

    // Documents fournis
    _subTitle(doc, 'Documents fournis par le client');
    final docs = [
      ['Cahier des prescriptions', mission.docCahierPrescriptions],
      ['Notes de calculs', mission.docNotesCalculs],
      ['Schémas unifilaires', mission.docSchemasUnifilaires],
      ['Plan de masse', mission.docPlanMasse],
      ['Plans architecturaux', mission.docPlansArchitecturaux],
      ['Déclarations CE', mission.docDeclarationsCe],
      ['Liste des installations', mission.docListeInstallations],
      ['Plan des locaux à risques', mission.docPlanLocauxRisques],
      ['Rapport analyse foudre', mission.docRapportAnalyseFoudre],
      ['Rapport étude foudre', mission.docRapportEtudeFoudre],
      ['Registre de sécurité', mission.docRegistreSecurite],
      ['Rapport dernière vérification', mission.docRapportDerniereVerif],
      ['Autre document', mission.docAutre],
    ];
    final docsRows = <TableRow>[
      _headerRow(['Document', 'Fourni']),
      for (final d in docs)
        _dataRow([d[0] as String, (d[1] as bool? ?? false) ? '✓ OUI' : '✗ NON']),
    ];
    doc.addTable(Table(rows: docsRows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. DESCRIPTION DES INSTALLATIONS
  // ═══════════════════════════════════════════════════════════════
  static void _addDescriptionInstallations(
      Document doc, DescriptionInstallations? description, List<String> allPhotos) {
    _sectionTitle(doc, 'DESCRIPTION DES INSTALLATIONS', level: 1, pageBreak: true);

    if (description == null) {
      _bodyText(doc, 'Aucune donnée disponible.');
      return;
    }

    void collectPhotos(List<InstallationItem> items) {
      for (final item in items) allPhotos.addAll(item.photoPaths);
    }

    void addSection(String title, List<InstallationItem> items) {
      if (items.isEmpty) return;
      _subTitle(doc, title);
      _addInstallationItemsTable(doc, items);
      collectPhotos(items);
    }

    addSection('Alimentation Moyenne Tension (MT)', description.alimentationMoyenneTension);
    addSection('Alimentation Basse Tension (BT)', description.alimentationBasseTension);
    addSection('Groupe Électrogène', description.groupeElectrogene);
    addSection('Alimentation en carburant', description.alimentationCarburant);
    addSection('Inverseur', description.inverseur);
    addSection('Stabilisateur', description.stabilisateur);
    addSection('Onduleurs', description.onduleurs);

    // Caractéristiques générales (sélections radio)
    final selections = <List<String>>[];
    if (description.regimeNeutre?.isNotEmpty == true)
      selections.add(['Régime du neutre', description.regimeNeutre!]);
    if (description.eclairageSecurite?.isNotEmpty == true)
      selections.add(['Éclairage de sécurité', description.eclairageSecurite!]);
    if (description.modificationsInstallations?.isNotEmpty == true)
      selections.add(['Modifications des installations', description.modificationsInstallations!]);
    if (description.noteCalcul?.isNotEmpty == true)
      selections.add(['Note de calcul', description.noteCalcul!]);
    if (description.registreSecurite?.isNotEmpty == true)
      selections.add(['Registre de sécurité', description.registreSecurite!]);
    if (description.presenceParatonnerre?.isNotEmpty == true)
      selections.add(['Présence de paratonnerre', description.presenceParatonnerre!]);
    if (description.analyseRisqueFoudre?.isNotEmpty == true)
      selections.add(['Analyse risque foudre', description.analyseRisqueFoudre!]);
    if (description.etudeTechniqueFoudre?.isNotEmpty == true)
      selections.add(['Étude technique foudre', description.etudeTechniqueFoudre!]);

    if (selections.isNotEmpty) {
      _subTitle(doc, 'Caractéristiques générales');
      final rows = <TableRow>[
        _headerRow(['Caractéristique', 'Valeur']),
        for (final s in selections) _dataRow(s),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  7. LISTE RÉCAPITULATIVE DES OBSERVATIONS
  // ═══════════════════════════════════════════════════════════════
  static void _addListeRecapitulative(Document doc, AuditInstallationsElectriques audit) {
    _sectionTitle(doc, 'LISTE RÉCAPITULATIVE DES OBSERVATIONS', level: 1, pageBreak: true);

    _bodyText(doc, 'Niveau de priorité des observations constatées :');
    doc.addTable(Table(rows: [
      TableRow(cells: [
        TableCell.text('P1 : À surveiller', backgroundColor: _green),
        TableCell.text('P2 : Mise en conformité à planifier', backgroundColor: _orange),
        TableCell.text('P3 : Critique, Action immédiate', backgroundColor: _red),
      ]),
    ], borders: TableBorders.all()));

    _subTitle(doc, 'Observations Moyenne Tension');
    final obsMT = _collectObservationsMT(audit);
    if (obsMT.isEmpty) {
      _bodyText(doc, 'Aucune observation de non-conformité.');
    } else {
      final rows = <TableRow>[
        _headerRow(['Localisation', 'Équipement', 'Observation', 'Réf. normative', 'Priorité']),
        for (final obs in obsMT)
          TableRow(cells: [
            TableCell.text(obs[0]),
            TableCell.text(obs[1]),
            TableCell.text(obs[2]),
            TableCell.text(obs[3]),
            TableCell.text(obs[4],
                backgroundColor: obs[4] == '3' ? _red : obs[4] == '2' ? _orange : _green),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }

    _subTitle(doc, 'Observations Basse Tension');
    final obsBT = _collectObservationsBT(audit);
    if (obsBT.isEmpty) {
      _bodyText(doc, 'Aucune observation de non-conformité.');
    } else {
      final rows = <TableRow>[
        _headerRow(['Localisation', 'Équipement', 'Observation', 'Réf. normative', 'Priorité']),
        for (final obs in obsBT)
          TableRow(cells: [
            TableCell.text(obs[0]),
            TableCell.text(obs[1]),
            TableCell.text(obs[2]),
            TableCell.text(obs[3]),
            TableCell.text(obs[4],
                backgroundColor: obs[4] == '3' ? _red : obs[4] == '2' ? _orange : _green),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }
  }

  // ── Collecte observations MT ──
  static List<List<String>> _collectObservationsMT(AuditInstallationsElectriques audit) {
    final list = <List<String>>[];

    void addEl(String loc, String equip, ElementControle el) {
      if (el.conforme == false || el.estNA) {
        list.add([
          loc, equip,
          el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          el.referenceNormative ?? '',
          el.priorite?.toString() ?? '',
        ]);
      }
    }

    void addPt(String loc, String equip, PointVerification p) {
      if (p.conformite == 'non') {
        list.add([
          loc, equip,
          p.observation?.isNotEmpty == true ? p.observation! : p.pointVerification,
          p.referenceNormative ?? '',
          p.priorite?.toString() ?? '',
        ]);
      }
    }

    for (final l in audit.moyenneTensionLocaux) {
      for (final el in l.dispositionsConstructives) addEl(l.nom, 'Dispositions constructives', el);
      for (final el in l.conditionsExploitation) addEl(l.nom, 'Conditions d\'exploitation', el);
      for (final c in l.cellules) {
        for (final el in c.elementsVerifies) addEl(l.nom, 'Cellule ${c.fonction}', el);
      }
      for (final t in l.transformateurs) {
        for (final el in t.elementsVerifies) addEl(l.nom, 'Transformateur', el);
      }
      for (final c in l.coffrets) {
        for (final p in c.pointsVerification) addPt(l.nom, c.nom, p);
      }
    }
    for (final z in audit.moyenneTensionZones) {
      for (final c in z.coffrets) {
        for (final p in c.pointsVerification) addPt(z.nom, c.nom, p);
      }
      for (final l in z.locaux) {
        for (final el in l.dispositionsConstructives) addEl(l.nom, 'Dispositions constructives', el);
        for (final c in l.coffrets) {
          for (final p in c.pointsVerification) addPt(l.nom, c.nom, p);
        }
      }
    }
    return list;
  }

  // ── Collecte observations BT ──
  static List<List<String>> _collectObservationsBT(AuditInstallationsElectriques audit) {
    final list = <List<String>>[];

    void addEl(String loc, String equip, ElementControle el) {
      if (el.conforme == false || el.estNA) {
        list.add([
          loc, equip,
          el.observation?.isNotEmpty == true ? el.observation! : el.elementControle,
          el.referenceNormative ?? '',
          el.priorite?.toString() ?? '',
        ]);
      }
    }

    void addPt(String loc, String equip, PointVerification p) {
      if (p.conformite == 'non') {
        list.add([
          loc, equip,
          p.observation?.isNotEmpty == true ? p.observation! : p.pointVerification,
          p.referenceNormative ?? '',
          p.priorite?.toString() ?? '',
        ]);
      }
    }

    for (final z in audit.basseTensionZones) {
      for (final c in z.coffretsDirects) {
        for (final p in c.pointsVerification) addPt(z.nom, c.nom, p);
      }
      for (final l in z.locaux) {
        for (final el in (l.dispositionsConstructives ?? <ElementControle>[])) addEl(l.nom, 'Dispositions constructives', el);
        for (final el in (l.conditionsExploitation ?? <ElementControle>[])) addEl(l.nom, 'Conditions d\'exploitation', el);
        for (final c in l.coffrets) {
          for (final p in c.pointsVerification) addPt(l.nom, c.nom, p);
        }
      }
    }
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  //  8. AUDIT DES INSTALLATIONS ÉLECTRIQUES
  // ═══════════════════════════════════════════════════════════════
  static void _addAuditInstallations(
      Document doc, AuditInstallationsElectriques? audit, List<String> allPhotos) {
    _sectionTitle(doc, 'AUDIT DES INSTALLATIONS ÉLECTRIQUES', level: 1, pageBreak: true);

    if (audit == null) {
      _bodyText(doc, 'Aucune donnée d\'audit disponible.');
      return;
    }

    allPhotos.addAll(audit.photos);

    // ── MOYENNE TENSION ──
    if (audit.moyenneTensionLocaux.isNotEmpty || audit.moyenneTensionZones.isNotEmpty) {
      _subTitle(doc, 'MOYENNE TENSION');

      if (audit.moyenneTensionLocaux.isNotEmpty) {
        _subTitle(doc, 'Locaux Moyenne Tension');
        for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
          _addLocalMTDetails(doc, audit.moyenneTensionLocaux[i], i + 1, allPhotos);
        }
      }

      if (audit.moyenneTensionZones.isNotEmpty) {
        _subTitle(doc, 'Zones Moyenne Tension');
        for (int i = 0; i < audit.moyenneTensionZones.length; i++) {
          _addZoneMTDetails(doc, audit.moyenneTensionZones[i], i + 1, allPhotos);
        }
      }
    }

    // ── BASSE TENSION ──
    if (audit.basseTensionZones.isNotEmpty) {
      _subTitle(doc, 'BASSE TENSION');
      for (int i = 0; i < audit.basseTensionZones.length; i++) {
        _addZoneBTDetails(doc, audit.basseTensionZones[i], i + 1, allPhotos);
      }
    }
  }

  static void _addLocalMTDetails(Document doc, MoyenneTensionLocal local, int idx, List<String> photos) {
    photos.addAll(local.photos);
    doc.addParagraph(Paragraph.heading('Local MT $idx : ${local.nom} (${local.type})', level: 4));

    doc.addTable(Table(rows: [
      _headerRow(['Nom du local', 'Type']),
      _dataRow([local.nom, local.type]),
      _dataRow(['Accessible', local.accessible ? 'OUI' : 'NON']),
    ], borders: TableBorders.all()));

    if (local.dispositionsConstructives.isNotEmpty) {
      _subTitle(doc, 'Dispositions constructives');
      _addElementsTable(doc, local.dispositionsConstructives);
    }
    if (local.conditionsExploitation.isNotEmpty) {
      _subTitle(doc, 'Conditions d\'exploitation');
      _addElementsTable(doc, local.conditionsExploitation);
    }
    // Cellules (nouvelle liste)
    for (final c in local.cellules) _addCelluleDetails(doc, c, photos);
    // Transformateurs (nouvelle liste)
    for (final t in local.transformateurs) _addTransformateurDetails(doc, t, photos);
    // Coffrets
    if (local.coffrets.isNotEmpty) {
      _subTitle(doc, 'Coffrets / Armoires dans le local');
      for (int j = 0; j < local.coffrets.length; j++) {
        _addCoffretDetails(doc, local.coffrets[j], j + 1, photos);
      }
    }
    if (local.observationsLibres.isNotEmpty) {
      _subTitle(doc, 'Observations du local');
      _addObservationsTable(doc, local.observationsLibres);
    }
  }

  static void _addZoneMTDetails(Document doc, MoyenneTensionZone zone, int idx, List<String> photos) {
    photos.addAll(zone.photos);
    doc.addParagraph(Paragraph.heading('Zone MT $idx : ${zone.nom}', level: 4));

    final infoRows = <TableRow>[_headerRow(['Champ', 'Valeur']), _dataRow(['Nom', zone.nom])];
    if (zone.description != null) infoRows.add(_dataRow(['Description', zone.description!]));
    doc.addTable(Table(rows: infoRows, borders: TableBorders.all()));

    if (zone.coffrets.isNotEmpty) {
      _subTitle(doc, 'Coffrets / Armoires dans la zone');
      for (int j = 0; j < zone.coffrets.length; j++) {
        _addCoffretDetails(doc, zone.coffrets[j], j + 1, photos);
      }
    }
    if (zone.observationsLibres.isNotEmpty) {
      _subTitle(doc, 'Observations de la zone');
      _addObservationsTable(doc, zone.observationsLibres);
    }
    if (zone.locaux.isNotEmpty) {
      _subTitle(doc, 'Locaux dans la zone');
      for (int j = 0; j < zone.locaux.length; j++) {
        _addLocalMTDetails(doc, zone.locaux[j], j + 1, photos);
      }
    }
  }

  static void _addZoneBTDetails(Document doc, BasseTensionZone zone, int idx, List<String> photos) {
    photos.addAll(zone.photos);
    doc.addParagraph(Paragraph.heading('Zone BT $idx : ${zone.nom}', level: 3));

    final infoRows = <TableRow>[_headerRow(['Champ', 'Valeur']), _dataRow(['Nom', zone.nom])];
    if (zone.description != null) infoRows.add(_dataRow(['Description', zone.description!]));
    doc.addTable(Table(rows: infoRows, borders: TableBorders.all()));

    if (zone.coffretsDirects.isNotEmpty) {
      _subTitle(doc, 'Coffrets / Armoires directs');
      for (int j = 0; j < zone.coffretsDirects.length; j++) {
        _addCoffretDetails(doc, zone.coffretsDirects[j], j + 1, photos);
      }
    }
    if (zone.observationsLibres.isNotEmpty) {
      _subTitle(doc, 'Observations de la zone');
      _addObservationsTable(doc, zone.observationsLibres);
    }
    if (zone.locaux.isNotEmpty) {
      _subTitle(doc, 'Locaux dans la zone');
      for (int j = 0; j < zone.locaux.length; j++) {
        _addLocalBTDetails(doc, zone.locaux[j], j + 1, photos);
      }
    }
  }

  static void _addLocalBTDetails(Document doc, BasseTensionLocal local, int idx, List<String> photos) {
    photos.addAll(local.photos);
    doc.addParagraph(Paragraph.heading('Local BT $idx : ${local.nom} (${local.type})', level: 5));

    doc.addTable(Table(rows: [
      _headerRow(['Nom', 'Type', 'Accessible']),
      TableRow(cells: [
        TableCell.text(local.nom),
        TableCell.text(local.type),
        TableCell.text(local.accessible ? 'OUI' : 'NON'),
      ]),
    ], borders: TableBorders.all()));

    if ((local.dispositionsConstructives ?? []).isNotEmpty) {
      _subTitle(doc, 'Dispositions constructives');
      _addElementsTable(doc, local.dispositionsConstructives!);
    }
    if ((local.conditionsExploitation ?? []).isNotEmpty) {
      _subTitle(doc, 'Conditions d\'exploitation');
      _addElementsTable(doc, local.conditionsExploitation!);
    }
    // Cellules BT (LOCAL_MTBT)
    for (final c in local.cellules) _addCelluleDetails(doc, c, photos);
    for (final t in local.transformateurs) _addTransformateurDetails(doc, t, photos);

    if (local.coffrets.isNotEmpty) {
      _subTitle(doc, 'Coffrets / Armoires');
      for (int k = 0; k < local.coffrets.length; k++) {
        _addCoffretDetails(doc, local.coffrets[k], k + 1, photos);
      }
    }
    if (local.observationsLibres.isNotEmpty) {
      _subTitle(doc, 'Observations');
      _addObservationsTable(doc, local.observationsLibres);
    }
  }

  static void _addCelluleDetails(Document doc, Cellule c, List<String> photos) {
    photos.addAll(c.photos);
    doc.addParagraph(Paragraph.heading('Cellule : ${c.fonction}', level: 6));
    doc.addTable(Table(rows: [
      _headerRow(['Champ', 'Valeur']),
      _dataRow(['Fonction', c.fonction]),
      _dataRow(['Type', c.type]),
      _dataRow(['Marque / Modèle / Année', c.marqueModeleAnnee]),
      _dataRow(['Tension assignée', c.tensionAssignee]),
      _dataRow(['Pouvoir de coupure', c.pouvoirCoupure]),
      _dataRow(['Numérotation', c.numerotation]),
      _dataRow(['Parafoudres', c.parafoudres]),
    ], borders: TableBorders.all()));

    if (c.elementsVerifies.isNotEmpty) {
      _subTitle(doc, 'Éléments vérifiés de la cellule');
      _addElementsTable(doc, c.elementsVerifies);
    }
  }

  static void _addTransformateurDetails(Document doc, TransformateurMTBT t, List<String> photos) {
    photos.addAll(t.photos);
    doc.addParagraph(Paragraph.heading('Transformateur', level: 6));
    doc.addTable(Table(rows: [
      _headerRow(['Champ', 'Valeur']),
      _dataRow(['Type', t.typeTransformateur]),
      _dataRow(['Marque / Année', t.marqueAnnee]),
      _dataRow(['Puissance assignée', t.puissanceAssignee]),
      _dataRow(['Tension primaire / secondaire', t.tensionPrimaireSecondaire]),
      _dataRow(['Relais Buchholz', t.relaisBuchholz]),
      _dataRow(['Type de refroidissement', t.typeRefroidissement]),
      _dataRow(['Régime du neutre', t.regimeNeutre]),
    ], borders: TableBorders.all()));

    if (t.elementsVerifies.isNotEmpty) {
      _subTitle(doc, 'Éléments vérifiés du transformateur');
      _addElementsTable(doc, t.elementsVerifies);
    }
  }

  static void _addCoffretDetails(Document doc, CoffretArmoire coffret, int idx, List<String> photos) {
    photos.addAll(coffret.photos);
    photos.addAll(coffret.photosExternes);
    photos.addAll(coffret.photosInternes);

    doc.addParagraph(Paragraph.heading('Équipement $idx : ${coffret.nom} (${coffret.type})', level: 7));

    // Informations générales — alignées sur le PDF
    final infoRows = <TableRow>[
      _headerRow(['Champ', 'Valeur', 'Champ', 'Valeur']),
      TableRow(cells: [
        TableCell.text('Nom', backgroundColor: _headerBg),
        TableCell.text(coffret.nom),
        TableCell.text('Type', backgroundColor: _headerBg),
        TableCell.text(coffret.type),
      ]),
      TableRow(cells: [
        TableCell.text('N° Équipement', backgroundColor: _headerBg),
        TableCell.text(coffret.numeroEquipement ?? '-'),
        TableCell.text('Repère', backgroundColor: _headerBg),
        TableCell.text(coffret.repere ?? '-'),
      ]),
      TableRow(cells: [
        TableCell.text('Domaine de tension', backgroundColor: _headerBg),
        TableCell.text(coffret.domaineTension),
        TableCell.text('Zone ATEX', backgroundColor: _headerBg),
        TableCell.text(coffret.zoneAtex ? 'OUI' : 'NON'),
      ]),
      TableRow(cells: [
        TableCell.text('Identification armoire', backgroundColor: _headerBg),
        TableCell.text(coffret.identificationArmoire ? 'OUI' : 'NON'),
        TableCell.text('Signalisation danger', backgroundColor: _headerBg),
        TableCell.text(coffret.signalisationDanger ? 'OUI' : 'NON'),
      ]),
      TableRow(cells: [
        TableCell.text('Présence schéma', backgroundColor: _headerBg),
        TableCell.text(coffret.presenceSchema ? 'OUI' : 'NON'),
        TableCell.text('Présence parafoudre', backgroundColor: _headerBg),
        TableCell.text(coffret.presenceParafoudre ? 'OUI' : 'NON'),
      ]),
      TableRow(cells: [
        TableCell.text('Vérif. thermographie', backgroundColor: _headerBg),
        TableCell.text(coffret.verificationThermographie ? 'OUI' : 'NON'),
        TableCell.text('Statut', backgroundColor: _headerBg),
        TableCell.text(coffret.statut),
      ]),
    ];
    if (coffret.description?.isNotEmpty == true) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Description', backgroundColor: _headerBg),
        TableCell.text(coffret.description!),
        TableCell.text('QR Code', backgroundColor: _headerBg),
        TableCell.text(coffret.qrCode),
      ]));
    }
    doc.addTable(Table(rows: infoRows, borders: TableBorders.all()));

    // Alimentations
    if (coffret.alimentations.isNotEmpty) {
      _subTitle(doc, 'Alimentations');
      final alimentRows = <TableRow>[
        _headerRow(['Source', 'Type protection', 'PDC (kA)', 'Calibre (A)', 'Section (mm²)']),
        for (final a in coffret.alimentations)
          TableRow(cells: [
            TableCell.text(a.source.isNotEmpty ? a.source : '-'),
            TableCell.text(a.typeProtection),
            TableCell.text(a.pdcKA),
            TableCell.text(a.calibre),
            TableCell.text(a.sectionCable),
          ]),
      ];
      doc.addTable(Table(rows: alimentRows, borders: TableBorders.all()));
    }

    // Protection de tête
    if (coffret.protectionTete != null) {
      final pt = coffret.protectionTete!;
      _subTitle(doc, 'Protection de tête');
      doc.addTable(Table(rows: [
        _headerRow(['Type protection', 'PDC (kA)', 'Calibre', 'Section câble']),
        TableRow(cells: [
          TableCell.text(pt.typeProtection),
          TableCell.text(pt.pdcKA),
          TableCell.text(pt.calibre),
          TableCell.text(pt.sectionCable),
        ]),
      ], borders: TableBorders.all()));
    }

    // Points de vérification
    if (coffret.pointsVerification.isNotEmpty) {
      _subTitle(doc, 'Points de vérification');
      final pvRows = <TableRow>[
        _headerRow(['Point de vérification', 'Conformité', 'Observation', 'Réf. normative', 'Priorité']),
        for (final p in coffret.pointsVerification)
          TableRow(cells: [
            TableCell.text(p.pointVerification),
            TableCell.text(p.conformite,
                backgroundColor: p.conformite == 'oui'
                    ? _green
                    : p.conformite == 'non'
                        ? _red
                        : _orange),
            TableCell.text(p.observation ?? '-'),
            TableCell.text(p.referenceNormative ?? '-'),
            TableCell.text(p.priorite?.toString() ?? '-'),
          ]),
      ];
      doc.addTable(Table(rows: pvRows, borders: TableBorders.all()));
    }

    // Observations parafoudre
    if (coffret.presenceParafoudre && coffret.observationsParafoudre.isNotEmpty) {
      _subTitle(doc, 'Observations parafoudre');
      _addObservationsTable(doc, coffret.observationsParafoudre);
    }

    // Observations libres
    if (coffret.observationsLibres.isNotEmpty) {
      _subTitle(doc, 'Observations');
      _addObservationsTable(doc, coffret.observationsLibres);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  9. CLASSEMENT DES EMPLACEMENTS
  // ═══════════════════════════════════════════════════════════════
  static void _addClassementEmplacements(
      Document doc, List<ClassementEmplacement> classements, List<ClassementZone> classementsZones) {
    _sectionTitle(doc, 'CLASSEMENT DES EMPLACEMENTS', level: 1, pageBreak: true);

    // Zones
    if (classementsZones.isNotEmpty) {
      _subTitle(doc, 'Classement des zones');
      final rows = <TableRow>[
        _headerRow(['Zone', 'Type', 'Origine', 'AF', 'BE', 'AE', 'AD', 'AG', 'IP', 'IK']),
        for (final z in classementsZones)
          TableRow(cells: [
            TableCell.text(z.nomZone),
            TableCell.text(z.typeZone),
            TableCell.text(z.origineClassement),
            TableCell.text(z.af ?? '-'),
            TableCell.text(z.be ?? '-'),
            TableCell.text(z.ae ?? '-'),
            TableCell.text(z.ad ?? '-'),
            TableCell.text(z.ag ?? '-'),
            TableCell.text(z.ip ?? '-'),
            TableCell.text(z.ik ?? '-'),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }

    // Emplacements
    if (classements.isEmpty) {
      _bodyText(doc, 'Aucun classement d\'emplacement disponible.');
      return;
    }
    _subTitle(doc, 'Classement des locaux');
    final rows = <TableRow>[
      _headerRow(['Localisation', 'Zone', 'Type', 'Origine', 'AF', 'BE', 'AE', 'AD', 'AG', 'IP', 'IK']),
      for (final e in classements)
        TableRow(cells: [
          TableCell.text(e.localisation),
          TableCell.text(e.zone ?? '-'),
          TableCell.text(e.typeLocal ?? '-'),
          TableCell.text(e.origineClassement),
          TableCell.text(e.af ?? '-'),
          TableCell.text(e.be ?? '-'),
          TableCell.text(e.ae ?? '-'),
          TableCell.text(e.ad ?? '-'),
          TableCell.text(e.ag ?? '-'),
          TableCell.text(e.ip ?? '-'),
          TableCell.text(e.ik ?? '-'),
        ]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  10. CODIFICATION DES INFLUENCES EXTERNES
  // ═══════════════════════════════════════════════════════════════
  static void _addCodificationInfluences(Document doc) {
    _sectionTitle(doc, 'CODIFICATION DES INFLUENCES EXTERNES', level: 1, pageBreak: true);

    _bodyText(doc,
      'Conformément à la norme NF C 15-100, le classement des influences externes est défini '
      'par une combinaison de lettres et de chiffres caractérisant chaque paramètre. '
      'Le tableau ci-dessous présente les principaux codes utilisés dans ce rapport.');

    final rows = <TableRow>[
      _headerRow(['Code', 'Désignation', 'Valeurs']),
      _dataRow(['AF', 'Altitude', 'AF1: ≤2000m, AF2: >2000m']),
      _dataRow(['BE', 'Compétences des personnes', 'BE1: Ordinaires, BE2: Enfants, BE3: Handicapées, BE4: Qualifiées']),
      _dataRow(['AE', 'Présence d\'eau', 'AE1: Négligeable, AE2: Chutes, AE3: Aspersion, AE4: Projection, AE5: Jets, AE6: Paquets de mer, AE7: Immersion, AE8: Submersion']),
      _dataRow(['AD', 'Présence de substances solides', 'AD1: Négligeable, AD2: Risque de chute, AD3: Poussières importantes, AD4: Milieu corrosif']),
      _dataRow(['AG', 'Chocs mécaniques', 'AG1: Faibles, AG2: Moyens, AG3: Importants']),
      _dataRow(['IP', 'Degré de protection', 'IP00 à IP68 selon IEC 60529']),
      _dataRow(['IK', 'Résistance aux chocs', 'IK00 à IK10 selon EN 50102']),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  11. FOUDRE
  // ═══════════════════════════════════════════════════════════════
  static void _addObservationsFoudre(Document doc, List<Foudre> foudres) {
    _sectionTitle(doc, 'PROTECTION CONTRE LA FOUDRE', level: 1, pageBreak: true);

    if (foudres.isEmpty) {
      _bodyText(doc, 'Aucune observation foudre disponible.');
      return;
    }

    foudres.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));
    final rows = <TableRow>[
      _headerRow(['Priorité', 'Observation']),
      for (final f in foudres)
        TableRow(cells: [
          TableCell.text(
            f.niveauPriorite.toString(),
            backgroundColor: f.niveauPriorite == 3 ? _red
                : f.niveauPriorite == 2 ? _orange
                : _green,
          ),
          TableCell.text(f.observation),
        ]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  12. MESURES ET ESSAIS
  // ═══════════════════════════════════════════════════════════════
  static void _addMesuresEssais(Document doc, MesuresEssais mesures, List<String> allPhotos) {
    _sectionTitle(doc, 'MESURES ET ESSAIS', level: 1, pageBreak: true);

    // Conditions de mesure
    if (mesures.conditionMesure.observation?.isNotEmpty == true) {
      _subTitle(doc, 'Conditions de mesure');
      doc.addTable(Table(rows: [
        _headerRow(['Conditions de mesure']),
        TableRow(cells: [TableCell.text(mesures.conditionMesure.observation!)]),
      ], borders: TableBorders.all()));
    }

    // Essais démarrage auto
    if (mesures.essaiDemarrageAuto.observation?.isNotEmpty == true) {
      _subTitle(doc, 'Essais de démarrage automatique du groupe électrogène');
      doc.addTable(Table(rows: [
        _headerRow(['Résultat']),
        TableRow(cells: [TableCell.text(mesures.essaiDemarrageAuto.observation!)]),
      ], borders: TableBorders.all()));
    }

    // Test arrêt urgence
    if (mesures.testArretUrgence.observation?.isNotEmpty == true) {
      _subTitle(doc, 'Test de fonctionnement de l\'arrêt d\'urgence');
      doc.addTable(Table(rows: [
        _headerRow(['Résultat']),
        TableRow(cells: [TableCell.text(mesures.testArretUrgence.observation!)]),
      ], borders: TableBorders.all()));
    }

    // Prises de terre
    if (mesures.prisesTerre.isNotEmpty) {
      _subTitle(doc, 'Prises de terre');
      final rows = <TableRow>[
        _headerRow(['Localisation', 'Identification', 'Condition', 'Nature', 'Méthode', 'Valeur (Ω)', 'Observation']),
        for (final pt in mesures.prisesTerre)
          TableRow(cells: [
            TableCell.text(pt.localisation),
            TableCell.text(pt.identification),
            TableCell.text(pt.conditionPriseTerre),
            TableCell.text(pt.naturePriseTerre),
            TableCell.text(pt.methodeMesure),
            TableCell.text(pt.valeurMesure?.toStringAsFixed(2) ?? '-'),
            TableCell.text(pt.observation ?? '-'),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }

    // Avis mesures terre
    if (mesures.avisMesuresTerre.observation?.isNotEmpty == true) {
      _subTitle(doc, 'Avis sur les mesures');
      if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty) {
        doc.addTable(Table(rows: [
          _headerRow(['Prises de terre satisfaisantes']),
          for (final s in mesures.avisMesuresTerre.satisfaisants)
            TableRow(cells: [TableCell.text('• $s')]),
        ], borders: TableBorders.all()));
      }
      if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty) {
        doc.addTable(Table(rows: [
          _headerRow(['Prises de terre non satisfaisantes']),
          for (final s in mesures.avisMesuresTerre.nonSatisfaisants)
            TableRow(cells: [TableCell.text('• $s')]),
        ], borders: TableBorders.all()));
      }
      doc.addTable(Table(rows: [
        _headerRow(['Avis général']),
        TableRow(cells: [TableCell.text(mesures.avisMesuresTerre.observation!)]),
      ], borders: TableBorders.all()));
    }

    // Essais déclenchement différentiels
    if (mesures.essaisDeclenchement.isNotEmpty) {
      _subTitle(doc, 'Essais de déclenchement des dispositifs différentiels');
      final rows = <TableRow>[
        _headerRow(['Localisation', 'Coffret', 'Circuit', 'Type', 'IΔn (mA)', 'Tempo (s)', 'Isolement (MΩ)', 'Essai', 'Observation']),
        for (final e in mesures.essaisDeclenchement)
          TableRow(cells: [
            TableCell.text(e.localisation),
            TableCell.text(e.coffret ?? '-'),
            TableCell.text(e.designationCircuit ?? '-'),
            TableCell.text(e.typeDispositif),
            TableCell.text(e.reglageIAn?.toString() ?? '-'),
            TableCell.text(e.tempo?.toString() ?? '-'),
            TableCell.text(e.isolement?.toString() ?? '-'),
            TableCell.text(e.essai,
                backgroundColor: e.essai == 'B' ? _green : e.essai == 'M' ? _red : _altBg),
            TableCell.text(e.observation ?? '-'),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));

      // Statistiques
      final stats = _calculateEssaisStats(mesures.essaisDeclenchement);
      doc.addTable(Table(rows: [
        _headerRow(['Statistique', 'Valeur']),
        _dataRow(['Total essais', stats['total'].toString()]),
        _dataRow(['Essais réussis (B)', stats['bon'].toString()]),
        _dataRow(['Essais non réussis (M)', stats['mauvais'].toString()]),
        _dataRow(['Non essayés (NE)', stats['non_essaye'].toString()]),
      ], borders: TableBorders.all()));
    }

    // Continuité et résistance
    if (mesures.continuiteResistances.isNotEmpty) {
      _subTitle(doc, 'Continuité et résistance des conducteurs de protection');
      final rows = <TableRow>[
        _headerRow(['Localisation', 'Désignation tableau', 'Origine mesure', 'Observation']),
        for (final c in mesures.continuiteResistances)
          TableRow(cells: [
            TableCell.text(c.localisation),
            TableCell.text(c.designationTableau),
            TableCell.text(c.origineMesure),
            TableCell.text(c.observation ?? '-'),
          ]),
      ];
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  13. PAGE DE SIGNATURE
  // ═══════════════════════════════════════════════════════════════
  static void _addSignaturePage(Document doc, RenseignementsGeneraux? rg, String? nomInspecteur) {
    _sectionTitle(doc, 'SIGNATURE ET APPROBATION', level: 1, pageBreak: true);

    doc.addParagraph(Paragraph.text('Fait à Douala le ${_formatDate(DateTime.now())}'));
    doc.addParagraph(Paragraph.text(''));

    final rows = <TableRow>[
      _headerRow(['LA DIRECTION', 'L\'INSPECTEUR']),
      TableRow(cells: [
        TableCell.text('\n\n\n\nSignature et cachet'),
        TableCell.text(nomInspecteur != null ? '\n\n\n\n$nomInspecteur' : '\n\n\n\nSignature'),
      ]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  14. ANNEXES PHOTOS
  // ═══════════════════════════════════════════════════════════════
  static void _addAnnexesPhotos(Document doc, List<String> allPhotos) {
    _sectionTitle(doc, 'ANNEXES — PHOTOS', level: 1, pageBreak: true);
    _bodyText(doc, 'Liste des photos prises lors de l\'audit :');

    final rows = <TableRow>[
      _headerRow(['N°', 'Fichier', 'Description']),
    ];

    for (int i = 0; i < allPhotos.length; i++) {
      final fileName = allPhotos[i].split('/').last;
      String desc = 'Photo d\'audit';
      if (fileName.contains('zone')) {
        desc = 'Photo de zone';
      // ignore: curly_braces_in_flow_control_structures
      } else if (fileName.contains('local')) desc = 'Photo de local';
      else if (fileName.contains('coffret')) desc = 'Photo de coffret';
      else if (fileName.contains('transformateur')) desc = 'Photo de transformateur';
      else if (fileName.contains('cellule')) desc = 'Photo de cellule';
      rows.add(_dataRow(['${i + 1}', fileName, desc]));
    }
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS TABLEAUX
  // ═══════════════════════════════════════════════════════════════
  static void _addInstallationItemsTable(Document doc, List<InstallationItem> items) {
    if (items.isEmpty) return;
    // Ordre naturel des champs depuis description_installations_sequence
    final orderedKeys = [
      'Gamme De Cellule', 'Type De Cellule', 'Calibre Du Disjoncteur', 'Section Du Cable',
      'Nature Du Reseau', 'Observations', 'Puissance Transformateur', 'Tension', 'Intensite',
      'Puissance (Kva)', 'Capacite', 'Mode', 'Annee De Fabrication', "Annee D'Installation",
      'Marque', 'Modele',
    ];
    final allKeys = <String>{};
    for (final item in items) {
      allKeys.addAll(item.data.keys);
    }
    final sortedKeys = orderedKeys.where(allKeys.contains).toList()
      ..addAll(allKeys.where((k) => !orderedKeys.contains(k)).toList()..sort());

    final headerRow = TableRow(cells: [
      for (final k in sortedKeys) TableCell.text(k, backgroundColor: _headerBg),
    ]);
    final rows = <TableRow>[headerRow];
    for (final item in items) {
      rows.add(TableRow(cells: [
        for (final k in sortedKeys) TableCell.text(item.data[k] ?? '-'),
      ]));
    }
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  static void _addElementsTable(Document doc, List<ElementControle> elements) {
    if (elements.isEmpty) return;
    final rows = <TableRow>[
      _headerRow(['Élément de contrôle', 'Conformité', 'NA', 'Observation', 'Réf. normative', 'Priorité']),
      for (final el in elements)
        TableRow(cells: [
          TableCell.text(el.elementControle),
          TableCell.text(
            el.estNA ? 'NA' : (el.conforme == true ? 'Conforme' : el.conforme == false ? 'Non conforme' : '-'),
            backgroundColor: el.estNA ? _orange : el.conforme == true ? _green : el.conforme == false ? _red : '',
          ),
          TableCell.text(el.estNA ? 'OUI' : 'NON'),
          TableCell.text(el.observation ?? '-'),
          TableCell.text(el.referenceNormative ?? '-'),
          TableCell.text(el.priorite?.toString() ?? '-'),
        ]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  static void _addObservationsTable(Document doc, List<ObservationLibre> observations) {
    if (observations.isEmpty) return;
    final rows = <TableRow>[
      _headerRow(['N°', 'Observation']),
      for (int i = 0; i < observations.length; i++)
        _dataRow(['${i + 1}', observations[i].texte]),
    ];
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS UI
  // ═══════════════════════════════════════════════════════════════
  static void _sectionTitle(Document doc, String title,
      {int level = 1, bool center = false, bool pageBreak = false}) {
    doc.addParagraph(Paragraph.heading(title,
        level: level,
        alignment: center ? Alignment.center : Alignment.left,
        pageBreakBefore: pageBreak));
  }

  static void _subTitle(Document doc, String title) {
    doc.addParagraph(Paragraph.heading(title, level: 5));
  }

  static void _bodyText(Document doc, String text) {
    doc.addParagraph(Paragraph.text(text));
  }

  static void _bullet(Document doc, String text) {
    doc.addParagraph(Paragraph.text('• $text'));
  }

  static TableRow _headerRow(List<String> labels) => TableRow(cells: [
        for (final l in labels) TableCell.text(l, backgroundColor: _headerBg),
      ]);

  static TableRow _dataRow(List<String> values) =>
      TableRow(cells: [for (final v in values) TableCell.text(v)]);

  // ═══════════════════════════════════════════════════════════════
  //  UTILITAIRES
  // ═══════════════════════════════════════════════════════════════
  static String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static Map<String, dynamic> _calculateEssaisStats(
      List<EssaiDeclenchementDifferentiel> essais) {
    return {
      'total': essais.length,
      'bon': essais.where((e) => e.essai == 'B' || e.essai == 'OK').length,
      'mauvais': essais.where((e) => e.essai == 'M' || e.essai == 'NON OK').length,
      'non_essaye': essais.where((e) => e.essai == 'NE').length,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  //  PARTAGE / SUPPRESSION
  // ═══════════════════════════════════════════════════════════════
  static Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Rapport d\'Audit Électrique',
          text: 'Veuillez trouver ci-joint le rapport d\'audit électrique.');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur partage Word: $e');
    }
  }

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur suppression Word: $e');
    }
  }
}