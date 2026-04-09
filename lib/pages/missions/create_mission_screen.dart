// lib/pages/missions/create_mission_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late final CreateMissionData _formData;

  // Controllers
  final _nomClientCtrl = TextEditingController();
  final _activiteClientCtrl = TextEditingController();
  final _adresseClientCtrl = TextEditingController();
  final _dgResponsableCtrl = TextEditingController();
  final _natureMissionCtrl = TextEditingController();
  final _periodiciteCtrl = TextEditingController();
  final _dureeMissionCtrl = TextEditingController();

  DateTime? _selectedDateIntervention;
  DateTime? _selectedDateRapport;
  List<Verificateur> _allVerificateurs = [];
  List<Verificateur> _selectedVerificateurs = [];

  @override
  void initState() {
    super.initState();
    _loadVerificateurs();

  // Initialiser _formData avec des listes modifiables
  _formData = CreateMissionData(
    nomClient: '',
    accompagnateurs: [],  // Liste vide modifiable
    verificateurs: [],    // Liste vide modifiable
  );

    // Ajouter l'utilisateur courant par défaut
    _selectedVerificateurs.add(widget.currentUser);
  }

  void _loadVerificateurs() {
    _allVerificateurs = HiveService.getAllVerificateurs();
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isIntervention) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIntervention) {
          _selectedDateIntervention = picked;
        } else {
          _selectedDateRapport = picked;
        }
      });
    }
  }

  void _selectVerificateurs() async {
    final result = await showDialog<List<Verificateur>>(
      context: context,
      builder: (context) => VerificateurSelectionDialog(
        allVerificateurs: _allVerificateurs,
        selectedVerificateurs: _selectedVerificateurs,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedVerificateurs = result;
      });
    }
  }

  void _addAccompagnateur() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const AddAccompagnateurDialog(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _formData.accompagnateurs.add(result);
      });
    }
  }

  void _removeAccompagnateur(int index) {
    setState(() {
      _formData.accompagnateurs.removeAt(index);
    });
  }

  Future<void> _saveMission() async {
    if (!_formKey.currentState!.validate()) return;

    // Valider les vérificateurs
    if (_selectedVerificateurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un vérificateur')),
      );
      return;
    }

    // Remplir les données du formulaire
    _formData.nomClient = _nomClientCtrl.text.trim();
    _formData.activiteClient = _activiteClientCtrl.text.trim().isEmpty ? null : _activiteClientCtrl.text.trim();
    _formData.adresseClient = _adresseClientCtrl.text.trim().isEmpty ? null : _adresseClientCtrl.text.trim();
    _formData.dgResponsable = _dgResponsableCtrl.text.trim().isEmpty ? null : _dgResponsableCtrl.text.trim();
    _formData.natureMission = _natureMissionCtrl.text.trim().isEmpty ? null : _natureMissionCtrl.text.trim();
    _formData.periodicite = _periodiciteCtrl.text.trim().isEmpty ? null : _periodiciteCtrl.text.trim();
    _formData.dureeMissionJours = _dureeMissionCtrl.text.trim().isEmpty ? null : int.tryParse(_dureeMissionCtrl.text.trim());
    _formData.dateIntervention = _selectedDateIntervention;
    _formData.dateRapport = _selectedDateRapport;
    
    // Convertir les vérificateurs sélectionnés
    _formData.verificateurs = _selectedVerificateurs.map((v) => {
      'matricule': v.matricule,
      'nom': v.nom,
      'prenom': v.prenom,
    }).toList();

    // Créer l'ID unique
    final missionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Créer la mission
    final mission = _formData.toMission(missionId, widget.currentUser.matricule);
    
    // Sauvegarder
    await HiveService.saveMission(mission);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission créée avec succès')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nouvelle Mission'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveMission,
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Client
              _buildSectionTitle('Informations Client'),
              _buildTextField(_nomClientCtrl, 'Nom du client *', Icons.business),
              const SizedBox(height: 12),
              _buildTextField(_activiteClientCtrl, 'Activité du client', Icons.work),
              const SizedBox(height: 12),
              _buildTextField(_adresseClientCtrl, 'Adresse', Icons.location_on),

              const SizedBox(height: 24),
              _buildSectionTitle('Mission'),
              _buildTextField(_dgResponsableCtrl, 'DG / Responsable', Icons.person),
              const SizedBox(height: 12),
              _buildDateField('Date d\'intervention', _selectedDateIntervention, true),
              const SizedBox(height: 12),
              _buildDateField('Date du rapport', _selectedDateRapport, false),
              const SizedBox(height: 12),
              _buildTextField(_natureMissionCtrl, 'Nature de la mission', Icons.description),
              const SizedBox(height: 12),
              _buildTextField(_periodiciteCtrl, 'Périodicité', Icons.calendar_today),
              const SizedBox(height: 12),
              _buildTextField(_dureeMissionCtrl, 'Durée (jours)', Icons.timer, keyboardType: TextInputType.number),

              const SizedBox(height: 24),
              _buildSectionTitle('Vérificateurs'),
              _buildVerificateurSelector(),

              const SizedBox(height: 24),
              _buildSectionTitle('Accompagnateurs'),
              _buildAccompagnateursList(),

              const SizedBox(height: 32),
              // Bouton sauvegarde
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Créer la mission', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkBlue,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: label.contains('*') ? (v) => v?.isEmpty ?? true ? 'Requis' : null : null,
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate, bool isIntervention) {
    return InkWell(
      onTap: () => _selectDate(context, isIntervention),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(selectedDate)
                    : label,
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificateurSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.people),
        title: Text('${_selectedVerificateurs.length} vérificateur(s) sélectionné(s)'),
        subtitle: Text(_selectedVerificateurs.map((v) => v.fullName).join(', ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: _selectVerificateurs,
      ),
    );
  }

  Widget _buildAccompagnateursList() {
    return Column(
      children: [
        if (_formData.accompagnateurs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun accompagnateur', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._formData.accompagnateurs.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return Card(
              child: ListTile(
                title: Text(name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeAccompagnateur(index),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addAccompagnateur,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un accompagnateur'),
        ),
      ],
    );
  }
}

// Dialog pour sélectionner les vérificateurs
class VerificateurSelectionDialog extends StatefulWidget {
  final List<Verificateur> allVerificateurs;
  final List<Verificateur> selectedVerificateurs;

  const VerificateurSelectionDialog({
    super.key,
    required this.allVerificateurs,
    required this.selectedVerificateurs,
  });

  @override
  State<VerificateurSelectionDialog> createState() => _VerificateurSelectionDialogState();
}

class _VerificateurSelectionDialogState extends State<VerificateurSelectionDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedVerificateurs.map((v) => v.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner les vérificateurs'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.allVerificateurs.length,
          itemBuilder: (context, index) {
            final verif = widget.allVerificateurs[index];
            return CheckboxListTile(
              title: Text(verif.fullName),
              subtitle: Text(verif.matricule),
              value: _selectedIds.contains(verif.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedIds.add(verif.id);
                  } else {
                    _selectedIds.remove(verif.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final selected = widget.allVerificateurs
                .where((v) => _selectedIds.contains(v.id))
                .toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

// Dialog pour ajouter un accompagnateur
class AddAccompagnateurDialog extends StatefulWidget {
  const AddAccompagnateurDialog({super.key});

  @override
  State<AddAccompagnateurDialog> createState() => _AddAccompagnateurDialogState();
}

class _AddAccompagnateurDialogState extends State<AddAccompagnateurDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un accompagnateur'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nom complet',
          hintText: 'Ex: Jean Martin',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}