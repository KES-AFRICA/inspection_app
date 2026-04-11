import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

// ================================================================
// ÉCRAN PRINCIPAL : LISTE DES PRISES DE TERRE
// ================================================================

class PrisesTerreScreen extends StatefulWidget {
  final Mission mission;

  const PrisesTerreScreen({super.key, required this.mission});

  @override
  State<PrisesTerreScreen> createState() => _PrisesTerreScreenState();
}

class _PrisesTerreScreenState extends State<PrisesTerreScreen> {
  List<PriseTerre> _prisesTerre = [];
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
    _loadPrisesTerre();
  }

  Future<void> _loadPrisesTerre() async {
    setState(() => _isLoading = true);
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _prisesTerre = mesures.prisesTerre;
    } catch (e) {
      print('❌ Erreur chargement prises terre: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterPriseTerre() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterPriseTerreScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadPrisesTerre();
    }
  }

  void _editerPriseTerre(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterPriseTerreScreen(
          mission: widget.mission,
          priseTerre: _prisesTerre[index],
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadPrisesTerre();
    }
  }

  Future<void> _supprimerPriseTerre(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirmer la suppression', style: TextStyle(fontSize: _fontSizeM(context) + 2, fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment supprimer cette prise de terre ?', style: TextStyle(fontSize: _fontSizeM(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deletePriseTerre(
                missionId: widget.mission.id,
                index: index,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Prise de terre supprimée', style: TextStyle(fontSize: _fontSizeM(context))),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadPrisesTerre();
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

  // Extraire le résultat depuis l'observation
  String _extraireResultat(String? observation) {
    if (observation == null || observation.isEmpty) return 'Non défini';
    if (observation.contains('[Satisfaisant]')) return 'Satisfaisant';
    if (observation.contains('[Non satisfaisant]')) return 'Non satisfaisant';
    return 'Non défini';
  }

  // Extraire le texte libre depuis l'observation
  String _extraireTexteLibre(String? observation) {
    if (observation == null || observation.isEmpty) return '';
    if (observation.contains('[Satisfaisant]')) {
      return observation.replaceFirst('[Satisfaisant] ', '').replaceFirst('[Satisfaisant]', '');
    }
    if (observation.contains('[Non satisfaisant]')) {
      return observation.replaceFirst('[Non satisfaisant] ', '').replaceFirst('[Non satisfaisant]', '');
    }
    return observation;
  }

  Widget _buildPriseTerreCard(PriseTerre priseTerre, int index) {
    final context = this.context;
    final resultat = _extraireResultat(priseTerre.observation);
    final texteLibre = _extraireTexteLibre(priseTerre.observation);
    
    // Déterminer la couleur et le statut en fonction du résultat
    Color cardColor;
    Color statutColor;
    String statutText;
    IconData statutIcon;
    
    switch (resultat) {
      case 'Satisfaisant':
        cardColor = Colors.green;
        statutColor = Colors.green;
        statutText = 'SATISFAISANT';
        statutIcon = Icons.check_circle;
        break;
      case 'Non satisfaisant':
        cardColor = Colors.red;
        statutColor = Colors.red;
        statutText = 'NON SATISFAISANT';
        statutIcon = Icons.warning_rounded;
        break;
      default:
        cardColor = Colors.orange;
        statutColor = Colors.orange;
        statutText = 'NON DÉFINI';
        statutIcon = Icons.help_outline;
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
        onTap: () => _editerPriseTerre(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(_spacingL(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec identification et statut
              Row(
                children: [
                  // Badge d'identification
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _spacingM(context), vertical: _spacingS(context) * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.electrical_services, size: _iconSizeS(context), color: Colors.blue),
                        SizedBox(width: _spacingS(context)),
                        Text(
                          priseTerre.identification,
                          style: TextStyle(
                            fontSize: _fontSizeS(context),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Badge de statut
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
                  SizedBox(width: _spacingS(context)),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerPriseTerre(index);
                      } else if (value == 'delete') {
                        _supprimerPriseTerre(index);
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
              
              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: _iconSizeS(context) * 0.8, color: Colors.grey.shade500),
                  SizedBox(width: _spacingS(context) * 0.5),
                  Expanded(
                    child: Text(
                      priseTerre.localisation,
                      style: TextStyle(fontSize: _fontSizeM(context), fontWeight: FontWeight.w600, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: _spacingM(context)),
              
              // Détails
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
                            label: 'Nature',
                            value: priseTerre.naturePriseTerre,
                            icon: Icons.terrain,
                          ),
                        ),
                        SizedBox(width: _spacingM(context)),
                        Expanded(
                          child: _buildInfoChip(
                            context,
                            label: 'Méthode',
                            value: priseTerre.methodeMesure,
                            icon: Icons.science,
                          ),
                        ),
                      ],
                    ),
                    
                    if (priseTerre.conditionMesure.isNotEmpty && priseTerre.conditionMesure != '-') ...[
                      SizedBox(height: _spacingS(context)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              context,
                              label: 'Condition',
                              value: priseTerre.conditionMesure,
                              icon: Icons.tune,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (priseTerre.valeurMesure != null) ...[
                      SizedBox(height: _spacingM(context)),
                      Container(
                        padding: EdgeInsets.all(_spacingS(context)),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statutColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Valeur mesurée',
                              style: TextStyle(fontSize: _fontSizeM(context), fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                            ),
                            Text(
                              '${priseTerre.valeurMesure!.toStringAsFixed(2)} Ω',
                              style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.bold, color: statutColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Affichage du texte libre de l'observation
                    if (texteLibre.isNotEmpty) ...[
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
                              texteLibre,
                              style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade700),
                              maxLines: 3,
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
                  maxLines: 1,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Prises de terre', style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterPriseTerre,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        child: Icon(Icons.add, size: _iconSizeM(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prisesTerre.isEmpty
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
                        child: Icon(Icons.bolt_outlined, size: 48, color: Colors.blue.shade300),
                      ),
                      SizedBox(height: _spacingL(context)),
                      Text(
                        'Aucune prise de terre',
                        style: TextStyle(fontSize: _fontSizeL(context), fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: _spacingS(context)),
                      Text(
                        'Cliquez sur le + pour ajouter une prise de terre',
                        style: TextStyle(fontSize: _fontSizeM(context), color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPrisesTerre,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: _spacingS(context)),
                    itemCount: _prisesTerre.length,
                    itemBuilder: (context, index) {
                      return _buildPriseTerreCard(_prisesTerre[index], index);
                    },
                  ),
                ),
    );
  }
}

// ================================================================
// ÉCRAN POUR AJOUTER/MODIFIER UNE PRISE DE TERRE
// ================================================================

class AjouterPriseTerreScreen extends StatefulWidget {
  final Mission mission;
  final PriseTerre? priseTerre;
  final int? index;

  const AjouterPriseTerreScreen({
    super.key,
    required this.mission,
    this.priseTerre,
    this.index,
  });

  bool get isEdition => priseTerre != null;

  @override
  State<AjouterPriseTerreScreen> createState() => _AjouterPriseTerreScreenState();
}

class _AjouterPriseTerreScreenState extends State<AjouterPriseTerreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationController = TextEditingController();
  final _identificationController = TextEditingController();
  final _conditionController = TextEditingController();
  final _natureController = TextEditingController();
  final _methodeController = TextEditingController();
  final _valeurController = TextEditingController();
  final _observationLibreController = TextEditingController();
  
  String _selectedResultat = 'Satisfaisant';
  
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
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _natureController.text = 'Boucle en fond de fouille';
      _methodeController.text = 'Impédance de boucle';
      _conditionController.text = '-';
    }
  }

  void _chargerDonneesExistantes() {
    final pt = widget.priseTerre!;
    _localisationController.text = pt.localisation;
    _identificationController.text = pt.identification;
    _conditionController.text = pt.conditionMesure;
    _natureController.text = pt.naturePriseTerre;
    _methodeController.text = pt.methodeMesure;
    if (pt.valeurMesure != null) {
      _valeurController.text = pt.valeurMesure!.toString();
    }
    
    // Extraire le résultat et l'observation libre
    if (pt.observation != null && pt.observation!.isNotEmpty) {
      final observation = pt.observation!;
      if (observation.contains('[Satisfaisant]')) {
        _selectedResultat = 'Satisfaisant';
        _observationLibreController.text = observation.replaceFirst('[Satisfaisant] ', '');
      } else if (observation.contains('[Non satisfaisant]')) {
        _selectedResultat = 'Non satisfaisant';
        _observationLibreController.text = observation.replaceFirst('[Non satisfaisant] ', '');
      } else {
        _selectedResultat = 'Satisfaisant';
        _observationLibreController.text = observation;
      }
    }
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      // Construire l'observation complète avec le résultat
      final observationComplete = _observationLibreController.text.trim().isNotEmpty
          ? '[$_selectedResultat] ${_observationLibreController.text.trim()}'
          : '[$_selectedResultat]';
      
      final priseTerre = PriseTerre(
        localisation: _localisationController.text.trim(),
        identification: _identificationController.text.trim(),
        conditionMesure: _conditionController.text.trim(),
        naturePriseTerre: _natureController.text.trim(),
        methodeMesure: _methodeController.text.trim(),
        valeurMesure: _valeurController.text.trim().isNotEmpty 
            ? double.tryParse(_valeurController.text.trim())
            : null,
        observation: observationComplete,
      );

      bool success;
      if (widget.isEdition) {
        success = await HiveService.updatePriseTerre(
          missionId: widget.mission.id,
          index: widget.index!,
          priseTerre: priseTerre,
        );
      } else {
        success = await HiveService.addPriseTerre(
          missionId: widget.mission.id,
          priseTerre: priseTerre,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdition ? 'Prise de terre modifiée' : 'Prise de terre ajoutée', style: TextStyle(fontSize: _fontSizeM)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true, int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      margin: EdgeInsets.only(bottom: _spacingL),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _fontSizeM),
        decoration: InputDecoration(
          labelText: '${isRequired ? "$label*" : label}',
          labelStyle: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue, width: 2)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: _spacingM, vertical: _spacingM * 0.8),
        ),
        maxLines: maxLines,
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Obligatoire';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged, {bool isRequired = true}) {
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
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: value.isNotEmpty ? value : null,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_circle, size: _iconSizeS, color: Colors.grey.shade600),
              hint: Text('Sélectionner...', style: TextStyle(fontSize: _fontSizeM, color: Colors.grey.shade500)),
              style: TextStyle(fontSize: _fontSizeM, color: Colors.black87),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
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
                  label: 'Satisfaisant',
                  isSelected: _selectedResultat == 'Satisfaisant',
                  onTap: () => setState(() => _selectedResultat = 'Satisfaisant'),
                  color: Colors.green,
                ),
              ),
              SizedBox(width: _spacingM),
              Expanded(
                child: _buildResultatButton(
                  label: 'Non satisfaisant',
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
          title: Text(widget.isEdition ? 'Modifier prise terre' : 'Ajouter prise terre', style: TextStyle(fontSize: _fontSizeL, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, size: _iconSizeM), onPressed: _annuler),
          actions: [
            IconButton(icon: Icon(Icons.check, size: _iconSizeM), onPressed: _sauvegarder),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      _buildTextField('Localisation', _localisationController),
                      _buildTextField('Identification (PT1, PT2...)', _identificationController),
                      
                      if (!_isSmallScreen)
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Condition mesure', _conditionController)),
                          ],
                        )
                      else
                        _buildTextField('Condition mesure', _conditionController),
                      
                      _buildDropdown(
                        'Nature prise de terre',
                        HiveService.getNaturesPriseTerre(),
                        _natureController.text,
                        (value) {
                          if (value != null) {
                            setState(() => _natureController.text = value);
                          }
                        },
                      ),
                      
                      _buildDropdown(
                        'Méthode de mesure',
                        HiveService.getMethodesMesure(),
                        _methodeController.text,
                        (value) {
                          if (value != null) {
                            setState(() => _methodeController.text = value);
                          }
                        },
                      ),
                      
                      _buildTextField('Valeur mesurée (Ω)', _valeurController, isRequired: false, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      
                      _buildResultatSelector(),
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
      ),
    );
  }

  @override
  void dispose() {
    _localisationController.dispose();
    _identificationController.dispose();
    _conditionController.dispose();
    _natureController.dispose();
    _methodeController.dispose();
    _valeurController.dispose();
    _observationLibreController.dispose();
    super.dispose();
  }
}