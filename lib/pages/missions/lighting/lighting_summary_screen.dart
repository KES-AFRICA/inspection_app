import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/file_storage_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_light_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

/// Écran de Résumé et Génération de Rapport - Vérification Éclairage
/// Aligné sur l'expérience utilisateur et l'interface de SummaryStep
class LightingSummaryScreen extends StatefulWidget {
  final Mission mission;

  const LightingSummaryScreen({
    super.key,
    required this.mission,
  });

  @override
  State<LightingSummaryScreen> createState() => _LightingSummaryScreenState();
}

class _LightingSummaryScreenState extends State<LightingSummaryScreen> {
  List<LightingInspection> _inspections = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  File? _pdfFile;
  String? _pdfFileName;
  bool _showPdfPreview = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLastReports();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    final inspections =
        HiveService.getLightingInspectionsByMissionId(widget.mission.id);
    setState(() {
      _inspections = inspections;
      _isLoading = false;
    });
  }

  /// Rechargement automatique du dernier rapport généré enregistré dans Hive
  Future<void> _loadLastReports() async {
    try {
      final reports = await HiveService.getAllReportsForMission(
          '${widget.mission.id}_lighting');
      if (reports.isNotEmpty) {
        final lastReport = reports.last;
        final file = File(lastReport.filePath);
        if (await file.exists()) {
          setState(() {
            _pdfFile = file;
            _pdfFileName = lastReport.fileName;
            _showPdfPreview = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur rechargement dernier rapport éclairage: $e');
      }
    }
  }

  /// Affichage du modal BottomSheet de sélection du type de rapport (PDF vs Word)
  void _showReportTypeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Générer un rapport d\'éclairage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
              ),
              title: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Générer le rapport au format PDF'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _generateReport('pdf');
              },
            ),
            const Divider(height: 0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description, color: Colors.blue.shade700),
              ),
              title: const Text('Word', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Générer le rapport au format Word'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _generateReport('word');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Génération effectives du rapport (PDF ou bascule vers le dialogue Word)
  Future<void> _generateReport(String reportType) async {
    if (reportType == 'word') {
      _showWordPreviewUnavailableDialog();
      return;
    }

    setState(() => _isGenerating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Génération du rapport PDF Éclairage...'),
          ],
        ),
      ),
    );

    try {
      final file = await PdfReportLightService.generateLightingMissionReport(
          widget.mission.id);

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (file != null && file.existsSync()) {
        final sanitizedClient =
            widget.mission.nomClient.replaceAll(RegExp(r'[^\w]'), '_');
        final fileName =
            'Rapport_Eclairage_${sanitizedClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final savedFile = await FileStorageService.saveReport(file, fileName);

        final lastReport = LastReport(
          missionId: '${widget.mission.id}_lighting',
          filePath: savedFile.path,
          fileName: fileName,
          generatedAt: DateTime.now(),
          reportType: 'pdf',
        );
        await HiveService.saveLastReport(lastReport);

        setState(() {
          _pdfFile = savedFile;
          _pdfFileName = fileName;
          _showPdfPreview = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rapport PDF Éclairage généré avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showError('Erreur lors de la génération du rapport');
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Erreur: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// Dialogue informant que la fonctionnalité Word est en cours de développement
  void _showWordPreviewUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 6,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade700,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La génération du rapport au format Word (.docx) pour les vérifications d\'éclairage est actuellement en cours de développement.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Le rapport PDF haute précision est déjà disponible et prêt pour la consultation, le partage et l\'impression.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.blue.shade900,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'COMPRIS',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Prévisualisation du rapport PDF au clic sur la carte
  Future<void> _previewReport(File file) async {
    try {
      if (!await file.exists()) {
        _showError('Fichier PDF non trouvé');
        return;
      }

      final pdfBytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: path.basename(file.path),
      );
    } catch (e) {
      _showError('Erreur de prévisualisation: $e');
    }
  }

  /// Téléchargement / Sauvegarde locale
  Future<void> _downloadReport(File file, String fileName) async {
    final hasPermission = await _checkAndRequestStoragePermission();
    if (!hasPermission) {
      _showError(
          'Permission de stockage refusée. Impossible de sauvegarder le fichier.');
      return;
    }

    try {
      final savedFile = await FileStorageService.saveReport(file, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé dans ${savedFile.parent.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      if (await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }

      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur permission: $e');
      }
      return false;
    }
  }

  /// Partage du fichier PDF
  Future<void> _shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject:
          'Rapport de vérification éclairage - ${widget.mission.nomClient}',
      text:
          'Voici le rapport de vérification des installations d\'éclairage pour ${widget.mission.nomClient}',
    );
  }

  /// Envoi d'email avec pièce jointe
  Future<void> _sendEmailWithAttachment() async {
    if (_pdfFile == null) return;
    await Share.shareXFiles(
      [XFile(_pdfFile!.path)],
      subject:
          'Rapport de vérification éclairage - ${widget.mission.nomClient}',
      text:
          'Veuillez trouver ci-joint le rapport d\'inspection éclairage pour ${widget.mission.nomClient}',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalLocaux = _inspections.length;
    final totalConformes =
        _inspections.where((i) => i.nbLuminairesNonConformes == 0).length;
    final totalNonConformes = totalLocaux - totalConformes;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Résumé & Rapport Éclairage',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Informations de la Mission (Carte supérieure)
                  _buildMissionInfoCard(),

                  const SizedBox(height: 16),

                  // 2. Statistiques des inspections éclairage
                  Row(
                    children: [
                      _buildStatCard(
                          'Locaux contrôlés',
                          '$totalLocaux',
                          AppTheme.primaryBlue,
                          Icons.meeting_room_outlined),
                      const SizedBox(width: 8),
                      _buildStatCard('Conformes', '$totalConformes',
                          Colors.green.shade700, Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _buildStatCard(
                          'Non conformes',
                          '$totalNonConformes',
                          Colors.red.shade700,
                          Icons.warning_amber_rounded),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Bouton Générer / Régénérer
                  _buildGenerateButton(),

                  const SizedBox(height: 20),

                  // 4. Zone d'affichage du rapport généré (Style SummaryStep)
                  if (_showPdfPreview && _pdfFile != null) ...[
                    const Text(
                      'RAPPORTS DISPONIBLES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildReportCard(
                      file: _pdfFile!,
                      fileName: _pdfFileName,
                      reportType: 'pdf',
                      icon: Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  /// Carte des informations générales de la mission
  Widget _buildMissionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.mission.nomClient.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Site', widget.mission.nomSite ?? 'Non renseigné'),
          _buildSummaryRow(
              'Adresse', widget.mission.adresseClient ?? 'Non renseignée'),
          _buildSummaryRow('Statut', widget.mission.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton de génération de rapport au même design que SummaryStep
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _showReportTypeDialog,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(_showPdfPreview ? Icons.refresh : Icons.add),
        label: Text(_showPdfPreview ? 'RÉGÉNÉRER LE RAPPORT' : 'GÉNÉRER LE RAPPORT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Carte d'affichage du rapport généré (reprend exactement le widget _buildReportCard de SummaryStep)
  Widget _buildReportCard({
    required File file,
    required String? fileName,
    required String reportType,
    required IconData icon,
    required Color color,
  }) {
    final cleanFileName = fileName?.split('/').last ?? 'Rapport généré';
    final isPdf = reportType == 'pdf';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _previewReport(file),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge Type Fichier Stylisé
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPdf
                              ? [Colors.red.shade600, Colors.red.shade400]
                              : [Colors.blue.shade600, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isPdf ? 'PDF' : 'DOCX',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Détails Fichier
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cleanFileName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Cliquez pour prévisualiser',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Boutons d'Action Premium alignés à droite
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCircleActionButton(
                      icon: Icons.download_rounded,
                      tooltip: 'Télécharger',
                      onTap: () => _downloadReport(file, fileName!),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleActionButton(
                      icon: Icons.share_rounded,
                      tooltip: 'Partager',
                      onTap: () => _shareReport(file),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleActionButton(
                      icon: Icons.email_rounded,
                      tooltip: 'Email',
                      onTap: _sendEmailWithAttachment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.grey.shade700),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        tooltip: tooltip,
      ),
    );
  }
}
