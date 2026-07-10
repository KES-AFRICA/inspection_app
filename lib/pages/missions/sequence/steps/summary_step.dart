// lib/pages/missions/sequence/steps/summary_step.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_renseignements_generaux_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_mission_status_use_case.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/file_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/mission_providers.dart';
import 'package:inspec_app/features/mission/presentation/providers/mission_detail_provider.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:inspec_app/services/word_report_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class SummaryStep extends ConsumerStatefulWidget {
  final Mission mission;
  final Verificateur user;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onPrevious;

  const SummaryStep({
    super.key,
    required this.mission,
    required this.user,
    required this.onDataChanged,
    required this.onPrevious,
  });

  @override
  ConsumerState<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends ConsumerState<SummaryStep> {
  Map<String, dynamic> _progress = {};
  bool _isGenerating = false;
  File? _pdfFile;
  File? _wordFile;
  String? _pdfFileName;
  String? _wordFileName;
  bool _showPdfPreview = false;
  bool _showWordPreview = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    widget.onDataChanged({'summary_active': true});
    _loadLastReports();
    _markCurrentStepCompleted();
  }

  Future<void> _markCurrentStepCompleted() async {
    await SequenceProgressService.markStepCompleted(widget.mission.id, 6);
    if (kDebugMode) {
      print('✅ Étape 6 (Résumé) marquée comme complétée');
    }
  }

  Future<void> _loadProgress() async {
    await SequenceProgressService.markStepCompleted(widget.mission.id, 6);
    final progress = await SequenceProgressService.getProgress(widget.mission.id);
    setState(() {
      _progress = progress;
    });
  }

  Future<void> _loadLastReports() async {
    final getReportsUseCase = ref.read(getAllReportsForMissionUseCaseProvider);
    final reports = await getReportsUseCase(widget.mission.id);
    
    for (var report in reports) {
      final file = File(report.filePath);
      if (await file.exists()) {
        if (report.reportType == 'pdf') {
          setState(() {
            _pdfFile = file;
            _pdfFileName = report.fileName;
            _showPdfPreview = true;
          });
        } else if (report.reportType == 'docx') {
          setState(() {
            _wordFile = file;
            _wordFileName = report.fileName;
            _showWordPreview = true;
          });
        }
      }
    }
  }

  Future<void> _generateReport(String reportType) async {
    setState(() => _isGenerating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Génération du rapport ${reportType.toUpperCase()} en cours...'),
          ],
        ),
      ),
    );

    try {
      File? file;
      String fileName;
      if (reportType == 'word') {
        file = await WordReportService.generateMissionReport(widget.mission.id);
        fileName = 'Rapport_${widget.mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.docx';
      } else {
        file = await PdfReportService.generateMissionReport(widget.mission.id);
        fileName = 'Rapport_${widget.mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (file != null && file.existsSync()) {
        final savedFile = await FileStorageService.saveReport(file, fileName);
        
        final lastReport = LastReport(
          missionId: widget.mission.id,
          filePath: savedFile.path,
          fileName: fileName,
          generatedAt: DateTime.now(),
          reportType: reportType,
        );
        final saveReportUseCase = ref.read(saveLastReportUseCaseProvider);
        await saveReportUseCase(lastReport);
        
        setState(() {
          if (reportType == 'pdf') {
            _pdfFile = savedFile;
            _pdfFileName = fileName;
            _showPdfPreview = true;
          } else {
            _wordFile = savedFile;
            _wordFileName = fileName;
            _showWordPreview = true;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport ${reportType.toUpperCase()} généré avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _showError('Erreur lors de la génération');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Erreur: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

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
                'Générer un rapport',
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
              subtitle: const Text('Générer un rapport au format PDF'),
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
              subtitle: const Text('Générer un rapport au format Word'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _generateReport('word');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _previewReport(File file, String reportType) async {
    if (reportType != 'pdf') {
      _showWordPreviewUnavailableDialog();
      return;
    }

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

  void _showWordPreviewUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.info_outline, color: Colors.orange.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'La prévisualisation des documents Word n\'est pas disponible dans l\'application.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vous pouvez télécharger le fichier Word pour l\'ouvrir avec une application externe (Microsoft Word, Google Docs, etc.).',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800, height: 1.3),
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
            child: const Text('COMPRIS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(File file, String fileName) async {
    final hasPermission = await _checkAndRequestStoragePermission();
    if (!hasPermission) {
      _showError('Permission de stockage refusée. Impossible de sauvegarder le fichier.');
      return;
    }
    
    try {
      final savedFile = await FileStorageService.saveReport(file, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport sauvegardé dans ${savedFile.parent.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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

  Future<void> _shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rapport d\'audit électrique - ${widget.mission.nomClient}',
      text: 'Voici le rapport d\'audit électrique pour ${widget.mission.nomClient}',
    );
  }

  Future<void> _sendEmailWithAttachment() async {
    final getRgUseCase = ref.read(getRenseignementsGenerauxUseCaseProvider);
    final renseignements = await getRgUseCase(widget.mission.id);
    final verificateurs = renseignements.verificateurs;
    
    final emails = verificateurs
        .map((v) => v['email'])
        .where((e) => e != null && e.toString().isNotEmpty)
        .toList();
    
    if (emails.isEmpty) {
      _showError('Aucun email de vérificateur trouvé');
      return;
    }
    
    final subject = Uri.encodeComponent('Rapport d\'audit électrique - ${widget.mission.nomClient}');
    final body = Uri.encodeComponent(
      'Bonjour,\n\n'
      'La mission d\'audit électrique pour ${widget.mission.nomClient} est terminée.\n\n'
      'Veuillez trouver ci-joint le rapport complet.\n\n'
      'Cordialement,\n'
      '${widget.user.prenom} ${widget.user.nom}'
    );
    
    final recipients = emails.join(',');
    final mailtoUri = Uri.parse('mailto:$recipients?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      } else {
        final fileToSend = _pdfFile ?? _wordFile;
        if (fileToSend != null) {
          await Share.shareXFiles(
            [XFile(fileToSend.path)],
            subject: Uri.decodeComponent(subject),
            text: Uri.decodeComponent(body),
          );
        }
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToPreviousStep() {
    widget.onPrevious();
  }

  Future<void> _finishMission() async {
    final updateStatusUseCase = ref.read(updateMissionStatusUseCaseProvider);
    await updateStatusUseCase(
      missionId: widget.mission.id,
      status: 'termine',
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  int _getCompletedStepsCount() {
    final completed = _progress['completedSteps'] as List<dynamic>? ?? [];
    return completed.length;
  }

  int _getTotalSteps() {
    return 7;
  }

  bool get hasAnyReport => _showPdfPreview || _showWordPreview;
  bool get hasPdf => _showPdfPreview && _pdfFile != null;
  bool get hasWord => _showWordPreview && _wordFile != null;

  // ============================================================
  // VERSION OPTIMISÉE DE LA CARTE RAPPORT (COMPACTE)
  // ============================================================
  
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
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _previewReport(file, reportType),
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
                            color: color.withOpacity(0.25),
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
                              Icon(Icons.visibility_outlined, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Cliquez pour prévisualiser',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

  // ============================================================
  // CONSTRUCTION DE LA LISTE DES RAPPORTS
  // ============================================================
  
  List<Widget> _buildReportsList() {
    final List<Widget> reports = [];
    
    if (hasPdf) {
      reports.add(_buildReportCard(
        file: _pdfFile!,
        fileName: _pdfFileName,
        reportType: 'pdf',
        icon: Icons.picture_as_pdf,
        color: Colors.red,
      ));
    }
    
    if (hasWord) {
      reports.add(_buildReportCard(
        file: _wordFile!,
        fileName: _wordFileName,
        reportType: 'word',
        icon: Icons.description,
        color: Colors.blue,
      ));
    }
    
    return reports;
  }

  // ============================================================
  // WIDGETS DE L'INTERFACE
  // ============================================================
  
  Widget _buildSuccessHeader(int completedSteps, int totalSteps, int percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade800.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Grand indicateur circulaire premium
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          
          // Textes informatifs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Félicitations !',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mission Terminée',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous avez validé $completedSteps étapes sur $totalSteps.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_rounded, color: AppTheme.primaryBlue, size: 22),
              SizedBox(width: 8),
              Text('Informations de la mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Client', widget.mission.nomClient),
          if (widget.mission.activiteClient != null)
            _buildSummaryRow('Activité', widget.mission.activiteClient!),
          if (widget.mission.adresseClient != null)
            _buildSummaryRow('Adresse', widget.mission.adresseClient!),
          _buildSummaryRow('Statut', widget.mission.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildStepsCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rtl_rounded, color: AppTheme.primaryBlue, size: 22),
              SizedBox(width: 8),
              Text(
                'Progression de la mission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepTimelineTile(0, 'JSA', _progress['completedSteps']?.contains(0) ?? false, Icons.engineering_rounded, false),
          _buildStepTimelineTile(1, 'Renseignements généraux', _progress['completedSteps']?.contains(1) ?? false, Icons.info_rounded, false),
          _buildStepTimelineTile(2, 'Documents nécessaires', _progress['completedSteps']?.contains(2) ?? false, Icons.folder_rounded, false),
          _buildStepTimelineTile(3, 'Description des installations', _progress['completedSteps']?.contains(3) ?? false, Icons.description_rounded, false),
          _buildStepTimelineTile(4, 'Audit des installations', _progress['completedSteps']?.contains(4) ?? false, Icons.electrical_services_rounded, false),
          _buildStepTimelineTile(5, 'Schéma des installations', _progress['completedSteps']?.contains(5) ?? false, Icons.schema_rounded, false),
          _buildStepTimelineTile(6, 'Rapport final généré', true, Icons.summarize_rounded, true),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _showReportTypeDialog,
        icon: _isGenerating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(hasAnyReport ? Icons.refresh : Icons.add),
        label: Text(hasAnyReport ? 'RÉGÉNÉRER' : 'GÉNÉRER'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _goToPreviousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text('PRÉCÉDENT'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _finishMission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TERMINER'),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTimelineTile(int index, String title, bool isCompleted, IconData icon, bool isLast) {
    final color = isCompleted ? Colors.green : Colors.grey.shade400;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne Timeline à gauche (Cercle + Ligne de liaison)
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  color: color,
                  size: 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          
          // Contenu de l'étape à droite
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                      fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? 'Complété' : 'En attente',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCompleted ? Colors.green.shade700 : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD PRINCIPAL (VERSION CORRIGÉE SANS BOTTOM OVERFLOW)
  // ============================================================
  
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(missionDetailProvider(widget.mission.id));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (mission) {
        final completedSteps = _getCompletedStepsCount();
        final totalSteps = _getTotalSteps();
        final percentage = (completedSteps / totalSteps * 100).round();

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,  // ← Permet au Column de s'adapter au contenu
                  children: [
                    // En-tête de succès
                    _buildSuccessHeader(completedSteps, totalSteps, percentage),
                    const SizedBox(height: 24),

                    // Informations de la mission
                    _buildMissionInfoCard(),
                    const SizedBox(height: 24),

                    // Étapes complétées
                    _buildStepsCompletionCard(),
                    const SizedBox(height: 24),

                    // Bouton Générer/Régénérer
                    _buildGenerateButton(),
                    const SizedBox(height: 16),

                    // Zone des rapports (format compact pour éviter le débordement)
                    if (hasAnyReport) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      ..._buildReportsList(),
                    ],
                    
                    // Espace final pour éviter que le contenu ne touche le bord
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        );
      },
    );
  }
}