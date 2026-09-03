// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/prises_terre_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/features/mesures_essais/presentation/providers/mesures_essais_provider.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/utils/image_compress_helper.dart';

class PrisesTerreScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const PrisesTerreScreen({super.key, required this.mission});

  @override
  ConsumerState<PrisesTerreScreen> createState() => _PrisesTerreScreenState();
}

class _PrisesTerreScreenState extends ConsumerState<PrisesTerreScreen> {
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
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
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
          mission: widget.mission,
          conditionOptions: _conditionOptions,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final nouvellePrise = PriseTerre(
        localisation: result['localisation'] ?? '',
        identification: result['identification'] ?? '',
        conditionPriseTerre: result['conditionMesure'] ?? 'Barette fermée',
        naturePriseTerre: result['naturePriseTerre'] ?? '',
        methodeMesure: result['methodeMesure'] ?? '',
        valeurMesure: double.tryParse(result['valeurMesure']?.toString() ?? ''),
        observation: result['observation'],
        interconnecteAutrePrise: result['interconnecteAutrePrise'],
        photo: result['photo'],
      );
      
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      mesures.prisesTerre.add(nouvellePrise);
      
      final success = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
      
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
          mission: widget.mission,
          initialData: {
            'localisation': prise.localisation,
            'identification': prise.identification,
            'conditionMesure': prise.conditionPriseTerre,
            'naturePriseTerre': prise.naturePriseTerre,
            'methodeMesure': prise.methodeMesure,
            'valeurMesure': prise.valeurMesure?.toString() ?? '',
            'observation': prise.observation ?? '',
            'interconnecteAutrePrise': prise.interconnecteAutrePrise ?? '',
            'photo': prise.photo ?? '',
          },
          conditionOptions: _conditionOptions,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final updatedPrise = PriseTerre(
        localisation: result['localisation'] ?? '',
        identification: result['identification'] ?? '',
        conditionPriseTerre: result['conditionMesure'] ?? 'Barette fermée',
        naturePriseTerre: result['naturePriseTerre'] ?? '',
        methodeMesure: result['methodeMesure'] ?? '',
        valeurMesure: double.tryParse(result['valeurMesure']?.toString() ?? ''),
        observation: result['observation'],
        interconnecteAutrePrise: result['interconnecteAutrePrise'],
        photo: result['photo'],
      );
      
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      
      if (index < mesures.prisesTerre.length) {
        mesures.prisesTerre[index] = updatedPrise;
        final success = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
        
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
      final mesures = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).load();
      
