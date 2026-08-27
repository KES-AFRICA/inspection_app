import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/mission_integrity_validator.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_validator_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MissionIntegrityValidator Tests', () {
    test('sanitizeSequenceProgress fixes invalid negative step', () async {
      const missionId = 'test_mission_neg';
      await SequenceProgressService.saveCurrentStep(missionId, -1);
      
      await MissionIntegrityValidator.sanitizeSequenceProgress(missionId);
      
      final progress = await SequenceProgressService.getProgress(missionId);
      expect(progress['currentStep'], equals(0));
    });

    test('sanitizeSequenceProgress preserves valid step', () async {
      const missionId = 'test_mission_valid';
      await SequenceProgressService.saveCurrentStep(missionId, 3);
      
      await MissionIntegrityValidator.sanitizeSequenceProgress(missionId);
      
      final progress = await SequenceProgressService.getProgress(missionId);
      expect(progress['currentStep'], equals(3));
    });
  });
}
