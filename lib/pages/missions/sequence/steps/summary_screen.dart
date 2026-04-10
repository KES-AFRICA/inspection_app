import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:inspec_app/services/word_report_service.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    _progress = await SequenceProgressService.getProgress(widget.mission.id);
    setState(() => _isLoading = false);
  }

  Future<void> _generateAndShareReport(String reportType) async {
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
      } else {
        file = await PdfReportService.generateMissionReport(widget.mission.id);
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (file != null && file.existsSync()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Rapport d\'audit électrique - ${widget.mission.nomClient}',
          text: 'Voici le rapport d\'audit électrique pour ${widget.mission.nomClient}',
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
    return 6; // Renseignements, JSA, Documents, Description, Audit, Schéma
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
                  _buildStepTile(0, 'Renseignements généraux', _progress['completedSteps']?.contains(0) ?? false),
                  _buildStepTile(1, 'JSA', _progress['completedSteps']?.contains(1) ?? false),
                  _buildStepTile(2, 'Documents nécessaires', _progress['completedSteps']?.contains(2) ?? false),
                  _buildStepTile(3, 'Description des installations', _progress['completedSteps']?.contains(3) ?? false),
                  _buildStepTile(4, 'Audit des installations', _progress['completedSteps']?.contains(4) ?? false),
                  _buildStepTile(5, 'Schéma des installations', _progress['completedSteps']?.contains(5) ?? false),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton générer rapport
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generateAndShareReport('PDF'),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Génération...' : 'GÉNÉRER LE RAPPORT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bouton partager
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : () => _generateAndShareReport('Word'),
                icon: const Icon(Icons.share),
                label: const Text('PARTAGER'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
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