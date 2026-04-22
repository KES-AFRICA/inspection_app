// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/arret_urgence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ArretUrgenceScreen extends StatefulWidget {
  final Mission mission;

  const ArretUrgenceScreen({super.key, required this.mission});

  @override
  State<ArretUrgenceScreen> createState() => _ArretUrgenceScreenState();
}

class _ArretUrgenceScreenState extends State<ArretUrgenceScreen> {
  String? _selectedValue;
  bool _isLoading = true;
  bool _isSaving = false;

  // ✅ 3 options
  final List<String> _options = ['Satisfaisant', 'Non satisfaisant', 'Sans objet'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      
      if (mounted) {
        setState(() {
          _selectedValue = mesures.testArretUrgence.observation;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelection(String value) async {
    setState(() => _isSaving = true);
    
    try {
      final success = await HiveService.updateTestArretUrgence(
        missionId: widget.mission.id,
        observation: value,
      );
      
      if (success && mounted) {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test arrêt urgence'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message informatif
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: isSmallScreen ? 20 : 22),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                      child: Text(
                        'Sélectionnez le résultat du test de fonctionnement de l\'arrêt d\'urgence',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Titre
              Text(
                'Résultat du test',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              // Options
              ..._options.map((option) {
                final isSelected = _selectedValue == option;
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
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
              }).toList(),
              
              if (_isSaving)
                Padding(
                  padding: EdgeInsets.only(top: isSmallScreen ? 20 : 24),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}