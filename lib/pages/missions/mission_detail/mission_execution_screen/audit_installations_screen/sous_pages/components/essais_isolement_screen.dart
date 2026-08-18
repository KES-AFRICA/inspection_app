import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';

const List<String> kSectionCableOptions = [
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
        statutText = 'SATISFAISANT';
        statutIcon = Icons.check_circle;
        statutColor = Colors.green;
        break;
      case 'Non satisfaisant':
        statutText = 'NON SATISFAISANT';
        statutIcon = Icons.warning_rounded;
        statutColor = Colors.red;
        break;
      case 'Sans objet':
        statutText = 'SANS OBJET';
        statutIcon = Icons.remove_circle_outline;
        statutColor = Colors.grey;
        break;
      default:
        statutText = 'NON DÉFINI';
        statutIcon = Icons.help_outline;
        statutColor = Colors.orange;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: _spacingL(context), vertical: _spacingS(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statutColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editerEssai(essai, index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(_spacingL(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut & Menu ⋮
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _spacingM(context),
                      vertical: _spacingS(context) * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statutIcon, size: _iconSizeS(context), color: statutColor),
                        SizedBox(width: _spacingS(context)),
                        Text(
                          statutText,
                          style: TextStyle(
                            fontSize: _fontSizeXS(context),
                            fontWeight: FontWeight.bold,
                            color: statutColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerEssai(essai, index);
                      } else if (value == 'delete') {
                        _supprimerEssai(index);
                      }
                    },
                    icon: Icon(Icons.more_vert, size: _iconSizeM(context), color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: _iconSizeS(context), color: AppTheme.primaryBlue),
                            SizedBox(width: _spacingS(context)),
                            Text('Modifier', style: TextStyle(fontSize: _fontSizeM(context))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: _iconSizeS(context), color: Colors.red),
                            SizedBox(width: _spacingS(context)),
                            Text('Supprimer', style: TextStyle(fontSize: _fontSizeM(context))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: _spacingM(context)),

              // Repère d'origine
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: _iconSizeS(context) * 0.9, color: Colors.grey.shade600),
                  SizedBox(width: _spacingS(context) * 0.5),
                  Expanded(
                    child: Text(
                      'Origine : ${essai.displayRepereOrigine}',
                      style: TextStyle(
                        fontSize: _fontSizeL(context),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              SizedBox(height: _spacingS(context)),

              // Tronçon : Point A -> Point B
              Row(
                children: [
                  Icon(Icons.compare_arrows, size: _iconSizeS(context) * 0.9, color: AppTheme.primaryBlue),
                  SizedBox(width: _spacingS(context) * 0.5),
                  Expanded(
                    child: Text(
                      '${essai.displayPointA} ➔ ${essai.displayPointB}',
                      style: TextStyle(
                        fontSize: _fontSizeM(context),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              SizedBox(height: _spacingM(context)),

              // Grille de paramètres techniques
              Container(
                padding: EdgeInsets.all(_spacingM(context)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            label: 'Section',
                            value: essai.displaySection,
                            icon: Icons.line_weight,
                          ),
                        ),
                        SizedBox(width: _spacingM(context)),
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            label: 'Nb câbles',
                            value: essai.displayNombreCables,
                            icon: Icons.tag,
                          ),
                        ),
                        SizedBox(width: _spacingM(context)),
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            label: 'Isolement',
                            value: '${essai.isolement} MΩ',
                            icon: Icons.speed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _spacingS(context),
        vertical: _spacingS(context) * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: _iconSizeS(context) * 0.8, color: AppTheme.primaryBlue.withOpacity(0.7)),
          SizedBox(width: _spacingS(context) * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: _fontSizeXS(context), color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _fontSizeS(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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

  String? _selectedRepereOrigine;
  String? _selectedPointA;
  String? _selectedPointB;
  String? _selectedSectionCable;

  final _nombreCablesController = TextEditingController();
  final _isolementController = TextEditingController();

  String? _selectedAppreciation;

  List<String> _localisations = [];
  List<String> _equipementsOriginals = [];
  List<String> _equipementsPointB = [];

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
    _chargerLocalisations();

    if (widget.isEdition) {
      _chargerDonneesExistantes();
    }
  }

  @override
  void dispose() {
    _nombreCablesController.dispose();
    _isolementController.dispose();
    super.dispose();
  }

  void _chargerLocalisations() {
    _localisations = HiveService.getLocalisationsForEssais(widget.mission.id);
    if (_localisations.isEmpty) {
      _localisations = ['Local technique', 'TGBT', 'Tableau divisionnaire', 'Zone principale'];
    }
  }

  void _onRepereOrigineChanged(String? newValue) {
    setState(() {
      _selectedRepereOrigine = newValue;
      _selectedPointA = null;
      _selectedPointB = null;

      if (newValue != null && newValue.isNotEmpty) {
        _equipementsOriginals = HiveService.getEquipementsForLocalisation(widget.mission.id, newValue);
      } else {
        _equipementsOriginals = [];
      }
      _equipementsPointB = [];
    });
  }

  void _onPointAChanged(String? newValue) {
    setState(() {
      _selectedPointA = newValue;
      if (newValue != null && newValue == _selectedPointB) {
        _selectedPointB = null;
      }
      _equipementsPointB = _equipementsOriginals.where((eq) => eq != newValue).toList();
    });
  }

  void _chargerDonneesExistantes() {
    final essai = widget.essai!;
    _selectedRepereOrigine = essai.reperePointOrigine ?? essai.localisation;

    if (_selectedRepereOrigine != null && _selectedRepereOrigine!.isNotEmpty) {
      if (!_localisations.contains(_selectedRepereOrigine)) {
        _localisations.add(_selectedRepereOrigine!);
      }
      _equipementsOriginals = HiveService.getEquipementsForLocalisation(widget.mission.id, _selectedRepereOrigine!);
    }

    _selectedPointA = essai.pointA ?? essai.designation ?? essai.pointControle;
    if (_selectedPointA != null && _selectedPointA!.isNotEmpty && !_equipementsOriginals.contains(_selectedPointA)) {
      _equipementsOriginals.add(_selectedPointA!);
    }

    _selectedPointB = essai.pointB;
    _equipementsPointB = _equipementsOriginals.where((eq) => eq != _selectedPointA).toList();
    if (_selectedPointB != null && _selectedPointB!.isNotEmpty && !_equipementsPointB.contains(_selectedPointB)) {
      _equipementsPointB.add(_selectedPointB!);
    }

    _selectedSectionCable = essai.sectionCable;
    if (_selectedSectionCable != null && !kSectionCableOptions.contains(_selectedSectionCable)) {
      // Intégrer la valeur custom si elle n'existait pas dans la liste
      kSectionCableOptions.contains(_selectedSectionCable);
    }

    _nombreCablesController.text = essai.nombreCablesTestes != null ? essai.nombreCablesTestes.toString() : '';
    _isolementController.text = essai.isolement > 0 ? essai.isolement.toString() : '';
    _selectedAppreciation = essai.appreciation.isNotEmpty ? essai.appreciation : null;
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedRepereOrigine == null || _selectedRepereOrigine!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner le Repère du point d\'origine.');
      return;
    }

    if (_selectedPointA == null || _selectedPointA!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner le Point A (origine).');
      return;
    }

    if (_selectedPointB == null || _selectedPointB!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner le Point B (extrémité).');
      return;
    }

    if (_selectedSectionCable == null || _selectedSectionCable!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner la Section du câble.');
      return;
    }

    final nbCables = int.tryParse(_nombreCablesController.text.trim());
    if (nbCables == null || nbCables <= 0) {
      _showErrorSnackBar('Veuillez saisir un nombre valide de câbles testés.');
      return;
    }

    final isoValue = double.tryParse(_isolementController.text.trim().replaceAll(',', '.'));
    if (isoValue == null || isoValue <= 0) {
      _showErrorSnackBar('Veuillez saisir une valeur d\'isolement valide (MΩ).');
      return;
    }

    if (_selectedAppreciation == null || _selectedAppreciation!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner une appréciation.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();

      final essai = EssaiIsolement(
        syncId: widget.essai?.syncId ?? 'iso_${DateTime.now().microsecondsSinceEpoch}',
        equipmentSyncId: _selectedPointA,
        pointControle: 'De $_selectedPointA vers $_selectedPointB',
        isolement: isoValue,
        appreciation: _selectedAppreciation!,
        localisation: _selectedRepereOrigine,
        designation: _selectedPointA,
        reperePointOrigine: _selectedRepereOrigine,
        pointA: _selectedPointA,
        pointB: _selectedPointB,
        sectionCable: _selectedSectionCable,
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
    return Scaffold(
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
              // Card de sélection de la localisation & des points A/B
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
                      '1. Repère & Tronçon',
                      style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                    ),
                    const Divider(height: 20),

                    // Repère du point d'origine (Select)
                    Text('Repère du point d\'origine *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedRepereOrigine,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Sélectionner le local ou la zone',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _localisations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc,
                          child: Text(loc, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _onRepereOrigineChanged,
                    ),

                    SizedBox(height: _spacingM),

                    // Point A (origine)
                    Text('Point A (origine) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedPointA,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _selectedRepereOrigine == null
                            ? 'Veuillez d\'abord choisir l\'origine'
                            : 'Sélectionner l\'équipement d\'origine',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.flash_on, size: 20, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _equipementsOriginals.map((eq) {
                        return DropdownMenuItem<String>(
                          value: eq,
                          child: Text(eq, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _selectedRepereOrigine != null ? _onPointAChanged : null,
                    ),

                    SizedBox(height: _spacingM),

                    // Point B (extrémité) - exclut Point A
                    Text('Point B (extrémité) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedPointB,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _selectedPointA == null
                            ? 'Veuillez d\'abord choisir le Point A'
                            : 'Sélectionner l\'équipement d\'extrémité',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.double_arrow, size: 20, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _equipementsPointB.map((eq) {
                        return DropdownMenuItem<String>(
                          value: eq,
                          child: Text(eq, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _selectedPointA != null
                          ? (v) => setState(() => _selectedPointB = v)
                          : null,
                    ),
                  ],
                ),
              ),

              SizedBox(height: _spacingL),

              // Card des Caractéristiques du câble et de la mesure
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
                      '2. Câble & Mesure',
                      style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                    ),
                    const Divider(height: 20),

                    // Section du câble
                    Text('Section du câble (mm²) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSectionCable,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Choisir la section du câble',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.line_weight, size: 20, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: kSectionCableOptions.map((sec) {
                        return DropdownMenuItem<String>(
                          value: sec,
                          child: Text(sec),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSectionCable = v),
                    ),

                    SizedBox(height: _spacingM),

                    // Nombre de câbles testés
                    Text('Nombre de câbles testés *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nombreCablesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 1, 3, 4',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.tag, size: 20, color: Colors.blue),
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
                    Text('Isolement (MΩ) *', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _isolementController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Ex: 250.0 ou 500',
                        suffixText: 'MΩ',
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.speed, size: 20, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
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
                    Row(
                      children: [
                        _buildAppreciationButton(
                          label: 'Satisfaisant',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        SizedBox(width: _spacingS),
                        _buildAppreciationButton(
                          label: 'Non satisfaisant',
                          icon: Icons.warning_rounded,
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
    );
  }
}
