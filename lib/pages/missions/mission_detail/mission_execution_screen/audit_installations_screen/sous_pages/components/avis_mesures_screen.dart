import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class AvisMesuresScreen extends StatefulWidget {
  final Mission mission;

  const AvisMesuresScreen({super.key, required this.mission});

  @override
  State<AvisMesuresScreen> createState() => _AvisMesuresScreenState();
}

class _AvisMesuresScreenState extends State<AvisMesuresScreen> {
  final _observationController = TextEditingController();
  bool _isLoading = false;
  bool _hasData = false;
  List<String> _satisfaisants = [];
  List<String> _nonSatisfaisants = [];
  int _totalPrisesTerre = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _totalPrisesTerre = mesures.prisesTerre.length;
      
      
      _satisfaisants = List.from(mesures.avisMesuresTerre.satisfaisants);
      _nonSatisfaisants = List.from(mesures.avisMesuresTerre.nonSatisfaisants);
      
      if (mesures.avisMesuresTerre.observation != null) {
        _observationController.text = mesures.avisMesuresTerre.observation!;
        _hasData = true;
      }
    } catch (e) {
      print('❌ Erreur chargement avis mesures: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sauvegarder() async {
    if (_observationController.text.trim().isEmpty) {
      _showError('Veuillez saisir un avis');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final success = await HiveService.updateAvisMesuresTerre(
        missionId: widget.mission.id,
        observation: _observationController.text.trim(),
        satisfaisants: _satisfaisants,
        nonSatisfaisants: _nonSatisfaisants,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avis sur les mesures sauvegardé'),
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

  Widget _buildListChip(String label, List<String> items, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : Icons.warning,
                size: 16,
                color: color,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Aucun',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pourcentageSatisfaisant = _totalPrisesTerre > 0 
        ? ((_satisfaisants.length / _totalPrisesTerre) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Avis sur les mesures'),
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
                    
                    // Formulaire d'avis
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
                            'Avis et recommandations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Formulez votre avis global sur les mesures et proposez des actions correctives si nécessaire.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _observationController,
                            decoration: InputDecoration(
                              labelText: 'Avis et recommandations*',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 10,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir un avis';
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
                              'SAUVEGARDER L\'AVIS',
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
      ),
    );
  }

  Color _getPourcentageColor(int pourcentage) {
    if (pourcentage >= 80) return Colors.green;
    if (pourcentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }
}