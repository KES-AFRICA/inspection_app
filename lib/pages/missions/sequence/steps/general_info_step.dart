// lib/pages/missions/sequence/steps/general_info_step.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class GeneralInfoStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final Function(bool) onValidationChanged; // NOUVEAU : Callback pour notifier la validation

  const GeneralInfoStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onValidationChanged,
  });

  @override
  State<GeneralInfoStep> createState() => _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<GeneralInfoStep> {
  // Contrôleurs
  late TextEditingController _etablissementController;
  late TextEditingController _installationController;
  late TextEditingController _activiteController;
  
  // Données
  DateTime? _dateDebut;
  DateTime? _dateFin;
  int _dureeJours = 0;
  
  // Sélections
  String? _verificationType;
  String? _registreControle;
  String? _compteRenduDestinataire;
  
  // Listes
  List<Map<String, String>> _accompagnateurs = [];
  List<Map<String, String>> _verificateurs = [];
  
  // Focus
  final FocusNode _etablissementFocus = FocusNode();
  final FocusNode _installationFocus = FocusNode();
  final FocusNode _activiteFocus = FocusNode();

  // Options pour les dropdowns stylisés
  final List<Map<String, dynamic>> _verificationOptions = [
    {
      'value': 'Périodique réglementaire',
      'title': 'Périodique réglementaire',
      'description': 'Vérification périodique selon la réglementation en vigueur',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
    },
    {
      'value': 'Initiale réglementaire',
      'title': 'Initiale réglementaire',
      'description': 'Vérification initiale avant mise en service',
      'icon': Icons.note_add,
      'color': Colors.green,
    },
    {
      'value': 'Audit réglementaire',
      'title': 'Audit réglementaire',
      'description': 'Audit complet de conformité réglementaire',
      'icon': Icons.assignment,
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> _registreOptions = [
    {
      'value': 'Présenté',
      'title': 'Présenté',
      'description': 'Le registre de contrôle a été fourni et est à jour',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'value': 'Non présenté',
      'title': 'Non présenté',
      'description': 'Le registre de contrôle n\'a pas été fourni',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  bool _isLoading = true;
  RenseignementsGeneraux? _data;

  // Getters pour la validation
  bool get isFormValid {
    return _etablissementController.text.trim().isNotEmpty &&
           _installationController.text.trim().isNotEmpty &&
           _activiteController.text.trim().isNotEmpty &&
           _verificationType != null &&
           _dateDebut != null &&
           _dateFin != null &&
           _accompagnateurs.isNotEmpty &&
           _verificateurs.isNotEmpty &&
           _registreControle != null &&
           _compteRenduDestinataire != null;
  }


  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    _etablissementController = TextEditingController();
    _installationController = TextEditingController();
    _activiteController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _data = await HiveService.getOrCreateRenseignementsGeneraux(widget.mission.id);
      
      setState(() {
        _etablissementController.text = _data!.etablissement;
        _installationController.text = _data!.installation;
        _activiteController.text = _data!.activite;
        
        _dateDebut = _data!.dateDebut;
        _dateFin = _data!.dateFin;
        _dureeJours = _data!.dureeJours;
        _verificationType = _data!.verificationType;
        _registreControle = _data!.registreControle.isNotEmpty ? _data!.registreControle : null;
        _compteRenduDestinataire = _data!.compteRendu.isNotEmpty ? _data!.compteRendu : null;
        _accompagnateurs = List.from(_data!.accompagnateurs);
        _verificateurs = List.from(_data!.verificateurs);
      });
      
      // Notifier la validation initiale
      _notifyValidation();
    } catch (e) {
      print('❌ Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _notifyValidation() {
    widget.onValidationChanged(isFormValid);
  }

  Future<void> _saveData() async {
    if (_data == null) return;
    
    _data!.etablissement = _etablissementController.text;
    _data!.installation = _installationController.text;
    _data!.activite = _activiteController.text;
    _data!.dateDebut = _dateDebut;
    _data!.dateFin = _dateFin;
    _data!.dureeJours = _dureeJours;
    _data!.verificationType = _verificationType;
    _data!.registreControle = _registreControle ?? '';
    _data!.compteRendu = _compteRenduDestinataire ?? '';
    _data!.accompagnateurs = List.from(_accompagnateurs);
    _data!.verificateurs = List.from(_verificateurs);
    _data!.updatedAt = DateTime.now();
    
    await HiveService.saveRenseignementsGeneraux(_data!);
    
    widget.onDataChanged(_data!.toMap());
    _notifyValidation();
    print('✅ Renseignements généraux sauvegardés');
  }

  void _calculateDuree() {
    if (_dateDebut != null && _dateFin != null) {
      _dureeJours = _dateFin!.difference(_dateDebut!).inDays;
    } else {
      _dureeJours = 0;
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
        _calculateDuree();
      });
      await _saveData();
    }
  }

  void _showVerificationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStyledPicker(
        title: 'Type de vérification',
        options: _verificationOptions,
        selectedValue: _verificationType,
        onSelected: (value) async {
          setState(() => _verificationType = value);
          await _saveData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRegistrePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStyledPicker(
        title: 'Registre de contrôle',
        options: _registreOptions,
        selectedValue: _registreControle,
        onSelected: (value) async {
          setState(() => _registreControle = value);
          await _saveData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCompteRenduPicker() {
    if (_accompagnateurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ajouter des accompagnateurs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> accompagnateurOptions = _accompagnateurs.map((accomp) {
      return {
        'value': accomp['nom'],
        'title': accomp['nom']!,
        'description': accomp['poste']?.isNotEmpty == true 
            ? '${accomp['poste']}${accomp['email']?.isNotEmpty == true ? ' • ${accomp['email']}' : ''}'
            : (accomp['email']?.isNotEmpty == true ? accomp['email'] : 'Aucun poste spécifié'),
        'icon': Icons.person,
        'color': Colors.purple,
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStyledPicker(
        title: 'Compte rendu de fin de visite fait à',
        options: accompagnateurOptions,
        selectedValue: _compteRenduDestinataire,
        onSelected: (value) async {
          setState(() => _compteRenduDestinataire = value);
          await _saveData();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildStyledPicker({
    required String title,
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
            width: isSmallScreen ? 30 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 0),
          // Options avec scroll pour éviter les débordements
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: options.map((option) {
                  final isSelected = selectedValue == option['value'];
                  return InkWell(
                    onTap: () => onSelected(option['value']),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: isSelected ? (option['color'] as Color).withOpacity(0.05) : Colors.transparent,
                        border: isSelected
                            ? Border(
                                left: BorderSide(color: option['color'], width: 4),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 40 : 48,
                            height: isSmallScreen ? 40 : 48,
                            decoration: BoxDecoration(
                              color: (option['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            ),
                            child: Icon(
                              option['icon'],
                              color: option['color'],
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['title'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? option['color'] : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  option['description'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: option['color'],
                              size: isSmallScreen ? 20 : 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          // Bouton fermer
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
        ],
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isRequired = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final displayColor = color ?? (value != null ? AppTheme.primaryBlue : (isRequired ? Colors.red : Colors.grey));
    final borderColor = value != null 
        ? displayColor.withOpacity(0.3) 
        : (isRequired ? Colors.red.shade300 : Colors.grey.shade200);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 10 : 14
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(icon, size: isSmallScreen ? 18 : 20, color: displayColor),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12, 
                          color: Colors.grey
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Colors.black87 : (isRequired ? Colors.red.shade400 : Colors.grey.shade500),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down, 
              color: displayColor, 
              size: isSmallScreen ? 22 : 24
            ),
          ],
        ),
      ),
    );
  }

  void _showAjouterAccompagnateurDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final posteController = TextEditingController();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)
        ),
        title: Text(
          'Ajouter un accompagnateur',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              TextField(
                controller: posteController,
                decoration: InputDecoration(
                  labelText: 'Poste / Fonction',
                  prefixIcon: Icon(Icons.work, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom est obligatoire'), 
                    backgroundColor: Colors.red
                  ),
                );
                return;
              }
              setState(() {
                _accompagnateurs.add({
                  'nom': nom,
                  'email': emailController.text.trim(),
                  'poste': posteController.text.trim(),
                });
              });
              await _saveData();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Ajouter',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAjouterVerificateurDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)
        ),
        title: Text(
          'Ajouter un vérificateur',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom est obligatoire'), 
                    backgroundColor: Colors.red
                  ),
                );
                return;
              }
              setState(() {
                _verificateurs.add({
                  'nom': nom,
                  'email': emailController.text.trim(),
                });
              });
              await _saveData();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Ajouter',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _supprimerAccompagnateur(int index) async {
    final accompagnateurSupprime = _accompagnateurs[index];
    setState(() {
      _accompagnateurs.removeAt(index);
      // Si le destinataire du compte rendu était cet accompagnateur, réinitialiser
      if (_compteRenduDestinataire == accompagnateurSupprime['nom']) {
        _compteRenduDestinataire = null;
      }
    });
    await _saveData();
  }

  void _supprimerVerificateur(int index) async {
    setState(() {
      _verificateurs.removeAt(index);
    });
    await _saveData();
  }

  @override
  void dispose() {
    _etablissementController.dispose();
    _installationController.dispose();
    _activiteController.dispose();
    _etablissementFocus.dispose();
    _installationFocus.dispose();
    _activiteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Chargement des données...',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Renseignements Principaux',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  // Indicateur de validation
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFormValid 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      border: Border.all(
                        color: isFormValid ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFormValid ? Icons.check_circle : Icons.warning,
                          size: isSmallScreen ? 14 : 16,
                          color: isFormValid ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          isFormValid ? 'Complet' : 'Incomplet',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: isFormValid ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Établissement
              _buildTextField(
                controller: _etablissementController,
                label: 'Établissement vérifié',
                icon: Icons.business,
                focusNode: _etablissementFocus,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Installation vérifiée
              _buildTextField(
                controller: _installationController,
                label: 'Installation vérifiée',
                icon: Icons.location_city,
                hint: 'Ex: Bâtiment A',
                focusNode: _installationFocus,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Activité principale
              _buildTextField(
                controller: _activiteController,
                label: 'Activité principale',
                icon: Icons.work_outline,
                hint: 'Ex: BTP, Industrie, Services...',
                focusNode: _activiteFocus,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Type de vérification - STYLISÉ
              _buildDisplayField(
                label: 'Type de vérification',
                value: _verificationType,
                hint: 'Sélectionnez le type de vérification',
                icon: Icons.verified_outlined,
                onTap: _showVerificationPicker,
                color: _verificationType != null ? Colors.blue : null,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Dates
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: (_dateDebut == null || _dateFin == null) 
                        ? Colors.red.shade300 
                        : Colors.transparent,
                    width: (_dateDebut == null || _dateFin == null) ? 1.5 : 0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            ),
                            child: Icon(
                              Icons.calendar_today, 
                              color: Colors.orange, 
                              size: isSmallScreen ? 18 : 20
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Période d\'intervention',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16, 
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                Text(
                                  ' *',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        children: [
                          _buildDateField(
                            label: 'Date de début',
                            date: _dateDebut,
                            icon: Icons.play_arrow,
                            onTap: () => _selectDate(context, true),
                            isRequired: true,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildDateField(
                            label: 'Date de fin',
                            date: _dateFin,
                            icon: Icons.check,
                            onTap: () => _selectDate(context, false),
                            isRequired: true,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                                  ),
                                  child: Icon(
                                    Icons.timer_outlined, 
                                    color: AppTheme.primaryBlue, 
                                    size: isSmallScreen ? 18 : 20
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 10 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Durée',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12, 
                                          color: Colors.grey
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '$_dureeJours jour(s)',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Accompagnateurs
              _buildDynamicListSection(
                title: 'Accompagnateurs',
                icon: Icons.people,
                color: Colors.blue,
                items: _accompagnateurs,
                itemBuilder: (accomp) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accomp['nom']!, 
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    if (accomp['email']!.isNotEmpty)
                      Text(
                        accomp['email']!, 
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12, 
                          color: Colors.grey
                        ),
                      ),
                    if (accomp['poste']!.isNotEmpty)
                      Text(
                        accomp['poste']!, 
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12, 
                          color: Colors.grey
                        ),
                      ),
                  ],
                ),
                onAdd: _showAjouterAccompagnateurDialog,
                onDelete: _supprimerAccompagnateur,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Vérificateurs
              _buildDynamicListSection(
                title: 'Vérificateurs',
                icon: Icons.verified_user,
                color: Colors.green,
                items: _verificateurs,
                itemBuilder: (verif) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verif['nom']!, 
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    if (verif['email']!.isNotEmpty)
                      Text(
                        verif['email']!, 
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12, 
                          color: Colors.grey
                        ),
                      ),
                  ],
                ),
                onAdd: _showAjouterVerificateurDialog,
                onDelete: _supprimerVerificateur,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Registre de contrôle - STYLISÉ
              _buildDisplayField(
                label: 'Registre de contrôle',
                value: _registreControle,
                hint: 'Sélectionnez l\'état du registre',
                icon: Icons.book_outlined,
                onTap: _showRegistrePicker,
                color: _registreControle != null 
                    ? (_registreControle == 'Présenté' ? Colors.green : Colors.red)
                    : null,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Compte rendu de fin de visite fait à
              _buildDisplayField(
                label: 'Compte rendu de fin de visite fait à',
                value: _compteRenduDestinataire,
                hint: _accompagnateurs.isEmpty 
                    ? 'Ajoutez d\'abord des accompagnateurs' 
                    : 'Sélectionnez le destinataire',
                icon: Icons.description_outlined,
                onTap: _showCompteRenduPicker,
                color: _compteRenduDestinataire != null ? Colors.purple : null,
                isRequired: true,
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    String? hint,
    bool isRequired = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasText = controller.text.trim().isNotEmpty;
    final borderColor = hasText 
        ? AppTheme.primaryBlue.withOpacity(0.3)
        : (isRequired ? Colors.red.shade300 : Colors.grey.shade200);
    
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            border: Border.all(color: borderColor),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: isRequired ? '$label *' : label,
              labelStyle: TextStyle(
                color: hasText 
                    ? Colors.grey.shade600 
                    : (isRequired ? Colors.red.shade400 : Colors.grey.shade600),
              ),
              hintText: hint,
              prefixIcon: Icon(
                icon, 
                size: isSmallScreen ? 18 : 20,
                color: focusNode.hasFocus ? AppTheme.primaryBlue : (hasText ? AppTheme.primaryBlue : Colors.grey)
              ),
              suffixIcon: hasText 
                  ? Icon(Icons.check_circle, color: Colors.green, size: isSmallScreen ? 16 : 18)
                  : (isRequired ? Icon(Icons.error_outline, color: Colors.red, size: isSmallScreen ? 16 : 18) : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20, 
                vertical: isSmallScreen ? 14 : 18
              ),
            ),
            onChanged: (_) => _saveData(),
            onEditingComplete: () => focusNode.unfocus(),
          ),
        );
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final borderColor = date != null 
        ? Colors.grey.shade200 
        : (isRequired ? Colors.red.shade300 : Colors.grey.shade200);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 10 : 14
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: date != null 
                    ? AppTheme.primaryBlue.withOpacity(0.1) 
                    : (isRequired ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(
                icon, 
                size: isSmallScreen ? 16 : 18, 
                color: date != null ? AppTheme.primaryBlue : (isRequired ? Colors.red : Colors.grey)
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12, 
                          color: Colors.grey
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    date != null 
                        ? DateFormat('dd/MM/yyyy').format(date!)
                        : 'Non définie',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : (isRequired ? Colors.red.shade400 : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today, 
              size: isSmallScreen ? 16 : 18, 
              color: date != null ? AppTheme.primaryBlue : (isRequired ? Colors.red.shade300 : Colors.grey.shade400)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> items,
    required Widget Function(Map<String, String>) itemBuilder,
    required VoidCallback onAdd,
    required Function(int) onDelete,
    bool isRequired = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final borderColor = items.isNotEmpty 
        ? Colors.transparent 
        : (isRequired ? Colors.red.shade300 : Colors.transparent);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: borderColor, width: items.isEmpty && isRequired ? 1.5 : 0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (items.isEmpty && isRequired)
                  Icon(
                    Icons.warning_amber_rounded,
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                if (items.isNotEmpty)
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: itemBuilder(item)),
                          IconButton(
                            icon: Icon(
                              Icons.delete, 
                              size: isSmallScreen ? 16 : 18, 
                              color: Colors.red
                            ),
                            onPressed: () => onDelete(index),
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 32 : 40,
                              minHeight: isSmallScreen ? 32 : 40,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                if (items.isEmpty && isRequired)
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.red.shade700,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        Expanded(
                          child: Text(
                            'Au moins un élément est requis',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      'AJOUTER UN $title'.toUpperCase(),
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}