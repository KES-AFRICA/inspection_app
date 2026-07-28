// lib/pages/missions/create_mission_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';

class CreateMissionScreen extends StatefulWidget {
  final Verificateur currentUser;
  final Mission? missionToEdit;

  const CreateMissionScreen({
    super.key,
    required this.currentUser,
    this.missionToEdit,
  });

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs
  final _nomClientCtrl = TextEditingController();
  final _activiteClientCtrl = TextEditingController();
  final _activiteSurSiteCtrl = TextEditingController();
  final _adresseClientCtrl = TextEditingController();
  final _nomSiteCtrl = TextEditingController();
  final _installationCtrl = TextEditingController();
  
  // Sélection pour Nature de vérification
  String? _natureMission;

  // Classement réglementaire
  String? _classementReglementaireType;
  String? _classementReglementaireCategorie;

  static const List<String> _classementTypes = [
    '—', 'A', 'B', 'C', 'D', 'E', 'J', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y'
  ];

  static const List<String> _classementCategories = [
    '—', '1ère catégorie', '2ème catégorie', '3ème catégorie', '4ème catégorie', '5ème catégorie'
  ];

  // Sélection pour Périmètre de la mission
  List<String> _selectedPerimetres = [];

  static const List<String> _perimetreOptions = [
    'Vérification électrique',
    'Analyse du risque foudre et étude technique foudre',
    'Audit foudre',
    'Vérification thermographie infrarouge',
    'Cartographie des prises de terre',
    'Reconstitution des schémas des installations existantes',
    'Élaboration des schémas et note de calcul pour la mise en conformité des installations',
  ];

