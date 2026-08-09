import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/backup/components/recent_backups_list.dart';
import 'package:inspec_app/pages/backup/dialogs/invalid_format_dialog.dart';
import 'package:inspec_app/pages/backup/dialogs/operation_progress_dialog.dart';
import 'package:inspec_app/services/backup/operation_progress_state.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';

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

    // 1. Dialogue de sélection des missions avec cases à cocher
    final selectedIds = await _showMissionSelectionDialog(missions);
    if (selectedIds == null || selectedIds.isEmpty)
      return; // Annulé ou aucune sélection

    // 2. Dialogue de confirmation d'exportation (même modèle visuel que l'importation)
    if (!mounted) return;
    final confirmed = await _showExportConfirmationDialog(selectedIds.length);
    if (confirmed != true) return; // Annulé

    // 3. Lancement de l'exportation avec dialogue de progression réactif
    bool isCancelled = false;
    final stateNotifier = ValueNotifier<OperationProgressState>(
      OperationProgressState(
        type: OperationType.export,
        status: OperationStatus.initialization,
        title: 'Exportation de ${selectedIds.length} mission(s)',
        totalMissions: selectedIds.length,
        currentStep: 'Initialisation...',
      ),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return ValueListenableBuilder<OperationProgressState>(
          valueListenable: stateNotifier,
          builder: (context, state, _) {
            return OperationProgressDialog(
              state: state,
              onCancel: () {
                isCancelled = true;
                stateNotifier.value = state.copyWith(
                  status: OperationStatus.cancelled,
                  currentStep: 'Annulation en cours...',
                  isCancelRequested: true,
                );
              },
              onClose: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            );
          },
        );
      },
    );

    setState(() => _isExporting = true);

    final result = await BackupService.exporterMissionsSelection(
      selectedIds,
      matricule: widget.user.matricule,
      onProgressState: (st) {
        if (!isCancelled) {
          stateNotifier.value = st;
        }
      },
      isCancelled: () => isCancelled,
    );

    if (!mounted) return;
    setState(() => _isExporting = false);
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop(); // Fermer le dialogue de progression

    if (result.success) {
      // Affichage du message de succès PUR (sans barre ni loader)
      _showSuccessDialog(
        'Exportation terminée avec succès',
        '${selectedIds.length} mission(s) exportée(s) avec succès dans Downloads/Verif Elec.',
      );
      _loadLocalBackups();
    } else if (isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportation annulée.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        allowedExtensions: ['json', 'inspec', 'bin', 'zip'],
        withData: false,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) return;

      final filePath = pickerResult.files.first.path;
      if (filePath == null || filePath.isEmpty) {
        if (!mounted) return;
        InvalidFormatDialog.show(
          context,
          detailedMessage: 'Chemin de fichier invalide.',
        );
        return;
      }

      // Validation explicite de l'extension
      final lowerPath = filePath.toLowerCase();
      if (!lowerPath.endsWith('.json') &&
          !lowerPath.endsWith('.inspec') &&
          !lowerPath.endsWith('.bin') &&
          !lowerPath.endsWith('.zip')) {
        if (!mounted) return;
        InvalidFormatDialog.show(context);
        return;
      }

      // Inspection de la sauvegarde
      final inspect = await BackupService.inspecterSauvegardeFichier(filePath);
      if (!inspect.isValid) {
        if (!mounted) return;
        InvalidFormatDialog.show(context, detailedMessage: inspect.message);
        return;
      }

      // Dialogue de confirmation unique (Renumérotation automatique des doublons)
      if (!mounted) return;
      final confirmed = await _showSingleImportConfirmationDialog(inspect);
      if (confirmed != true) return; // Annulé par l'utilisateur

      bool isCancelled = false;
      final stateNotifier = ValueNotifier<OperationProgressState>(
        OperationProgressState(
          type: OperationType.import,
          status: OperationStatus.initialization,
          title: 'Importation en cours',
          totalMissions: inspect.missionCount > 0 ? inspect.missionCount : 1,
          currentStep: 'Initialisation de l\'importation...',
        ),
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return ValueListenableBuilder<OperationProgressState>(
            valueListenable: stateNotifier,
            builder: (context, state, _) {
              return OperationProgressDialog(
                state: state,
                onCancel: () {
                  isCancelled = true;
                  stateNotifier.value = state.copyWith(
                    status: OperationStatus.cancelled,
                    currentStep: 'Annulation en cours...',
                    isCancelRequested: true,
                  );
                },
                onClose: () =>
                    Navigator.of(dialogCtx, rootNavigator: true).pop(),
              );
            },
          );
        },
      );

      setState(() => _isImporting = true);

      // Exécution de l'importation sans écraser (renumérotation auto des doublons)
      final result = await BackupService.importerSauvegardeFichier(
        filePath: filePath,
        ecraser: false,
        importeurMatricule: widget.user.matricule,
        importeurNom: widget.user.nom,
        importeurPrenom: widget.user.prenom,
        onProgress: (stage, prg) {
          if (!isCancelled) {
            stateNotifier.value = stateNotifier.value.copyWith(
              status: OperationStatus.inProgress,
              currentStep: stage,
              overallProgress: prg,
            );
          }
        },
      );

      if (!mounted) return;
      setState(() => _isImporting = false);
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Fermer le dialogue de progression

      if (result.success) {
        final total = result.importedMissions + result.skippedMissions;
        final warningsText = result.warnings.isNotEmpty
            ? '\n\nAvertissements :\n• ${result.warnings.join('\n• ')}'
            : '';

        // Affichage du message de succès PUR (sans barre ni loader)
        _showSuccessDialog(
          'Importation terminée avec succès',
          '${result.importedMissions} mission(s) restaurée(s) sur $total.'
              '${result.skippedMissions > 0 ? " (${result.skippedMissions} conservée(s) sans écraser)" : ""}'
              '$warningsText',
        );
        _loadLocalBackups();
      } else if (isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Importation annulée.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorDialog(
          result.message ?? "Erreur lors de l'importation.",
          result.errorDetail,
        );
      }
    } catch (e) {
      if (!mounted) return;
      InvalidFormatDialog.show(context, detailedMessage: e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGUES ET MODALES (SÉLECTION AVEC CASES À COCHER & CONFIRMATIONS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dialogue de sélection de missions avec cases à cocher (ouvert au clic sur EXPORTER)
  Future<List<String>?> _showMissionSelectionDialog(List<Mission> missions) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Set<String> selectedIds = <String>{};

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) {
          final allSelected = selectedIds.length == missions.length;

          return AlertDialog(
            backgroundColor: isDarkMode
                ? const Color(0xFF1E293B)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.cloud_upload_rounded,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choisir les missions à exporter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedIds.length} sélectionnée(s)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSt(() {
                            if (allSelected) {
                              selectedIds.clear();
                            } else {
                              selectedIds.addAll(missions.map((m) => m.id));
                            }
                          });
                        },
                        child: Text(
                          allSelected
                              ? 'Désélectionner tout'
                              : 'Sélectionner tout',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: missions.length,
                      itemBuilder: (context, index) {
                        final m = missions[index];
                        final isChecked = selectedIds.contains(m.id);

                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (val) {
                            setSt(() {
                              if (val == true) {
                                selectedIds.add(m.id);
                              } else {
                                selectedIds.remove(m.id);
                              }
                            });
                          },
                          activeColor: AppTheme.primaryBlue,
                          dense: true,
                          title: Text(
                            m.nomClient,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.darkBlue,
                            ),
                          ),
                          subtitle: Text(
                            m.nomSite ?? 'Site non renseigné',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          secondary: Icon(
                            Icons.folder_rounded,
                            color: isChecked
                                ? AppTheme.primaryBlue
                                : Colors.grey,
                          ),
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
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, selectedIds.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Valider (${selectedIds.length})'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialogue de confirmation d'exportation (Même modèle visuel que la confirmation d'importation)
  Future<bool?> _showExportConfirmationDialog(int count) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
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
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmation d\'Exportation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                  color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                ),
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
                color: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Format de sortie',
                    '.inspec',
                    isDarkMode,
                  ),
                  _buildInfoRow('Missions sélectionnées', '$count', isDarkMode),
                  _buildInfoRow('Signature SHA-256', '✅ Inclus', isDarkMode),
                  _buildInfoRow(
                    'Destination',
                    'Downloads/Verif Elec',
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: const Text(
                  'Exporter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Génère une sauvegarde chiffrée réutilisable sur d\'autres appareils.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialogue de confirmation d'importation unifié
  Future<bool?> _showSingleImportConfirmationDialog(InspectionSauvegarde info) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
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
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.green.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sauvegarde Détectée',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                  color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                ),
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
                color: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Format',
                    'V${info.schemaVersion} (${info.magic})',
                    isDarkMode,
                  ),
                  _buildInfoRow(
                    'Type d\'export',
                    info.exportType ?? 'Standard',
                    isDarkMode,
                  ),
                  _buildInfoRow(
                    'Missions contenues',
                    '${info.missionCount}',
                    isDarkMode,
                  ),
                  if (info.exportedAt != null)
                    _buildInfoRow(
                      'Créé le',
                      info.exportedAt!.substring(0, 16).replaceAll('T', ' à '),
                      isDarkMode,
                    ),
                  _buildInfoRow(
                    'Signature SHA-256',
                    info.checksumValid ? '✅ Valide' : '⚠️ Non vérifiée',
                    isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cloud_download_rounded, size: 20),
                label: const Text(
                  'Importer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Renumérote les doublons si une mission portant le même identifiant existe déjà.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialogue de succès PUR (Affiche uniquement le message de succès sans loader ni barre de progression)
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
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 28,
              ),
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
                color: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDarkMode
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Compris',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
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
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 28,
              ),
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
                  color: isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDarkMode
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF991B1B),
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
                backgroundColor: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                foregroundColor: isDarkMode
                    ? Colors.white
                    : const Color(0xFF1E293B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE PRINCIPALE (DESIGN ET STRUCTURE ORIGINALE PRÉSERVÉS À 100%)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER BANNER (Original)
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
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
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
                          'Sauvegardes chiffrées SHA-256 • Format V4 • Export/Import hors-ligne complet',
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

            // 2. CARTES PRINCIPALES (EXPORT & IMPORT - Originales)
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
                    subtitle: 'Depuis fichier (.inspec, .bin, .json)',
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

            // 3. INFOCARD INTÉGRITÉ & SÉCURITÉ (Originale)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
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
                            color: isDarkMode
                                ? Colors.white
                                : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chaque export inclut l\'intégralité des photos, des mesures et des éléments de Corbeille avec vérification d\'intégrité.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. SAUVEGARDES LOCALES (Conserver les 4 dernières générations)
            RecentBackupsList(
              backups: _localBackups,
              isLoading: _isLoadingBackups,
              onRefresh: _loadLocalBackups,
              onDeleteFile: (file) async {
                await file.delete();
                _loadLocalBackups();
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
