// test/features/alimentation_site_mt_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/features/description_installations/domain/entities/description_installations_entity.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';

void main() {
  group('Évolution Alimentation du site Moyen Tension & Retrait IACM Cellule', () {
    test('1. Progression & completion de alimentation_site_mt', () {
      final desc = DescriptionInstallations.create('mission_123');

      expect(desc.isSectionComplete('alimentation_site_mt'), false);
      expect(desc.getProgress()['alimentation_site_mt'], false);

      desc.natureReseauAlimentationSite = 'Souterrain';
      desc.tensionAlimentationSite = '15';
      desc.nombreAlimentationSite = '2';
      desc.presenceIacmAlimentationSite = 'Non';

      expect(desc.isSectionComplete('alimentation_site_mt'), true);
      expect(desc.getProgress()['alimentation_site_mt'], true);
    });

    test('2. Round-trip Clean Architecture (Mapper)', () {
      final descModel = DescriptionInstallations.create('mission_123');
      descModel.natureReseauAlimentationSite = 'Aérien';
      descModel.tensionAlimentationSite = '20';
      descModel.nombreAlimentationSite = '1';
      descModel.presenceIacmAlimentationSite = 'Oui';

      final entity = DescriptionInstallationsMapper.toEntity(descModel);

      expect(entity.natureReseauAlimentationSite, 'Aérien');
      expect(entity.tensionAlimentationSite, '20');
      expect(entity.nombreAlimentationSite, '1');
      expect(entity.presenceIacmAlimentationSite, 'Oui');
      expect(entity.isSectionComplete('alimentation_site_mt'), true);

      final modelBack = DescriptionInstallationsMapper.toModel(entity);

      expect(modelBack.natureReseauAlimentationSite, 'Aérien');
      expect(modelBack.tensionAlimentationSite, '20');
      expect(modelBack.nombreAlimentationSite, '1');
      expect(modelBack.presenceIacmAlimentationSite, 'Oui');
    });

    test('3. Rétrocompatibilité avec les anciennes missions (champs null par défaut)', () {
      final descModel = DescriptionInstallations.create('mission_legacy');

      expect(descModel.natureReseauAlimentationSite, null);
      expect(descModel.tensionAlimentationSite, null);
      expect(descModel.nombreAlimentationSite, null);
      expect(descModel.presenceIacmAlimentationSite, null);
      expect(descModel.isSectionComplete('alimentation_site_mt'), false);
    });

    test('4. Retrait de la collecte PRESENCE IACM pour les Cellules MT PDF', () {
      final desc = DescriptionInstallations.create('mission_123');
      final cellule = Cellule(
        fonction: 'Arrivée',
        type: 'IM',
        marqueModeleAnnee: 'Schneider',
        tensionAssignee: '24kV',
        pouvoirCoupure: '16kA',
        numerotation: 'C1',
        parafoudres: 'Non',
        gamme: 'SM6',
        tensionService: '15',
        presenceIacm: 'Oui', // Ancienne donnée en base
      );

      final pdfData = InstallationDescriptionPdfData.fromDescription(
        desc: desc,
        audit: AuditInstallationsElectriques(
          missionId: 'mission_123',
          updatedAt: DateTime.now(),
          moyenneTensionLocaux: [
            MoyenneTensionLocal(
              nom: 'Local MT 1',
              type: 'Poste',
              dispositionsConstructives: [],
              conditionsExploitation: [],
              cellule: cellule,
            ),
          ],
        ),
      );

      expect(pdfData.mtRows.length, 1);
      final fields = pdfData.mtRows.expand((r) => r.normalizedFields.keys).toList();
      expect(fields.contains('PRESENCE IACM'), false);
    });
  });
}
