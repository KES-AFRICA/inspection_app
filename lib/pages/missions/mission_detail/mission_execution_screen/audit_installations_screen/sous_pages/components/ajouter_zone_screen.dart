import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AjouterZoneScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic zone; // Pour l'édition
  final int? zoneIndex; // Pour l'édition

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
  
  // Photos de la zone
  List<String> _zonePhotos = [];
  bool _isLoadingPhotos = false;
  
  // Observations libres - NOUVEAU : Toggle Oui/Non
  bool _addObservation = false; // Par défaut Non
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
    
    // Charger les observations existantes
    _observationsExistantes.addAll(zone.observationsLibres);
    
    // Charger les photos de la zone
    if (zone.photos.isNotEmpty) {
      _zonePhotos = List.from(zone.photos);
    }
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS DE LA ZONE =====

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

  // ===== MÉTHODES POUR GESTION DES PHOTOS D'OBSERVATION =====

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
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isSmallScreen ? 20 : 24),
      ],
    );
  }

  // ===== GESTION DES OBSERVATIONS AVEC TOGGLE OUI/NON =====

  Widget _buildObservationsSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBSERVATIONS SUR LA ZONE',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),

        // Observations existantes
        if (_observationsExistantes.isNotEmpty)
          ..._observationsExistantes.asMap().entries.map((entry) {
            final index = entry.key;
            final observation = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            observation.texte,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red, size: isSmallScreen ? 18 : 20),
                          onPressed: () => _supprimerObservationExistante(index),
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 32 : 40,
                            minHeight: isSmallScreen ? 32 : 40,
                          ),
                        ),
                      ],
                    ),
                    if (observation.photos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            'Photos associées (${observation.photos.length})',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: observation.photos.length,
                            itemBuilder: (context, photoIndex) {
                              return GestureDetector(
                                onTap: () => _previsualiserPhoto(observation.photos, photoIndex),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
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
                      ),
                  ],
                ),
              ),
            );
          }),

        // Toggle Oui/Non pour ajouter une nouvelle observation
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Oui/Non
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ajouter une observation ?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ),
                    // Bouton Oui
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _addObservation = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 14 : 18,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: _addObservation ? Colors.green.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _addObservation ? Colors.green : Colors.grey.shade300,
                            width: _addObservation ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          'Oui',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: _addObservation ? Colors.green : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton Non
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _addObservation = false;
                          _observationController.clear();
                          _observationPhotos.clear();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 14 : 18,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: !_addObservation ? Colors.red.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: !_addObservation ? Colors.red : Colors.grey.shade300,
                            width: !_addObservation ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          'Non',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: !_addObservation ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Champs d'observation (affichés uniquement si Oui)
                if (_addObservation) ...[
                  SizedBox(height: isSmallScreen ? 14 : 18),
                  
                  TextFormField(
                    controller: _observationController,
                    decoration: InputDecoration(
                      labelText: 'Observation',
                      border: const OutlineInputBorder(),
                      hintText: 'Saisissez votre observation...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Photos pour la nouvelle observation
                  _buildPhotosSection(
                    'Photos pour cette observation',
                    _observationPhotos,
                    _prendrePhotoObservation,
                    _choisirPhotoObservationDepuisGalerie,
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  ElevatedButton(
                    onPressed: _ajouterObservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Ajouter cette observation',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
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
      _addObservation = false; // Réinitialiser le toggle à Non après ajout
    });
    
    _showSuccess('Observation ajoutée');
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'observation', style: TextStyle(fontSize: 16)),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===== FIN GESTION OBSERVATIONS =====

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEdition ? 'Zone modifiée' : 'Zone ajoutée'),
                backgroundColor: Colors.green,
              ),
            );
            
            if (!widget.isEdition) {
              // Synchroniser les classements
              await HiveService.syncClassementsZonesFromAudit(widget.mission.id);
              
              // Récupérer le classement créé
              final classement = await HiveService.getOrCreateClassementZone(
                missionId: widget.mission.id,
                nomZone: _nomController.text.trim(),
                typeZone: widget.isMoyenneTension ? 'MT' : 'BT',
              );
              
              // Rediriger vers l'écran de classement
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassementZoneScreen(
                    mission: widget.mission,
                    classement: classement,
                  ),
                ),
              );
              
              //  retourner à l'écran MT/BT (pas à l'audit principal)
              if (result == true) {
                // Retourner à l'écran précédent (MoyenneTensionScreen ou BasseTensionScreen)
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
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: label.contains('Nom') ? 'Ex: Sous-sol 1, RDC, Étage 2...' : null,
          prefixIcon: label.contains('Nom') ? const Icon(Icons.place) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
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
        appBar: AppBar(
          title: Text(
            widget.isEdition ? 'Modifier la Zone' : 'Ajouter une Zone',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _sauvegarder,
              tooltip: 'Enregistrer',
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: ListView(
              children: [
                SizedBox(height: isSmallScreen ? 8 : 12),
                // Nom de la zone
                _buildTextField(_nomController, 'Nom de la zone*', isRequired: true),
                SizedBox(height: isSmallScreen ? 8 : 12),
      
                // Photos de la zone
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: _buildPhotosSection(
                      'Photos de la zone',
                      _zonePhotos,
                      _prendrePhotoZone,
                      _choisirPhotoZoneDepuisGalerie,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
      
                // Observations libres
                if (!widget.isEdition)
                  _buildObservationsSection(),
                if (!widget.isEdition)
                  SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Bouton d'enregistrement
                ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: isSmallScreen ? 18 : 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEdition ? 'MODIFIER LA ZONE' : 'AJOUTER LA ZONE',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
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