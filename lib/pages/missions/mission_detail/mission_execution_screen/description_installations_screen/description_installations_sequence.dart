// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/description_installations_sequence.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/description_installations_form.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/paratonnerre_sequence_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class DescriptionInstallationsSequenceScreen extends StatefulWidget {
  final Mission mission;
  final VoidCallback onPreviousStep;
  final VoidCallback onNextStep;

  const DescriptionInstallationsSequenceScreen({
    super.key,
    required this.mission,
    required this.onPreviousStep,
    required this.onNextStep,
  });

  @override
  State<DescriptionInstallationsSequenceScreen> createState() => _DescriptionInstallationsSequenceScreenState();
}

class _DescriptionInstallationsSequenceScreenState extends State<DescriptionInstallationsSequenceScreen> {
  int _currentStep = 0;
  Map<String, bool> _progress = {};
  bool _isLoading = true;
  bool _isFirstLoad = true;
  
  late final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _sections = [
    {
      'key': 'alimentation_moyenne_tension',
      'title': 'Caractéristiques de l\'alimentation moyenne tension',
      'shortTitle': 'Alimentation MT',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFFE67E22),
      'champs': ['TYPE DE CELLULE', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE', 'NATURE DU RESEAU', 'OBSERVATIONS'],
      'requiredFields': ['TYPE DE CELLULE', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE', 'NATURE DU RESEAU'],
      'isList': true,
    },
    {
      'key': 'alimentation_basse_tension',
      'title': 'Caractéristiques de l\'alimentation basse tension sortie transformateur',
      'shortTitle': 'Alimentation BT',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFF2980B9),
      'champs': ['PUISSANCE TRANSFORMATEUR', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION', 'OBSERVATIONS'],
      'requiredFields': ['PUISSANCE TRANSFORMATEUR', 'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'SECTION DU CABLE', 'TENSION'],
      'isList': true,
    },
    {
      'key': 'groupe_electrogene',
      'title': 'Caractéristiques du groupe électrogène',
      'shortTitle': 'Groupe électrogène',
      'icon': Icons.electrical_services_outlined,
      'color': const Color(0xFF27AE60),
      'champs': ['MARQUE', 'TYPE', 'N° SERIE', 'PUISSANCE (KVA)', 'INTENSITE', 'ANNEE DE FABRICATION', 'CALIBRE DU DISJONCTEUR', 'SECTION DU CABLE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'INTENSITE'],
      'isList': true,
    },
    {
      'key': 'alimentation_carburant',
      'title': 'Alimentation du groupe électrogène en carburant',
      'shortTitle': 'Alim. carburant',
      'icon': Icons.local_gas_station_outlined,
      'color': const Color(0xFF8E44AD),
      'champs': ['MODE', 'CAPACITE', 'CUVE DE RETENTION', 'INDICATEUR DE NIVEAU', 'MISE A LA TERRE', 'ANNEE DE FABRICATION'],
      'requiredFields': ['MODE', 'CAPACITE', 'CUVE DE RETENTION'],
      'isList': true,
    },
    {
      'key': 'inverseur',
      'title': 'Caractéristiques de l\'inverseur',
      'shortTitle': 'Inverseur',
      'icon': Icons.swap_horiz_outlined,
      'color': const Color(0xFFC0392B),
      'champs': ['MARQUE', 'TYPE', 'N° SERIE', 'INTENSITE (A)', 'REGLAGES'],
      'requiredFields': ['MARQUE', 'TYPE', 'INTENSITE (A)'],
      'isList': true,
    },
    {
      'key': 'stabilisateur',
      'title': 'Caractéristiques du stabilisateur',
      'shortTitle': 'Stabilisateur',
      'icon': Icons.tune_outlined,
      'color': const Color(0xFFD35400),
      'champs': ['MARQUE', 'TYPE', 'N° SERIE', 'ANNEE DE FABRICATION', 'ANNEE D\'INSTALLATION', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'ENTREE', 'SORTIE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'ENTREE', 'SORTIE'],
      'isList': true,
    },
    {
      'key': 'onduleurs',
      'title': 'Caractéristiques des onduleurs',
      'shortTitle': 'Onduleurs',
      'icon': Icons.power_outlined,
      'color': const Color(0xFF16A085),
      'champs': ['MARQUE', 'TYPE', 'N° DE SERIE', 'PUISSANCE (KVA)', 'INTENSITE (A)', 'NOMBRE DE PHASE'],
      'requiredFields': ['MARQUE', 'TYPE', 'PUISSANCE (KVA)', 'INTENSITE (A)'],
      'isList': true,
    },
    {
      'key': 'regime_neutre',
      'title': 'Régime de neutre',
      'shortTitle': 'Régime neutre',
      'icon': Icons.settings_input_component_outlined,
      'color': const Color(0xFF7F8C8D),
      'options': ['IT', 'TT', 'TN'],
      'isRadio': true,
    },
    {
      'key': 'eclairage_securite',
      'title': 'Éclairage de sécurité',
      'shortTitle': 'Éclairage sécurité',
      'icon': Icons.emergency_outlined,
      'color': const Color(0xFFF39C12),
      'options': ['Présent', 'Non présent'],
      'isRadio': true,
    },
    {
      'key': 'modifications_installations',
      'title': 'Modifications apportées aux installations',
      'shortTitle': 'Modifications',
      'icon': Icons.construction_outlined,
      'color': const Color(0xFF2C3E50),
      'options': ['Oui', 'Non'],
      'isRadio': true,
    },
    {
      'key': 'note_calcul',
      'title': 'Note de calcul des installations électriques',
      'shortTitle': 'Note calcul',
      'icon': Icons.calculate_outlined,
      'color': const Color(0xFF3498DB),
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
    {
      'key': 'paratonnerre',
      'title': 'Présence de paratonnerre',
      'shortTitle': 'Paratonnerre',
      'icon': Icons.flash_on_outlined,
      'color': const Color(0xFFF1C40F),
      'fields': ['presence_paratonnerre', 'analyse_risque_foudre', 'etude_technique_foudre'],
      'isParatonnerre': true,
    },
    {
      'key': 'registre_securite',
      'title': 'Registre de sécurité',
      'shortTitle': 'Registre sécurité',
      'icon': Icons.security_outlined,
      'color': const Color(0xFFE74C3C),
      'options': ['Non transmis', 'Transmis'],
      'isRadio': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.hasClients) {
      final newPage = _pageController.page?.round() ?? 0;
      if (_currentStep != newPage) {
        setState(() {
          _currentStep = newPage;
        });
      }
    }

    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    try {
      final progress = await HiveService.getMissionProgress(widget.mission.id);
      
      if (!mounted) return;
      
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
      
      // UNIQUEMENT au premier chargement, trouver la première étape incomplète
      if (_isFirstLoad) {
        _isFirstLoad = false;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            int targetStep = 0;
            
            // Chercher la première étape incomplète
            for (int i = 0; i < _sections.length; i++) {
              final section = _sections[i];
              final key = section['key'] as String;
              if (!_progress.containsKey(key) || !_progress[key]!) {
                targetStep = i;
                break;
              }
            }
            
            // Si tout est complet, rester sur la première page
            _pageController.jumpToPage(targetStep);
            setState(() {
              _currentStep = targetStep;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    
    if (_currentStep < _sections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNextStep();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onPreviousStep();
    }
  }

  void _onSectionComplete(String sectionKey) async {
    // Mettre à jour immédiatement le statut local SANS recharger
    setState(() {
      _progress[sectionKey] = true;
    });
    
    try {
      final freshProgress = await HiveService.getMissionProgress(widget.mission.id);
      if (mounted) {
        setState(() {
          _progress = freshProgress;
        });
      }
    } catch (e) {
      // Ignorer les erreurs de rechargement
    }
  }

    @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentSection = _sections[_currentStep];
    final completed = _progress.values.where((v) => v).length;
    final percentage = (_sections.isNotEmpty) ? (completed / _sections.length * 100).round() : 0;
    final sectionColor = currentSection['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Carte d'en-tête moderne
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sectionColor, sectionColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              boxShadow: [
                BoxShadow(
                  color: sectionColor.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 8 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                        ),
                        child: Icon(
                          currentSection['icon'] as IconData,
                          color: Colors.white,
                          size: isSmallScreen ? 22 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSection['title'] as String,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Catégorie ${_currentStep + 1}/${_sections.length}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  
                  // Barre de progression
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 5 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _sections.isNotEmpty ? completed / _sections.length : 0,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: isSmallScreen ? 4 : 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu de la catégorie
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: _sections.map((section) {
                return _buildSectionWidget(section, _progress[section['key']] ?? false);
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSectionWidget(Map<String, dynamic> section, bool isComplete) {
    final stableKey = ValueKey('section_${section['key']}');
    
    if (section['isList'] == true) {
      return DescriptionInstallationsForm(
        key: stableKey,
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
        key: stableKey,
        mission: widget.mission,
        title: section['title'],
        field: section['key'],
        options: List<String>.from(section['options']),
        onComplete: _onSectionComplete,
        isComplete: isComplete,
      );
    } else if (section['isParatonnerre'] == true) {
      return ParatonnerreSequenceScreen(
        key: stableKey,
        mission: widget.mission,
        onComplete: _onSectionComplete,
        isComplete: isComplete,
      );
    }
    
    return const Center(child: Text('Type de section non supporté'));
  }

  Widget _buildBottomNavigation() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _sections.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(isFirstStep ? 'DOCUMENTS' : 'PRÉCÉDENT'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLastStep ? 'AUDIT' : 'SUIVANT'),
                  if (!isLastStep) const SizedBox(width: 8),
                  if (!isLastStep) const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}