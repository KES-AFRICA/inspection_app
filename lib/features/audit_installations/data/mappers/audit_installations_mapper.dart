// lib/features/audit_installations/data/mappers/audit_installations_mapper.dart
import 'package:inspec_app/models/audit_installations_electriques.dart';
import '../../domain/entities/audit_installations_entities.dart';

class AuditInstallationsMapper {
  static String? _normRef(String? ref) {
    if (ref == null || ref.isEmpty) return ref;
    return ref.replaceAll(RegExp(r'§\s*'), 'art ');
  }

  // ElementControle
  static ElementControleEntity toElementEntity(ElementControle model) {
    return ElementControleEntity(
      elementControle: model.elementControle,
      conforme: model.conforme,
      observation: model.observation,
      priorite: model.priorite,
      photos: List<String>.from(model.photos),
      referenceNormative: _normRef(model.referenceNormativeEffective),
      estNA: model.estNA,
      familleRisque: model.familleRisqueEffective,
      criticite: model.criticiteEffective,
    );
  }

  static ElementControle toElementModel(ElementControleEntity entity) {
    return ElementControle(
      elementControle: entity.elementControle,
      conforme: entity.conforme,
      observation: entity.observation,
      priorite: entity.priorite,
      photos: List<String>.from(entity.photos),
      referenceNormative: _normRef(entity.referenceNormative),
      estNA: entity.estNA,
      familleRisque: entity.familleRisque,
      criticite: entity.criticite,
    );
  }

  // Cellule
  static CelluleEntity toCelluleEntity(Cellule model) {
    return CelluleEntity(
      fonction: model.fonction,
      type: model.type,
      marqueModeleAnnee: model.marqueModeleAnnee,
      tensionAssignee: model.tensionAssignee,
      pouvoirCoupure: model.pouvoirCoupure,
      numerotation: model.numerotation,
      parafoudres: model.parafoudres,
      elementsVerifies: model.elementsVerifies.map(toElementEntity).toList(),
      photos: List<String>.from(model.photos),
      gamme: model.gamme,
      calibreDisjoncteur: model.calibreDisjoncteur,
      sectionCables: model.sectionCables,
      natureReseau: model.natureReseau,
      presenceIacm: model.presenceIacm,
      syncId: model.syncId,
      observations: model.observations?.map(toElementEntity).toList(),
    );
  }

  static Cellule toCelluleModel(CelluleEntity entity) {
    return Cellule(
      fonction: entity.fonction,
      type: entity.type,
      marqueModeleAnnee: entity.marqueModeleAnnee,
      tensionAssignee: entity.tensionAssignee,
      pouvoirCoupure: entity.pouvoirCoupure,
      numerotation: entity.numerotation,
      parafoudres: entity.parafoudres,
      elementsVerifies: entity.elementsVerifies.map(toElementModel).toList(),
      photos: List<String>.from(entity.photos),
      gamme: entity.gamme,
      calibreDisjoncteur: entity.calibreDisjoncteur,
      sectionCables: entity.sectionCables,
      natureReseau: entity.natureReseau,
      presenceIacm: entity.presenceIacm,
      syncId: entity.syncId,
      observations: entity.observations?.map(toElementModel).toList(),
    );
  }

  // TransformateurMTBT
  static TransformateurMTBTEntity toTransformateurEntity(TransformateurMTBT model) {
    return TransformateurMTBTEntity(
      typeTransformateur: model.typeTransformateur,
      marqueAnnee: model.marqueAnnee,
      puissanceAssignee: model.puissanceAssignee,
      tensionPrimaireSecondaire: model.tensionPrimaireSecondaire,
      relaisBuchholz: model.relaisBuchholz,
      typeRefroidissement: model.typeRefroidissement,
      regimeNeutre: model.regimeNeutre,
      elementsVerifies: model.elementsVerifies.map(toElementEntity).toList(),
      photos: List<String>.from(model.photos),
      calibreDisjoncteur: model.calibreDisjoncteur,
      sectionCables: model.sectionCables,
      syncId: model.syncId,
      observations: model.observations?.map(toElementEntity).toList(),
    );
  }

