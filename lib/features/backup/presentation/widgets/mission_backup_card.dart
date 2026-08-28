// lib/features/backup/presentation/widgets/mission_backup_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/mission.dart';
import '../../domain/models/mission_sync_state.dart';
import '../providers/backup_providers.dart';

class MissionBackupCard extends ConsumerWidget {
  final Mission mission;
  final String currentMatricule;

  const MissionBackupCard({
    super.key,
    required this.mission,
    required this.currentMatricule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStates = ref.watch(backupSyncNotifierProvider);
    final syncState = syncStates[mission.id] ??
        MissionSyncState(
          missionId: mission.id,
          status: SyncStatus.neverBackedUp,
          statusMessage: 'Jamais sauvegardée',
        );

    final isSyncing = syncState.status == SyncStatus.syncing;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getBorderColor(syncState.status),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : Nom Mission & Badge d'état
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.nomClient,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mission.natureMission ?? "Inspection"} • ${mission.adresseClient ?? ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(syncState.status),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: Icon(
                        syncState.status == SyncStatus.paused ? Icons.pause_circle_filled_rounded : Icons.more_vert_rounded,
                        size: 20,
                        color: syncState.status == SyncStatus.paused ? const Color(0xFFD97706) : Colors.grey.shade600,
                      ),
                      tooltip: 'Gestion de la sauvegarde automatique',
                      onSelected: (value) async {
                        if (value == 'pause') {
                          _confirmPause(context, ref);
                        } else if (value == 'resume') {
                          await ref.read(backupQueueServiceProvider).setMissionPaused(mission.id, currentMatricule, false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sauvegarde automatique réactivée pour cette mission.'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (syncState.status != SyncStatus.paused)
                          const PopupMenuItem(
                            value: 'pause',
                            child: Row(
                              children: [
                                Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFD97706), size: 18),
                                SizedBox(width: 8),
                                Text('Mettre en pause l\'auto-backup', style: TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'resume',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                                SizedBox(width: 8),
                                Text('Réactiver l\'auto-backup', style: TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression en direct si synchronisation en cours
            if (isSyncing) ...[
              LinearProgressIndicator(
                value: syncState.progress > 0 ? syncState.progress : null,
                backgroundColor: Colors.blue.shade100,
                color: const Color(0xFF0078D4),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      syncState.statusMessage ?? 'Transfert en cours...',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0078D4)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(syncState.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0078D4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Détails Métadonnées
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    syncState.lastBackupDate != null
                        ? 'Dernière sauvegarde: ${DateFormat('dd/MM/yyyy HH:mm').format(syncState.lastBackupDate!)}'
                        : 'Aucune sauvegarde distante',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action intelligents (Pause, Reprendre, Annuler, Sauvegarder, Restaurer)
            Row(
              children: [
                if (syncState.status == SyncStatus.syncing) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final activeJob = await ref
                            .read(backupJobManagerProvider)
                            .getActiveJobForMission(mission.id);
                        if (activeJob != null) {
                          await ref
                              .read(backupSyncNotifierProvider.notifier)
                              .pauseBackup(activeJob.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.pause_circle_filled_rounded, size: 16),
                      label: const Text(
                        'Mettre en pause',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final activeJob = await ref
                            .read(backupJobManagerProvider)
                            .getActiveJobForMission(mission.id);
                        if (activeJob != null) {
                          await ref
                              .read(backupSyncNotifierProvider.notifier)
                              .cancelBackup(activeJob.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        'Annuler',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ] else if (syncState.status == SyncStatus.paused || syncState.status == SyncStatus.localOnly) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final activeJob = await ref
                            .read(backupJobManagerProvider)
                            .getActiveJobForMission(mission.id);
                        if (activeJob != null) {
                          await ref
                              .read(backupSyncNotifierProvider.notifier)
                              .resumeBackup(activeJob.id, currentMatricule);
                        } else {
                          await ref
                              .read(backupSyncNotifierProvider.notifier)
                              .backupMission(mission.id, currentMatricule);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                      label: const Text(
                        'Reprendre',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final activeJob = await ref
                            .read(backupJobManagerProvider)
                            .getActiveJobForMission(mission.id);
                        if (activeJob != null) {
                          await ref
                              .read(backupSyncNotifierProvider.notifier)
                              .cancelBackup(activeJob.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        'Annuler',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (isSyncing || syncState.status == SyncStatus.upToDate)
                          ? null
                          : () async {
                              final success = await ref
                                  .read(backupSyncNotifierProvider.notifier)
                                  .backupMission(mission.id, currentMatricule);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Sauvegarde Cloud effectuée avec succès !'
                                          : 'Échec de la sauvegarde.',
                                    ),
                                    backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: syncState.status == SyncStatus.upToDate
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF0078D4),
                        disabledBackgroundColor: syncState.status == SyncStatus.upToDate
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                        foregroundColor: syncState.status == SyncStatus.upToDate
                            ? const Color(0xFF047857)
                            : Colors.white,
                        disabledForegroundColor: syncState.status == SyncStatus.upToDate
                            ? const Color(0xFF047857)
                            : Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: syncState.status == SyncStatus.upToDate ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: syncState.status == SyncStatus.upToDate
                              ? const BorderSide(color: Color(0xFF10B981), width: 1)
                              : BorderSide.none,
                        ),
                      ),
                      icon: Icon(
                        syncState.status == SyncStatus.upToDate
                            ? Icons.check_circle_rounded
                            : Icons.cloud_upload_rounded,
                        size: 16,
                      ),
                      label: Text(
                        syncState.status == SyncStatus.upToDate
                            ? 'Mission à jour'
                            : 'Sauvegarder',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSyncing || syncState.status == SyncStatus.neverBackedUp
                          ? null
                          : () {
                              _confirmRestore(context, ref);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded, size: 16),
                      label: const Text(
                        'Restaurer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.upToDate:
        return const Color(0xFF10B981); // Vert
      case SyncStatus.localOnly:
        return const Color(0xFFF59E0B); // Ambre / Jaune
      case SyncStatus.pendingUpload:
        return const Color(0xFF3B82F6); // Bleu clair
      case SyncStatus.localModifications:
        return const Color(0xFFF59E0B); // Orange
      case SyncStatus.neverBackedUp:
        return Colors.grey.shade300;
      case SyncStatus.syncing:
        return const Color(0xFF0078D4); // Bleu
      case SyncStatus.paused:
        return const Color(0xFFD97706); // Ambre Pause
      case SyncStatus.failed:
      case SyncStatus.interrupted:
        return const Color(0xFFEF4444); // Rouge
    }
  }

  Widget _buildStatusBadge(SyncStatus status) {
    String text;
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case SyncStatus.upToDate:
        text = 'CLOUD & LOCAL';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        break;
      case SyncStatus.localOnly:
        text = 'LOCAL';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.phonelink_lock_rounded;
        break;
      case SyncStatus.pendingUpload:
        text = 'EN ATTENTE';
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        icon = Icons.hourglass_top_rounded;
        break;
      case SyncStatus.localModifications:
        text = 'MODIFIÉE';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon = Icons.edit_note_rounded;
        break;
      case SyncStatus.neverBackedUp:
        text = 'NON SAUVEGARDÉE';
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        icon = Icons.cloud_off_rounded;
        break;
      case SyncStatus.syncing:
        text = 'TRANSFERT CLOUD';
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.paused:
        text = 'PAUSE';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.pause_circle_filled_rounded;
        break;
      case SyncStatus.failed:
      case SyncStatus.interrupted:
        text = 'ÉCHEC CLOUD';
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPause(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mettre en pause l\'Auto-Backup ?'),
        content: Text(
          'Voulez-vous suspendre la sauvegarde automatique planifiée pour la mission "${mission.nomClient}" ?\n\nCette mission ne sera plus sauvegardée automatiquement à 17h10 jusqu\'à sa réactivation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(backupQueueServiceProvider).setMissionPaused(mission.id, currentMatricule, true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sauvegarde automatique mise en pause.'),
                    backgroundColor: Color(0xFFD97706),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            child: const Text('Mettre en pause'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la restauration'),
        content: Text(
          'Voulez-vous restaurer la version Cloud de la mission "${mission.nomClient}" ? Les données locales seront mises à jour avec la version enregistrée dans le Cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restauration en cours de développement...'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0078D4)),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }
}
