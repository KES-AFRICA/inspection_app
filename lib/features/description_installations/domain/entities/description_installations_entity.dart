// lib/features/description_installations/domain/entities/description_installations_entity.dart
import 'installation_item_entity.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

class DescriptionInstallationsEntity {
  final String missionId;
  final List<InstallationItemEntity> alimentationMoyenneTension;
  final List<InstallationItemEntity> alimentationBasseTension;
  final List<InstallationItemEntity> groupeElectrogene;
  final List<InstallationItemEntity> alimentationCarburant;
  final List<InstallationItemEntity> inverseur;
  final List<InstallationItemEntity> stabilisateur;
  final List<InstallationItemEntity> onduleurs;
  final List<InstallationItemEntity> cpi;
  final String? regimeNeutre;
  final String? regimeNeutreDetail;
  final String? eclairageSecurite;
  final String? modificationsInstallations;
  final String? noteCalcul;
  final String? registreSecurite;
  final String? presenceParatonnerre;
  final String? analyseRisqueFoudre;
  final String? etudeTechniqueFoudre;
  final String? natureReseauAlimentationSite;
  final String? tensionAlimentationSite;
  final String? nombreAlimentationSite;
  final String? presenceIacmAlimentationSite;
  final List<ObservationLibre> foudreObservations;
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
    this.cpi = const [],
    this.regimeNeutre,
    this.regimeNeutreDetail,
    this.eclairageSecurite,
    this.modificationsInstallations,
    this.noteCalcul,
    this.registreSecurite,
    this.presenceParatonnerre,
    this.analyseRisqueFoudre,
    this.etudeTechniqueFoudre,
    this.natureReseauAlimentationSite,
    this.tensionAlimentationSite,
    this.nombreAlimentationSite,
    this.presenceIacmAlimentationSite,
    this.foudreObservations = const [],
    required this.updatedAt,
  });

  bool isSectionComplete(String sectionKey) {
    switch (sectionKey) {
      case 'alimentation_site_mt':
        return natureReseauAlimentationSite?.isNotEmpty == true ||
            tensionAlimentationSite?.isNotEmpty == true ||
            nombreAlimentationSite?.isNotEmpty == true ||
            presenceIacmAlimentationSite?.isNotEmpty == true;
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
      case 'cpi':
      case 'test_cpi':
        return cpi.isNotEmpty;
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
        if (presenceParatonnerre == 'Non') return true;
        if (presenceParatonnerre == 'Oui') return true;
        return presenceParatonnerre != null && presenceParatonnerre!.isNotEmpty;
      default:
        return false;
    }
  }

  Map<String, bool> getProgress() {
    final hasIt = regimeNeutre != null &&
        regimeNeutre!.split(',').map((e) => e.trim()).contains('IT');
    return {
      'alimentation_site_mt': isSectionComplete('alimentation_site_mt'),
      'alimentation_moyenne_tension': isSectionComplete('alimentation_moyenne_tension'),
      'alimentation_basse_tension': isSectionComplete('alimentation_basse_tension'),
      'groupe_electrogene': isSectionComplete('groupe_electrogene'),
      'alimentation_carburant': isSectionComplete('alimentation_carburant'),
      'inverseur': isSectionComplete('inverseur'),
      'stabilisateur': isSectionComplete('stabilisateur'),
      'onduleurs': isSectionComplete('onduleurs'),
      'regime_neutre': isSectionComplete('regime_neutre'),
      if (hasIt) 'test_cpi': isSectionComplete('test_cpi'),
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
