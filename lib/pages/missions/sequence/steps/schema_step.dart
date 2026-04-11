// lib/pages/missions/sequence/steps/schema_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

class SchemaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onComplete;

  const SchemaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onComplete,
  });

  @override
  State<SchemaStep> createState() => _SchemaStepState();
}

class _SchemaStepState extends State<SchemaStep> {
  String? _selectedOption;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    
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
      print('❌ Erreur chargement schema: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    final data = {
      'schema_option': _selectedOption,
    };
    await SequenceProgressService.saveStepData(widget.mission.id, 'schema', data);
    widget.onDataChanged(data);
    print('✅ Schéma sauvegardé: $_selectedOption');
  }

  void _handleOptionSelected(String? value) {
    setState(() {
      _selectedOption = value;
    });
    _saveData(); // Sauvegarde immédiate
  }

  void _handleComplete() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner Oui ou Non'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Sauvegarder une dernière fois avant de passer à l'étape suivante
    _saveData();
    widget.onComplete();
  }

  bool get _isFormValid => _selectedOption != null;

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
            // En-tête
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
            
            // Question
            const Text(
              'Un schéma des installations électriques existantes a-t-il été fourni ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 16),
            
            // Options Oui/Non
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
            
            const SizedBox(height: 50),
            
            // Bouton Terminer
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid ? _handleComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isFormValid ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isFormValid) ...[
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'TERMINER ET VOIR LE RÉSUMÉ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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