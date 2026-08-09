// lib/pages/stats/mission_analytics_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/stats/components/analytics_kpi_cards.dart';
import 'package:inspec_app/pages/stats/components/compliance_health_card.dart';
import 'package:inspec_app/pages/stats/components/criticality_distribution_card.dart';
import 'package:inspec_app/pages/stats/components/equipment_breakdown_table.dart';
import 'package:inspec_app/pages/stats/components/mission_team_traceability_card.dart';
import 'package:inspec_app/pages/stats/components/mt_bt_comparison_card.dart';
import 'package:inspec_app/pages/stats/components/photos_and_backup_card.dart';
import 'package:inspec_app/pages/stats/components/risk_analysis_card.dart';
import 'package:inspec_app/pages/stats/components/top_defects_card.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class MissionAnalyticsDetailScreen extends StatefulWidget {
  final Mission mission;

  const MissionAnalyticsDetailScreen({
    super.key,
    required this.mission,
  });

  @override
  State<MissionAnalyticsDetailScreen> createState() => _MissionAnalyticsDetailScreenState();
}

class _MissionAnalyticsDetailScreenState extends State<MissionAnalyticsDetailScreen> {
  String _selectedTension = 'Tous'; // 'Tous', 'MT', 'BT'

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mission = widget.mission;

    // Calculer le snapshot analytique certifié pour CETTE mission uniquement
    final analyticsData = AnalyticsEngine.computeDashboardData(
      [mission],
      tensionFilter: _selectedTension,
    );

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDarkMode ? Colors.white : AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        // Titre d'AppBar lisible, grand et correctement positionné
        title: Text(
          mission.nomClient,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : AppTheme.darkBlue,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [

          const SizedBox(height: 20),
          // 1. Bannière de Contexte de la Mission (Nom, Site, Adresse, Dates & Filtre MT/BT)
          _buildMissionContextBanner(mission, isDarkMode),

          const SizedBox(height: 16),

          // 2. Traçabilité des personnes ayant travaillé sur la mission (Placé tout en haut)
          MissionTeamTraceabilityCard(
            mission: mission,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 3. Catégorie 1 : Vue Synthétique Globale de la Mission
          AnalyticsKpiCards(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 4. Catégorie 2 : Santé de la Conformité & Jauge Tricolore
          ComplianceHealthCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 5. Catégorie 3 : Répartition des Criticités
          CriticalityDistributionCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 6. Catégorie 4 : Top 10 des Points de Vérification Problématiques
          TopDefectsCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 7. Catégorie 5 : Tableau d'Analyse des 10 Catégories d'Équipements
          EquipmentBreakdownTable(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 8. Catégorie 6 : Comparaisons MT vs BT
          MtBtComparisonCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 9. Catégories 7, 8, 9 : Installations à Risque & Références Normatives
          RiskAnalysisCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // 10. Catégories 10, 11, 12 : Photographies & Media
          PhotosAndBackupCard(
            data: analyticsData,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionContextBanner(Mission mission, bool isDarkMode) {
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
          // Ligne 1 : Nom Client + Sélecteur Domaine MT/BT
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.analytics_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Site de ${mission.nomSite ?? 'Site Unifié KES'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.natureMission ?? 'Inspection Périodique Standard',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Ligne 2 : Informations d'intervention, dernière modification et adresse
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildContextDetail(
                icon: Icons.calendar_today_rounded,
                label: 'Intervention',
                value: mission.dateIntervention != null
                    ? _formatDate(mission.dateIntervention!)
                    : _formatDate(mission.createdAt),
                isDarkMode: isDarkMode,
              ),
              _buildContextDetail(
                icon: Icons.history_rounded,
                label: 'Dernière modif.',
                value: _formatDate(mission.updatedAt),
                isDarkMode: isDarkMode,
              ),
              _buildContextDetail(
                icon: Icons.pin_drop_rounded,
                label: 'Localisation',
                value: mission.adresseClient?.isNotEmpty == true ? mission.adresseClient! : 'Non précisée',
                isDarkMode: isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Ligne 3 : Filtres Tension (Tous / MT / BT) intégrés dans la carte de contexte
          Row(
            children: [
              Text(
                'Filtre tension :',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade400 : AppTheme.darkBlue,
                ),
              ),
              const SizedBox(width: 8),
              _buildTensionChip('Tous', isDarkMode),
              const SizedBox(width: 6),
              _buildTensionChip('MT', isDarkMode),
              const SizedBox(width: 6),
              _buildTensionChip('BT', isDarkMode),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildTensionChip(String label, bool isDarkMode) {
    final isSelected = _selectedTension == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTension = label;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : (isDarkMode ? Colors.white10 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildContextDetail({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
