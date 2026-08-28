import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

@Timeout(Duration(minutes: 45))
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('guinness_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        return tempDir.path;
      },
    );
    Hive.init(tempDir.path);
    await HiveService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    try { await tempDir.delete(recursive: true); } catch (_) {}
  });

  test('Diagnostic GUINNESS DOUALA - Importation et Diagnostic PDF & Navigation pour la mission Guinness', () async {
    final inspecPath = '/home/andelson-teufack/Téléchargements/backup_GUINNESS_DOUALA_-_BASSA_KES1_2026-08-27T05-29-03.inspec';
    final file = File(inspecPath);
    expect(file.existsSync(), isTrue, reason: 'Le fichier .inspec doit exister');

    final fileSize = file.lengthSync();
    print('📦 Taille du fichier .inspec: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} Mo ($fileSize octets)');

    // 1. Importer la mission
    final result = await BackupService.importerSauvegardeFichier(
      filePath: inspecPath,
      ecraser: true,
      importeurMatricule: 'AUDIT',
      importeurNom: 'AUDIT',
      importeurPrenom: 'AUDIT',
    );
    expect(result.success, isTrue, reason: 'L\'importation doit réussir');

    final metaBox = Hive.box<Mission>('missions');
    final meta = metaBox.values.firstWhere((m) => m.nomClient.contains('GUINNESS') || (m.nomSite != null && m.nomSite!.contains('DOUALA')));
    final missionId = meta.id;
    print('✅ Mission importée avec ID: $missionId');
    print('✅ Nom site: ${meta.nomSite}, Client: ${meta.nomClient}');

    // 2. Charger les données pour l'audit
    final progress = await SequenceProgressService.getProgress(missionId);
    print('✅ Sequence progress saved in Hive: $progress');

    final audit = await HiveService.getOrCreateAuditInstallations(missionId);
    final desc = await HiveService.getOrCreateDescriptionInstallations(missionId);

    print('✅ Zones BT: ${audit.basseTensionZones.length}, Zones MT: ${audit.moyenneTensionZones.length}');

    int totalCoffrets = 0;
    int totalPhotos = 0;
    int totalPoints = 0;
    int totalObservations = 0;
    int totalAlimentations = 0;

    void processCoffret(CoffretArmoire c) {
      totalCoffrets++;
      totalPhotos += c.photos.length + c.photosExternes.length + c.photosInternes.length;
      totalPoints += c.pointsVerification.length;
      totalObservations += c.observationsLibres.length + c.observationsParafoudre.length;
      totalAlimentations += c.alimentations.length;
    }

    for (var zone in audit.moyenneTensionZones) {
      for (var c in zone.coffrets) processCoffret(c);
      for (var local in zone.locaux) {
        for (var c in local.coffrets) processCoffret(c);
      }
    }
    for (var local in audit.moyenneTensionLocaux) {
      for (var c in local.coffrets) processCoffret(c);
    }
    for (var zone in audit.basseTensionZones) {
      for (var c in zone.coffretsDirects) processCoffret(c);
      for (var local in zone.locaux) {
        for (var c in local.coffrets) processCoffret(c);
      }
    }

    print('📊 STATISTIQUES ÉQUIPEMENTS GUINNESS:');
    print('   - Total Coffrets/Armoires/TGBT/Inverseurs: $totalCoffrets');
    print('   - Total Photos Équipements: $totalPhotos');
    print('   - Total Points de Vérification: $totalPoints');
    print('   - Total Observations: $totalObservations');
    print('   - Total Alimentations: $totalAlimentations');

    // Diagnostic Problème 1: currentStep == -1
    final currentStep = progress['currentStep'] as int? ?? 0;
    print('🔍 DIAGNOSTIC CRASH #1 - currentStep: $currentStep');
    if (currentStep < 0) {
      print('❌ CAUSE CRASH #1 CONFIRMÉE: currentStep est négatif ($currentStep)! L\'accès à l\'étape dans SequenceScreen (0..5) provoque un RangeError -1.');
    }

    // Diagnostic Problème 2: Génération PDF
    print('⚙️ Lancement de la génération du rapport PDF...');
    try {
      final pdfFile = await PdfReportService.generateMissionReport(
        missionId,
        onProgress: (progress, message) {
          print('📈 [PDF PROGRESS ${(progress * 100).toStringAsFixed(1)}%] $message');
        },
      );
      print('🎉 Rapport PDF généré avec SUCÈS ! Fichier: ${pdfFile?.path}, Taille: ${(pdfFile != null ? (pdfFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2) : 0)} Mo');
    } catch (e, st) {
      print('❌ EXCEPTION GÉNERATION PDF REPRODUITE: $e');
      print(st);
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
