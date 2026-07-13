import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class StatsAppBar extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final bool isCustomPeriod;
  final VoidCallback onResetPeriod;
  final Function(String) onPeriodSelected;

  const StatsAppBar({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.isCustomPeriod,
    required this.onResetPeriod,
    required this.onPeriodSelected,
  });

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = selectedPeriod == value;
    final themeColor = AppTheme.primaryBlue;

    return InkWell(
      onTap: () => onPeriodSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau récapitulatif
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.08),
                  AppTheme.lightBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.12), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCustomPeriod ? Icons.date_range : Icons.calendar_today,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période active',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCustomPeriod)
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.red.shade600),
                    onPressed: onResetPeriod,
                    tooltip: 'Réinitialiser',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Chips horizontaux de sélection de période
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPeriodChip('today', 'Aujourd\'hui'),
                const SizedBox(width: 8),
                _buildPeriodChip('week', 'Semaine'),
                const SizedBox(width: 8),
                _buildPeriodChip('month', 'Mois'),
                const SizedBox(width: 8),
                _buildPeriodChip('year', 'Année'),
                const SizedBox(width: 8),
                _buildPeriodChip('custom', 'Personnalisé'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}