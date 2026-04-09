// lib/pages/missions/create_mission_screen.dart (simplifié)
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/create_mission_data.dart';
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
  final _nomClientCtrl = TextEditingController();
  final _activiteClientCtrl = TextEditingController();
  final _adresseClientCtrl = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nomClientCtrl.dispose();
    _activiteClientCtrl.dispose();
    _adresseClientCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Créer l'ID unique
    final missionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Créer les données de la mission
    final formData = CreateMissionData(
      nomClient: _nomClientCtrl.text.trim(),
      activiteClient: _activiteClientCtrl.text.trim().isEmpty 
          ? null 
          : _activiteClientCtrl.text.trim(),
      adresseClient: _adresseClientCtrl.text.trim().isEmpty 
          ? null 
          : _adresseClientCtrl.text.trim(),
    );
    
    // Créer la mission
    final mission = formData.toMission(missionId, widget.currentUser.email);
    
    // Sauvegarder
    await HiveService.saveMission(mission);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission créée avec succès'),
          backgroundColor: Colors.green,
        ),
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
            onPressed: _isLoading ? null : _saveMission,
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
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
              // Illustration
              Center(
                child: Icon(
                  Icons.assignment_add,
                  size: 80,
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              
              Center(
                child: Text(
                  'Créer une nouvelle mission',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Center(
                child: Text(
                  'Vous pourrez compléter les détails plus tard',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Nom du client (obligatoire)
              TextFormField(
                controller: _nomClientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Entreprise XYZ',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Activité du client
              TextFormField(
                controller: _activiteClientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Activité du client',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: BTP, Industrie, Services...',
                ),
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _adresseClientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 123 Rue Example, Ville',
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Les informations comme les dates, vérificateurs et documents pourront être ajoutées dans la page de détail de la mission.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Bouton créer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Créer la mission', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}