import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';
import 'cpi_test_form_screen.dart';

class CpiTestsListScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const CpiTestsListScreen({
    super.key,
    required this.mission,
  });

  @override
  ConsumerState<CpiTestsListScreen> createState() => _CpiTestsListScreenState();
}

class _CpiTestsListScreenState extends ConsumerState<CpiTestsListScreen> {
  bool _isLoading = true;
  List<CpiTest> _cpiTests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTests();
      }
    });
  }

  Future<void> _loadTests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final mesures = await ref
          .read(mesuresEssaisProvider(widget.mission.id).notifier)
          .load();
      if (mounted) {
        setState(() {
          _cpiTests = List.from(mesures.cpiTests);
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement tests CPI: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToAddTest() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CpiTestFormScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadTests();
    }
  }

  Future<void> _navigateToEditTest(CpiTest test) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CpiTestFormScreen(
          mission: widget.mission,
          test: test,
        ),
      ),
    );

    if (result == true) {
      await _loadTests();
    }
  }

  Future<void> _confirmDelete(CpiTest test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer le test CPI pour "${test.equipmentNom}" ?\n\n'
          'Cette action supprime uniquement ce test de contrôle sans affecter l\'armoire ni le transformateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(mesuresEssaisProvider(widget.mission.id).notifier);
        final mesures = await notifier.load();
        mesures.cpiTests.removeWhere((t) => t.id == test.id);
        await notifier.saveMesures(mesures);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test CPI supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadTests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'satisfaisant':
        return Colors.green.shade700;
      case 'non satisfaisant':
        return Colors.red.shade700;
      case 'sans objet':
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildStatusBadge(String label, String value) {
    final color = _getStatusColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_outlined,
                size: 54,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aucun test CPI enregistré',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez les essais réalisés sur les Contrôleurs Permanents d\'Isolement (réseau surveillé en régime IT).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddTest,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un test CPI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests CPI (Contrôleur Permanent d\'Isolement)'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTests,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddTest,
            tooltip: 'Ajouter un test',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cpiTests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTests,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _cpiTests.length,
                    itemBuilder: (context, index) {
                      final test = _cpiTests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToEditTest(test),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.sensors,
                                        size: 20,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            test.equipmentNom ?? 'Équipement BT',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Zone: ${(test.zone != null && test.zone!.isNotEmpty) ? test.zone! : "-"}  |  Repère: ${(test.repere != null && test.repere!.isNotEmpty) ? test.repere! : "-"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _navigateToEditTest(test);
                                        } else if (val == 'delete') {
                                          _confirmDelete(test);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Modifier'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 18, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                // Informations transfo & CPI
                                Row(
                                  children: [
                                    Icon(Icons.electrical_services, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Transfo: ${test.transformateurNom ?? "Non renseigné"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CPI: ${test.cpi}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Badges de résultats
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildStatusBadge('Déclenchement', test.essaiDeclenchement),
                                    _buildStatusBadge('Report d\'alarme', test.reportAlarme),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _cpiTests.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddTest,
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau test CPI'),
            )
          : null,
    );
  }
}
