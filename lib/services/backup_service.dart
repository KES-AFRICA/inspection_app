// lib/services/backup_service.dart
// ============================================================
// SYSTÈME DE SAUVEGARDE ET RESTAURATION COMPLÈTE
// Schema version : 2
// Rétrocompatible V1 : les sauvegardes V1 sont importables.
// Nouveautés V2 :
//   - exporterMission(missionId) : export ciblé d'une seule mission
//   - deleteMissionCompletely(missionId) : suppression totale sécurisée
//   - Checksum SHA-256 sur chaque export (détection de corruption)
//   - Magic V2 : INSPEC_BACKUP_V2
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/mission.dart';
import '../models/audit_installations_electriques.dart';
import '../models/description_installations.dart';
import '../models/classement_locaux.dart';
import '../models/classement_zone.dart';
import '../models/foudre.dart';
import '../models/mesures_essais.dart';
import '../models/jsa.dart';
import '../models/renseignements_generaux.dart';
import 'hive_service.dart';
import 'sequence_progress_service.dart';

// ─────────────────────────────────────────────────────────────
// RÉSULTATS TYPÉS
// ─────────────────────────────────────────────────────────────
class BackupResult {
  final bool success;
  final String? message;
  final String? filePath;
  final int? missionCount;
  final String? errorDetail;
  const BackupResult({
    required this.success,
    this.message,
    this.filePath,
    this.missionCount,
    this.errorDetail,
  });
}

class ImportResult {
  final bool success;
  final String? message;
  final int importedMissions;
  final int skippedMissions;
  final List<String> warnings;
  final String? errorDetail;
  const ImportResult({
    required this.success,
    this.message,
    this.importedMissions = 0,
    this.skippedMissions = 0,
    this.warnings = const [],
    this.errorDetail,
  });
}

// ─────────────────────────────────────────────────────────────
// RÉSULTAT DE SUPPRESSION
// ─────────────────────────────────────────────────────────────
class DeleteResult {
  final bool success;
  final String? message;
  final int deletedPhotos;
  const DeleteResult({
    required this.success,
    this.message,
    this.deletedPhotos = 0,
  });
}

// ─────────────────────────────────────────────────────────────
// SERVICE PRINCIPAL
// ─────────────────────────────────────────────────────────────
class BackupService {
  static const int _schemaVersion = 2;
  static const String _magic   = 'INSPEC_BACKUP_V2';
  static const String _magicV1 = 'INSPEC_BACKUP_V1'; // rétrocompat import

  // ═══════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════

