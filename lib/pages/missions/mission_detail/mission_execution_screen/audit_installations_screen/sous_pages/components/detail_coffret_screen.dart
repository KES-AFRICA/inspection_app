import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/observation_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

class DetailCoffretScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final String parentType;
  final int parentIndex;
  final int coffretIndex;
  final CoffretArmoire coffret;
  final int? zoneIndex;
  final bool isInZone;

  const DetailCoffretScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    required this.parentType,
    required this.parentIndex,
    required this.coffretIndex,
    required this.coffret,
    this.zoneIndex,
    this.isInZone = false,
  });

  @override
  State<DetailCoffretScreen> createState() => _DetailCoffretScreenState();
}

class _DetailCoffretScreenState extends State<DetailCoffretScreen> {
  late CoffretArmoire _coffret;
  final ImagePicker _picker = ImagePicker();
  List<String> _coffretPhotos = [];
  bool _isLoadingPhotos = false;
  
  // Pour les nouvelles observations
  final _nouvelleObservationController = TextEditingController();
  List<String> _photosPourNouvelleObservation = [];
  bool _isLoadingObservationPhotos = false;

  @override
  void initState() {
    super.initState();
    _coffret = widget.coffret;
    _chargerPhotosCoffret();
  }

  void _chargerPhotosCoffret() {
    if (_coffret.photos.isNotEmpty) {
      setState(() {
        _coffretPhotos = List.from(_coffret.photos);
      });
    }
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS DU COFFRET =====

  Future<void> _prendrePhotoCoffret() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets');
        
        setState(() {
          _coffretPhotos.add(savedPath);
          _coffret.photos = _coffretPhotos;
        });
        
        await _sauvegarderCoffret();
        _showSuccess('Photo ajoutée à l\' équipement');
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoCoffretDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets');
        
        setState(() {
          _coffretPhotos.add(savedPath);
          _coffret.photos = _coffretPhotos;
        });
        
        await _sauvegarderCoffret();
        _showSuccess('Photo ajoutée depuis la galerie');
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
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

  void _supprimerPhoto(List<String> photos, int index) async {
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
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Supprimer le fichier physique
                final file = File(photos[index]);
                if (await file.exists()) {
                  await file.delete();
                }
                
                // Mettre à jour la liste
                setState(() {
                  photos.removeAt(index);
                  
                  // Si c'est une photo du coffret, mettre à jour le coffret
                  if (photos == _coffretPhotos) {
                    _coffret.photos = _coffretPhotos;
                  }
                });
                
                // Sauvegarder si c'est une photo du coffret
                if (photos == _coffretPhotos) {
                  await _sauvegarderCoffret();
                }
                
                _showSuccess('Photo supprimée');
              } catch (e) {
                _showError('Erreur lors de la suppression: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(String title, List<String> photos, Function prendrePhoto, Function choisirPhoto, {bool isLoading = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        if (isLoading)
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
                    style: TextStyle(color: Colors.grey.shade600),
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

        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => prendrePhoto(),
                icon: Icon(Icons.camera_alt, size: 20),
                label: Text('Prendre une photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
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
      ],
    );
  }

  Widget _buildPhotosTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: _buildPhotosSection(
        'Photos du coffret',
        _coffretPhotos,
        _prendrePhotoCoffret,
        _choisirPhotoCoffretDepuisGalerie,
        isLoading: _isLoadingPhotos,
      ),
    );
  }

  // ===== MÉTHODES POUR GESTION DES OBSERVATIONS =====

  // Méthode pour ajouter une photo à une observation
  Future<void> _ajouterPhotoAObservation(List<String> photosList) async {
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
          photosList.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie(List<String> photosList) async {
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
          photosList.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _ajouterObservation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          title: 'Nouvelle observation',
          onSave: (ObservationLibre observation) async {
            setState(() {
              _coffret.observationsLibres.add(observation);
            });
            await _sauvegarderCoffret();
            _showSuccess('Observation ajoutée');
          },
        ),
      ),
    );
    
    // Rafraîchir après retour
    _refreshCoffret();
  }

  void _editerObservation(int index) async {
    final observation = _coffret.observationsLibres[index];
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          observation: observation,
          title: 'Modifier l\'observation',
          onSave: (ObservationLibre updatedObservation) async {
            setState(() {
              _coffret.observationsLibres[index] = updatedObservation;
            });
            await _sauvegarderCoffret();
            _showSuccess('Observation modifiée');
          },
        ),
      ),
    );
    
    // Rafraîchir après retour
    _refreshCoffret();
  }

  void _supprimerObservation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Supprimer les fichiers photos associés
              final observation = _coffret.observationsLibres[index];
              for (var photoPath in observation.photos) {
                try {
                  final file = File(photoPath);
                  if (await file.exists()) {
                    await file.delete();
                  }
                } catch (e) {
                  print('Erreur suppression photo: $e');
                }
              }
              
              setState(() {
                _coffret.observationsLibres.removeAt(index);
              });
              
              await _sauvegarderCoffret();
              _showSuccess('Observation supprimée');
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationCard(ObservationLibre observation, int index) {
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppTheme.primaryBlue),
                      onPressed: () => _editerObservation(index),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _supprimerObservation(index),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 4),
            Text(
              '${_formatDate(observation.dateCreation)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            if (observation.photos.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Photos associées (${observation.photos.length})',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 4),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: observation.photos.length,
                  itemBuilder: (context, photoIndex) {
                    return GestureDetector(
                      onTap: () => _previsualiserPhoto(observation.photos, photoIndex),
                      child: Container(
                        width: 80,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(observation.photos[photoIndex]),
                            fit: BoxFit.cover,
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
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildObservationsTab() {
    final observations = _coffret.observationsLibres;
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (observations.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: observations.length,
                itemBuilder: (context, index) {
                  return _buildObservationCard(observations[index], index);
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune observation',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez vos observations pour documenter ce coffret',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _ajouterObservation,
            icon: Icon(Icons.add_comment),
            label: Text('Ajouter une observation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FIN MÉTHODES OBSERVATIONS =====

  void _editerCoffret() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: widget.parentType,
          parentIndex: widget.parentIndex,
          isMoyenneTension: widget.isMoyenneTension,
          zoneIndex: widget.zoneIndex,
          coffret: _coffret,
          coffretIndex: widget.coffretIndex,
          isInZone: widget.isInZone,
        ),
      ),
    );

    if (result == true) {
      _refreshCoffret();
    }
  }

  void _refreshCoffret() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    // Recharger le coffret depuis la base
    if (widget.parentType == 'local') {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          // Coffret dans un local qui est dans une zone MT
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              final local = zone.locaux[widget.parentIndex];
              if (widget.coffretIndex < local.coffrets.length) {
                setState(() {
                  _coffret = local.coffrets[widget.coffretIndex];
                });
              }
            }
          }
        } else {
          // Coffret dans un local MT indépendant
          if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            final local = audit.moyenneTensionLocaux[widget.parentIndex];
            if (widget.coffretIndex < local.coffrets.length) {
              setState(() {
                _coffret = local.coffrets[widget.coffretIndex];
              });
            }
          }
        }
      } else {
        // Logique pour basse tension
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) {
            final local = zone.locaux[widget.parentIndex];
            if (widget.coffretIndex < local.coffrets.length) {
              setState(() {
                _coffret = local.coffrets[widget.coffretIndex];
              });
            }
          }
        }
      }
    } else if (widget.parentType == 'zone_mt') {
      if (widget.parentIndex < audit.moyenneTensionZones.length) {
        final zone = audit.moyenneTensionZones[widget.parentIndex];
        if (widget.coffretIndex < zone.coffrets.length) {
          setState(() {
            _coffret = zone.coffrets[widget.coffretIndex];
          });
        }
      }
    } else if (widget.parentType == 'zone_bt') {
      if (widget.parentIndex < audit.basseTensionZones.length) {
        final zone = audit.basseTensionZones[widget.parentIndex];
        if (widget.coffretIndex < zone.coffretsDirects.length) {
          setState(() {
            _coffret = zone.coffretsDirects[widget.coffretIndex];
          });
        }
      }
    }
    
    _chargerPhotosCoffret();
  }

  Future<void> _sauvegarderCoffret() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    if (widget.parentType == 'local') {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          // Coffret dans un local qui est dans une zone MT
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              final local = zone.locaux[widget.parentIndex];
              if (widget.coffretIndex < local.coffrets.length) {
                local.coffrets[widget.coffretIndex] = _coffret;
              }
            }
          }
        } else {
          // Coffret dans un local MT indépendant
          if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            final local = audit.moyenneTensionLocaux[widget.parentIndex];
            if (widget.coffretIndex < local.coffrets.length) {
              local.coffrets[widget.coffretIndex] = _coffret;
            }
          }
        }
      } else {
        // Pour basse tension
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) {
            final local = zone.locaux[widget.parentIndex];
            if (widget.coffretIndex < local.coffrets.length) {
              local.coffrets[widget.coffretIndex] = _coffret;
            }
          }
        }
      }
    } else if (widget.parentType == 'zone_mt') {
      // Coffret direct dans une zone MT
      if (widget.parentIndex < audit.moyenneTensionZones.length) {
        final zone = audit.moyenneTensionZones[widget.parentIndex];
        if (widget.coffretIndex < zone.coffrets.length) {
          zone.coffrets[widget.coffretIndex] = _coffret;
        }
      }
    } else if (widget.parentType == 'zone_bt') {
      // Coffret direct dans une zone BT
      if (widget.parentIndex < audit.basseTensionZones.length) {
        final zone = audit.basseTensionZones[widget.parentIndex];
        if (widget.coffretIndex < zone.coffretsDirects.length) {
          zone.coffretsDirects[widget.coffretIndex] = _coffret;
        }
      }
    }
    
    await HiveService.saveAuditInstallations(audit);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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

  // === AUTRES WIDGETS EXISTANTS ===

  Widget _buildInfoCard(String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isNotEmpty ? value : 'Non renseigné'),
      ),
    );
  }

  Widget _buildBooleanInfo(String title, bool value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: value ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value ? 'OUI' : 'NON',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlimentationCard(Alimentation alimentation, String title) {
    return  Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Type de protection', alimentation.typeProtection),
            _buildInfoRow('PDC kA', alimentation.pdcKA),
            _buildInfoRow('Calibre', alimentation.calibre),
            _buildInfoRow('Section de câble', alimentation.sectionCable),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      )
    );
  }

  // === NOUVELLE MÉTHODE POUR AFFICHER LES POINTS AVEC PHOTOS ===
  Widget _buildPointVerificationCard(PointVerification point) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              point.pointVerification,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConformiteColor(point.conformite).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getConformiteColor(point.conformite)),
                  ),
                  child: Text(
                    point.conformite.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getConformiteColor(point.conformite),
                    ),
                  ),
                ),
                if (point.priorite != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPrioriteColor(point.priorite!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getPrioriteColor(point.priorite!)),
                    ),
                    child: Text(
                      'N${point.priorite}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPrioriteColor(point.priorite!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // Observation
            if (point.observation != null && point.observation!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Observation: ${point.observation}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            // Référence normative
            if (point.referenceNormative != null && point.referenceNormative!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                'Référence: ${point.referenceNormative}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            
            // Photos (afficher uniquement s'il y a des photos)
            if (point.photos.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                "Photos de l'observation (${point.photos.length}):",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: point.conformite == 'non' ? Colors.red : 
                         point.conformite == 'oui' ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Container(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: point.photos.length,
                  itemBuilder: (context, photoIndex) {
                    return GestureDetector(
                      onTap: () => _previsualiserPhoto(point.photos, photoIndex),
                      child: Container(
                        width: 60,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: point.conformite == 'non' ? Colors.red.shade300 : 
                                   point.conformite == 'oui' ? Colors.green.shade300 : Colors.orange.shade300,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(point.photos[photoIndex]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConformiteColor(String conformite) {
    switch (conformite) {
      case 'oui': return Colors.green;
      case 'non': return Colors.red;
      default: return Colors.orange;
    }
  }

  Color _getPrioriteColor(int priorite) {
    switch (priorite) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

Future<List<EssaiDeclenchementDifferentiel>> _getEssaisPourCoffret() async {
  try {
    final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
    
    // Filtrer les essais qui correspondent à ce coffret par son nom
    final essaisPourCoffret = mesures.essaisDeclenchement
        .where((essai) {
          return essai.coffret == _coffret.nom || 
                 (essai.coffret != null && essai.coffret!.contains(_coffret.nom));
        })
        .toList();
    
    return essaisPourCoffret;
  } catch (e) {
    print('❌ Erreur chargement essais pour coffret "${_coffret.nom}": $e');
    return [];
  }
}

Widget _buildEssaiCard(EssaiDeclenchementDifferentiel essai, int index) {
  Color cardColor;
  String statutText;
  IconData statutIcon;
  
  switch (essai.essai) {
    case 'OK':
      cardColor = Colors.green;
      statutText = 'OK';
      statutIcon = Icons.check_circle;
      break;
    case 'NON OK':
      cardColor = Colors.red;
      statutText = 'NON OK';
      statutIcon = Icons.warning;
      break;
    default:
      cardColor = Colors.grey;
      statutText = 'NON ESSAYÉ';
      statutIcon = Icons.help_outline;
  }

  return Container(
    margin: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.grey
      ),
    ),
    child: InkWell(
      onTap: () => _editerEssai(essai),
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
                      Icon(statutIcon, size: 14, color: cardColor),
                      SizedBox(width: 6),
                      Text(
                        statutText,
                        style: TextStyle(
                          fontSize: 12,
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
                      _editerEssai(essai);
                    } else if (value == 'delete') {
                      _supprimerEssai(essai);
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
            
            // Circuit et localisation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(essai.designationCircuit != null && essai.designationCircuit!.isNotEmpty) ...[
                  Text(
                    essai.designationCircuit!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        essai.localisation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (essai.coffret != null && essai.coffret!.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.electrical_services, size: 14, color: Colors.grey.shade600),
                      SizedBox(width: 4),
                      Text(
                        essai.coffret!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 12),
            
            // Paramètres techniques
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Première ligne : Type et Réglage IΔn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            essai.typeDispositifComplet,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (essai.reglageIAn != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Réglage IΔn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${essai.reglageIAn} mA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Deuxième ligne : Temporisation et Isolement
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (essai.tempo != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temporisation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${essai.tempo} s',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (essai.isolement != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Isolement',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${essai.isolement} MΩ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // Si aucun des deux n'est présent, afficher un message
                  if (essai.tempo == null && essai.isolement == null && essai.reglageIAn == null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Aucun paramètre technique renseigné',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  
                  if (essai.observation != null && essai.observation!.isNotEmpty) ...[
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
                          essai.observation!,
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
  Widget _buildCoffretStats() {
    final pointsConformes = _coffret.pointsVerification.where((p) => p.conformite == 'oui').length;
    final totalPoints = _coffret.pointsVerification.length;
    final pourcentage = totalPoints > 0 ? (pointsConformes / totalPoints * 100).round() : 0;

    // Calculer le nombre total de photos (coffret + toutes les observations)
    int totalPhotos = _coffretPhotos.length;
    for (var observation in _coffret.observationsLibres) {
      totalPhotos += observation.photos.length;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Points', '$pointsConformes/$totalPoints'),
          _buildStatItem('Conformité', '$pourcentage%'),
          _buildStatItem('Photos', totalPhotos.toString()),
          _buildStatItem('Observations', _coffret.observationsLibres.length.toString()),
        ],
      ),
    );
  }

  // Méthode pour éditer un essai
void _editerEssai(EssaiDeclenchementDifferentiel essai) async {
  try {
    // Récupérer toutes les mesures pour trouver l'index exact
    final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
    final essais = mesures.essaisDeclenchement;
    
    // Trouver l'index de l'essai en comparant toutes les propriétés
    int essaiIndex = -1;
    for (int i = 0; i < essais.length; i++) {
      final currentEssai = essais[i];
      if (currentEssai.localisation == essai.localisation &&
          currentEssai.coffret == essai.coffret &&
          currentEssai.designationCircuit == essai.designationCircuit &&
          currentEssai.essai == essai.essai) {
        essaiIndex = i;
        break;
      }
    }
    
    if (essaiIndex != -1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AjouterEssaiDeclenchementScreen(
            mission: widget.mission,
            essai: essai,
            index: essaiIndex,
          ),
        ),
      );

      if (result == true) {
        // Rafraîchir l'affichage
        setState(() {});
        _showSuccess('Essai modifié');
      }
    } else {
      _showError('Essai non trouvé pour la modification');
    }
  } catch (e) {
    print('❌ Erreur éditer essai: $e');
    _showError('Erreur lors de la modification de l\'essai');
  }
}

// Méthode pour ajouter un nouvel essai
void _ajouterEssai() async {
  try {
    // Déterminer la localisation pour l'essai
    String localisationPourEssai = '';
    
    if (widget.parentType == 'local') {
      // Récupérer le nom du local
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          // Local dans une zone MT
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) {
              localisationPourEssai = zone.locaux[widget.parentIndex].nom;
            }
          }
        } else {
          // Local MT indépendant
          if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            localisationPourEssai = audit.moyenneTensionLocaux[widget.parentIndex].nom;
          }
        }
      } else {
        // Local BT (toujours dans une zone)
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) {
            localisationPourEssai = zone.locaux[widget.parentIndex].nom;
          }
        }
      }
    } else {
      // Coffret dans une zone directe
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      if (widget.isMoyenneTension) {
        if (widget.parentIndex < audit.moyenneTensionZones.length) {
          localisationPourEssai = audit.moyenneTensionZones[widget.parentIndex].nom;
        }
      } else {
        if (widget.parentIndex < audit.basseTensionZones.length) {
          localisationPourEssai = audit.basseTensionZones[widget.parentIndex].nom;
        }
      }
    }
    
    if (localisationPourEssai.isEmpty) {
      localisationPourEssai = 'Localisation non définie';
    }
    
    // Ouvrir le formulaire d'ajout d'essai
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterEssaiDeclenchementScreen(
          mission: widget.mission,
          localisationPredefinie: localisationPourEssai,
          coffretPredefini: _coffret.nom,
        ),
      ),
    );

    if (result == true) {
      // Rafraîchir l'affichage
      setState(() {});
      _showSuccess('Essai ajouté');
    }
  } catch (e) {
    print('❌ Erreur ajouter essai: $e');
    _showError('Erreur lors de l\'ajout de l\'essai: $e');
  }
}

// Méthode pour supprimer un essai
Future<void> _supprimerEssai(EssaiDeclenchementDifferentiel essai) async {
  try {
    // Récupérer toutes les mesures pour trouver l'index exact
    final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
    final essais = mesures.essaisDeclenchement;
    
    // Trouver l'index de l'essai
    int essaiIndex = -1;
    for (int i = 0; i < essais.length; i++) {
      final currentEssai = essais[i];
      if (currentEssai.localisation == essai.localisation &&
          currentEssai.coffret == essai.coffret &&
          currentEssai.designationCircuit == essai.designationCircuit &&
          currentEssai.essai == essai.essai) {
        essaiIndex = i;
        break;
      }
    }
    
    if (essaiIndex != -1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmer la suppression', style: TextStyle(fontSize: 18)),
          content: Text('Voulez-vous vraiment supprimer cet essai ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await HiveService.deleteEssaiDeclenchement(
                  missionId: widget.mission.id,
                  index: essaiIndex,
                );
                if (success) {
                  setState(() {});
                  _showSuccess('Essai supprimé');
                } else {
                  _showError('Erreur lors de la suppression');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        ),
      );
    } else {
      _showError('Essai non trouvé pour la suppression');
    }
  } catch (e) {
    print('❌ Erreur supprimer essai: $e');
    _showError('Erreur lors de la suppression de l\'essai');
  }
}

  Widget _buildEssaiTab() {
  return FutureBuilder<List<EssaiDeclenchementDifferentiel>>(
    future: _getEssaisPourCoffret(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Erreur de chargement'));
      }
      
      final essais = snapshot.data ?? [];
      
      return Column(
        children: [
          if (essais.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucun essai pour ce coffret',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ajoutez un essai pour tester ce coffret',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _ajouterEssai,
                      icon: Icon(Icons.add),
                      label: Text('Ajouter un essai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: essais.length,
                  itemBuilder: (context, index) {
                    return _buildEssaiCard(essais[index], index);
                  },
                ),
              ),
            ),
        ],
      );
    },
  );
}

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // MÉTHODE BUILD OBLIGATOIRE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_coffret.nom),
        backgroundColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editerCoffret,
            tooltip: 'Modifier le coffret',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCoffretStats(),
          Expanded(
            child: DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'OBSERVATIONS (${_coffret.observationsLibres.length})'),
                        Tab(text: 'PHOTOS (${_coffretPhotos.length})'),
                        Tab(text: 'INFORMATIONS'),
                        Tab(text: 'POINTS (${_coffret.pointsVerification.length})'),
                         Tab(text: 'ESSAI'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab OBSERVATIONS
                        _buildObservationsTab(),
                        
                        // Tab PHOTOS
                        _buildPhotosTab(),

                        // Tab INFORMATIONS
                        ListView(
                          padding: EdgeInsets.all(16),
                          children: [
                            // Informations de base
                            Text(
                              'INFORMATIONS DE BASE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildInfoCard('Nom', _coffret.nom),
                            _buildInfoCard('Type', _coffret.type),
                            if (_coffret.repere != null) _buildInfoCard('Repère', _coffret.repere!),
                            if (_coffret.description != null) _buildInfoCard('Description', _coffret.description!),
                            _buildInfoCard('Domaine de tension', _coffret.domaineTension),

                            SizedBox(height: 16),
                            Text(
                              'INFORMATIONS GÉNÉRALES',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildBooleanInfo('Zone ATEX', _coffret.zoneAtex),
                            _buildBooleanInfo('Identification armoire', _coffret.identificationArmoire),
                            _buildBooleanInfo('Signalisation danger', _coffret.signalisationDanger),
                            _buildBooleanInfo('Présence schéma', _coffret.presenceSchema),
                            _buildBooleanInfo('Présence parafoudre', _coffret.presenceParafoudre),
                            _buildBooleanInfo('Vérification thermographie', _coffret.verificationThermographie),

                            // Alimentations
                            if (_coffret.alimentations.isNotEmpty) ...[
                              SizedBox(height: 16),
                              Text(
                                'ALIMENTATIONS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              SizedBox(height: 12),
                              if (_coffret.type == 'INVERSEUR' && _coffret.alimentations.length >= 3) ...[
                                _buildAlimentationCard(_coffret.alimentations[0], 'ALIMENTATION 1'),
                                _buildAlimentationCard(_coffret.alimentations[1], 'ALIMENTATION 2'),
                                _buildAlimentationCard(_coffret.alimentations[2], 'SORTIE INVERSEUR'),
                              ] else if (_coffret.alimentations.isNotEmpty) ...[
                                _buildAlimentationCard(_coffret.alimentations[0], 'ORIGINE ALIMENTATION'),
                              ],
                              if (_coffret.protectionTete != null) 
                                _buildAlimentationCard(_coffret.protectionTete!, 'PROTECTION DE TÊTE'),
                            ],
                          ],
                        ),

                        // Tab POINTS DE VÉRIFICATION
                        _coffret.pointsVerification.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucun point de vérification',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _coffret.pointsVerification.length,
                                itemBuilder: (context, index) {
                                  return _buildPointVerificationCard(_coffret.pointsVerification[index]);
                                },
                              ),

                               _buildEssaiTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nouvelleObservationController.dispose();
    super.dispose();
  }
}