// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/description_installations_form.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class DescriptionInstallationsForm extends StatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;
  final List<String> requiredFields;
  final Function(String) onComplete;
  final bool isComplete;

  const DescriptionInstallationsForm({
    super.key,
    required this.mission,
    required this.title,
    required this.sectionKey,
    required this.champs,
    required this.requiredFields,
    required this.onComplete,
    required this.isComplete,
  });

  @override
  State<DescriptionInstallationsForm> createState() => _DescriptionInstallationsFormState();
}

class _DescriptionInstallationsFormState extends State<DescriptionInstallationsForm> {
  List<InstallationItem> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // ✅ OPTIONS POUR TYPE DE CELLULE
  static const List<String> _typeCelluleOptions = [
    'I : Interrupteur-sectionneur (arrivée / départ boucle)',
    'IM : Interrupteur-sectionneur avec mise à la terre',
    'IQ : Interrupteur avec disjoncteur',
    'ID : Interrupteur départ ligne',
    'Q : Disjoncteur HTA',
    'IF : Interrupteur-fusibles (protection transformateur)',
    'D : Départ direct',
    'DM : Départ avec mise à la terre',
    'M : Mesure HTA',
    'DE : Cellule de mise à la terre',
    'QM : Interrupteur-sectionneur (arrivée, boucle, couplage)',
    'QMC : Interrupteur motorisé',
    'QF : Interrupteur-fusibles (protection transformateur)',
    'DM1 / DM2 : Départ câble',
    'GBC : Disjoncteur général',
    'BC : Couplage jeux de barres',
    'SE : Sectionnement avec mise à la terre',
    'Incoming (I) : Arrivée réseau',
    'Outgoing (O) : Départ ligne ou câble',
    'Bus Coupler (BC) : Couplage jeux de barres',
    'Transformer Feeder (TF) : Départ transformateur',
    'Generator Feeder (GF) : Groupe électrogène',
    'Motor Feeder (MF) : Moteur HTA',
    'Capacitor Feeder (CF) : Batterie de condensateurs',
    'Metering (M) : Mesure HTA',
    'Bus Riser (BR) : Liaison tableau',
  ];

  // ✅ Liste des sections de câble disponibles
  static const List<String> _sectionCableOptions = [
    '0,5 mm²', '0,75 mm²', '1 mm²', '1,5 mm²', '2,5 mm²', '4 mm²', '6 mm²',
    '10 mm²', '16 mm²', '25 mm²', '35 mm²', '50 mm²', '70 mm²', '95 mm²',
    '120 mm²', '150 mm²', '185 mm²', '240 mm²', '300 mm²', '400 mm²',
    '500 mm²', '630 mm²',
  ];

  // ✅ Options pour les différents champs dropdown
  final Map<String, List<String>> _dropdownOptions = {
    'Type De Cellule': _typeCelluleOptions,
    'Nature Du Reseau': ['Aérien', 'Souterrain', 'Mixte'],
    'Mode': ['Pompe électrique', 'Gravitaire', 'Manuel', 'Autre'],
    'Cuve De Retention': ['Oui', 'Non'],
    'Indicateur De Niveau': ['Oui', 'Non'],
    'Mise A La Terre': ['Oui', 'Non'],
    'Section Du Cable': _sectionCableOptions,
  };

