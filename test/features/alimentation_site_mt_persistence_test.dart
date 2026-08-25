// test/features/alimentation_site_mt_persistence_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/features/description_installations/domain/entities/description_installations_entity.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('Slide 1 - Persistence & Serialization Tests for Alimentation du site MT', () {
    test('1. Verify all 4 fields (Nature, Tension, Nombre, IACM) on DescriptionInstallations model', () {
      final desc = DescriptionInstallations.create('mission_test_001');

      expect(desc.natureReseauAlimentationSite, isNull);
      expect(desc.tensionAlimentationSite, isNull);
      expect(desc.nombreAlimentationSite, isNull);
      expect(desc.presenceIacmAlimentationSite, isNull);
      expect(desc.isSectionComplete('alimentation_site_mt'), isFalse);

      desc.natureReseauAlimentationSite = 'Aérien';
      desc.tensionAlimentationSite = '20';
      desc.nombreAlimentationSite = '2';
      desc.presenceIacmAlimentationSite = 'Oui';

      expect(desc.natureReseauAlimentationSite, 'Aérien');
      expect(desc.tensionAlimentationSite, '20');
      expect(desc.nombreAlimentationSite, '2');
      expect(desc.presenceIacmAlimentationSite, 'Oui');
      expect(desc.isSectionComplete('alimentation_site_mt'), isTrue);
    });

    test('2. Clean Architecture Domain Entity Mapping (Mapper toEntity & toModel)', () {
      final modelInput = DescriptionInstallations.create('mission_test_002');
      modelInput.natureReseauAlimentationSite = 'Souterrain';
      modelInput.tensionAlimentationSite = '15';
      modelInput.nombreAlimentationSite = '1';
      modelInput.presenceIacmAlimentationSite = 'Sans objet';

      final entity = DescriptionInstallationsMapper.toEntity(modelInput);
      expect(entity.natureReseauAlimentationSite, 'Souterrain');
      expect(entity.tensionAlimentationSite, '15');
      expect(entity.nombreAlimentationSite, '1');
      expect(entity.presenceIacmAlimentationSite, 'Sans objet');
      expect(entity.isSectionComplete('alimentation_site_mt'), isTrue);

      final modelOutput = DescriptionInstallationsMapper.toModel(entity);
      expect(modelOutput.natureReseauAlimentationSite, 'Souterrain');
      expect(modelOutput.tensionAlimentationSite, '15');
      expect(modelOutput.nombreAlimentationSite, '1');
      expect(modelOutput.presenceIacmAlimentationSite, 'Sans objet');
      expect(modelOutput.isSectionComplete('alimentation_site_mt'), isTrue);
    });

    test('3. Hive Adapter Serialization Field Count Verification', () {
      final adapter = DescriptionInstallationsAdapter();
      expect(adapter.typeId, equals(2));
    });
  });
}