  static TransformateurMTBT toTransformateurModel(TransformateurMTBTEntity entity) {
    return TransformateurMTBT(
      typeTransformateur: entity.typeTransformateur,
      marqueAnnee: entity.marqueAnnee,
      puissanceAssignee: entity.puissanceAssignee,
      tensionPrimaireSecondaire: entity.tensionPrimaireSecondaire,
      relaisBuchholz: entity.relaisBuchholz,
      typeRefroidissement: entity.typeRefroidissement,
      regimeNeutre: entity.regimeNeutre,
      elementsVerifies: entity.elementsVerifies.map(toElementModel).toList(),
      photos: List<String>.from(entity.photos),
      calibreDisjoncteur: entity.calibreDisjoncteur,
      sectionCables: entity.sectionCables,
      syncId: entity.syncId,
      observations: entity.observations?.map(toElementModel).toList(),
    );
  }

  // Alimentation
  static AlimentationEntity toAlimentationEntity(Alimentation model) {
    return AlimentationEntity(
      typeProtection: model.typeProtection,
      courbe: model.courbe,
      pdcKA: model.pdcKA,
      calibre: model.calibre,
      sectionCable: model.sectionCable,
      photos: List<String>.from(model.photos),
      source: model.source,
    );
  }

  static Alimentation toAlimentationModel(AlimentationEntity entity) {
    return Alimentation(
      typeProtection: entity.typeProtection,
      courbe: entity.courbe ?? '',
      pdcKA: entity.pdcKA,
      calibre: entity.calibre,
      sectionCable: entity.sectionCable,
      photos: List<String>.from(entity.photos),
      source: entity.source,
    );
  }

  // PointVerification
  static PointVerificationEntity toPointVerificationEntity(PointVerification model) {
    return PointVerificationEntity(
      pointVerification: model.pointVerification,
      conformite: model.conformite,
      observation: model.observation,
      referenceNormative: _normRef(model.referenceNormative),
      priorite: model.priorite,
      photos: List<String>.from(model.photos),
    );
  }

  static PointVerification toPointVerificationModel(PointVerificationEntity entity) {
    return PointVerification(
      pointVerification: entity.pointVerification,
      conformite: entity.conformite,
      observation: entity.observation,
      referenceNormative: _normRef(entity.referenceNormative),
      priorite: entity.priorite,
      photos: List<String>.from(entity.photos),
    );
  }

  // ObservationLibre
  static ObservationLibreEntity toObservationLibreEntity(ObservationLibre model) {
    return ObservationLibreEntity(
      texte: model.texte,
      photos: List<String>.from(model.photos),
      dateCreation: model.dateCreation,
      dateModification: model.dateModification,
    );
  }

  static ObservationLibre toObservationLibreModel(ObservationLibreEntity entity) {
    return ObservationLibre(
      texte: entity.texte,
      photos: List<String>.from(entity.photos),
      dateCreation: entity.dateCreation,
      dateModification: entity.dateModification,
    );
  }

  // CoffretArmoire
  static CoffretArmoireEntity toCoffretEntity(CoffretArmoire model) {
    return CoffretArmoireEntity(
      qrCode: model.qrCode,
      nom: model.nom,
      type: model.type,
      description: model.description,
      repere: model.repere,
      zoneAtex: model.zoneAtex,
      domaineTension: model.domaineTension,
      identificationArmoire: model.identificationArmoire,
      signalisationDanger: model.signalisationDanger,
      presenceSchema: model.presenceSchema,
      presenceParafoudre: model.presenceParafoudre,
      verificationThermographie: model.verificationThermographie,
      alimentations: model.alimentations.map(toAlimentationEntity).toList(),
      protectionTete: model.protectionTete != null ? toAlimentationEntity(model.protectionTete!) : null,
      pointsVerification: model.pointsVerification.map(toPointVerificationEntity).toList(),
      observationsLibres: model.observationsLibres.map(toObservationLibreEntity).toList(),
      photos: List<String>.from(model.photos),
      numeroEquipement: model.numeroEquipement,
      statut: model.statut,
      currentStep: model.currentStep,
      photosExternes: List<String>.from(model.photosExternes),
      photosInternes: List<String>.from(model.photosInternes),
      observationsParafoudre: model.observationsParafoudre.map(toObservationLibreEntity).toList(),
    );
  }