  static Future<BackupResult> exporterMissions(String matricule) async {
    try {
      final missions = HiveService.getMissionsByMatricule(matricule);
      if (missions.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Aucune mission à exporter.',
        );
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = 'inspec_backup_${matricule}_$ts.json';

      // 1. Sauvegarde dans Downloads/Verif Elec/ (même dossier que les rapports)
      File? savedFile;
      String? savedPath;
      try {
        final downloadsPath = Platform.isAndroid
            ? await ExternalPath.getExternalStoragePublicDirectory(
                ExternalPath.DIRECTORY_DOWNLOAD)
            : (await getApplicationDocumentsDirectory()).path;
        final verifElecDir = Directory('$downloadsPath/Verif Elec');
        if (!await verifElecDir.exists()) {
          await verifElecDir.create(recursive: true);
        }
        savedFile = File('${verifElecDir.path}/$fileName');
        
        // Sérialisation des métadonnées et structures Hive légères (sans les photos)
        final serializedMissions = <Map<String, dynamic>>[];
        for (final m in missions) {
          serializedMissions.add(await _serializeMissionStructureOnly(m));
        }

        final params = ExportParams(
          filePath: savedFile.path,
          magic: _magic,
          schemaVersion: _schemaVersion,
          exportedAt: DateTime.now().toIso8601String(),
          appVersion: '2.0.0',
          exportType: 'all_missions',
          matricule: matricule,
          missionsData: serializedMissions,
          localDrafts: _serializeLocalDrafts(missions.map((m) => m.id).toList()),
          coffretDrafts: _serializeCoffretDrafts(missions.map((m) => m.id).toList()),
        );

        // Lancer l'Isolate d'écriture progressive par flux
        await compute(_performStreamingExport, params);
        savedPath = savedFile.path;
        if (kDebugMode) print('✅ Backup sauvegardé de façon progressive: $savedPath');
      } catch (e, st) {
        if (kDebugMode) print('⚠️ Sauvegarde locale échouée: $e\n$st');
      }

      // 2. Partage via share_plus (email, Drive, WhatsApp, etc.)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      // Si la sauvegarde locale a réussi, on copie le fichier
      if (savedFile != null && savedFile.existsSync()) {
        await savedFile.copy(tempFile.path);
      } else {
        // Fallback de génération directement vers temp
        final serializedMissions = <Map<String, dynamic>>[];
        for (final m in missions) {
          serializedMissions.add(await _serializeMissionStructureOnly(m));
        }
        final params = ExportParams(
          filePath: tempFile.path,
          magic: _magic,
          schemaVersion: _schemaVersion,
          exportedAt: DateTime.now().toIso8601String(),
          appVersion: '2.0.0',
          exportType: 'all_missions',
          matricule: matricule,
          missionsData: serializedMissions,
          localDrafts: _serializeLocalDrafts(missions.map((m) => m.id).toList()),
          coffretDrafts: _serializeCoffretDrafts(missions.map((m) => m.id).toList()),
        );
        await compute(_performStreamingExport, params);
      }

      final xFile = XFile(tempFile.path, mimeType: 'application/json');
      await Share.shareXFiles(
        [xFile],
        subject: 'Sauvegarde Inspec — $ts',
        text: '${missions.length} mission(s) — $ts',
      );

      final localMsg = savedPath != null
          ? '\nFichier aussi sauvegardé dans Downloads/Verif Elec/'
          : '';

      return BackupResult(
        success: true,
        message: '${missions.length} mission(s) exportée(s).$localMsg',
        filePath: savedPath ?? tempFile.path,
        missionCount: missions.length,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ Export: $e\n$st');
      return BackupResult(
        success: false,
        message: "Erreur lors de l'export.",
        errorDetail: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // EXPORT CIBLÉ D'UNE SEULE MISSION
  // ─────────────────────────────────────────────────────────

  static Future<BackupResult> exporterMission(String missionId) async {
    try {
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) {
        return const BackupResult(
          success: false,
          message: 'Mission introuvable.',
        );
      }

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final safeClient =
          mission.nomClient.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = 'inspec_${safeClient}_$ts.json';

      // Sauvegarde locale
      String? savedPath;
      File? savedFile;
      try {
        final downloadsPath = Platform.isAndroid
            ? await ExternalPath.getExternalStoragePublicDirectory(
                ExternalPath.DIRECTORY_DOWNLOAD)
            : (await getApplicationDocumentsDirectory()).path;
        final dir = Directory('$downloadsPath/Verif Elec');
        if (!await dir.exists()) await dir.create(recursive: true);
        savedFile = File('${dir.path}/$fileName');

        final serializedMission = await _serializeMissionStructureOnly(mission);

        final params = ExportParams(
          filePath: savedFile.path,
          magic: _magic,
          schemaVersion: _schemaVersion,
          exportedAt: DateTime.now().toIso8601String(),
          appVersion: '2.0.0',
          exportType: 'single_mission',
          missionsData: [serializedMission],
          localDrafts: _serializeLocalDrafts([mission.id]),
          coffretDrafts: _serializeCoffretDrafts([mission.id]),
        );

        await compute(_performStreamingExport, params);
        savedPath = savedFile.path;
        if (kDebugMode) print('✅ Backup mission sauvegardé par streaming: $savedPath');
      } catch (e, st) {
        if (kDebugMode) print('⚠️ Sauvegarde locale ignorée: $e\n$st');
      }

      // Partage
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      if (savedFile != null && savedFile.existsSync()) {
        await savedFile.copy(tempFile.path);
      } else {
        final serializedMission = await _serializeMissionStructureOnly(mission);
        final params = ExportParams(
          filePath: tempFile.path,
          magic: _magic,
          schemaVersion: _schemaVersion,
          exportedAt: DateTime.now().toIso8601String(),
          appVersion: '2.0.0',
          exportType: 'single_mission',
          missionsData: [serializedMission],
          localDrafts: _serializeLocalDrafts([mission.id]),
          coffretDrafts: _serializeCoffretDrafts([mission.id]),
        );
        await compute(_performStreamingExport, params);
      }

      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/json')],
        subject: 'Sauvegarde — ${mission.nomClient}',
        text: 'Export mission ${mission.nomClient} ($ts)',
      );

      return BackupResult(
        success: true,
        message: 'Mission exportée avec succès.',
        filePath: savedPath ?? tempFile.path,
        missionCount: 1,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ exporterMission: $e\n$st');
      return BackupResult(
        success: false,
        message: "Erreur lors de l'export de la mission.",
        errorDetail: e.toString(),
      );
    }
  }

  // ── Mission + structure de ses données liées (sans charger les photos en Base64) ──
  static Future<Map<String, dynamic>> _serializeMissionStructureOnly(Mission m) async {
    final id = m.id;
    final audit = HiveService.getAuditInstallationsByMissionId(id);
    final desc = HiveService.getDescriptionInstallationsByMissionId(id);
    final mesures = HiveService.getMesuresEssaisByMissionId(id);
    final jsa = HiveService.getJSAByMissionId(id);
    final rens = HiveService.getRenseignementsGenerauxByMissionId(id);
    final foudres = HiveService.getFoudreObservationsByMissionId(id);
    final classements = _classementsByMission(id);
    final classementZones = _classementZonesByMission(id);
    final sequenceProgress = await SequenceProgressService.getProgress(id);

    // Ne pas collecter le base64 ici, seulement collecter la liste de chemins physiques
    final photoPaths = audit != null ? _collectAllPhotoPaths(audit) : <String>[];

    return {
      'mission': m.toJson(),
      'photo_paths': photoPaths, // Utilisé uniquement pour l'Isolate de streaming
      'audit': audit != null ? _serializeAudit(audit) : null,

      'description_installations':
          desc != null ? _serializeDescription(desc) : null,
      'mesures_essais': mesures != null ? _serializeMesures(mesures) : null,
      'jsa': jsa != null ? _serializeJSA(jsa) : null,
      'renseignements_generaux':
          rens != null ? _serializeRenseignements(rens) : null,
      'foudre_observations': foudres.map(_f).toList(),
      'classements_locaux': classements,
      'classements_zones': classementZones,
      'sequence_progress': sequenceProgress,
    };
  }

  // ── Audit installations ──
  static Map<String, dynamic> _serializeAudit(
      AuditInstallationsElectriques a) {
    return {
      'missionId': a.missionId,
      'updatedAt': a.updatedAt.toIso8601String(),
      'photos': a.photos,
      'moyenneTensionLocaux':
          a.moyenneTensionLocaux.map(_serializeMTLocal).toList(),
      'moyenneTensionZones':
          a.moyenneTensionZones.map(_serializeMTZone).toList(),
      'basseTensionZones':
          a.basseTensionZones.map(_serializeBTZone).toList(),
    };
  }

  static Map<String, dynamic> _serializeMTLocal(MoyenneTensionLocal l) => {
        'nom': l.nom,
        'type': l.type,
        'accessible': l.accessible,
        'aReverifier': l.aReverifier,
        'photos': l.photos,
        'dispositionsConstructives':
            l.dispositionsConstructives.map(_serializeElement).toList(),
        'conditionsExploitation':
            l.conditionsExploitation.map(_serializeElement).toList(),
        // Ancien champ unique (rétrocompat)
        'cellule': l.cellule != null ? _serializeCellule(l.cellule!) : null,
        'transformateur': l.transformateur != null
            ? _serializeTransformateur(l.transformateur!)
            : null,
        // Nouvelles listes
        'cellules': l.cellules.map(_serializeCellule).toList(),
        'transformateurs':
            l.transformateurs.map(_serializeTransformateur).toList(),
        'coffrets': l.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres':
            l.observationsLibres.map(_serializeObs).toList(),
      };

  static Map<String, dynamic> _serializeMTZone(MoyenneTensionZone z) => {
        'nom': z.nom,
        'description': z.description,
        'photos': z.photos,
        'classementZoneId': z.classementZoneId,
        'coffrets': z.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres': z.observationsLibres.map(_serializeObs).toList(),
        'locaux': z.locaux.map(_serializeMTLocal).toList(),
      };

  static Map<String, dynamic> _serializeBTZone(BasseTensionZone z) => {
        'nom': z.nom,
        'description': z.description,
        'photos': z.photos,
        'classementZoneId': z.classementZoneId,
        'coffretsDirects': z.coffretsDirects.map(_serializeCoffret).toList(),
        'observationsLibres': z.observationsLibres.map(_serializeObs).toList(),
        'locaux': z.locaux.map(_serializeBTLocal).toList(),
      };

  static Map<String, dynamic> _serializeBTLocal(BasseTensionLocal l) => {
        'nom': l.nom,
        'type': l.type,
        'accessible': l.accessible,
        'aReverifier': l.aReverifier,
        'photos': l.photos,
        'dispositionsConstructives':
            (l.dispositionsConstructives ?? []).map(_serializeElement).toList(),
        'conditionsExploitation':
            (l.conditionsExploitation ?? []).map(_serializeElement).toList(),
        // Fields 9 et 10 — présents si build_runner a été relancé
        'cellules': l.cellules.map(_serializeCellule).toList(),
        'transformateurs': l.transformateurs.map(_serializeTransformateur).toList(),
        'coffrets': l.coffrets.map(_serializeCoffret).toList(),
        'observationsLibres': l.observationsLibres.map(_serializeObs).toList(),
      };

  static Map<String, dynamic> _serializeElement(ElementControle e) => {
        'elementControle': e.elementControle,
        'conforme': e.conforme,
        'observation': e.observation,
        'priorite': e.priorite,
        'photos': e.photos,
        'referenceNormative': e.referenceNormative,
        'estNA': e.estNA,
      };

  static Map<String, dynamic> _serializeCellule(Cellule c) => {
        'fonction': c.fonction,
        'type': c.type,
        'marqueModeleAnnee': c.marqueModeleAnnee,
        'tensionAssignee': c.tensionAssignee,
        'pouvoirCoupure': c.pouvoirCoupure,
        'numerotation': c.numerotation,
        'parafoudres': c.parafoudres,
        'photos': c.photos,
        'elementsVerifies':
            c.elementsVerifies.map(_serializeElement).toList(),
      };

  static Map<String, dynamic> _serializeTransformateur(
          TransformateurMTBT t) =>
      {
        'typeTransformateur': t.typeTransformateur,
        'marqueAnnee': t.marqueAnnee,
        'puissanceAssignee': t.puissanceAssignee,
        'tensionPrimaireSecondaire': t.tensionPrimaireSecondaire,
        'relaisBuchholz': t.relaisBuchholz,
        'typeRefroidissement': t.typeRefroidissement,
        'regimeNeutre': t.regimeNeutre,
        'photos': t.photos,
        'elementsVerifies':
            t.elementsVerifies.map(_serializeElement).toList(),
      };

  static Map<String, dynamic> _serializeCoffret(CoffretArmoire c) => {
        'qrCode': c.qrCode,
        'nom': c.nom,
        'type': c.type,
        'description': c.description,
        'repere': c.repere,
        'numeroEquipement': c.numeroEquipement,
        'statut': c.statut,
        'currentStep': c.currentStep,
        'zoneAtex': c.zoneAtex,
        'domaineTension': c.domaineTension,
        'identificationArmoire': c.identificationArmoire,
        'signalisationDanger': c.signalisationDanger,
        'presenceSchema': c.presenceSchema,
        'presenceParafoudre': c.presenceParafoudre,
        'verificationThermographie': c.verificationThermographie,
        'photos': c.photos,
        'photosExternes': c.photosExternes,
        'photosInternes': c.photosInternes,
        'alimentations': c.alimentations.map(_serializeAlim).toList(),
        'protectionTete': c.protectionTete != null
            ? _serializeAlim(c.protectionTete!)
            : null,
        'pointsVerification':
            c.pointsVerification.map(_serializePoint).toList(),
        'observationsLibres': c.observationsLibres.map(_serializeObs).toList(),
        'observationsParafoudre':
            c.observationsParafoudre.map(_serializeObs).toList(),
      };

  static Map<String, dynamic> _serializeAlim(Alimentation a) => {
        'typeProtection': a.typeProtection,
        'pdcKA': a.pdcKA,
        'calibre': a.calibre,
        'sectionCable': a.sectionCable,
        'source': a.source,
        'photos': a.photos,
      };

  static Map<String, dynamic> _serializePoint(PointVerification p) => {
        'pointVerification': p.pointVerification,
        'conformite': p.conformite,
        'observation': p.observation,
        'referenceNormative': p.referenceNormative,
        'priorite': p.priorite,
        'photos': p.photos,
      };

  static Map<String, dynamic> _serializeObs(ObservationLibre o) => {
        'texte': o.texte,
        'photos': o.photos,
        'dateCreation': o.dateCreation.toIso8601String(),
        'dateModification': o.dateModification.toIso8601String(),
      };

  // ── Description des installations ──
  static Map<String, dynamic> _serializeDescription(
      DescriptionInstallations d) =>
      {
        'missionId': d.missionId,
        'alimentationMoyenneTension': d.alimentationMoyenneTension
            .map(_serializeInstallationItem)
            .toList(),
        'alimentationBasseTension': d.alimentationBasseTension
            .map(_serializeInstallationItem)
            .toList(),
        'groupeElectrogene':
            d.groupeElectrogene.map(_serializeInstallationItem).toList(),
        'alimentationCarburant':
            d.alimentationCarburant.map(_serializeInstallationItem).toList(),
        'inverseur': d.inverseur.map(_serializeInstallationItem).toList(),
        'stabilisateur':
            d.stabilisateur.map(_serializeInstallationItem).toList(),
        'onduleurs': d.onduleurs.map(_serializeInstallationItem).toList(),
        'regimeNeutre': d.regimeNeutre,
        'regimeNeutreDetail': d.regimeNeutreDetail,
        'eclairageSecurite': d.eclairageSecurite,
        'modificationsInstallations': d.modificationsInstallations,
        'noteCalcul': d.noteCalcul,
        'registreSecurite': d.registreSecurite,
        'presenceParatonnerre': d.presenceParatonnerre,
        'analyseRisqueFoudre': d.analyseRisqueFoudre,
        'etudeTechniqueFoudre': d.etudeTechniqueFoudre,
        'updatedAt': d.updatedAt.toIso8601String(),
      };

  static Map<String, dynamic> _serializeInstallationItem(
          InstallationItem i) =>
      {'data': i.data, 'photoPaths': i.photoPaths};

  // ── Mesures et essais — sérialisation champ par champ ──
  static Map<String, dynamic> _serializeMesures(MesuresEssais m) => {
        'missionId': m.missionId,
        'updatedAt': m.updatedAt.toIso8601String(),
        'conditionMesure': {'observation': m.conditionMesure.observation},
        'essaiDemarrageAuto': {
          'observation': m.essaiDemarrageAuto.observation
        },
        'testArretUrgence': {'observation': m.testArretUrgence.observation},
        'avisMesuresTerre': {
          'satisfaisants': m.avisMesuresTerre.satisfaisants,
          'nonSatisfaisants': m.avisMesuresTerre.nonSatisfaisants,
          'observation': m.avisMesuresTerre.observation,
        },
        'prisesTerre': m.prisesTerre
            .map((p) => {
                  'localisation': p.localisation,
                  'identification': p.identification,
                  'conditionPriseTerre': p.conditionPriseTerre,
                  'naturePriseTerre': p.naturePriseTerre,
                  'methodeMesure': p.methodeMesure,
                  'valeurMesure': p.valeurMesure,
                  'observation': p.observation,
                })
            .toList(),
        'essaisDeclenchement': m.essaisDeclenchement
            .map((e) => {
                  'localisation': e.localisation,
                  'coffret': e.coffret,
                  'designationCircuit': e.designationCircuit,
                  'typeDispositif': e.typeDispositif,
                  'reglageIAn': e.reglageIAn,
                  'tempo': e.tempo,
                  'isolement': e.isolement,
                  'essai': e.essai,
                  'observation': e.observation,
                })
            .toList(),
        'continuiteResistances': m.continuiteResistances
            .map((c) => {
                  'localisation': c.localisation,
                  'designationTableau': c.designationTableau,
                  'origineMesure': c.origineMesure,
                  'observation': c.observation,
                })
            .toList(),
      };

  // ── JSA ──
  static Map<String, dynamic> _serializeJSA(JSA j) {
    return {
      'missionId': j.missionId,
      'operationEffectuer': j.operationEffectuer,
      'updatedAt': j.updatedAt.toIso8601String(),
      'currentSubCategory': j.currentSubCategory,
      'inspecteurs': j.inspecteurs.map((i) => {
        'nom': i.nom,
        'prenom': i.prenom,
        'signature': i.signature,
      }).toList(),
      'planUrgence': {
        'voiesIssuesIdentifiees': j.planUrgence.voiesIssuesIdentifiees,
        'zonesRassemblementIdentifiees': j.planUrgence.zonesRassemblementIdentifiees,
        'consignesSecuriteInternes': j.planUrgence.consignesSecuriteInternes,
        'personneContactClient': j.planUrgence.personneContactClient,
        'personneContactKES': j.planUrgence.personneContactKES,
      },
      'dangers': {
        'chocElectrique': j.dangers.chocElectrique,
        'bruit': j.dangers.bruit,
        'stressThermique': j.dangers.stressThermique,
        'eclairageInadapte': j.dangers.eclairageInadapte,
        'zoneCirculationMalDefinie': j.dangers.zoneCirculationMalDefinie,
        'solAccidente': j.dangers.solAccidente,
        'emissionGazPoussiere': j.dangers.emissionGazPoussiere,
        'espaceConfine': j.dangers.espaceConfine,
        'autreEnvironnement': j.dangers.autreEnvironnement,
        'chuteObjets': j.dangers.chuteObjets,
        'coactivite': j.dangers.coactivite,
        'portCharge': j.dangers.portCharge,
        'expositionProduitsChimiques': j.dangers.expositionProduitsChimiques,
        'chuteHauteur': j.dangers.chuteHauteur,
        'electrification': j.dangers.electrification,
        'incendiesExplosion': j.dangers.incendiesExplosion,
        'mauvaisesPostures': j.dangers.mauvaisesPostures,
        'chutePlainPied': j.dangers.chutePlainPied,
        'autrePhysique': j.dangers.autrePhysique,
      },
      'exigencesGenerales': {
        'signaletiqueSecurite': j.exigencesGenerales.signaletiqueSecurite,
        'ficheDonneeSecuriteDisponible': j.exigencesGenerales.ficheDonneeSecuriteDisponible,
        'uneMinuteMaSecurite': j.exigencesGenerales.uneMinuteMaSecurite,
        'balise': j.exigencesGenerales.balise,
        'zoneTravailPropre': j.exigencesGenerales.zoneTravailPropre,
        'toolboxMeeting': j.exigencesGenerales.toolboxMeeting,
        'permisTravail': j.exigencesGenerales.permisTravail,
        'extincteurs': j.exigencesGenerales.extincteurs,
        'outilsMaterielsIsolants': j.exigencesGenerales.outilsMaterielsIsolants,
        'boitePharmacie': j.exigencesGenerales.boitePharmacie,
        'autre': j.exigencesGenerales.autre,
      },
      'epi': {
        'casqueSecurite': j.epi.casqueSecurite,
        'bouchonsOreille': j.epi.bouchonsOreille,
        'lunettesProtection': j.epi.lunettesProtection,
        'harnaisSecurite': j.epi.harnaisSecurite,
        'chaussureSecurite': j.epi.chaussureSecurite,
        'masqueSecurite': j.epi.masqueSecurite,
        'combinaisonLongueManche': j.epi.combinaisonLongueManche,
        'gantsIsolants': j.epi.gantsIsolants,
        'cacheNez': j.epi.cacheNez,
        'gilet': j.epi.gilet,
        'autre': j.epi.autre,
      },
      'verificationFinale': {
        'travailTermineNA': j.verificationFinale.travailTermineNA,
        'travailTermineApplicable': j.verificationFinale.travailTermineApplicable,
        'consignationCadenasRetireNA': j.verificationFinale.consignationCadenasRetireNA,
        'consignationCadenasRetireApplicable': j.verificationFinale.consignationCadenasRetireApplicable,
        'absenceConsignataireProcedureNA': j.verificationFinale.absenceConsignataireProcedureNA,
        'absenceConsignataireProcedureApplicable': j.verificationFinale.absenceConsignataireProcedureApplicable,
        'consignataireAbsentProcedureAppliqueeNA': j.verificationFinale.consignataireAbsentProcedureAppliqueeNA,
        'consignataireAbsentProcedureAppliqueeApplicable': j.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable,
        'materielEnleveZoneNettoyeeNA': j.verificationFinale.materielEnleveZoneNettoyeeNA,
        'materielEnleveZoneNettoyeeApplicable': j.verificationFinale.materielEnleveZoneNettoyeeApplicable,
        'risquesSupprimesEquipementPretNA': j.verificationFinale.risquesSupprimesEquipementPretNA,
        'risquesSupprimesEquipementPretApplicable': j.verificationFinale.risquesSupprimesEquipementPretApplicable,
        'autresPoints': j.verificationFinale.autresPoints,
        'donneurOrdreSignature': j.verificationFinale.donneurOrdreSignature,
        'chargeAffairesSignature': j.verificationFinale.chargeAffairesSignature,
      },
    };
  }

  static Map<String, dynamic> _serializeRenseignements(
      RenseignementsGeneraux r) =>
      {
        'missionId': r.missionId,
        'etablissement': r.etablissement,
        'installation': r.installation,
        'activite': r.activite,
        'dateDebut': r.dateDebut?.toIso8601String(),
        'dateFin': r.dateFin?.toIso8601String(),
        'dureeJours': r.dureeJours,
        'verificationType': r.verificationType,
        'registreControle': r.registreControle,
        'compteRendu': r.compteRendu,
        'accompagnateurs': r.accompagnateurs,
        'verificateurs': r.verificateurs,
        'updatedAt': r.updatedAt.toIso8601String(),
        'nomSite': r.nomSite,
      };

  static Map<String, dynamic> _f(Foudre f) => f.toJson();

  // ── Classements ──
  static List<Map<String, dynamic>> _classementsByMission(String missionId) {
    final box = Hive.box<ClassementEmplacement>('classement_locaux');
    return box.values
        .where((c) => c.missionId == missionId)
        .map((c) => {
              'missionId': c.missionId,
              'localisation': c.localisation,
              'zone': c.zone,
              'origineClassement': c.origineClassement,
              'af': c.af,
              'be': c.be,
              'ae': c.ae,
              'ad': c.ad,
              'ag': c.ag,
              'ip': c.ip,
              'ik': c.ik,
              'updatedAt': c.updatedAt.toIso8601String(),
              'typeLocal': c.typeLocal,
              'typeEmplacement': c.typeEmplacement,
              'heriteDeZone': c.heriteDeZone,
              'zoneParenteId': c.zoneParenteId,
            })
        .toList();
  }

  static List<Map<String, dynamic>> _classementZonesByMission(
      String missionId) {
    final box = Hive.box<ClassementZone>('classement_zones');
    return box.values
        .where((c) => c.missionId == missionId)
        .map((c) => {
              'missionId': c.missionId,
              'nomZone': c.nomZone,
              'origineClassement': c.origineClassement,
              'typeZone': c.typeZone,
              'af': c.af,
              'be': c.be,
              'ae': c.ae,
              'ad': c.ad,
              'ag': c.ag,
              'ip': c.ip,
              'ik': c.ik,
              'updatedAt': c.updatedAt.toIso8601String(),
            })
        .toList();
  }

  // ── Brouillons locaux ──
  static List<Map<String, dynamic>> _serializeLocalDrafts(
      List<String> missionIds) {
    final box = Hive.box('local_drafts');
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is! Map) continue;
        final missionId = data['missionId'];
        if (!missionIds.contains(missionId)) continue;
        final local = data['local'];
        Map<String, dynamic>? serializedLocal;
        String localClass = 'MT';
        if (local is MoyenneTensionLocal) {
          serializedLocal = _serializeMTLocal(local);
          localClass = 'MT';
        } else if (local is BasseTensionLocal) {
          serializedLocal = _serializeBTLocal(local);
          localClass = 'BT';
        }
        if (serializedLocal == null) continue;
        result.add({
          'key': key.toString(),
          'missionId': missionId,
          'isMoyenneTension': data['isMoyenneTension'],
          'zoneIndex': data['zoneIndex'],
          'isInZone': data['isInZone'],
          'localType': data['localType'],
          'nomLocal': data['nomLocal'],
          'currentStep': data['currentStep'],
          'savedAt': data['savedAt'],
          'localId': data['localId'],
          'localClass': localClass,
          'local': serializedLocal,
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft local ignoré: $e');
      }
    }
    return result;
  }

  // ── Brouillons coffrets ──
  static List<Map<String, dynamic>> _serializeCoffretDrafts(
      List<String> missionIds) {
    final box = Hive.box('coffret_drafts');
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is! Map) continue;
        final missionId = data['missionId'];
        if (!missionIds.contains(missionId)) continue;
        final coffret = data['coffret'];
        if (coffret is! CoffretArmoire) continue;
        result.add({
          'key': key.toString(),
          'missionId': missionId,
          'parentType': data['parentType'],
          'parentIndex': data['parentIndex'],
          'isMoyenneTension': data['isMoyenneTension'],
          'zoneIndex': data['zoneIndex'],
          'savedAt': data['savedAt'],
          'coffret': _serializeCoffret(coffret),
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft coffret ignoré: $e');
      }
    }
    return result;
  }


  // ── Isolate helper pour calculer le checksum lors de l'export ──
  static Map<String, dynamic> _computeExportChecksum(Map<String, dynamic> payload) {
    final contentForHash = jsonEncode(payload);
    payload['checksum'] = sha256.convert(utf8.encode(contentForHash)).toString();
    return payload;
  }

  // ── Isolate helper pour le décodage et la vérification du Checksum ──
  static Map<String, dynamic> _parseJsonAndVerifyChecksum(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const FormatException('file_not_found');
    }
    final bytes = file.readAsBytesSync();
    final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final fileMagic = payload['magic'] as String?;
    
    if (fileMagic == _magic) {
      final checksum = payload['checksum'] as String?;
      if (checksum != null) {
        final len = bytes.length;
        if (len > 79) {
          // Les 79 derniers octets correspondent à : ,"checksum":"[64_hex_chars]"}
          final bytesToHash = bytes.sublist(0, len - 79);
          final computed = sha256.convert(bytesToHash).toString();
          if (computed != checksum) {
            throw const FormatException('checksum_invalid');
          }
        } else {
          throw const FormatException('checksum_invalid');
        }
      }
    }
    return payload;
  }

