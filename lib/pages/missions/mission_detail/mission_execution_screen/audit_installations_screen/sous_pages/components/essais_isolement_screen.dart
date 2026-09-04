import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';

const List<String> kSectionCableOptions = [
  '0',
  '1.5 mm²',
  '2.5 mm²',
  '4 mm²',
  '6 mm²',
  '10 mm²',
  '16 mm²',
  '25 mm²',
  '35 mm²',
  '50 mm²',
  '70 mm²',
  '95 mm²',
  '120 mm²',
  '150 mm²',
  '185 mm²',
  '240 mm²',
  '300 mm²',
];

// ================================================================
// ÉCRAN PRINCIPAL : LISTE DES ESSAIS D'ISOLEMENT
// ================================================================

class EssaisIsolementScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const EssaisIsolementScreen({super.key, required this.mission});

  @override
  ConsumerState<EssaisIsolementScreen> createState() => _EssaisIsolementScreenState();
}

class _EssaisIsolementScreenState extends ConsumerState<EssaisIsolementScreen> {
  List<EssaiIsolement> _essais = [];
  bool _isLoading = true;

  // Helpers responsifs
  double _rw(BuildContext context) => MediaQuery.of(context).size.width;
  bool _isSmallScreen(BuildContext context) => _rw(context) < 360;

  double _fontSizeL(BuildContext context) => _isSmallScreen(context) ? 15 : 17;
  double _fontSizeM(BuildContext context) => _isSmallScreen(context) ? 13 : 14;
  double _fontSizeS(BuildContext context) => _isSmallScreen(context) ? 11 : 12;
  double _fontSizeXS(BuildContext context) => _isSmallScreen(context) ? 10 : 11;
  double _iconSizeM(BuildContext context) => _isSmallScreen(context) ? 18 : 20;
  double _iconSizeS(BuildContext context) => _isSmallScreen(context) ? 14 : 16;
  double _spacingL(BuildContext context) => _isSmallScreen(context) ? 12 : 16;
  double _spacingM(BuildContext context) => _isSmallScreen(context) ? 10 : 12;
  double _spacingS(BuildContext context) => _isSmallScreen(context) ? 6 : 8;

  @override
  void initState() {
    super.initState();
    _loadEssais();
  }

  Future<void> _loadEssais() async {
    setState(() => _isLoading = true);
    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      
      // Purge automatique des anciens tests d'isolement inline de coffrets (effacés avec les champs)
      mesures.essaisIsolement.removeWhere(
        (e) => (e.pointA == null || e.pointA!.isEmpty) && (e.pointB == null || e.pointB!.isEmpty) && (e.reperePointOrigine == null || e.reperePointOrigine!.isEmpty),
      );
      await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);

