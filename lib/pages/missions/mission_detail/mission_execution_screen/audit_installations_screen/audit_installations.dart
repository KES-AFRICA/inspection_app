import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/foudre_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/moyenne_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/mesures_essais_screen.dart';

class AuditInstallationsScreen extends StatefulWidget {
  final Mission mission;

  const AuditInstallationsScreen({super.key, required this.mission});

  @override
  State<AuditInstallationsScreen> createState() => _AuditInstallationsScreenState();
}

class _AuditInstallationsScreenState extends State<AuditInstallationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      MissionStatisticsCollector.getInventory(widget.mission.id);
    });
  }

  void _navigateToMoyenneTension(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoyenneTensionScreen(mission: widget.mission),
      ),
    );
  }

  void _navigateToBasseTension(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasseTensionScreen(mission: widget.mission),
      ),
    );
  }

  void _navigateToFoudre(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoudreScreen(mission: widget.mission),
      ),
    );
  }

  void _navigateToMesuresEssais(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesuresEssaisScreen(mission: widget.mission),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Section MOYENNE TENSION
            _buildSectionTile(
              context,
              'MOYENNE TENSION',
              Icons.bolt_outlined,
              'Audit des installations moyenne tension',
              _navigateToMoyenneTension,
              color: AppTheme.primaryBlue,
            ),
            
            Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
            
            // Section BASSE TENSION
            _buildSectionTile(
              context,
              'BASSE TENSION',
              Icons.power_outlined,
              'Audit des installations basse tension',
              _navigateToBasseTension,
              color: AppTheme.primaryBlue,
            ),
            
            Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
            
            // Section OBSERVATIONS FOUDRE
            _buildSectionTile(
              context,
              'OBSERVATIONS FOUDRE',
              Icons.warning_amber_outlined,
              'Observations et niveau de priorité',
              _navigateToFoudre,
              color: AppTheme.primaryBlue,
            ),

            Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),

            // Section MESURES ET ESSAIS
            _buildSectionTile(
              context,
              'MESURES ET ESSAIS',
              Icons.speed_outlined,
              'Prises de terre, isolement, continuité',
              _navigateToMesuresEssais,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Function(BuildContext) onTap, {
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => onTap(context),
    );
  }
}