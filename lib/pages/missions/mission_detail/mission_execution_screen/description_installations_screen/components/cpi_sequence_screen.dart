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
  // Statut du test (3 choix : 'Satisfaisant', 'Non satisfaisant', 'Sans objet')
  String _selectedStatus = 'Sans objet';
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _regimeNeutre;
  bool _hasItRegime = true;

  @override
  void initState() {
    super.initState();
    _loadExistingCpiData();
  }

  Future<void> _loadExistingCpiData() async {
    try {
      final desc = await ref
          .read(descriptionInstallationsProvider(widget.mission.id).notifier)
          .load();

      final regime = desc.regimeNeutre;
      final hasIt = regime?.split(',').map((e) => e.trim()).contains('IT') ?? false;

      if (desc.cpi.isNotEmpty) {
        final cpiData = desc.cpi.last.data;
        setState(() {
          _regimeNeutre = regime;
          _hasItRegime = hasIt;
          _selectedStatus = cpiData['RESULTAT_TEST'] ?? 'Sans objet';
          _isLoaded = true;
        });
      } else {
        setState(() {
          _regimeNeutre = regime;
          _hasItRegime = hasIt;
          _isLoaded = true;
        });
      }
    } catch (_) {
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _selectAndSaveStatus(String status) async {
    if (_isSaving) return;

    setState(() {
      _selectedStatus = status;
      _isSaving = true;
    });

    try {
      final desc = await ref
          .read(descriptionInstallationsProvider(widget.mission.id).notifier)
          .load();
      final existingData = desc.cpi.isNotEmpty ? desc.cpi.last.data : <String, String>{};

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
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasItRegime) {
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
                    'Régime actuellement sélectionné : ${_regimeNeutre != null && _regimeNeutre!.isNotEmpty ? _regimeNeutre : 'Aucun'}.\n\n'
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
                _buildStatusOption('Satisfaisant'),
                const SizedBox(width: 8),
                _buildStatusOption('Non satisfaisant'),
                const SizedBox(width: 8),
                _buildStatusOption('Sans objet'),
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

  Widget _buildStatusOption(String status) {
    final isSelected = _selectedStatus == status;
    final color = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final icon = _getStatusIcon(status);

    return Expanded(
      child: InkWell(
        onTap: () => _selectAndSaveStatus(status),
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
