import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/arret_urgence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/avis_mesures_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/conditions_mesure_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/continuite_resistance_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/demarrage_auto_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/prises_terre_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class MesuresEssaisScreen extends StatefulWidget {
  final Mission mission;

  const MesuresEssaisScreen({super.key, required this.mission});

  @override
  State<MesuresEssaisScreen> createState() => _MesuresEssaisScreenState();
}

class _MesuresEssaisScreenState extends State<MesuresEssaisScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, bool> _sectionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _stats = mesures.calculerStatistiques();
      
      // Vérifier l'état de chaque section
      _sectionStatus = {
        'conditions_mesure': _stats['condition_mesure_renseignee'] ?? false,
        'demarrage_auto': _stats['demarrage_auto_renseigne'] ?? false,
        'arret_urgence': _stats['arret_urgence_renseigne'] ?? false,
        'prises_terre': (mesures.prisesTerre.isNotEmpty),
        'avis_mesures': _stats['avis_mesures_renseigne'] ?? false,
        'essais_declenchement': (mesures.essaisDeclenchement.isNotEmpty),
        'continuite_resistance': (mesures.continuiteResistances.isNotEmpty),
      };
    } catch (e) {
      print('❌ Erreur chargement mesures et essais: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isSectionComplete(String sectionKey) {
    return _sectionStatus[sectionKey] ?? false;
  }

  Widget _buildSectionTile(String title, IconData icon, String subtitle, Function onTap, String sectionKey) {
    final isComplete = _isSectionComplete(sectionKey);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: (isComplete ? Colors.green : AppTheme.primaryBlue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isComplete ? Colors.green : AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isComplete ? Colors.green.shade800 : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isComplete ? Colors.green.shade600 : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isComplete)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: isComplete ? Colors.green.shade400 : Colors.grey.shade500),
          ],
        ),
        onTap: () => onTap(),
      ),
    );
  }

  void _navigateToConditionsMesure() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConditionsMesureScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToDemarrageAuto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemarrageAutoScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToArretUrgence() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArretUrgenceScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToPrisesTerre() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrisesTerreScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToAvisMesures() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvisMesuresScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToEssaisDeclenchement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EssaisDeclenchementScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToContinuiteResistance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinuiteResistanceScreen(mission: widget.mission),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mesures et Essais'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSectionTile(
                      'Conditions de mesure',
                      Icons.thermostat_outlined,
                      'Paramètres environnementaux de mesure',
                      _navigateToConditionsMesure,
                      'conditions_mesure',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Essais démarrage auto',
                      Icons.power_settings_new_outlined,
                      'Groupe électrogène - démarrage automatique',
                      _navigateToDemarrageAuto,
                      'demarrage_auto',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Test arrêt urgence',
                      Icons.emergency_outlined,
                      'Fonctionnement arrêt d\'urgence',
                      _navigateToArretUrgence,
                      'arret_urgence',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Prises de terre',
                      Icons.bolt_outlined,
                      'Mesures des prises de terre',
                      _navigateToPrisesTerre,
                      'prises_terre',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Avis sur les mesures',
                      Icons.assessment_outlined,
                      'Analyse et recommandations',
                      _navigateToAvisMesures,
                      'avis_mesures',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Essais déclenchement',
                      Icons.flash_on_outlined,
                      'Dispositifs différentiels',
                      _navigateToEssaisDeclenchement,
                      'essais_declenchement',
                    ),
                    const Divider(height: 0, thickness: 0.5),
                    
                    _buildSectionTile(
                      'Continuité et résistance',
                      Icons.cable_outlined,
                      'Conducteurs de protection',
                      _navigateToContinuiteResistance,
                      'continuite_resistance',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}