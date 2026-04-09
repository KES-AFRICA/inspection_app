import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class GeneralInfoStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const GeneralInfoStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<GeneralInfoStep> createState() => _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<GeneralInfoStep> {
  // Contrôleurs
  late TextEditingController _etablissementController;
  late TextEditingController _installationController;
  late TextEditingController _activiteController;
  late TextEditingController _compteRenduController;
  
  // Données
  DateTime? _dateDebut;
  DateTime? _dateFin;
  int _dureeJours = 0;
  
  // Sélections
  String? _verificationType;
  String? _registreControle;
  
  // Listes
  List<Map<String, String>> _accompagnateurs = [];
  List<Map<String, String>> _verificateurs = [];
  
  // Focus
  final FocusNode _etablissementFocus = FocusNode();
  final FocusNode _installationFocus = FocusNode();
  final FocusNode _activiteFocus = FocusNode();
  final FocusNode _compteRenduFocus = FocusNode();

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
      'title': 'Non Présenté',
      'description': 'Le registre de contrôle n\'a pas été fourni',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  bool _isLoading = true;
  RenseignementsGeneraux? _data;

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
    _compteRenduController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _data = await HiveService.getOrCreateRenseignementsGeneraux(widget.mission.id);
      
      setState(() {
        _etablissementController.text = _data!.etablissement;
        _installationController.text = _data!.installation;
        _activiteController.text = _data!.activite;
        _compteRenduController.text = _data!.compteRendu;
        
        _dateDebut = _data!.dateDebut;
        _dateFin = _data!.dateFin;
        _dureeJours = _data!.dureeJours;
        _verificationType = _data!.verificationType;
        _registreControle = _data!.registreControle;
        _accompagnateurs = List.from(_data!.accompagnateurs);
        _verificateurs = List.from(_data!.verificateurs);
      });
    } catch (e) {
      print('❌ Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
    _data!.compteRendu = _compteRenduController.text;
    _data!.accompagnateurs = List.from(_accompagnateurs);
    _data!.verificateurs = List.from(_verificateurs);
    _data!.updatedAt = DateTime.now();
    
    await HiveService.saveRenseignementsGeneraux(_data!);
    
    widget.onDataChanged(_data!.toMap());
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

  Widget _buildStyledPicker({
    required String title,
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 0),
          // Options
          ...options.map((option) {
            final isSelected = selectedValue == option['value'];
            return InkWell(
              onTap: () => onSelected(option['value']),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (option['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        option['icon'],
                        color: option['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? option['color'] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: option['color'],
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          // Bouton fermer
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
  }) {
    final displayColor = color ?? (value != null ? AppTheme.primaryBlue : Colors.grey);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: displayColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: displayColor, size: 24),
          ],
        ),
      ),
    );
  }

  void _showAjouterAccompagnateurDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final posteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un accompagnateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: posteController,
              decoration: const InputDecoration(
                labelText: 'Poste / Fonction',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire'), backgroundColor: Colors.red),
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
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAjouterVerificateurDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un vérificateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire'), backgroundColor: Colors.red),
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
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _supprimerAccompagnateur(int index) async {
    setState(() {
      _accompagnateurs.removeAt(index);
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
    _compteRenduController.dispose();
    _etablissementFocus.dispose();
    _installationFocus.dispose();
    _activiteFocus.dispose();
    _compteRenduFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des données...'),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Text(
              'Renseignements Principaux',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Établissement
            _buildTextField(
              controller: _etablissementController,
              label: 'Établissement vérifié',
              icon: Icons.business,
              focusNode: _etablissementFocus,
            ),
            const SizedBox(height: 16),

            // Installation vérifiée
            _buildTextField(
              controller: _installationController,
              label: 'Installation vérifiée',
              icon: Icons.location_city,
              hint: 'Ex: Bâtiment A',
              focusNode: _installationFocus,
            ),
            const SizedBox(height: 16),

            // Activité principale
            _buildTextField(
              controller: _activiteController,
              label: 'Activité principale',
              icon: Icons.work_outline,
              hint: 'Ex: BTP, Industrie, Services...',
              focusNode: _activiteFocus,
            ),
            const SizedBox(height: 24),

            // Type de vérification - STYLISÉ
            _buildDisplayField(
              label: 'Type de vérification',
              value: _verificationType,
              hint: 'Sélectionnez le type de vérification',
              icon: Icons.verified_outlined,
              onTap: _showVerificationPicker,
              color: _verificationType != null ? Colors.blue : null,
            ),
            const SizedBox(height: 24),

            // Dates
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Période d\'intervention',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDateField(
                          label: 'Date de début',
                          date: _dateDebut,
                          icon: Icons.play_arrow,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          label: 'Date de fin',
                          date: _dateFin,
                          icon: Icons.check,
                          onTap: () => _selectDate(context, false),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.timer_outlined, color: AppTheme.primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Durée',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      '$_dureeJours jour(s)',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),

            // Accompagnateurs
            _buildDynamicListSection(
              title: 'Accompagnateurs',
              icon: Icons.people,
              color: Colors.blue,
              items: _accompagnateurs,
              itemBuilder: (accomp) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(accomp['nom']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (accomp['email']!.isNotEmpty)
                    Text(accomp['email']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (accomp['poste']!.isNotEmpty)
                    Text(accomp['poste']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              onAdd: _showAjouterAccompagnateurDialog,
              onDelete: _supprimerAccompagnateur,
            ),
            const SizedBox(height: 24),

            // Vérificateurs
            _buildDynamicListSection(
              title: 'Vérificateurs',
              icon: Icons.verified_user,
              color: Colors.green,
              items: _verificateurs,
              itemBuilder: (verif) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verif['nom']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (verif['email']!.isNotEmpty)
                    Text(verif['email']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              onAdd: _showAjouterVerificateurDialog,
              onDelete: _supprimerVerificateur,
            ),
            const SizedBox(height: 24),

            // Registre de contrôle - STYLISÉ
            _buildDisplayField(
              label: 'Registre de contrôle',
              value: _registreControle,
              hint: 'Sélectionnez l\'état du registre',
              icon: Icons.book_outlined,
              onTap: _showRegistrePicker,
              color: _registreControle != null 
                  ? (_registreControle == 'Présent' ? Colors.green : (_registreControle == 'Partiellement présent' ? Colors.orange : Colors.red))
                  : null,
            ),
            const SizedBox(height: 24),

            // Compte rendu
            _buildTextField(
              controller: _compteRenduController,
              label: 'Compte rendu de fin de visite fait à',
              icon: Icons.description_outlined,
              hint: 'Nom et prénom du destinataire',
              focusNode: _compteRenduFocus,
            ),
            const SizedBox(height: 32),
          ],
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
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, color: focusNode.hasFocus ? AppTheme.primaryBlue : Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null 
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                        : 'Non définie',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade400),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (items.isNotEmpty)
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: itemBuilder(item)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => onDelete(index),
                          ),
                        ],
                      ),
                    );
                  }),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('AJOUTER UN $title'.toUpperCase()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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