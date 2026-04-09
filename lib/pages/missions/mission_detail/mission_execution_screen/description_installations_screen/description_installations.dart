import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_selection_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/installation_detail.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/paratonnerre_screen.dart';

class DescriptionInstallationsScreen extends StatelessWidget {
  final Mission mission;

  const DescriptionInstallationsScreen({
    super.key,
    required this.mission,
  });

  void _navigateToDetail(BuildContext context, String title, String sectionKey, List<String> champs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallationDetailScreen(
          mission: mission,
          title: title,
          sectionKey: sectionKey,
          champs: champs,
        ),
      ),
    );
  }

  void _navigateToRadioSelection(BuildContext context, String title, String field, List<String> options) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadioSelectionScreen(
          mission: mission,
          title: title,
          field: field,
          options: options,
        ),
      ),
    );
  }

  void _navigateToParatonnerre(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParatonnerreScreen(mission: mission),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildListTile(
            context,
            'Caractéristiques de l\'alimentation moyenne tension',
            Icons.bolt_outlined,
            'alimentation_moyenne_tension',
            ['TYPE DE CELLULE', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE', 'NATURE DU RESEAU', 'OBSERVATIONS'],
          ),
          
          _buildListTile(
            context,
            'Caractéristiques de l\'alimentation basse tension sortie transformateur',
            Icons.bolt_outlined,
            'alimentation_basse_tension',
            ['PUISSANCE TRANSFORMATEUR', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION', 'OBSERVATIONS'],
          ),
          
          _buildListTile(
            context,
            'Caractéristiques du groupe électrogène',
            Icons.electrical_services_outlined,
            'groupe_electrogene',
            ['MARQUE', 'TYPE', 'SERIE', 'PUISSANCE (KVA)', 'INTENSITE', 'ANNEE DE FABRICATION', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE'],
          ),
          
          _buildListTile(
            context,
            'Alimentation du groupe électrogène en carburant',
            Icons.local_gas_station_outlined,
            'alimentation_carburant',
            ['MODE', 'CAPACITE', 'CUVE DE RETENTION', 'INDICATEUR DE NIVEAU', 'MISE A LA TERRE', 'ANNEE DE FABRICATION'],
          ),
          
          _buildListTile(
            context,
            'Caractéristiques de l\'inverseur',
            Icons.swap_horiz_outlined,
            'inverseur',
            ['MARQUE', 'TYPE', 'SERIE', 'INTENSITE (A)', 'REGLAGES'],
          ),
          
          _buildListTile(
            context,
            'Caractéristiques du stabilisateur',
            Icons.tune_outlined,
            'stabilisateur',
            ['MARQUE', 'TYPE', 'SERIE', 'ANNEE DE FABRICATION', 'ANNEE D\'INSTALLATION', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'ENTREE', 'SORTIE'],
          ),
          
          _buildListTile(
            context,
            'Caractéristiques des onduleurs',
            Icons.power_outlined,
            'onduleurs',
            ['MARQUE', 'TYPE', 'SERIE', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'NOMBRE DE PHASE'],
          ),
          
          _buildRadioTile(
            context,
            'Régime de neutre',
            Icons.settings_input_component_outlined,
            'regime_neutre',
            ['IT', 'TT', 'TN'],
          ),
          
          _buildRadioTile(
            context,
            'Eclairage de sécurité',
            Icons.emergency_outlined,
            'eclairage_securite',
            ['Présent', 'Non présent'],
          ),
          
          _buildRadioTile(
            context,
            'Modifications apportées aux installations',
            Icons.construction_outlined,
            'modifications_installations',
            ['Sans objet', 'Avec objet'],
          ),
          
          _buildRadioTile(
            context,
            'Note de calcul des installations électriques',
            Icons.calculate_outlined,
            'note_calcul',
            ['Non transmis', 'Transmis'],
          ),
          
          _buildSimpleTile(
            context,
            'Présence de paratonnerre',
            Icons.flash_on_outlined,
            _navigateToParatonnerre,
          ),
          
          _buildRadioTile(
            context,
            'Registre de sécurité',
            Icons.security_outlined,
            'registre_securite',
            ['Non transmis', 'Transmis'],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon, String sectionKey, List<String> champs) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
          onTap: () => _navigateToDetail(context, title, sectionKey, champs),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildRadioTile(BuildContext context, String title, IconData icon, String field, List<String> options) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
          onTap: () => _navigateToRadioSelection(context, title, field, options),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _buildSimpleTile(BuildContext context, String title, IconData icon, Function onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
          onTap: () => onTap(context),
        ),
        Container(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}