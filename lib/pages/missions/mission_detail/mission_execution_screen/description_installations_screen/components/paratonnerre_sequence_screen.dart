// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/paratonnerre_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ParatonnerreSequenceScreen extends StatefulWidget {
  final Mission mission;
  final Function(String) onComplete;
  final bool isComplete;

  const ParatonnerreSequenceScreen({
    super.key,
    required this.mission,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<ParatonnerreSequenceScreen> createState() => _ParatonnerreSequenceScreenState();
}

class _ParatonnerreSequenceScreenState extends State<ParatonnerreSequenceScreen> {
  String? _presenceParatonnerre;
  String? _analyseRisqueFoudre;
  String? _etudeTechniqueFoudre;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _options = ['Oui', 'Non'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      if (mounted) {
        setState(() {
          _presenceParatonnerre = desc.presenceParatonnerre;
          _analyseRisqueFoudre = desc.analyseRisqueFoudre;
          _etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ✅ SAUVEGARDE INSTANTANÉE
  Future<void> _saveField(String field, String value) async {
    setState(() => _isSaving = true);
    
    try {
      final success = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: field,
        value: value,
      );
      
      // Vérifier si la section est complète
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      final isParatonnerreComplete = desc.presenceParatonnerre != null &&
          desc.analyseRisqueFoudre != null &&
          desc.etudeTechniqueFoudre != null;
      
      if (isParatonnerreComplete && !widget.isComplete) {
        widget.onComplete('paratonnerre');
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          // Message informatif
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: isSmallScreen ? 16 : 18),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: Text(
                    'Tous les champs sont sauvegardés automatiquement',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          
          // Présence paratonnerre
          _buildRadioSection(
            title: 'Présence de paratonnerre',
            value: _presenceParatonnerre,
            onChanged: (value) {
              setState(() => _presenceParatonnerre = value);
              _saveField('presence_paratonnerre', value);
            },
            isSmallScreen: isSmallScreen,
          ),
          
          const SizedBox(height: 16),
          
          // Analyse risque foudre
          _buildRadioSection(
            title: 'Analyse risque foudre',
            value: _analyseRisqueFoudre,
            onChanged: (value) {
              setState(() => _analyseRisqueFoudre = value);
              _saveField('analyse_risque_foudre', value);
            },
            isSmallScreen: isSmallScreen,
          ),
          
          const SizedBox(height: 16),
          
          // Étude technique foudre
          _buildRadioSection(
            title: 'Étude technique foudre',
            value: _etudeTechniqueFoudre,
            onChanged: (value) {
              setState(() => _etudeTechniqueFoudre = value);
              _saveField('etude_technique_foudre', value);
            },
            isSmallScreen: isSmallScreen,
          ),
          
          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 16 : 20),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRadioSection({
    required String title,
    required String? value,
    required Function(String) onChanged,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
          const Divider(height: 0),
          ..._options.map((option) {
            final isSelected = value == option;
            return RadioListTile<String>(
              title: Text(
                option,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                ),
              ),
              value: option,
              groupValue: value,
              onChanged: _isSaving ? null : (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppTheme.primaryBlue,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }
}