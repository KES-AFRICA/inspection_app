import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';

void main() {
  group('InstallationDescriptionSyncService Unit Tests', () {
    test('normalizeKey should normalize strings removing accents, casing and special chars', () {
      expect(InstallationDescriptionSyncService.normalizeKey('Gamme De Cellule'), equals('gamme de cellule'));
      expect(InstallationDescriptionSyncService.normalizeKey('Type  de   Cellule'), equals('type de cellule'));
      expect(InstallationDescriptionSyncService.normalizeKey('Section Du Câble'), equals('section du cable'));
      expect(InstallationDescriptionSyncService.normalizeKey('Présence IACM'), equals('presence iacm'));
      expect(InstallationDescriptionSyncService.normalizeKey('Tension primaire / secondaire'), equals('tension primaire / secondaire'));
    });

    test('getFieldWithAlias should find values with exact and alias keys', () {
      final data = {
        'Gamme De Cellule': 'SM6',
        'Section Du Cable': '240mm²',
        'presence_iacm': 'Oui',
      };

      final aliases = {
        'gamme de cellule': 'Gamme De Cellule',
        'gamme': 'Gamme De Cellule',
        'section du cable': 'Section Du Cable',
        'presence iacm': 'PRESENCE IACM',
      };

      expect(
        InstallationDescriptionSyncService.getFieldWithAlias(data, 'Gamme De Cellule', aliases),
        equals('SM6'),
      );
      expect(
        InstallationDescriptionSyncService.getFieldWithAlias(data, 'Section Du Cable', aliases),
        equals('240mm²'),
      );
      expect(
        InstallationDescriptionSyncService.getFieldWithAlias(data, 'PRESENCE IACM', aliases),
        equals('Oui'),
      );
    });
  });
}
