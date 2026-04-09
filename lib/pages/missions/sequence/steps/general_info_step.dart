import 'package:flutter/material.dart';
import 'package:inspec_app/pages/missions/sequence/sequence_progress_service.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

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
  late TextEditingController _registreControleController;
  late TextEditingController _compteRenduController;
  
  // Données
  DateTime? _dateDebut;
  DateTime? _dateFin;
  int _dureeJours = 0;
  
  // Sélections
  String? _verificationType;
  
  // Accompagnateurs
  List<Map<String, String>> _accompagnateurs = [];
  
  // Vérificateurs
  List<Map<String, String>> _verificateurs = [];
  
  // Focus
  final FocusNode _etablissementFocus = FocusNode();
  final FocusNode _installationFocus = FocusNode();
  final FocusNode _activiteFocus = FocusNode();
  final FocusNode _registreFocus = FocusNode();
  final FocusNode _compteRenduFocus = FocusNode();

  // Types de vérification disponibles
  final List<String> _verificationOptions = [
    'Périodique réglementaire',
    'Initiale réglementaire',
    'Audit réglementaire',
  ];

  @override
  void initState() {
    super.initState();
    _etablissementController = TextEditingController(text: widget.mission.nomClient);
    _installationController = TextEditingController();
    _activiteController = TextEditingController(text: widget.mission.activiteClient ?? '');
    _registreControleController = TextEditingController();
    _compteRenduController = TextEditingController();
    
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final savedData = await SequenceProgressService.getStepData(
        widget.mission.id, 
        'general_info'
      );
      
      if (savedData != null && savedData is Map<String, dynamic>) {
        setState(() {
          // Restaurer les champs texte
          _etablissementController.text = savedData['etablissement'] ?? widget.mission.nomClient;
          _installationController.text = savedData['installation'] ?? '';
          _activiteController.text = savedData['activite'] ?? widget.mission.activiteClient ?? '';
          _registreControleController.text = savedData['registreControle'] ?? '';
          _compteRenduController.text = savedData['compteRendu'] ?? '';
          
          // Restaurer les dates
          if (savedData['dateDebut'] != null) {
            _dateDebut = DateTime.parse(savedData['dateDebut']);
          }
          if (savedData['dateFin'] != null) {
            _dateFin = DateTime.parse(savedData['dateFin']);
          }
          _calculateDuree();
          
          // Restaurer le type de vérification
          _verificationType = savedData['verificationType'];
          
          // Restaurer les accompagnateurs
          if (savedData['accompagnateurs'] != null) {
            _accompagnateurs = List<Map<String, String>>.from(savedData['accompagnateurs']);
          }
          
          // Restaurer les vérificateurs
          if (savedData['verificateurs'] != null) {
            _verificateurs = List<Map<String, String>>.from(savedData['verificateurs']);
          }
        });
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    }
  }

  void _calculateDuree() {
    if (_dateDebut != null && _dateFin != null) {
      _dureeJours = _dateFin!.difference(_dateDebut!).inDays;
    } else {
      _dureeJours = 0;
    }
    setState(() {});
    _notifyDataChanged();
  }

  void _notifyDataChanged() async {
    final data = {
      'etablissement': _etablissementController.text,
      'installation': _installationController.text,
      'activite': _activiteController.text,
      'dateDebut': _dateDebut?.toIso8601String(),
      'dateFin': _dateFin?.toIso8601String(),
      'dureeJours': _dureeJours,
      'verificationType': _verificationType,
      'registreControle': _registreControleController.text,
      'accompagnateurs': _accompagnateurs,
      'verificateurs': _verificateurs,
      'compteRendu': _compteRenduController.text,
    };
    
    // Sauvegarde automatique à chaque changement
    await SequenceProgressService.saveStepData(widget.mission.id, 'general_info', data);
    widget.onDataChanged(data);
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
      _notifyDataChanged();
    }
  }

  void _showAjouterAccompagnateurDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final posteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ajouter un accompagnateur',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
            onPressed: () {
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
              _notifyDataChanged();
              Navigator.pop(context);
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
        title: const Text(
          'Ajouter un vérificateur',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
            onPressed: () {
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
              _notifyDataChanged();
              Navigator.pop(context);
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

  void _supprimerAccompagnateur(int index) {
    setState(() {
      _accompagnateurs.removeAt(index);
    });
    _notifyDataChanged();
  }

  void _supprimerVerificateur(int index) {
    setState(() {
      _verificateurs.removeAt(index);
    });
    _notifyDataChanged();
  }

  @override
  void dispose() {
    _etablissementController.dispose();
    _installationController.dispose();
    _activiteController.dispose();
    _registreControleController.dispose();
    _compteRenduController.dispose();
    _etablissementFocus.dispose();
    _installationFocus.dispose();
    _activiteFocus.dispose();
    _registreFocus.dispose();
    _compteRenduFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
      
            // Type de vérification (Dropdown)
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
              child: DropdownButtonFormField<String>(
                value: _verificationType,
                decoration: InputDecoration(
                  labelText: 'Vérification',
                  prefixIcon: Icon(Icons.verified_outlined, color: AppTheme.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                items: _verificationOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _verificationType = value;
                  });
                  _notifyDataChanged();
                },
              ),
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.people, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Accompagnateurs',
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
                        // Liste des accompagnateurs
                        if (_accompagnateurs.isNotEmpty)
                          ..._accompagnateurs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final accomp = entry.value;
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
                                  const Icon(Icons.person, size: 20, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          accomp['nom']!,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (accomp['email']!.isNotEmpty)
                                          Text(
                                            accomp['email']!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        if (accomp['poste']!.isNotEmpty)
                                          Text(
                                            accomp['poste']!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _supprimerAccompagnateur(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        
                        // Bouton ajouter
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAjouterAccompagnateurDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('AJOUTER UN ACCOMPAGNATEUR'),
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
            ),
            const SizedBox(height: 24),
      
            // Vérificateurs
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Vérificateurs',
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
                        // Liste des vérificateurs
                        if (_verificateurs.isNotEmpty)
                          ..._verificateurs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final verif = entry.value;
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
                                  const Icon(Icons.person, size: 20, color: Colors.green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          verif['nom']!,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (verif['email']!.isNotEmpty)
                                          Text(
                                            verif['email']!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _supprimerVerificateur(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        
                        // Bouton ajouter
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAjouterVerificateurDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('AJOUTER UN VÉRIFICATEUR'),
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
            ),
            const SizedBox(height: 24),
      
            // Registre de contrôle
            _buildTextField(
              controller: _registreControleController,
              label: 'Registre de contrôle',
              icon: Icons.book_outlined,
              hint: 'Numéro ou référence du registre',
              focusNode: _registreFocus,
            ),
            const SizedBox(height: 24),
      
            // Compte rendu de fin de visite fait à (champ texte)
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
            onChanged: (_) => _notifyDataChanged(),
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
}