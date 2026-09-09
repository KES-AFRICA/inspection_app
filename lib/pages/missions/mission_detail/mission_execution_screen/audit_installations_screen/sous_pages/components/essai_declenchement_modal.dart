// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essai_declenchement_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/document_generation/essai_declenchement_helper.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Modal bottom sheet pour saisir ou modifier un essai de déclenchement différentiel
class EssaiDeclenchementModal extends ConsumerStatefulWidget {
  final String missionId;
  final String elementId;
  final String equipementId;
  final String zone;
  final String repere;
  final String designation;
  final String? circuitName;
  final String precision;
  final String typeDispositif;
  final String calibre;
  final String ddr;
  final EssaiDeclenchementDifferentiel? existingEssai;

  const EssaiDeclenchementModal({
    super.key,
    required this.missionId,
    required this.elementId,
    required this.equipementId,
    required this.zone,
    required this.repere,
    required this.designation,
    this.circuitName,
    required this.precision,
    required this.typeDispositif,
    required this.calibre,
    required this.ddr,
    this.existingEssai,
  });

  static Future<EssaiDeclenchementDifferentiel?> show(
    BuildContext context, {
    required String missionId,
    required String elementId,
    required String equipementId,
    required String zone,
    required String repere,
    required String designation,
    String? circuitName,
    required String precision,
    required String typeDispositif,
    required String calibre,
    required String ddr,
    EssaiDeclenchementDifferentiel? existingEssai,
  }) {
    return showModalBottomSheet<EssaiDeclenchementDifferentiel>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: GestureDetector(
          onTap: () {}, // Prevent taps inside the modal container from dismissing
          child: EssaiDeclenchementModal(
            missionId: missionId,
            elementId: elementId,
            equipementId: equipementId,
            zone: zone,
            repere: repere,
            designation: designation,
            circuitName: circuitName,
            precision: precision,
            typeDispositif: typeDispositif,
            calibre: calibre,
            ddr: ddr,
            existingEssai: existingEssai,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<EssaiDeclenchementModal> createState() => _EssaiDeclenchementModalState();
}

class _EssaiDeclenchementModalState extends ConsumerState<EssaiDeclenchementModal> {
  final _tempoController = TextEditingController();
  final _observationController = TextEditingController();
  
  // Par défaut "Satisfaisant"
  String _selectedResultat = 'Satisfaisant';
  bool _isSaving = false;
  EssaiDeclenchementDifferentiel? _resolvedEssai;

  bool get isEdition => _resolvedEssai != null || widget.existingEssai != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _resolvedEssai = widget.existingEssai;
    if (_resolvedEssai == null) {
      final mesures = HiveService.getMesuresEssaisByMissionId(widget.missionId);
      if (mesures != null) {
        for (final e in mesures.essaisDeclenchement) {
          // 1. Priorité absolue : correspondance par elementId
          if (widget.elementId.isNotEmpty && e.elementId == widget.elementId) {
            _resolvedEssai = e;
            break;
          }
          // 2. Fallback rétrocompatible si elementId absent
          if (e.elementId == null || e.elementId!.isEmpty) {
            if (widget.precision == EssaiDeclenchementHelper.precisionProtectionTete) {
              if (widget.equipementId.isNotEmpty &&
                  e.equipementId == widget.equipementId &&
                  e.precision != null &&
                  e.precision!.trim().toLowerCase() == widget.precision.trim().toLowerCase()) {
                _resolvedEssai = e;
                break;
              }
            } else {
              final targetCircuit = (widget.circuitName != null && widget.circuitName!.trim().isNotEmpty)
                  ? widget.circuitName!.trim().toLowerCase()
                  : null;
              if (widget.equipementId.isNotEmpty &&
                  e.equipementId == widget.equipementId &&
                  e.precision != null &&
                  e.precision!.trim().toLowerCase() == widget.precision.trim().toLowerCase() &&
                  targetCircuit != null &&
                  e.designationCircuit != null &&
                  e.designationCircuit!.trim().toLowerCase() == targetCircuit) {
                _resolvedEssai = e;
                break;
              }
            }
          }
        }
      }
    }

    if (isEdition) {
      final e = _resolvedEssai ?? widget.existingEssai!;
      _tempoController.text = e.displayTempo.isNotEmpty && e.displayTempo != '-'
          ? e.displayTempo
          : "Réglage d'origine.";
      _selectedResultat = (e.essai == 'NON OK' || e.essai == 'M' || e.essai == 'Non satisfaisant')
          ? 'Non satisfaisant'
          : 'Satisfaisant';
      _observationController.text = e.observation ?? '';
    } else {
      _tempoController.text = "Réglage d'origine.";
      _selectedResultat = 'Satisfaisant';
    }
  }

  @override
  void dispose() {
    _tempoController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final tempoStr = _tempoController.text.trim();
      final double? tempoValue = (tempoStr == "Réglage d'origine." || tempoStr == "Réglage d'origine")
          ? 0.0
          : double.tryParse(tempoStr);

      final cleanCalibre = widget.calibre.replaceAll(RegExp(r'[^0-9.]'), '');
      final calibreDouble = double.tryParse(cleanCalibre);

      final cleanDdr = widget.ddr.replaceAll(RegExp(r'[^0-9.]'), '');
      final ddrDouble = double.tryParse(cleanDdr);

      final now = DateTime.now().toUtc();
      final essaiValue = _selectedResultat == 'Satisfaisant' ? 'OK' : 'NON OK';

      // Charger les mesures existantes
      final mesures = await ref.read(mesuresEssaisProvider(widget.missionId).notifier).load();

      EssaiDeclenchementDifferentiel savedEssai;

      int existingIndex = -1;
      final targetId = _resolvedEssai?.id ?? widget.existingEssai?.id;
      final targetElementId = widget.elementId.isNotEmpty ? widget.elementId : null;

      existingIndex = mesures.essaisDeclenchement.indexWhere((e) {
        if (targetId != null && targetId.isNotEmpty && e.id == targetId) return true;
        if (targetElementId != null && e.elementId == targetElementId) return true;
        if (e.elementId == null || e.elementId!.isEmpty) {
          if (widget.precision == EssaiDeclenchementHelper.precisionProtectionTete) {
            if (widget.equipementId.isNotEmpty &&
                e.equipementId == widget.equipementId &&
                e.precision != null &&
                e.precision!.trim().toLowerCase() == widget.precision.trim().toLowerCase()) {
              return true;
            }
          } else {
            final targetCircuit = (widget.circuitName != null && widget.circuitName!.trim().isNotEmpty)
                ? widget.circuitName!.trim().toLowerCase()
                : null;
            if (widget.equipementId.isNotEmpty &&
                e.equipementId == widget.equipementId &&
                e.precision != null &&
                e.precision!.trim().toLowerCase() == widget.precision.trim().toLowerCase() &&
                targetCircuit != null &&
                e.designationCircuit != null &&
                e.designationCircuit!.trim().toLowerCase() == targetCircuit) {
              return true;
            }
          }
        }
        return false;
      });

      final effectiveCircuitName = (widget.circuitName != null && widget.circuitName!.trim().isNotEmpty)
          ? widget.circuitName!.trim()
          : widget.precision;

      if (existingIndex != -1) {
        // Mode modification
        final prev = mesures.essaisDeclenchement[existingIndex];
        savedEssai = prev.copyWith(
          id: prev.id,
          localisation: widget.repere.isNotEmpty ? widget.repere : (widget.zone.isNotEmpty ? widget.zone : prev.localisation),
          coffret: widget.designation.isNotEmpty ? widget.designation : prev.coffret,
          designationCircuit: effectiveCircuitName,
          typeDispositif: widget.typeDispositif.isNotEmpty ? widget.typeDispositif : prev.typeDispositif,
          calibre: calibreDouble ?? prev.calibre,
          reglageIAn: ddrDouble ?? prev.reglageIAn,
          tempo: tempoValue,
          tempoText: tempoStr.isNotEmpty ? tempoStr : "Réglage d'origine.",
          essai: essaiValue,
          observation: _observationController.text.trim().isNotEmpty ? _observationController.text.trim() : null,
          updatedAt: now,
          elementId: widget.elementId.isNotEmpty ? widget.elementId : prev.elementId,
          precision: widget.precision.isNotEmpty ? widget.precision : prev.precision,
          equipementId: widget.equipementId.isNotEmpty ? widget.equipementId : prev.equipementId,
          zone: widget.zone.isNotEmpty ? widget.zone : prev.zone,
          repere: widget.repere.isNotEmpty ? widget.repere : prev.repere,
        );
        mesures.essaisDeclenchement[existingIndex] = savedEssai;
      } else {
        // Mode création
        savedEssai = EssaiDeclenchementDifferentiel(
          localisation: widget.repere.isNotEmpty ? widget.repere : widget.zone,
          coffret: widget.designation,
          designationCircuit: effectiveCircuitName,
          typeDispositif: widget.typeDispositif,
          calibre: calibreDouble,
          reglageIAn: ddrDouble,
          tempo: tempoValue,
          tempoText: tempoStr.isNotEmpty ? tempoStr : "Réglage d'origine.",
          essai: essaiValue,
          observation: _observationController.text.trim().isNotEmpty ? _observationController.text.trim() : null,
          createdAt: now,
          updatedAt: now,
          elementId: widget.elementId,
          precision: widget.precision,
          equipementId: widget.equipementId,
          zone: widget.zone,
          repere: widget.repere,
        );
        mesures.essaisDeclenchement.add(savedEssai);
      }

      final success = await ref.read(mesuresEssaisProvider(widget.missionId).notifier).saveMesures(mesures);
      await HiveService.saveMesuresEssais(mesures);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdition ? 'Essai de déclenchement modifié' : 'Essai de déclenchement enregistré'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, savedEssai);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la sauvegarde de l\'essai'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre supérieure indicatrice
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // En-tête titre + icône
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.speed, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdition ? "Modifier l'essai de déclenchement" : "Essai de déclenchement",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Dispositif différentiel résiduel (DDR)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Récapitulatif contextuel
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildContextRow('Zone', widget.zone.isNotEmpty ? widget.zone : '-'),
                    _buildContextRow('Repère', widget.repere.isNotEmpty ? widget.repere : '-'),
                    _buildContextRow('Équipement', widget.designation),
                    if (widget.circuitName != null && widget.circuitName!.trim().isNotEmpty)
                      _buildContextRow('Circuit / Élément', widget.circuitName!.trim()),
                    _buildContextRow('Précision', widget.precision),
                    _buildContextRow('Type dispositif', widget.typeDispositif),
                    _buildContextRow('Calibre', widget.calibre.isNotEmpty ? '${widget.calibre} A' : '-'),
                    _buildContextRow('IΔn', widget.ddr.isNotEmpty ? '${widget.ddr} mA' : '-'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Champ Temporisation avec bouton 'Réglage d\'origine'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Temporisation",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                  ),
                  
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tempoController,
                decoration: InputDecoration(
                  hintText: "Réglage d'origine.",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.restart_alt, size: 18),
                    tooltip: "Rétablir Réglage d'origine",
                    onPressed: () {
                      setState(() {
                        _tempoController.text = "Réglage d'origine.";
                      });
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Toggle Résultat de l'essai
              Text(
                "Résultat de l'essai",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildResultToggleOption(
                      title: 'Satisfaisant',
                      icon: Icons.check_circle,
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                      isSelected: _selectedResultat == 'Satisfaisant',
                      onTap: () => setState(() => _selectedResultat = 'Satisfaisant'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildResultToggleOption(
                      title: 'Non satisfaisant',
                      icon: Icons.cancel,
                      color: Colors.red.shade700,
                      bgColor: Colors.red.shade50,
                      isSelected: _selectedResultat == 'Non satisfaisant',
                      onTap: () => setState(() => _selectedResultat = 'Non satisfaisant'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champ Observation (optionnel)
            Text(
              "Observation (optionnelle)",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _observationController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Remarques éventuelles sur l'essai...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Annuler"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEdition ? "Modifier" : "Enregistrer",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildContextRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildResultToggleOption({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          border: isSelected ? Border.all(color: color.withOpacity(0.4), width: 1.2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
