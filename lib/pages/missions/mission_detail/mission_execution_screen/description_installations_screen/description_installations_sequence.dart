// description_installations_sequence.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/description_installations_form.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/paratonnerre_sequence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class DescriptionInstallationsSequenceScreen extends StatefulWidget {
  final Mission mission;

  const DescriptionInstallationsSequenceScreen({super.key, required this.mission});

  @override
  State<DescriptionInstallationsSequenceScreen> createState() => _DescriptionInstallationsSequenceScreenState();
}

class _DescriptionInstallationsSequenceScreenState extends State<DescriptionInstallationsSequenceScreen> {
  int _currentStep = 0;
  Map<String, bool> _progress = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _sections = [
    {
      'key': 'alimentation_moyenne_tension',
      'title': 'Caractéristiques de l\'alimentation moyenne tension',
      'icon': Icons.bolt_outlined,
      'champs': ['TYPE DE CELLULE', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE', 'NATURE DU RESEAU', 'OBSERVATIONS'],
      'requiredFields': ['TYPE DE CELLULE', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE', 'NATURE DU RESEAU'],
      'isList': true,
    },
    {
      'key': 'alimentation_basse_tension',
      'title': 'Caractéristiques de l\'alimentation basse tension sortie transformateur',
      'icon': Icons.bolt_outlined,
      'champs': ['PUISSANCE TRANSFORMATEUR', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION', 'OBSERVATIONS'],
      'requiredFields': ['PUISSANCE TRANSFORMATEUR', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION'],
      'isList': true,
    },
    {
      'key': 'groupe_electrogene',
      'title': 'Caractéristiques du groupe électrogène',
      'icon': Icons.electrical_services_outlined,
      'champs': ['MARQUE', 'TYPE', 'SERIE', 'PUISSANCE (KVA)', 'INTENSITE', 'ANNEE DE FABRICATION', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'INTENSITE'],
      'isList': true,
    },
    {
      'key': 'alimentation_carburant',
      'title': 'Alimentation du groupe électrogène en carburant',
      'icon': Icons.local_gas_station_outlined,
      'champs': ['MODE', 'CAPACITE', 'CUVE DE RETENTION', 'INDICATEUR DE NIVEAU', 'MISE A LA TERRE', 'ANNEE DE FABRICATION'],
      'requiredFields': ['MODE', 'CAPACITE', 'CUVE DE RETENTION'],
      'isList': true,
    },
    {
      'key': 'inverseur',
      'title': 'Caractéristiques de l\'inverseur',
      'icon': Icons.swap_horiz_outlined,
      'champs': ['MARQUE', 'TYPE', 'SERIE', 'INTENSITE (A)', 'REGLAGES'],
      'requiredFields': ['MARQUE', 'TYPE', 'INTENSITE (A)'],
      'isList': true,
    },
    {
      'key': 'stabilisateur',
      'title': 'Caractéristiques du stabilisateur',
      'icon': Icons.tune_outlined,
      'champs': ['MARQUE', 'TYPE', 'SERIE', 'ANNEE DE FABRICATION', 'ANNEE D\'INSTALLATION', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'ENTREE', 'SORTIE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'ENTREE', 'SORTIE'],
      'isList': true,
    },
    {
      'key': 'onduleurs',
      'title': 'Caractéristiques des onduleurs',
      'icon': Icons.power_outlined,
      'champs': ['MARQUE', 'TYPE', 'SERIE', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'NOMBRE DE PHASE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'INTENSITE (A)'],
      'isList': true,
    },
    {
      'key': 'regime_neutre',
      'title': 'Régime de neutre',
      'icon': Icons.settings_input_component_outlined,
      'options': ['IT', 'TT', 'TN'],
      'isRadio': true,
    },
    {
      'key': 'eclairage_securite',
      'title': 'Eclairage de sécurité',
      'icon': Icons.emergency_outlined,
      'options': ['Présent', 'Non présent'],
      'isRadio': true,
    },
    {
      'key': 'modifications_installations',
      'title': 'Modifications apportées aux installations',
      'icon': Icons.construction_outlined,
      'options': ['Sans objet', 'Avec objet'],
      'isRadio': true,
    },
    {
      'key': 'note_calcul',
      'title': 'Note de calcul des installations électriques',
      'icon': Icons.calculate_outlined,
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
    {
      'key': 'registre_securite',
      'title': 'Registre de sécurité',
      'icon': Icons.security_outlined,
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
    {
      'key': 'paratonnerre',
      'title': 'Protection des installations contre la foudre',
      'icon': Icons.flash_on_outlined,
      'fields': ['presence_paratonnerre', 'analyse_risque_foudre', 'etude_technique_foudre'],
      'isParatonnerre': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

Future<void> _loadProgress() async {
  setState(() {
    _isLoading = true;
  });

  final progress = await HiveService.getMissionProgress(widget.mission.id);
  
  // DEBUG: Afficher la progression
  print('📊 Progression chargée: $progress');
  
  setState(() {
    _progress = progress;
    _isLoading = false;
    
    // Trouver la première étape incomplète
    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      final key = section['key'] as String;
      if (!_progress.containsKey(key) || !_progress[key]!) {
        _currentStep = i;
        print('🎯 Première étape incomplète: $key (étape $i)');
        break;
      }
    }
  });
}

void _nextStep() {
  if (_currentStep < _sections.length - 1) {
    setState(() {
      _currentStep++;
    });
    // Réinitialiser l'état des contrôleurs
    _resetFormState();
  }
}

 

void _previousStep() {
  if (_currentStep > 0) {
    setState(() {
      _currentStep--;
    });
    _resetFormState();
  }
}

void _goToStep(int step) {
  setState(() {
    _currentStep = step;
  });
  _resetFormState();
}

// Méthode pour s'assurer que les formulaires sont réinitialisés
void _resetFormState() {
  // Forcer le widget à se reconstruire complètement
  if (mounted) {
    setState(() {});
  }
}
void _onSectionComplete(String sectionKey) async {
  // ✅ Mise à jour IMMÉDIATE de l’état local
  setState(() {
    _progress[sectionKey] = true;
  });

 // recharger depuis Hive pour être sûr
  await _loadProgress();
}


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Description des Installations'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentSection = _sections[_currentStep];
    final isComplete = _progress[currentSection['key'] as String] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Description des Installations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentStep + 1}/${_sections.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Étapes',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          
          // Contenu de l'étape actuelle
          Expanded(
            child: _buildCurrentStep(currentSection, isComplete),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildProgressBar() {
    final completed = _progress.values.where((isComplete) => isComplete).length;
    final percentage = (completed / _sections.length * 100).round();

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression globale',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            color: AppTheme.primaryBlue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

Widget _buildCurrentStep(Map<String, dynamic> section, bool isComplete) {
  // TOUJOURS créer un nouveau widget avec une clé unique
  final uniqueKey = Key('${section['key']}_${DateTime.now().millisecondsSinceEpoch}');
  
  if (section['isList'] == true) {
    return DescriptionInstallationsForm(
      key: uniqueKey, // Clé unique pour forcer la reconstruction
      mission: widget.mission,
      title: section['title'],
      sectionKey: section['key'],
      champs: List<String>.from(section['champs']),
      requiredFields: List<String>.from(section['requiredFields']),
      onComplete: _onSectionComplete,
      isComplete: isComplete,
    );
  } else if (section['isRadio'] == true) {
    return RadioSequenceScreen(
      key: uniqueKey,
      mission: widget.mission,
      title: section['title'],
      field: section['key'],
      options: List<String>.from(section['options']),
      onComplete: _onSectionComplete,
      isComplete: isComplete,
    );
  } else if (section['isParatonnerre'] == true) {
    return ParatonnerreSequenceScreen(
      key: uniqueKey,
      mission: widget.mission,
      onComplete: _onSectionComplete,
      isComplete: isComplete,
    );
  }
  
  return Center(
    child: Text('Type de section non supporté'),
  );
}

Widget _buildBottomNavigation() {
  final isFirstStep = _currentStep == 0;
  final isLastStep = _currentStep == _sections.length - 1;
  final currentSection = _sections[_currentStep];
  final isCurrentComplete = _progress[currentSection['key'] as String] ?? false;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade300)),
    ),
    child: Row(
      children: [
        // Bouton Précédent
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.primaryBlue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text('PRÉCÉDENT'),
                ],
              ),
            ),
          ),
        
        if (!isFirstStep) SizedBox(width: 16),
        // Bouton Suivant/Compléter
        Expanded(
          child: ElevatedButton(
            onPressed: isCurrentComplete 
              ? () {
                  if (isLastStep) {
                    // Même effet que la flèche de retour de l'AppBar
                    Navigator.pop(context);
                  } else {
                    _nextStep();
                  }
                }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentComplete ? AppTheme.primaryBlue : Colors.grey.shade300,
              foregroundColor: isCurrentComplete ? Colors.white : Colors.grey.shade500,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isLastStep ? 'TERMINER' : 'SUIVANT'),
                if (!isLastStep) SizedBox(width: 8),
                if (!isLastStep) Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

}