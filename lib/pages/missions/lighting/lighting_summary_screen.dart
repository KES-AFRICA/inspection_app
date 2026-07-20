import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_light_service.dart';
import 'package:printing/printing.dart';

/// Écran de Résumé et Prévisualisation du Rapport PDF - Vérification Éclairage
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner des Statistiques
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mission.nomClient.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Site : ${widget.mission.nomSite ?? "Non renseigné"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDark.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard('Locaux contrôlés', '$totalLocaux',
                              AppTheme.primaryBlue, Icons.meeting_room_outlined),
                          const SizedBox(width: 8),
                          _buildStatCard('Conformes', '$totalConformes',
                              Colors.green.shade700, Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          _buildStatCard('Non conformes', '$totalNonConformes',
                              Colors.red.shade700, Icons.warning_amber_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lecteur et Prévisualisation PDF Interactif
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PdfPreview(
                      build: (format) async {
                        final file = await PdfReportLightService
                            .generateLightingMissionReport(widget.mission.id);
                        if (file != null) {
                          return file.readAsBytesSync();
                        }
                        return Uint8List(0);
                      },
                      allowPrinting: true,
                      allowSharing: true,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      pdfFileName:
                          'Rapport_Eclairage_${widget.mission.nomClient.replaceAll(RegExp(r'[^\w]'), '_')}_${widget.mission.id}.pdf',
                      loadingWidget: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Génération du rapport PDF Éclairage...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
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
          borderRadius: BorderRadius.circular(8),
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
}
