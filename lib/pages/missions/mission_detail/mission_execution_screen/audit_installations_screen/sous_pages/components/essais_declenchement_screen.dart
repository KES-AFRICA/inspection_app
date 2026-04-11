import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

// ================================================================
// ÉCRAN PRINCIPAL : LISTE DES ESSAIS
// ================================================================

class EssaisDeclenchementScreen extends StatefulWidget {
  final Mission mission;

  const EssaisDeclenchementScreen({super.key, required this.mission});

  @override
  State<EssaisDeclenchementScreen> createState() => _EssaisDeclenchementScreenState();
}

class _EssaisDeclenchementScreenState extends State<EssaisDeclenchementScreen> {
  List<EssaiDeclenchementDifferentiel> _essais = [];
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
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _essais = mesures.essaisDeclenchement;
    } catch (e) {
      print('❌ Erreur chargement essais déclenchement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterEssai() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiDeclenchementScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadEssais();
    }
  }

  void _editerEssai(EssaiDeclenchementDifferentiel essai, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiDeclenchementScreen(
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
        title: Text('Confirmer la suppression', style: TextStyle(fontSize: _fontSizeM(context) + 2, fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment supprimer cet essai ?', style: TextStyle(fontSize: _fontSizeM(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deleteEssaiDeclenchement(
                missionId: widget.mission.id,
                index: index,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Essai supprimé', style: TextStyle(fontSize: _fontSizeM(context))),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadEssais();
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

  Widget _buildEssaiCard(EssaiDeclenchementDifferentiel essai, int index) {
    final context = this.context;
    Color cardColor;
    String statutText;
    IconData statutIcon;
    Color statutColor;
    
    switch (essai.essai) {
      case 'Satisfaisant':
      case 'OK':
        cardColor = Colors.green;
        statutText = 'SATISFAISANT';
        statutIcon = Icons.check_circle;
        statutColor = Colors.green;
        break;
      case 'Non satisfaisant':
      case 'NON OK':
        cardColor = Colors.red;
        statutText = 'NON SATISFAISANT';
        statutIcon = Icons.warning_rounded;
        statutColor = Colors.red;
        break;
      default:
        cardColor = Colors.orange;
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
              // En-tête avec statut
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _spacingM(context), vertical: _spacingS(context) * 0.5),
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
              
              // Circuit et localisation
              if (essai.designationCircuit != null && essai.designationCircuit!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: _spacingS(context)),
                  child: Text(
                    essai.designationCircuit!,
                    style: TextStyle(
                      fontSize: _fontSizeL(context),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: _iconSizeS(context) * 0.8, color: Colors.grey.shade500),
                  SizedBox(width: _spacingS(context) * 0.5),
                  Expanded(
                    child: Text(
                      essai.localisation,
                      style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              
              if (essai.coffret != null && essai.coffret!.isNotEmpty) ...[
                SizedBox(height: _spacingS(context) * 0.5),
                Row(
                  children: [
                    Icon(Icons.electrical_services, size: _iconSizeS(context) * 0.8, color: Colors.grey.shade500),
                    SizedBox(width: _spacingS(context) * 0.5),
                    Expanded(
                      child: Text(
                        essai.coffret!,
                        style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
              
              SizedBox(height: _spacingM(context)),
              
              // Paramètres techniques
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
                            label: 'Type',
                            value: essai.typeDispositif,
                            icon: Icons.devices_other,
                          ),
                        ),
                        SizedBox(width: _spacingM(context)),
                        if (essai.reglageIAn != null)
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              label: 'IΔn',
                              value: '${essai.reglageIAn} mA',
                              icon: Icons.settings,
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: _spacingS(context)),
                    
                    Row(
                      children: [
                        if (essai.tempo != null)
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              label: 'Tempo',
                              value: '${essai.tempo} s',
                              icon: Icons.timer,
                            ),
                          ),
                        SizedBox(width: _spacingM(context)),
                        if (essai.isolement != null)
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              label: 'Isolement',
                              value: '${essai.isolement} MΩ',
                              icon: Icons.insights,
                            ),
                          ),
                      ],
                    ),
                    
                    if (essai.observation != null && essai.observation!.isNotEmpty) ...[
                      SizedBox(height: _spacingM(context)),
                      const Divider(height: 1),
                      SizedBox(height: _spacingM(context)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: _iconSizeS(context) * 0.8, color: Colors.grey.shade500),
                          SizedBox(width: _spacingS(context)),
                          Expanded(
                            child: Text(
                              essai.observation!,
                              style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _spacingS(context), vertical: _spacingS(context) * 0.5),
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
                  style: TextStyle(fontSize: _fontSizeS(context), fontWeight: FontWeight.w500, color: Colors.black87),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Essais déclenchement', style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.w600)),
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
                          child: Icon(Icons.flash_on_outlined, size: 48, color: Colors.blue.shade300),
                        ),
                        SizedBox(height: _spacingL(context)),
                        Text(
                          'Aucun essai de déclenchement',
                          style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: _spacingS(context)),
                        Text(
                          'Cliquez sur le + pour ajouter un essai',
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
// ÉCRAN POUR AJOUTER/MODIFIER UN ESSAI
// ================================================================

class AjouterEssaiDeclenchementScreen extends StatefulWidget {
  final Mission mission;
  final EssaiDeclenchementDifferentiel? essai;
  final int? index;
  final String? localisationPredefinie;
  final String? coffretPredefini;

  const AjouterEssaiDeclenchementScreen({
    super.key,
    required this.mission,
    this.essai,
    this.index,
    this.localisationPredefinie,
    this.coffretPredefini,
  });

  bool get isEdition => essai != null;
  bool get aLocalisationPredefinie => localisationPredefinie != null && localisationPredefinie!.isNotEmpty;
  bool get aCoffretPredefini => coffretPredefini != null && coffretPredefini!.isNotEmpty;

  @override
  State<AjouterEssaiDeclenchementScreen> createState() => _AjouterEssaiDeclenchementScreenState();
}

class _AjouterEssaiDeclenchementScreenState extends State<AjouterEssaiDeclenchementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationController = TextEditingController();
  final _coffretController = TextEditingController();
  final _circuitController = TextEditingController();
  final _reglageController = TextEditingController();
  final _tempoController = TextEditingController();
  final _isolementController = TextEditingController();
  final _observationController = TextEditingController();
  
  String _selectedType = 'DDR';
  String _selectedResultat = 'Non satisfaisant';
  
  List<String> _localisations = [];
  List<String> _coffrets = [];
  
  bool _localisationValid = false;
  bool _circuitValid = false;
  bool _reglageValid = false;
  bool _tempoValid = false;
  bool _isolementValid = false;

  // Helpers responsifs
  double _rw() => MediaQuery.of(context).size.width;
  bool get _isSmallScreen => _rw() < 360;
  
  double get _fontSizeL => _isSmallScreen ? 15 : 16;
  double get _fontSizeM => _isSmallScreen ? 13 : 14;
  double get _fontSizeS => _isSmallScreen ? 12 : 13;
  double get _fontSizeXS => _isSmallScreen ? 11 : 12;
  double get _iconSizeM => _isSmallScreen ? 18 : 20;
  double get _iconSizeS => _isSmallScreen ? 14 : 16;
  double get _spacingL => _isSmallScreen ? 12 : 16;
  double get _spacingM => _isSmallScreen ? 10 : 12;
  double get _spacingS => _isSmallScreen ? 6 : 8;

  @override
  void initState() {
    super.initState();
    
    if (widget.aCoffretPredefini) {
      _coffretController.text = widget.coffretPredefini!;
    }
    
    _chargerLocalisations();
    
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      if (widget.aLocalisationPredefinie) {
        _localisationController.text = widget.localisationPredefinie!;
        _localisationValid = true;
        _updateCoffretsForLocalisation(widget.localisationPredefinie!);
      }
    }
  }

  void _chargerLocalisations() {
    _localisations = HiveService.getLocalisationsForEssais(widget.mission.id);
    if (_localisations.isEmpty) {
      _localisations = ['Local technique', 'TGBT', 'Tableau divisionnaire'];
    }
    
    if (_localisationController.text.isNotEmpty && !_localisations.contains(_localisationController.text)) {
      _localisations.add(_localisationController.text);
    }
  }

  void _updateCoffretsForLocalisation(String localisation) {
    _coffrets = HiveService.getCoffretsForLocalisation(widget.mission.id, localisation);
    
    // Si un seul coffret, le sélectionner automatiquement
    if (_coffrets.length == 1) {
      _coffretController.text = _coffrets.first;
    } else if (widget.aCoffretPredefini && !_coffrets.contains(widget.coffretPredefini)) {
      _coffrets.add(widget.coffretPredefini!);
    }
  }

  void _chargerDonneesExistantes() {
    final essai = widget.essai!;
    
    _chargerLocalisations();
    
    _localisationController.text = essai.localisation;
    _localisationValid = essai.localisation.isNotEmpty;
    
    _updateCoffretsForLocalisation(essai.localisation);
    
    if (essai.coffret != null && essai.coffret!.isNotEmpty) {
      _coffretController.text = essai.coffret!;
      if (!_coffrets.contains(essai.coffret)) {
        _coffrets.add(essai.coffret!);
      }
    }
    
    _circuitController.text = essai.designationCircuit ?? '';
    _circuitValid = essai.designationCircuit != null && essai.designationCircuit!.isNotEmpty;
    
    _selectedType = essai.typeDispositif;
    
    if (essai.reglageIAn != null) {
      _reglageController.text = essai.reglageIAn!.toString();
      _reglageValid = true;
    }
    
    if (essai.tempo != null) {
      _tempoController.text = essai.tempo!.toString();
      _tempoValid = true;
    }
    
    if (essai.isolement != null) {
      _isolementController.text = essai.isolement!.toString();
      _isolementValid = true;
    }
    
    _selectedResultat = (essai.essai == 'OK' || essai.essai == 'Satisfaisant') ? 'Satisfaisant' : 'Non satisfaisant';
    
    if (essai.observation != null) {
      _observationController.text = essai.observation!;
    }
  }

  void _validateLocalisation(String value) => setState(() => _localisationValid = value.trim().isNotEmpty);
  void _validateCircuit(String value) => setState(() => _circuitValid = value.trim().isNotEmpty);
  void _validateReglage(String value) => setState(() => _reglageValid = value.trim().isNotEmpty);
  void _validateTempo(String value) => setState(() => _tempoValid = value.trim().isNotEmpty);
  void _validateIsolement(String value) => setState(() => _isolementValid = value.trim().isNotEmpty);

  bool _validateAllFields() {
    bool allValid = true;
    if (_localisationController.text.trim().isEmpty) { _localisationValid = false; allValid = false; }
    if (_circuitController.text.trim().isEmpty) { _circuitValid = false; allValid = false; }
    if (_reglageController.text.trim().isEmpty) { _reglageValid = false; allValid = false; }
    if (_tempoController.text.trim().isEmpty) { _tempoValid = false; allValid = false; }
    if (_isolementController.text.trim().isEmpty) { _isolementValid = false; allValid = false; }
    setState(() {});
    return allValid;
  }

  void _onLocalisationChanged(String? value) {
    if (value != null) {
      setState(() {
        _localisationController.text = value;
        _validateLocalisation(value);
        _updateCoffretsForLocalisation(value);
      });
    }
  }

  Widget _buildCoffretField() {
    // Cas où le coffret est prédéfini (depuis l'ajout d'un coffret)
    if (widget.aCoffretPredefini) {
      return Container(
        margin: EdgeInsets.only(bottom: _spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coffret', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            SizedBox(height: _spacingS * 0.5),
            Container(
              padding: EdgeInsets.symmetric(horizontal: _spacingM, vertical: _spacingM * 0.8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.electrical_services, size: _iconSizeS, color: Colors.grey.shade600),
                  SizedBox(width: _spacingS),
                  Expanded(
                    child: Text(
                      _coffretController.text,
                      style: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tooltip(
                    message: 'Coffret défini automatiquement',
                    child: Icon(Icons.info_outline, size: _iconSizeS, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Déterminer le hint en fonction du nombre de coffrets
    String hintText;
    if (_localisationController.text.isEmpty) {
      hintText = 'Sélectionnez d\'abord une localisation';
    } else if (_coffrets.isEmpty) {
      hintText = 'Aucun coffret disponible';
    } else {
      hintText = 'Sélectionnez un coffret';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: _spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coffret', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          SizedBox(height: _spacingS * 0.5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _spacingM),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _coffretController.text.isNotEmpty && _coffrets.contains(_coffretController.text) ? _coffretController.text : null,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_circle, size: _iconSizeS, color: Colors.grey.shade600),
              hint: Text(
                hintText,
                style: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade500),
                overflow: TextOverflow.ellipsis,
              ),
              style: TextStyle(fontSize: _fontSizeM, color: Colors.black87),
              items: _coffrets.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _coffrets.isEmpty ? null : (value) {
                if (value != null) {
                  setState(() {
                    _coffretController.text = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sauvegarder() async {
    if (!_validateAllFields()) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    final essaiValue = _selectedResultat == 'Satisfaisant' ? 'OK' : 'NON OK';

    final essai = EssaiDeclenchementDifferentiel(
      localisation: _localisationController.text.trim(),
      coffret: _coffretController.text.trim().isNotEmpty ? _coffretController.text.trim() : null,
      designationCircuit: _circuitController.text.trim(),
      typeDispositif: _selectedType,
      reglageIAn: double.tryParse(_reglageController.text.trim()),
      tempo: double.tryParse(_tempoController.text.trim()),
      isolement: double.tryParse(_isolementController.text.trim()),
      essai: essaiValue,
      observation: _observationController.text.trim().isNotEmpty ? _observationController.text.trim() : null,
    );

    bool success;
    if (widget.isEdition) {
      success = await HiveService.updateEssaiDeclenchement(
        missionId: widget.mission.id,
        index: widget.index!,
        essai: essai,
      );
    } else {
      success = await HiveService.addEssaiDeclenchement(
        missionId: widget.mission.id,
        essai: essai,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEdition ? 'Essai modifié' : 'Essai ajouté', style: TextStyle(fontSize: _fontSizeM)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showError('Erreur lors de la sauvegarde');
    }
  }

  void _annuler() => Navigator.pop(context);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: _fontSizeM)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true, int maxLines = 1, TextInputType? keyboardType, Function(String)? onChanged}) {
    bool isValid = true;
    
    if (isRequired) {
      if (label.contains('Localisation')) isValid = _localisationValid;
      else if (label.contains('Circuit')) isValid = _circuitValid;
      else if (label.contains('Réglage')) isValid = _reglageValid;
      else if (label.contains('Temporisation')) isValid = _tempoValid;
      else if (label.contains('Isolement')) isValid = _isolementValid;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: _spacingL),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _fontSizeM),
        onChanged: (value) {
          if (onChanged != null) onChanged(value);
          if (isRequired) {
            if (label.contains('Localisation')) _validateLocalisation(value);
            else if (label.contains('Circuit')) _validateCircuit(value);
            else if (label.contains('Réglage')) _validateReglage(value);
            else if (label.contains('Temporisation')) _validateTempo(value);
            else if (label.contains('Isolement')) _validateIsolement(value);
          }
        },
        decoration: InputDecoration(
          labelText: '${isRequired ? "$label*" : label}',
          labelStyle: TextStyle(fontSize: _fontSizeM, color: isValid ? Colors.grey.shade600 : Colors.red),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isValid ? Colors.grey.shade300 : Colors.red)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isValid ? Colors.grey.shade300 : Colors.red)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isValid ? Colors.blue : Colors.red, width: 2)),
          errorText: !isValid && isRequired ? 'Obligatoire' : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: _spacingM, vertical: _spacingM * 0.8),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged, {bool isValid = true, bool isRequired = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: _spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label*' : label,
            style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
          SizedBox(height: _spacingS * 0.5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: _spacingM),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isValid ? Colors.grey.shade300 : Colors.red),
            ),
            child: DropdownButton<String>(
              value: value.isNotEmpty && options.contains(value) ? value : null,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_circle, size: _iconSizeS, color: Colors.grey.shade600),
              hint: Text('Sélectionner...', style: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade500)),
              style: TextStyle(fontSize: _fontSizeM, color: Colors.black87),
              items: options.where((o) => o.isNotEmpty).map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          if (!isValid && isRequired)
            Padding(
              padding: EdgeInsets.only(top: _spacingS * 0.5),
              child: Text('Obligatoire', style: TextStyle(color: Colors.red, fontSize: _fontSizeXS)),
            ),
        ],
      ),
    );
  }

  Widget _buildResultatSelector() {
    return Container(
      margin: EdgeInsets.only(bottom: _spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Résultat de l\'essai*', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          SizedBox(height: _spacingS),
          Row(
            children: [
              Expanded(
                child: _buildResultatButton(
                  label: 'S',
                  isSelected: _selectedResultat == 'Satisfaisant',
                  onTap: () => setState(() => _selectedResultat = 'Satisfaisant'),
                  color: Colors.green,
                ),
              ),
              SizedBox(width: _spacingM),
              Expanded(
                child: _buildResultatButton(
                  label: 'Ns',
                  isSelected: _selectedResultat == 'Non satisfaisant',
                  onTap: () => setState(() => _selectedResultat = 'Non satisfaisant'),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultatButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: _spacingM * 0.8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Satisfaisant' ? Icons.check_circle : Icons.warning_rounded,
              size: _iconSizeS,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            SizedBox(width: _spacingS),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: _fontSizeS, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.isEdition ? 'Modifier essai' : 'Ajouter essai', style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, size: _iconSizeM), onPressed: _annuler),
          actions: [
            IconButton(icon: Icon(Icons.check, size: _iconSizeM), onPressed: _sauvegarder),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(_spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(_spacingM),
                margin: EdgeInsets.only(bottom: _spacingL),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: _iconSizeS),
                    SizedBox(width: _spacingS),
                    Expanded(
                      child: Text(
                        'TOUS LES CHAMPS MARQUÉS * SONT OBLIGATOIRES',
                        style: TextStyle(fontSize: _fontSizeS, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
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
                  children: [
                    _buildDropdown(
                      'Localisation',
                      _localisations,
                      _localisationController.text.isNotEmpty ? _localisationController.text : (_localisations.isNotEmpty ? _localisations.first : ''),
                      _onLocalisationChanged,
                      isValid: _localisationValid,
                      isRequired: true,
                    ),
                    _buildCoffretField(),
                    _buildTextField('Désignation du circuit', _circuitController, isRequired: true, onChanged: _validateCircuit),
                    
                    // Type et Résultat sur la même ligne si écran assez large
                    if (!_isSmallScreen)
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              'Type de dispositif',
                              HiveService.getTypesDispositifDifferentiel(),
                              _selectedType,
                              (v) => setState(() => _selectedType = v!),
                              isRequired: true,
                            ),
                          ),
                          SizedBox(width: _spacingL),
                          Expanded(child: _buildResultatSelector()),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildDropdown(
                            'Type de dispositif',
                            HiveService.getTypesDispositifDifferentiel(),
                            _selectedType,
                            (v) => setState(() => _selectedType = v!),
                            isRequired: true,
                          ),
                          _buildResultatSelector(),
                        ],
                      ),
                    
                    // Réglage et Temporisation
                    if (!_isSmallScreen)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Réglage IΔn (mA)',
                              _reglageController,
                              isRequired: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: _validateReglage,
                            ),
                          ),
                          SizedBox(width: _spacingL),
                          Expanded(
                            child: _buildTextField(
                              'Temporisation (s)',
                              _tempoController,
                              isRequired: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: _validateTempo,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTextField(
                            'Réglage IΔn (mA)',
                            _reglageController,
                            isRequired: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _validateReglage,
                          ),
                          _buildTextField(
                            'Temporisation (s)',
                            _tempoController,
                            isRequired: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _validateTempo,
                          ),
                        ],
                      ),
                    
                    _buildTextField(
                      'Isolement (MΩ)',
                      _isolementController,
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _validateIsolement,
                    ),
                    _buildTextField('Observation', _observationController, isRequired: false, maxLines: 3),
                  ],
                ),
              ),
              
              SizedBox(height: _spacingL),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: _spacingM),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      child: Text(widget.isEdition ? 'MODIFIER' : 'AJOUTER', style: TextStyle(fontSize: _fontSizeM, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: _spacingM),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _annuler,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: _spacingM),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('ANNULER', style: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade600)),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: _spacingL),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localisationController.dispose();
    _coffretController.dispose();
    _circuitController.dispose();
    _reglageController.dispose();
    _tempoController.dispose();
    _isolementController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}