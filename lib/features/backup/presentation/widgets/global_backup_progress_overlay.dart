// lib/features/backup/presentation/widgets/global_backup_progress_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/backup_orchestrator.dart';
import '../providers/backup_providers.dart';

class GlobalBackupProgressOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalBackupProgressOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orchestratorState = ref.watch(backupOrchestratorStateProvider).value ?? const BackupOrchestratorState();
    final isActive = orchestratorState.isActive || orchestratorState.status == BackupEngineStatus.completed;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette Design System
    final cardBg = isDark
        ? const Color(0xFF1E293B)
        : Colors.white;
    
    final borderColor = isDark
        ? const Color(0xFF0078D4).withValues(alpha: 0.4)
        : const Color(0xFF0078D4).withValues(alpha: 0.2);

    final titleColor = isDark
        ? Colors.white
        : const Color(0xFF0F172A);

    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    final iconBg = const Color(0xFF0078D4).withValues(alpha: 0.12);
    const brandColor = Color(0xFF0078D4);

    final progressPercent = (orchestratorState.currentProgress * 100).toInt();

    return Stack(
      children: [
        child,
        if (isActive)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Pod Icône
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            orchestratorState.status == BackupEngineStatus.completed
                                ? Icons.check_circle_rounded
                                : Icons.cloud_upload_rounded,
                            color: orchestratorState.status == BackupEngineStatus.completed
                                ? const Color(0xFF10B981)
                                : brandColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Titre & Sous-titre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    orchestratorState.status == BackupEngineStatus.completed
                                        ? 'Sauvegarde Cloud Réussie'
                                        : 'Sauvegarde Cloud M365',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (orchestratorState.status == BackupEngineStatus.syncing) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orchestratorState.statusMessage ?? 'Protection de vos données...',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Badge de Progression % & Compteur
                        if (orchestratorState.totalMissions > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: brandColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              orchestratorState.status == BackupEngineStatus.syncing
                                  ? '${orchestratorState.completedMissions}/${orchestratorState.totalMissions} • $progressPercent%'
                                  : '${orchestratorState.completedMissions}/${orchestratorState.totalMissions}',
                              style: const TextStyle(
                                color: brandColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (orchestratorState.status == BackupEngineStatus.syncing) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: orchestratorState.currentProgress > 0 ? orchestratorState.currentProgress : null,
                          backgroundColor: brandColor.withValues(alpha: 0.12),
                          color: brandColor,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
