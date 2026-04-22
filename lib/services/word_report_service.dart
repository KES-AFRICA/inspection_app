import 'dart:io';
import 'package:docs_gee/docs_gee.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class WordReportService {
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      // Récupérer toutes les données de la mission
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements = HiveService.getEmplacementsByMissionId(missionId);
      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres = HiveService.getFoudreObservationsByMissionId(missionId);

      // Liste pour collecter toutes les photos
      final List<String> allPhotos = [];

      // Créer le document avec marges réduites
      final doc = Document(
        title: 'Rapport d\'Audit Électrique - ${mission.nomClient}',
        author: 'Application Inspection Électrique',
        includeTableOfContents: true,
        tocTitle: 'SOMMAIRE',
        tocMaxLevel: 3,
      );

      // ==================== PAGE DE COUVERTURE ====================
      _addCoverPage(doc, mission);

      // ==================== 1. IDENTIFICATION DE LA MISSION ====================
      _addMissionIdentification(doc, mission, allPhotos);

      // ==================== 2. DESCRIPTION DES INSTALLATIONS ====================
      _addDescriptionInstallations(doc, description, missionId, allPhotos);

      // ==================== 3. AUDIT DES INSTALLATIONS ÉLECTRIQUES ====================
      _addAuditInstallations(doc, audit, missionId, allPhotos);

      // ==================== 4. CLASSEMENT DES EMPLACEMENTS ====================
      _addClassementEmplacements(doc, classements);

      // ==================== 5. MESURES ET ESSAIS ====================
      _addMesuresEssais(doc, mesures, missionId, allPhotos);

      // ==================== 6. OBSERVATIONS FOUDRES ====================
      _addObservationsFoudre(doc, foudres);

      // ==================== 7. ANNEXES - PHOTOS ====================
      if (allPhotos.isNotEmpty) {
        _addAnnexesPhotos(doc, allPhotos);
      }


      // Générer le fichier DOCX
      final bytes = DocxGenerator().generate(doc);
      
      // Sauvegarder le fichier
      final dir = await getTemporaryDirectory();
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.docx'
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      print('✅ Rapport généré: ${file.path}');
      return file;
    } catch (e, stack) {
      print('❌ Erreur génération rapport Word: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  // ==================== PAGE DE COUVERTURE ====================
  static void _addCoverPage(Document doc, Mission mission) {
    // Page de couverture centrée
    doc.addParagraph(Paragraph.heading(
      'RAPPORT D\'AUDIT ÉLECTRIQUE',
      level: 1,
      alignment: Alignment.center,
    ));
    
    doc.addParagraph(Paragraph.heading(
      mission.nomClient,
      level: 2,
      alignment: Alignment.center,
    ));
    
    doc.addParagraph(Paragraph.text(
      'Date d\'intervention: ${_formatDate(mission.dateIntervention ?? DateTime.now())}',
      alignment: Alignment.center,
    ));
    
    if (mission.natureMission != null) {
      doc.addParagraph(Paragraph.text(
        'Nature de la mission: ${mission.natureMission}',
        alignment: Alignment.center,
      ));
    }
    
    doc.addParagraph(Paragraph.text(
      'Rapport généré le: ${_formatDate(DateTime.now())}',
      alignment: Alignment.center,
    ));
  }

  // ==================== MÉTHODES D'AJOUT DE CONTENU ====================

  static void _addMissionIdentification(Document doc, Mission mission, List<String> allPhotos) {
    doc.addParagraph(Paragraph.heading('1. IDENTIFICATION DE LA MISSION', level: 1));
    
    final infoRows = [
      TableRow(cells: [
        TableCell.text('Client', backgroundColor: 'E0E0E0'),
        TableCell.text(mission.nomClient),
      ]),
    ];
    
    if (mission.activiteClient != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Activité du client'),
        TableCell.text(mission.activiteClient!),
      ]));
    }
    
    if (mission.adresseClient != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Adresse'),
        TableCell.text(mission.adresseClient!),
      ]));
    }
    
    if (mission.dgResponsable != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('DG responsable'),
        TableCell.text(mission.dgResponsable!),
      ]));
    }
    
    if (mission.dateIntervention != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Date d\'intervention'),
        TableCell.text(_formatDate(mission.dateIntervention!)),
      ]));
    }
    
    if (mission.dateRapport != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Date du rapport'),
        TableCell.text(_formatDate(mission.dateRapport!)),
      ]));
    }
    
    if (mission.natureMission != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Nature de la mission'),
        TableCell.text(mission.natureMission!),
      ]));
    }
    
    if (mission.periodicite != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Périodicité'),
        TableCell.text(mission.periodicite!),
      ]));
    }
    
    if (mission.dureeMissionJours != null) {
      infoRows.add(TableRow(cells: [
        TableCell.text('Durée de la mission'),
        TableCell.text('${mission.dureeMissionJours} jours'),
      ]));
    }
    
    doc.addTable(Table(rows: infoRows, borders: TableBorders.all()));
    
    // Documents fournis - Format tableau
    doc.addParagraph(Paragraph.heading('Documents fournis par le client', level: 2));
    
    final docsRows = [
      TableRow(cells: [
        TableCell.text('Document', backgroundColor: 'E0E0E0'),
        TableCell.text('Fourni', backgroundColor: 'E0E0E0'),
      ]),
    ];
    
    final docs = [
      {'label': 'Cahier des prescriptions', 'value': mission.docCahierPrescriptions},
      {'label': 'Notes de calculs', 'value': mission.docNotesCalculs},
      {'label': 'Schémas unifilaires', 'value': mission.docSchemasUnifilaires},
      {'label': 'Plan de masse', 'value': mission.docPlanMasse},
      {'label': 'Plans architecturaux', 'value': mission.docPlansArchitecturaux},
      {'label': 'Déclarations CE', 'value': mission.docDeclarationsCe},
      {'label': 'Liste des installations', 'value': mission.docListeInstallations},
      {'label': 'Plan des locaux à risques', 'value': mission.docPlanLocauxRisques},
      {'label': 'Rapport analyse foudre', 'value': mission.docRapportAnalyseFoudre},
      {'label': 'Rapport étude foudre', 'value': mission.docRapportEtudeFoudre},
      {'label': 'Registre de sécurité', 'value': mission.docRegistreSecurite},
      {'label': 'Rapport dernière vérification', 'value': mission.docRapportDerniereVerif},
      {'label': 'Autre document', 'value': mission.docAutre},
    ];
    
    for (var docInfo in docs) {
      docsRows.add(TableRow(cells: [
        TableCell.text(docInfo['label'] as String),
        TableCell.text(
          docInfo['value'] as bool? ?? false ? '✓ OUI' : '✗ NON', 
        ),
      ]));
    }
    
    doc.addTable(Table(rows: docsRows, borders: TableBorders.all()));
  }

