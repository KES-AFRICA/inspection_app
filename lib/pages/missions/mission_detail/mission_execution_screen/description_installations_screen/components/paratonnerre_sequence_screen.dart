// paratonnerre_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class ParatonnerreSequenceScreen extends StatefulWidget {
  final Mission mission;
  final void Function(String missionId) onComplete;
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

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    setState(() => _isLoading = true);

    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      setState(() {
        _presenceParatonnerre = desc.presenceParatonnerre;
        _analyseRisqueFoudre = desc.analyseRisqueFoudre;
        _etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_presenceParatonnerre == null) {
      _showErrorSnackBar('Veuillez sélectionner la présence de paratonnerre');
      return false;
    }
    
    if (_analyseRisqueFoudre == null) {
      _showErrorSnackBar('Veuillez sélectionner l\'analyse risque foudre');
      return false;
    }
    
    if (_etudeTechniqueFoudre == null) {
      _showErrorSnackBar('Veuillez sélectionner l\'étude technique foudre');
      return false;
    }
    
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveSelections() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success1 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'presence_paratonnerre',
        value: _presenceParatonnerre!,
      );

      final success2 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'analyse_risque_foudre',
        value: _analyseRisqueFoudre!,
      );

      final success3 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'etude_technique_foudre',
        value: _etudeTechniqueFoudre!,
      );

      if (success1 && success2 && success3 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sélections sauvegardées avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onComplete(widget.mission.id);
      } else {
        _showErrorSnackBar('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRadioGroup(String title, String? selectedValue, Function(String?) onChanged) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged('OUI'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selectedValue == 'OUI' 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.transparent,
                      side: BorderSide(
                        color: selectedValue == 'OUI' 
                            ? Colors.green 
                            : Colors.grey.shade300,
                        width: selectedValue == 'OUI' ? 2 : 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    ),
                    child: Text(
                      'OUI',
                      style: TextStyle(
                        color: selectedValue == 'OUI' ? Colors.green : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onChanged('NON'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selectedValue == 'NON' 
                          ? Colors.red.withOpacity(0.1) 
                          : Colors.transparent,
                      side: BorderSide(
                        color: selectedValue == 'NON' 
                            ? Colors.red 
                            : Colors.grey.shade300,
                        width: selectedValue == 'NON' ? 2 : 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    ),
                    child: Text(
                      'NON',
                      style: TextStyle(
                        color: selectedValue == 'NON' ? Colors.red : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de statut ALIGNÉ À GAUCHE
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // ALIGNÉ À GAUCHE
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isComplete 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: widget.isComplete 
                          ? Colors.green.withOpacity(0.4)
                          : Colors.orange.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isComplete ? Icons.check_circle : Icons.pending_outlined,
                        color: widget.isComplete ? Colors.green : Colors.orange,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 10),
                      Text(
                        widget.isComplete ? 'Section complétée' : 'En attente de saisie',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: widget.isComplete ? Colors.green.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options de sélection
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildRadioGroup(
                        'Présence de paratonnerre',
                        _presenceParatonnerre,
                        (value) => setState(() => _presenceParatonnerre = value),
                      ),
                      _buildRadioGroup(
                        'Analyse risque foudre',
                        _analyseRisqueFoudre,
                        (value) => setState(() => _analyseRisqueFoudre = value),
                      ),
                      _buildRadioGroup(
                        'Étude technique foudre',
                        _etudeTechniqueFoudre,
                        (value) => setState(() => _etudeTechniqueFoudre = value),
                      ),
                    ],
                  ),
          ),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelections,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: isSmallScreen ? 16 : 18),
                        SizedBox(width: 8),
                        Text(
                          'SAUVEGARDER',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}