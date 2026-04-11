import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_locaux_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/foudre_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/moyenne_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/mesures_essais_screen.dart'; // Nouvelle importation

class AuditInstallationsScreen extends StatelessWidget {
  final Mission mission;

  const AuditInstallationsScreen({super.key, required this.mission});

  void _navigateToMoyenneTension(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoyenneTensionScreen(mission: mission),
      ),
    );
  }

  void _navigateToBasseTension(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasseTensionScreen(mission: mission),
      ),
    );
  }

  void _navigateToClassementLocaux(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementLocauxScreen(mission: mission),
      ),
    );
  }

  void _navigateToFoudre(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoudreScreen(mission: mission),
      ),
    );
  }

  void _navigateToMesuresEssais(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesuresEssaisScreen(mission: mission),
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
      
            // Section CLASSEMENT DES LOCAUX
            _buildSectionTile(
              context,
              'CLASSEMENT DES LOCAUX',
              Icons.location_on_outlined,
              'Influences externes et indices de protection',
              _navigateToClassementLocaux,
              color: AppTheme.primaryBlue,
            ),
            
            Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
            
            // Section OBSERVATIONS FOUDRES
            _buildSectionTile(
              context,
              'OBSERVATIONS FOUDRE',
              Icons.warning_amber_outlined,
              'Observations et niveau de priorité',
              _navigateToFoudre,
              color: AppTheme.primaryBlue,
            ),
            
            Divider(height: 0, thickness: 0.5, color: Colors.grey.shade300),
            
            // NOUVELLE SECTION: MESURES ET ESSAIS
            _buildSectionTile(
              context,
              'MESURES ET ESSAIS',
              Icons.science_outlined,
              'Mesures électriques et essais fonctionnels',
              _navigateToMesuresEssais,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile(BuildContext context, String title, IconData icon, String subtitle, Function onTap, {required Color color}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minVerticalPadding: 0,
      dense: true,
      onTap: () => onTap(context),
    );
  }
}