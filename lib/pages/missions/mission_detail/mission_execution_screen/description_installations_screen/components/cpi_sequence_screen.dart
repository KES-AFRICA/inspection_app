// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/cpi_sequence_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';

class CpiSequenceScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final Function(String) onComplete;
  final bool isComplete;

  const CpiSequenceScreen({
    super.key,
    required this.mission,
    required this.onComplete,
    this.isComplete = false,
  });

  @override
  ConsumerState<CpiSequenceScreen> createState() => _CpiSequenceScreenState();
}

class _CpiSequenceScreenState extends ConsumerState<CpiSequenceScreen> {
  String? _locallySelectedStatus;
  bool _isSaving = false;

  Future<void> _selectAndSaveStatus(String status, Map<String, String> existingData) async {
    if (_isSaving) return;

    setState(() {
      _locallySelectedStatus = status;
      _isSaving = true;
    });

    try {
      final cpiData = Map<String, String>.from(existingData);
      cpiData['RÉGIME DE NEUTRE SURVEILLÉ'] = 'IT';
      cpiData['RESULTAT_TEST'] = status;

      final cpiItem = InstallationItem(data: cpiData);
      final notifier = ref.read(
        descriptionInstallationsProvider(widget.mission.id).notifier,
      );

      final success = await notifier.updateInstallationItem('cpi', 0, cpiItem);

      if (success) {
        widget.onComplete('test_cpi');

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enregistré : $status'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Satisfaisant':
        return Colors.green.shade700;
      case 'Non satisfaisant':
        return Colors.red.shade700;
      case 'Sans objet':
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Satisfaisant':
        return Colors.green.shade50;
      case 'Non satisfaisant':
        return Colors.red.shade50;
      case 'Sans objet':
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Satisfaisant':
        return Icons.check_circle_outline;
      case 'Non satisfaisant':
        return Icons.cancel_outlined;
      case 'Sans objet':
      default:
        return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(descriptionInstallationsProvider(widget.mission.id));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (desc) {
        final regime = desc.regimeNeutre;
        final hasItRegime = regime?.split(',').map((e) => e.trim()).contains('IT') ?? false;

        final existingCpiData = desc.cpi.isNotEmpty ? desc.cpi.last.data : <String, String>{};
        final savedStatus = existingCpiData['RESULTAT_TEST'] ?? 'Sans objet';
        final activeStatus = _locallySelectedStatus ?? savedStatus;

        if (!hasItRegime) {
          return _buildNonItNotice(regime);
        }

        return _buildCpiContent(activeStatus, existingCpiData);
      },
    );
  }

  Widget _buildNonItNotice(String? regimeNeutre) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Test CPI (Réservé au Régime IT)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Le test du Contrôleur Permanent d\'Isolement (CPI) s\'applique uniquement aux installations électriques fonctionnant en Régime IT (NF C 15-100).\n\n'
                  'Régime actuellement sélectionné : ${regimeNeutre != null && regimeNeutre.isNotEmpty ? regimeNeutre : 'Aucun'}.\n\n'
                  'Le statut de ce test est donc automatiquement fixé à "Sans objet".',
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                SizedBox(width: 10),
                Text(
                  'Statut retenu : Sans objet',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCpiContent(String activeStatus, Map<String, String> existingCpiData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner En-tête
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Test du CPI (Régime IT)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Contrôle du déclenchement et de la transmission du report d\'alarme sur réseau IT.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Sélection du Statut du Test (Positionné au-dessus des essais)
          const Text(
            'Résultat de l\'essai du CPI',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusOption('Satisfaisant', activeStatus, existingCpiData),
                const SizedBox(width: 8),
                _buildStatusOption('Non satisfaisant', activeStatus, existingCpiData),
                const SizedBox(width: 8),
                _buildStatusOption('Sans objet', activeStatus, existingCpiData),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Cartes explicatives des essais
          _buildInfoCard(
            title: 'ESSAI DE DÉCLENCHEMENT DU CPI',
            icon: Icons.offline_bolt_outlined,
            description:
                'L\'essai consiste à simuler, au moyen d\'une résistance calibrée, un défaut d\'isolement sur le réseau IT surveillé, et à vérifier que le Contrôleur Permanent d\'Isolement détecte ce défaut et déclenche l\'alarme (locale et/ou à distance) au seuil de réglage configuré, sans provoquer de coupure de l\'installation.',
          ),
          const SizedBox(height: 12),

          _buildInfoCard(
            title: 'VÉRIFICATION DU REPORT D\'ALARME',
            icon: Icons.notifications_active_outlined,
            description:
                'Le report d\'alarme (voyant local, report GTB/GTC, ou tout autre dispositif de signalisation à distance) est contrôlé conjointement afin de s\'assurer que le personnel d\'exploitation est effectivement informé en cas de premier défaut d\'isolement.',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    String status,
    String activeStatus,
    Map<String, String> existingCpiData,
  ) {
    final isSelected = activeStatus == status;
    final color = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final icon = _getStatusIcon(status);

    return Expanded(
      child: InkWell(
        onTap: () => _selectAndSaveStatus(status, existingCpiData),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
