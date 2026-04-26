// lib/pages/missions/sequence/steps/schema_step.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

class SchemaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const SchemaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<SchemaStep> createState() => _SchemaStepState();
}

class _SchemaStepState extends State<SchemaStep> {
  String? _selectedOption;
  bool _isLoading = true;
  bool _hasAttemptedNext = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    
    try {
      // ✅ Charger depuis la mission d'abord
      final mission = HiveService.getMissionById(widget.mission.id);
      if (mission != null && mission.schemaOption != null) {
        setState(() {
          _selectedOption = mission.schemaOption;
        });
      }
      
      // Sinon essayer depuis SequenceProgressService
      if (_selectedOption == null) {
        final savedData = await SequenceProgressService.getStepData(
          widget.mission.id, 
          'schema'
        );
        
        if (savedData != null && savedData is Map<String, dynamic>) {
          setState(() {
            _selectedOption = savedData['schema_option'];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement schema: $e');
      }
    } finally {
      setState(() => _isLoading = false);
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
    
    // Sauvegarder dans la mission (persistant)
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null) {
      mission.schemaOption = _selectedOption;
      mission.updatedAt = DateTime.now();
      await mission.save();
      if (kDebugMode) {
        print('✅ Schéma sauvegardé dans mission: $_selectedOption');
      }
    }
    
    //  Marquer l'étape comme complétée
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
  }
}