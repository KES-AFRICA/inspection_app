// lib/pages/stats/components/compliance_health_card.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class ComplianceHealthCard extends StatelessWidget {
  final AnalyticsDashboardData data;
  final bool isDarkMode;

  const ComplianceHealthCard({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final rate = data.complianceRate;
    Color rateColor;
    String healthStatus;
    IconData healthIcon;

    if (rate >= 90.0) {
      rateColor = const Color(0xFF10B981);
      healthStatus = 'Excellente conformité globale';
      healthIcon = Icons.check_circle_rounded;
    } else if (rate >= 75.0) {
      rateColor = const Color(0xFFF59E0B);
      healthStatus = 'Conformité satisfaisante (Vigilance)';
      healthIcon = Icons.warning_amber_rounded;
    } else {
      rateColor = const Color(0xFFEF4444);
      healthStatus = 'Niveau de risque élevé (Intervention requise)';
      healthIcon = Icons.gpp_bad_rounded;
    }

    final nonCompliantRate = data.totalPointsEvaluated > 0
        ? (data.nonCompliantPointsCount / data.totalPointsEvaluated) * 100.0
        : 0.0;
    final naRate = data.totalPointsEvaluated > 0
        ? (data.naPointsCount / data.totalPointsEvaluated) * 100.0
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rateColor.withValues(alpha: isDarkMode ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety_rounded, size: 20, color: rateColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catégorie 2 — Santé de la Conformité',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(healthIcon, size: 14, color: rateColor),
                    const SizedBox(width: 4),
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: rateColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Diagnostic de santé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(healthIcon, size: 16, color: rateColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    healthStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rateColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de progression tricolore interactive
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (data.compliantPointsCount > 0)
                    Expanded(
                      flex: data.compliantPointsCount,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (data.nonCompliantPointsCount > 0)
                    Expanded(
                      flex: data.nonCompliantPointsCount,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  if (data.naPointsCount > 0)
                    Expanded(
                      flex: data.naPointsCount,
                      child: Container(color: const Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Légende détaillée tricolore
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                label: 'Conformes',
                count: data.compliantPointsCount,
                percentage: rate,
                color: const Color(0xFF10B981),
              ),
              _buildLegendItem(
                label: 'Non-conformes',
                count: data.nonCompliantPointsCount,
                percentage: nonCompliantRate,
                color: const Color(0xFFEF4444),
              ),
              _buildLegendItem(
                label: 'Sans objet (S.O.)',
                count: data.naPointsCount,
                percentage: naRate,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required double percentage,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$count (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.darkBlue,
          ),
        ),
      ],
    );
  }
}
