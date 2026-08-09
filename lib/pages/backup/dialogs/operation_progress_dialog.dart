// lib/pages/backup/dialogs/operation_progress_dialog.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/backup/operation_progress_state.dart';

class OperationProgressDialog extends StatelessWidget {
  final OperationProgressState state;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;

  const OperationProgressDialog({
    super.key,
    required this.state,
    this.onCancel,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExport = state.type == OperationType.export;

    final isDone = state.status == OperationStatus.completed;
    final isError = state.status == OperationStatus.error;
    final isCancelled = state.status == OperationStatus.cancelled;
    final isCancelRequested = state.isCancelRequested;

    Color headerColor;
    IconData headerIcon;
    String statusTitle;

    if (isDone) {
      headerColor = const Color(0xFF10B981);
      headerIcon = Icons.check_circle_rounded;
      statusTitle = isExport ? 'Exportation terminée' : 'Importation terminée';
    } else if (isCancelled) {
      headerColor = const Color(0xFFF59E0B);
      headerIcon = Icons.warning_amber_rounded;
      statusTitle = 'Opération annulée';
    } else if (isError) {
      headerColor = const Color(0xFFEF4444);
      headerIcon = Icons.error_outline_rounded;
      statusTitle = isExport ? 'Échec de l\'exportation' : 'Échec de l\'importation';
    } else {
      headerColor = AppTheme.primaryBlue;
      headerIcon = isExport ? Icons.cloud_upload_rounded : Icons.cloud_download_rounded;
      statusTitle = state.title;
    }

    final percentageInt = (state.overallProgress.clamp(0.0, 1.0) * 100).toInt();

    return PopScope(
      canPop: isDone || isError || isCancelled,
      child: Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. En-tête avec Icône & Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(headerIcon, color: headerColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isDone && !isError && !isCancelled)
                          Text(
                            isCancelRequested ? 'Annulation en cours...' : 'Traitement des données',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isCancelRequested
                                  ? Colors.orange
                                  : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isDone && !isError && !isCancelled)
                    Text(
                      '$percentageInt %',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: headerColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Barre de progression globale
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (isDone || isError || isCancelled) ? null : state.overallProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(headerColor),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Carte de contexte de la mission courante
              if (state.currentMissionName != null || state.totalMissions > 1)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder_open_rounded,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mission ${state.currentMissionIndex} sur ${state.totalMissions}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.currentMissionName ?? 'Mission Inconnu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // 4. Étape courante & compteurs
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.currentStep,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (state.processedItemsCount > 0 || state.processedPhotosCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (state.processedItemsCount > 0)
                      _buildBadge(
                        label: '${state.processedItemsCount} éléments',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF2563EB),
                        isDarkMode: isDarkMode,
                      ),
                    if (state.processedItemsCount > 0 && state.processedPhotosCount > 0)
                      const SizedBox(width: 6),
                    if (state.processedPhotosCount > 0)
                      _buildBadge(
                        label: '${state.processedPhotosCount} médias',
                        icon: Icons.photo_library_rounded,
                        color: const Color(0xFF7C3AED),
                        isDarkMode: isDarkMode,
                      ),
                  ],
                ),
              ],

              // Message de succès / erreur
              if (state.message != null && state.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  state.message!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? const Color(0xFF10B981) : (isDarkMode ? Colors.grey.shade300 : Colors.black87),
                  ),
                ),
              ],

              if (state.errorDetail != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorDetail!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 20),

              // 5. Actions (Bouton Annuler ou Bouton Fermer)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isDone && !isError && !isCancelled)
                    OutlinedButton.icon(
                      onPressed: isCancelRequested ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        isCancelRequested
                            ? 'Annulation...'
                            : (isExport ? 'Annuler l\'exportation' : 'Annuler l\'importation'),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: headerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
