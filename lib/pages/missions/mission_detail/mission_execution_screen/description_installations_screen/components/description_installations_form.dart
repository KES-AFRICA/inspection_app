// description_installations_form.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/item_detail_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class DescriptionInstallationsForm extends StatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;
  final List<String> requiredFields;
  final void Function(String sectionKey) onComplete;
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
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _photoPaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _addingMore = false;
  List<InstallationItem> _items = [];
  
  // Scroll controller
  final ScrollController _scrollController = ScrollController();
  
  // Variables pour les dropdowns Oui/Non
  String? _selectedCuveRetention;
  String? _selectedIndicateurNiveau;
  String? _selectedMiseALaTerre;
  
  // Variable pour section de câble
  String? _selectedSectionCable;
  
  // Variable pour TYPE DE CELLULE
  String? _selectedTypeCellule;
  
  // Options Oui/Non
  static const List<String> _ouiNonOptions = ['Oui', 'Non'];
  
  // Options pour TYPE DE CELLULE
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

    'Q : Disjoncteur HTA',

    'DM1 / DM2 : Départ câble',

    'GBC : Disjoncteur général',

    'BC : Couplage jeux de barres',

    'M : Mesure HTA',

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
  
  // Liste des sections de câble disponibles
  static const List<String> _sectionCableOptions = [
    '0,5 mm²', '0,75 mm²', '1 mm²', '1,5 mm²', '2,5 mm²', '4 mm²', '6 mm²',
    '10 mm²', '16 mm²', '25 mm²', '35 mm²', '50 mm²', '70 mm²', '95 mm²',
    '120 mm²', '150 mm²', '185 mm²', '240 mm²', '300 mm²', '400 mm²',
    '500 mm²', '630 mm²',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadExistingItems();
  }

  void _initializeForm() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    for (var champ in widget.champs) {
      _controllers[champ] = TextEditingController();
    }
    _photoPaths.clear();
    _addingMore = false;
    _selectedCuveRetention = null;
    _selectedIndicateurNiveau = null;
    _selectedMiseALaTerre = null;
    _selectedSectionCable = null;
    _selectedTypeCellule = null;
  }

  Future<void> _loadExistingItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final items = await HiveService.getInstallationItemsFromSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
      );
      
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() => _photoPaths.add(photo.path));
      _scrollToBottom();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null && mounted) {
      setState(() => _photoPaths.add(photo.path));
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removePhoto(int index) {
    if (!mounted) return;
    setState(() => _photoPaths.removeAt(index));
  }

  bool _estChampObservations(String champ) {
    final lowerChamp = champ.toLowerCase();
    return lowerChamp.contains('observation') || 
           lowerChamp.contains('remarque') ||
           lowerChamp.contains('note');
  }

  bool _isTypeCelluleField(String champ) {
    return champ == 'Type De Cellule';
  }

  bool _isSectionCableField(String champ) {
    final lowerChamp = champ.toUpperCase();
    return lowerChamp.contains('SECTION') && 
           (lowerChamp.contains('CABLE') || lowerChamp.contains('CÂBLE'));
  }

  bool _isAnneeField(String champ) {
    final upperChamp = champ.toUpperCase();
    return upperChamp.contains('ANNEE') || upperChamp.contains('ANNÉE');
  }

  bool _isCuveRetentionField(String champ) {
    final upperChamp = champ.toUpperCase();
    return upperChamp.contains('CUVE') && upperChamp.contains('RETENTION');
  }

  bool _isIndicateurNiveauField(String champ) {
    final upperChamp = champ.toUpperCase();
    return upperChamp.contains('INDICATEUR') && upperChamp.contains('NIVEAU');
  }

  bool _isMiseALaTerreField(String champ) {
    final upperChamp = champ.toUpperCase();
    return upperChamp.contains('MISE') && upperChamp.contains('TERRE');
  }

  bool _isOuiNonField(String champ) {
    return _isCuveRetentionField(champ) || 
           _isIndicateurNiveauField(champ) || 
           _isMiseALaTerreField(champ);
  }

  bool _hasAtLeastOneFieldFilled() {
    for (var champ in widget.champs) {
      if (_isTypeCelluleField(champ)) {
        if (_selectedTypeCellule != null && _selectedTypeCellule!.isNotEmpty) return true;
      } else if (_isOuiNonField(champ)) {
        final value = _getOuiNonFieldValue(champ);
        if (value != null && value.isNotEmpty) return true;
      } else if (_isSectionCableField(champ)) {
        if (_selectedSectionCable != null && _selectedSectionCable!.isNotEmpty) return true;
      } else {
        final value = _controllers[champ]!.text.trim();
        if (value.isNotEmpty) return true;
      }
    }
    if (_photoPaths.isNotEmpty) return true;
    return false;
  }

  String? _getOuiNonFieldValue(String champ) {
    if (_isCuveRetentionField(champ)) return _selectedCuveRetention;
    if (_isIndicateurNiveauField(champ)) return _selectedIndicateurNiveau;
    if (_isMiseALaTerreField(champ)) return _selectedMiseALaTerre;
    return null;
  }

  void _setOuiNonFieldValue(String champ, String? value) {
    setState(() {
      if (_isCuveRetentionField(champ)) {
        _selectedCuveRetention = value;
        _controllers[champ]?.text = value ?? '';
      } else if (_isIndicateurNiveauField(champ)) {
        _selectedIndicateurNiveau = value;
        _controllers[champ]?.text = value ?? '';
      } else if (_isMiseALaTerreField(champ)) {
        _selectedMiseALaTerre = value;
        _controllers[champ]?.text = value ?? '';
      }
    });
  }

  String? _validateAnnee(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    
    final annee = int.tryParse(value.trim());
    final anneeActuelle = DateTime.now().year;
    
    if (annee == null) {
      return 'Veuillez entrer une année valide (ex: 2023)';
    }
    if (annee < 1900) {
      return 'L\'année doit être supérieure à 1900';
    }
    if (annee > anneeActuelle) {
      return 'L\'année ne peut pas dépasser $anneeActuelle';
    }
    return null;
  }

  String? _validateFabricationVsInstallation() {
    if (widget.sectionKey != 'stabilisateur') return null;
    
    final anneeFabController = _controllers['Annee De Fabrication'];
    final anneeInstController = _controllers['Annee D\'Installation'];
    
    if (anneeFabController == null || anneeInstController == null) return null;
    
    final anneeFab = anneeFabController.text.trim();
    final anneeInst = anneeInstController.text.trim();
    
    if (anneeFab.isEmpty || anneeInst.isEmpty) return null;
    
    final fab = int.tryParse(anneeFab);
    final inst = int.tryParse(anneeInst);
    
    if (fab != null && inst != null) {
      if (fab >= inst) {
        return 'L\'année de fabrication ($fab) doit être strictement inférieure à l\'année d\'installation ($inst)';
      }
    }
    return null;
  }

  bool _validateForm() {
    if (!_hasAtLeastOneFieldFilled()) {
      _showErrorSnackBar('Veuillez remplir au moins un champ');
      return false;
    }

    for (var champ in widget.champs) {
      if (_isAnneeField(champ) && !_isOuiNonField(champ)) {
        final value = _controllers[champ]!.text.trim();
        if (value.isNotEmpty) {
          final error = _validateAnnee(value);
          if (error != null) {
            _showErrorSnackBar('$champ : $error');
            return false;
          }
        }
      }
    }

    final errorStab = _validateFabricationVsInstallation();
    if (errorStab != null) {
      _showErrorSnackBar(errorStab);
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveItem() async {
    FocusScope.of(context).unfocus();
    
    if (!_validateForm()) {
      return;
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = <String, String>{};
      
      for (var champ in widget.champs) {
        if (_isTypeCelluleField(champ)) {
          if (_selectedTypeCellule != null && _selectedTypeCellule!.isNotEmpty) {
            data[champ] = _selectedTypeCellule!;
          }
        } else if (_isOuiNonField(champ)) {
          final value = _getOuiNonFieldValue(champ);
          if (value != null && value.isNotEmpty) {
            data[champ] = value;
          }
        } else if (_isSectionCableField(champ)) {
          if (_selectedSectionCable != null && _selectedSectionCable!.isNotEmpty) {
            data[champ] = _selectedSectionCable!;
          }
        } else {
          final value = _controllers[champ]!.text.trim();
          if (value.isNotEmpty) {
            data[champ] = value;
          }
        }
      }

      final item = InstallationItem(
        data: data,
        photoPaths: List.from(_photoPaths),
      );

      final success = await HiveService.addInstallationItemToSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        item: item,
      );

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Élément enregistré avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        _resetForm();
        await _loadExistingItems();
        
        if (!_addingMore) {
          final addAnother = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Élément ajouté'),
              content: const Text('Voulez-vous ajouter un autre élément ?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    widget.onComplete(widget.sectionKey);
                  },
                  child: const Text('Terminer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Ajouter un autre'),
                ),
              ],
            ),
          );
          
          if (addAnother == true && mounted) {
            setState(() {
              _addingMore = true;
            });
            _scrollToTop();
          }
        } else {
          setState(() {});
          _scrollToTop();
        }
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Erreur lors de l\'enregistrement: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    for (var controller in _controllers.values) {
      controller.clear();
    }
    if (!mounted) return;
    setState(() {
      _photoPaths.clear();
      _selectedCuveRetention = null;
      _selectedIndicateurNiveau = null;
      _selectedMiseALaTerre = null;
      _selectedSectionCable = null;
      _selectedTypeCellule = null;
    });
  }

  void _viewItemDetails(InstallationItem item, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(
          mission: widget.mission,
          sectionKey: widget.sectionKey,
          item: item,
          index: index,
          champs: widget.champs,
          requiredFields: widget.champs,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadExistingItems();
    }
  }

  void _showPhotoFullScreen(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  File(_photoPaths[index]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Photo ${index + 1}/${_photoPaths.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getDisplayFields(InstallationItem item) {
    final Map<String, String> result = {};
    int displayed = 0;
    
    for (var champ in widget.champs) {
      if (displayed >= 2) break;
      
      final value = item.data[champ];
      if (value != null && value.trim().isNotEmpty) {
        final label = champ.length > 20 ? '${champ.substring(0, 20)}...' : champ;
        result[label] = value;
        displayed++;
      }
    }
    
    if (result.length < 2) {
      for (var champ in widget.champs) {
        if (result.length >= 2) break;
        if (!result.containsKey(champ)) {
          final value = item.data[champ] ?? '—';
          final label = champ.length > 20 ? '${champ.substring(0, 20)}...' : champ;
          result[label] = value;
        }
      }
    }
    
    return result;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTypeCelluleDropdown(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTypeCellule,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, size: isSmallScreen ? 20 : 24, color: Colors.grey.shade600),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        hint: Text(
          'Sélectionnez le type de cellule',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.shade500,
          ),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 12, 
            vertical: isSmallScreen ? 12 : 14
          ),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.black87,
        ),
        items: _typeCelluleOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedTypeCellule = value;
            for (var champ in widget.champs) {
              if (_isTypeCelluleField(champ)) {
                _controllers[champ]?.text = value ?? '';
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildOuiNonDropdown(String champ, bool isSmallScreen) {
    final currentValue = _getOuiNonFieldValue(champ);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, size: isSmallScreen ? 20 : 24, color: Colors.grey.shade600),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        hint: Text(
          'Sélectionnez Oui ou Non',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.shade500,
          ),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 12, 
            vertical: isSmallScreen ? 12 : 14
          ),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.black87,
        ),
        items: _ouiNonOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: option == 'Oui' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  option,
                  style: TextStyle(
                    color: option == 'Oui' ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) => _setOuiNonFieldValue(champ, value),
      ),
    );
  }

  Widget _buildSectionCableDropdown(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSectionCable,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, size: isSmallScreen ? 20 : 24, color: Colors.grey.shade600),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        hint: Text(
          'Sélectionnez la section de câble',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.shade500,
          ),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 12, 
            vertical: isSmallScreen ? 12 : 14
          ),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 14,
          color: Colors.black87,
        ),
        items: _sectionCableOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSectionCable = value;
            for (var champ in widget.champs) {
              if (_isSectionCableField(champ)) {
                _controllers[champ]?.text = value ?? '';
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isComplete 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: widget.isComplete 
                            ? Colors.green.withOpacity(0.4)
                            : Colors.orange.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isComplete ? Icons.check_circle : Icons.pending_outlined,
                          color: widget.isComplete ? Colors.green : Colors.orange,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        Text(
                          widget.isComplete ? 'Section complétée' : 'En attente de saisie',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: widget.isComplete ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              if (_items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Éléments déjà ajoutés (${_items.length})',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    SizedBox(
                      height: isSmallScreen ? 140 : 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final fields = _getDisplayFields(item);
                          
                          return GestureDetector(
                            onTap: () => _viewItemDetails(item, index),
                            child: Container(
                              width: isSmallScreen ? 170 : 200,
                              margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isSmallScreen ? 6 : 8, 
                                                vertical: isSmallScreen ? 3 : 4
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Élément ${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isSmallScreen ? 9 : 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (item.photoPaths.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.photo,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: Colors.green,
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: isSmallScreen ? 10 : 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: fields.entries.map((entry) {
                                              return Padding(
                                                padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.key,
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 9 : 10,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      entry.value,
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 11 : 12,
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.photoPaths.isNotEmpty)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${item.photoPaths.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    const Divider(),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                  ],
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ...widget.champs.map((champ) {
                      final estObservations = _estChampObservations(champ);
                      final isTypeCellule = _isTypeCelluleField(champ);
                      final isSectionCable = _isSectionCableField(champ);
                      final isOuiNon = _isOuiNonField(champ);
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    champ,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            
                            if (isTypeCellule)
                              _buildTypeCelluleDropdown(isSmallScreen)
                            else if (isSectionCable)
                              _buildSectionCableDropdown(isSmallScreen)
                            else if (isOuiNon)
                              _buildOuiNonDropdown(champ, isSmallScreen)
                            else if (estObservations)
                              TextFormField(
                                controller: _controllers[champ],
                                maxLines: 5,
                                minLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Saisissez vos observations (optionnel)...',
                                  hintStyle: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 10 : 12, 
                                    vertical: isSmallScreen ? 10 : 12
                                  ),
                                ),
                              )
                            else
                              TextFormField(
                                controller: _controllers[champ],
                                maxLines: 2,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Saisissez ${champ.toLowerCase()}...',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 10 : 12, 
                                    vertical: isSmallScreen ? 10 : 12
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    Padding(
                      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Photos',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '(optionnel)',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: isSmallScreen ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _takePhoto,
                                  icon: Icon(Icons.camera_alt_outlined, size: isSmallScreen ? 16 : 18),
                                  label: Text(
                                    'Prendre',
                                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickFromGallery,
                                  icon: Icon(Icons.photo_library_outlined, size: isSmallScreen ? 16 : 18),
                                  label: Text(
                                    'Galerie',
                                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          
                          if (_photoPaths.isNotEmpty)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: _photoPaths.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _showPhotoFullScreen(index),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(_photoPaths[index])),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removePhoto(index),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              SizedBox(
                width: isSmallScreen ? 250 : 350,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _addingMore ? 'AJOUTER UN AUTRE' : 'SAUVEGARDER',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 15 : 18),
            ],
          ),
        ),
      ),
    );
  }
}