// test/features/audit_installations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/get_audit_installations_use_case.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/save_audit_installations_use_case.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;

void main() {
  group('AuditInstallationsMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final model = AuditInstallationsElectriques(
        missionId: 'mission_123',
        updatedAt: DateTime(2026, 7, 8),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT 1',
            type: 'TYPE_A',
            dispositionsConstructives: [
              ElementControle(
                elementControle: 'Disjoncteur',
                conforme: true,
                observation: 'OK',
                priorite: 1,
                photos: ['path/1.jpg'],
                referenceNormative: 'NF C 13-100',
                estNA: false,
              ),
            ],
            cellules: [
              Cellule(
                fonction: 'Arrivée',
                type: 'IM',
                marqueModeleAnnee: 'Schneider SM6 2020',
                tensionAssignee: '20kV',
                pouvoirCoupure: '12.5kA',
                numerotation: 'C1',
                parafoudres: 'Oui',
                elementsVerifies: [],
                photos: [],
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                typeTransformateur: 'Sec',
                marqueAnnee: 'Legrand 2021',
                puissanceAssignee: '630kVA',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Non',
                typeRefroidissement: 'AN',
                regimeNeutre: 'IT',
                elementsVerifies: [],
                photos: [],
              ),
            ],
            coffrets: [
              CoffretArmoire(
                qrCode: 'QR_MT_1',
                nom: 'TGBT MT',
                type: 'TGBT',
                domaineTension: 'BT',
                statut: 'complet',
              ),
            ],
          ),
        ],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone BT 1',
            description: 'Zone principale',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'LOCAL_TGBT',
              ),
            ],
          ),
        ],
        photos: ['photo_globale.jpg'],
      );

      final entity = AuditInstallationsMapper.toEntity(model);
      expect(entity.missionId, model.missionId);
      expect(entity.updatedAt, model.updatedAt);
      expect(entity.photos, model.photos);
      expect(entity.moyenneTensionLocaux.length, 1);
      
      final localEntity = entity.moyenneTensionLocaux.first;
      expect(localEntity.nom, 'Local MT 1');
      expect(localEntity.dispositionsConstructives.length, 1);
      expect(localEntity.cellules.length, 1);
      expect(localEntity.transformateurs.length, 1);
      expect(localEntity.coffrets.length, 1);

      final mappedModel = AuditInstallationsMapper.toModel(entity);
      expect(mappedModel.missionId, model.missionId);
      expect(mappedModel.updatedAt, model.updatedAt);
      expect(mappedModel.photos, model.photos);
      expect(mappedModel.moyenneTensionLocaux.length, 1);
      
      final localModel = mappedModel.moyenneTensionLocaux.first;
      expect(localModel.nom, 'Local MT 1');
      expect(localModel.dispositionsConstructives.length, 1);
      expect(localModel.cellules.length, 1);
      expect(localModel.transformateurs.length, 1);
      expect(localModel.coffrets.length, 1);
    });
  });

  group('DI Registrations', () {
    test('Should resolve AuditInstallations UseCases from get_it after di initialization', () async {
      final getIt = GetIt.instance;
      await getIt.reset();

      await di.init();

      expect(getIt.isRegistered<GetAuditInstallationsUseCase>(), isTrue);
      expect(getIt.isRegistered<SaveAuditInstallationsUseCase>(), isTrue);

      final getUseCase = getIt<GetAuditInstallationsUseCase>();
      final saveUseCase = getIt<SaveAuditInstallationsUseCase>();

      expect(getUseCase, isNotNull);
      expect(saveUseCase, isNotNull);
    });
  });
}
