// lib/pages/missions/sequence/steps/schema_step.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/mission/presentation/providers/mission_detail_provider.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

class SchemaStep extends ConsumerStatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const SchemaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  ConsumerState<SchemaStep> createState() => _SchemaStepState();
}

class _SchemaStepState extends ConsumerState<SchemaStep> {
  String? _selectedOption;
  bool _isFirstLoad = true;
  bool _hasAttemptedNext = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadFallbackOption() async {
    try {
      final savedData = await SequenceProgressService.getStepData(
        widget.mission.id, 
        'schema'
      );
      if (savedData != null && savedData is Map<String, dynamic>) {
        setState(() {
          _selectedOption = savedData['schema_option'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement fallback schema: $e');
      }
    }
  }

  Future<void> _saveData() async {
    if (_selectedOption == null) return;
    
    final data = {
      'schema_option': _selectedOption,
    };
    
    // Sauvegarder dans SequenceProgressService
    await SequenceProgressService.saveStepData(widget.mission.id, 'schema', data);
    widget.onDataChanged(data);
    
    // Sauvegarder dans la mission (persistant) via le notifier Riverpod
    final notifier = ref.read(missionDetailProvider(widget.mission.id).notifier);
    await notifier.updateSchemaOption(_selectedOption!);
    
    // Marquer l'étape comme complétée
    await SequenceProgressService.markStepCompleted(widget.mission.id, 5);
  }

  void _handleOptionSelected(String? value) {
    setState(() {
      _selectedOption = value;
    });
    _saveData();
  }

  bool get isFormValid => _selectedOption != null;
  String? get errorMessage => _hasAttemptedNext && !isFormValid ? 'Veuillez sélectionner Oui ou Non' : null;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(missionDetailProvider(widget.mission.id));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (mission) {
        if (_isFirstLoad) {
          _selectedOption = mission.schemaOption;
          if (_selectedOption == null) {
            _loadFallbackOption();
          }
          _isFirstLoad = false;
        }

        return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.timeline, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Schéma des installations électriques existantes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Un schéma des installations électriques existantes a-t-il été fourni ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Oui',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: 'oui',
                    groupValue: _selectedOption,
                    onChanged: _handleOptionSelected,
                    activeColor: Colors.green,
                    tileColor: _selectedOption == 'oui' 
                        ? Colors.green.withOpacity(0.1) 
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Divider(height: 0),
                  RadioListTile<String>(
                    title: const Text(
                      'Non',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: 'non',
                    groupValue: _selectedOption,
                    onChanged: _handleOptionSelected,
                    activeColor: Colors.red,
                    tileColor: _selectedOption == 'non' 
                        ? Colors.red.withOpacity(0.1) 
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
      },
    );
  }
}