  // ═══════════════════════════════════════════════════════════
  // IMPORT
  // ═══════════════════════════════════════════════════════════

  static Future<ImportResult> importerMissions(
    String filePath, {
    bool ecraserExistants = false,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
  }) async {
    final warnings = <String>[];
    int imported = 0;
    int skipped = 0;

    // ─ 1. Lecture et validation en arrière-plan via compute Isolate ─
    Map<String, dynamic> payload;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ImportResult(
            success: false, message: 'Fichier introuvable.');
      }
      payload = await compute(_parseJsonAndVerifyChecksum, filePath);
    } catch (e) {
      if (e.toString().contains('checksum_invalid')) {
        return const ImportResult(
          success: false,
          message: 'Intégrité du fichier compromise (checksum invalide). '
              'Le fichier est peut-être corrompu ou modifié.',
        );
      }
      return ImportResult(
        success: false,
        message: 'Fichier JSON invalide ou corrompu.',
        errorDetail: e.toString(),
      );
    }

    // ─ 2. Validation magic (V1 rétrocompat + V2) ─
    final fileMagic = payload['magic'] as String?;
    if (fileMagic != _magic && fileMagic != _magicV1) {
      return const ImportResult(
        success: false,
        message: "Ce fichier n'est pas une sauvegarde Inspec valide.",
      );
    }

    final schemaVersion = payload['schema_version'] as int? ?? 1;
    if (schemaVersion > _schemaVersion) {
      return ImportResult(
        success: false,
        message:
            'Sauvegarde créée avec une version plus récente (schéma v$schemaVersion). '
            'Mettez à jour l\'application.',
      );
    }

    // ─ 3. Import des missions ─
    final missionsData = payload['missions'] as List<dynamic>? ?? [];
    for (final m in missionsData) {
      try {
        final r = await _importMission(
            m as Map<String, dynamic>,
            ecraser: ecraserExistants,
            importeurMatricule: importeurMatricule,
            importeurNom: importeurNom,
            importeurPrenom: importeurPrenom,
          );
        if (r == 'imported') {
          imported++;
        } else {
          skipped++;
          final nom = ((m['mission'] as Map?))?['nom_client'] as String? ??
              'Mission inconnue';
          warnings.add('Mission "$nom" ignorée (déjà existante).');
        }
      } catch (e) {
        warnings.add('Erreur sur une mission: $e');
        if (kDebugMode) print('❌ Import mission: $e');
      }
    }

    // ─ 4. Import brouillons ─
    try {
      await _importLocalDrafts(
          payload['local_drafts'] as List<dynamic>? ?? [],
          ecraser: ecraserExistants);
    } catch (e) {
      warnings.add('Brouillons locaux partiellement importés: $e');
    }
    try {
      await _importCoffretDrafts(
          payload['coffret_drafts'] as List<dynamic>? ?? [],
          ecraser: ecraserExistants);
    } catch (e) {
      warnings.add('Brouillons coffrets partiellement importés: $e');
    }

    return ImportResult(
      success: imported > 0 || warnings.isEmpty,
      message: imported > 0
          ? '$imported mission(s) importée(s).'
          : 'Aucune nouvelle mission importée.',
      importedMissions: imported,
      skippedMissions: skipped,
      warnings: warnings,
    );
  }

  // ─────────────────────────────────────────────────────────
  // IMPORT D'UNE MISSION
  // ─────────────────────────────────────────────────────────

  static Future<String> _importMission(
    Map<String, dynamic> data, {
    required bool ecraser,
    required String importeurMatricule,
    required String importeurNom,
    required String importeurPrenom,
  }) async {
    final mj = data['mission'] as Map<String, dynamic>?;
    if (mj == null) return 'skipped';
    final missionId = mj['id'] as String?;
    if (missionId == null) return 'skipped';

    // Vérifier doublon — la clé Hive de la mission EST son id
    final box = Hive.box<Mission>('missions');
    final existing = box.get(missionId);
    if (existing != null && !ecraser) return 'skipped';

    final createdPhotoPaths = <String>[];

    try {
      // Mission — put avec l'id comme clé (cohérent avec HiveService.saveMission)
      final mission = Mission.fromJson(mj);

      // S'assurer que l'importeur apparaît dans les verificateurs
      // pour que getMissionsByMatricule la retourne dans sa liste
      mission.verificateurs ??= [];
      final dejaPresent = mission.verificateurs!
          .any((v) => v['matricule'] == importeurMatricule);
      if (!dejaPresent) {
        mission.verificateurs!.add({
          'matricule': importeurMatricule,
          'nom': importeurNom,
          'prenom': importeurPrenom,
          'role': 'importeur',
        });
      }

      await box.put(missionId, mission);

      // Restaurer les photos en premier
      final photosMap = data['photos'] as Map<String, dynamic>?;
      if (photosMap != null && photosMap.isNotEmpty) {
        final paths = await _restorePhotos(photosMap);
        createdPhotoPaths.addAll(paths);
      }

      // Audit
      final auditData = data['audit'] as Map<String, dynamic>?;
      if (auditData != null) await _importAudit(auditData);

      // Description installations
      final descData =
          data['description_installations'] as Map<String, dynamic>?;
      if (descData != null) await _importDescription(descData);

      // Mesures et essais
      final mesuresData = data['mesures_essais'] as Map<String, dynamic>?;
      if (mesuresData != null) await _importMesures(mesuresData);

      // JSA
      final jsaData = data['jsa'] as Map<String, dynamic>?;
      if (jsaData != null) await _importJSA(jsaData);

      // Renseignements généraux
      final rensData =
          data['renseignements_generaux'] as Map<String, dynamic>?;
      if (rensData != null) await _importRenseignements(rensData);

      // Foudre
      for (final f in data['foudre_observations'] as List<dynamic>? ?? []) {
        await _importFoudre(f as Map<String, dynamic>);
      }

      // Classements locaux
      for (final c in data['classements_locaux'] as List<dynamic>? ?? []) {
        await _importClassement(c as Map<String, dynamic>);
      }

      // Classements zones
      for (final c in data['classements_zones'] as List<dynamic>? ?? []) {
        await _importClassementZone(c as Map<String, dynamic>);
      }

      // Progression de séquence (rétrocompatible)
      final progressData = data['sequence_progress'] as Map<dynamic, dynamic>?;
      if (progressData != null) {
        final progressBox = await Hive.openBox('mission_progress');
        await progressBox.put(missionId, Map<String, dynamic>.from(progressData));
      }

      return 'imported';
    } catch (e, st) {
      if (kDebugMode) print('❌ Exception détectée lors de l\'import: $e\n$st');
      // Déclencher le rollback automatique
      await _rollbackMission(missionId, createdPhotoPaths);
      rethrow;
    }
  }

  // ── Audit ──
  static Future<void> _importAudit(Map<String, dynamic> d) async {
    final missionId = d['missionId'] as String;

    // Vérifier si un audit existe déjà pour cette mission
    final box = Hive.box<AuditInstallationsElectriques>(
        'audit_installations_electriques');
    final exists =
        box.values.any((a) => a.missionId == missionId);
    if (exists) return;

    final audit = AuditInstallationsElectriques(
      missionId: missionId,
      updatedAt: _dt(d['updatedAt']),
      photos: _strList(d['photos']),
      moyenneTensionLocaux:
          (d['moyenneTensionLocaux'] as List<dynamic>?)
                  ?.map((l) =>
                      _parseMTLocal(l as Map<String, dynamic>))
                  .toList() ??
              [],
      moyenneTensionZones:
          (d['moyenneTensionZones'] as List<dynamic>?)
                  ?.map((z) =>
                      _parseMTZone(z as Map<String, dynamic>))
                  .toList() ??
              [],
      basseTensionZones:
          (d['basseTensionZones'] as List<dynamic>?)
                  ?.map((z) =>
                      _parseBTZone(z as Map<String, dynamic>))
                  .toList() ??
              [],
    );

    // Utiliser box.add() comme HiveService le fait — clé auto-incrémentée
    await box.add(audit);

    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>('missions');
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.auditInstallationsElectriquesId =
          audit.key.toString();
      await mission.save();
    }
  }

  static MoyenneTensionLocal _parseMTLocal(Map<String, dynamic> d) =>
      MoyenneTensionLocal(
        nom: d['nom'] as String? ?? '',
        type: d['type'] as String? ?? 'LOCAL_ELECTRIQUE',
        accessible: d['accessible'] as bool? ?? true,
        aReverifier: d['aReverifier'] as bool? ?? false,
        photos: _strList(d['photos']),
        dispositionsConstructives: _parseElements(d['dispositionsConstructives']),
        conditionsExploitation: _parseElements(d['conditionsExploitation']),
        cellule: d['cellule'] != null
            ? _parseCellule(d['cellule'] as Map<String, dynamic>)
            : null,
        transformateur: d['transformateur'] != null
            ? _parseTransformateur(d['transformateur'] as Map<String, dynamic>)
            : null,
        cellules: (d['cellules'] as List<dynamic>?)
                ?.map((c) => _parseCellule(c as Map<String, dynamic>))
                .toList() ??
            [],
        transformateurs: (d['transformateurs'] as List<dynamic>?)
                ?.map((t) => _parseTransformateur(t as Map<String, dynamic>))
                .toList() ??
            [],
        coffrets: _parseCoffrets(d['coffrets']),
        observationsLibres: _parseObs(d['observationsLibres']),
      );

  static MoyenneTensionZone _parseMTZone(Map<String, dynamic> d) =>
      MoyenneTensionZone(
        nom: d['nom'] as String? ?? '',
        description: d['description'] as String?,
        photos: _strList(d['photos']),
        classementZoneId: d['classementZoneId'] as String?,
        coffrets: _parseCoffrets(d['coffrets']),
        observationsLibres: _parseObs(d['observationsLibres']),
        locaux: (d['locaux'] as List<dynamic>?)
                ?.map((l) => _parseMTLocal(l as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static BasseTensionZone _parseBTZone(Map<String, dynamic> d) =>
      BasseTensionZone(
        nom: d['nom'] as String? ?? '',
        description: d['description'] as String?,
        photos: _strList(d['photos']),
        classementZoneId: d['classementZoneId'] as String?,
        coffretsDirects: _parseCoffrets(d['coffretsDirects']),
        observationsLibres: _parseObs(d['observationsLibres']),
        locaux: (d['locaux'] as List<dynamic>?)
                ?.map((l) => _parseBTLocal(l as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static BasseTensionLocal _parseBTLocal(Map<String, dynamic> d) =>
      BasseTensionLocal(
        nom: d['nom'] as String? ?? '',
        type: d['type'] as String? ?? 'LOCAL_ELECTRIQUE',
        accessible: d['accessible'] as bool? ?? true,
        aReverifier: d['aReverifier'] as bool? ?? false,
        photos: _strList(d['photos']),
        dispositionsConstructives: _parseElements(d['dispositionsConstructives']),
        conditionsExploitation: _parseElements(d['conditionsExploitation']),
        cellules: (d['cellules'] as List<dynamic>?)
                ?.map((c) => _parseCellule(c as Map<String, dynamic>))
                .toList() ??
            [],
        transformateurs: (d['transformateurs'] as List<dynamic>?)
                ?.map((t) => _parseTransformateur(t as Map<String, dynamic>))
                .toList() ??
            [],
        coffrets: _parseCoffrets(d['coffrets']),
        observationsLibres: _parseObs(d['observationsLibres']),
      );

  static List<ElementControle> _parseElements(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      final conforme = m['conforme'] as bool?;
      final estNA = m['estNA'] as bool? ?? false;
      // Priorité par défaut à 3 si Non ou NA et absente du JSON
      final priorite = m['priorite'] as int? ??
          ((conforme == false || estNA) ? 3 : null);
      return ElementControle(
        elementControle: m['elementControle'] as String? ?? '',
        conforme: conforme,
        observation: m['observation'] as String?,
        priorite: priorite,
        photos: _strList(m['photos']),
        referenceNormative: m['referenceNormative'] as String?,
        estNA: estNA,
      );
    }).toList();
  }

  static Cellule _parseCellule(Map<String, dynamic> d) => Cellule(
        fonction: d['fonction'] as String? ?? '',
        type: d['type'] as String? ?? '',
        marqueModeleAnnee: d['marqueModeleAnnee'] as String? ?? '',
        tensionAssignee: d['tensionAssignee'] as String? ?? '',
        pouvoirCoupure: d['pouvoirCoupure'] as String? ?? '',
        numerotation: d['numerotation'] as String? ?? '',
        parafoudres: d['parafoudres'] as String? ?? '',
        photos: _strList(d['photos']),
        elementsVerifies: _parseElements(d['elementsVerifies']),
      );

  static TransformateurMTBT _parseTransformateur(Map<String, dynamic> d) =>
      TransformateurMTBT(
        typeTransformateur: d['typeTransformateur'] as String? ?? '',
        marqueAnnee: d['marqueAnnee'] as String? ?? '',
        puissanceAssignee: d['puissanceAssignee'] as String? ?? '',
        tensionPrimaireSecondaire:
            d['tensionPrimaireSecondaire'] as String? ?? '',
        relaisBuchholz: d['relaisBuchholz'] as String? ?? '',
        typeRefroidissement: d['typeRefroidissement'] as String? ?? '',
        regimeNeutre: d['regimeNeutre'] as String? ?? '',
        photos: _strList(d['photos']),
        elementsVerifies: _parseElements(d['elementsVerifies']),
      );

  static List<CoffretArmoire> _parseCoffrets(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final d = e as Map<String, dynamic>;
      return CoffretArmoire(
        qrCode: d['qrCode'] as String? ?? '',
        nom: d['nom'] as String? ?? '',
        type: d['type'] as String? ?? '',
        description: d['description'] as String?,
        repere: d['repere'] as String?,
        numeroEquipement: d['numeroEquipement'] as String?,
        statut: d['statut'] as String? ?? 'incomplet',
        currentStep: d['currentStep'] as int? ?? 0,
        zoneAtex: d['zoneAtex'] as bool? ?? false,
        domaineTension: d['domaineTension'] as String? ?? '',
        identificationArmoire: d['identificationArmoire'] as bool? ?? false,
        signalisationDanger: d['signalisationDanger'] as bool? ?? false,
        presenceSchema: d['presenceSchema'] as bool? ?? false,
        presenceParafoudre: d['presenceParafoudre'] as bool? ?? false,
        verificationThermographie:
            d['verificationThermographie'] as bool? ?? false,
        photos: _strList(d['photos']),
        photosExternes: _strList(d['photosExternes']),
        photosInternes: _strList(d['photosInternes']),
        alimentations: (d['alimentations'] as List<dynamic>?)
                ?.map((a) => _parseAlim(a as Map<String, dynamic>))
                .toList() ??
            [],
        protectionTete: d['protectionTete'] != null
            ? _parseAlim(d['protectionTete'] as Map<String, dynamic>)
            : null,
        pointsVerification: (d['pointsVerification'] as List<dynamic>?)
                ?.map((p) => _parsePoint(p as Map<String, dynamic>))
                .toList() ??
            [],
        observationsLibres: _parseObs(d['observationsLibres']),
        observationsParafoudre: _parseObs(d['observationsParafoudre']),
      );
    }).toList();
  }

  static Alimentation _parseAlim(Map<String, dynamic> d) => Alimentation(
        typeProtection: d['typeProtection'] as String? ?? '',
        pdcKA: d['pdcKA'] as String? ?? '',
        calibre: d['calibre'] as String? ?? '',
        sectionCable: d['sectionCable'] as String? ?? '',
        source: d['source'] as String? ?? '',
        photos: _strList(d['photos']),
      );

  static PointVerification _parsePoint(Map<String, dynamic> d) {
    final conformite = d['conformite'] as String? ?? '';
    // Priorité par défaut à 3 si Non ou NA et absente du JSON
    // évite que _isCurrentSlideValid bloque la navigation après import
    final priorite = d['priorite'] as int? ??
        ((conformite == 'non' || conformite == 'na') ? 3 : null);
    return PointVerification(
      pointVerification: d['pointVerification'] as String? ?? '',
      conformite: conformite,
      observation: d['observation'] as String?,
      referenceNormative: d['referenceNormative'] as String?,
      priorite: priorite,
      photos: _strList(d['photos']),
    );
  }

  static List<ObservationLibre> _parseObs(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return ObservationLibre(
        texte: m['texte'] as String? ?? '',
        photos: _strList(m['photos']),
        dateCreation: _dt(m['dateCreation']),
        dateModification: _dt(m['dateModification']),
      );
    }).toList();
  }

  // ── Description ──
  static Future<void> _importDescription(Map<String, dynamic> d) async {
    final missionId = d['missionId'] as String;
    final box = Hive.box<DescriptionInstallations>('description_installations');

    // Ne pas écraser une description existante
    final exists = box.values.any((v) => v.missionId == missionId);
    if (exists) return;

    final desc = DescriptionInstallations(
      missionId: missionId,
      alimentationMoyenneTension: _parseItems(d['alimentationMoyenneTension']),
      alimentationBasseTension: _parseItems(d['alimentationBasseTension']),
      groupeElectrogene: _parseItems(d['groupeElectrogene']),
      alimentationCarburant: _parseItems(d['alimentationCarburant']),
      inverseur: _parseItems(d['inverseur']),
      stabilisateur: _parseItems(d['stabilisateur']),
      onduleurs: _parseItems(d['onduleurs']),
      regimeNeutre: d['regimeNeutre'] as String?,
      regimeNeutreDetail: d['regimeNeutreDetail'] as String?,
      eclairageSecurite: d['eclairageSecurite'] as String?,
      modificationsInstallations: d['modificationsInstallations'] as String?,
      noteCalcul: d['noteCalcul'] as String?,
      registreSecurite: d['registreSecurite'] as String?,
      presenceParatonnerre: d['presenceParatonnerre'] as String?,
      analyseRisqueFoudre: d['analyseRisqueFoudre'] as String?,
      etudeTechniqueFoudre: d['etudeTechniqueFoudre'] as String?,
      updatedAt: _dt(d['updatedAt']),
    );

    await box.add(desc);

    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>('missions');
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.descriptionInstallationsId = desc.key.toString();
      await mission.save();
    }
  }

  static List<InstallationItem> _parseItems(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return InstallationItem(
        data: Map<String, String>.from(m['data'] as Map? ?? {}),
        photoPaths: _strList(m['photoPaths']),
      );
    }).toList();
  }

  // ── Mesures et essais ──
  static Future<void> _importMesures(Map<String, dynamic> d) async {
    try {
      final missionId = d['missionId'] as String;
      final box = Hive.box<MesuresEssais>('mesures_essais');
      final exists = box.values.any((m) => m.missionId == missionId);
      if (exists) return; // Ne pas écraser

      final cm = d['conditionMesure'] as Map<String, dynamic>?;
      final eda = d['essaiDemarrageAuto'] as Map<String, dynamic>?;
      final tau = d['testArretUrgence'] as Map<String, dynamic>?;
      final amt = d['avisMesuresTerre'] as Map<String, dynamic>?;

      final mesures = MesuresEssais(
        missionId: missionId,
        updatedAt: _dt(d['updatedAt']),
        conditionMesure:
            ConditionMesure(observation: cm?['observation'] as String?),
        essaiDemarrageAuto:
            EssaiDemarrageAuto(observation: eda?['observation'] as String?),
        testArretUrgence:
            TestArretUrgence(observation: tau?['observation'] as String?),
        avisMesuresTerre: AvisMesuresTerre(
          satisfaisants: _strList(amt?['satisfaisants']),
          nonSatisfaisants: _strList(amt?['nonSatisfaisants']),
          observation: amt?['observation'] as String?,
        ),
        prisesTerre: (d['prisesTerre'] as List<dynamic>?)
                ?.map((p) {
                  final m = p as Map<String, dynamic>;
                  return PriseTerre(
                    localisation: m['localisation'] as String? ?? '',
                    identification: m['identification'] as String? ?? '',
                    conditionPriseTerre:
                        m['conditionPriseTerre'] as String? ?? '',
                    naturePriseTerre: m['naturePriseTerre'] as String? ?? '',
                    methodeMesure: m['methodeMesure'] as String? ?? '',
                    valeurMesure: (m['valeurMesure'] as num?)?.toDouble(),
                    observation: m['observation'] as String?,
                  );
                })
                .toList() ??
            [],
        essaisDeclenchement: (d['essaisDeclenchement'] as List<dynamic>?)
                ?.map((e) {
                  final m = e as Map<String, dynamic>;
                  return EssaiDeclenchementDifferentiel(
                    localisation: m['localisation'] as String? ?? '',
                    coffret: m['coffret'] as String?,
                    designationCircuit: m['designationCircuit'] as String?,
                    typeDispositif: m['typeDispositif'] as String? ?? 'DDR',
                    reglageIAn: (m['reglageIAn'] as num?)?.toDouble(),
                    tempo: (m['tempo'] as num?)?.toDouble(),
                    isolement: (m['isolement'] as num?)?.toDouble(),
                    essai: m['essai'] as String? ?? 'NE',
                    observation: m['observation'] as String?,
                  );
                })
                .toList() ??
            [],
        continuiteResistances: (d['continuiteResistances'] as List<dynamic>?)
                ?.map((c) {
                  final m = c as Map<String, dynamic>;
                  return ContinuiteResistance(
                    localisation: m['localisation'] as String? ?? '',
                    designationTableau: m['designationTableau'] as String? ?? '',
                    origineMesure: m['origineMesure'] as String? ?? '',
                    observation: m['observation'] as String?,
                  );
                })
                .toList() ??
            [],
      );
      await box.add(mesures);
    } catch (e) {
      if (kDebugMode) print('⚠️ Mesures import: $e');
    }
  }

  // ── JSA ──
  static Future<void> _importJSA(Map<String, dynamic> d) async {
    try {
      final missionId = d['missionId'] as String;
      final box = Hive.box<JSA>('jsa');
      final exists = box.values.any((j) => j.missionId == missionId);
      if (exists) return;

      final pu = d['planUrgence'] as Map<String, dynamic>?;
      final da = d['dangers'] as Map<String, dynamic>?;
      final eg = d['exigencesGenerales'] as Map<String, dynamic>?;
      final ep = d['epi'] as Map<String, dynamic>?;
      final vf = d['verificationFinale'] as Map<String, dynamic>?;

      final planUrgence = JSAPlanUrgence();
      if (pu != null) {
        planUrgence.voiesIssuesIdentifiees = pu['voiesIssuesIdentifiees'] as bool? ?? false;
        planUrgence.zonesRassemblementIdentifiees = pu['zonesRassemblementIdentifiees'] as bool? ?? false;
        planUrgence.consignesSecuriteInternes = pu['consignesSecuriteInternes'] as bool? ?? false;
        planUrgence.personneContactClient = pu['personneContactClient'] as String? ?? '';
        planUrgence.personneContactKES = pu['personneContactKES'] as String? ?? '';
      }

      final dangers = JSADangers();
      if (da != null) {
        dangers.chocElectrique = da['chocElectrique'] as bool? ?? false;
        dangers.bruit = da['bruit'] as bool? ?? false;
        dangers.stressThermique = da['stressThermique'] as bool? ?? false;
        dangers.eclairageInadapte = da['eclairageInadapte'] as bool? ?? false;
        dangers.zoneCirculationMalDefinie = da['zoneCirculationMalDefinie'] as bool? ?? false;
        dangers.solAccidente = da['solAccidente'] as bool? ?? false;
        dangers.emissionGazPoussiere = da['emissionGazPoussiere'] as bool? ?? false;
        dangers.espaceConfine = da['espaceConfine'] as bool? ?? false;
        dangers.autreEnvironnement = da['autreEnvironnement'] as String? ?? '';
        dangers.chuteObjets = da['chuteObjets'] as bool? ?? false;
        dangers.coactivite = da['coactivite'] as bool? ?? false;
        dangers.portCharge = da['portCharge'] as bool? ?? false;
        dangers.expositionProduitsChimiques = da['expositionProduitsChimiques'] as bool? ?? false;
        dangers.chuteHauteur = da['chuteHauteur'] as bool? ?? false;
        dangers.electrification = da['electrification'] as bool? ?? false;
        dangers.incendiesExplosion = da['incendiesExplosion'] as bool? ?? false;
        dangers.mauvaisesPostures = da['mauvaisesPostures'] as bool? ?? false;
        dangers.chutePlainPied = da['chutePlainPied'] as bool? ?? false;
        dangers.autrePhysique = da['autrePhysique'] as String? ?? '';
      }

      final exigences = JSAExigencesGenerales();
      if (eg != null) {
        exigences.signaletiqueSecurite = eg['signaletiqueSecurite'] as bool? ?? false;
        exigences.ficheDonneeSecuriteDisponible = eg['ficheDonneeSecuriteDisponible'] as bool? ?? false;
        exigences.uneMinuteMaSecurite = eg['uneMinuteMaSecurite'] as bool? ?? false;
        exigences.balise = eg['balise'] as bool? ?? false;
        exigences.zoneTravailPropre = eg['zoneTravailPropre'] as bool? ?? false;
        exigences.toolboxMeeting = eg['toolboxMeeting'] as bool? ?? false;
        exigences.permisTravail = eg['permisTravail'] as bool? ?? false;
        exigences.extincteurs = eg['extincteurs'] as bool? ?? false;
        exigences.outilsMaterielsIsolants = eg['outilsMaterielsIsolants'] as bool? ?? false;
        exigences.boitePharmacie = eg['boitePharmacie'] as bool? ?? false;
        exigences.autre = eg['autre'] as String? ?? '';
      }

      final epi = JSAEPI();
      if (ep != null) {
        epi.casqueSecurite = ep['casqueSecurite'] as bool? ?? false;
        epi.bouchonsOreille = ep['bouchonsOreille'] as bool? ?? false;
        epi.lunettesProtection = ep['lunettesProtection'] as bool? ?? false;
        epi.harnaisSecurite = ep['harnaisSecurite'] as bool? ?? false;
        epi.chaussureSecurite = ep['chaussureSecurite'] as bool? ?? false;
        epi.masqueSecurite = ep['masqueSecurite'] as bool? ?? false;
        epi.combinaisonLongueManche = ep['combinaisonLongueManche'] as bool? ?? false;
        epi.gantsIsolants = ep['gantsIsolants'] as bool? ?? false;
        epi.cacheNez = ep['cacheNez'] as bool? ?? false;
        epi.gilet = ep['gilet'] as bool? ?? false;
        epi.autre = ep['autre'] as String? ?? '';
      }

      final verif = JSAVerificationFinale();
      if (vf != null) {
        verif.travailTermineNA = vf['travailTermineNA'] as bool? ?? false;
        verif.travailTermineApplicable = vf['travailTermineApplicable'] as bool? ?? false;
        verif.consignationCadenasRetireNA = vf['consignationCadenasRetireNA'] as bool? ?? false;
        verif.consignationCadenasRetireApplicable = vf['consignationCadenasRetireApplicable'] as bool? ?? false;
        verif.absenceConsignataireProcedureNA = vf['absenceConsignataireProcedureNA'] as bool? ?? false;
        verif.absenceConsignataireProcedureApplicable = vf['absenceConsignataireProcedureApplicable'] as bool? ?? false;
        verif.consignataireAbsentProcedureAppliqueeNA = vf['consignataireAbsentProcedureAppliqueeNA'] as bool? ?? false;
        verif.consignataireAbsentProcedureAppliqueeApplicable = vf['consignataireAbsentProcedureAppliqueeApplicable'] as bool? ?? false;
        verif.materielEnleveZoneNettoyeeNA = vf['materielEnleveZoneNettoyeeNA'] as bool? ?? false;
        verif.materielEnleveZoneNettoyeeApplicable = vf['materielEnleveZoneNettoyeeApplicable'] as bool? ?? false;
        verif.risquesSupprimesEquipementPretNA = vf['risquesSupprimesEquipementPretNA'] as bool? ?? false;
        verif.risquesSupprimesEquipementPretApplicable = vf['risquesSupprimesEquipementPretApplicable'] as bool? ?? false;
        verif.autresPoints = vf['autresPoints'] as String? ?? '';
        verif.donneurOrdreSignature = vf['donneurOrdreSignature'] as String? ?? '';
        verif.chargeAffairesSignature = vf['chargeAffairesSignature'] as String? ?? '';
      }

      final jsa = JSA(
        missionId: missionId,
        operationEffectuer: d['operationEffectuer'] as String? ?? '',
        updatedAt: _dt(d['updatedAt']),
        currentSubCategory: d['currentSubCategory'] as int? ?? 0,
        inspecteurs: (d['inspecteurs'] as List<dynamic>?)?.map((i) {
          final m = i as Map<String, dynamic>;
          return JSAInspecteur(
            nom: m['nom'] as String? ?? '',
            prenom: m['prenom'] as String? ?? '',
            signature: m['signature'] as String? ?? '',
          );
        }).toList() ?? [],
        planUrgence: planUrgence,
        dangers: dangers,
        exigencesGenerales: exigences,
        epi: epi,
        verificationFinale: verif,
      );
      await box.add(jsa);
    } catch (e) {
      if (kDebugMode) print('⚠️ JSA import: $e');
    }
  }

  // ── Renseignements généraux ──
  static Future<void> _importRenseignements(Map<String, dynamic> d) async {
    try {
      final missionId = d['missionId'] as String;
      final box =
          Hive.box<RenseignementsGeneraux>('renseignements_generaux');
      final exists = box.values.any((r) => r.missionId == missionId);
      if (exists) return;
      final rens = RenseignementsGeneraux(
        missionId: missionId,
        etablissement: d['etablissement'] as String? ?? '',
        installation: d['installation'] as String? ?? '',
        activite: d['activite'] as String? ?? '',
        dateDebut: d['dateDebut'] != null
            ? DateTime.tryParse(d['dateDebut'] as String)
            : null,
        dateFin: d['dateFin'] != null
            ? DateTime.tryParse(d['dateFin'] as String)
            : null,
        dureeJours: d['dureeJours'] as int? ?? 0,
        verificationType: d['verificationType'] as String?,
        registreControle: d['registreControle'] as String? ?? '',
        compteRendu: _strList(d['compteRendu']),
        accompagnateurs: (d['accompagnateurs'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
        verificateurs: (d['verificateurs'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [],
        nomSite: d['nomSite'] as String? ?? '',
        updatedAt: _dt(d['updatedAt']),

      );
      await box.add(rens);
    } catch (e) {
      if (kDebugMode) print('⚠️ Renseignements import: $e');
    }
  }

  // ── Foudre ──
  static Future<void> _importFoudre(Map<String, dynamic> d) async {
    try {
      final foudre = Foudre.fromJson(d);
      final box = Hive.box<Foudre>('foudre_observations');
      await box.add(foudre);
    } catch (e) {
      if (kDebugMode) print('⚠️ Foudre import: $e');
    }
  }

  // ── Classements ──
  static Future<void> _importClassement(Map<String, dynamic> d) async {
    try {
      final box = Hive.box<ClassementEmplacement>('classement_locaux');
      final missionId = d['missionId'] as String? ?? '';
      final localisation = d['localisation'] as String? ?? '';
      // Anti-doublon : ne pas réinsérer si déjà présent
      final existe = box.values.any(
          (c) => c.missionId == missionId && c.localisation == localisation);
      if (existe) return;

      await box.add(ClassementEmplacement(
        missionId: d['missionId'] as String? ?? '',
        localisation: d['localisation'] as String? ?? '',
        zone: d['zone'] as String?,
        origineClassement:
            d['origineClassement'] as String? ?? 'KES I&P',
        af: d['af'] as String?,
        be: d['be'] as String?,
        ae: d['ae'] as String?,
        ad: d['ad'] as String?,
        ag: d['ag'] as String?,
        ip: d['ip'] as String?,
        ik: d['ik'] as String?,
        updatedAt: _dt(d['updatedAt']),
        typeLocal: d['typeLocal'] as String?,
        typeEmplacement: d['typeEmplacement'] as String? ?? 'local',
        heriteDeZone: d['heriteDeZone'] as bool? ?? false,
        zoneParenteId: d['zoneParenteId'] as String?,
      ));
    } catch (e) {
      if (kDebugMode) print('⚠️ Classement import: $e');
    }
  }

  static Future<void> _importClassementZone(Map<String, dynamic> d) async {
    try {
      final box = Hive.box<ClassementZone>('classement_zones');
      final missionId = d['missionId'] as String? ?? '';
      final nomZone = d['nomZone'] as String? ?? '';
      // Anti-doublon : ne pas réinsérer si déjà présent
      final existe = box.values
          .any((c) => c.missionId == missionId && c.nomZone == nomZone);
      if (existe) return;
      await box.add(ClassementZone(
        missionId: d['missionId'] as String? ?? '',
        nomZone: d['nomZone'] as String? ?? '',
        origineClassement:
            d['origineClassement'] as String? ?? 'KES I&P',
        typeZone: d['typeZone'] as String? ?? 'BT',
        af: d['af'] as String?,
        be: d['be'] as String?,
        ae: d['ae'] as String?,
        ad: d['ad'] as String?,
        ag: d['ag'] as String?,
        ip: d['ip'] as String?,
        ik: d['ik'] as String?,
        updatedAt: _dt(d['updatedAt']),
      ));
    } catch (e) {
      if (kDebugMode) print('⚠️ ClassementZone import: $e');
    }
  }

  // ── Brouillons locaux ──
  static Future<void> _importLocalDrafts(
    List<dynamic> drafts, {
    required bool ecraser,
  }) async {
    final box = Hive.box('local_drafts');
    for (final draft in drafts) {
      try {
        final d = draft as Map<String, dynamic>;
        final key = d['key'] as String?;
        if (key == null) continue;
        if (box.containsKey(key) && !ecraser) continue;
        final localData = d['local'] as Map<String, dynamic>?;
        if (localData == null) continue;
        final localClass = d['localClass'] as String? ?? 'MT';
        final localObj = localClass == 'MT'
            ? _parseMTLocal(localData)
            : _parseBTLocal(localData);
        await box.put(key, {
          'local': localObj,
          'currentStep': d['currentStep'],
          'missionId': d['missionId'],
          'isMoyenneTension': d['isMoyenneTension'],
          'zoneIndex': d['zoneIndex'],
          'isInZone': d['isInZone'],
          'localType': d['localType'],
          'nomLocal': d['nomLocal'],
          'savedAt': d['savedAt'],
          'localId': key,
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft local import: $e');
      }
    }
  }

  // ── Brouillons coffrets ──
  static Future<void> _importCoffretDrafts(
    List<dynamic> drafts, {
    required bool ecraser,
  }) async {
    final box = Hive.box('coffret_drafts');
    for (final draft in drafts) {
      try {
        final d = draft as Map<String, dynamic>;
        final key = d['key'] as String?;
        if (key == null) continue;
        if (box.containsKey(key) && !ecraser) continue;
        final coffretData = d['coffret'] as Map<String, dynamic>?;
        if (coffretData == null) continue;
        final coffrets = _parseCoffrets([coffretData]);
        if (coffrets.isEmpty) continue;
        await box.put(key, {
          'coffret': coffrets.first,
          'missionId': d['missionId'],
          'parentType': d['parentType'],
          'parentIndex': d['parentIndex'],
          'isMoyenneTension': d['isMoyenneTension'],
          'zoneIndex': d['zoneIndex'],
          'savedAt': d['savedAt'],
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Draft coffret import: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // UTILITAIRES
  // ─────────────────────────────────────────────────────────

  static List<String> _strList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>).map((e) => e as String).toList();
  }

  static DateTime _dt(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw as String);
    } catch (_) {
      return DateTime.now();
    }
  }



  // ── Sérialiser toutes les photos d'une mission en base64 ──
  // ── Collecter tous les chemins photos d'un audit ──
  static List<String> _collectAllPhotoPaths(AuditInstallationsElectriques a) {
    final paths = <String>{};

    void addPhotos(List<String> p) => paths.addAll(p.where((x) => x.isNotEmpty));
    void addElement(ElementControle e) => addPhotos(e.photos);
    void addObs(List<ObservationLibre> obs) {
      for (final o in obs) addPhotos(o.photos);
    }
    void addCoffret(CoffretArmoire c) {
      addPhotos(c.photos);
      addPhotos(c.photosExternes);
      addPhotos(c.photosInternes);
      addObs(c.observationsLibres);
      addObs(c.observationsParafoudre);
      for (final p in c.pointsVerification) addPhotos(p.photos);
      for (final al in c.alimentations) addPhotos(al.photos);
      if (c.protectionTete != null) addPhotos(c.protectionTete!.photos);
    }
    void addMTLocal(MoyenneTensionLocal l) {
      addPhotos(l.photos);
      addObs(l.observationsLibres);
      l.dispositionsConstructives.forEach(addElement);
      l.conditionsExploitation.forEach(addElement);
      for (final c in l.coffrets) addCoffret(c);
      for (final cell in l.cellules) {
        addPhotos(cell.photos);
        cell.elementsVerifies.forEach(addElement);
      }
      for (final t in l.transformateurs) {
        addPhotos(t.photos);
        t.elementsVerifies.forEach(addElement);
      }
    }
    void addBTLocal(BasseTensionLocal l) {
      addPhotos(l.photos);
      addObs(l.observationsLibres);
      (l.dispositionsConstructives ?? []).forEach(addElement);
      (l.conditionsExploitation ?? []).forEach(addElement);
      for (final c in l.coffrets) addCoffret(c);
    }

    addPhotos(a.photos);
    for (final l in a.moyenneTensionLocaux) addMTLocal(l);
    for (final z in a.moyenneTensionZones) {
      addPhotos(z.photos);
      addObs(z.observationsLibres);
      for (final c in z.coffrets) addCoffret(c);
      for (final l in z.locaux) addMTLocal(l);
    }
    for (final z in a.basseTensionZones) {
      addPhotos(z.photos);
      addObs(z.observationsLibres);
      for (final c in z.coffretsDirects) addCoffret(c);
      for (final l in z.locaux) addBTLocal(l);
    }
    return paths.toList();
  }

  // ── Encoder les photos en base64 ──
  static Future<Map<String, String>> _exportPhotos(List<String> paths) async {
    final result = <String, String>{};
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          result[path] = base64Encode(bytes);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Photo ignorée: $path — $e');
      }
    }
    return result;
  }

  // ── Restaurer les photos depuis base64 ──
  static Future<List<String>> _restorePhotos(Map<String, dynamic> photosMap) async {
    final createdPaths = <String>[];
    final appDir = await getApplicationDocumentsDirectory();
    for (final entry in photosMap.entries) {
      final originalPath = entry.key as String;
      final b64 = entry.value as String? ?? '';
      if (b64.isEmpty) continue;
      try {
        final fileName = originalPath.split('/').last;
        // Extraire le sous-dossier depuis le chemin original
        String subDir = 'misc';
        final parts = originalPath.split('/');
        final idx = parts.indexOf('audit_photos');
        if (idx != -1 && idx + 2 < parts.length) {
          subDir = parts[idx + 1];
        }
        final dir = Directory('${appDir.path}/audit_photos/$subDir');
        if (!await dir.exists()) await dir.create(recursive: true);
        final newFile = File('${dir.path}/$fileName');
        if (!await newFile.exists()) {
          await newFile.writeAsBytes(base64Decode(b64));
          createdPaths.add(newFile.path);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Restauration photo: $originalPath — $e');
      }
    }
    return createdPaths;
  }

  // ── Rollback atomique d'une mission en cas d'échec d'import ──
  static Future<void> _rollbackMission(String missionId, List<String> createdPhotoPaths) async {
    if (kDebugMode) print('🔄 Rollback de l\'import pour la mission: $missionId');

    // 1. Nettoyer les boxes Hive liées
    Future<void> cleanBox<T>(String boxName, bool Function(T) predicate) async {
      try {
        final box = Hive.box<T>(boxName);
        final toDelete = box.values.where(predicate).map((e) => (e as dynamic).key).toList();
        for (final k in toDelete) {
          await box.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Rollback cleanBox $boxName: $e');
      }
    }

    await cleanBox<AuditInstallationsElectriques>('audit_installations_electriques', (a) => a.missionId == missionId);
    await cleanBox<DescriptionInstallations>('description_installations', (d) => d.missionId == missionId);
    await cleanBox<ClassementEmplacement>('classement_locaux', (c) => c.missionId == missionId);
    await cleanBox<ClassementZone>('classement_zones', (z) => z.missionId == missionId);
    await cleanBox<Foudre>('foudre_observations', (f) => f.missionId == missionId);
    await cleanBox<MesuresEssais>('mesures_essais', (m) => m.missionId == missionId);
    await cleanBox<JSA>('jsa', (j) => j.missionId == missionId);
    await cleanBox<RenseignementsGeneraux>('renseignements_generaux', (r) => r.missionId == missionId);

    // Brouillons
    try {
      final coffretDraftsBox = Hive.box('coffret_drafts');
      final coffretKeys = coffretDraftsBox.keys.where((k) {
        final data = coffretDraftsBox.get(k);
        return data is Map && data['missionId'] == missionId;
      }).toList();
      for (final k in coffretKeys) await coffretDraftsBox.delete(k);
    } catch (_) {}

    try {
      final localDraftsBox = Hive.box('local_drafts');
      final localKeys = localDraftsBox.keys.where((k) {
        final data = localDraftsBox.get(k);
        return data is Map && data['missionId'] == missionId;
      }).toList();
      for (final k in localKeys) await localDraftsBox.delete(k);
    } catch (_) {}

    try {
      final progressBox = Hive.box('mission_progress');
      if (progressBox.containsKey(missionId)) {
        await progressBox.delete(missionId);
      }
    } catch (_) {}

    // Supprimer la mission elle-même
    try {
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.delete(missionId);
    } catch (_) {}

    // 2. Nettoyer les fichiers physiques de photos spécifiquement créés pour cet import
    for (final path in createdPhotoPaths) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Rollback photo: $path — $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUPPRESSION COMPLÈTE D'UNE MISSION — utilisé par MissionCard
  // ─────────────────────────────────────────────────────────

  /// Supprime une mission et TOUTES ses données associées de façon atomique.
  /// Nettoie : toutes les boxes Hive + photos disque + brouillons + rapports.
  /// Aucune donnée orpheline ne subsiste après l'appel.
  static Future<DeleteResult> deleteMissionCompletely(
      String missionId) async {
    int deletedPhotos = 0;

    try {
      // ── 1. Collecter les chemins photos AVANT suppression ─────────
      final allPhotoPaths = <String>[];
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      if (audit != null) {
        allPhotoPaths.addAll(_collectAllPhotoPaths(audit));
      }

      // ── 2. Supprimer toutes les boxes Hive liées ──────────────────
      Future<void> cleanBox<T>(String boxName,
          bool Function(T) predicate) async {
        try {
          final box = Hive.box<T>(boxName);
          final toDelete =
              box.values.where(predicate).map((e) => (e as dynamic).key).toList();
          for (final k in toDelete) {
            await box.delete(k);
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ cleanBox $boxName: $e');
        }
      }

      await cleanBox<AuditInstallationsElectriques>(
          'audit_installations_electriques',
          (a) => a.missionId == missionId);
      await cleanBox<DescriptionInstallations>(
          'description_installations',
          (d) => d.missionId == missionId);
      await cleanBox<ClassementEmplacement>(
          'classement_locaux',
          (c) => c.missionId == missionId);
      await cleanBox<ClassementZone>(
          'classement_zones',
          (z) => z.missionId == missionId);
      await cleanBox<Foudre>(
          'foudre_observations',
          (f) => f.missionId == missionId);
      await cleanBox<MesuresEssais>(
          'mesures_essais',
          (m) => m.missionId == missionId);
      await cleanBox<JSA>(
          'jsa',
          (j) => j.missionId == missionId);
      await cleanBox<RenseignementsGeneraux>(
          'renseignements_generaux',
          (r) => r.missionId == missionId);

      // Brouillons coffrets
      try {
        final coffretDraftsBox = Hive.box('coffret_drafts');
        final coffretKeys = coffretDraftsBox.keys.where((k) {
          final data = coffretDraftsBox.get(k);
          return data is Map && data['missionId'] == missionId;
        }).toList();
        for (final k in coffretKeys) {
          await coffretDraftsBox.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ coffret_drafts delete: $e');
      }

      // Brouillons locaux
      try {
        final localDraftsBox = Hive.box('local_drafts');
        final localKeys = localDraftsBox.keys.where((k) {
          final data = localDraftsBox.get(k);
          return data is Map && data['missionId'] == missionId;
        }).toList();
        for (final k in localKeys) {
          await localDraftsBox.delete(k);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ local_drafts delete: $e');
      }

      // Rapports générés
      try {
        final lastReportBox = Hive.box('last_reports');
        if (lastReportBox.containsKey(missionId)) {
          await lastReportBox.delete(missionId);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ last_reports delete: $e');
      }

      // ── 3. Supprimer la mission elle-même ─────────────────────────
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.delete(missionId);

      // ── 4. Supprimer les photos du disque ─────────────────────────
      for (final path in allPhotoPaths) {
        try {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
            deletedPhotos++;
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Photo non supprimée: $path — $e');
        }
      }

      if (kDebugMode) {
        print(
            '✅ Mission $missionId supprimée. Photos: $deletedPhotos');
      }

      return DeleteResult(
        success: true,
        message:
            'Mission supprimée avec succès ($deletedPhotos photo(s) effacée(s)).',
        deletedPhotos: deletedPhotos,
      );
    } catch (e, st) {
      if (kDebugMode) print('❌ deleteMissionCompletely: $e\n$st');
      return DeleteResult(
        success: false,
        message: 'Erreur lors de la suppression : ${e.toString()}',
        deletedPhotos: deletedPhotos,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// STRUCTURE DE PARAMÈTRES POUR L'ISOLATE D'EXPORT STREAMING
// ─────────────────────────────────────────────────────────────

class ExportParams {
  final String filePath;
  final String magic;
  final int schemaVersion;
  final String exportedAt;
  final String appVersion;
  final String exportType;
  final String? matricule;
  final List<Map<String, dynamic>> missionsData;
  final List<Map<String, dynamic>> localDrafts;
  final List<Map<String, dynamic>> coffretDrafts;

  ExportParams({
    required this.filePath,
    required this.magic,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.exportType,
    this.matricule,
    required this.missionsData,
    required this.localDrafts,
    required this.coffretDrafts,
  });
}

// Classe sink simple pour accumuler la valeur de hachage finale
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

// Function Isolate globale (ou top-level/static) exécutant l'écriture progressive
Future<void> _performStreamingExport(ExportParams params) async {
  final file = File(params.filePath);
  if (file.existsSync()) {
    file.deleteSync();
  }
  final sink = file.openWrite(encoding: utf8);
  
  final digestSink = _DigestSink();
  final hashInput = sha256.startChunkedConversion(digestSink);

  // Helper pour écrire et hasher en même temps
  void writeChunk(String chunk) {
    sink.write(chunk);
    hashInput.add(utf8.encode(chunk));
  }

  // 1. Début du payload
  writeChunk('{');
  writeChunk('"magic":${jsonEncode(params.magic)},');
  writeChunk('"schema_version":${params.schemaVersion},');
  writeChunk('"exported_at":${jsonEncode(params.exportedAt)},');
  writeChunk('"app_version":${jsonEncode(params.appVersion)},');
  writeChunk('"export_type":${jsonEncode(params.exportType)},');
  if (params.matricule != null) {
    writeChunk('"matricule":${jsonEncode(params.matricule)},');
  }
  writeChunk('"mission_count":${params.missionsData.length},');
  
  // 2. Début des missions
  writeChunk('"missions":[');
  
  for (int i = 0; i < params.missionsData.length; i++) {
    if (i > 0) writeChunk(',');
    final mData = params.missionsData[i];
    
    // Début de l'objet mission
    writeChunk('{');
    
    // a. mission metadata
    writeChunk('"mission":${jsonEncode(mData['mission'])},');
    
    // b. photos list (progressive)
    final photoPaths = List<String>.from(mData['photo_paths'] ?? []);
    writeChunk('"photo_count":${photoPaths.length},');
    writeChunk('"photos":{');
    
    for (int j = 0; j < photoPaths.length; j++) {
      if (j > 0) writeChunk(',');
      final path = photoPaths[j];
      final photoFile = File(path);
      String base64Content = '';
      if (photoFile.existsSync()) {
        final bytes = photoFile.readAsBytesSync();
        base64Content = base64Encode(bytes);
      }
      writeChunk('${jsonEncode(path)}:${jsonEncode(base64Content)}');
    }
    writeChunk('},'); // fin de "photos"
    
    // c. audit
    writeChunk('"audit":${jsonEncode(mData['audit'])},');
    
    // d. autres tables
    writeChunk('"description_installations":${jsonEncode(mData['description_installations'])},');
    writeChunk('"mesures_essais":${jsonEncode(mData['mesures_essais'])},');
    writeChunk('"jsa":${jsonEncode(mData['jsa'])},');
    writeChunk('"renseignements_generaux":${jsonEncode(mData['renseignements_generaux'])},');
    writeChunk('"foudre_observations":${jsonEncode(mData['foudre_observations'])},');
    writeChunk('"classements_locaux":${jsonEncode(mData['classements_locaux'])},');
    writeChunk('"classements_zones":${jsonEncode(mData['classements_zones'])},');
    writeChunk('"sequence_progress":${jsonEncode(mData['sequence_progress'])}');
    
    writeChunk('}'); // fin de l'objet mission
  }
  writeChunk('],'); // fin de "missions"
  
  // 3. Drafts
  writeChunk('"local_drafts":${jsonEncode(params.localDrafts)},');
  writeChunk('"coffret_drafts":${jsonEncode(params.coffretDrafts)}');
  
  // 4. Fermeture de l'accumulateur SHA-256 (calculé sur tout le payload sans la clé checksum)
  hashInput.close();
  final checksum = digestSink.value.toString();
  
  // 5. Ajout du checksum et accolade de fermeture finale
  sink.write(',"checksum":${jsonEncode(checksum)}');
  sink.write('}');
  
  await sink.flush();
  await sink.close();
}