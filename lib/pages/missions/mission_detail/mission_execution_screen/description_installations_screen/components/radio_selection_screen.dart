import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_description_selection_use_case.dart';

class RadioSelectionScreen extends StatefulWidget {
  final Mission mission;
  final String title;
  final String field;
  final List<String> options;

  const RadioSelectionScreen({
    super.key,
    required this.mission,
    required this.title,
    required this.field,
    required this.options,
  });

  @override
  State<RadioSelectionScreen> createState() => _RadioSelectionScreenState();
}

class _RadioSelectionScreenState extends State<RadioSelectionScreen> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  void _loadCurrentSelection() async {
    final getDescUseCase = GetIt.instance<GetDescriptionInstallationsUseCase>();
    final desc = await getDescUseCase(widget.mission.id);
    
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
    });
  }

  void _sauvegarder() async {
    if (_selectedOption != null) {
      final updateSelectionUseCase = GetIt.instance<UpdateDescriptionSelectionUseCase>();
      final success = await updateSelectionUseCase(
        missionId: widget.mission.id,
        field: widget.field,
        value: _selectedOption!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Option sauvegardée: $_selectedOption')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sélectionnez une option:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ...widget.options.map((option) {
            return Column(
              children: [
                RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
                Container(height: 1, color: Colors.grey.shade300),
              ],
            );
          }).toList(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _selectedOption != null ? _sauvegarder : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'SAUVEGARDER',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}