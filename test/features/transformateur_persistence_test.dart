import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Transformateur MT/BT Persistence & Clean Architecture Mapping', () {
    late TransformateurMTBT fullTransfo;

    setUp(() {
      fullTransfo = TransformateurMTBT(
        typeTransformateur: 'Huile',
        marqueAnnee: 'Schneider / 2022',
        marque: 'Schneider',
        anneeFabrication: '2022',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20 kV / 400 V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
        calibreDisjoncteur: '1000A',
        sectionCables: '240 mm²',
        syncId: 'transfo_test_123',
        intensiteNominale: '909 A',
        couplage: 'Dyn11',
        typeReseau: 'Triphasé + N',
        pccAmont: '500 MVA',
        puissanceUcc: '4 %',
        ik3Max: '15.2 kA',
        nom: 'Transfo T1',
        repere: 'POSTE HT',
      );
    });

    test('1. AuditInstallationsMapper preserves all 6 new fields in toEntity and toModel roundtrip', () {
      final entity = AuditInstallationsMapper.toTransformateurEntity(fullTransfo);

      // Verify Entity attributes
      expect(entity.intensiteNominale, equals('909 A'));
      expect(entity.couplage, equals('Dyn11'));
      expect(entity.typeReseau, equals('Triphasé + N'));
      expect(entity.pccAmont, equals('500 MVA'));
      expect(entity.puissanceUcc, equals('4 %'));
      expect(entity.ik3Max, equals('15.2 kA'));

      // Convert back to Model
      final restoredModel = AuditInstallationsMapper.toTransformateurModel(entity);

      // Verify Model attributes
      expect(restoredModel.intensiteNominale, equals('909 A'));
      expect(restoredModel.couplage, equals('Dyn11'));
      expect(restoredModel.typeReseau, equals('Triphasé + N'));
      expect(restoredModel.pccAmont, equals('500 MVA'));
      expect(restoredModel.puissanceUcc, equals('4 %'));
      expect(restoredModel.ik3Max, equals('15.2 kA'));
    });

    test('2. TransformateurMTBTEntity copyWith preserves unmodified fields', () {
      final entity = AuditInstallationsMapper.toTransformateurEntity(fullTransfo);
      final updatedEntity = entity.copyWith(couplage: 'Yyn0');

      expect(updatedEntity.couplage, equals('Yyn0'));
      expect(updatedEntity.intensiteNominale, equals('909 A'));
      expect(updatedEntity.typeReseau, equals('Triphasé + N'));
      expect(updatedEntity.pccAmont, equals('500 MVA'));
      expect(updatedEntity.puissanceUcc, equals('4 %'));
      expect(updatedEntity.ik3Max, equals('15.2 kA'));
    });

    test('3. Legacy TransformateurMTBT without the 6 fields behaves safely', () {
      final legacyTransfo = TransformateurMTBT(
        typeTransformateur: 'Sec',
        marqueAnnee: 'Legrand / 2015',
        puissanceAssignee: '250 kVA',
        tensionPrimaireSecondaire: '15 kV / 400 V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'IT',
      );

      final entity = AuditInstallationsMapper.toTransformateurEntity(legacyTransfo);
      expect(entity.couplage, isNull);
      expect(entity.typeReseau, isNull);
      expect(entity.pccAmont, isNull);
      expect(entity.puissanceUcc, isNull);
      expect(entity.ik3Max, isNull);
      expect(entity.intensiteNominale, isNull);

      final restored = AuditInstallationsMapper.toTransformateurModel(entity);
      expect(restored.couplage, isNull);
      expect(restored.typeTransformateur, equals('Sec'));
    });

    test('4. Tension MT/BT custom expressions like 20/0.4* or 15/0.4 are preserved without alteration', () {
      final customTransfo = TransformateurMTBT(
        typeTransformateur: 'Huile',
        marqueAnnee: 'Schneider / 2022',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20/0.4*',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
      );

      final entity = AuditInstallationsMapper.toTransformateurEntity(customTransfo);
      expect(entity.tensionPrimaireSecondaire, equals('20/0.4*'));

      final restored = AuditInstallationsMapper.toTransformateurModel(entity);
      expect(restored.tensionPrimaireSecondaire, equals('20/0.4*'));
    });
  });
}
