// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ClassementZoneScreen extends StatefulWidget {
  final Mission mission;
  final ClassementZone classement;

  const ClassementZoneScreen({
    super.key,
    required this.mission,
    required this.classement,
  });

  @override
  State<ClassementZoneScreen> createState() => _ClassementZoneScreenState();
}

class _ClassementZoneScreenState extends State<ClassementZoneScreen> {
  late ClassementZone _classement;
  final _origineController = TextEditingController();
  
  bool _isLoading = false;
  bool _origineValid = false;
  bool _afValid = false;
  bool _beValid = false;
  bool _aeValid = false;
  bool _adValid = false;
  bool _agValid = false;

  @override
  void initState() {
    super.initState();
    _classement = widget.classement;
    _origineController.text = _classement.origineClassement;
    
    _origineValid = _classement.origineClassement.isNotEmpty;
    _afValid = _classement.af != null && _classement.af!.isNotEmpty;
    _beValid = _classement.be != null && _classement.be!.isNotEmpty;
    _aeValid = _classement.ae != null && _classement.ae!.isNotEmpty;
    _adValid = _classement.ad != null && _classement.ad!.isNotEmpty;
    _agValid = _classement.ag != null && _classement.ag!.isNotEmpty;
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
    if (_classement.af == null || _classement.af!.isEmpty) { _afValid = false; allValid = false; }
    if (_classement.be == null || _classement.be!.isEmpty) { _beValid = false; allValid = false; }
    if (_classement.ae == null || _classement.ae!.isEmpty) { _aeValid = false; allValid = false; }
    if (_classement.ad == null || _classement.ad!.isEmpty) { _adValid = false; allValid = false; }
    if (_classement.ag == null || _classement.ag!.isEmpty) { _agValid = false; allValid = false; }
    setState(() {});
    return allValid;
  }

  Future<void> _sauvegarder() async {
    if (!_validateAllFields()) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    _classement.origineClassement = _origineController.text.trim();
    _classement.calculerIndices();
    
    final success = await HiveService.saveClassementZone(_classement);
    
    setState(() => _isLoading = false);
    
    if (success) {
      _showSnackBar('Classement sauvegardé', Colors.green);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // BUG #2 + #3 FIX: un seul pop suffit.
        // AjouterZoneScreen a utilisé pushReplacement, donc la pile est :
        //   [MoyenneTensionScreen] → [ClassementZoneScreen]
        // Un seul pop nous ramène directement à MoyenneTensionScreen.
        // Le double pop précédent remontait trop haut (dépilait MoyenneTensionScreen).
        Navigator.of(context).pop(true);
      }
    } else {
      _showSnackBar('Erreur lors de la sauvegarde', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildSelecteur(String title, String? currentValue, List<String> options, Function(String?) onChanged, {required bool isValid}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: isValid ? AppTheme.darkBlue : Colors.red,
                  ),
                ),
              ),
              if (!isValid)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Obligatoire',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.red),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isValid ? Colors.grey.shade300 : Colors.red.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: currentValue,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_circle, color: isValid ? AppTheme.primaryBlue : Colors.red),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: Text(
                'Sélectionnez',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.black87),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndices() {
    _classement.calculerIndices();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: isSmallScreen ? 18 : 20),
              SizedBox(width: 8),
              Text(
                'Indices minimaux de protection',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('IP', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(
                        _classement.ip ?? '--',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('IK', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      SizedBox(height: 4),
                      Text(
                        _classement.ik ?? '--',
                        style: TextStyle(
                          fontSize: 20,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Classement: ${_classement.nomZone}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _sauvegarder,
            ),
        ],
      ),
      body: GestureDetector(
        onTap:()=> FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'avertissement
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TOUS LES CHAMPS SONT OBLIGATOIRES',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Origine classement
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _origineValid ? AppTheme.darkBlue : Colors.red,
                            ),
                          ),
                        ),
                        Text(' *', style: TextStyle(fontSize: 15, color: Colors.red)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _origineValid ? Colors.grey.shade300 : Colors.red.shade300),
                      ),
                      child: TextFormField(
                        controller: _origineController,
                        onChanged: _validateOrigine,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ex: KES I&P',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Titre section influences
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'INFLUENCES EXTERNES',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sélecteurs d'influences
              _buildSelecteur(
                'AF - Substances corrosives ou polluantes',
                _classement.af,
                HiveService.getOptionsAF(),
                (value) => setState(() { _classement.af = value; _validateAF(value); }),
                isValid: _afValid,
              ),
              
              _buildSelecteur(
                'BE - Matières traitées ou entreposées',
                _classement.be,
                HiveService.getOptionsBE(),
                (value) => setState(() { _classement.be = value; _validateBE(value); }),
                isValid: _beValid,
              ),
              
              _buildSelecteur(
                'AE - Pénétration de corps solides',
                _classement.ae,
                HiveService.getOptionsAE(),
                (value) => setState(() { _classement.ae = value; _validateAE(value); }),
                isValid: _aeValid,
              ),
              
              _buildSelecteur(
                'AD - Pénétration de liquides',
                _classement.ad,
                HiveService.getOptionsAD(),
                (value) => setState(() { _classement.ad = value; _validateAD(value); }),
                isValid: _adValid,
              ),
              
              _buildSelecteur(
                'AG - Risques de chocs mécaniques',
                _classement.ag,
                HiveService.getOptionsAG(),
                (value) => setState(() { _classement.ag = value; _validateAG(value); }),
                isValid: _agValid,
              ),
              
              SizedBox(height: 16),
              
              // Indices calculés
              _buildIndices(),
              
              SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sauvegarder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'SAUVEGARDER',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'ANNULER',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}