static void _addDescriptionInstallations(Document doc, DescriptionInstallations? description, String missionId, List<String> allPhotos) {
  doc.addParagraph(Paragraph.heading('2. DESCRIPTION DES INSTALLATIONS', level: 1, pageBreakBefore: true));
  
  if (description == null) {
    doc.addParagraph(Paragraph.text('Aucune donnée disponible.', alignment: Alignment.center));
    return;
  }
  
  // Collecter toutes les photos de toutes les sections
  void collectPhotos(List<InstallationItem> items) {
    for (var item in items) {
      if (item.photoPaths.isNotEmpty) {
        allPhotos.addAll(item.photoPaths);
      }
    }
  }
  
  // ==================== Alimentation Moyenne Tension ====================
  if (description.alimentationMoyenneTension.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.1 Alimentation Moyenne Tension (MT)', level: 2));
    _addInstallationItemsTable(doc, description.alimentationMoyenneTension);
    collectPhotos(description.alimentationMoyenneTension);
  }
  
  // ==================== Alimentation Basse Tension ====================
  if (description.alimentationBasseTension.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.2 Alimentation Basse Tension (BT)', level: 2));
    _addInstallationItemsTable(doc, description.alimentationBasseTension);
    collectPhotos(description.alimentationBasseTension);
  }
  
  // ==================== Groupe Électrogène ====================
  if (description.groupeElectrogene.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.3 Groupe Électrogène', level: 2));
    _addInstallationItemsTable(doc, description.groupeElectrogene);
    collectPhotos(description.groupeElectrogene);
  }
  
  // ==================== Alimentation en carburant ====================
  if (description.alimentationCarburant.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.3.1 Alimentation en carburant', level: 3));
    _addInstallationItemsTable(doc, description.alimentationCarburant);
    collectPhotos(description.alimentationCarburant);
  }
  
  // ==================== Inverseur ====================
  if (description.inverseur.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.4 Inverseur', level: 2));
    _addInstallationItemsTable(doc, description.inverseur);
    collectPhotos(description.inverseur);
  }
  
  // ==================== Stabilisateur ====================
  if (description.stabilisateur.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.5 Stabilisateur', level: 2));
    _addInstallationItemsTable(doc, description.stabilisateur);
    collectPhotos(description.stabilisateur);
  }
  
  // ==================== Onduleurs ====================
  if (description.onduleurs.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.6 Onduleurs', level: 2));
    _addInstallationItemsTable(doc, description.onduleurs);
    collectPhotos(description.onduleurs);
  }
  
  // ==================== Sélections diverses ====================
  final selections = <Map<String, String?>>[];
  
  if (description.regimeNeutre != null) {
    selections.add({'Caractéristique': 'Régime du neutre', 'Valeur': description.regimeNeutre});
  }
  
  if (description.eclairageSecurite != null) {
    selections.add({'Caractéristique': 'Éclairage de sécurité', 'Valeur': description.eclairageSecurite});
  }
  
  if (description.modificationsInstallations != null) {
    selections.add({'Caractéristique': 'Modifications des installations', 'Valeur': description.modificationsInstallations});
  }
  
  if (description.noteCalcul != null) {
    selections.add({'Caractéristique': 'Note de calcul', 'Valeur': description.noteCalcul});
  }
  
  if (description.registreSecurite != null) {
    selections.add({'Caractéristique': 'Registre de sécurité', 'Valeur': description.registreSecurite});
  }
  
  if (description.presenceParatonnerre != null) {
    selections.add({'Caractéristique': 'Présence de paratonnerre', 'Valeur': description.presenceParatonnerre});
  }
  
  if (description.analyseRisqueFoudre != null) {
    selections.add({'Caractéristique': 'Analyse risque foudre', 'Valeur': description.analyseRisqueFoudre});
  }
  
  if (description.etudeTechniqueFoudre != null) {
    selections.add({'Caractéristique': 'Étude technique foudre', 'Valeur': description.etudeTechniqueFoudre});
  }
  
  if (selections.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('2.7 Caractéristiques générales', level: 2));
    
    final headerRow = TableRow(cells: [
      TableCell.text('Caractéristique', backgroundColor: 'E0E0E0'),
      TableCell.text('Valeur', backgroundColor: 'E0E0E0'),
    ]);
    
    final rows = [headerRow];
    
    for (var selection in selections) {
      rows.add(TableRow(cells: [
        TableCell.text(selection['Caractéristique']!),
        TableCell.text(selection['Valeur']!),
      ]));
    }
    
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
  }
}

