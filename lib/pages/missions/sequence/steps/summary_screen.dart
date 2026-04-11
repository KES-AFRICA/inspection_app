import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:inspec_app/services/word_report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SummaryScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;

  const SummaryScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, dynamic> _progress = {};
  bool _isLoading = true;
  bool _isGenerating = false;
  File? _generatedFile;
  String? _generatedFileName;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _saveCurrentStep();
  }

  Future<void> _saveCurrentStep() async {
    // Sauvegarder l'étape courante (Summary) pour pouvoir y revenir
    await SequenceProgressService.saveCurrentStep(widget.mission.id, 6);
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    _progress = await SequenceProgressService.getProgress(widget.mission.id);
    setState(() => _isLoading = false);
  }

  Future<void> _goToPreviousStep() async {
    // Sauvegarder l'étape Summary comme complétée
    await SequenceProgressService.markStepCompleted(widget.mission.id, 6);
    // Revenir à l'étape précédente (Schéma)
    await SequenceProgressService.saveCurrentStep(widget.mission.id, 5);
    
    if (mounted) {
      Navigator.pop(context);
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
            Text('Génération du rapport $reportType en cours...'),
          ],
        ),
      ),
    );

    try {
      File? file;
      if (reportType == 'Word') {
        file = await WordReportService.generateMissionReport(widget.mission.id);
        _generatedFileName = 'Rapport_${widget.mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.docx';
      } else {
        file = await PdfReportService.generateMissionReport(widget.mission.id);
        _generatedFileName = 'Rapport_${widget.mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (file != null && file.existsSync()) {
        setState(() {
          _generatedFile = file;
          _showPreview = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport $reportType généré avec succès !'),
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

  Future<void> _downloadReport() async {
    if (_generatedFile == null) return;
    
    try {
      // Sauvegarder dans le dossier Téléchargements
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final savedFile = await _generatedFile!.copy('${directory.path}/$_generatedFileName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé dans ${directory.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Fallback vers le dossier Documents
        final documentsDir = await getApplicationDocumentsDirectory();
        final savedFile = await _generatedFile!.copy('${documentsDir.path}/$_generatedFileName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé dans les documents'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _shareReport() async {
    if (_generatedFile == null) return;
    
    await Share.shareXFiles(
      [XFile(_generatedFile!.path)],
      subject: 'Rapport d\'audit électrique - ${widget.mission.nomClient}',
      text: 'Voici le rapport d\'audit électrique pour ${widget.mission.nomClient}',
    );
  }

  Future<void> _sendByEmail() async {
    if (_generatedFile == null) return;
    
    // TODO: Implémenter l'envoi par email plus tard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité à venir - Envoi par email'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  int _getCompletedStepsCount() {
    return _progress['completedSteps']?.length ?? 0;
  }

  int _getTotalSteps() {
    return 7; // JSA, Renseignements, Documents, Description, Audit, Schéma, Summary
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completedSteps = _getCompletedStepsCount();
    final totalSteps = _getTotalSteps();
    final percentage = (completedSteps / totalSteps * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé de la mission'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToPreviousStep,
          tooltip: 'Retour à l\'étape précédente',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec succès
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
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
                  const Text(
                    'Informations de la mission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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

            // Résumé des étapes
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
                  const Text(
                    'Étapes complétées',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStepTile(0, 'JSA', _progress['completedSteps']?.contains(0) ?? false),
                  _buildStepTile(1, 'Renseignements généraux', _progress['completedSteps']?.contains(1) ?? false),
                  _buildStepTile(2, 'Documents nécessaires', _progress['completedSteps']?.contains(2) ?? false),
                  _buildStepTile(3, 'Description des installations', _progress['completedSteps']?.contains(3) ?? false),
                  _buildStepTile(4, 'Audit des installations', _progress['completedSteps']?.contains(4) ?? false),
                  _buildStepTile(5, 'Schéma des installations', _progress['completedSteps']?.contains(5) ?? false),
                  _buildStepTile(6, 'Résumé', true),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton générer rapport (ou REGENERER si déjà généré)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generateReport('PDF'),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_generatedFile != null ? 'RÉGÉNÉRER LE RAPPORT' : 'GÉNÉRER LE RAPPORT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Zone de prévisualisation (apparaît après génération)
            if (_showPreview && _generatedFile != null) ...[
              const SizedBox(height: 24),
              
              // Titre de la section
              Row(
                children: [
                  Icon(Icons.preview, size: 20, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'Prévisualisation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Petit bouton de téléchargement
                  IconButton(
                    onPressed: _downloadReport,
                    icon: Icon(Icons.download, color: AppTheme.primaryBlue),
                    tooltip: 'Télécharger le rapport',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Carte de prévisualisation
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    // Aperçu du fichier
                    Container(
                      height: 120,
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
                            Icon(
                              Icons.description,
                              size: 48,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _generatedFileName?.split('/').last ?? 'Rapport généré',
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
                                'Prêt à être partagé',
                                style: TextStyle(fontSize: 10, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Boutons d'action
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sendByEmail,
                              icon: const Icon(Icons.email, size: 18),
                              label: const Text('Email'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                side: BorderSide(color: AppTheme.primaryBlue),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareReport,
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Partager'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildStepTile(int index, String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            size: 20,
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