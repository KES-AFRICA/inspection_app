import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';

class ConditionsMesureScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const ConditionsMesureScreen({super.key, required this.mission});

  @override
  ConsumerState<ConditionsMesureScreen> createState() => _ConditionsMesureScreenState();
}

class _ConditionsMesureScreenState extends ConsumerState<ConditionsMesureScreen> {
  final _observationController = TextEditingController();
  bool _isLoading = false;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      if (mesures.conditionMesure.observation != null) {
        _observationController.text = mesures.conditionMesure.observation!;
        _hasData = true;
      }
    } catch (e) {
      print('❌ Erreur chargement conditions mesure: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sauvegarder() async {
    if (_observationController.text.trim().isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      mesures.conditionMesure.observation = _observationController.text.trim();
      
      final success = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conditions de mesure sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _annuler() {
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conditions de mesure'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _annuler,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _sauvegarder,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Formulaire d'observation
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observations sur les conditions de mesure',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _observationController,
                          decoration: InputDecoration(
                            labelText: 'Observations*',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Température ambiante 25°C, humidité relative 60%, bonnes conditions de mesure...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLines: 8,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir des observations';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Boutons d'action
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _sauvegarder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'SAUVEGARDER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _annuler,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'ANNULER',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }
}