static void _addInstallationItemsTable(Document doc, List<InstallationItem> items) {
  if (items.isEmpty) return;
  
  // Extraire tous les champs uniques de tous les items
  final fields = <String>{};
  for (var item in items) {
    fields.addAll(item.data.keys);
  }
  
  // Trier les champs pour un affichage cohérent
  final sortedFields = fields.toList()..sort();
  
  // Créer l'en-tête du tableau
  final headerRow = TableRow(cells: [
    for (var field in sortedFields)
      TableCell.text(field, backgroundColor: 'E0E0E0'),
  ]);
  
  final rows = [headerRow];
  
  // Ajouter chaque item comme ligne
  for (var item in items) {
    rows.add(TableRow(cells: [
      for (var field in sortedFields)
        TableCell.text(item.data[field] ?? '-'),
    ]));
  }
  
  doc.addTable(Table(rows: rows, borders: TableBorders.all()));
}

// ==================== MÉTHODE UTILITAIRE ====================

static void _addCardsTable(Document doc, List<Map<String, String>> cards) {
  if (cards.isEmpty) return;
  
  // Extraire tous les champs uniques
  final fields = <String>{};
  for (var card in cards) {
    fields.addAll(card.keys);
  }
  
  final sortedFields = fields.toList()..sort();
  
  final headerRow = TableRow(cells: [
    for (var field in sortedFields)
      TableCell.text(field, backgroundColor: 'E0E0E0'),
  ]);
  
  final rows = [headerRow];
  
  for (var card in cards) {
    rows.add(TableRow(cells: [
      for (var field in sortedFields)
        TableCell.text(card[field] ?? '-'),
    ]));
  }
  
  doc.addTable(Table(rows: rows, borders: TableBorders.all()));
}
static void _addAuditInstallations(Document doc, AuditInstallationsElectriques? audit, String missionId, List<String> allPhotos) {
  doc.addParagraph(Paragraph.heading('3. AUDIT DES INSTALLATIONS ÉLECTRIQUES', level: 1, pageBreakBefore: true));
  
  if (audit == null) {
    doc.addParagraph(Paragraph.text('Aucune donnée d\'audit disponible.', alignment: Alignment.center));
    return;
  }
  
  // Collecter les photos dans la liste globale
  if (audit.photos.isNotEmpty) {
    allPhotos.addAll(audit.photos);
  }
  
  // ==================== MOYENNE TENSION ====================
  if (audit.moyenneTensionLocaux.isNotEmpty || audit.moyenneTensionZones.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('3.1 MOYENNE TENSION', level: 2));
    
    // Locaux MT
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('3.1.1 Locaux Moyenne Tension', level: 3));
      
      for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
        final local = audit.moyenneTensionLocaux[i];
        _addLocalMTDetails(doc, local, i + 1, allPhotos);
      }
    }
    
    // Zones MT
    if (audit.moyenneTensionZones.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('3.1.2 Zones Moyenne Tension', level: 3));
      
      for (int i = 0; i < audit.moyenneTensionZones.length; i++) {
        final zone = audit.moyenneTensionZones[i];
        _addZoneMTDetails(doc, zone, i + 1, allPhotos);
      }
    }
  }
  
  // ==================== BASSE TENSION ====================
  if (audit.basseTensionZones.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('3.2 BASSE TENSION', level: 2, pageBreakBefore: true));
    
    for (int i = 0; i < audit.basseTensionZones.length; i++) {
      final zone = audit.basseTensionZones[i];
      _addZoneBTDetails(doc, zone, i + 1, allPhotos);
    }
  }

}

static void _addLocalMTDetails(Document doc, MoyenneTensionLocal local, int index, List<String> allPhotos) {
  // Collecter les photos
  if (local.photos.isNotEmpty) {
    allPhotos.addAll(local.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Local MT ${index}: ${local.nom} (${local.type})', level: 4));
  
  // Tableau d'identification du local
  final localInfoRows = [
    TableRow(cells: [
      TableCell.text('Nom du local', backgroundColor: 'E0E0E0'),
      TableCell.text(local.nom),
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text(local.type),
    ]),
  ];
  
  doc.addTable(Table(rows: localInfoRows, borders: TableBorders.all()));
  
  // Dispositions constructives
  if (local.dispositionsConstructives.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Dispositions constructives', level: 5));
    _addElementsTableWithNormes(doc, local.dispositionsConstructives);
  }
  
  // Conditions d'exploitation
  if (local.conditionsExploitation.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Conditions d\'exploitation', level: 5));
    _addElementsTableWithNormes(doc, local.conditionsExploitation);
  }
  
  // Cellule
  if (local.cellule != null) {
    _addCelluleDetails(doc, local.cellule!, allPhotos);
  }
  
  // Transformateur
  if (local.transformateur != null) {
    _addTransformateurDetails(doc, local.transformateur!, allPhotos);
  }
  
  // Coffrets dans le local
  if (local.coffrets.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Coffrets/Armoires dans le local', level: 5));
    for (int j = 0; j < local.coffrets.length; j++) {
      final coffret = local.coffrets[j];
      _addCoffretDetails(doc, coffret, j + 1, allPhotos);
    }
  }
  
  // Observations 
  if (local.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations du local', level: 5));
    _addObservationsTable(doc, local.observationsLibres);
  }
}

