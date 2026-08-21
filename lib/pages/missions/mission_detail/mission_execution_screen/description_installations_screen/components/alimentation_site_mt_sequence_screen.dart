// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/alimentation_site_mt_sequence_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';
import 'package:inspec_app/models/mission.dart';

class AlimentationSiteMtSequenceScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final Function(String) onComplete;
  final bool isComplete;

  const AlimentationSiteMtSequenceScreen({
    super.key,
    required this.mission,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  ConsumerState<AlimentationSiteMtSequenceScreen> createState() =>
      _AlimentationSiteMtSequenceScreenState();
}

class _AlimentationSiteMtSequenceScreenState
    extends ConsumerState<AlimentationSiteMtSequenceScreen> {
  final _tensionController = TextEditingController();
  final _nombreController = TextEditingController();

  String? _natureReseau;
  String? _presenceIacm;
  bool _isFirstLoad = true;
  bool _isSaving = false;

  final List<String> _natureOptions = ['Souterrain', 'Aérien'];
  final List<String> _iacmOptions = ['Oui', 'Non', 'Sans objet'];

  @override
  void dispose() {
    _tensionController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _saveField(String field, String value) async {
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      await notifier.updateDescriptionSelection(field, value);

      final stateData = ref
          .read(descriptionInstallationsProvider(widget.mission.id))
          .value;
      final isComplete =
          stateData?.isSectionComplete('alimentation_site_mt') ?? false;

      if (isComplete && !widget.isComplete) {
        widget.onComplete('alimentation_site_mt');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enregistré : $value'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final asyncData = ref.watch(
      descriptionInstallationsProvider(widget.mission.id),
    );

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (desc) {
        if (_isFirstLoad) {
          _natureReseau = desc.natureReseauAlimentationSite;
          _tensionController.text = desc.tensionAlimentationSite ?? '';
          _nombreController.text = desc.nombreAlimentationSite ?? '';
          _presenceIacm = desc.presenceIacmAlimentationSite;
          _isFirstLoad = false;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 1. Nature du réseau
              _buildSectionCard(
                title: 'Nature du réseau',
                child: Column(
                  children: _natureOptions.map((opt) {
                    final isSelected = _natureReseau == opt;
                    return RadioListTile<String>(
                      title: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      value: opt,
                      groupValue: _natureReseau,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _natureReseau = val);
                                _saveField('nature_reseau_alim_site', val);
                              }
                            },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Tension alimentation (kV)
              _buildSectionCard(
                title: 'Tension alimentation',
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _tensionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.\,]?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Tension d\'alimentation',
                      hintText: 'Ex: 15 ou 20',
                      suffixText: 'kV',
                      suffixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (val) {
                      final cleanVal = val.trim();
                      _saveField('tension_alim_site', cleanVal);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Nombre d'alimentation
              _buildSectionCard(
                title: 'Nombre d\'alimentation',
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _nombreController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Nombre d\'alimentation',
                      hintText: 'Ex: 1 ou 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (val) {
                      final cleanVal = val.trim();
                      _saveField('nombre_alim_site', cleanVal);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Présence de l'IACM à l'entrée de l'alimentation sur site
              _buildSectionCard(
                title: 'Présence de l\'IACM à l\'entrée de l\'alimentation sur site',
                child: Column(
                  children: _iacmOptions.map((opt) {
                    final isSelected = _presenceIacm == opt;
                    return RadioListTile<String>(
                      title: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      value: opt,
                      groupValue: _presenceIacm,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _presenceIacm = val);
                                _saveField('presence_iacm_alim_site', val);
                              }
                            },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Bouton Enregistrer global
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final tensionVal = _tensionController.text.trim();
                          final nombreVal = _nombreController.text.trim();

                          if (_natureReseau != null) {
                            await _saveField('nature_reseau_alim_site', _natureReseau!);
                          }
                          if (tensionVal.isNotEmpty) {
                            await _saveField('tension_alim_site', tensionVal);
                          }
                          if (nombreVal.isNotEmpty) {
                            await _saveField('nombre_alim_site', nombreVal);
                          }
                          if (_presenceIacm != null) {
                            await _saveField('presence_iacm_alim_site', _presenceIacm!);
                          }
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Valider et sauvegarder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
