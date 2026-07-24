import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  final Verificateur user;
  const BackupScreen({super.key, required this.user});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  List<File> _localBackups = [];
  bool _isLoadingBackups = true;

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
  }

  Future<void> _loadLocalBackups() async {
    setState(() => _isLoadingBackups = true);
    final files = await BackupService.getLocalBackupFiles();
    if (mounted) {
      setState(() {
        _localBackups = files;
        _isLoadingBackups = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleExport() async {
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);
    if (missions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune mission disponible à exporter.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (missions.length == 1) {
      await _exportSingleMission(missions.first);
      return;
    }

    final chosen = await _showMissionSelectionDialog(missions);
    if (chosen == null) return;

    if (chosen == '__ALL__') {
      await _exportAllMissions();
    } else {
      final mission = missions.firstWhere(
        (m) => m.id == chosen,
        orElse: () => missions.first,
      );
      await _exportSingleMission(mission);
    }
  }

  Future<void> _exportSingleMission(Mission mission) async {
    _showLoadingDialog(context, "Génération de l'exportation... Veuillez patienter.");
    setState(() => _isExporting = true);

    final result = await BackupService.exporterMission(mission.id);

    if (!mounted) return;
    setState(() => _isExporting = false);
    Navigator.of(context, rootNavigator: true).pop(); // Fermer le dialogue de chargement

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Exportation réussie.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadLocalBackups();
    } else {
      _showErrorDialog(
        result.message ?? "Erreur lors de l'exportation.",
        result.errorDetail,
      );
    }
  }

  Future<void> _exportAllMissions() async {
    _showLoadingDialog(context, "Génération de la sauvegarde globale... Veuillez patienter.");
    setState(() => _isExporting = true);

    final result = await BackupService.exporterMissions(widget.user.matricule);

    if (!mounted) return;
    setState(() => _isExporting = false);
    Navigator.of(context, rootNavigator: true).pop(); // Fermer le dialogue de chargement

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Exportation réussie.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadLocalBackups();
    } else {
      _showErrorDialog(
        result.message ?? "Erreur lors de l'exportation.",
        result.errorDetail,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMPORT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleImport() async {
    try {
      final pickerResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false, // CRITIQUE: 0 Mo alloués en RAM native
      );

      if (pickerResult == null || pickerResult.files.isEmpty) return;

      final filePath = pickerResult.files.first.path;
      if (filePath == null || filePath.isEmpty) {
        if (!mounted) return;
        _showErrorDialog('Chemin de fichier invalide.', null);
        return;
      }

      final inspect = await BackupService.inspecterSauvegardeFichier(filePath);
      if (!inspect.isValid) {
        if (!mounted) return;
        _showErrorDialog(
          inspect.message ?? 'Fichier de sauvegarde invalide.',
          null,
        );
        return;
      }

      if (!mounted) return;
      final mode = await _showImportOptionsDialog(inspect);
      if (mode == null) return; // Annulé

      final ecraser = (mode == 'ecraser');

      double progress = 0.05;
      String progressText = "Initialisation de l'importation...";

      StateSetter? dialogSetState;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSt) {
            dialogSetState = setSt;
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 14),
                  Text('Importation en cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      setState(() => _isImporting = true);

      final result = await BackupService.importerSauvegardeFichier(
        filePath: filePath,
        ecraser: ecraser,
        importeurMatricule: widget.user.matricule,
        importeurNom: widget.user.nom,
        importeurPrenom: widget.user.prenom,
        onProgress: (stage, prg) {
          if (mounted) {
            dialogSetState?.call(() {
              progressText = stage;
              progress = prg;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _isImporting = false);
      Navigator.of(context, rootNavigator: true).pop(); // Fermer loading

      if (result.success) {
        final total = result.importedMissions + result.skippedMissions;
        final warningsText = result.warnings.isNotEmpty
            ? '\n\nAvertissements :\n• ${result.warnings.join('\n• ')}'
            : '';

        _showSuccessDialog(
          'Importation terminée avec succès',
          '${result.importedMissions} mission(s) restaurée(s) sur $total.'
          '${result.skippedMissions > 0 ? " (${result.skippedMissions} conservée(s) sans écraser)" : ""}'
          '$warningsText',
        );
      } else {
        _showErrorDialog(
          result.message ?? "Erreur lors de l'importation.",
          result.errorDetail,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Erreur lors de l'ouverture du fichier.", e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGUES ET MODALES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> _showMissionSelectionDialog(List<Mission> missions) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choisir la sauvegarde',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                leading: Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryBlue),
                title: const Text(
                  'Toutes les missions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${missions.length} mission(s) active(s)',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, '__ALL__'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: missions.length,
                  itemBuilder: (context, index) {
                    final m = missions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_rounded, color: Colors.blue),
                      title: Text(
                        m.nomClient,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        m.nomSite ?? 'Site non renseigné',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      onTap: () => Navigator.pop(ctx, m.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showImportOptionsDialog(InspectionSauvegarde info) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sauvegarde Détectée',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Format', 'V${info.schemaVersion} (${info.magic})'),
                  _buildInfoRow('Type d\'export', info.exportType ?? 'Standard'),
                  _buildInfoRow('Nombre de missions', '${info.missionCount}'),
                  if (info.exportedAt != null)
                    _buildInfoRow('Date de création', info.exportedAt!.substring(0, 16).replaceAll('T', ' à ')),
                  _buildInfoRow('Signature SHA-256', info.checksumValid ? '✅ Valide' : '⚠️ Non vérifiée'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mode d\'importation :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              leading: const Icon(Icons.merge_type_rounded, color: Colors.blue),
              title: const Text('Fusionner sans écraser', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              subtitle: const Text('Renumérote automatiquement les doublons (ex: Mission (1)) sans rien écraser', style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'fusion'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              leading: const Icon(Icons.sync_problem_rounded, color: Colors.orange),
              title: const Text('Remplacer les doublons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              subtitle: const Text('Écrase les missions ayant le même identifiant', style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'ecraser'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String? detail) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: detail != null
            ? Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              )
            : null,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Sauvegarde & Restauration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDarkMode ? Colors.white : AppTheme.darkBlue,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : AppTheme.darkBlue,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sécurisation des données',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sauvegardes chiffrées SHA-256 • Format V3 • Export/Import hors-ligne complet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. CARTES PRINCIPALES (EXPORT & IMPORT)
            Row(
              children: [
                // Carte EXPORTATION
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: 'Exporter',
                    subtitle: '${missions.length} mission(s) disponible(s)',
                    icon: Icons.cloud_upload_rounded,
                    iconColor: AppTheme.primaryBlue,
                    buttonText: 'EXPORTER',
                    isLoading: _isExporting,
                    onTap: _handleExport,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),

                // Carte IMPORTATION
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: 'Importer',
                    subtitle: 'Depuis fichier .json',
                    icon: Icons.cloud_download_rounded,
                    iconColor: Colors.green.shade600,
                    buttonText: 'IMPORTER',
                    isLoading: _isImporting,
                    onTap: _handleImport,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. INFOCARD INTÉGRITÉ & SÉCURITÉ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protection et Traçabilité',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDarkMode ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chaque export inclut l\'intégralité des photos, des mesures et des éléments de Corbeille avec vérification d\'intégrité.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. SAUVEGARDES LOCALES (HISTORIQUE)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SAUVEGARDES LOCALES DETECTÉES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: isDarkMode ? Colors.grey.shade400 : AppTheme.greyDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: _loadLocalBackups,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingBackups)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_localBackups.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun fichier de sauvegarde local dans Downloads/Verif Elec/',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localBackups.length,
                itemBuilder: (context, index) {
                  final file = _localBackups[index];
                  final name = file.path.split('/').last;
                  final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
                  final modDate = file.lastModifiedSync();
                  final dateStr = '${modDate.day.toString().padLeft(2, '0')}/'
                      '${modDate.month.toString().padLeft(2, '0')}/'
                      '${modDate.year} à ${modDate.hour.toString().padLeft(2, '0')}:${modDate.minute.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$sizeKb Ko • $dateStr',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18, color: Colors.blue),
                          onPressed: () {
                            Share.shareXFiles([XFile(file.path)]);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          onPressed: () async {
                            await file.delete();
                            _loadLocalBackups();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
