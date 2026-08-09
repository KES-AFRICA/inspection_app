// lib/pages/stats/components/mission_summary_card.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class MissionSummaryCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;
  final bool isDarkMode;

  const MissionSummaryCard({
    super.key,
    required this.mission,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les données certifiées pour cette mission spécifique
    final data = AnalyticsEngine.computeDashboardData([mission]);

    final rate = data.complianceRate;
    Color rateColor;
    if (rate >= 90.0) {
      rateColor = const Color(0xFF10B981);
    } else if (rate >= 75.0) {
      rateColor = const Color(0xFFF59E0B);
    } else {
      rateColor = const Color(0xFFEF4444);
    }

    final statusColor = _getStatusColor(mission.status);
    final verificateursCount = (mission.verificateurs?.length ?? 0) + (mission.accompagnateurs?.length ?? 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rateColor.withValues(alpha: isDarkMode ? 0.3 : 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : Client, Site et Statut Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.business_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.nomClient,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.nomSite ?? 'Site Unifié KES',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Badge de Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatus(mission.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Ligne 2 : Conformité %, NCs total, Équipements & Photos
            Row(
              children: [
                // Conformité % Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: rateColor),
                      const SizedBox(width: 4),
                      Text(
                        '${rate.toStringAsFixed(1)}% Conf.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: rateColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Non-Conformités Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.nonCompliantPointsCount > 0
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: data.nonCompliantPointsCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.nonCompliantPointsCount} NC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: data.nonCompliantPointsCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Équipements & Photos
                Text(
                  '${data.totalEquipments} éq. • ${data.photoStats.totalPhotos} photos',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ligne 3 : Barre de progression de conformité
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate / 100.0,
                minHeight: 6,
                backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(rateColor),
              ),
            ),

            const SizedBox(height: 12),

            // Ligne 4 : Criticités & Intervenants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Criticités
                Row(
                  children: [
                    _buildCritChip('Critique', data.critiqueCount, const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    _buildCritChip('Majeure', data.majeureCount, const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _buildCritChip('Mineure', data.mineureCount, const Color(0xFF3B82F6)),
                  ],
                ),

                // Équipe / Flèche
                Row(
                  children: [
                    if (verificateursCount > 0) ...[
                      Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        '$verificateursCount pers.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCritChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${label[0]}:$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('encour') || lower.contains('en cours')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('termine') || lower.contains('terminé')) {
      return const Color(0xFF059669);
    }
    return const Color(0xFFD97706);
  }

  String _formatStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('encour') || lower.contains('en cours')) return 'En cours';
    if (lower.contains('termine') || lower.contains('terminé')) return 'Terminée';
    return 'En attente';
  }
}