static void _addZoneMTDetails(Document doc, MoyenneTensionZone zone, int index, List<String> allPhotos) {
  // Collecter les photos de la zone
  if (zone.photos.isNotEmpty) {
    allPhotos.addAll(zone.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Zone MT ${index}: ${zone.nom}', level: 4));
  
  // Tableau d'identification de la zone
  final zoneInfoRows = [
    TableRow(cells: [
      TableCell.text('Nom de la zone', backgroundColor: 'E0E0E0'),
      TableCell.text(zone.nom),
    ]),
  ];
  
  if (zone.description != null) {
    zoneInfoRows.add(TableRow(cells: [
      TableCell.text('Description', backgroundColor: 'E0E0E0'),
      TableCell.text(zone.description!),
    ]));
  }
  
  doc.addTable(Table(rows: zoneInfoRows, borders: TableBorders.all()));
  
  // Coffrets dans la zone
  if (zone.coffrets.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Coffrets/Armoires dans la zone', level: 5));
    for (int j = 0; j < zone.coffrets.length; j++) {
      final coffret = zone.coffrets[j];
      _addCoffretDetails(doc, coffret, j + 1, allPhotos);
    }
  }
  
  // Observations de la zone
  if (zone.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations de la zone', level: 5));
    _addObservationsTable(doc, zone.observationsLibres);
  }
  
  // Locaux dans la zone
  if (zone.locaux.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Locaux dans la zone', level: 5));
    
    for (int j = 0; j < zone.locaux.length; j++) {
      final local = zone.locaux[j];
      _addLocalDansZoneDetails(doc, local, j + 1, allPhotos);
    }
  }
}

static void _addZoneBTDetails(Document doc, BasseTensionZone zone, int index, List<String> allPhotos) {
  // Collecter les photos de la zone
  if (zone.photos.isNotEmpty) {
    allPhotos.addAll(zone.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Zone BT ${index}: ${zone.nom}', level: 3));
  
  // Tableau d'identification de la zone
  final zoneInfoRows = [
    TableRow(cells: [
      TableCell.text('Nom de la zone', backgroundColor: 'E0E0E0'),
      TableCell.text(zone.nom),
    ]),
  ];
  
  if (zone.description != null) {
    zoneInfoRows.add(TableRow(cells: [
      TableCell.text('Description', backgroundColor: 'E0E0E0'),
      TableCell.text(zone.description!),
    ]));
  }
  
  doc.addTable(Table(rows: zoneInfoRows, borders: TableBorders.all()));
  
  // Coffrets directs dans la zone
  if (zone.coffretsDirects.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Coffrets/Armoires directs dans la zone', level: 4));
    for (int j = 0; j < zone.coffretsDirects.length; j++) {
      final coffret = zone.coffretsDirects[j];
      _addCoffretDetails(doc, coffret, j + 1, allPhotos);
    }
  }
  
  // Observations de la zone
  if (zone.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations de la zone', level: 4));
    _addObservationsTable(doc, zone.observationsLibres);
  }
  
  // Locaux dans la zone
  if (zone.locaux.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Locaux dans la zone', level: 4));
    
    for (int j = 0; j < zone.locaux.length; j++) {
      final local = zone.locaux[j];
      _addLocalBTDansZoneDetails(doc, local, j + 1, allPhotos);
    }
  }
}

static void _addLocalDansZoneDetails(Document doc, MoyenneTensionLocal local, int index, List<String> allPhotos) {
  // Collecter photos du local
  if (local.photos.isNotEmpty) {
    allPhotos.addAll(local.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Local dans zone ${index}: ${local.nom}', level: 6));
  
  // Tableau d'identification du local
  final localInfoRows = [
    TableRow(cells: [
      TableCell.text('Nom du local', backgroundColor: 'E0E0E0'),
      TableCell.text(local.nom),
    ]),
  ];
  
  doc.addTable(Table(rows: localInfoRows, borders: TableBorders.all()));
  
  // Coffrets dans le local
  if (local.coffrets.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Coffrets/Armoires dans le local', level: 7));
    for (int k = 0; k < local.coffrets.length; k++) {
      final coffret = local.coffrets[k];
      _addCoffretDetails(doc, coffret, k + 1, allPhotos);
    }
  }
  
  // Observations du local
  if (local.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations du local', level: 7));
    _addObservationsTable(doc, local.observationsLibres);
  }
}

static void _addLocalBTDansZoneDetails(Document doc, BasseTensionLocal local, int index, List<String> allPhotos) {
  // Collecter photos du local
  if (local.photos.isNotEmpty) {
    allPhotos.addAll(local.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Local BT ${index}: ${local.nom} (${local.type})', level: 5));
  
  // Tableau d'identification du local
  final localInfoRows = [
    TableRow(cells: [
      TableCell.text('Nom du local', backgroundColor: 'E0E0E0'),
      TableCell.text(local.nom),
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text(local.type),
    ]),
  ];
  
  doc.addTable(Table(rows: localInfoRows, borders: TableBorders.all()));
  
  // Dispositions constructives
  if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Dispositions constructives', level: 6));
    _addElementsTableWithNormes(doc, local.dispositionsConstructives!);
  }
  
  // Conditions d'exploitation
  if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Conditions d\'exploitation', level: 6));
    _addElementsTableWithNormes(doc, local.conditionsExploitation!);
  }
  
  // Coffrets dans le local
  if (local.coffrets.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Coffrets/Armoires dans le local', level: 6));
    for (int k = 0; k < local.coffrets.length; k++) {
      final coffret = local.coffrets[k];
      _addCoffretDetails(doc, coffret, k + 1, allPhotos);
    }
  }
  
  // Observations du local
  if (local.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations du local', level: 6));
    _addObservationsTable(doc, local.observationsLibres);
  }
}

static void _addCelluleDetails(Document doc, Cellule cellule, List<String> allPhotos) {
  // Collecter photos cellule
  if (cellule.photos.isNotEmpty) {
    allPhotos.addAll(cellule.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Cellule', level: 5));
  
  final celluleInfoRows = [
    TableRow(cells: [
      TableCell.text('Fonction', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.fonction),
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.type),
    ]),
    TableRow(cells: [
      TableCell.text('Marque/Modèle/Année', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.marqueModeleAnnee),
      TableCell.text('Tension assignée', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.tensionAssignee),
    ]),
    TableRow(cells: [
      TableCell.text('Pouvoir de coupure', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.pouvoirCoupure),
      TableCell.text('Numérotation', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.numerotation),
    ]),
    TableRow(cells: [
      TableCell.text('Parafoudres', backgroundColor: 'E0E0E0'),
      TableCell.text(cellule.parafoudres),
    ]),
  ];
  
  doc.addTable(Table(rows: celluleInfoRows, borders: TableBorders.all()));
  
  if (cellule.elementsVerifies.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Éléments vérifiés de la cellule', level: 6));
    _addElementsTableWithNormes(doc, cellule.elementsVerifies);
  }
}

static void _addTransformateurDetails(Document doc, TransformateurMTBT transformateur, List<String> allPhotos) {
  // Collecter photos transformateur
  if (transformateur.photos.isNotEmpty) {
    allPhotos.addAll(transformateur.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Transformateur', level: 5));
  
  final transformateurInfoRows = [
    TableRow(cells: [
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.typeTransformateur),
      TableCell.text('Marque/Année', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.marqueAnnee),
    ]),
    TableRow(cells: [
      TableCell.text('Puissance assignée', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.puissanceAssignee),
      TableCell.text('Tension primaire/secondaire', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.tensionPrimaireSecondaire),
    ]),
    TableRow(cells: [
      TableCell.text('Relais Buchholz', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.relaisBuchholz),
      TableCell.text('Type de refroidissement', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.typeRefroidissement),
    ]),
    TableRow(cells: [
      TableCell.text('Régime du neutre', backgroundColor: 'E0E0E0'),
      TableCell.text(transformateur.regimeNeutre),
    ]),
  ];
  
  doc.addTable(Table(rows: transformateurInfoRows, borders: TableBorders.all()));
  
  if (transformateur.elementsVerifies.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Éléments vérifiés du transformateur', level: 6));
    _addElementsTableWithNormes(doc, transformateur.elementsVerifies);
  }
}

static void _addCoffretDetails(Document doc, CoffretArmoire coffret, int index, List<String> allPhotos) {
  // Collecter les photos du coffret
  if (coffret.photos.isNotEmpty) {
    allPhotos.addAll(coffret.photos);
  }
  
  doc.addParagraph(Paragraph.heading('Coffret ${index}: ${coffret.nom} (${coffret.type})', level: 7));
  
  // Tableau d'identification du coffret
  final infoRows = [
    TableRow(cells: [
      TableCell.text('Nom', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.nom),
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.type),
    ]),
  ];
  
  if (coffret.qrCode.isNotEmpty) {
    infoRows.add(TableRow(cells: [
      TableCell.text('QR Code', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.qrCode),
    ]));
  }
  
  if (coffret.description != null) {
    infoRows.add(TableRow(cells: [
      TableCell.text('Description', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.description!),
    ]));
  }
  
  if (coffret.repere != null) {
    infoRows.add(TableRow(cells: [
      TableCell.text('Repère', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.repere!),
    ]));
  }
  
  infoRows.addAll([
    TableRow(cells: [
      TableCell.text('Zone ATEX', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.zoneAtex ? 'OUI' : 'NON'),
      TableCell.text('Domaine tension', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.domaineTension),
    ]),
    TableRow(cells: [
      TableCell.text('Identification armoire', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.identificationArmoire ? 'OUI' : 'NON'),
      TableCell.text('Signalisation danger', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.signalisationDanger ? 'OUI' : 'NON'),
    ]),
    TableRow(cells: [
      TableCell.text('Présence schéma', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.presenceSchema ? 'OUI' : 'NON'),
      TableCell.text('Présence parafoudre', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.presenceParafoudre ? 'OUI' : 'NON'),
    ]),
    TableRow(cells: [
      TableCell.text('Vérification thermographie', backgroundColor: 'E0E0E0'),
      TableCell.text(coffret.verificationThermographie ? 'OUI' : 'NON'),
    ]),
  ]);
  
  doc.addTable(Table(rows: infoRows, borders: TableBorders.all()));
  
  // Alimentations
  if (coffret.alimentations.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Alimentations', level: 8));
    
    final alimentationsRows = [
      TableRow(cells: [
        TableCell.text('Type de protection', backgroundColor: 'E0E0E0'),
        TableCell.text('PDC (kA)', backgroundColor: 'E0E0E0'),
        TableCell.text('Calibre', backgroundColor: 'E0E0E0'),
        TableCell.text('Section câble (mm²)', backgroundColor: 'E0E0E0'),
      ]),
    ];
    
    for (var alimentation in coffret.alimentations) {
      alimentationsRows.add(TableRow(cells: [
        TableCell.text(alimentation.typeProtection),
        TableCell.text(alimentation.pdcKA),
        TableCell.text(alimentation.calibre),
        TableCell.text(alimentation.sectionCable),
      ]));
    }
    
    doc.addTable(Table(rows: alimentationsRows, borders: TableBorders.all()));
  }
  
  // Protection de tête
  if (coffret.protectionTete != null) {
    final protectionRows = [
      TableRow(cells: [
        TableCell.text('Protection de tête', backgroundColor: 'E0E0E0'),
        TableCell.text('Type', backgroundColor: 'E0E0E0'),
        TableCell.text('PDC (kA)', backgroundColor: 'E0E0E0'),
      ]),
      TableRow(cells: [
        TableCell.text(''),
        TableCell.text(coffret.protectionTete!.typeProtection),
        TableCell.text(coffret.protectionTete!.pdcKA),
      ]),
    ];
    
    doc.addTable(Table(rows: protectionRows, borders: TableBorders.all()));
  }
  
  // Points de vérification
  if (coffret.pointsVerification.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Points de vérification', level: 8));
    _addPointsVerificationTable(doc, coffret.pointsVerification);
  }
  
  // Observations 
  if (coffret.observationsLibres.isNotEmpty) {
    doc.addParagraph(Paragraph.heading('Observations du coffret', level: 8));
    _addObservationsTable(doc, coffret.observationsLibres);
  }
}

static void _addPointsVerificationTable(Document doc, List<PointVerification> points) {
  final pointsRows = [
    TableRow(cells: [
      TableCell.text('Point de vérification', backgroundColor: 'E0E0E0'),
      TableCell.text('Conformité', backgroundColor: 'E0E0E0'),
      TableCell.text('Observation', backgroundColor: 'E0E0E0'),
      TableCell.text('Référence normative', backgroundColor: 'E0E0E0'),
      TableCell.text('Priorité', backgroundColor: 'E0E0E0'),
    ]),
  ];
  
  for (var point in points) {
    pointsRows.add(TableRow(cells: [
      TableCell.text(point.pointVerification),
      TableCell.text(point.conformite),
      TableCell.text(point.observation ?? '-'),
      TableCell.text(point.referenceNormative ?? '-'),
      TableCell.text(point.priorite?.toString() ?? '-'),

    ]));
  }
  
  doc.addTable(Table(rows: pointsRows, borders: TableBorders.all()));
}

static void _addObservationsTable(Document doc, List<ObservationLibre> observations) {
  if (observations.isEmpty) return;
  
  final observationsRows = [
    TableRow(cells: [
      TableCell.text('N°', backgroundColor: 'E0E0E0'),
      TableCell.text('Observation', backgroundColor: 'E0E0E0'),
    ]),
  ];
  
  for (int i = 0; i < observations.length; i++) {
    observationsRows.add(TableRow(cells: [
      TableCell.text('${i + 1}'),
      TableCell.text(observations[i].texte),
    ]));
  }
  
  doc.addTable(Table(rows: observationsRows, borders: TableBorders.all()));
}

static void _addElementsTableWithNormes(Document doc, List<ElementControle> elements) {
  if (elements.isEmpty) return;
  
  final headerRow = TableRow(cells: [
    TableCell.text('Élément de contrôle', backgroundColor: 'E0E0E0'),
    TableCell.text('Conformité', backgroundColor: 'E0E0E0'),
    TableCell.text('Observation', backgroundColor: 'E0E0E0'),
    TableCell.text('Référence normative', backgroundColor: 'E0E0E0'),
    TableCell.text('Priorité', backgroundColor: 'E0E0E0'),
  ]);
  
  final rows = [headerRow];
  
  for (var element in elements) {
    rows.add(TableRow(cells: [
      TableCell.text(element.elementControle),
      TableCell.text(element.conforme != null ? 'Conforme' : 'Non conforme'),
      TableCell.text(element.observation ?? '-'),
      TableCell.text(element.referenceNormative ?? '-'),
      TableCell.text(element.priorite?.toString() ?? '-'),
    ]));
  }
  
  doc.addTable(Table(rows: rows, borders: TableBorders.all()));
}
  static void _addClassementEmplacements(Document doc, List<ClassementEmplacement> classements) {
    doc.addParagraph(Paragraph.heading('4. CLASSEMENT DES EMPLACEMENTS', level: 1, pageBreakBefore: true));
    
    if (classements.isEmpty) {
      doc.addParagraph(Paragraph.text('Aucun classement disponible.', alignment: Alignment.center));
      return;
    }
    
    final headerRow = TableRow(cells: [
      TableCell.text('Localisation', backgroundColor: 'E0E0E0'),
      TableCell.text('Zone', backgroundColor: 'E0E0E0'),
      TableCell.text('Type', backgroundColor: 'E0E0E0'),
      TableCell.text('AF', backgroundColor: 'E0E0E0'),
      TableCell.text('BE', backgroundColor: 'E0E0E0'),
      TableCell.text('AE', backgroundColor: 'E0E0E0'),
      TableCell.text('AD', backgroundColor: 'E0E0E0'),
      TableCell.text('AG', backgroundColor: 'E0E0E0'),
      TableCell.text('IP', backgroundColor: 'E0E0E0'),
      TableCell.text('IK', backgroundColor: 'E0E0E0'),
    ]);
    
    final rows = [headerRow];
    
    for (var emp in classements) {
      rows.add(TableRow(cells: [
        TableCell.text(emp.localisation),
        TableCell.text(emp.zone ?? '-'),
        TableCell.text(emp.typeLocal ?? '-'),
        TableCell.text(emp.af ?? '-'),
        TableCell.text(emp.be ?? '-'),
        TableCell.text(emp.ae ?? '-'),
        TableCell.text(emp.ad ?? '-'),
        TableCell.text(emp.ag ?? '-'),
        TableCell.text(emp.ip ?? '-'),
        TableCell.text(emp.ik ?? '-'),
      ]));
    }
    
    doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    
  }

  static void _addMesuresEssais(Document doc, MesuresEssais? mesures, String missionId, List<String> allPhotos) {
    doc.addParagraph(Paragraph.heading('5. MESURES ET ESSAIS', level: 1, pageBreakBefore: true));
    
    if (mesures == null) {
      doc.addParagraph(Paragraph.text('Aucune mesure ou essai disponible.', alignment: Alignment.center));
      return;
    }
    
    // ==================== SECTION 1: CONDITIONS DE MESURE ====================
    if (mesures.conditionMesure.observation != null && mesures.conditionMesure.observation!.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.1 Conditions de mesure', level: 2));
      
      final conditionsRows = [
        TableRow(cells: [
          TableCell.text('Conditions de mesure', backgroundColor: 'E0E0E0'),
        ]),
        TableRow(cells: [
          TableCell.text(mesures.conditionMesure.observation!),
        ]),
      ];
      
      doc.addTable(Table(rows: conditionsRows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE ====================
    if (mesures.essaiDemarrageAuto.observation != null && mesures.essaiDemarrageAuto.observation!.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.2 Essais de démarrage automatique du groupe électrogène', level: 2));
      
      final essaisRows = [
        TableRow(cells: [
          TableCell.text('Résultat des essais', backgroundColor: 'E0E0E0'),
        ]),
        TableRow(cells: [
          TableCell.text(mesures.essaiDemarrageAuto.observation!),
        ]),
      ];
      
      doc.addTable(Table(rows: essaisRows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 3: TEST D'ARRÊT D'URGENCE ====================
    if (mesures.testArretUrgence.observation != null && mesures.testArretUrgence.observation!.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.3 Test de fonctionnement de l\'arrêt d\'urgence', level: 2));
      
      final testRows = [
        TableRow(cells: [
          TableCell.text('Résultat du test', backgroundColor: 'E0E0E0'),
        ]),
        TableRow(cells: [
          TableCell.text(mesures.testArretUrgence.observation!),
        ]),
      ];
      
      doc.addTable(Table(rows: testRows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 4: PRISES DE TERRE ====================
    if (mesures.prisesTerre.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.4 Prises de terre', level: 2));
      
      final headerRow = TableRow(cells: [
        TableCell.text('Localisation', backgroundColor: 'E0E0E0'),
        TableCell.text('Identification', backgroundColor: 'E0E0E0'),
        TableCell.text('Condition mesure', backgroundColor: 'E0E0E0'),
        TableCell.text('Nature prise terre', backgroundColor: 'E0E0E0'),
        TableCell.text('Méthode mesure', backgroundColor: 'E0E0E0'),
        TableCell.text('Valeur mesure (Ω)', backgroundColor: 'E0E0E0'),
        TableCell.text('Observation', backgroundColor: 'E0E0E0'),
      ]);
      
      final rows = [headerRow];
      
      for (var pt in mesures.prisesTerre) {
        rows.add(TableRow(cells: [
          TableCell.text(pt.localisation),
          TableCell.text(pt.identification),
          TableCell.text(pt.conditionPriseTerre),
          TableCell.text(pt.naturePriseTerre),
          TableCell.text(pt.methodeMesure),
          TableCell.text(pt.valeurMesure?.toStringAsFixed(2) ?? '-'),
          TableCell.text(pt.observation ?? '-'),
        ]));
      }
      
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 5: AVIS SUR LES MESURES ====================
    if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.5 Avis sur les mesures', level: 2));
      
      // Liste des PT satisfaisants
      if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty) {
        final satisfaisantsRows = [
          TableRow(cells: [
            TableCell.text('Prises de terre satisfaisantes', backgroundColor: 'E0E0E0'),
          ]),
        ];
        
        for (var pt in mesures.avisMesuresTerre.satisfaisants) {
          satisfaisantsRows.add(TableRow(cells: [
            TableCell.text('• $pt'),
          ]));
        }
        
        doc.addTable(Table(rows: satisfaisantsRows, borders: TableBorders.all()));
      }
      
      // Liste des PT non satisfaisants
      if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty) {
        final nonSatisfaisantsRows = [
          TableRow(cells: [
            TableCell.text('Prises de terre non satisfaisantes', backgroundColor: 'E0E0E0'),
          ]),
        ];
        
        for (var pt in mesures.avisMesuresTerre.nonSatisfaisants) {
          nonSatisfaisantsRows.add(TableRow(cells: [
            TableCell.text('• $pt'),
          ]));
        }
        
        doc.addTable(Table(rows: nonSatisfaisantsRows, borders: TableBorders.all()));
      }
      
      final avisRows = [
        TableRow(cells: [
          TableCell.text('Avis général', backgroundColor: 'E0E0E0'),
        ]),
        TableRow(cells: [
          TableCell.text(mesures.avisMesuresTerre.observation!),
        ]),
      ];
      
      doc.addTable(Table(rows: avisRows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 6: ESSAIS DÉCLENCHEMENT DIFFÉRENTIELS ====================
    if (mesures.essaisDeclenchement.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.6 Essais de déclenchement des dispositifs différentiels', level: 2));
      
      final headerRow = TableRow(cells: [
        TableCell.text('Localisation', backgroundColor: 'E0E0E0'),
        TableCell.text('Coffret', backgroundColor: 'E0E0E0'),
        TableCell.text('Désignation circuit', backgroundColor: 'E0E0E0'),
        TableCell.text('Type dispositif', backgroundColor: 'E0E0E0'),
        TableCell.text('Réglage IΔn (mA)', backgroundColor: 'E0E0E0'),
        TableCell.text('Tempo (s)', backgroundColor: 'E0E0E0'),
        TableCell.text('Isolement (MΩ)', backgroundColor: 'E0E0E0'),
        TableCell.text('Essai', backgroundColor: 'E0E0E0'),
        TableCell.text('Observation', backgroundColor: 'E0E0E0'),
      ]);
      
      final rows = [headerRow];
      
      for (var essai in mesures.essaisDeclenchement) {
        rows.add(TableRow(cells: [
          TableCell.text(essai.localisation),
          TableCell.text(essai.coffret ?? '-'),
          TableCell.text(essai.designationCircuit ?? '-'),
          TableCell.text(essai.typeDispositif),
          TableCell.text(essai.reglageIAn?.toString() ?? '-'),
          TableCell.text(essai.tempo?.toString() ?? '-'),
          TableCell.text(essai.isolement?.toString() ?? '-'),
          TableCell.text(essai.essai),
          TableCell.text(essai.observation ?? '-'),
        ]));
      }
      
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
      
      // Statistiques
      final stats = _calculateEssaisStats(mesures.essaisDeclenchement);
      final statsRows = [
        TableRow(cells: [
          TableCell.text('Statistiques', backgroundColor: 'E0E0E0'),
          TableCell.text('Valeur', backgroundColor: 'E0E0E0'),
        ]),
        TableRow(cells: [
          TableCell.text('Total essais'),
          TableCell.text(stats['total'].toString()),
        ]),
        TableRow(cells: [
          TableCell.text('Essais réussis'),
          TableCell.text(stats['bon'].toString()),
        ]),
        TableRow(cells: [
          TableCell.text('Essais non réussis'),
          TableCell.text(stats['mauvais'].toString()),
        ]),
        TableRow(cells: [
          TableCell.text('Essais non essayés'),
          TableCell.text(stats['non_essaye'].toString()),
        ]),
      ];
      
      doc.addTable(Table(rows: statsRows, borders: TableBorders.all()));
    }
    
    // ==================== SECTION 7: CONTINUITÉ ET RÉSISTANCE ====================
    if (mesures.continuiteResistances.isNotEmpty) {
      doc.addParagraph(Paragraph.heading('5.7 Continuité et résistance des conducteurs de protection', level: 2));
      
      final headerRow = TableRow(cells: [
        TableCell.text('Localisation', backgroundColor: 'E0E0E0'),
        TableCell.text('Désignation tableau', backgroundColor: 'E0E0E0'),
        TableCell.text('Origine mesure', backgroundColor: 'E0E0E0'),
        TableCell.text('Observation', backgroundColor: 'E0E0E0'),
      ]);
      
      final rows = [headerRow];
      
      for (var cont in mesures.continuiteResistances) {
        rows.add(TableRow(cells: [
          TableCell.text(cont.localisation),
          TableCell.text(cont.designationTableau),
          TableCell.text(cont.origineMesure),
          TableCell.text(cont.observation ?? '-'),
        ]));
      }
      
      doc.addTable(Table(rows: rows, borders: TableBorders.all()));
    }
  }

static void _addObservationsFoudre(Document doc, List<Foudre> foudres) {
  doc.addParagraph(Paragraph.heading('6. OBSERVATIONS FOUDRES', level: 1, pageBreakBefore: true));
  
  if (foudres.isEmpty) {
    doc.addParagraph(Paragraph.text('Aucune observation foudre disponible.', alignment: Alignment.center));
    return;
  }
  
  // Créer le tableau avec 2 colonnes
  final headerRow = TableRow(cells: [
    TableCell.text('Priorité', backgroundColor: 'E0E0E0'),
    TableCell.text('Observation', backgroundColor: 'E0E0E0'),
  ]);
  
  final rows = [headerRow];
  
  // Trier par priorité (1, 2, 3)
  foudres.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));
  
  for (var foudre in foudres) {
    rows.add(TableRow(cells: [
      TableCell.text(foudre.niveauPriorite.toString()),
      TableCell.text(foudre.observation),
    ]));
  }
  
  doc.addTable(Table(rows: rows, borders: TableBorders.all()));
}
  static void _addAnnexesPhotos(Document doc, List<String> allPhotos) {
    doc.addParagraph(Paragraph.heading('7. ANNEXES - PHOTOS', level: 1, pageBreakBefore: true));
    
    doc.addParagraph(Paragraph.text('Liste des photos prises lors de l\'audit:'));
    
    final photosRows = [
      TableRow(cells: [
        TableCell.text('N°', backgroundColor: 'E0E0E0'),
        TableCell.text('Fichier photo', backgroundColor: 'E0E0E0'),
        TableCell.text('Description', backgroundColor: 'E0E0E0'),
      ]),
    ];
    
    // Extraire seulement le nom du fichier
    for (int i = 0; i < allPhotos.length; i++) {
      final photoPath = allPhotos[i];
      final fileName = photoPath.split('/').last;
      
      // Déterminer la description basée sur le nom du fichier
      String description = 'Photo d\'audit';
      if (fileName.contains('zone')) description = 'Photo de zone';
      if (fileName.contains('local')) description = 'Photo de local';
      if (fileName.contains('coffret')) description = 'Photo de coffret';
      if (fileName.contains('transformateur')) description = 'Photo de transformateur';
      if (fileName.contains('cellule')) description = 'Photo de cellule';
      
      photosRows.add(TableRow(cells: [
        TableCell.text('${i + 1}'),
        TableCell.text(fileName),
        TableCell.text(description),
      ]));
    }
    
    doc.addTable(Table(rows: photosRows, borders: TableBorders.all()));
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static Map<String, dynamic> _calculateEssaisStats(List<EssaiDeclenchementDifferentiel> essais) {
    int total = essais.length;
    int bon = essais.where((e) => e.essai == 'B' || e.essai == 'OK').length;
    int mauvais = essais.where((e) => e.essai == 'M' || e.essai == 'NON OK').length;
    int nonEssaye = essais.where((e) => e.essai == 'NE').length;
    
    return {
      'total': total,
      'bon': bon,
      'mauvais': mauvais,
      'non_essaye': nonEssaye,
    };
  }


  // ==================== MÉTHODE DE PARTAGE ====================

  static Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
        subject: 'Rapport d\'Audit Électrique',
        text: 'Veuillez trouver ci-joint le rapport d\'audit électrique généré.',
      );
      print('✅ Rapport partagé avec succès');
    } catch (e) {
      print('❌ Erreur lors du partage: $e');
    }
  }

  // ==================== MÉTHODE DE SUPPRESSION ====================

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        print('✅ Rapport supprimé: ${file.path}');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }
}