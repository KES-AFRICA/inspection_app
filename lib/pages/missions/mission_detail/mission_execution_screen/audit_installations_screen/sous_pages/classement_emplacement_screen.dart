// classement_emplacement_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ClassementEmplacementScreen extends StatefulWidget {
  final Mission mission;
  final ClassementEmplacement emplacement;

  const ClassementEmplacementScreen({
    super.key,
    required this.mission,
    required this.emplacement,
  });

  @override
  State<ClassementEmplacementScreen> createState() => _ClassementEmplacementScreenState();
}

class _ClassementEmplacementScreenState extends State<ClassementEmplacementScreen> {
  late ClassementEmplacement _emplacement;
  final _origineController = TextEditingController();

  bool _isLoading = false;
  
  bool _origineValid = false;
  bool _afValid = false;
  bool _beValid = false;
  bool _aeValid = false;
  bool _adValid = false;
  bool _agValid = false;

  bool get _estEnHeritage => _emplacement.heriteDeZone && _emplacement.zoneParenteId != null;

  String? get _afEffective => _emplacement.afEffective;
  String? get _beEffective => _emplacement.beEffective;
  String? get _aeEffective => _emplacement.aeEffective;
  String? get _adEffective => _emplacement.adEffective;
  String? get _agEffective => _emplacement.agEffective;
  String? get _ipEffective => _emplacement.ipEffective;
  String? get _ikEffective => _emplacement.ikEffective;

  // Helper methods pour la responsivité
  double _getResponsiveFontSize(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.8;
    if (width < 600) return baseSize * 0.9;
    return baseSize;
  }

  double _getResponsiveSpacing(double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSpacing * 0.7;
    if (width < 600) return baseSpacing * 0.85;
    return baseSpacing;
  }

  double _getResponsiveIconSize(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.8;
    if (width < 600) return baseSize * 0.9;
    return baseSize;
  }

  @override
  void initState() {
    super.initState();
    _emplacement = widget.emplacement;
    _origineController.text = _emplacement.origineClassement;
    
    // Utiliser les valeurs EFFECTIVES pour la validation
    _origineValid = _emplacement.origineClassement.isNotEmpty;
    _afValid = _afEffective != null && _afEffective!.isNotEmpty;
    _beValid = _beEffective != null && _beEffective!.isNotEmpty;
    _aeValid = _aeEffective != null && _aeEffective!.isNotEmpty;
    _adValid = _adEffective != null && _adEffective!.isNotEmpty;
    _agValid = _agEffective != null && _agEffective!.isNotEmpty;
  }

  @override
  void dispose() {
    _origineController.dispose();
    super.dispose();
  }

  void _validateOrigine(String value) => setState(() => _origineValid = value.trim().isNotEmpty);
  void _validateAF(String? value) => setState(() => _afValid = value != null && value.isNotEmpty);
  void _validateBE(String? value) => setState(() => _beValid = value != null && value.isNotEmpty);
  void _validateAE(String? value) => setState(() => _aeValid = value != null && value.isNotEmpty);
  void _validateAD(String? value) => setState(() => _adValid = value != null && value.isNotEmpty);
  void _validateAG(String? value) => setState(() => _agValid = value != null && value.isNotEmpty);

  bool _validateAllFields() {
    bool allValid = true;
    if (_origineController.text.trim().isEmpty) { _origineValid = false; allValid = false; }
    if (_emplacement.af == null || _emplacement.af!.isEmpty) { _afValid = false; allValid = false; }
    if (_emplacement.be == null || _emplacement.be!.isEmpty) { _beValid = false; allValid = false; }
    if (_emplacement.ae == null || _emplacement.ae!.isEmpty) { _aeValid = false; allValid = false; }
    if (_emplacement.ad == null || _emplacement.ad!.isEmpty) { _adValid = false; allValid = false; }
    if (_emplacement.ag == null || _emplacement.ag!.isEmpty) { _agValid = false; allValid = false; }
    setState(() {});
    return allValid;
  }

  void _sauvegarder() async {
    if (!_validateAllFields()) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires', Colors.red);
      return;
    }

