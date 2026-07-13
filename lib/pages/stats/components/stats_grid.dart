import 'package:flutter/material.dart';
import 'package:inspec_app/pages/stats/widgets/stat_card_widget.dart';

class StatsGrid extends StatelessWidget {
  final int totalMissions;
  final int pendingMissions;
  final int inProgressMissions;
  final int completedMissions;

  const StatsGrid({
    super.key,
    required this.totalMissions,
    required this.pendingMissions,
    required this.inProgressMissions,
    required this.completedMissions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      childAspectRatio: 1.2,
      children: [
        StatCardWidget(
          title: 'Total Missions',
          value: totalMissions.toString(),
          icon: Icons.assignment_outlined,
          color: Colors.blue,
        ),
        StatCardWidget(
          title: 'En attente',
          value: pendingMissions.toString(),
          icon: Icons.hourglass_empty_outlined,
          color: Colors.orange,
        ),
        StatCardWidget(
          title: 'En cours',
          value: inProgressMissions.toString(),
          icon: Icons.play_circle_outline,
          color: Colors.blue,
        ),
        StatCardWidget(
          title: 'Terminées',
          value: completedMissions.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
      ],
    );
  }
}