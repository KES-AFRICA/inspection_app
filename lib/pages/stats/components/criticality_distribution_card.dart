// lib/pages/stats/components/criticality_distribution_card.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class CriticalityDistributionCard extends StatelessWidget {
  final AnalyticsDashboardData data;
  final bool isDarkMode;

  const CriticalityDistributionCard({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final totalClassified = data.critiqueCount + data.majeureCount + data.mineureCount;

    final pctCritique = totalClassified > 0 ? (data.critiqueCount / totalClassified) * 100.0 : 0.0;
    final pctMajeure = totalClassified > 0 ? (data.majeureCount / totalClassified) * 100.0 : 0.0;
    final pctMineure = totalClassified > 0 ? (data.mineureCount / totalClassified) * 100.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.report_problem_rounded, size: 20, color: const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catégorie 3 — Répartition des Criticités',
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
              Text(
                '$totalClassified non-conformité(s)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade300 : AppTheme.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lignes de jauge par niveau de criticité
          _buildCriticalityRow(
            label: 'Critique (Urgent / Danger)',
            count: data.critiqueCount,
            percentage: pctCritique,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
          const SizedBox(height: 10),
          _buildCriticalityRow(
            label: 'Majeure (Prioritaire)',
            count: data.majeureCount,
            percentage: pctMajeure,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 10),
          _buildCriticalityRow(
            label: 'Mineure (À corriger)',
            count: data.mineureCount,
            percentage: pctMineure,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalityRow({
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required Color bgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 8,
            backgroundColor: isDarkMode ? const Color(0xFF0F172A) : bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
