// lib/features/description_installations/domain/entities/description_installations_entity.dart
import 'installation_item_entity.dart';

class DescriptionInstallationsEntity {
  final String missionId;
  final List<InstallationItemEntity> alimentationMoyenneTension;
  final List<InstallationItemEntity> alimentationBasseTension;
  final List<InstallationItemEntity> groupeElectrogene;
  final List<InstallationItemEntity> alimentationCarburant;
  final List<InstallationItemEntity> inverseur;
  final List<InstallationItemEntity> stabilisateur;
  final List<InstallationItemEntity> onduleurs;
  final String? regimeNeutre;
  final String? regimeNeutreDetail;
  final String? eclairageSecurite;
  final String? modificationsInstallations;
  final String? noteCalcul;
  final String? registreSecurite;
  final String? presenceParatonnerre;
  final String? analyseRisqueFoudre;
  final String? etudeTechniqueFoudre;
  final DateTime updatedAt;

  const DescriptionInstallationsEntity({
    required this.missionId,
    this.alimentationMoyenneTension = const [],
    this.alimentationBasseTension = const [],
    this.groupeElectrogene = const [],
    this.alimentationCarburant = const [],
    this.inverseur = const [],
    this.stabilisateur = const [],
    this.onduleurs = const [],
    this.regimeNeutre,
    this.regimeNeutreDetail,
    this.eclairageSecurite,
    this.modificationsInstallations,
    this.noteCalcul,
    this.registreSecurite,
    this.presenceParatonnerre,
    this.analyseRisqueFoudre,
    this.etudeTechniqueFoudre,
    required this.updatedAt,
  });

  bool isSectionComplete(String sectionKey) {
    switch (sectionKey) {
      case 'alimentation_moyenne_tension':
        return alimentationMoyenneTension.isNotEmpty;
      case 'alimentation_basse_tension':
        return alimentationBasseTension.isNotEmpty;
      case 'groupe_electrogene':
        return groupeElectrogene.isNotEmpty;
      case 'alimentation_carburant':
        return alimentationCarburant.isNotEmpty;
      case 'inverseur':
        return inverseur.isNotEmpty;
      case 'stabilisateur':
        return stabilisateur.isNotEmpty;
      case 'onduleurs':
        return onduleurs.isNotEmpty;
      case 'regime_neutre':
        return regimeNeutre?.isNotEmpty == true;
      case 'eclairage_securite':
        return eclairageSecurite?.isNotEmpty == true;
      case 'modifications_installations':
        return modificationsInstallations?.isNotEmpty == true;
      case 'note_calcul':
        return noteCalcul?.isNotEmpty == true;
      case 'registre_securite':
        return registreSecurite?.isNotEmpty == true;
      case 'paratonnerre':
        return presenceParatonnerre != null &&
            analyseRisqueFoudre != null &&
            etudeTechniqueFoudre != null;
      default:
        return false;
    }
  }

  Map<String, bool> getProgress() {
    return {
      'alimentation_moyenne_tension': isSectionComplete('alimentation_moyenne_tension'),
      'alimentation_basse_tension': isSectionComplete('alimentation_basse_tension'),
      'groupe_electrogene': isSectionComplete('groupe_electrogene'),
      'alimentation_carburant': isSectionComplete('alimentation_carburant'),
      'inverseur': isSectionComplete('inverseur'),
      'stabilisateur': isSectionComplete('stabilisateur'),
      'onduleurs': isSectionComplete('onduleurs'),
      'regime_neutre': isSectionComplete('regime_neutre'),
      'eclairage_securite': isSectionComplete('eclairage_securite'),
      'modifications_installations': isSectionComplete('modifications_installations'),
      'note_calcul': isSectionComplete('note_calcul'),
      'registre_securite': isSectionComplete('registre_securite'),
      'paratonnerre': isSectionComplete('paratonnerre'),
    };
  }

  int getCompletionPercentage() {
    final progress = getProgress();
    final completed = progress.values.where((v) => v).length;
    return ((completed / progress.length) * 100).round();
  }
}