      _essais = mesures.essaisIsolement;
    } catch (e) {
      debugPrint('❌ Erreur chargement essais isolement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterEssai() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiIsolementScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadEssais();
    }
  }

  void _editerEssai(EssaiIsolement essai, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiIsolementScreen(
          mission: widget.mission,
          essai: essai,
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadEssais();
    }
  }

  Future<void> _supprimerEssai(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirmer la suppression',
          style: TextStyle(fontSize: _fontSizeM(context) + 2, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cet essai d\'isolement ?',
          style: TextStyle(fontSize: _fontSizeM(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();

              if (index < mesures.essaisIsolement.length) {
                mesures.essaisIsolement.removeAt(index);
                await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
              }

              await _loadEssais();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Essai d\'isolement supprimé', style: TextStyle(fontSize: _fontSizeM(context))),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer', style: TextStyle(fontSize: _fontSizeM(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildEssaiCard(EssaiIsolement essai, int index) {
    final context = this.context;
    String statutText;
    IconData statutIcon;
    Color statutColor;

    switch (essai.appreciation) {
      case 'Satisfaisant':
        statutText = 'Satisfaisant';
        statutIcon = Icons.check_circle;
        statutColor = Colors.green.shade700;
        break;
      case 'Non satisfaisant':
        statutText = 'Non satisfaisant';
        statutIcon = Icons.cancel;
        statutColor = Colors.red.shade700;
        break;
      case 'Sans objet':
        statutText = 'Sans objet';
        statutIcon = Icons.remove_circle_outline;
        statutColor = Colors.grey.shade700;
        break;
      default:
        statutText = 'Non défini';
        statutIcon = Icons.help_outline;
        statutColor = Colors.orange.shade700;
    }

    final isSatisfaisant = essai.appreciation == 'Satisfaisant';
    final isNonSatisfaisant = essai.appreciation == 'Non satisfaisant';
    final badgeBg = isSatisfaisant
        ? Colors.green.shade50
        : (isNonSatisfaisant ? Colors.red.shade50 : Colors.grey.shade100);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _spacingL(context),
        vertical: _spacingS(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editerEssai(essai, index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1 : Statut en Haut à Gauche & Menu 3 points en Haut à Droite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statutIcon, size: 14, color: statutColor),
                        const SizedBox(width: 4),
                        Text(
                          statutText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statutColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerEssai(essai, index);
                      } else if (value == 'delete') {
                        _supprimerEssai(index);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            const Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Ligne 2 : Nom du repère/local sur sa propre ligne (pour gérer les noms longs)
              Text(
                essai.displayRepereOrigine,
                style: TextStyle(
                  fontSize: _fontSizeL(context),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),

              const SizedBox(height: 10),

              // Ligne 3 : Point A puis en bas Point B (empilés)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Origine : ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            essai.displayPointA,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extrémité : ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            essai.displayPointB,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Ligne 4 : Métriques clés (SECTION A, SECTION B, CÂBLES, ISOLEMENT)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      label: 'SECTION A',
                      value: essai.displaySectionPointA,
                    ),
                  ),
                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricItem(
                      label: 'SECTION B',
                      value: essai.displaySectionPointB,
                    ),
                  ),
                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricItem(
                      label: 'CÂBLES',
                      value: essai.displayNombreCables,
                    ),
                  ),
                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricItem(
                      label: 'ISOLEMENT',
                      value: '${essai.isolement} MΩ',
                      isHighlight: true,
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

  Widget _buildMetricItem({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.blue.shade800 : Colors.grey.shade800,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mesuresEssaisProvider(widget.mission.id));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'Essais de mesure d\'isolement',
            style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _ajouterEssai,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          child: Icon(Icons.add, size: _iconSizeM(context)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _essais.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.speed_outlined, size: 48, color: Colors.blue.shade300),
                        ),
                        SizedBox(height: _spacingL(context)),
                        Text(
                          'Aucun essai d\'isolement enregistré',
                          style: TextStyle(
                            fontSize: _fontSizeL(context),
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: _spacingS(context)),
                        Text(
                          'Cliquez sur le + pour ajouter un essai de tronçon',
                          style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEssais,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: _spacingS(context)),
                      itemCount: _essais.length,
                      itemBuilder: (context, index) {
                        return _buildEssaiCard(_essais[index], index);
                      },
                    ),
                  ),
      ),
    );
  }
}

// ================================================================
// ÉCRAN POUR AJOUTER / MODIFIER UN ESSAI D'ISOLEMENT
// ================================================================

class AjouterEssaiIsolementScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final EssaiIsolement? essai;
  final int? index;

  const AjouterEssaiIsolementScreen({
    super.key,
    required this.mission,
    this.essai,
    this.index,
  });

  bool get isEdition => essai != null;

  @override
  ConsumerState<AjouterEssaiIsolementScreen> createState() => _AjouterEssaiIsolementScreenState();
}

class _AjouterEssaiIsolementScreenState extends ConsumerState<AjouterEssaiIsolementScreen> {
  final _formKey = GlobalKey<FormState>();

