import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('Audit & Resolution PDF Table Mapping (MT & BT)', () {
    test('MT - Cellule MT avec clés synchro, UI et legacy', () {
      final itemSynchro = InstallationItem(
        data: {
          'auditCelluleId': 'cellule_1',
          'Gamme De Cellule': 'SM6',
          'Type De Cellule': 'IM',
          'Tension de service': '20',
          'TENSION ASSIGNEE(KV)': '24',
          'POUVOIR DE COUPURE ASSIGNE(KA)': '12.5',
          'Calibre Du Disjoncteur': '630',
          'SECTION DU CABLE(mm2)': '95',
          'NATURE DU RESEAU': 'Souterrain',
          'PRESENCE IACM': 'Absent',
          'Observations': 'RAS',
        },
        createdAt: DateTime.now(),
      );

      final itemUIForm = InstallationItem(
        data: {
          'Gamme De Cellule': 'Premset',
          'Type De Cellule': 'CB',
          'Tension de service': '15',
          'Tension assignée': '17.5',
          'Pouvoir de coupure assigné': '16',
          'Calibre Du Disjoncteur': '400',
          'Section Du Cable': '70',
          'Nature Du Reseau': 'Aérien',
        },
        createdAt: DateTime.now(),
      );

      // 1. Colonne 'TYPE DE CELLULE'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemSynchro.data, 'TYPE DE CELLULE', InstallationDescriptionSyncService.celluleAliases),
          'IM');
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemUIForm.data, 'TYPE DE CELLULE', InstallationDescriptionSyncService.celluleAliases),
          'CB');

      // 2. Colonne 'TENSION DE SERVICE (kV)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemSynchro.data, 'TENSION DE SERVICE (kV)', InstallationDescriptionSyncService.celluleAliases),
          '20');
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemUIForm.data, 'TENSION DE SERVICE (kV)', InstallationDescriptionSyncService.celluleAliases),
          '15');

      // 3. Colonne 'TENSION ASSIGNEE(KV)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemSynchro.data, 'TENSION ASSIGNEE(KV)', InstallationDescriptionSyncService.celluleAliases),
          '24');
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemUIForm.data, 'TENSION ASSIGNEE(KV)', InstallationDescriptionSyncService.celluleAliases),
          '17.5');

      // 4. Colonne 'POUVOIR DE COUPURE ASSIGNE(KA)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemSynchro.data, 'POUVOIR DE COUPURE ASSIGNE(KA)', InstallationDescriptionSyncService.celluleAliases),
          '12.5');
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemUIForm.data, 'POUVOIR DE COUPURE ASSIGNE(KA)', InstallationDescriptionSyncService.celluleAliases),
          '16');

      // 5. Colonne 'SECTION DU CABLE(mm2)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemSynchro.data, 'SECTION DU CABLE(mm2)', InstallationDescriptionSyncService.celluleAliases),
          '95');
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemUIForm.data, 'SECTION DU CABLE(mm2)', InstallationDescriptionSyncService.celluleAliases),
          '70');
    });

    test('BT - Transformateur MT/BT avec clés synchro, UI et calculées', () {
      final itemTransfo = InstallationItem(
        data: {
          'auditTransformateurId': 'transfo_1',
          'Puissance Transformateur': '630',
          'Type de transformateur': 'IMMERGÉ',
          'Intensité nominale': '909',
          'Calibre Du Disjoncteur Sortie Transformateur': '1000',
          'Section Du Cable': '240',
          'Tension': '20 kV / 400 V',
          'Couplage': 'Dyn11',
          'Type de réseau': 'Réseau urbain',
          'PCC amont': '500',
          'Puissance UCC': '4 %',
          'IK3 MAX': '21,55 kA',
        },
        createdAt: DateTime.now(),
      );

      // 1. Colonne 'PUISSANCE TRANSFORMATEUR (KVA)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'PUISSANCE TRANSFORMATEUR (KVA)', InstallationDescriptionSyncService.transfoAliases),
          '630');

      // 2. Colonne 'TYPE DE TRANSFORMATEUR'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'TYPE DE TRANSFORMATEUR', InstallationDescriptionSyncService.transfoAliases),
          'IMMERGÉ');

      // 3. Colonne 'INTENSITE NOMINALE'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'INTENSITE NOMINALE', InstallationDescriptionSyncService.transfoAliases),
          '909');

      // 4. Colonne 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', InstallationDescriptionSyncService.transfoAliases),
          '1000');

      // 5. Colonne 'TENSION MT/BT'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'TENSION MT/BT', InstallationDescriptionSyncService.transfoAliases),
          '20 kV / 400 V');

      // 6. Colonne 'PCC AMONT EN MVA'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'PCC AMONT EN MVA', InstallationDescriptionSyncService.transfoAliases),
          '500');

      // 7. Colonne 'UCC EN %'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'UCC EN %', InstallationDescriptionSyncService.transfoAliases),
          '4 %');

      // 8. Colonne 'IK3 MAX(KA)'
      expect(
          InstallationDescriptionSyncService.getFieldWithAlias(
              itemTransfo.data, 'IK3 MAX(KA)', InstallationDescriptionSyncService.transfoAliases),
          '21,55 kA');
    });
  });
}
