// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/prises_terre_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class PrisesTerreScreen extends StatefulWidget {
  final Mission mission;

  const PrisesTerreScreen({super.key, required this.mission});

  @override
  State<PrisesTerreScreen> createState() => _PrisesTerreScreenState();
}

class _PrisesTerreScreenState extends State<PrisesTerreScreen> {
  List<PriseTerre> _prisesTerre = [];
  bool _isLoading = true;

  // ✅ Options pour "Condition prise de terre"
  final List<String> _conditionOptions = ['Barette ouverte', 'Barette fermée'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      setState(() {
        _prisesTerre = List.from(mesures.prisesTerre);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterPriseTerre() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AjouterPriseTerreScreen(
          conditionOptions: _conditionOptions,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final nouvellePrise = PriseTerre(
        localisation: result['localisation'] ?? '',
        identification: result['identification'] ?? '',
        conditionPriseTerre: result['conditionPriseTerre'] ?? 'Barette fermée', // ✅ Valeur par défaut
        naturePriseTerre: result['naturePriseTerre'] ?? '',
        methodeMesure: result['methodeMesure'] ?? '',
        valeurMesure: double.tryParse(result['valeurMesure']?.toString() ?? ''),
        observation: result['observation'],
      );
      
      final success = await HiveService.addPriseTerre(
        missionId: widget.mission.id,
        priseTerre: nouvellePrise,
      );
      
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prise de terre ajoutée'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  Future<void> _editerPriseTerre(int index) async {
    final prise = _prisesTerre[index];
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AjouterPriseTerreScreen(
          initialData: {
            'localisation': prise.localisation,
            'identification': prise.identification,
            'conditionPriseTerre': prise.conditionPriseTerre,
            'naturePriseTerre': prise.naturePriseTerre,
            'methodeMesure': prise.methodeMesure,
            'valeurMesure': prise.valeurMesure?.toString() ?? '',
            'observation': prise.observation ?? '',
          },
          conditionOptions: _conditionOptions,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final updatedPrise = PriseTerre(
        localisation: result['localisation'] ?? '',
        identification: result['identification'] ?? '',
        conditionPriseTerre: result['conditionPriseTerre'] ?? 'Barette fermée',
        naturePriseTerre: result['naturePriseTerre'] ?? '',
        methodeMesure: result['methodeMesure'] ?? '',
        valeurMesure: double.tryParse(result['valeurMesure']?.toString() ?? ''),
        observation: result['observation'],
      );
      
      final success = await HiveService.updatePriseTerre(
        missionId: widget.mission.id,
        index: index,
        priseTerre: updatedPrise,
      );
      
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prise de terre modifiée'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  Future<void> _supprimerPriseTerre(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette prise de terre ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await HiveService.deletePriseTerre(
        missionId: widget.mission.id,
        index: index,
      );
      
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prise de terre supprimée'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prises de terre'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterPriseTerre,
            tooltip: 'Ajouter une prise de terre',
          ),
        ],
      ),
      body: _prisesTerre.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_outlined, size: isSmallScreen ? 60 : 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune prise de terre',
                    style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur le bouton + pour ajouter',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              itemCount: _prisesTerre.length,
              itemBuilder: (context, index) {
                final prise = _prisesTerre[index];
                return Card(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                  child: InkWell(
                    onTap: () => _editerPriseTerre(index),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: isSmallScreen ? 28 : 32,
                                height: isSmallScreen ? 28 : 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  prise.identification,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red, size: isSmallScreen ? 18 : 20),
                                onPressed: () => _supprimerPriseTerre(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Localisation', prise.localisation, isSmallScreen),
                          _buildInfoRow('Condition prise de terre', prise.conditionPriseTerre, isSmallScreen),
                          _buildInfoRow('Nature prise de terre', prise.naturePriseTerre, isSmallScreen),
                          _buildInfoRow('Méthode de mesure', prise.methodeMesure, isSmallScreen),
                          _buildInfoRow('Valeur mesurée', prise.valeurMesure?.toString() ?? '-', isSmallScreen),
                          if (prise.observation != null && prise.observation!.isNotEmpty)
                            _buildInfoRow('Observation', prise.observation!, isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 100 : 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ÉCRAN D'AJOUT/MODIFICATION D'UNE PRISE DE TERRE
// ============================================================
class _AjouterPriseTerreScreen extends StatefulWidget {
  final Map<String, String>? initialData;
  final List<String> conditionOptions;

  const _AjouterPriseTerreScreen({
    this.initialData,
    required this.conditionOptions,
  });

  @override
  State<_AjouterPriseTerreScreen> createState() => _AjouterPriseTerreScreenState();
}

class _AjouterPriseTerreScreenState extends State<_AjouterPriseTerreScreen> {
  final _localisationController = TextEditingController();
  final _identificationController = TextEditingController();
  String? _conditionMesure;
  String? _naturePriseTerre;
  String? _methodeMesure;
  final _valeurMesureController = TextEditingController();
  final _observationController = TextEditingController();

  final List<String> _natureOptions = [
    'Piquet de terre',
    'Fond de fouille interconnecté',
    'Autre',
  ];

  final List<String> _methodeOptions = [
    'Impédance de boucle',
    'Résistance de terre',
    'Méthode des 62%',
    'Méthode de chute de potentiel',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _localisationController.text = widget.initialData!['localisation'] ?? '';
      _identificationController.text = widget.initialData!['identification'] ?? '';
      _conditionMesure = widget.initialData!['conditionMesure'] ?? 'Barette fermée';
      _naturePriseTerre = widget.initialData!['naturePriseTerre'];
      _methodeMesure = widget.initialData!['methodeMesure'];
      _valeurMesureController.text = widget.initialData!['valeurMesure'] ?? '';
      _observationController.text = widget.initialData!['observation'] ?? '';
    } else {
      // ✅ Valeur par défaut pour condition prise de terre
      _conditionMesure = 'Barette fermée';
    }
  }

  @override
  void dispose() {
    _localisationController.dispose();
    _identificationController.dispose();
    _valeurMesureController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _localisationController.text.trim().isNotEmpty &&
           _identificationController.text.trim().isNotEmpty &&
           _conditionMesure != null &&
           _naturePriseTerre != null &&
           _methodeMesure != null;
  }

  void _save() {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = {
      'localisation': _localisationController.text.trim(),
      'identification': _identificationController.text.trim(),
      'conditionMesure': _conditionMesure,
      'naturePriseTerre': _naturePriseTerre,
      'methodeMesure': _methodeMesure,
      'valeurMesure': _valeurMesureController.text.trim(),
      'observation': _observationController.text.trim(),
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData != null ? 'Modifier la prise de terre' : 'Ajouter une prise de terre',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: isSmallScreen ? 20 : 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les champs marqués * sont obligatoires',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Localisation *
              _buildTextField(_localisationController, 'Localisation *', isSmallScreen),
              const SizedBox(height: 14),
              
              // Identification *
              _buildTextField(_identificationController, 'Identification *', isSmallScreen),
              const SizedBox(height: 14),
              
              // Condition prise de terre * (Dropdown avec valeur par défaut)
              _buildDropdown(
                label: 'Condition prise de terre *',
                value: _conditionMesure,
                options: widget.conditionOptions,
                onChanged: (value) => setState(() => _conditionMesure = value),
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 14),
              
              // Nature prise de terre *
              _buildDropdown(
                label: 'Nature prise de terre *',
                value: _naturePriseTerre,
                options: _natureOptions,
                onChanged: (value) => setState(() => _naturePriseTerre = value),
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 14),
              
              // Méthode de mesure *
              _buildDropdown(
                label: 'Méthode de mesure *',
                value: _methodeMesure,
                options: _methodeOptions,
                onChanged: (value) => setState(() => _methodeMesure = value),
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 14),
              
              // Valeur mesurée (optionnel)
              _buildTextField(_valeurMesureController, 'Valeur mesurée (Ω)', isSmallScreen,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              
              // Observation (optionnel)
              _buildTextField(_observationController, 'Observation', isSmallScreen, maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isSmallScreen,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    final isRequired = label.contains('*');
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    required bool isSmallScreen,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text('Sélectionnez...', style: TextStyle(color: Colors.grey.shade500)),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}