  List<EquipementIsolementItem> _allEquipements = [];
  EquipementIsolementItem? _selectedPointAItem;
  EquipementIsolementItem? _selectedPointBItem;

  String? _selectedSectionPointA;
  String? _selectedSectionPointB;
  bool _isSectionPointAManual = false;
  bool _isSectionPointBManual = false;

  final _nombreCablesController = TextEditingController();
  final _isolementController = TextEditingController();

  String? _selectedAppreciation;
  bool _isSaving = false;

  // Helpers responsifs
  double _rw() => MediaQuery.of(context).size.width;
  bool get _isSmallScreen => _rw() < 360;

  double get _fontSizeL => _isSmallScreen ? 15 : 16;
  double get _fontSizeM => _isSmallScreen ? 13 : 14;
  double get _spacingL => _isSmallScreen ? 12 : 16;
  double get _spacingM => _isSmallScreen ? 10 : 12;
  double get _spacingS => _isSmallScreen ? 6 : 8;

  @override
  void initState() {
    super.initState();
    _chargerEquipements();
  }

  @override
  void dispose() {
    _nombreCablesController.dispose();
    _isolementController.dispose();
    super.dispose();
  }

  void _chargerEquipements() {
    _allEquipements = HiveService.getAllEquipementsIsolementForMission(widget.mission.id);

    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _selectedSectionPointA ??= '0';
      _selectedSectionPointB ??= '0';
    }
  }

  void _chargerDonneesExistantes() {
    final essai = widget.essai!;

    // Résolution du Point A
    if (essai.equipmentPointASyncId != null && essai.equipmentPointASyncId!.isNotEmpty) {
      _selectedPointAItem = _allEquipements.cast<EquipementIsolementItem?>().firstWhere(
            (e) => e?.id == essai.equipmentPointASyncId,
            orElse: () => null,
          );
    }
    if (_selectedPointAItem == null && (essai.pointA != null && essai.pointA!.isNotEmpty || essai.nomEquipementPointA != null && essai.nomEquipementPointA!.isNotEmpty)) {
      final infoA = essai.resolvePointAInfo(_allEquipements);
      _selectedPointAItem = _allEquipements.cast<EquipementIsolementItem?>().firstWhere(
            (e) => e?.displayName == infoA.displayName || e?.nom == infoA.nomEquipement || e?.id == infoA.equipmentId,
            orElse: () {
              final fallback = EquipementIsolementItem(
                id: infoA.equipmentId ?? 'legacy_A_${DateTime.now().millisecondsSinceEpoch}',
                nom: infoA.nomEquipement.isNotEmpty ? infoA.nomEquipement : (essai.pointA ?? ''),
                type: 'Équipement',
                repere: infoA.repere.isNotEmpty ? infoA.repere : (essai.reperePointOrigine ?? essai.localisation ?? 'Local'),
                zone: infoA.zone,
                sectionPointA: essai.sectionCablePointA ?? essai.sectionCable,
              );
              _allEquipements.add(fallback);
              return fallback;
            },
          );
    }

    // Résolution du Point B
    if (essai.equipmentPointBSyncId != null && essai.equipmentPointBSyncId!.isNotEmpty) {
      _selectedPointBItem = _allEquipements.cast<EquipementIsolementItem?>().firstWhere(
            (e) => e?.id == essai.equipmentPointBSyncId,
            orElse: () => null,
          );
    }
    if (_selectedPointBItem == null && (essai.pointB != null && essai.pointB!.isNotEmpty || essai.nomEquipementPointB != null && essai.nomEquipementPointB!.isNotEmpty)) {
      final infoB = essai.resolvePointBInfo(_allEquipements);
      _selectedPointBItem = _allEquipements.cast<EquipementIsolementItem?>().firstWhere(
            (e) => e?.displayName == infoB.displayName || e?.nom == infoB.nomEquipement || e?.id == infoB.equipmentId,
            orElse: () {
              final fallback = EquipementIsolementItem(
                id: infoB.equipmentId ?? 'legacy_B_${DateTime.now().millisecondsSinceEpoch}',
                nom: infoB.nomEquipement.isNotEmpty ? infoB.nomEquipement : (essai.pointB ?? ''),
                type: 'Équipement',
                repere: infoB.repere.isNotEmpty ? infoB.repere : (essai.reperePointOrigine ?? essai.localisation ?? 'Local'),
                zone: infoB.zone,
                sectionPointB: essai.sectionCablePointB ?? essai.sectionCable,
              );
              _allEquipements.add(fallback);
              return fallback;
            },
          );
    }

    final secA = essai.sectionCablePointA ?? essai.sectionCable;
    _selectedSectionPointA = (secA != null && secA.trim().isNotEmpty) ? secA.trim() : '0';

    final secB = essai.sectionCablePointB ?? essai.sectionCable;
    _selectedSectionPointB = (secB != null && secB.trim().isNotEmpty) ? secB.trim() : '0';

    _isSectionPointAManual = essai.isSectionPointAManual ?? false;
    _isSectionPointBManual = essai.isSectionPointBManual ?? false;

    _nombreCablesController.text = essai.nombreCablesTestes != null ? essai.nombreCablesTestes.toString() : '';
    _isolementController.text = essai.isolement > 0 ? essai.isolement.toString() : '';
    _selectedAppreciation = essai.appreciation.isNotEmpty ? essai.appreciation : null;
  }

  void _onPointAChanged(EquipementIsolementItem? newItem) {
    setState(() {
      _selectedPointAItem = newItem;
      if (newItem == null) {
        _selectedPointBItem = null;
        if (!_isSectionPointAManual) {
          _selectedSectionPointA = '0';
        }
      } else {
        if (newItem.id == _selectedPointBItem?.id) {
          _selectedPointBItem = null;
        }
        if (!_isSectionPointAManual) {
          final sec = newItem.sectionPointA?.trim();
          _selectedSectionPointA = (sec != null && sec.isNotEmpty) ? sec : '0';
        }
      }
    });
  }

  void _onPointBChanged(EquipementIsolementItem? newItem) {
    setState(() {
      _selectedPointBItem = newItem;
      if (newItem == null) {
        if (!_isSectionPointBManual) {
          _selectedSectionPointB = '0';
        }
      } else {
        if (!_isSectionPointBManual) {
          final sec = newItem.sectionPointB?.trim();
          _selectedSectionPointB = (sec != null && sec.isNotEmpty) ? sec : '0';
        }
      }
    });
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedPointAItem == null) {
      _showErrorSnackBar('Veuillez sélectionner le Point A (origine).');
      return;
    }

    if (_selectedPointBItem == null) {
      _showErrorSnackBar('Veuillez sélectionner le Point B (extrémité).');
      return;
    }

    if (_selectedSectionPointA == null || _selectedSectionPointA!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner la Section du câble Point A.');
      return;
    }

    if (_selectedSectionPointB == null || _selectedSectionPointB!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner la Section du câble Point B.');
      return;
    }

    final nbCables = int.tryParse(_nombreCablesController.text.trim());
    if (nbCables == null || nbCables <= 0) {
      _showErrorSnackBar('Veuillez saisir un nombre valide de câbles testés.');
      return;
    }

    if (_selectedAppreciation == null || _selectedAppreciation!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner une appréciation.');
      return;
    }

    final isSansObjet = _selectedAppreciation == 'Sans objet';
    final double isoValue;
    if (isSansObjet) {
      isoValue = 0.0;
    } else {
      final parsedIso = double.tryParse(_isolementController.text.trim().replaceAll(',', '.'));
      if (parsedIso == null || parsedIso <= 0) {
        _showErrorSnackBar('Veuillez saisir une valeur d\'isolement valide (MΩ).');
        return;
      }
      isoValue = parsedIso;
    }

    setState(() => _isSaving = true);

    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();

      final repereDerive = EssaiIsolement.computeRepereDerive(
        _selectedPointAItem?.repere,
        _selectedPointBItem?.repere,
      );

      final essai = EssaiIsolement(
        syncId: widget.essai?.syncId ?? 'iso_${DateTime.now().microsecondsSinceEpoch}',
        equipmentSyncId: _selectedPointAItem?.id,
        pointControle: 'De ${_selectedPointAItem?.nom} vers ${_selectedPointBItem?.nom}',
        isolement: isoValue,
        appreciation: _selectedAppreciation!,
        localisation: repereDerive,
        designation: _selectedPointAItem?.nom,
        reperePointOrigine: repereDerive,
        pointA: _selectedPointAItem?.displayName ?? _selectedPointAItem?.nom,
        pointB: _selectedPointBItem?.displayName ?? _selectedPointBItem?.nom,
        sectionCable: _selectedSectionPointA, // Fallback legacy
        sectionCablePointA: _selectedSectionPointA,
        sectionCablePointB: _selectedSectionPointB,
        isSectionPointAManual: _isSectionPointAManual,
        isSectionPointBManual: _isSectionPointBManual,
        equipmentPointASyncId: _selectedPointAItem?.id,
        equipmentPointBSyncId: _selectedPointBItem?.id,
        zonePointA: _selectedPointAItem?.zone,
        reperePointA: _selectedPointAItem?.repere,
        nomEquipementPointA: _selectedPointAItem?.nom,
        zonePointB: _selectedPointBItem?.zone,
        reperePointB: _selectedPointBItem?.repere,
        nomEquipementPointB: _selectedPointBItem?.nom,
        nombreCablesTestes: nbCables,
      );

      if (widget.isEdition && widget.index != null && widget.index! < mesures.essaisIsolement.length) {
        mesures.essaisIsolement[widget.index!] = essai;
      } else {
        mesures.essaisIsolement.add(essai);
      }

      await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde essai isolement: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildAppreciationButton({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedAppreciation == label;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedAppreciation = label),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: isSelected ? color : Colors.grey.shade600),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnoughEquipments = _allEquipements.length >= 2;
    final List<EquipementIsolementItem> equipementsPointBOptions =
        _allEquipements.where((eq) => eq.id != _selectedPointAItem?.id).toList();

    final String computedRepere = EssaiIsolement.computeRepereDerive(
      _selectedPointAItem?.repere,
      _selectedPointBItem?.repere,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            widget.isEdition ? 'Modifier l\'essai d\'isolement' : 'Ajouter un essai d\'isolement',
            style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(_spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de sélection des équipements & repère dérivé
                Container(
                  padding: EdgeInsets.all(_spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Tronçon d\'isolement (Point A & B)',
                        style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                      ),
                      const Divider(height: 20),

                      if (!hasEnoughEquipments) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Au moins 2 équipements enregistrés dans l\'audit sont nécessaires pour mesurer l\'isolement d\'un tronçon.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _spacingM),
                      ],

                      // Point A (origine)
                      Text('Point A (origine) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<EquipementIsolementItem?>(
                        value: _selectedPointAItem,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Sélectionner l\'équipement d\'origine (Point A)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500, overflow: TextOverflow.ellipsis),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem<EquipementIsolementItem?>(
                            value: null,
                            child: Text('Aucune sélection', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ),
                          ..._allEquipements.map((eq) {
                            return DropdownMenuItem<EquipementIsolementItem?>(
                              value: eq,
                              child: Text(eq.displayName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: hasEnoughEquipments ? _onPointAChanged : null,
                      ),

                      SizedBox(height: _spacingM),

                      // Point B (extrémité) - exclut Point A
                      Text('Point B (extrémité) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<EquipementIsolementItem?>(
                        value: _selectedPointBItem,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: _selectedPointAItem == null
                              ? 'Veuillez d\'abord choisir le Point A'
                              : 'Sélectionner l\'équipement d\'extrémité (Point B)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500, overflow: TextOverflow.ellipsis),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem<EquipementIsolementItem?>(
                            value: null,
                            child: Text('Aucune sélection', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ),
                          ...equipementsPointBOptions.map((eq) {
                            return DropdownMenuItem<EquipementIsolementItem?>(
                              value: eq,
                              child: Text(eq.displayName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (_selectedPointAItem != null && hasEnoughEquipments) ? _onPointBChanged : null,
                      ),

                      SizedBox(height: _spacingM),

                      // Repère du point d'origine (Champ dérivé automatique non modifiable à la main)
                      Text('Repère du point d\'origine (dérivé)', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                computedRepere,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: _spacingL),

                // Card des Sections de câble & Mesure
                Container(
                  padding: EdgeInsets.all(_spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Sections de câble & Mesures',
                        style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                      ),
                      const Divider(height: 20),

                      // Section du câble Point A
                      Text('Section du câble Point A (mm²) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        value: (_selectedSectionPointA != null && kSectionCableOptions.contains(_selectedSectionPointA))
                            ? _selectedSectionPointA
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Choisir la section Point A',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500, overflow: TextOverflow.ellipsis),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Aucune sélection', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ),
                          ...kSectionCableOptions.map((sec) {
                            return DropdownMenuItem<String?>(
                              value: sec,
                              child: Text(sec, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedSectionPointA = v;
                            _isSectionPointAManual = true;
                          });
                        },
                      ),

                      SizedBox(height: _spacingM),

                      // Section du câble Point B
                      Text('Section du câble Point B (mm²) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        value: (_selectedSectionPointB != null && kSectionCableOptions.contains(_selectedSectionPointB))
                            ? _selectedSectionPointB
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Choisir la section Point B',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500, overflow: TextOverflow.ellipsis),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Aucune sélection', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ),
                          ...kSectionCableOptions.map((sec) {
                            return DropdownMenuItem<String?>(
                              value: sec,
                              child: Text(sec, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedSectionPointB = v;
                            _isSectionPointBManual = true;
                          });
                        },
                      ),

                      SizedBox(height: _spacingM),

                      // Nombre de câbles testés
                      Text('Nombre de câbles testés *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nombreCablesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 1',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Champ obligatoire';
                          final numVal = int.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) return 'Saisir un entier valide';
                          return null;
                        },
                      ),

                      SizedBox(height: _spacingM),

                      // Isolement (MΩ)
                      Text(
                        _selectedAppreciation == 'Sans objet' ? 'Isolement (MΩ)' : 'Isolement (MΩ) *',
                        style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _isolementController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: _selectedAppreciation == 'Sans objet' ? 'Sans objet (0.0)' : 'Ex: 250.0',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          suffixText: 'MΩ',
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.speed, size: 20, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (_selectedAppreciation == 'Sans objet') return null;
                          if (val == null || val.trim().isEmpty) return 'Champ obligatoire';
                          final numVal = double.tryParse(val.trim().replaceAll(',', '.'));
                          if (numVal == null || numVal <= 0) return 'Saisir une valeur valide (ex: 250.0)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: _spacingL),

                // Card de l'Appréciation
                Container(
                  padding: EdgeInsets.all(_spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. Appréciation *',
                        style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAppreciationButton(
                              label: 'Satisfaisant',
                              icon: Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            SizedBox(width: _spacingS),
                            _buildAppreciationButton(
                              label: 'Non satisfaisant',
                              icon: Icons.cancel,
                              color: Colors.red,
                            ),
                            SizedBox(width: _spacingS),
                            _buildAppreciationButton(
                              label: 'Sans objet',
                              icon: Icons.remove_circle_outline,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: _spacingL * 1.5),

                // Boutons d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.isEdition ? 'Mettre à jour l\'essai' : 'Enregistrer l\'essai',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
