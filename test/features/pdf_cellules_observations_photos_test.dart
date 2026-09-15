import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_observations_recap_builder.dart';

Cellule _createCellule({
  String? nom,
  String fonction = 'Arrivée',
  String numerotation = '',
  String? photo,
  List<String>? photos,
}) {
  return Cellule(
    fonction: fonction,
    type: 'Cellule',
    marqueModeleAnnee: 'Schneider SM6 2020',
    tensionAssignee: '20 kV',
    pouvoirCoupure: '12.5 kA',
    numerotation: numerotation,
    parafoudres: 'Oui',
    nom: nom,
    photo: photo,
    photos: photos ?? [],
    elementsVerifies: [],
  );
}

TransformateurMTBT _createTransfo({
  String? nom,
  String puissance = '630 kVA',
  String? photo,
  List<String>? photos,
}) {
  return TransformateurMTBT(
    typeTransformateur: 'Huile',
    marqueAnnee: 'Schneider 2018',
    puissanceAssignee: puissance,
    tensionPrimaireSecondaire: '20kV / 400V',
    relaisBuchholz: 'Oui',
    typeRefroidissement: 'ONAN',
    regimeNeutre: 'TN-S',
    nom: nom,
    photo: photo,
    photos: photos ?? [],
    elementsVerifies: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Problème 1 : Numérotation séquentielle des cellules MT dans la synthèse des équipements', () {
    test('Désignation séquentielle automatique (Cellule 01, Cellule 02...) avec conservation des noms utilisateurs', () {
      final localMT = MoyenneTensionLocal(
        nom: 'Poste MT Principal',
        type: 'Poste MT',
        cellules: [
          // Cellule 1 : Sans nom (ou générique)
          _createCellule(nom: '', fonction: 'Arrivée'),
          // Cellule 2 : Nom utilisateur explicite
          _createCellule(nom: 'Cellule ENEO', fonction: 'Comptage', numerotation: '02'),
          // Cellule 3 : Fonction = "Présent" et nom générique
          _createCellule(nom: 'Présent', fonction: 'Présent'),
          // Cellule 4 : Sans nom
          _createCellule(nom: null, fonction: ''),
        ],
        transformateurs: [
          _createTransfo(nom: '', puissance: '630 kVA'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [localMT],
        moyenneTensionZones: [],
        basseTensionZones: [],
      );

      final equipements = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);

      final cellulesMT = equipements.where((e) => e.type == 'Cellule').toList();
      expect(cellulesMT.length, 4);

      // Position 1 : sans nom -> Cellule 01
      expect(cellulesMT[0].nom, 'Cellule 01');

      // Position 2 : nom utilisateur -> Cellule ENEO (mais position séquentielle incrémentée)
      expect(cellulesMT[1].nom, 'Cellule ENEO');

      // Position 3 : fonction "Présent" -> filtré et devient Cellule 03
      expect(cellulesMT[2].nom, 'Cellule 03');

      // Position 4 : sans nom -> Cellule 04
      expect(cellulesMT[3].nom, 'Cellule 04');

      // Aucun libellé indésirable "Cellule Présent"
      for (final cell in cellulesMT) {
        expect(cell.nom.toLowerCase().contains('présent'), isFalse);
        expect(cell.nom.toLowerCase().contains('absent'), isFalse);
      }
    });
  });

  group('Problème 2 : Élimination de ÉQUIPEMENT SANS NOM dans la synthèse des observations', () {
    test('Observations libres et coffrets anonymes ont une désignation contextuelle', () {
      final localMT = MoyenneTensionLocal(
        nom: 'Local Technique A',
        type: 'Local MT',
        observationsLibres: [
          ObservationLibre(texte: 'Manque éclairage de sécurité'),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR1',
            type: 'COFFRET',
            nom: '',
            repere: 'COFFRET-01',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Mise à la terre',
                conformite: 'Non',
                observation: 'Câble déconnecté',
              ),
            ],
          ),
          CoffretArmoire(
            qrCode: 'QR2',
            type: 'COFFRET',
            nom: 'Sans nom',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Plastron',
                conformite: 'Non',
                observation: 'Plastron manquant',
              ),
            ],
          ),
        ],
      );

      final zoneMT = MoyenneTensionZone(
        nom: 'Zone MT Extérieure',
        observationsLibres: [
          ObservationLibre(texte: 'Sol encombré'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm2',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [localMT],
        moyenneTensionZones: [zoneMT],
        basseTensionZones: [],
      );

      // 1. Observations MT
      final obsMT = PdfObservationsRecapBuilder.collectObservationsMT(audit);

      final obsLocalLibre = obsMT.firstWhere((o) => o.observation == 'Manque éclairage de sécurité');
      expect(obsLocalLibre.coffret, 'Observations du local');

      final obsZoneLibre = obsMT.firstWhere((o) => o.observation == 'Sol encombré');
      expect(obsZoneLibre.coffret, 'Observations de la zone');

      // 2. Observations BT (car coffrets de type COFFRET dans local MT sont collectés dans BT)
      final obsBT = PdfObservationsRecapBuilder.collectObservationsBT(audit);

      final obsCoffretAvecRepere = obsBT.firstWhere((o) => o.observation == 'Câble déconnecté');
      expect(obsCoffretAvecRepere.coffret, 'COFFRET-01');

      final obsCoffretSansNom = obsBT.firstWhere((o) => o.observation == 'Plastron manquant');
      expect(obsCoffretSansNom.coffret, contains('Local Technique A'));

      // Aucun "ÉQUIPEMENT SANS NOM" ni dans MT ni dans BT
      for (final o in [...obsMT, ...obsBT]) {
        expect(o.coffret.toLowerCase(), isNot(contains('équipement sans nom')));
        expect(o.coffret.toLowerCase(), isNot(contains('sans nom')));
      }

      // Vérifier le rendu unifié des tables sans aucune erreur
      final widgetsMT = PdfObservationsRecapBuilder.buildObsRecapTableMT(obsMT);
      expect(widgetsMT, isNotEmpty);

      final widgetsBT = PdfObservationsRecapBuilder.buildObsRecapTableBT(obsBT);
      expect(widgetsBT, isNotEmpty);
    });
  });

  group('Problème 3 : Fiabilisation des photos pour cellules et transformateurs', () {
    test('AppImageUtils supporte les sous-dossiers mission_photos, cellules et transformateurs', () {
      expect(AppImageUtils.supportedFolderKeywords, contains('mission_photos'));
      expect(AppImageUtils.supportedFolderKeywords, contains('cellules'));
      expect(AppImageUtils.supportedFolderKeywords, contains('transformateurs'));
    });

    test('buildCelluleSection et buildTransformateurSection résolvent correctement les photos', () {
      final tempDir = Directory.systemTemp.createTempSync('photo_test_');
      try {
        final dummyFile = File('${tempDir.path}/cellule_test.png');
        dummyFile.writeAsBytesSync(PdfAuditInstallationsBuilder.placeholder1x1.bytes);

        final cellule = _createCellule(
          nom: 'Cellule Arrivée',
          photo: dummyFile.path,
        );

        final transfo = _createTransfo(
          nom: 'Transfo 1',
          photo: dummyFile.path,
        );

        final celluleWidgets = PdfAuditInstallationsBuilder.buildCelluleSection(
          cellule,
          saveFilesToDisk: true,
        );
        expect(celluleWidgets, isNotEmpty);

        final transfoWidgets = PdfAuditInstallationsBuilder.buildTransformateurSection(
          transfo,
          saveFilesToDisk: true,
        );
        expect(transfoWidgets, isNotEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
