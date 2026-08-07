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
                _buildStatusBadge(syncState.status),
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
                  Text(
                    syncState.statusMessage ?? 'Transfert en cours...',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0078D4)),
                  ),
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
                Text(
                  syncState.lastBackupDate != null
                      ? 'Dernière sauvegarde: ${DateFormat('dd/MM/yyyy HH:mm').format(syncState.lastBackupDate!)}'
                      : 'Aucune sauvegarde distante',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSyncing
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
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: Text(
                      syncState.status == SyncStatus.neverBackedUp
                          ? 'Sauvegarder'
                          : 'Mettre à jour',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () {
                          _confirmRestore(context, ref);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_download_rounded, size: 16),
                  label: const Text('Restaurer'),
                ),
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
      case SyncStatus.localModifications:
        return const Color(0xFFF59E0B); // Orange
      case SyncStatus.neverBackedUp:
        return Colors.grey.shade300;
      case SyncStatus.syncing:
        return const Color(0xFF0078D4); // Bleu
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
        text = 'À JOUR';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
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
        text = 'EN COURS';
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.failed:
      case SyncStatus.interrupted:
        text = 'ÉCHEC';
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