    _emplacement.origineClassement = _origineController.text.trim();
    _emplacement.calculerIndices();
    
    final success = await HiveService.updateEmplacement(_emplacement);
    
    if (success) {
      _showSnackBar('Classement sauvegardé', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Erreur lors de la sauvegarde', Colors.red);
    }
  }


  void _annuler() => Navigator.pop(context, false);

  Widget _buildSelecteur(String title, String? currentValue, List<String> options, Function(String?) onChanged, {required bool isValid}) {
    final titleFontSize = _getResponsiveFontSize(15);
    final optionFontSize = _getResponsiveFontSize(13);
    final spacing = _getResponsiveSpacing(12);
    final iconSize = _getResponsiveIconSize(18);
    
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isValid ? Colors.grey.shade300 : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title*',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: isValid ? AppTheme.darkBlue : Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!isValid)
                Container(
                  margin: EdgeInsets.only(left: spacing * 0.5),
                  padding: EdgeInsets.symmetric(horizontal: spacing * 0.6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Obligatoire',
                    style: TextStyle(fontSize: optionFontSize * 0.8, color: Colors.red),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing * 0.6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isValid ? Colors.grey.shade300 : Colors.red.shade300),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: currentValue,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_circle, size: iconSize, color: isValid ? AppTheme.primaryBlue : Colors.red),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: Text(
                'Sélectionnez',
                style: TextStyle(fontSize: optionFontSize, color: Colors.grey.shade500),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.8),
              ),
              style: TextStyle(fontSize: optionFontSize, color: Colors.black87),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(fontSize: optionFontSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                onChanged(value);
                switch (title) {
                  case 'AF - Substances corrosives ou polluantes*': _validateAF(value); break;
                  case 'BE - Matières traitées ou entreposées*': _validateBE(value); break;
                  case 'AE - Pénétration de corps solides*': _validateAE(value); break;
                  case 'AD - Pénétration de liquides*': _validateAD(value); break;
                  case 'AG - Risques de chocs mécaniques*': _validateAG(value); break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final titleFontSize = _getResponsiveFontSize(20);
    final subtitleFontSize = _getResponsiveFontSize(16);
    final bodyFontSize = _getResponsiveFontSize(14);
    final spacing = _getResponsiveSpacing(16);
    final iconSize = _getResponsiveIconSize(24);
    final smallIconSize = _getResponsiveIconSize(18);

    final estComplet = _afEffective != null && _beEffective != null && 
                       _aeEffective != null && _adEffective != null && _agEffective != null;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Classement: ${_emplacement.localisation}',
          style: TextStyle(fontSize: subtitleFontSize),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: smallIconSize),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          // Si c'est un local qui hérite, on propose de passer en spécifique
          if (_estEnHeritage)
            IconButton(
              icon: Icon(Icons.link_off, size: smallIconSize),
              onPressed: _passerEnClassementSpecifique,
              tooltip: 'Passer en classement spécifique',
            )
          else if (!_estEnHeritage)
            IconButton(
              icon: Icon(Icons.check, size: smallIconSize),
              onPressed: _sauvegarder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message d'avertissement (seulement si pas en héritage)
            if (!_estEnHeritage)
              Container(
                padding: EdgeInsets.all(spacing * 0.8),
                margin: EdgeInsets.only(bottom: spacing),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: smallIconSize),
                    SizedBox(width: spacing * 0.6),
                    Expanded(
                      child: Text(
                        'TOUS LES CHAMPS SONT OBLIGATOIRES',
                        style: TextStyle(
                          fontSize: bodyFontSize * 0.9,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Bannière "Héritage" si applicable
            if (_estEnHeritage)
              Container(
                padding: EdgeInsets.all(spacing),
                margin: EdgeInsets.only(bottom: spacing),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue, size: iconSize * 0.8),
                    SizedBox(width: spacing * 0.6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classement hérité de la zone',
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            'Les valeurs ci-dessous proviennent de la zone "${_emplacement.zone}"',
                            style: TextStyle(
                              fontSize: bodyFontSize * 0.85,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // En-tête avec informations
            Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconSize * 1.8,
                    height: iconSize * 1.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _emplacement.isLocal ? Icons.location_on : Icons.map_outlined,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: spacing * 0.8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _emplacement.localisation,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        if (_emplacement.zone != null) ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.place, size: smallIconSize * 0.7, color: Colors.grey.shade600),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Zone: ${_emplacement.zone}',
                                  style: TextStyle(fontSize: bodyFontSize * 0.9, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_emplacement.typeLocal != null) ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category, size: smallIconSize * 0.7, color: Colors.grey.shade600),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Type: ${_emplacement.typeLocal}',
                                  style: TextStyle(fontSize: bodyFontSize * 0.9, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Badge de statut
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: estComplet ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estComplet ? 'Classement complet' : 'Classement incomplet',
                            style: TextStyle(
                              fontSize: bodyFontSize * 0.75,
                              fontWeight: FontWeight.w600,
                              color: estComplet ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacing * 1.2),
            
            // Origine classement
            Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
                border: Border.all(color: _origineValid ? Colors.grey.shade200 : Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Origine du classement',
                          style: TextStyle(
                            fontSize: subtitleFontSize * 0.9,
                            fontWeight: FontWeight.w600,
                            color: _origineValid ? AppTheme.darkBlue : Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_estEnHeritage) Text(' *', style: TextStyle(fontSize: subtitleFontSize * 0.9, color: Colors.red)),
                    ],
                  ),
                  SizedBox(height: spacing * 0.6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _estEnHeritage ? Colors.blue.shade200 : (_origineValid ? Colors.grey.shade300 : Colors.red.shade300)),
                    ),
                    child: TextFormField(
                      controller: _origineController,
                      onChanged: _estEnHeritage ? null : _validateOrigine,
                      enabled: !_estEnHeritage,
                      style: TextStyle(fontSize: bodyFontSize, color: _estEnHeritage ? Colors.grey.shade700 : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Ex: KES I&P',
                        hintStyle: TextStyle(fontSize: bodyFontSize, color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacing * 1.2),
            
            // Titre section influences
            Container(
              padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: iconSize * 0.8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: spacing * 0.6),
                  Expanded(
                    child: Text(
                      'INFLUENCES EXTERNES',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Affichage des influences (lecture seule si héritage)
            if (_estEnHeritage) ...[
              _buildReadOnlySelecteur(
                'AF - Substances corrosives ou polluantes',
                _afEffective,
              ),
              _buildReadOnlySelecteur(
                'BE - Matières traitées ou entreposées',
                _beEffective,
              ),
              _buildReadOnlySelecteur(
                'AE - Pénétration de corps solides',
                _aeEffective,
              ),
              _buildReadOnlySelecteur(
                'AD - Pénétration de liquides',
                _adEffective,
              ),
              _buildReadOnlySelecteur(
                'AG - Risques de chocs mécaniques',
                _agEffective,
              ),
            ] else ...[
              _buildSelecteur(
                'AF - Substances corrosives ou polluantes*',
                _emplacement.af,
                HiveService.getOptionsAF(),
                (value) => setState(() { _emplacement.af = value; _validateAF(value); }),
                isValid: _afValid,
              ),
              _buildSelecteur(
                'BE - Matières traitées ou entreposées*',
                _emplacement.be,
                HiveService.getOptionsBE(),
                (value) => setState(() { _emplacement.be = value; _validateBE(value); }),
                isValid: _beValid,
              ),
              _buildSelecteur(
                'AE - Pénétration de corps solides*',
                _emplacement.ae,
                HiveService.getOptionsAE(),
                (value) => setState(() { _emplacement.ae = value; _validateAE(value); }),
                isValid: _aeValid,
              ),
              _buildSelecteur(
                'AD - Pénétration de liquides*',
                _emplacement.ad,
                HiveService.getOptionsAD(),
                (value) => setState(() { _emplacement.ad = value; _validateAD(value); }),
                isValid: _adValid,
              ),
              _buildSelecteur(
                'AG - Risques de chocs mécaniques*',
                _emplacement.ag,
                HiveService.getOptionsAG(),
                (value) => setState(() { _emplacement.ag = value; _validateAG(value); }),
                isValid: _agValid,
              ),
            ],
            
            SizedBox(height: spacing),
            
            // Indices calculés (basés sur les valeurs effectives)
            _buildIndices(),
            
            SizedBox(height: spacing * 1.5),
            
            // Boutons d'action (seulement si pas en héritage)
            if (!_estEnHeritage) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing * 0.9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'SAUVEGARDER',
                              style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(width: spacing * 0.8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: spacing * 0.9),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'ANNULER',
                        style: TextStyle(fontSize: bodyFontSize, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // En mode héritage, bouton pour passer en spécifique
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _passerEnClassementSpecifique,
                  icon: Icon(Icons.link_off, size: bodyFontSize),
                  label: Text(
                    'PASSER EN CLASSEMENT SPÉCIFIQUE',
                    style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: spacing * 0.9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: spacing * 0.9),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'FERMER',
                    style: TextStyle(fontSize: bodyFontSize, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  // NOUVEAU : Widget de sélecteur en lecture seule
  Widget _buildReadOnlySelecteur(String title, String? value) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final spacing = _getResponsiveSpacing(12);
    final titleFontSize = _getResponsiveFontSize(15);
    
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: titleFontSize * 0.8, color: Colors.blue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.replaceAll('*', ''),
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Non défini',
                    style: TextStyle(
                      fontSize: titleFontSize * 0.9,
                      color: value != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.visibility, size: titleFontSize * 0.9, color: Colors.blue.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : Méthode pour passer en classement spécifique
  Future<void> _passerEnClassementSpecifique() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passer en classement spécifique ?'),
        content: const Text(
          'Vous allez détacher ce local du classement de sa zone.\n\n'
          'Les valeurs actuelles seront copiées et vous pourrez les modifier indépendamment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await HiveService.passerEnClassementSpecifique(
          localId: _emplacement.key.toString(),
        );
        
        // Recharger l'emplacement
        final box = Hive.box<ClassementEmplacement>('classement_locaux');
        final updated = box.get(_emplacement.key);
        if (updated != null) {
          setState(() {
            _emplacement = updated;
            _origineValid = _emplacement.origineClassement.isNotEmpty;
            _afValid = _emplacement.af != null && _emplacement.af!.isNotEmpty;
            _beValid = _emplacement.be != null && _emplacement.be!.isNotEmpty;
            _aeValid = _emplacement.ae != null && _emplacement.ae!.isNotEmpty;
            _adValid = _emplacement.ad != null && _emplacement.ad!.isNotEmpty;
            _agValid = _emplacement.ag != null && _emplacement.ag!.isNotEmpty;
          });
        }
        
        _showSnackBar('Classement spécifique activé', Colors.green);
      } catch (e) {
        _showSnackBar('Erreur: $e', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // MODIFIER : _buildIndices pour utiliser les valeurs effectives
  Widget _buildIndices() {
    // Utiliser les valeurs effectives
    final ipValue = _ipEffective;
    final ikValue = _ikEffective;
    
    final titleFontSize = _getResponsiveFontSize(15);
    final valueFontSize = _getResponsiveFontSize(22);
    final smallFontSize = _getResponsiveFontSize(11);
    final spacing = _getResponsiveSpacing(12);
    final iconSize = _getResponsiveIconSize(18);
    
    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: iconSize),
              SizedBox(width: spacing * 0.6),
              Expanded(
                child: Text(
                  'Indices minimaux de protection',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_estEnHeritage)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: smallFontSize, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Hérité', style: TextStyle(fontSize: smallFontSize, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: spacing * 0.8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Text('IP', style: TextStyle(fontSize: smallFontSize, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(
                        ipValue ?? '--',
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: spacing * 0.8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Text('IK', style: TextStyle(fontSize: smallFontSize, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(
                        ikValue ?? '--',
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.6),
          Row(
            children: [
              Icon(Icons.info_outline, size: smallFontSize, color: Colors.white70),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  _estEnHeritage 
                      ? 'Calculés à partir du classement de la zone parente'
                      : 'Calculés à partir des influences AE, AD et AG',
                  style: TextStyle(fontSize: smallFontSize * 0.9, color: Colors.white70, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}