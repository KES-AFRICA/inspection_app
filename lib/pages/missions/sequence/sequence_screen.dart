// lib/pages/missions/sequence/sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/pages/missions/sequence/steps/general_info_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/jsa_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/documents_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/description_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/audit_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/schema_step.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/sequence/steps/summary_screen.dart';

class SequenceScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;

  const SequenceScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends State<SequenceScreen> {
  late int _currentStep;
  late List<Map<String, dynamic>> _steps;
  late PageController _pageController;
  bool _isLoading = true;
  final Map<String, bool> _stepValidation = {};

  // Clé pour accéder à l'état de GeneralInfoStep
  final GlobalKey<GeneralInfoStepState> _generalInfoKey = GlobalKey<GeneralInfoStepState>();
  Widget? _cachedDescriptionWidget;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _loadProgress();
    _ensureStatusIsEnCours();
  }

  /// S'assure que le statut de la mission est bien "en_cours"
  Future<void> _ensureStatusIsEnCours() async {
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null && mission.isEnAttente) {
      await HiveService.updateMissionStatus(
        missionId: widget.mission.id,
        newStatus: 'en_cours',
      );
      widget.mission.status = 'en_cours';
    }
  }

  void _initializeSteps() {
    _steps = [
      {
        'title': 'JSA',
        'widget': JsaStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('jsa', data),
          onNextStep: _goToNextStep, // ← Pour aller vers Renseignements
        ),
      },
      {
        'title': 'Renseignements généraux',
        'widget': GeneralInfoStep(
          key: _generalInfoKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('general_info', data),
          onValidationChanged: (isValid) {
            setState(() {
              _stepValidation['general_info'] = isValid;
            });
          },
        ),
      },
      {
        'title': 'Documents nécessaires',
        'widget': DocumentsStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('documents', data),
        ),
      },
      {
        'title': 'Description des installations',
        'widget': DescriptionStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('description', data),
          onPreviousStep: _goToPreviousStep,  // Revenir à Documents
          onNextStep: _goToNextStep,
        ),
      },
      {
        'title': 'Audit des installations',
        'widget': AuditStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('audit', data),
        ),
      },
      {
        'title': 'Schéma des installations',
        'widget': SchemaStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('schema', data),
          onComplete: _onSequenceComplete,
        ),
      },
    ];
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    
    final progress = await SequenceProgressService.getProgress(widget.mission.id);
    var savedStep = progress['currentStep'] ?? 0;
    
    if (savedStep >= _steps.length) {
      savedStep = _steps.length - 1;
      await SequenceProgressService.saveCurrentStep(widget.mission.id, savedStep);
    }
    
    _currentStep = savedStep;
    _pageController = PageController(initialPage: _currentStep);
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveStepData(String stepKey, dynamic data) async {
    await SequenceProgressService.saveStepData(widget.mission.id, stepKey, data);
  }

  // NOUVEAU : Méthode pour fermer le clavier avant toute transition
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _goToNextStep() async {
    // Fermer le clavier immédiatement
    _dismissKeyboard();
    
    if (_currentStep == 1) {
      // Déclencher la validation visuelle
      _generalInfoKey.currentState?.triggerValidation();
      
      // Vérifier si le formulaire est valide
      final isValid = _generalInfoKey.currentState?.isFormValid ?? false;
      
      if (!isValid) {
        // Attendre un peu que l'UI se mette à jour
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez remplir tous les champs obligatoires (marqués en rouge)'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    if (_currentStep < _steps.length - 1) {
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
      await SequenceProgressService.markStepCompleted(widget.mission.id, _currentStep);
      
      setState(() {
        _currentStep++;
      });
      
      // Animation de transition
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    }
  }

  Future<void> _goToPreviousStep() async {
    // Fermer le clavier immédiatement
    _dismissKeyboard();
    
    if (_currentStep > 0) {
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
      
      setState(() {
        _currentStep--;
      });
      
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    }
  }

  void _onSequenceComplete() async {
    _dismissKeyboard();
    
    await SequenceProgressService.markStepCompleted(widget.mission.id, _steps.length - 1);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryScreen(
            mission: widget.mission,
            user: widget.user,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentStep >= _steps.length) {
      _currentStep = _steps.length - 1;
    }

    final currentStepTitle = _steps[_currentStep]['title'] as String;
    final totalSteps = _steps.length;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            currentStepTitle,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _dismissKeyboard();
              _showExitDialog();
            },
          ),
        ),
        body: Column(
          children: [
            // Barre de progression
            LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.3),
              color: Colors.white,
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _steps.map((step) => step['widget'] as Widget).toList(),
              ),
            ),
            // Navigation buttons
            if (_currentStep != 0 && _currentStep != 3)
            Container(
              padding: const EdgeInsets.all(16),
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
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goToPreviousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 18),
                            SizedBox(width: 8),
                            Text('Précédent'),
                          ],
                        ),
                      ),
                    ),
                  if (_currentStep > 0 && _currentStep < _steps.length - 1)
                    const SizedBox(width: 12),
                  if (_currentStep < _steps.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goToNextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Suivant'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la mission'),
        content: const Text('Votre progression sera sauvegardée. Vous pourrez reprendre plus tard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}