  static CoffretArmoire toCoffretModel(CoffretArmoireEntity entity) {
    return CoffretArmoire(
      qrCode: entity.qrCode,
      nom: entity.nom,
      type: entity.type,
      description: entity.description,
      repere: entity.repere,
      zoneAtex: entity.zoneAtex,
      domaineTension: entity.domaineTension,
      identificationArmoire: entity.identificationArmoire,
      signalisationDanger: entity.signalisationDanger,
      presenceSchema: entity.presenceSchema,
      presenceParafoudre: entity.presenceParafoudre,
      verificationThermographie: entity.verificationThermographie,
      alimentations: entity.alimentations.map(toAlimentationModel).toList(),
      protectionTete: entity.protectionTete != null ? toAlimentationModel(entity.protectionTete!) : null,
      pointsVerification: entity.pointsVerification.map(toPointVerificationModel).toList(),
      observationsLibres: entity.observationsLibres.map(toObservationLibreModel).toList(),
      photos: List<String>.from(entity.photos),
      numeroEquipement: entity.numeroEquipement,
      statut: entity.statut,
      currentStep: entity.currentStep,
      photosExternes: List<String>.from(entity.photosExternes),
      photosInternes: List<String>.from(entity.photosInternes),
      observationsParafoudre: entity.observationsParafoudre.map(toObservationLibreModel).toList(),
    );
  }

  // MoyenneTensionLocal
  static MoyenneTensionLocalEntity toMoyenneTensionLocalEntity(MoyenneTensionLocal model) {
    model.migrateFromOldFields();
    return MoyenneTensionLocalEntity(
      nom: model.nom,
      type: model.type,
      dispositionsConstructives: model.dispositionsConstructives.map(toElementEntity).toList(),
      conditionsExploitation: model.conditionsExploitation.map(toElementEntity).toList(),
      coffrets: model.coffrets.map(toCoffretEntity).toList(),
      observationsLibres: model.observationsLibres.map(toObservationLibreEntity).toList(),
      photos: List<String>.from(model.photos),
      cellules: model.cellules.map(toCelluleEntity).toList(),
      transformateurs: model.transformateurs.map(toTransformateurEntity).toList(),
      accessible: model.accessible,
      aReverifier: model.aReverifier,
      isRiskZone: model.isRiskZone,
    );
  }

  static MoyenneTensionLocal toMoyenneTensionLocalModel(MoyenneTensionLocalEntity entity) {
    return MoyenneTensionLocal(
      nom: entity.nom,
      type: entity.type,
      dispositionsConstructives: entity.dispositionsConstructives.map(toElementModel).toList(),
      conditionsExploitation: entity.conditionsExploitation.map(toElementModel).toList(),
      coffrets: entity.coffrets.map(toCoffretModel).toList(),
      observationsLibres: entity.observationsLibres.map(toObservationLibreModel).toList(),
      photos: List<String>.from(entity.photos),
      cellules: entity.cellules.map(toCelluleModel).toList(),
      transformateurs: entity.transformateurs.map(toTransformateurModel).toList(),
      accessible: entity.accessible,
      aReverifier: entity.aReverifier,
      isRiskZone: entity.isRiskZone,
    );
  }

  // MoyenneTensionZone
  static MoyenneTensionZoneEntity toMoyenneTensionZoneEntity(MoyenneTensionZone model) {
    return MoyenneTensionZoneEntity(
      nom: model.nom,
      description: model.description,
      coffrets: model.coffrets.map(toCoffretEntity).toList(),
      observationsLibres: model.observationsLibres.map(toObservationLibreEntity).toList(),
      photos: List<String>.from(model.photos),
      locaux: model.locaux.map(toMoyenneTensionLocalEntity).toList(),
      classementZoneId: model.classementZoneId,
      isRiskZone: model.isRiskZone,
    );
  }

  static MoyenneTensionZone toMoyenneTensionZoneModel(MoyenneTensionZoneEntity entity) {
    return MoyenneTensionZone(
      nom: entity.nom,
      description: entity.description,
      coffrets: entity.coffrets.map(toCoffretModel).toList(),
      observationsLibres: entity.observationsLibres.map(toObservationLibreModel).toList(),
      photos: List<String>.from(entity.photos),
      locaux: entity.locaux.map(toMoyenneTensionLocalModel).toList(),
      classementZoneId: entity.classementZoneId,
      isRiskZone: entity.isRiskZone,
    );
  }

