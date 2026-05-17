// lib/pages/backup/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:file_picker/file_picker.dart' ;
import 'package:inspec_app/services/backup_service.dart';


class BackupScreen extends StatefulWidget {
  final Verificateur user;
  const BackupScreen({super.key, required this.user});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  // ── Export ──
  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    final result =
        await BackupService.exporterMissions(widget.user.matricule);
    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? 'Export réussi.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ));
    } else {
      _showErrorDialog(result.message ?? 'Erreur inconnue.', result.errorDetail);
    }
  }

  // ── Import ──
  Future<void> _handleImport() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final filePath = picked.files.first.path;
    if (filePath == null) return;

    final opts = await _showImportOptionsDialog();
    if (opts == null) return;

    setState(() => _isImporting = true);
    final result = await BackupService.importerMissions(
      filePath,
      ecraserExistants: opts['ecraser'] as bool,
    );
    if (!mounted) return;
    setState(() => _isImporting = false);

    if (result.importedMissions > 0 ||
        result.skippedMissions > 0 ||
        result.warnings.isNotEmpty) {
      _showImportReport(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? ''),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // ── Dialogue options import ──
  Future<Map<String, dynamic>?> _showImportOptionsDialog() {
    bool ecraser = false;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.file_download_outlined,
                  color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              Expanded(      // ← Permet au texte de prendre l'espace restant sans déborder
                child: Text('Importer une sauvegarde'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Importer les missions depuis ce fichier de sauvegarde ?'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Cette opération ne peut pas être annulée.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange))),
                  ],
                ),
              ),
              CheckboxListTile(
                value: ecraser,
                onChanged: (v) => setS(() => ecraser = v ?? false),
                title: const Text('Écraser les missions existantes',
                    style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'ecraser': ecraser}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Importer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rapport d'import ──
  void _showImportReport(ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
              result.success
                  ? Icons.check_circle
                  : Icons.error_outline,
              color: result.success ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          const Text("Rapport d'import"),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reportRow(Icons.file_download, 'Importées',
                  '${result.importedMissions}', Colors.green),
              _reportRow(Icons.skip_next, 'Ignorées',
                  '${result.skippedMissions}', Colors.orange),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Avertissements :',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ...result.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(w,
                                    style:
                                        const TextStyle(fontSize: 12))),
                          ]),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg, String? detail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Erreur'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _reportRow(
          IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Sauvegarde & Restauration'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bandeau info ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryBlue.withOpacity(0.10),
                  AppTheme.primaryBlue.withOpacity(0.04)
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.security,
                      color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protection de vos données',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.primaryBlue)),
                      SizedBox(height: 4),
                      Text(
                          'Exportez régulièrement vos missions pour éviter '
                          'toute perte en cas de panne ou de perte du téléphone.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Card Export ──
            _buildActionCard(
              icon: Icons.file_upload_outlined,
              color: AppTheme.primaryBlue,
              title: 'Exporter mes missions',
              subtitle:
                  'Génère un fichier JSON complet de toutes vos missions, '
                  'locaux, équipements, brouillons et données d\'inspection.',
              tip:
                  'Partagez le fichier sur Google Drive, WhatsApp, email ou tout autre cloud.',
              buttonLabel: 'Exporter toutes mes missions',
              isLoading: _isExporting,
              onPressed: _isExporting ? null : _handleExport,
            ),

            const SizedBox(height: 16),

            // ── Card Import ──
            _buildActionCard(
              icon: Icons.file_download_outlined,
              color: Colors.teal,
              title: 'Importer une sauvegarde',
              subtitle:
                  'Restaure vos données depuis un fichier .json créé par l\'application.',
              tip:
                  'Sélectionnez le fichier .json depuis votre téléphone ou votre cloud.',
              buttonLabel: 'Sélectionner et importer',
              isLoading: _isImporting,
              onPressed: _isImporting ? null : _handleImport,
            ),

            const SizedBox(height: 24),

            // ── Bonnes pratiques ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('Bonnes pratiques',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  _tip(Icons.calendar_today, 'Fréquence',
                      'Exportez après chaque journée d\'inspection sur le terrain.'),
                  _tip(Icons.cloud_upload, 'Stockage',
                      'Conservez le fichier sur Google Drive, OneDrive ou envoyez-le par email.'),
                  _tip(Icons.phone_android, 'Restauration',
                      'Sur un nouveau téléphone, installez l\'app puis importez votre sauvegarde.'),
                  _tip(Icons.update, 'Compatibilité',
                      'Les sauvegardes sont versionnées et rétrocompatibles avec les futures versions.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String tip,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Text(tip,
                    style: TextStyle(fontSize: 11, color: color))),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(icon, size: 18),
            label: Text(
                isLoading ? 'Traitement en cours...' : buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tip(IconData icon, String label, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(text,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ]),
      );
}