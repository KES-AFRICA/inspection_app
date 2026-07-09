import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';

class RadioSelectionScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RadioSelectionScreen> createState() => _RadioSelectionScreenState();
}

class _RadioSelectionScreenState extends ConsumerState<RadioSelectionScreen> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  void _loadCurrentSelection() async {
    final desc = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).load();
    
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
      final success = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).updateDescriptionSelection(
        widget.field,
        _selectedOption!,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Option sauvegardée: $_selectedOption')),
        );
        Navigator.pop(context, true);
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