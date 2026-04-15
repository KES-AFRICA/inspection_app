// lib/pages/missions/mission_detail/mission_execution_screen/mission_execution.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/audit_installations.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/description_installations_sequence.dart';

class MissionExecutionScreen extends StatelessWidget {
  final Mission mission;

  const MissionExecutionScreen({
    super.key,
    required this.mission,
  });

  void _navigateToDescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DescriptionInstallationsSequenceScreen(
          mission: mission,
          // Callbacks pour la navigation depuis cet écran
          onPreviousStep: () {
            // Retour à l'écran précédent (MissionExecutionScreen)
            Navigator.pop(context);
          },
          onNextStep: () {
            // Passer à l'écran d'audit
            Navigator.pop(context);
            _navigateToAudit(context);
          },
        ),
      ),
    );
  }

  void _navigateToAudit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuditInstallationsScreen(mission: mission),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mission.nomClient,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Section DESCRIPTION DES INSTALLATIONS
          _buildSectionTile(
            context,
            'DESCRIPTION DES INSTALLATIONS',
            Icons.description_outlined,
            _navigateToDescription,
          ),
          
          // Séparateur
          Container(height: 1, color: Colors.grey.shade300),
          
          // Section AUDIT DES INSTALLATIONS ELECTRIQUES
          _buildSectionTile(
            context,
            'AUDIT DES INSTALLATIONS ELECTRIQUES',
            Icons.engineering_outlined,
            _navigateToAudit,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, String title, IconData icon, Function(BuildContext) onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24, color: AppTheme.primaryBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => onTap(context),
    );
  }
}