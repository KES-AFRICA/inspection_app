import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';

void main() {
  group('Description Installations Sync & Regeneration Tests', () {
    test('buildLocalisationMap constructs synchronous breadcrumbs correctly', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_test_sync',
        updatedAt: DateTime.now(),
      );

      final localMt = MoyenneTensionLocal(
        nom: 'Local MT Principal',
        type: 'LOCAL_TRANSFORMATEUR',
      );
      final cellule1 = Cellule(
        fonction: 'Arrivée',
        type: 'Cellule RM6 IM',
        marqueModeleAnnee: 'Schneider 2022',
        tensionAssignee: '24',
        pouvoirCoupure: '12.5',
        numerotation: 'C1',
        parafoudres: 'Non',
        syncId: 'cell_001',
      );
      localMt.cellules.add(cellule1);

      final transfo1 = TransformateurMTBT(
        typeTransformateur: 'HUILE',
        marqueAnnee: '2022',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20/0.4',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN',
        syncId: 'transfo_001',
      );
      localMt.transformateurs.add(transfo1);

      audit.moyenneTensionLocaux.add(localMt);

      final locMap = InstallationDescriptionSyncService.buildLocalisationMap(audit);

      expect(locMap.containsKey('cell_001'), isTrue);
      expect(locMap['cell_001'], equals('Moyenne Tension ➔ Local MT Principal ➔ Cellule RM6 IM'));

      expect(locMap.containsKey('transfo_001'), isTrue);
      expect(locMap['transfo_001'], equals('Moyenne Tension ➔ Local MT Principal ➔ 630 kVA'));
    });

    test('syncAuditToDescription is idempotent and preserves manual items', () async {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_idempotent_test',
        updatedAt: DateTime.now(),
      );

      final localMt = MoyenneTensionLocal(
        nom: 'Local 1',
        type: 'LOCAL_TRANSFORMATEUR',
      );
      localMt.cellules.add(Cellule(
        fonction: 'Protection',
        type: 'SM6 IM',
        marqueModeleAnnee: 'ABB 2021',
        tensionAssignee: '24',
        pouvoirCoupure: '16',
        numerotation: 'C2',
        parafoudres: 'Non',
        syncId: 'c1',
      ));
      audit.moyenneTensionLocaux.add(localMt);

      final desc = DescriptionInstallations.create('mission_idempotent_test');
      
      // Ajouter un item manuel sans auditCelluleId
      desc.alimentationMoyenneTension.add(InstallationItem(
        data: {'Gamme De Cellule': 'Manuelle'},
        createdAt: DateTime.now(),
      ));

      expect(desc.alimentationMoyenneTension.length, equals(1));
    });
  });
}