  static List<String> normalizePerimetreList(List<String> rawList) {
    const mapping = {
      'Vérification thermographique': 'Vérification thermographie infrarouge',
      'Vérification des prises de terre': 'Cartographie des prises de terre',
    };

    final result = <String>[];
    for (final item in rawList) {
      final normalized = mapping[item] ?? item;
      if (!result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.missionToEdit != null) {
      final m = widget.missionToEdit!;
      _nomClientCtrl.text = m.nomClient;
      _activiteClientCtrl.text = m.activiteClient ?? '';
      _activiteSurSiteCtrl.text = m.activiteSurSite ?? '';
      _classementReglementaireType = m.classementReglementaireType;
      _classementReglementaireCategorie = m.classementReglementaireCategorie;
      _adresseClientCtrl.text = m.adresseClient ?? '';
      _nomSiteCtrl.text = m.nomSite ?? '';
      _installationCtrl.text = m.installation ?? '';
      _natureMission = m.natureMission;
      if (m.perimetreMission != null) {
        _selectedPerimetres = normalizePerimetreList(m.perimetreMission!);
      }
    }
  }

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
    _activiteSurSiteCtrl.dispose();
    _adresseClientCtrl.dispose();
    _nomSiteCtrl.dispose();
    _installationCtrl.dispose();
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

    if (_installationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir l\'installation vérifiée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool isEditing = widget.missionToEdit != null;
      final missionId = isEditing
          ? widget.missionToEdit!.id
          : DateTime.now().millisecondsSinceEpoch.toString();
      
      final mission = Mission(
        id: missionId,
        nomClient: _nomClientCtrl.text.trim(),
        activiteClient: _activiteClientCtrl.text.trim().isEmpty ? null : _activiteClientCtrl.text.trim(),
        activiteSurSite: _activiteSurSiteCtrl.text.trim().isEmpty ? null : _activiteSurSiteCtrl.text.trim(),
        classementReglementaireType: _classementReglementaireType,
        classementReglementaireCategorie: _classementReglementaireCategorie,
        adresseClient: _adresseClientCtrl.text.trim().isEmpty ? null : _adresseClientCtrl.text.trim(),
        nomSite: _nomSiteCtrl.text.trim(),
        installation: _installationCtrl.text.trim(),
        natureMission: _natureMission,
        perimetreMission: _selectedPerimetres.isEmpty ? null : List<String>.from(_selectedPerimetres),
        createdAt: isEditing ? widget.missionToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        status: isEditing ? widget.missionToEdit!.status : 'en_attente',
        logoClient: isEditing ? widget.missionToEdit!.logoClient : null,
        accompagnateurs: isEditing ? widget.missionToEdit!.accompagnateurs : null,
        verificateurs: isEditing
            ? widget.missionToEdit!.verificateurs
            : [
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
          SnackBar(
            content: Text(isEditing
                ? 'Mission modifiée avec succès'
                : 'Mission créée avec succès'),
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

  void _showPerimetrePicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                  'Périmètre de la mission',
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
                    children: _perimetreOptions.map((option) {
                      final isSelected = _selectedPerimetres.contains(option);
                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppTheme.primaryBlue,
                        title: Text(
                          option,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                          ),
                        ),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              if (!_selectedPerimetres.contains(option)) {
                                _selectedPerimetres.add(option);
                              }
                            } else {
                              _selectedPerimetres.remove(option);
                            }
                          });
                          setBottomSheetState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Validate button
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Valider',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            widget.missionToEdit != null ? 'Éditer la mission' : 'Nouvelle Mission',
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
                      widget.missionToEdit != null ? 'Enregistrer' : 'Créer',
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
                  label: 'Activité principale du client',
                  icon: Icons.work_outline,
                  hint: 'Ex: Société de transport, Banque...',
                ),
                SizedBox(height: isSmallScreen ? 14 : 16),

                // Activité sur le site
                _buildTextField(
                  controller: _activiteSurSiteCtrl,
                  label: 'Activité sur le site',
                  icon: Icons.storefront_outlined,
                  hint: 'Ex: Atelier, Gare, Dépôt, Siège...',
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

                // Installation vérifiée
                _buildTextField(
                  controller: _installationCtrl,
                  label: 'Installation vérifiée',
                  icon: Icons.electrical_services,
                  hint: 'Ex: Installations électriques BT/MT...',
                  isRequired: true,
                ),
                SizedBox(height: isSmallScreen ? 14 : 16),
                
                // Adresse
                _buildTextField(
                  controller: _adresseClientCtrl,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                  hint: 'Ex: Yaoundé, Cameroun',
                  maxLines: 2,
                ),
                SizedBox(height: isSmallScreen ? 24 : 28),

                // Section Classement réglementaire
                Text(
                  'CLASSEMENT RÈGLEMENTAIRE',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _classementTypes.contains(_classementReglementaireType) ? _classementReglementaireType : '—',
                        decoration: InputDecoration(
                          labelText: 'Type ERP / ERT',
                          prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.darkBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: _classementTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _classementReglementaireType = (val == '—' ? null : val)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _classementCategories.contains(_classementReglementaireCategorie) ? _classementReglementaireCategorie : '—',
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: const Icon(Icons.filter_list_outlined, color: AppTheme.darkBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: _classementCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _classementReglementaireCategorie = (val == '—' ? null : val)),
                      ),
                    ),
                  ],
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
                SizedBox(height: isSmallScreen ? 24 : 28),

                // Section Périmètre de la mission
                Text(
                  'PÉRIMÈTRE DE LA MISSION',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                _buildDisplayField(
                  label: 'Périmètre de la mission',
                  value: _selectedPerimetres.isEmpty
                      ? null
                      : _selectedPerimetres.join(', '),
                  hint: 'Sélectionnez le périmètre de la mission',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: _showPerimetrePicker,
                  color: _selectedPerimetres.isNotEmpty ? Colors.blue : null,
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
                                widget.missionToEdit != null
                                    ? Icons.save_rounded
                                    : Icons.add_circle_outline,
                                size: isSmallScreen ? 20 : 22,
                                color: Colors.white,
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 10),
                              Text(
                                widget.missionToEdit != null
                                    ? 'ENREGISTRER'
                                    : 'CRÉER LA MISSION',
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