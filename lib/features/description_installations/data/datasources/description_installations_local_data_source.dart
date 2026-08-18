// lib/features/description_installations/data/datasources/description_installations_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';

abstract class DescriptionInstallationsLocalDataSource {
  Future<DescriptionInstallations> getOrCreateDescriptionInstallations(String missionId);
  Future<void> saveDescriptionInstallations(DescriptionInstallations desc);
  Future<bool> addInstallationItemToSection({
    required String missionId,
    required String section,
    required InstallationItem item,
  });
  Future<bool> updateInstallationItemInSection({
    required String missionId,
    required String section,
    required int index,
    required InstallationItem item,
  });
  Future<bool> removeInstallationItemFromSection({
    required String missionId,
    required String section,
    required int index,
  });
  Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  });
}

class DescriptionInstallationsLocalDataSourceImpl implements DescriptionInstallationsLocalDataSource {
  static const String _descriptionBox = 'description_installations';
  static const String _missionBox = 'missions';

  @override
  Future<DescriptionInstallations> getOrCreateDescriptionInstallations(String missionId) async {
    try {
      final existing = HiveService.getDescriptionInstallationsByMissionId(missionId);
      if (existing != null) return existing;
    } catch (_) {}

    return await HiveService.getOrCreateDescriptionInstallations(missionId);
  }

  @override
  Future<void> saveDescriptionInstallations(DescriptionInstallations desc) async {
    await HiveService.saveDescriptionInstallations(desc);
  }

  @override
  Future<bool> addInstallationItemToSection({
    required String missionId,
    required String section,
    required InstallationItem item,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      if (section == 'cpi') {
        desc.cpi = [item];
      } else {
        desc.addInstallationItem(section, item);
      }
      await saveDescriptionInstallations(desc);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateInstallationItemInSection({
    required String missionId,
    required String section,
    required int index,
    required InstallationItem item,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      
      switch (section) {
        case 'alimentation_moyenne_tension':
          if (index < desc.alimentationMoyenneTension.length) {
            desc.alimentationMoyenneTension[index] = item;
          }
          break;
        case 'alimentation_basse_tension':
          if (index < desc.alimentationBasseTension.length) {
            desc.alimentationBasseTension[index] = item;
          }
          break;
        case 'groupe_electrogene':
          if (index < desc.groupeElectrogene.length) {
            desc.groupeElectrogene[index] = item;
          }
          break;
        case 'alimentation_carburant':
          if (index < desc.alimentationCarburant.length) {
            desc.alimentationCarburant[index] = item;
          }
          break;
        case 'inverseur':
          if (index < desc.inverseur.length) {
            desc.inverseur[index] = item;
          }
          break;
        case 'stabilisateur':
          if (index < desc.stabilisateur.length) {
            desc.stabilisateur[index] = item;
          }
          break;
        case 'onduleurs':
          if (index < desc.onduleurs.length) {
            desc.onduleurs[index] = item;
          }
          break;
        case 'cpi':
          desc.cpi = [item];
          break;
        default:
          return false;
      }

      await saveDescriptionInstallations(desc);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeInstallationItemFromSection({
    required String missionId,
    required String section,
    required int index,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      
      switch (section) {
        case 'alimentation_moyenne_tension':
          if (index < desc.alimentationMoyenneTension.length) {
            desc.alimentationMoyenneTension.removeAt(index);
          }
          break;
        case 'alimentation_basse_tension':
          if (index < desc.alimentationBasseTension.length) {
            desc.alimentationBasseTension.removeAt(index);
          }
          break;
        case 'groupe_electrogene':
          if (index < desc.groupeElectrogene.length) {
            desc.groupeElectrogene.removeAt(index);
          }
          break;
        case 'alimentation_carburant':
          if (index < desc.alimentationCarburant.length) {
            desc.alimentationCarburant.removeAt(index);
          }
          break;
        case 'inverseur':
          if (index < desc.inverseur.length) {
            desc.inverseur.removeAt(index);
          }
          break;
        case 'stabilisateur':
          if (index < desc.stabilisateur.length) {
            desc.stabilisateur.removeAt(index);
          }
          break;
        case 'onduleurs':
          if (index < desc.onduleurs.length) {
            desc.onduleurs.removeAt(index);
          }
          break;
        case 'cpi':
          if (index < desc.cpi.length) {
            desc.cpi.removeAt(index);
          }
          break;
        default:
          return false;
      }

      await saveDescriptionInstallations(desc);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      
      switch (field) {
        case 'regime_neutre':
          desc.regimeNeutre = value;
          break;
        case 'regime_neutre_detail':
          desc.regimeNeutreDetail = value.isEmpty ? null : value;
          break;
        case 'eclairage_securite':
          desc.eclairageSecurite = value;
          break;
        case 'modifications_installations':
          desc.modificationsInstallations = value;
          break;
        case 'note_calcul':
          desc.noteCalcul = value;
          break;
        case 'registre_securite':
          desc.registreSecurite = value;
          break;
        case 'presence_paratonnerre':
          desc.presenceParatonnerre = value;
          break;
        case 'analyse_risque_foudre':
          desc.analyseRisqueFoudre = value;
          break;
        case 'etude_technique_foudre':
          desc.etudeTechniqueFoudre = value;
          break;
        default:
          return false;
      }

      await saveDescriptionInstallations(desc);
      return true;
    } catch (e) {
      return false;
    }
  }
}
