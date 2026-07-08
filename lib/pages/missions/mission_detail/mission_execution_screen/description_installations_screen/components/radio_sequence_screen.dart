// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/radio_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_description_selection_use_case.dart';
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
  String? _tnDetail; // 'C' ou 'S' pour TN-C ou TN-S
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showTnOptions = false;

  bool _showAutreField = false;
  final TextEditingController _autreController = TextEditingController();
  String? _autreSavedValue;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final getDescUseCase =
          GetIt.instance<GetDescriptionInstallationsUseCase>();
      final desc = await getDescUseCase(widget.mission.id);
      String? value;
      String? detail;

      switch (widget.field) {
        case 'regime_neutre':
          value = desc.regimeNeutre;
          detail = desc.regimeNeutreDetail;
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
        // La logique "Autre" ne s'applique QU'AU slide regime_neutre
        final standardOptions = ['IT', 'TT', 'TN'];
        final isAutre =
            widget.field == 'regime_neutre' &&
            value != null &&
            !standardOptions.contains(value) &&
            value.isNotEmpty;
        setState(() {
          if (isAutre) {
            _selectedValue = 'Autre';
            _showAutreField = true;
            _autreController.text = value ?? '';
            _autreSavedValue = value;
          } else {
            _selectedValue = value;
          }
          _tnDetail = detail;
          _showTnOptions = (value == 'TN');
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
      final updateSelectionUseCase =
          GetIt.instance<UpdateDescriptionSelectionUseCase>();
      // Si c'est le régime de neutre, gérer le détail TN
      if (widget.field == 'regime_neutre') {
        // Sauvegarder la valeur principale
        final success = await updateSelectionUseCase(
          missionId: widget.mission.id,
          field: widget.field,
          value: value,
        );

        // Si la valeur est 'TN', on garde le détail existant
        // Sinon, on efface le détail
        if (value != 'TN' && _tnDetail != null) {
          await updateSelectionUseCase(
            missionId: widget.mission.id,
            field: 'regime_neutre_detail',
            value: '',
          );
          setState(() => _tnDetail = null);
        }

        if (success && !widget.isComplete) {
          widget.onComplete(widget.field);
        }
      } else {
        final success = await updateSelectionUseCase(
          missionId: widget.mission.id,
          field: widget.field,
          value: value,
        );

        if (success && !widget.isComplete) {
          widget.onComplete(widget.field);
        }
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

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  // ✅ Sauvegarde du détail TN
  Future<void> _saveTnDetail(String detail) async {
    setState(() => _isSaving = true);

    try {
      final updateSelectionUseCase =
          GetIt.instance<UpdateDescriptionSelectionUseCase>();
      final success = await updateSelectionUseCase(
        missionId: widget.mission.id,
        field: 'regime_neutre_detail',
        value: detail,
      );

      if (success) {
        setState(() => _tnDetail = detail);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Détail TN enregistré : TN-$detail'),
              backgroundColor: Colors.green,
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
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
    // "Autre" : on attend que l'utilisateur confirme son texte avant de sauvegarder
    if (value != 'Autre') {
      _saveSelection(value);
    }
  }

  Future<void> _saveAutreValue() async {
    final customValue = _autreController.text.trim();
    if (customValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un régime de neutre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _autreSavedValue = customValue;
    });
    try {
      await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: widget.field,
        value: customValue,
      );
      if (!widget.isComplete) widget.onComplete(widget.field);
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistré : $customValue'),
            backgroundColor: Colors.green,
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

          // Options principales
          ...displayOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedValue == option;

            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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

          // ✅ Sous-options TN-C / TN-S (apparaissent uniquement si TN est sélectionné)
          if (_showTnOptions) ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_right,
                        color: AppTheme.primaryBlue,
                        size: isSmallScreen ? 20 : 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Type de régime TN',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTnOptionButton(
                          label: 'TN-C',
                          isSelected: _tnDetail == 'C',
                          onTap: () => _saveTnDetail('C'),
                          color: Colors.blue,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: _buildTnOptionButton(
                          label: 'TN-S',
                          isSelected: _tnDetail == 'S',
                          onTap: () => _saveTnDetail('S'),
                          color: Colors.green,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 8 : 10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: isSmallScreen ? 14 : 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Expanded(
                          child: Text(
                            'TN-C : Neutre et protection combinés\nTN-S : Neutre et protection séparés',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 16 : 20),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Champ libre pour "Autre" (régime de neutre uniquement)
          if (_showAutreField && widget.field == 'regime_neutre') ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primaryBlue,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Précisez le régime de neutre',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _autreController,
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: IT-T, PEN, BT isolé...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      suffixIcon: _autreSavedValue != null
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAutreValue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Valider',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_autreSavedValue != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sauvegardé : $_autreSavedValue',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTnOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
