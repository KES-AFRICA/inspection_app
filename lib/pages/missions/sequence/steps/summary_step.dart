// lib/pages/missions/sequence/steps/summary_step.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:inspec_app/services/word_report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;

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
  }

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

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    _progress = await SequenceProgressService.getProgress(widget.mission.id);
    
    // ✅ Vérifier et corriger l'état du schéma si nécessaire
    final mission = HiveService.getMissionById(widget.mission.id);
    final completedSteps = _progress['completedSteps'] as List<dynamic>? ?? [];
    
    if (mission?.schemaOption != null && !completedSteps.contains(5)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 5);
      _progress = await SequenceProgressService.getProgress(widget.mission.id);
    }
    
    setState(() => _isLoading = false);
  }

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
        final lastReport = LastReport(
          missionId: widget.mission.id,
          filePath: file.path,
          fileName: fileName,
          generatedAt: DateTime.now(),
          reportType: reportType,
        );
        await HiveService.saveLastReport(lastReport);
        
        setState(() {
          if (reportType == 'pdf') {
            _pdfFile = file;
            _pdfFileName = fileName;
            _showPdfPreview = true;
          } else {
            _wordFile = file;
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

  Future<void> _downloadReport(File file, String fileName) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final verifDir = Directory('${directory.path}/Verif Elec');
        if (!await verifDir.exists()) {
          await verifDir.create(recursive: true);
        }
        await file.copy('${verifDir.path}/$fileName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé dans ${verifDir.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        await file.copy('${documentsDir.path}/$fileName');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport sauvegardé dans les documents'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
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
    // Récupérer les emails des vérificateurs
    final renseignements = await HiveService.getRenseignementsGenerauxByMissionId(widget.mission.id);
    final verificateurs = renseignements?.verificateurs ?? [];
    final emails = verificateurs.map((v) => v['email']).where((e) => e != null && e.isNotEmpty).toList();
    
    if (emails.isEmpty) {
      _showError('Aucun email de vérificateur trouvé');
      return;
    }
    
    final recipients = emails.join(',');
    final subject = Uri.encodeComponent('Rapport d\'audit électrique - ${widget.mission.nomClient}');
    final body = Uri.encodeComponent(
      'Bonjour,\n\n'
      'La mission d\'audit électrique pour ${widget.mission.nomClient} est terminée.\n\n'
      'Veuillez trouver ci-joint le rapport complet.\n\n'
      'Cordialement,\n'
      '${widget.user.prenom} ${widget.user.nom}'
    );
    
    // Pour l'email avec pièce jointe, on utilise share_plus
    // L'utilisateur choisira son application email préférée
    if (_pdfFile != null) {
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: Uri.decodeComponent(subject),
        text: Uri.decodeComponent(body),
      );
    } else if (_wordFile != null) {
      await Share.shareXFiles(
        [XFile(_wordFile!.path)],
        subject: Uri.decodeComponent(subject),
        text: Uri.decodeComponent(body),
      );
    } else {
      _showError('Aucun rapport à envoyer');
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

  void _finishMission() async {
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
          GestureDetector(
            onTap: () => _previewReport(file),
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
                Container(
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
                ),
                const SizedBox(height: 24),

                // Informations de la mission
                Container(
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
                ),
                const SizedBox(height: 24),

                // Étapes complétées avec icônes différenciées
                Container(
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
                      _buildStepTile(
                        0,
                        'JSA',
                        _progress['completedSteps']?.contains(0) ?? false,
                        Icons.engineering_outlined,
                      ),
                      _buildStepTile(
                        1,
                        'Renseignements généraux',
                        _progress['completedSteps']?.contains(1) ?? false,
                        Icons.info_outline,
                      ),
                      _buildStepTile(
                        2,
                        'Documents nécessaires',
                        _progress['completedSteps']?.contains(2) ?? false,
                        Icons.folder_outlined,
                      ),
                      _buildStepTile(
                        3,
                        'Description des installations',
                        _progress['completedSteps']?.contains(3) ?? false,
                        Icons.description_outlined,
                      ),
                      _buildStepTile(
                        4,
                        'Audit des installations',
                        _progress['completedSteps']?.contains(4) ?? false,
                        Icons.electrical_services_outlined,
                      ),
                      _buildStepTile(
                        5,
                        'Schéma des installations',
                        _progress['completedSteps']?.contains(5) ?? false,
                        Icons.timeline_outlined,
                      ),
                      _buildStepTile(
                        6,
                        'Résumé',
                        true,
                        Icons.summarize_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton Générer/Régénérer
                SizedBox(
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
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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