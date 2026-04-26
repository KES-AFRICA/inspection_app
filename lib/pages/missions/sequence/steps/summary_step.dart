// lib/pages/missions/sequence/steps/summary_step.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/file_storage_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:inspec_app/services/word_report_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class SummaryStep extends StatefulWidget {
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
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  Map<String, dynamic> _progress = {};
  bool _isLoading = true;
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
    _ensureStatusIsTermine();
    _loadLastReports();
    _markCurrentStepCompleted();
  }

  /// Marque l'étape Résumé (index 6) comme complétée
  Future<void> _markCurrentStepCompleted() async {
    await SequenceProgressService.markStepCompleted(widget.mission.id, 6);
    if (kDebugMode) {
      print('✅ Étape 6 (Résumé) marquée comme complétée');
    }
  }

  /// S'assure que le statut de la mission est "terminé"
  Future<void> _ensureStatusIsTermine() async {
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null && !mission.isTermine) {
      await HiveService.updateMissionStatus(
        missionId: widget.mission.id,
        newStatus: 'termine',
      );
      widget.mission.status = 'termine';
    }
  }

  /// Charge la progression et corrige l'étape 6 si nécessaire
  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    
    // Force l'étape 6 comme complétée
    await SequenceProgressService.markStepCompleted(widget.mission.id, 6);
    
    _progress = await SequenceProgressService.getProgress(widget.mission.id);
    
    final completedSteps = _progress['completedSteps'] as List<dynamic>? ?? [];
    if (kDebugMode) {
      print('📊 Étapes complétées: $completedSteps');
    }
    
    setState(() => _isLoading = false);
  }

  /// Charge les derniers rapports générés depuis Hive
  Future<void> _loadLastReports() async {
    final reports = await HiveService.getAllReportsForMission(widget.mission.id);
    
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

  /// Génère un nouveau rapport (PDF ou Word)
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
        // Sauvegarde dans le dossier dédié
        final savedFile = await FileStorageService.saveReport(file, fileName);
        
        final lastReport = LastReport(
          missionId: widget.mission.id,
          filePath: savedFile.path,
          fileName: fileName,
          generatedAt: DateTime.now(),
          reportType: reportType,
        );
        await HiveService.saveLastReport(lastReport);
        
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

  /// Affiche le dialogue de choix du type de rapport (PDF ou Word)
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
            // Handle
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
            // Option PDF
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
            // Option Word
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

  /// Prévisualise un rapport (PDF uniquement)
  Future<void> _previewReport(File file, String reportType) async {
    // Word non prévisualisable - afficher un dialogue design
    if (reportType == 'docx') {
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

  /// Affiche un dialogue design pour informer que la prévisualisation Word n'est pas disponible
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

  /// Télécharge le rapport dans le dossier /Downloads/Verif Elec/
  Future<void> _downloadReport(File file, String fileName) async {
    // Demander la permission avant de télécharger
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

  /// Vérifier et demander la permission de stockage
  Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Pour Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
      
      // Pour les versions antérieures
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

  /// Partage le rapport via l'application de partage native
  Future<void> _shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rapport d\'audit électrique - ${widget.mission.nomClient}',
      text: 'Voici le rapport d\'audit électrique pour ${widget.mission.nomClient}',
    );
  }

  /// Envoie un email avec le rapport aux vérificateurs
  Future<void> _sendEmailWithAttachment() async {
    // Récupère les emails des vérificateurs
    final renseignements = await HiveService.getRenseignementsGenerauxByMissionId(widget.mission.id);
    final verificateurs = renseignements?.verificateurs ?? [];
    
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
        // Fallback avec share_plus
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

  /// Termine la mission et retourne à l'écran des détails
  Future<void> _finishMission() async {
    await HiveService.updateMissionStatus(
      missionId: widget.mission.id,
      newStatus: 'termine',
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

  /// Carte d'affichage d'un rapport avec ses actions
  Widget _buildReportCard({
    required File file,
    required String? fileName,
    required String reportType,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Zone cliquable pour la prévisualisation
          GestureDetector(
            onTap: () => _previewReport(file, reportType),  // ✅ CORRECTION ICI
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48, color: color),
                    const SizedBox(height: 8),
                    Text(
                      fileName?.split('/').last ?? 'Rapport généré',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cliquez pour visualiser',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Actions du rapport
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _downloadReport(file, fileName!),
                  icon: Icon(Icons.download, color: color),
                  tooltip: 'Télécharger',
                ),
                IconButton(
                  onPressed: () => _shareReport(file),
                  icon: Icon(Icons.share, color: color),
                  tooltip: 'Partager',
                ),
                IconButton(
                  onPressed: _sendEmailWithAttachment,
                  icon: Icon(Icons.email, color: color),
                  tooltip: 'Envoyer par email',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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

                // Zone des rapports (visible uniquement si des rapports existent)
                if (hasAnyReport) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  if (hasPdf)
                    _buildReportCard(
                      file: _pdfFile!,
                      fileName: _pdfFileName,
                      reportType: 'pdf',
                      icon: Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                  if (hasWord)
                    _buildReportCard(
                      file: _wordFile!,
                      fileName: _wordFileName,
                      reportType: 'word',
                      icon: Icons.description,
                      color: Colors.blue,
                    ),
                ],
              ],
            ),
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }

  /// Widget d'en-tête de succès
  Widget _buildSuccessHeader(int completedSteps, int totalSteps, int percentage) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            'Mission terminée !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez complété $completedSteps/$totalSteps étapes',
            style: TextStyle(fontSize: 14, color: Colors.green.shade700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.green.shade100,
            color: Colors.green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% complété',
            style: TextStyle(fontSize: 12, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  /// Widget des informations de la mission
  Widget _buildMissionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations de la mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSummaryRow('Client', widget.mission.nomClient),
          if (widget.mission.activiteClient != null)
            _buildSummaryRow('Activité', widget.mission.activiteClient!),
          if (widget.mission.adresseClient != null)
            _buildSummaryRow('Adresse', widget.mission.adresseClient!),
          _buildSummaryRow('Statut', widget.mission.status),
        ],
      ),
    );
  }

  /// Widget du résumé des étapes complétées
  Widget _buildStepsCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Étapes complétées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildStepTile(0, 'JSA', _progress['completedSteps']?.contains(0) ?? false, Icons.engineering_outlined),
          _buildStepTile(1, 'Renseignements généraux', _progress['completedSteps']?.contains(1) ?? false, Icons.info_outline),
          _buildStepTile(2, 'Documents nécessaires', _progress['completedSteps']?.contains(2) ?? false, Icons.folder_outlined),
          _buildStepTile(3, 'Description des installations', _progress['completedSteps']?.contains(3) ?? false, Icons.description_outlined),
          _buildStepTile(4, 'Audit des installations', _progress['completedSteps']?.contains(4) ?? false, Icons.electrical_services_outlined),
          _buildStepTile(5, 'Schéma des installations', _progress['completedSteps']?.contains(5) ?? false, Icons.timeline_outlined),
          _buildStepTile(6, 'Résumé', true, Icons.summarize_outlined),
        ],
      ),
    );
  }

  /// Widget du bouton de génération de rapport
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _showReportTypeDialog,
        icon: _isGenerating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(hasAnyReport ? Icons.refresh : Icons.add),
        label: Text(hasAnyReport ? 'RÉGÉNÉRER' : 'GÉNÉRER'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Widget de la barre de navigation inférieure
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
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  /// Ligne d'information (label + valeur)
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

  /// Ligne d'étape avec icône différenciée selon l'état de complétion
  Widget _buildStepTile(int index, String title, bool isCompleted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : icon,
              color: isCompleted ? Colors.green : Colors.grey.shade500,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}