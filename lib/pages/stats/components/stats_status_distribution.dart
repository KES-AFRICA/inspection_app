import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/stats/widgets/distribution_item_widget.dart';

class StatsStatusDistribution extends StatelessWidget {
  final int pendingMissions;
  final int inProgressMissions;
  final int completedMissions;
  final int totalMissions;

  const StatsStatusDistribution({
    super.key,
    required this.pendingMissions,
    required this.inProgressMissions,
    required this.completedMissions,
    required this.totalMissions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart_outline, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Répartition des missions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DistributionItemWidget(
            status: 'En attente',
            count: pendingMissions,
            total: totalMissions,
            color: Colors.orange,
          ),
          DistributionItemWidget(
            status: 'En cours',
            count: inProgressMissions,
            total: totalMissions,
            color: AppTheme.primaryBlue,
          ),
          DistributionItemWidget(
            status: 'Terminée',
            count: completedMissions,
            total: totalMissions,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}