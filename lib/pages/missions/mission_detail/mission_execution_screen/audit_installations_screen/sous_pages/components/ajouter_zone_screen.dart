import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
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
  
  // Observations libres
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
        insetPadding: EdgeInsets.all(20),
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
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _supprimerPhoto(photos, index);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
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
        title: Text('Supprimer la photo'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            Text(
              '${photos.length} photo(s)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        
        if (_isLoadingPhotos && title.contains('zone'))
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (photos.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
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
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aucune photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
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
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
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
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => prendrePhoto(),
                icon: Icon(Icons.camera_alt, size: 20),
                label: Text('Prendre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            SizedBox(width: 4),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => choisirPhoto(),
                icon: Icon(Icons.photo_library, size: 20),
                label: Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
          ],
        ),
        
        SizedBox(height: 24),
      ],
    );
  }

  // ===== GESTION DES OBSERVATIONS =====

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBSERVATIONS SUR LA ZONE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(height: 10),

        // Observations existantes
        if (_observationsExistantes.isNotEmpty)
          ..._observationsExistantes.asMap().entries.map((entry) {
            final index = entry.key;
            final observation = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            observation.texte,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _supprimerObservationExistante(index),
                        ),
                      ],
                    ),
                    if (observation.photos.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          Text(
                            'Photos associées (${observation.photos.length})',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
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
                                child: Image.file(
                                  File(observation.photos[photoIndex]),
                                  fit: BoxFit.cover,
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

        // Nouvelle observation
        Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle observation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),

                TextFormField(
                  controller: _observationController,
                  decoration: InputDecoration(
                    labelText: 'Observation',
                    border: OutlineInputBorder(),
                    hintText: 'Saisissez votre observation...',
                  ),
                  maxLines: 3,
                ),

                SizedBox(height: 16),

                // Photos pour la nouvelle observation
                _buildPhotosSection(
                  'Photos pour cette observation',
                  _observationPhotos,
                  _prendrePhotoObservation,
                  _choisirPhotoObservationDepuisGalerie,
                ),

                SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _ajouterObservation,
                  child: Text('Ajouter cette observation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
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
    });
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'observation',style: TextStyle(fontSize: 16),),
        content: Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ===== FIN GESTION OBSERVATIONS =====

  void _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      try {
        dynamic zone;
        
        if (widget.isMoyenneTension) {
          zone = MoyenneTensionZone(
            nom: _nomController.text.trim(),
            coffrets: widget.isEdition ? widget.zone.coffrets : [],
            observationsLibres: _observationsExistantes, // Liste d'ObservationLibre
            photos: _zonePhotos,
            locaux: widget.isEdition ? widget.zone.locaux : [],
          );
        } else {
          zone = BasseTensionZone(
            nom: _nomController.text.trim(),
            locaux: widget.isEdition ? widget.zone.locaux : [],
            coffretsDirects: widget.isEdition ? widget.zone.coffretsDirects : [],
            observationsLibres: _observationsExistantes, // Liste d'ObservationLibre
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
          Navigator.pop(context, true);
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isMultiline = false, bool isRequired = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          hintText: label.contains('Nom') ? 'Ex: Sous-sol 1, RDC, Étage 2...' : null,
          prefixIcon: label.contains('Nom') ? Icon(Icons.place) : null,
          filled: true,
          fillColor: Colors.grey.shade100,
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
    return GestureDetector(
      onTap: () {FocusScope.of(context).unfocus();},
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdition ? 'Modifier la Zone' : 'Ajouter une Zone'),
          backgroundColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _sauvegarder,
              tooltip: 'Enregistrer',
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ListView(
              children: [
                 SizedBox(height: 12),
                // Nom de la zone
                _buildTextField(_nomController, 'Nom de la zone*', isRequired: true),
                SizedBox(height: 12),
      
                // Photos de la zone
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: _buildPhotosSection(
                      'Photos de la zone',
                      _zonePhotos,
                      _prendrePhotoZone,
                      _choisirPhotoZoneDepuisGalerie,
                    ),
                  ),
                ),
                SizedBox(height: 12),
      
                // Observations libres
                if(!widget.isEdition)
                _buildObservationsSection(),
                if(!widget.isEdition)
                SizedBox(height: 32),
                
                // Bouton d'enregistrement
                ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isMoyenneTension 
                        ? Colors.blue 
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        widget.isEdition ? 'MODIFIER LA ZONE' : 'AJOUTER LA ZONE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
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