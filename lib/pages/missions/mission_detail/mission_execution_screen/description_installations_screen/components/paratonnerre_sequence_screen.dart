// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/paratonnerre_sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/observation_screen.dart';
import 'package:inspec_app/components/safe_file_image.dart';

class ParatonnerreSequenceScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final Function(String) onComplete;
  final bool isComplete;

  const ParatonnerreSequenceScreen({
    super.key,
    required this.mission,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  ConsumerState<ParatonnerreSequenceScreen> createState() =>
      _ParatonnerreSequenceScreenState();
}

class _ParatonnerreSequenceScreenState
    extends ConsumerState<ParatonnerreSequenceScreen> {
  String? _presenceParatonnerre;
  String? _analyseRisqueFoudre;
  String? _etudeTechniqueFoudre;
  bool _isFirstLoad = true;

  final List<String> _presenceOptions = ['Oui', 'Non'];
  final List<String> _subOptions = ['Oui', 'Non', 'Sans objet'];

  Future<void> _saveField(String field, String value) async {
    try {
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );
      await notifier.updateDescriptionSelection(field, value);

      final stateData = ref
          .read(descriptionInstallationsProvider(widget.mission.id))
          .value;
      final isParatonnerreComplete =
          stateData?.isSectionComplete('paratonnerre') ?? false;

      if (isParatonnerreComplete && !widget.isComplete) {
        widget.onComplete('paratonnerre');
      }
    } catch (_) {
      // Auto-sauvegarde silencieuse
    }
  }

  void _ajouterObservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          title: 'Nouvelle Observation Foudre',
          canAddPhotos: true,
          onSave: (obs) async {
            final notifier = ref.read(
              descriptionInstallationsProvider(widget.mission.id).notifier,
            );
            await notifier.addFoudreObservation(obs);
          },
        ),
      ),
    );
  }

  void _editerObservation(int index, ObservationLibre obs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          observation: obs,
          title: 'Modifier Observation Foudre',
          canAddPhotos: true,
          onSave: (updatedObs) async {
            final notifier = ref.read(
              descriptionInstallationsProvider(widget.mission.id).notifier,
            );
            await notifier.updateFoudreObservation(index, updatedObs);
          },
        ),
      ),
    );
  }

  void _supprimerObservation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression', style: TextStyle(fontSize: 18)),
        content: const Text('Voulez-vous vraiment supprimer cette observation foudre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(
                descriptionInstallationsProvider(widget.mission.id).notifier,
              );
              await notifier.removeFoudreObservation(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final asyncData = ref.watch(
      descriptionInstallationsProvider(widget.mission.id),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (desc) {
          if (_isFirstLoad) {
            _presenceParatonnerre = desc.presenceParatonnerre;
            _analyseRisqueFoudre = desc.analyseRisqueFoudre ?? 'Sans objet';
            _etudeTechniqueFoudre = desc.etudeTechniqueFoudre ?? 'Sans objet';
            _isFirstLoad = false;
          }

          final foudreObsList = desc.foudreObservations;
          final isParatonnerreOui = _presenceParatonnerre == 'Oui';

          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Carte principale : Présence de paratonnerre
                _buildRadioCard(
                  title: 'Présence de paratonnerre',
                  options: _presenceOptions,
                  selectedValue: _presenceParatonnerre,
                  onChanged: (value) {
                    setState(() => _presenceParatonnerre = value);
                    _saveField('presence_paratonnerre', value);

                    // Si on repasse à Non, aucune autre carte ne doit s'afficher
                    if (value == 'Non') {
                      _analyseRisqueFoudre = 'Sans objet';
                      _etudeTechniqueFoudre = 'Sans objet';
                      _saveField('analyse_risque_foudre', 'Sans objet');
                      _saveField('etude_technique_foudre', 'Sans objet');
                    }
                  },
                  isSmallScreen: isSmallScreen,
                ),

                // 2. Si "Oui" : Cartes supplémentaires Analyse et Étude
                if (isParatonnerreOui) ...[
                  const SizedBox(height: 16),
                  _buildRadioCard(
                    title: 'Analyse risque foudre',
                    options: _subOptions,
                    selectedValue: _analyseRisqueFoudre ?? 'Sans objet',
                    onChanged: (value) {
                      setState(() => _analyseRisqueFoudre = value);
                      _saveField('analyse_risque_foudre', value);
                    },
                    isSmallScreen: isSmallScreen,
                  ),

                  const SizedBox(height: 16),
                  _buildRadioCard(
                    title: 'Étude technique foudre',
                    options: _subOptions,
                    selectedValue: _etudeTechniqueFoudre ?? 'Sans objet',
                    onChanged: (value) {
                      setState(() => _etudeTechniqueFoudre = value);
                      _saveField('etude_technique_foudre', value);
                    },
                    isSmallScreen: isSmallScreen,
                  ),

                  const SizedBox(height: 24),

                  // 3. Espace dédié de gestion des Observations Foudre
                  _buildObservationsSection(
                    context: context,
                    foudreObsList: foudreObsList,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadioCard({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onChanged,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
          ),
          const Divider(height: 0),
          ...options.map((option) {
            final isSelected = selectedValue == option;
            return RadioListTile<String>(
              title: Text(
                option,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                ),
              ),
              value: option,
              groupValue: selectedValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppTheme.primaryBlue,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildObservationsSection({
    required BuildContext context,
    required List<ObservationLibre> foudreObsList,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Observations Foudre',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _ajouterObservation,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 0),
          const SizedBox(height: 12),

          if (foudreObsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade400, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Aucune observation foudre enregistrée',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: foudreObsList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final obs = foudreObsList[index];
                return _buildObservationCard(index, obs);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildObservationCard(int index, ObservationLibre obs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  obs.texte,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                    onPressed: () => _editerObservation(index, obs),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _supprimerObservation(index),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),

          if (obs.hasNormativeReference) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Réf. normativ : ${obs.referenceNormative}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],

          if (obs.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: obs.photos.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SafeFileImage(
                      path: obs.photos[idx],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
