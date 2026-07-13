import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';

class RecentMissionItemWidget extends StatelessWidget {
  final Mission mission;

  const RecentMissionItemWidget({
    super.key,
    required this.mission,
  });

  Color _getStatusColor(String status) {
    final normalized = _normalizeStatus(status);
    switch (normalized) {
      case 'En attente': return Colors.orange;
      case 'En cours': return AppTheme.primaryBlue;
      case 'Terminé': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) return 'En cours';
    if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) return 'Terminé';
    if (lowerStatus.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(mission.status);
    final normalized = _normalizeStatus(mission.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.nomClient,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: AppTheme.darkBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        normalized == 'Terminé' ? 'Terminée' : normalized,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 13, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(mission.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}