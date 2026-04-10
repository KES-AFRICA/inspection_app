// lib/pages/missions/sequence/sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _loadProgress();
  }

  void _initializeSteps() {
    _steps = [
      {
        'title': 'JSA',
        'widget': JsaStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('jsa', data),
        ),
      },
      {
        'title': 'Renseignements généraux de l\'életablissement',
        'widget': GeneralInfoStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('general_info', data),
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
    _currentStep = progress['currentStep'] ?? 0;
    _pageController = PageController(initialPage: _currentStep);
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveStepData(String stepKey, dynamic data) async {
    await SequenceProgressService.saveStepData(widget.mission.id, stepKey, data);
  }

  Future<void> _goToNextStep() async {
    if (_currentStep < _steps.length - 1) {
      // Sauvegarder l'étape actuelle
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
      await SequenceProgressService.markStepCompleted(widget.mission.id, _currentStep);
      
      setState(() {
        _currentStep++;
      });
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    }
  }

  Future<void> _goToPreviousStep() async {
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
  // Marquer la dernière étape comme complétée
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final currentStepTitle = _steps[_currentStep]['title'] as String;
    final totalSteps = _steps.length;
    final currentWidget = _steps[_currentStep]['widget'] as Widget;

    return Scaffold(
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
            _showExitDialog();
          },
        ),
      ),
      body: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: (_currentStep + 1) / totalSteps,
            backgroundColor: Colors.white.withOpacity(0.3),
            color: Colors.white,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Désactive le swipe
              children: _steps.map((step) => step['widget'] as Widget).toList(),
            ),
          ),
          // Navigation buttons
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
                if (_currentStep > 0) const SizedBox(width: 12),
                  if(_currentStep != _steps.length - 1)
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Suivant'),
                          const Icon(Icons.arrow_forward, size: 18),

                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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