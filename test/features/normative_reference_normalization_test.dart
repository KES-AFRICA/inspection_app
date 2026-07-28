import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/unified_observation.dart';

void main() {
  group('Normative Reference Normalization Tests', () {
    test('normalizeNormativeReference converts § to art', () {
      expect(
        DispositionsConstructivesRegistry.normalizeNormativeReference('§ 422.3.1'),
        equals('art 422.3.1'),
      );
      expect(
        DispositionsConstructivesRegistry.normalizeNormativeReference('NF C 15-100 § 559.5'),
        equals('NF C 15-100 art 559.5'),
      );
      expect(
        DispositionsConstructivesRegistry.normalizeNormativeReference('NF C 13-100:2015 – § 411.3'),
        equals('NF C 13-100:2015 – art 411.3'),
      );
    });

    test('AuditInstallationsMapper converts § to art in referenceNormative', () {
      final model = ElementControle(
        elementControle: 'Test Item',
        conforme: false,
        referenceNormative: 'NF C 15-100 § 411.3',
      );

      final entity = AuditInstallationsMapper.toElementEntity(model);
      expect(entity.referenceNormative, equals('NF C 15-100 art 411.3'));

      final backToModel = AuditInstallationsMapper.toElementModel(entity);
      expect(backToModel.referenceNormative, equals('NF C 15-100 art 411.3'));
    });

    test('UnifiedObservation constructor converts § to art', () {
      final obs = UnifiedObservation(
        id: '1',
        missionId: 'm1',
        localisation: 'Local MT',
        itemNom: 'Item 1',
        texteObservation: 'Obs test',
        criticite: CriticalityLevel.majeure,
        referenceNormative: 'NF C 13-100 § 112',
        sourceCategory: AuditSourceCategory.moyenneTensionLocal,
        tableType: AuditTableType.dispositionsConstructives,
        typeObjet: 'Local',
      );

      expect(obs.referenceNormative, equals('NF C 13-100 art 112'));
    });
  });
}