  // BasseTensionLocal
  static BasseTensionLocalEntity toBasseTensionLocalEntity(BasseTensionLocal model) {
    return BasseTensionLocalEntity(
      nom: model.nom,
      type: model.type,
      dispositionsConstructives: model.dispositionsConstructives?.map(toElementEntity).toList() ?? const [],
      conditionsExploitation: model.conditionsExploitation?.map(toElementEntity).toList() ?? const [],
      coffrets: model.coffrets.map(toCoffretEntity).toList(),
      observationsLibres: model.observationsLibres.map(toObservationLibreEntity).toList(),
      photos: List<String>.from(model.photos),
      accessible: model.accessible,
      aReverifier: model.aReverifier,
      cellules: model.cellules.map(toCelluleEntity).toList(),
      transformateurs: model.transformateurs.map(toTransformateurEntity).toList(),
      isRiskZone: model.isRiskZone,
    );
  }

  static BasseTensionLocal toBasseTensionLocalModel(BasseTensionLocalEntity entity) {
    return BasseTensionLocal(
      nom: entity.nom,
      type: entity.type,
      dispositionsConstructives: entity.dispositionsConstructives.map(toElementModel).toList(),
      conditionsExploitation: entity.conditionsExploitation.map(toElementModel).toList(),
      coffrets: entity.coffrets.map(toCoffretModel).toList(),
      observationsLibres: entity.observationsLibres.map(toObservationLibreModel).toList(),
      photos: List<String>.from(entity.photos),
      accessible: entity.accessible,
      aReverifier: entity.aReverifier,
      cellules: entity.cellules.map(toCelluleModel).toList(),
      transformateurs: entity.transformateurs.map(toTransformateurModel).toList(),
      isRiskZone: entity.isRiskZone,
    );
  }

  // BasseTensionZone
  static BasseTensionZoneEntity toBasseTensionZoneEntity(BasseTensionZone model) {
    return BasseTensionZoneEntity(
      nom: model.nom,
      description: model.description,
      locaux: model.locaux.map(toBasseTensionLocalEntity).toList(),
      coffretsDirects: model.coffretsDirects.map(toCoffretEntity).toList(),
      observationsLibres: model.observationsLibres.map(toObservationLibreEntity).toList(),
      photos: List<String>.from(model.photos),
      classementZoneId: model.classementZoneId,
      isRiskZone: model.isRiskZone,
    );
  }

  static BasseTensionZone toBasseTensionZoneModel(BasseTensionZoneEntity entity) {
    return BasseTensionZone(
      nom: entity.nom,
      description: entity.description,
      locaux: entity.locaux.map(toBasseTensionLocalModel).toList(),
      coffretsDirects: entity.coffretsDirects.map(toCoffretModel).toList(),
      observationsLibres: entity.observationsLibres.map(toObservationLibreModel).toList(),
      photos: List<String>.from(entity.photos),
      classementZoneId: entity.classementZoneId,
      isRiskZone: entity.isRiskZone,
    );
  }

  // AuditInstallationsElectriques
  static AuditInstallationsElectriquesEntity toEntity(AuditInstallationsElectriques model) {
    return AuditInstallationsElectriquesEntity(
      missionId: model.missionId,
      updatedAt: model.updatedAt,
      moyenneTensionLocaux: model.moyenneTensionLocaux.map(toMoyenneTensionLocalEntity).toList(),
      moyenneTensionZones: model.moyenneTensionZones.map(toMoyenneTensionZoneEntity).toList(),
      basseTensionZones: model.basseTensionZones.map(toBasseTensionZoneEntity).toList(),
      photos: List<String>.from(model.photos),
    );
  }

  static AuditInstallationsElectriques toModel(AuditInstallationsElectriquesEntity entity) {
    return AuditInstallationsElectriques(
      missionId: entity.missionId,
      updatedAt: entity.updatedAt,
      moyenneTensionLocaux: entity.moyenneTensionLocaux.map(toMoyenneTensionLocalModel).toList(),
      moyenneTensionZones: entity.moyenneTensionZones.map(toMoyenneTensionZoneModel).toList(),
      basseTensionZones: entity.basseTensionZones.map(toBasseTensionZoneModel).toList(),
      photos: List<String>.from(entity.photos),
    );
  }
}
