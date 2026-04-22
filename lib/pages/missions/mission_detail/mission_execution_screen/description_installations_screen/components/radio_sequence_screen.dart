// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class RadioSequenceScreen extends StatefulWidget {
  final Mission mission;
  final String title;
  final String field;
  final List<String> options;
  final Function(String) onComplete;
  final bool isComplete;

  const RadioSequenceScreen({
    super.key,
    required this.mission,
    required this.title,
    required this.field,
    required this.options,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<RadioSequenceScreen> createState() => _RadioSequenceScreenState();
}

class _RadioSequenceScreenState extends State<RadioSequenceScreen> {
  String? _selectedValue;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      String? value;
      
      switch (widget.field) {
        case 'regime_neutre':
          value = desc.regimeNeutre;
          break;
        case 'eclairage_securite':
          value = desc.eclairageSecurite;
          break;
        case 'modifications_installations':
          value = desc.modificationsInstallations;
          break;
        case 'note_calcul':
          value = desc.noteCalcul;
          break;
        case 'registre_securite':
          value = desc.registreSecurite;
          break;
      }
      
      if (mounted) {
        setState(() {
          _selectedValue = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ✅ SAUVEGARDE INSTANTANÉE
  Future<void> _saveSelection(String value) async {
    setState(() => _isSaving = true);
    
    try {
      final success = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: widget.field,
        value: value,
      );
      
      if (success && !widget.isComplete) {
        widget.onComplete(widget.field);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistré : $value'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayOptions = widget.options;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 35 : 40),
          // Options
          ...displayOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedValue == option;
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                  ),
                ),
                value: option,
                groupValue: _selectedValue,
                onChanged: _isSaving ? null : (value) {
                  if (value != null) {
                    setState(() => _selectedValue = value);
                    _saveSelection(value);
                  }
                },
                activeColor: AppTheme.primaryBlue,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }),
          
          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 16 : 20),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}