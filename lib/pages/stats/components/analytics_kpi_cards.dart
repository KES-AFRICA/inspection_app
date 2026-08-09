// lib/pages/stats/components/analytics_kpi_cards.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class AnalyticsKpiCards extends StatelessWidget {
  final AnalyticsDashboardData data;
  final bool isDarkMode;

  const AnalyticsKpiCards({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section
        Row(
          children: [
            Icon(Icons.dashboard_customize_rounded, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Catégorie 1 — Vue Globale de la Mission',
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
        const SizedBox(height: 10),

        // Grille de cartes KPI avec ratio 1.35 donnant suffisamment de hauteur verticale
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'Zones & Locaux',
              value: '${data.totalZones} zones • ${data.totalLocaux} locaux',
              subtitle: 'MT: ${data.locauxMTCount} | BT: ${data.locauxBTCount} | GE: ${data.locauxGECount}',
              icon: Icons.domain_rounded,
              accentColor: const Color(0xFF2563EB),
              bgColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            ),
            _buildKpiCard(
              title: 'Équipements Électriques',
              value: '${data.totalEquipments} au total',
              subtitle: 'Cell: ${data.cellulesMTCount} | Transfo: ${data.transformateursCount} | TGBT: ${data.tgbtCount}',
              icon: Icons.electrical_services_rounded,
              accentColor: const Color(0xFF059669),
              bgColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
            ),
            _buildKpiCard(
              title: 'Points de Vérification',
              value: '${data.totalPointsEvaluated} contrôlés',
              subtitle: 'Conformes: ${data.compliantPointsCount} | NC: ${data.nonCompliantPointsCount} | SO: ${data.naPointsCount}',
              icon: Icons.fact_check_rounded,
              accentColor: const Color(0xFFD97706),
              bgColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
            ),
            _buildKpiCard(
              title: 'Missions Analysées',
              value: '${data.missions.length} mission(s)',
              subtitle: 'Terminées: ${data.progressStats.completedMissions} | En cours: ${data.progressStats.inProgressMissions}',
              icon: Icons.assignment_rounded,
              accentColor: const Color(0xFF7C3AED),
              bgColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3E8FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.3 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : AppTheme.darkBlue,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
