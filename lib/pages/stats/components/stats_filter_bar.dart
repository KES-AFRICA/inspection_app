// lib/pages/stats/components/stats_filter_bar.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';

class StatsFilterBar extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final String? selectedMissionId; // null = Toutes les missions
  final String selectedTension; // 'Tous', 'MT', 'BT'
  final List<Mission> availableMissions;
  final ValueChanged<String> onPeriodSelected;
  final ValueChanged<String?> onMissionSelected;
  final ValueChanged<String> onTensionSelected;
  final VoidCallback onResetPeriod;
  final bool isDarkMode;

  const StatsFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.selectedMissionId,
    required this.selectedTension,
    required this.availableMissions,
    required this.onPeriodSelected,
    required this.onMissionSelected,
    required this.onTensionSelected,
    required this.onResetPeriod,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne 1 : Période & Domaine de Tension
          Row(
            children: [
              // Chip Période
              InkWell(
                onTap: () => _showPeriodPicker(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Chips MT / BT / Tous
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTensionChip('Tous'),
                      const SizedBox(width: 6),
                      _buildTensionChip('MT'),
                      const SizedBox(width: 6),
                      _buildTensionChip('BT'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Ligne 2 : Sélecteur de Mission spécifique
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedMissionId,
                isExpanded: true,
                dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDarkMode ? Colors.white70 : Colors.black54),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Toutes les missions (${availableMissions.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  ...availableMissions.map((m) {
                    return DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(
                        '${m.nomClient} • ${m.nomSite ?? 'Site unifié'} (${_formatShortDate(m.createdAt)})',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDarkMode ? Colors.grey.shade200 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: onMissionSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTensionChip(String label) {
    final isSelected = selectedTension == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTensionSelected(label),
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showPeriodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_rounded, color: AppTheme.primaryBlue),
              title: const Text('Aujourd\'hui'),
              onTap: () {
                Navigator.pop(ctx);
                onPeriodSelected('today');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded, color: AppTheme.primaryBlue),
              title: const Text('Cette semaine'),
              onTap: () {
                Navigator.pop(ctx);
                onPeriodSelected('week');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month_rounded, color: AppTheme.primaryBlue),
              title: const Text('Ce mois'),
              onTap: () {
                Navigator.pop(ctx);
                onPeriodSelected('month');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: AppTheme.primaryBlue),
              title: const Text('Cette année'),
              onTap: () {
                Navigator.pop(ctx);
                onPeriodSelected('year');
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded, color: AppTheme.primaryBlue),
              title: const Text('Période personnalisée...'),
              onTap: () {
                Navigator.pop(ctx);
                onPeriodSelected('custom');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
