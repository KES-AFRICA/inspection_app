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
  // Choix unique
  String? _selectedOption;

  // Choix multiple (pour régime de neutre)
  final Set<String> _selectedRegimes = {};
  final TextEditingController _autreController = TextEditingController();
  bool _showAutreField = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  void _loadCurrentSelection() async {
    final desc = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).load();
    
    setState(() {
      if (widget.field == 'regime_neutre') {
        final val = desc.regimeNeutre;
        final detail = desc.regimeNeutreDetail;
        _selectedRegimes.clear();

        final standard = {'TT', 'TN-C', 'TN-S', 'IT'};
        if (val != null && val.isNotEmpty) {
          if (val == 'TN') {
            if (detail == 'C') _selectedRegimes.add('TN-C');
            else if (detail == 'S') _selectedRegimes.add('TN-S');
            else _selectedRegimes.add('TN-C');
          } else {
            final parts = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            List<String> autres = [];
            for (var part in parts) {
              if (standard.contains(part)) {
                _selectedRegimes.add(part);
              } else {
                autres.add(part);
              }
            }
            if (autres.isNotEmpty) {
              _selectedRegimes.add('Autre');
              _showAutreField = true;
              _autreController.text = autres.join(', ');
            }
          }
        }
      } else {
        switch (widget.field) {
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
      }
    });
  }

  void _sauvegarder() async {
    final notifier = ref.read(descriptionInstallationsProvider(widget.mission.id).notifier);

    if (widget.field == 'regime_neutre') {
      List<String> listToSave = [];
      for (var r in ['TT', 'TN-C', 'TN-S', 'IT']) {
        if (_selectedRegimes.contains(r)) {
          listToSave.add(r);
        }
      }
      final customText = _autreController.text.trim();
      if (_selectedRegimes.contains('Autre') && customText.isNotEmpty) {
        listToSave.add(customText);
      }

      final resultString = listToSave.join(', ');
      final success = await notifier.updateDescriptionSelection('regime_neutre', resultString);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultString.isEmpty
                  ? 'Régime de neutre réinitialisé'
                  : 'Régimes sauvegardés : $resultString'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } else {
      if (_selectedOption != null) {
        final success = await notifier.updateDescriptionSelection(
          widget.field,
          _selectedOption!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Option sauvegardée : $_selectedOption')),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.field == 'regime_neutre'
          ? _buildMultiSelectRegimeBody()
          : _buildSingleSelectBody(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _sauvegarder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'ENREGISTRER',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectRegimeBody() {
    final regimeOptions = [
      {'key': 'TT', 'title': 'Régime TT (Neutre à la terre, masses à la terre)'},
      {'key': 'TN-C', 'title': 'Régime TN-C (Neutre & protection confondus PEN)'},
      {'key': 'TN-S', 'title': 'Régime TN-S (Neutre & protection séparés N + PE)'},
      {'key': 'IT', 'title': 'Régime IT (Neutre isolé ou impédant, masses à la terre)'},
      {'key': 'Autre', 'title': 'Autre régime / Spécifique'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sélectionnez un ou plusieurs régimes de neutre (SLT) :',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...regimeOptions.map((opt) {
          final key = opt['key']!;
          final title = opt['title']!;
          final isChecked = _selectedRegimes.contains(key);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isChecked ? AppTheme.primaryBlue : Colors.grey.shade300,
                width: isChecked ? 2 : 1,
              ),
            ),
            color: isChecked ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Colors.white,
            child: CheckboxListTile(
              value: isChecked,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedRegimes.add(key);
                    if (key == 'Autre') _showAutreField = true;
                  } else {
                    _selectedRegimes.remove(key);
                    if (key == 'Autre') _showAutreField = false;
                  }
                });
              },
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                  color: isChecked ? AppTheme.primaryBlue : Colors.black87,
                ),
              ),
              activeColor: AppTheme.primaryBlue,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),

        if (_showAutreField) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _autreController,
            decoration: InputDecoration(
              labelText: 'Préciser l\'autre régime de neutre',
              hintText: 'Ex: TNC-S, TN-C / IT...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleSelectBody() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Sélectionnez une option :',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        ...widget.options.map((option) {
          final isSelected = _selectedOption == option;
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
              Container(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ],
    );
  }
}