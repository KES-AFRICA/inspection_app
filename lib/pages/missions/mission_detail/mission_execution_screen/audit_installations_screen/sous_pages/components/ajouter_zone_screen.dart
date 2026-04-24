import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AjouterZoneScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic zone;
  final int? zoneIndex;

  const AjouterZoneScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    this.zone,
    this.zoneIndex,
  });

  bool get isEdition => zone != null;

  @override
  State<AjouterZoneScreen> createState() => _AjouterZoneScreenState();
}

class _AjouterZoneScreenState extends State<AjouterZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<String> _zonePhotos = [];
  bool _isLoadingPhotos = false;
  
  bool _addObservation = false;
  final _observationController = TextEditingController();
  List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    }
  }
  
  void _chargerDonneesExistantes() {
    final zone = widget.zone!;
    _nomController.text = zone.nom;
    _observationsExistantes.addAll(zone.observationsLibres);
    if (zone.photos.isNotEmpty) {
      _zonePhotos = List.from(zone.photos);
    }
  }

  Future<void> _prendrePhotoZone() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
        setState(() {
          _zonePhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoZoneDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
        setState(() {
          _zonePhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() {
          _observationPhotos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    final fileName = '${subDir}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    
    await photoFile.copy(newPath);
    return newPath;
  }

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photos[index]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _supprimerPhoto(photos, index);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        
        if (_isLoadingPhotos && title.contains('zone'))
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (photos.isEmpty)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: isSmallScreen ? 40 : 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Aucune photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _previsualiserPhoto(photos, index),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photos[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _supprimerPhoto(photos, index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
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
        
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => prendrePhoto(),
                icon: Icon(Icons.camera_alt, size: isSmallScreen ? 18 : 20),
                label: Text(
                  'Prendre',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => choisirPhoto(),
                icon: Icon(Icons.photo_library, size: isSmallScreen ? 18 : 20),
                label: Text(
                  'Galerie',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isSmallScreen ? 20 : 24),
      ],
    );
  }

  Widget _buildObservationsSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'OBSERVATIONS',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        if (_observationsExistantes.isNotEmpty)
          ..._observationsExistantes.asMap().entries.map((entry) {
            final index = entry.key;
            final observation = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            observation.texte,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              height: 1.4,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: isSmallScreen ? 20 : 22),
                          onPressed: () => _supprimerObservationExistante(index),
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 36 : 40,
                            minHeight: isSmallScreen ? 36 : 40,
                          ),
                        ),
                      ],
                    ),
                    if (observation.photos.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 12 : 14),
                      Text(
                        '📸 ${observation.photos.length} photo${observation.photos.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: observation.photos.length,
                        itemBuilder: (context, photoIndex) {
                          return GestureDetector(
                            onTap: () => _previsualiserPhoto(observation.photos, photoIndex),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(observation.photos[photoIndex]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une observation',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkBlue,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 14),
                
                Row(
                  children: [
                    _buildToggleButton(
                      label: 'Oui',
                      isSelected: _addObservation,
                      selectedColor: Colors.green,
                      onTap: () {
                        setState(() {
                          _addObservation = true;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildToggleButton(
                      label: 'Non',
                      isSelected: !_addObservation,
                      selectedColor: Colors.red,
                      onTap: () {
                        setState(() {
                          _addObservation = false;
                          _observationController.clear();
                          _observationPhotos.clear();
                        });
                      },
                    ),
                  ],
                ),

                if (_addObservation) ...[
                  SizedBox(height: isSmallScreen ? 18 : 22),
                  
                  TextFormField(
                    controller: _observationController,
                    decoration: InputDecoration(
                      labelText: 'Observation',
                      hintText: 'Saisissez votre observation...',
                      prefixIcon: Icon(Icons.edit_note, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 4,
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

                  _buildPhotosSection(
                    'Photos associées',
                    _observationPhotos,
                    _prendrePhotoObservation,
                    _choisirPhotoObservationDepuisGalerie,
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

                  ElevatedButton(
                    onPressed: _ajouterObservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Ajouter l\'observation',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Icon(
                    label == 'Oui' ? Icons.check_circle : Icons.cancel,
                    color: selectedColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                if (isSelected) SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? selectedColor : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ajouterObservation() {
    final texte = _observationController.text.trim();
    if (texte.isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }

    setState(() {
      _observationsExistantes.add(ObservationLibre(
        texte: texte,
        photos: List.from(_observationPhotos),
      ));
      _observationController.clear();
      _observationPhotos.clear();
      _addObservation = false;
    });
    
    _showSuccess('Observation ajoutée');
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'observation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
              });
              _showSuccess('Observation supprimée');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      try {
        dynamic zone;
        
        if (widget.isMoyenneTension) {
          zone = MoyenneTensionZone(
            nom: _nomController.text.trim(),
            coffrets: widget.isEdition ? widget.zone.coffrets : [],
            observationsLibres: _observationsExistantes,
            photos: _zonePhotos,
            locaux: widget.isEdition ? widget.zone.locaux : [],
          );
        } else {
          zone = BasseTensionZone(
            nom: _nomController.text.trim(),
            locaux: widget.isEdition ? widget.zone.locaux : [],
            coffretsDirects: widget.isEdition ? widget.zone.coffretsDirects : [],
            observationsLibres: _observationsExistantes,
            photos: _zonePhotos,
          );
        }

        bool success;
        if (widget.isEdition) {
          success = await _updateZone(zone);
        } else {
          if (widget.isMoyenneTension) {
            success = await HiveService.addMoyenneTensionZone(
              missionId: widget.mission.id,
              zone: zone as MoyenneTensionZone,
            );
          } else {
            success = await HiveService.addBasseTensionZone(
              missionId: widget.mission.id,
              zone: zone as BasseTensionZone,
            );
          }
        }

        if (success) {
          if (mounted) {
            _showSuccess(widget.isEdition ? 'Zone modifiée avec succès' : 'Zone ajoutée avec succès');
            
            if (!widget.isEdition) {
              await HiveService.syncClassementsZonesFromAudit(widget.mission.id);
              
              final classement = await HiveService.getOrCreateClassementZone(
                missionId: widget.mission.id,
                nomZone: _nomController.text.trim(),
                typeZone: widget.isMoyenneTension ? 'MT' : 'BT',
              );
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassementZoneScreen(
                    mission: widget.mission,
                    classement: classement,
                  ),
                ),
              );
              
              if (result == true) {
                Navigator.pop(context, true);
              }
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          _showError('Erreur lors de la sauvegarde');
        }
      } catch (e) {
        _showError('Erreur: $e');
      }
    }
  }

  Future<bool> _updateZone(dynamic zone) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      if (widget.isMoyenneTension) {
        if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
          audit.moyenneTensionZones[widget.zoneIndex!] = zone;
        }
      } else {
        if (widget.zoneIndex! < audit.basseTensionZones.length) {
          audit.basseTensionZones[widget.zoneIndex!] = zone;
        }
      }
      
      await HiveService.saveAuditInstallations(audit);
      return true;
    } catch (e) {
      print('❌ Erreur updateZone: $e');
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: label.contains('Nom') ? 'Ex: Sous-sol 1, RDC, Étage 2...' : null,
          prefixIcon: label.contains('Nom') ? Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
        style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
        maxLines: isMultiline ? 4 : 1,
        validator: isRequired ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Veuillez saisir un nom';
          }
          return null;
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            widget.isEdition ? 'Modifier la Zone' : 'Nouvelle Zone',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _sauvegarder,
                icon: const Icon(Icons.check, color: Colors.white, size: 22),
                label: const Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section information de base
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.place, color: AppTheme.primaryBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_nomController, 'Nom de la zone', isRequired: true),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Section photos de la zone
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.photo_library, color: AppTheme.primaryBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildPhotosSection(
                          'Photos de la zone',
                          _zonePhotos,
                          _prendrePhotoZone,
                          _choisirPhotoZoneDepuisGalerie,
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (!widget.isEdition) ...[
                  const SizedBox(height: 20),
                  
                  // Section observations
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: _buildObservationsSection(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Bouton principal
                ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    minimumSize: Size(double.infinity, isSmallScreen ? 50 : 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.isEdition ? Icons.edit : Icons.add_circle_outline, size: isSmallScreen ? 22 : 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.isEdition ? 'MODIFIER LA ZONE' : 'CRÉER LA ZONE',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _observationController.dispose();
    super.dispose();
  }
}