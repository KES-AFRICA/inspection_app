import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/cancellation_token.dart';

typedef PdfProgressCallback = void Function(double progress, String message);

/// Contexte partagé de génération d\'un rapport PDF d\'inspection.
/// Transmet les modèles métiers, la session temporaire, les polices, les logos
/// et les registres de pagination/photos à chaque Builder spécialisé.
class PdfReportContext {
  final Mission mission;
  final String missionId;
  final AuditInstallationsElectriques? audit;
  final DescriptionInstallations? description;
  final dynamic classements;
  final dynamic classementsZones;
  final dynamic mesures;
  final dynamic foudres;
  final dynamic renseignements;
  final dynamic currentUser;
  final String nomSiteHeader;
  final String numeroRapportDoc;
  final Directory tempDir;
  final int? overrideTotalPages;
  final bool saveFilesToDisk;
  final PdfProgressCallback? onProgress;
  final CancellationToken? cancellationToken;
  final Map<String, int> trackedPages;
  final Map<String, List<int>> photoRegistry;

  // Assets graphiques en mémoire
  pw.MemoryImage? watermarkImage;
  pw.MemoryImage? firstPageFooterImage;
  pw.MemoryImage? otherPageFooterImage;
  pw.MemoryImage? logoKesImage;
  pw.MemoryImage? imgHabilitation;
  pw.MemoryImage? imgAccesGauche;
  pw.MemoryImage? imgAccesDroite1;
  pw.MemoryImage? imgAccesDroite2;

  // Polices typographiques
  pw.Font fontRegular;
  pw.Font fontBold;

  PdfReportContext({
    required this.mission,
    required this.missionId,
    required this.audit,
    required this.description,
    required this.classements,
    required this.classementsZones,
    required this.mesures,
    required this.foudres,
    required this.renseignements,
    required this.currentUser,
    required this.nomSiteHeader,
    required this.numeroRapportDoc,
    required this.tempDir,
    this.overrideTotalPages,
    this.saveFilesToDisk = true,
    this.onProgress,
    this.cancellationToken,
    Map<String, int>? trackedPages,
    Map<String, List<int>>? photoRegistry,
    this.watermarkImage,
    this.firstPageFooterImage,
    this.otherPageFooterImage,
    this.logoKesImage,
    this.imgHabilitation,
    this.imgAccesGauche,
    this.imgAccesDroite1,
    this.imgAccesDroite2,
    required this.fontRegular,
    required this.fontBold,
  })  : trackedPages = trackedPages ?? <String, int>{},
        photoRegistry = photoRegistry ?? <String, List<int>>{};
}
