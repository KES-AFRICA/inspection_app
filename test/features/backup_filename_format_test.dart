import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('Backup Service — Nouveau format de nom de fichier de sauvegarde', () {
    test('1. Format standardisé backup_nomduclient_sitedelamission_matricule_timestamp.inspec', () {
      final fileName = BackupService.buildBackupFileName(
        clientName: 'SABC Douala',
        siteName: 'Usine Principale',
        matricule: 'KES1',
        timestamp: '2026-08-24T20-39-16',
      );

      expect(
        fileName,
        equals('backup_SABC_Douala_Usine_Principale_KES1_2026-08-24T20-39-16.inspec'),
      );
    });

    test('2. Nettoyage des caractères spéciaux et gestion des valeurs vides/nulles', () {
      final fileName = BackupService.buildBackupFileName(
        clientName: 'Client / Special * Test ?',
        siteName: '',
        matricule: '  ',
        timestamp: '2026-08-25T10-00-00',
      );

      expect(
        fileName,
        equals('backup_Client___Special___Test___site_kes_2026-08-25T10-00-00.inspec'),
      );
    });
  });
}