      if (index < mesures.prisesTerre.length) {
        mesures.prisesTerre.removeAt(index);
        final success = await ref.read(mesuresEssaisProvider(widget.mission.id).notifier).saveMesures(mesures);
        
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
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                      'Aucune prise de terre enregistrée',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _ajouterPriseTerre,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une prise de terre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                itemCount: _prisesTerre.length,
                itemBuilder: (context, index) {
                  final prise = _prisesTerre[index];
                  final hasPhoto = prise.photo != null && prise.photo!.trim().isNotEmpty && File(prise.photo!).existsSync();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  prise.identification,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editerPriseTerre(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _supprimerPriseTerre(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          if (hasPhoto) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: Image.file(
                                  File(prise.photo!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _buildInfoRow('Localisation', prise.localisation, isSmallScreen),
                          _buildInfoRow('Condition prise de terre', prise.conditionPriseTerre, isSmallScreen),
                          _buildInfoRow('Nature prise de terre', prise.naturePriseTerre, isSmallScreen),
                          _buildInfoRow('Méthode de mesure', prise.methodeMesure, isSmallScreen),
                          _buildInfoRow(
                            'Valeur mesurée',
                            prise.valeurMesure != null ? '${prise.valeurMesure} Ω' : 'Non mesurée',
                            isSmallScreen,
                          ),
                          if (prise.interconnecteAutrePrise != null && prise.interconnecteAutrePrise!.isNotEmpty)
                            _buildInfoRow('Interconnecté à d\'autre prise', prise.interconnecteAutrePrise!, isSmallScreen),
                          if (prise.observation != null && prise.observation!.isNotEmpty)
                            _buildInfoRow('Observation', prise.observation!, isSmallScreen),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 140 : 170,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Formulaire Ajouter / Modifier Prise de terre
// ============================================================
class _AjouterPriseTerreScreen extends StatefulWidget {
  final Mission mission;
  final Map<String, dynamic>? initialData;
  final List<String> conditionOptions;

  const _AjouterPriseTerreScreen({
    required this.mission,
    this.initialData,
    required this.conditionOptions,
  });

  @override
  State<_AjouterPriseTerreScreen> createState() => _AjouterPriseTerreScreenState();
}

class _AjouterPriseTerreScreenState extends State<_AjouterPriseTerreScreen> {
  final _identificationController = TextEditingController();
  final _valeurMesureController = TextEditingController();
  final _observationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedLocalisation;
  String? _conditionMesure;
  String? _naturePriseTerre;
  String? _methodeMesure;
  String? _interconnecteAutrePrise;
  String? _photoPath;

  List<String> _localisationsOptions = [];

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
    _loadLocalisations();

    if (widget.initialData != null) {
      final loc = widget.initialData!['localisation']?.toString().trim();
      _selectedLocalisation = (loc != null && loc.isNotEmpty) ? loc : null;
      _identificationController.text = widget.initialData!['identification'] ?? '';

      final cond = widget.initialData!['conditionMesure']?.toString().trim();
      _conditionMesure = (cond != null && cond.isNotEmpty) ? cond : 'Barette fermée';

      final nat = widget.initialData!['naturePriseTerre']?.toString().trim();
      _naturePriseTerre = (nat != null && nat.isNotEmpty) ? nat : null;

      final meth = widget.initialData!['methodeMesure']?.toString().trim();
      _methodeMesure = (meth != null && meth.isNotEmpty) ? meth : null;

      _valeurMesureController.text = widget.initialData!['valeurMesure'] ?? '';
      _observationController.text = widget.initialData!['observation'] ?? '';

      final interconnecte = widget.initialData!['interconnecteAutrePrise']?.toString().trim();
      _interconnecteAutrePrise = (interconnecte != null && interconnecte.isNotEmpty) ? interconnecte : null;

      final photo = widget.initialData!['photo'];
      _photoPath = (photo != null && photo.toString().trim().isNotEmpty) ? photo.toString().trim() : null;

      if (_selectedLocalisation != null && !_localisationsOptions.contains(_selectedLocalisation)) {
        _localisationsOptions.insert(0, _selectedLocalisation!);
      }
    } else {
      _conditionMesure = 'Barette fermée';
    }
  }

  void _loadLocalisations() {
    _localisationsOptions = HiveService.getLocalisationsForEssais(widget.mission.id);
    if (_localisationsOptions.isEmpty) {
      _localisationsOptions = [
        'Extérieur',
        'Local technique',
        'Poste HTA',
        'Local transformateur',
        'Local GE',
        'TGBT',
      ];
    }
  }

  @override
  void dispose() {
    _identificationController.dispose();
    _valeurMesureController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo != null) {
        if (source == ImageSource.camera) {
          GalleryPhotoService.saveToGallery(File(photo.path));
        }
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${appDir.path}/audit_photos/prises_terre');
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        final fileName = 'pt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final targetPath = '${photosDir.path}/$fileName';

        final savedFile = await ImageCompressHelper.compressImage(File(photo.path), targetPath);
        setState(() {
          _photoPath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sélection photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _photoPath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isFormValid() {
    return _selectedLocalisation != null &&
           _selectedLocalisation!.trim().isNotEmpty &&
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
      'localisation': _selectedLocalisation?.trim() ?? '',
      'identification': _identificationController.text.trim(),
      'conditionMesure': _conditionMesure,
      'naturePriseTerre': _naturePriseTerre,
      'methodeMesure': _methodeMesure,
      'valeurMesure': _valeurMesureController.text.trim(),
      'observation': _observationController.text.trim(),
      'interconnecteAutrePrise': _interconnecteAutrePrise,
      'photo': _photoPath,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasPhoto = _photoPath != null && _photoPath!.trim().isNotEmpty && File(_photoPath!).existsSync();

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
              
              // Localisation * (Select)
              _buildDropdown(
                label: 'Localisation *',
                value: _selectedLocalisation,
                options: _localisationsOptions,
                onChanged: (value) => setState(() => _selectedLocalisation = value),
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 14),
              
              // Identification *
              _buildTextField(_identificationController, 'Identification *', isSmallScreen),
              const SizedBox(height: 14),
              
              // Condition prise de terre *
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
              
              // Interconnecté à d'autre prise (Optionnel / Select)
              _buildDropdown(
                label: 'Interconnecté à d\'autre prise',
                value: _interconnecteAutrePrise,
                options: const ['Oui', 'Non'],
                onChanged: (value) => setState(() => _interconnecteAutrePrise = value),
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 14),

              // Valeur mesurée (optionnel)
              _buildTextField(_valeurMesureController, 'Valeur mesurée (Ω)', isSmallScreen,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              
              // Photo (Optionnel)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo d\'illustration',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasPhoto)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_photoPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                              onPressed: _showPhotoOptions,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _showPhotoOptions,
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 32),
                            const SizedBox(height: 6),
                            Text(
                              'Ajouter une photo',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
    final List<String> effectiveOptions = [];
    for (final opt in options) {
      final trimmed = opt.trim();
      if (trimmed.isNotEmpty && !effectiveOptions.contains(trimmed)) {
        effectiveOptions.add(trimmed);
      }
    }

    String? effectiveValue = value?.trim();
    if (effectiveValue == null || effectiveValue.isEmpty) {
      effectiveValue = null;
    } else if (!effectiveOptions.contains(effectiveValue)) {
      effectiveOptions.insert(0, effectiveValue);
    }

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      hint: Text('Sélectionnez...', style: TextStyle(color: Colors.grey.shade500)),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: effectiveOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}