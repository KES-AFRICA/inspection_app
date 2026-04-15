// radio_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class RadioSequenceScreen extends StatefulWidget {
  final Mission mission;
  final String title;
  final String field;
  final List<String> options;
  final void Function(String field) onComplete;
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
  String? _selectedOption;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  Future<void> _loadCurrentSelection() async {
    setState(() => _isLoading = true);

    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      setState(() {
        switch (widget.field) {
          case 'regime_neutre':
            _selectedOption = desc.regimeNeutre;
            break;
          case 'eclairage_securite':
            _selectedOption = desc.eclairageSecurite;
            break;
          case 'modifications_installations':
            _selectedOption = desc.modificationsInstallations;
            break;
          case 'note_calcul':
            _selectedOption = desc.noteCalcul;
            break;
          case 'registre_securite':
            _selectedOption = desc.registreSecurite;
            break;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_selectedOption == null) {
      _showErrorSnackBar('Veuillez sélectionner une option');
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

  Future<void> _saveSelection() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: widget.field,
        value: _selectedOption!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Option sauvegardée avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onComplete(widget.field);
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
                : ListView.builder(
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedOption == option 
                                ? AppTheme.primaryBlue 
                                : Colors.grey.shade300,
                            width: _selectedOption == option ? 2 : 1,
                          ),
                        ),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20, 
                            vertical: isSmallScreen ? 12 : 16
                          ),
                          leading: Radio<String>(
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() => _selectedOption = value);
                            },
                            activeColor: AppTheme.primaryBlue,
                          ),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedOption = option);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSelection,
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