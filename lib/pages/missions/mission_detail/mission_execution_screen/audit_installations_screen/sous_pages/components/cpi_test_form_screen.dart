import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';

class CpiTestFormScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final CpiTest? test;

  const CpiTestFormScreen({
    super.key,
    required this.mission,
    this.test,
  });

  @override
  ConsumerState<CpiTestFormScreen> createState() => _CpiTestFormScreenState();
}

class _CpiTestFormScreenState extends ConsumerState<CpiTestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpiController = TextEditingController();

  List<CpiEligibleEquipment> _eligibleEquipments = [];
  CpiEligibleEquipment? _selectedEquipment;

  String _essaiDeclenchement = 'Satisfaisant';
  String _reportAlarme = 'Satisfaisant';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _statutOptions = const [
    'Satisfaisant',
    'Non satisfaisant',
    'Sans objet',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  void _loadEquipments() {
    setState(() => _isLoading = true);
    try {
      final list = HiveService.getCpiEligibleEquipementsForMission(widget.mission.id);
      _eligibleEquipments = list;

      if (widget.test != null) {
        final existingTest = widget.test!;
        _cpiController.text = existingTest.cpi;
        _essaiDeclenchement = existingTest.essaiDeclenchement.isNotEmpty
            ? existingTest.essaiDeclenchement
            : 'Satisfaisant';
        _reportAlarme = existingTest.reportAlarme.isNotEmpty
            ? existingTest.reportAlarme
            : 'Satisfaisant';

        // Trouver l'équipement correspondant
        final match = _eligibleEquipments.where((e) => e.id == existingTest.equipmentId);
        if (match.isNotEmpty) {
          _selectedEquipment = match.first;
        } else {
          // Fallback pour équipement historique
          final fallback = CpiEligibleEquipment(
            id: existingTest.equipmentId ?? '',
            equipmentNom: existingTest.equipmentNom ?? '',
            type: 'Coffret/Armoire',
            repere: existingTest.repere ?? '',
            zone: existingTest.zone ?? '',
            transformateurId: existingTest.transformateurId,
            transformateurNom: existingTest.transformateurNom,
            isHistorical: true,
          );
          _eligibleEquipments = [fallback, ..._eligibleEquipments];
          _selectedEquipment = fallback;
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement équipements éligibles CPI: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cpiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un équipement BT'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(mesuresEssaisProvider(widget.mission.id).notifier);
      final mesures = await notifier.load();

      final now = DateTime.now();
      final isEdit = widget.test != null;

      final updatedTest = CpiTest(
        id: isEdit ? widget.test!.id : 'cpi_${DateTime.now().millisecondsSinceEpoch}',
        equipmentId: _selectedEquipment!.id,
        equipmentNom: _selectedEquipment!.equipmentNom,
        transformateurId: _selectedEquipment!.transformateurId,
        transformateurNom: _selectedEquipment!.transformateurNom,
        zone: _selectedEquipment!.zone,
        repere: _selectedEquipment!.repere,
        cpi: _cpiController.text.trim(),
        essaiDeclenchement: _essaiDeclenchement,
        reportAlarme: _reportAlarme,
        createdAt: isEdit ? widget.test!.createdAt : now,
        updatedAt: now,
      );

      if (isEdit) {
        final idx = mesures.cpiTests.indexWhere((t) => t.id == widget.test!.id);
        if (idx != -1) {
          mesures.cpiTests[idx] = updatedTest;
        } else {
          mesures.cpiTests.add(updatedTest);
        }
      } else {
        mesures.cpiTests.add(updatedTest);
      }

      await notifier.saveMesures(mesures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Test CPI modifié avec succès' : 'Test CPI ajouté avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSegmentedSelector({
    required String label,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: _statutOptions.map((opt) {
              final isSelected = currentValue == opt;
              Color activeColor = AppTheme.primaryBlue;
              if (opt == 'Satisfaisant') activeColor = Colors.green.shade700;
              if (opt == 'Non satisfaisant') activeColor = Colors.red.shade700;
              if (opt == 'Sans objet') activeColor = Colors.grey.shade700;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.test != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le test CPI' : 'Ajouter un test CPI'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Avertissement si aucun équipement éligible
                  if (_eligibleEquipments.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aucun équipement BT éligible trouvé.\n'
                              'Pour qu\'un équipement apparaisse ici, il doit être alimenté par un transformateur MT en régime IT (configuré dans l\'Audit BT/MT).',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Section Équipement
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Équipement BT surveillé',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<CpiEligibleEquipment>(
                            value: _selectedEquipment,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Sélectionner l\'équipement *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: const Icon(Icons.table_chart_outlined),
                            ),
                            items: _eligibleEquipments.map((eq) {
                              return DropdownMenuItem(
                                value: eq,
                                child: Text(
                                  eq.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (eq) {
                              setState(() {
                                _selectedEquipment = eq;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Veuillez choisir un équipement' : null,
                          ),
                          if (_selectedEquipment != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Transformateur MT :',
                              _selectedEquipment!.transformateurNom ?? 'Non renseigné',
                              icon: Icons.electrical_services,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              'Zone / Localisation :',
                              _selectedEquipment!.zone.isNotEmpty
                                  ? _selectedEquipment!.zone
                                  : 'Non renseignée',
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              'Repère :',
                              _selectedEquipment!.repere.isNotEmpty
                                  ? _selectedEquipment!.repere
                                  : 'Non renseigné',
                              icon: Icons.tag,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Contrôle CPI
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paramètres & Résultats du CPI',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _cpiController,
                            decoration: InputDecoration(
                              labelText: 'CPI (Désignation / Marque / Modèle) *',
                              hintText: 'Ex: Vigilohm IM20, Bender iso685...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: const Icon(Icons.sensors),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Veuillez renseigner le CPI';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildSegmentedSelector(
                            label: 'Essais de déclenchement *',
                            currentValue: _essaiDeclenchement,
                            onChanged: (val) => setState(() => _essaiDeclenchement = val),
                          ),
                          const SizedBox(height: 16),
                          _buildSegmentedSelector(
                            label: 'Vérification du report d\'alarme *',
                            currentValue: _reportAlarme,
                            onChanged: (val) => setState(() => _reportAlarme = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton Enregistrer
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Enregistrer les modifications' : 'Ajouter le test CPI',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
