import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ContinuiteResistanceScreen extends StatefulWidget {
  final Mission mission;

  const ContinuiteResistanceScreen({super.key, required this.mission});

  @override
  State<ContinuiteResistanceScreen> createState() => _ContinuiteResistanceScreenState();
}

class _ContinuiteResistanceScreenState extends State<ContinuiteResistanceScreen> {
  List<ContinuiteResistance> _mesures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMesures();
  }

  Future<void> _loadMesures() async {
    setState(() => _isLoading = true);
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      _mesures = mesures.continuiteResistances;
    } catch (e) {
      print('❌ Erreur chargement continuité/résistance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _ajouterMesure() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterContinuiteResistanceScreen(
          mission: widget.mission,
        ),
      ),
    );

    if (result == true) {
      await _loadMesures();
    }
  }

  void _editerMesure(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterContinuiteResistanceScreen(
          mission: widget.mission,
          mesure: _mesures[index],
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadMesures();
    }
  }

  Future<void> _supprimerMesure(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: TextStyle(fontSize: 18)),
        content: Text('Voulez-vous vraiment supprimer cette mesure ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deleteContinuiteResistance(
                missionId: widget.mission.id,
                index: index,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mesure supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadMesures();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesureCard(ContinuiteResistance mesure, int index) {
    
    Color cardColor;
      cardColor = Colors.grey;
    

    return  Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: InkWell(
        onTap: () => _editerMesure(index),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          mesure.designationTableau,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerMesure(index);
                      } else if (value == 'delete') {
                        _supprimerMesure(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mesure.localisation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Détails de la mesure
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origine de mesure
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Origine de mesure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          mesure.origineMesure,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Observation
                    if (mesure.observation != null && mesure.observation!.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Divider(),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Observation',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            mesure.observation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Continuité et résistance'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _ajouterMesure,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: Icon(Icons.add),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  
                  if (_mesures.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cable_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune mesure de continuité',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Cliquez sur le bouton + pour ajouter une mesure',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadMesures,
                        child: ListView.builder(
                          itemCount: _mesures.length,
                          itemBuilder: (context, index) {
                            return _buildMesureCard(_mesures[index], index);
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// Écran pour ajouter/modifier une mesure
class AjouterContinuiteResistanceScreen extends StatefulWidget {
  final Mission mission;
  final ContinuiteResistance? mesure;
  final int? index;

  const AjouterContinuiteResistanceScreen({
    super.key,
    required this.mission,
    this.mesure,
    this.index,
  });

  bool get isEdition => mesure != null;

  @override
  State<AjouterContinuiteResistanceScreen> createState() => _AjouterContinuiteResistanceScreenState();
}

class _AjouterContinuiteResistanceScreenState extends State<AjouterContinuiteResistanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localisationController = TextEditingController();
  final _tableauController = TextEditingController();
  final _origineController = TextEditingController();
  final _resistanceController = TextEditingController();
  final _observationController = TextEditingController();
  
  String? _selectedStatut;
  
  List<String> _localisations = [];

  @override
  void initState() {
    super.initState();
    _chargerLocalisations();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    }
  }

  void _chargerLocalisations() {
    _localisations = HiveService.getLocalisationsForEssais(widget.mission.id);
    if (_localisations.isEmpty) {
      _localisations = ['Local technique', 'TGBT', 'Tableau divisionnaire'];
    }
  }

  void _chargerDonneesExistantes() {
    final mesure = widget.mesure!;
    _localisationController.text = mesure.localisation;
    _tableauController.text = mesure.designationTableau;
    _origineController.text = mesure.origineMesure;

    if (mesure.observation != null) {
      _observationController.text = mesure.observation!;
    }}

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      final mesure = ContinuiteResistance(
        localisation: _localisationController.text.trim(),
        designationTableau: _tableauController.text.trim(),
        origineMesure: _origineController.text.trim(),
        observation: _observationController.text.trim().isNotEmpty
            ? _observationController.text.trim()
            : null,
      );

      bool success;
      if (widget.isEdition) {
        success = await HiveService.updateContinuiteResistance(
          missionId: widget.mission.id,
          index: widget.index!,
          mesure: mesure,
        );
      } else {
        success = await HiveService.addContinuiteResistance(
          missionId: widget.mission.id,
          mesure: mesure,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdition ? 'Mesure modifiée' : 'Mesure ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = true, int maxLines = 1}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '$label${isRequired ? '*' : ''}',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: maxLines,
            validator: isRequired ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir $label';
              }
              return null;
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged, {bool isRequired = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label${isRequired ? '*' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Sélectionnez...'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdition ? 'Modifier mesure' : 'Ajouter mesure'),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Formulaire
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildDropdown(
                      'Localisation*',
                      _localisations,
                      _localisationController.text.isNotEmpty ? _localisationController.text : _localisations.first,
                      (value) {
                        if (value != null) {
                          setState(() => _localisationController.text = value);
                        }
                      },
                    ),
                    
                    _buildTextField('Désignation du tableau*', _tableauController),
                    
                    _buildTextField('Origine de mesure*', _origineController,
                      maxLines: 2,
                    ),
                    
                    
                    _buildTextField('Observation', _observationController, isRequired: false, maxLines: 3),
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
                        widget.isEdition ? 'MODIFIER' : 'AJOUTER',
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

  @override
  void dispose() {
    _localisationController.dispose();
    _tableauController.dispose();
    _origineController.dispose();
    _resistanceController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}