  // ✅ Générer les années (1900 à année actuelle)
  List<String> _getAnneeOptions() {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1900 + 1, (i) => (currentYear - i).toString());
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await HiveService.getInstallationItemsFromSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
      );
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(
          title: widget.title,
          champs: widget.champs,
          requiredFields: widget.requiredFields,
          dropdownOptions: _dropdownOptions,
          anneeOptions: _getAnneeOptions(),
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      
      final newItem = InstallationItem(data: result);
      final success = await HiveService.addInstallationItemToSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        item: newItem,
      );
      
      if (success) {
        await _loadData();
        _checkAndNotifyComplete();
        
        if (mounted) {
          // ✅ AFFICHER LE DIALOGUE APRÈS L'ENREGISTREMENT
          final shouldContinue = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(20),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enregistrement réussi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Voulez-vous continuer à ajouter des éléments ou terminer ?',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('CONTINUER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('TERMINER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (shouldContinue == true) {
            // CONTINUER : rouvrir l'écran d'ajout
            _addItem();
          }
          // TERMINER : ne rien faire, rester sur la liste
        }
      }
      
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddEditItemScreen(
          title: widget.title,
          champs: widget.champs,
          requiredFields: widget.requiredFields,
          initialData: item.data,
          dropdownOptions: _dropdownOptions,
          anneeOptions: _getAnneeOptions(),
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      
      final updatedItem = InstallationItem(data: result, photoPaths: item.photoPaths);
      final success = await HiveService.updateInstallationItemInSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        index: index,
        item: updatedItem,
      );
      
      if (success) {
        await _loadData();
        _checkAndNotifyComplete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modifié avec succès'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
          );
        }
      }
      
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cet élément ?'),
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
      setState(() => _isSaving = true);
      
      final success = await HiveService.removeInstallationItemFromSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        index: index,
      );
      
      if (success) {
        await _loadData();
        _checkAndNotifyComplete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supprimé avec succès'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
          );
        }
      }
      
      setState(() => _isSaving = false);
    }
  }

  void _checkAndNotifyComplete() {
    if (_items.isNotEmpty && !widget.isComplete) {
      widget.onComplete(widget.sectionKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState(isSmallScreen)
                  : ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(_items[index], index, isSmallScreen);
                      },
                    ),
            ),
          ],
        ),
        
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _isSaving ? null : _addItem,
            backgroundColor: Colors.green,
            child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: isSmallScreen ? 60 : 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton + pour ajouter',
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InstallationItem item, int index, bool isSmallScreen) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
      child: InkWell(
        onTap: () => _editItem(index),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.title}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red, size: isSmallScreen ? 18 : 20),
                    onPressed: () => _deleteItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ...widget.champs.where((champ) => item.data.containsKey(champ) && item.data[champ]!.isNotEmpty).map((champ) {
                final value = item.data[champ]!;
                return Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? 100 : 120,
                        child: Text(
                          '$champ:',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
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
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              if (item.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: item.photoPaths.map((path) => 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo, size: isSmallScreen ? 10 : 12, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            'Photo',
                            style: TextStyle(fontSize: isSmallScreen ? 9 : 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ÉCRAN D'AJOUT/MODIFICATION D'UN ÉLÉMENT
// ============================================================
class _AddEditItemScreen extends StatefulWidget {
  final String title;
  final List<String> champs;
  final List<String> requiredFields;
  final Map<String, String>? initialData;
  final Map<String, List<String>> dropdownOptions;
  final List<String> anneeOptions;

  const _AddEditItemScreen({
    required this.title,
    required this.champs,
    required this.requiredFields,
    this.initialData,
    required this.dropdownOptions,
    required this.anneeOptions,
  });

  @override
  State<_AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<_AddEditItemScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedValues = {};
  final Map<String, String?> _anneeFabrication = {};
  final Map<String, String?> _anneeInstallation = {};

  @override
  void initState() {
    super.initState();
    for (var champ in widget.champs) {
      _controllers[champ] = TextEditingController(text: widget.initialData?[champ] ?? '');
      _selectedValues[champ] = widget.initialData?[champ] ?? '';
      
      if (champ == 'Annee De Fabrication') {
        _anneeFabrication[champ] = widget.initialData?[champ] ?? '';
      }
      if (champ == 'Annee D\'Installation') {
        _anneeInstallation[champ] = widget.initialData?[champ] ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isYearValid(String year) {
    if (year.isEmpty) return true;
    final yearInt = int.tryParse(year);
    if (yearInt == null) return false;
    return yearInt <= DateTime.now().year;
  }

  bool _isInstallationYearValid(String fabricationYear, String installationYear) {
    if (fabricationYear.isEmpty || installationYear.isEmpty) return true;
    final fabInt = int.tryParse(fabricationYear);
    final instInt = int.tryParse(installationYear);
    if (fabInt == null || instInt == null) return true;
    return instInt >= fabInt;
  }

  void _validateInstallationYear() {
    final fabYear = _anneeFabrication['Annee De Fabrication'] ?? '';
    final instYear = _anneeInstallation['Annee D\'Installation'] ?? '';
    
    if (fabYear.isNotEmpty && instYear.isNotEmpty) {
      final fabInt = int.tryParse(fabYear);
      final instInt = int.tryParse(instYear);
      if (fabInt != null && instInt != null && instInt < fabInt) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("L'année d'installation ne peut pas être antérieure à l'année de fabrication"),
            backgroundColor: Colors.orange,
          ),
        );
        _anneeInstallation['Annee D\'Installation'] = fabYear;
        setState(() {});
      }
    }
  }

  bool _isFormValid() {
    for (var champ in widget.requiredFields) {
      String value;
      if (widget.dropdownOptions.containsKey(champ)) {
        value = _selectedValues[champ] ?? '';
      } else if (champ == 'Annee De Fabrication' || champ == 'Annee D\'Installation') {
        value = champ == 'Annee De Fabrication' 
            ? (_anneeFabrication[champ] ?? '')
            : (_anneeInstallation[champ] ?? '');
      } else {
        value = _controllers[champ]?.text.trim() ?? '';
      }
      if (value.isEmpty) return false;
      if (champ == 'Annee De Fabrication' && !_isYearValid(value)) return false;
    }
    return true;
  }

  void _save() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires correctement'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = <String, String>{};
    for (var champ in widget.champs) {
      String value;
      if (widget.dropdownOptions.containsKey(champ)) {
        value = _selectedValues[champ] ?? '';
      } else if (champ == 'Annee De Fabrication') {
        value = _anneeFabrication[champ] ?? '';
      } else if (champ == 'Annee D\'Installation') {
        value = _anneeInstallation[champ] ?? '';
      } else {
        value = _controllers[champ]?.text.trim() ?? '';
      }
      if (value.isNotEmpty) {
        result[champ] = value;
      }
    }

    // ✅ Retourner le résultat pour fermer l'écran d'ajout
    Navigator.pop(context, result);
  }

  // ✅ Méthode appelée APRÈS l'enregistrement (dans le parent)
  // Le dialogue sera affiché dans _AddEditItemScreenState après le pop
  // Mais on va plutôt afficher le dialogue dans le parent après le retour

  Widget _buildField(String champ) {
    final isRequired = widget.requiredFields.contains(champ);
    final hasOptions = widget.dropdownOptions.containsKey(champ);
    final isAnneeFabrication = champ == 'Annee De Fabrication';
    final isAnneeInstallation = champ == 'Annee D\'Installation';
    
    if (isAnneeFabrication || isAnneeInstallation) {
      final currentValue = isAnneeFabrication 
          ? _anneeFabrication[champ] 
          : _anneeInstallation[champ];
      
      return Container(
        margin: EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: currentValue?.isNotEmpty == true ? currentValue : null,
          isExpanded: true,
          hint: Text(
            'Sélectionnez $champ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          decoration: InputDecoration(
            labelText: isRequired ? '$champ *' : champ,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: widget.anneeOptions.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (isAnneeFabrication) {
                _anneeFabrication[champ] = value;
              } else {
                _anneeInstallation[champ] = value;
                _validateInstallationYear();
              }
            });
          },
        ),
      );
    }
    
    if (hasOptions) {
      final options = widget.dropdownOptions[champ]!;
      return Container(
        margin: EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          value: _selectedValues[champ]?.isNotEmpty == true ? _selectedValues[champ] : null,
          isExpanded: true,
          hint: Text(
            'Sélectionnez $champ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          decoration: InputDecoration(
            labelText: isRequired ? '$champ *' : champ,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedValues[champ] = value;
            });
          },
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[champ],
        decoration: InputDecoration(
          labelText: champ,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: champ == 'Observations' ? 3 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialData != null ? 'Modifier' : 'Ajouter',
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
              
              ...widget.champs.map((champ) => _buildField(champ)),
            ],
          ),
        ),
      ),
    );
  }
}