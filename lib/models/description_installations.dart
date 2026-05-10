import 'package:hive/hive.dart';

part 'description_installations.g.dart';

@HiveType(typeId: 2)
class DescriptionInstallations extends HiveObject {
  @HiveField(0)
  String missionId;

  // Caractéristiques de l'alimentation moyenne tension
  @HiveField(1)
  List<InstallationItem> alimentationMoyenneTension;

  // Caractéristiques de l'alimentation basse tension sortie transformateur
  @HiveField(2)
  List<InstallationItem> alimentationBasseTension;

  // Caractéristiques du groupe électrogène
  @HiveField(3)
  List<InstallationItem> groupeElectrogene;

  // Alimentation du groupe électrogène en carburant
  @HiveField(4)
  List<InstallationItem> alimentationCarburant;

  // Caractéristiques de l'inverseur
  @HiveField(5)
  List<InstallationItem> inverseur;

  // Caractéristiques du stabilisateur
  @HiveField(6)
  List<InstallationItem> stabilisateur;

  // Caractéristiques des onduleurs
  @HiveField(7)
  List<InstallationItem> onduleurs;

  // Sélections radio
  @HiveField(8)
  String? regimeNeutre;

  @HiveField(17)
  String? regimeNeutreDetail;

  @HiveField(9)
  String? eclairageSecurite;

  @HiveField(10)
  String? modificationsInstallations;

  @HiveField(11)
  String? noteCalcul;

  @HiveField(12)
  String? registreSecurite;

  // Paratonnerre
  @HiveField(13)
  String? presenceParatonnerre;

  @HiveField(14)
  String? analyseRisqueFoudre;

  @HiveField(15)
  String? etudeTechniqueFoudre;

  @HiveField(16)
  DateTime updatedAt;

  DescriptionInstallations({
    required this.missionId,
    List<InstallationItem>? alimentationMoyenneTension,
    List<InstallationItem>? alimentationBasseTension,
    List<InstallationItem>? groupeElectrogene,
    List<InstallationItem>? alimentationCarburant,
    List<InstallationItem>? inverseur,
    List<InstallationItem>? stabilisateur,
    List<InstallationItem>? onduleurs,
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
  })  : alimentationMoyenneTension = alimentationMoyenneTension ?? [],
        alimentationBasseTension = alimentationBasseTension ?? [],
        groupeElectrogene = groupeElectrogene ?? [],
        alimentationCarburant = alimentationCarburant ?? [],
        inverseur = inverseur ?? [],
        stabilisateur = stabilisateur ?? [],
        onduleurs = onduleurs ?? [];

  factory DescriptionInstallations.create(String missionId) {
    return DescriptionInstallations(
      missionId: missionId,
      updatedAt: DateTime.now(),
      alimentationMoyenneTension: [],
      alimentationBasseTension: [],
      groupeElectrogene: [],
      alimentationCarburant: [],
      inverseur: [],
      stabilisateur: [],
      onduleurs: [],
    );
  }

  // Ajouter un élément à une section (SAFE)
  void addInstallationItem(String sectionKey, InstallationItem item) {
    switch (sectionKey) {
      case 'alimentation_moyenne_tension':
        alimentationMoyenneTension.add(item);
        break;
      case 'alimentation_basse_tension':
        alimentationBasseTension.add(item);
        break;
      case 'groupe_electrogene':
        groupeElectrogene.add(item);
        break;
      case 'alimentation_carburant':
        alimentationCarburant.add(item);
        break;
      case 'inverseur':
        inverseur.add(item);
        break;
      case 'stabilisateur':
        stabilisateur.add(item);
        break;
      case 'onduleurs':
        onduleurs.add(item);
        break;
      default:
        throw Exception('Section inconnue: $sectionKey');
    }
  }

  // Vérifier si une section est complète
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

  // Progression
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

@HiveType(typeId: 25)
class InstallationItem extends HiveObject {
  @HiveField(0)
  Map<String, String> data;

  @HiveField(1)
  List<String> photoPaths;

  @HiveField(2)
  DateTime createdAt;

  InstallationItem({
    required Map<String, String> data,
    List<String>? photoPaths,
    DateTime? createdAt,
  })  : data = Map<String, String>.from(data),
        photoPaths = photoPaths ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isComplete(List<String> requiredFields) {
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool hasPhotos() => photoPaths.isNotEmpty;

  void addPhoto(String path) {
    photoPaths.add(path);
  }

  void removePhoto(String path) {
    photoPaths.remove(path);
  }

  void updateField(String field, String value) {
    data[field] = value;
  }
}
