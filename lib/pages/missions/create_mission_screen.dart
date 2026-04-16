// lib/pages/missions/create_mission_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/create_mission_data.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';

class CreateMissionScreen extends StatefulWidget {
  final Verificateur currentUser;

  const CreateMissionScreen({super.key, required this.currentUser});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs
  final _nomClientCtrl = TextEditingController();
  final _activiteClientCtrl = TextEditingController();
  final _adresseClientCtrl = TextEditingController();
  final _nomSiteCtrl = TextEditingController();
  
  // Sélection pour Nature de vérification
  String? _natureMission;
  
  // Options pour Nature de vérification
  final List<Map<String, dynamic>> _natureOptions = [
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
      'value': 'Audit',
      'title': 'Audit',
      'description': 'Audit complet de conformité réglementaire',
      'icon': Icons.assignment,
      'color': Colors.blue,
    },
    {
      'value': 'Expertise',
      'title': 'Expertise',
      'description': 'Expertise technique approfondie',
      'icon': Icons.engineering,
      'color': Colors.green,
    },
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nomClientCtrl.dispose();
    _activiteClientCtrl.dispose();
    _adresseClientCtrl.dispose();
    _nomSiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMission() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Valider que la nature est sélectionnée
    if (_natureMission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la nature de la vérification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nomSiteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le nom du site'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final missionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final mission = Mission(
        id: missionId,
        nomClient: _nomClientCtrl.text.trim(),
        activiteClient: _activiteClientCtrl.text.trim().isEmpty ? null : _activiteClientCtrl.text.trim(),
        adresseClient: _adresseClientCtrl.text.trim().isEmpty ? null : _adresseClientCtrl.text.trim(),
        nomSite: _nomSiteCtrl.text.trim(), // NOUVEAU
        natureMission: _natureMission,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_attente',
        verificateurs: [
          {
            'matricule': widget.currentUser.matricule,
            'nom': widget.currentUser.nom,
            'prenom': widget.currentUser.prenom,
          }
        ],
      );
      
      await HiveService.saveMission(mission);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNaturePicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
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
                'Nature de la vérification',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 0),
            // Options
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _natureOptions.map((option) {
                    final isSelected = _natureMission == option['value'];
                    return InkWell(
                      onTap: () {
                        setState(() => _natureMission = option['value']);
                        Navigator.pop(context);
                      },
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
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final displayColor = color ?? (value != null ? AppTheme.primaryBlue : Colors.grey);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 12 : 16
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          border: Border.all(
            color: value != null ? displayColor.withOpacity(0.3) : Colors.grey.shade200,
          ),
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
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              child: Icon(icon, size: isSmallScreen ? 20 : 22, color: displayColor),
            ),
            SizedBox(width: isSmallScreen ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13, 
                      color: Colors.grey.shade600
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down, 
              color: displayColor, 
              size: isSmallScreen ? 24 : 28
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
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
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon, size: isSmallScreen ? 20 : 22, color: AppTheme.primaryBlue),
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
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'Nouvelle Mission',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveMission,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Créer',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text(
                  'INFORMATIONS CLIENT',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Nom du client (obligatoire)
                _buildTextField(
                  controller: _nomClientCtrl,
                  label: 'Nom du client',
                  icon: Icons.business,
                  hint: 'Ex: Société Générale',
                  isRequired: true,
                ),
                SizedBox(height: isSmallScreen ? 14 : 16),
                
                // Activité du client
                _buildTextField(
                  controller: _activiteClientCtrl,
                  label: 'Activité du client',
                  icon: Icons.work_outline,
                  hint: 'Ex: Banque, Industrie, Services...',
                ),
                SizedBox(height: isSmallScreen ? 14 : 16),

                // Nom du site
                _buildTextField(
                  controller: _nomSiteCtrl,
                  label: 'Nom du site',
                  icon: Icons.location_city,
                  hint: 'Ex: Siège Social, Agence Centrale...',
                  isRequired: true,
                ),
                SizedBox(height: isSmallScreen ? 24 : 28),
                
                // Adresse
                _buildTextField(
                  controller: _adresseClientCtrl,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                  hint: 'Ex: Yaoundé, Cameroun',
                  maxLines: 2,
                ),
                SizedBox(height: isSmallScreen ? 24 : 28),
                
                // Section Nature de vérification
                Text(
                  'NATURE DE LA VÉRIFICATION',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Sélection de la nature
                _buildDisplayField(
                  label: 'Type de vérification',
                  value: _natureMission,
                  hint: 'Sélectionnez le type de vérification',
                  icon: Icons.verified_outlined,
                  onTap: _showNaturePicker,
                  color: _natureMission != null ? Colors.blue : null,
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 40),
                
                // Bouton de création
                Container(
                  width: double.infinity,
                  height: isSmallScreen ? 50 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withOpacity(0.85),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: isSmallScreen ? 20 : 22,
                                color: Colors.white,
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Text(
                                'CRÉER LA MISSION',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}