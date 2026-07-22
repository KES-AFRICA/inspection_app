// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';

class RadioSequenceScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RadioSequenceScreen> createState() => _RadioSequenceScreenState();
}

class _RadioSequenceScreenState extends ConsumerState<RadioSequenceScreen> {
  // Choix unique (pour autres champs)
  String? _selectedValue;
  String? _tnDetail;

  // Choix multiple (pour régime de neutre)
  final Set<String> _selectedRegimes = {};

  bool _isFirstLoad = true;
  bool _isSaving = false;
  bool _showTnOptions = false;

  bool _showAutreField = false;
  final TextEditingController _autreController = TextEditingController();
  String? _autreSavedValue;

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  // ── SÉLECTION MULTIPLE RÉGIMES DE NEUTRE ────────────────────────────────
  void _toggleRegime(String regime) {
    setState(() {
      if (_selectedRegimes.contains(regime)) {
        _selectedRegimes.remove(regime);
        if (regime == 'Autre') {
          _showAutreField = false;
        }
      } else {
        _selectedRegimes.add(regime);
        if (regime == 'Autre') {
          _showAutreField = true;
        }
      }
    });

    _saveMultiRegimes();
  }

  Future<void> _saveMultiRegimes() async {
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(descriptionInstallationsProvider(widget.mission.id).notifier);

      List<String> listToSave = [];
      for (var r in ['TT', 'TN-C', 'TN-S', 'IT']) {
        if (_selectedRegimes.contains(r)) {
          listToSave.add(r);
        }
      }

      final customText = _autreController.text.trim();
      if (_selectedRegimes.contains('Autre') && customText.isNotEmpty) {
        listToSave.add(customText);
        _autreSavedValue = customText;
      }

      final resultString = listToSave.join(', ');
      final success = await notifier.updateDescriptionSelection('regime_neutre', resultString);

      if (success && !widget.isComplete && resultString.isNotEmpty) {
        widget.onComplete('regime_neutre');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultString.isEmpty
                ? 'Aucun régime sélectionné'
                : 'Enregistré : $resultString'),
            backgroundColor: resultString.isEmpty ? Colors.orange : Colors.green,
            duration: const Duration(milliseconds: 600),
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

  // ── SÉLECTION UNIQUE (AUTRES CHAMPS) ──────────────────────────────────
  Future<void> _saveSelection(String value) async {
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(descriptionInstallationsProvider(widget.mission.id).notifier);
      final success = await notifier.updateDescriptionSelection(widget.field, value);

      if (success && !widget.isComplete) {
        widget.onComplete(widget.field);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistré : $value'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 500),
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

  void _onValueChanged(String value) {
    setState(() {
      _selectedValue = value;
      _showTnOptions = (value == 'TN');
      _showAutreField = (value == 'Autre');
      if (value != 'TN') _tnDetail = null;
      if (value != 'Autre') _autreSavedValue = null;
    });
    if (value != 'Autre') {
      _saveSelection(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final asyncData = ref.watch(descriptionInstallationsProvider(widget.mission.id));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (desc) {
        if (_isFirstLoad) {
          if (widget.field == 'regime_neutre') {
            final value = desc.regimeNeutre;
            final detail = desc.regimeNeutreDetail;
            _selectedRegimes.clear();

            final standard = {'TT', 'TN-C', 'TN-S', 'IT'};
            if (value != null && value.isNotEmpty) {
              if (value == 'TN') {
                if (detail == 'C') _selectedRegimes.add('TN-C');
                else if (detail == 'S') _selectedRegimes.add('TN-S');
                else _selectedRegimes.add('TN-C');
              } else {
                final parts = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                List<String> autres = [];
                for (var part in parts) {
                  if (standard.contains(part)) {
                    _selectedRegimes.add(part);
                  } else if (part == 'TN') {
                    if (detail == 'C') _selectedRegimes.add('TN-C');
                    else if (detail == 'S') _selectedRegimes.add('TN-S');
                    else _selectedRegimes.add('TN-C');
                  } else {
                    autres.add(part);
                  }
                }
                if (autres.isNotEmpty) {
                  _selectedRegimes.add('Autre');
                  _showAutreField = true;
                  _autreController.text = autres.join(', ');
                  _autreSavedValue = autres.join(', ');
                }
              }
            }
          } else {
            String? value;
            switch (widget.field) {
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

            final standardOptions = widget.options;
            final isAutre = value != null && !standardOptions.contains(value) && value.isNotEmpty;

            if (isAutre) {
              _selectedValue = 'Autre';
              _showAutreField = true;
              _autreController.text = value;
              _autreSavedValue = value;
            } else {
              _selectedValue = value;
            }
          }
          _isFirstLoad = false;
        }

        // ── RENDU POUR RÉGIME DE NEUTRE (SELECTION MULTIPLE) ─────────────────
        if (widget.field == 'regime_neutre') {
          final regimeListOptions = [
            {
              'key': 'TT',
              'title': 'Régime TT',
              'desc': 'Neutre directement à la terre, masses à la terre',
              'color': const Color(0xFF2563EB),
            },
            {
              'key': 'TN-C',
              'title': 'Régime TN-C',
              'desc': 'Neutre et conducteur de protection confondus (PEN)',
              'color': const Color(0xFF0284C7),
            },
            {
              'key': 'TN-S',
              'title': 'Régime TN-S',
              'desc': 'Neutre et conducteur de protection séparés (N + PE)',
              'color': const Color(0xFF059669),
            },
            {
              'key': 'IT',
              'title': 'Régime IT',
              'desc': 'Neutre isolé ou impédant, masses reliées à la terre',
              'color': const Color(0xFFD97706),
            },
            {
              'key': 'Autre',
              'title': 'Autre régime / Spécifique',
              'desc': 'Préciser un autre schéma ou régime mixte',
              'color': const Color(0xFF7C3AED),
            },
          ];

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 10 : 16),

                // Note d'aide
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rtl_rounded, color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cochez un ou plusieurs régimes de neutre présents sur cette installation.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cartes à cocher
                ...regimeListOptions.map((opt) {
                  final key = opt['key'] as String;
                  final title = opt['title'] as String;
                  final description = opt['desc'] as String;
                  final color = opt['color'] as Color;
                  final isChecked = _selectedRegimes.contains(key);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isChecked ? color.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isChecked ? color : Colors.grey.shade300,
                        width: isChecked ? 2 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isChecked,
                      onChanged: _isSaving ? null : (_) => _toggleRegime(key),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isChecked ? FontWeight.w800 : FontWeight.w600,
                          color: isChecked ? color : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      activeColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }),

                // Saisie texte si "Autre" est coché
                if (_showAutreField) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Préciser le régime autre :',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _autreController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ex: TNC-S, TN-C / IT...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => _saveMultiRegimes(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Résumé enregistré
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          desc.regimeNeutre?.isNotEmpty == true
                              ? 'Régimes enregistrés : ${desc.regimeNeutre}'
                              : 'Aucun régime sélectionné',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ── RENDU PAR DÉFAUT (SELECTION UNIQUE POUR AUTRES CHAMPS) ───────────
        final displayOptions = widget.options;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 35 : 40),

              ...displayOptions.asMap().entries.map((entry) {
                final option = entry.value;
                final isSelected = _selectedValue == option;

                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Colors.white,
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
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              _onValueChanged(value);
                            }
                          },
                    activeColor: AppTheme.primaryBlue,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
