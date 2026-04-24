import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/observation_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/qr_scan_coffret_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_coffret_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

class DetailLocalScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final int localIndex;
  final dynamic local; // MoyenneTensionLocal ou BasseTensionLocal
  final int? zoneIndex;
  final bool isInZone;

  const DetailLocalScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    required this.localIndex,
    required this.local,
    this.zoneIndex,
    this.isInZone = false,
  });

  @override
  State<DetailLocalScreen> createState() => _DetailLocalScreenState();
}

class _DetailLocalScreenState extends State<DetailLocalScreen> {
  late dynamic _local;
  List<CoffretArmoire> _coffrets = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _localPhotos = [];
  bool _isLoadingLocalPhotos = false;

  
  // Pour les nouvelles observations
  final _nouvelleObservationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _local = widget.local;
    _loadCoffrets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chargerPhotosLocal();
      }
    });
  }

  // Charger les coffrets (existants + brouillons)
  void _loadCoffrets() {
    // Récupérer les coffrets déjà sauvegardés dans le local
    final savedCoffrets = List<CoffretArmoire>.from(_local.coffrets);
    
    // Récupérer les brouillons pour ce local
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'local',
      parentIndex: widget.localIndex,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
    );
    
    // Filtrer les brouillons qui ne sont PAS déjà dans les coffrets sauvegardés
    final savedQrCodes = savedCoffrets.map((c) => c.qrCode).toSet();
    final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
    
    setState(() {
      _coffrets = [...uniqueDrafts, ...savedCoffrets];
    });
  }

  Future<void> _refreshLocal() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    setState(() {
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.localIndex < zone.locaux.length) {
              _local = zone.locaux[widget.localIndex];
            }
          }
        } else {
          if (widget.localIndex < audit.moyenneTensionLocaux.length) {
            _local = audit.moyenneTensionLocaux[widget.localIndex];
          }
        }
      } else {
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.localIndex < zone.locaux.length) {
            _local = zone.locaux[widget.localIndex];
          }
        }
      }
      _chargerPhotosLocal();
      _loadCoffrets();
    });
  }
  

  // ===== Ouvrir un brouillon pour continuer =====
  void _ouvrirBrouillon(CoffretArmoire draft) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: 'local',
          parentIndex: widget.localIndex,
          isMoyenneTension: widget.isMoyenneTension,
          zoneIndex: widget.zoneIndex,
          isInZone: widget.isInZone,
          qrCode: draft.qrCode,
          coffret: null,
        ),
      ),
    );
    
    if (result == true) {
      _rechargerLocal();
    }
  }

  // ===== Supprimer un brouillon =====
  void _supprimerBrouillon(CoffretArmoire draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le brouillon'),
        content: const Text('Voulez-vous vraiment supprimer ce brouillon ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.deleteCoffretDraft(draft.qrCode);
              _loadCoffrets();
              _showSuccess('Brouillon supprimé');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _chargerPhotosLocal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (_local.photos.isNotEmpty) {
        setState(() {
          _localPhotos = List.from(_local.photos);
        });
      }
    });
  }

  // ===== MÉTHODES POUR GESTION DES PHOTOS DU LOCAL =====

  Future<void> _prendrePhotoLocal() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingLocalPhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        
        setState(() {
          _localPhotos.add(savedPath);
          _local.photos = _localPhotos;
        });
        
        await _sauvegarderLocal();
        _showSuccess('Photo ajoutée au local');
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingLocalPhotos = false);
    }
  }

  Future<void> _choisirPhotoLocalDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoadingLocalPhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        
        setState(() {
          _localPhotos.add(savedPath);
          _local.photos = _localPhotos;
        });
        
        await _sauvegarderLocal();
        _showSuccess('Photo ajoutée depuis la galerie');
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingLocalPhotos = false);
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
                  
                  // Si c'est une photo du local, mettre à jour le local
                  if (photos == _localPhotos) {
                    _local.photos = _localPhotos;
                  }
                });
                
                // Sauvegarder si c'est une photo du local
                if (photos == _localPhotos) {
                  await _sauvegarderLocal();
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
      padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
      child: _buildPhotosSection(
        'Photos du local',
        _localPhotos,
        _prendrePhotoLocal,
        _choisirPhotoLocalDepuisGalerie,
        isLoading: _isLoadingLocalPhotos,
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
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_locaux');
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
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_locaux');
        setState(() {
          photosList.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _ajouterObservation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          title: 'Nouvelle observation',
          onSave: (ObservationLibre observation) async {
            setState(() {
              _local.observationsLibres.add(observation);
            });
            await _sauvegarderLocal();
            _showSuccess('Observation ajoutée');
          },
        ),
      ),
    );
    
    // Rafraîchir après retour avec un délai pour éviter le conflit
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _rechargerLocal();
      }
    });
  }

  void _editerObservation(int index) async {
    final observation = _local.observationsLibres[index];
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          observation: observation,
          title: 'Modifier l\'observation',
          onSave: (ObservationLibre updatedObservation) async {
            setState(() {
              _local.observationsLibres[index] = updatedObservation;
            });
            await _sauvegarderLocal();
            _showSuccess('Observation modifiée');
          },
        ),
      ),
    );
    
    // Rafraîchir après retour avec un délai
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _rechargerLocal();
      }
    });
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
              final observation = _local.observationsLibres[index];
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
                _local.observationsLibres.removeAt(index);
              });
              
              await _sauvegarderLocal();
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
    final observations = _local.observationsLibres;
    
    return Padding(
     padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
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
                      'Ajoutez vos observations pour documenter ce local',
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
          SizedBox(height: 64),
        ],
      ),
    );
  }

  // ===== FIN MÉTHODES OBSERVATIONS =====

  void _ajouterCoffret() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScanCoffretScreen(
          mission: widget.mission,
          parentType: 'local',
          parentIndex: widget.localIndex,
          isMoyenneTension: widget.isMoyenneTension,
          zoneIndex: widget.zoneIndex,
          isInZone: widget.isInZone,
        ),
      ),
    );

    if (result == true) {
      await _refreshLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coffret ajouté avec succès')),
        );
      }
    }
  }

  void _editerLocal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: widget.isMoyenneTension,
          local: _local,
          localIndex: widget.localIndex,
          zoneIndex: widget.zoneIndex,
          isInZone: widget.isInZone,
        ),
      ),
    );

    if (result == true) {
      // Utiliser addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _rechargerLocal();
        }
      });
    }
  }

  void _rechargerLocal() async {
    if (!mounted) return;
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        setState(() {
          if (widget.isMoyenneTension) {
            if (widget.isInZone && widget.zoneIndex != null) {
              if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
                final zone = audit.moyenneTensionZones[widget.zoneIndex!];
                if (widget.localIndex < zone.locaux.length) {
                  _local = zone.locaux[widget.localIndex];
                }
              }
            } else {
              if (widget.localIndex < audit.moyenneTensionLocaux.length) {
                _local = audit.moyenneTensionLocaux[widget.localIndex];
              }
            }
          } else {
            if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
              final zone = audit.basseTensionZones[widget.zoneIndex!];
              if (widget.localIndex < zone.locaux.length) {
                _local = zone.locaux[widget.localIndex];
              }
            }
          }
          _chargerPhotosLocal();
          _loadCoffrets(); 
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur rechargerLocal: $e');
      }
    }
  }

  // ===== NOUVEAU : Vérifier si un coffret est complet =====
  bool _isCoffretComplet(CoffretArmoire coffret) {
    if (coffret.nom.isEmpty) return false;
    if (coffret.type.isEmpty) return false;
    if (coffret.domaineTension.isEmpty) return false;
    if (coffret.photos.isEmpty) return false;
    
    for (var point in coffret.pointsVerification) {
      if (point.conformite.isEmpty) return false;
      if (point.conformite == 'non') {
        if (point.observation == null || point.observation!.trim().isEmpty) return false;
      }
    }
    
    return true;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _voirCoffret(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailCoffretScreen(
          mission: widget.mission,
          isMoyenneTension: widget.isMoyenneTension,
          parentType: 'local',
          parentIndex: widget.localIndex,
          coffretIndex: index,
          coffret: _local.coffrets[index],
          zoneIndex: widget.zoneIndex,
          isInZone: widget.isInZone,
        ),
      ),
    ).then((_) {
      // Utiliser addPostFrameCallback pour éviter les appels pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _rechargerLocal();
        }
      });
    });
  }

  void _editerCoffret(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: 'local',
          parentIndex: widget.localIndex,
          isMoyenneTension: widget.isMoyenneTension,
          zoneIndex: widget.zoneIndex,
          isInZone: widget.isInZone,
          coffret: _local.coffrets[index],
          coffretIndex: index,
        ),
      ),
    );

    if (result == true) {
      _rechargerLocal();
    }
  }

  void _supprimerCoffret(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce coffret ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _local.coffrets.removeAt(index);
              });
              await _sauvegarderLocal();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coffret supprimé')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  

  Future<void> _sauvegarderLocal() async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          // Local dans une zone MT
          if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.localIndex < zone.locaux.length) {
              zone.locaux[widget.localIndex] = _local;
            }
          }
        } else {
          // Local MT indépendant
          if (widget.localIndex < audit.moyenneTensionLocaux.length) {
            audit.moyenneTensionLocaux[widget.localIndex] = _local;
          }
        }
      } else {
        // Pour basse tension (toujours dans une zone)
        if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.localIndex < zone.locaux.length) {
            zone.locaux[widget.localIndex] = _local;
          }
        }
      }
      
      await HiveService.saveAuditInstallations(audit);
    } catch (e) {
      print('❌ Erreur sauvegarderLocal: $e');
      throw e;
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

  Widget _buildSection(String title, List<ElementControle> elements) {
    final conformiteCount = elements.where((e) => e.conforme!).length;
    final totalCount = elements.length;
    final pourcentage = totalCount > 0 ? (conformiteCount / totalCount * 100).round() : 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getProgressColor(pourcentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getProgressColor(pourcentage)),
                  ),
                  child: Text(
                    '$pourcentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(pourcentage),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...elements.map((element) => _buildElementItem(element)).toList(),
          ],
        ),
      ),
    );
  }

Widget _buildClassementTab() {
  return FutureBuilder<ClassementEmplacement?>(
    future: Future.value(
      HiveService.getClassementForLocal(
        missionId: widget.mission.id,
        localisation: _local.nom,
      ),
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final classement = snapshot.data;

      if (classement == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun classement défini',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _allerAuClassement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('DÉFINIR LE CLASSEMENT'),
              ),
            ],
          ),
        );
      }

      final estComplet =
          classement.af != null &&
          classement.be != null &&
          classement.ae != null &&
          classement.ad != null &&
          classement.ag != null;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: estComplet
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          estComplet
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: estComplet
                              ? Colors.green
                              : AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _local.nom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (classement.zone != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Zone: ${classement.zone}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estComplet
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estComplet ? 'Complet' : 'À compléter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: estComplet
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Origine
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Origine: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            classement.origineClassement.isNotEmpty
                                ? classement.origineClassement
                                : 'Non définie',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: classement.origineClassement.isNotEmpty
                                  ? AppTheme.darkBlue
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Influences
                  if (estComplet)
                    Column(
                    
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfluenceChip('AF', classement.af!),
                              _buildInfluenceChip('BE', classement.be!),
                              _buildInfluenceChip('AE', classement.ae!),
                              _buildInfluenceChip('AD', classement.ad!),
                              _buildInfluenceChip('AG', classement.ag!),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'IP: ${classement.ip ?? "N/A"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              Text(
                                'IK: ${classement.ik ?? "N/A"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: const Text(
                        'Cliquez sur "Modifier le classement" pour renseigner les influences externes',
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _allerAuClassement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('MODIFIER LE CLASSEMENT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

  void _allerAuClassement() async {
    final classement = await HiveService.getOrCreateClassementForLocal(
      missionId: widget.mission.id,
      localisation: _local.nom,
      zone: widget.isInZone && widget.zoneIndex != null 
          ? 'Zone ${widget.zoneIndex! + 1}' 
          : null,
      typeLocal: _local.type,
    );
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementEmplacementScreen(
          mission: widget.mission,
          emplacement: classement,
        ),
      ),
    );
    
    // Rafraîchir après retour
    if (result == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

Widget _buildInfluenceChip(String type, String code) {
  final Map<String, Color> colorMap = {
    'AF': Colors.blue,
    'BE': Colors.purple,
    'AE': Colors.orange,
    'AD': Colors.teal,
    'AG': Colors.red,
  };
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: colorMap[type]!.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: colorMap[type]!.withOpacity(0.3)),
    ),
    child: Text(
      '$type: $code',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorMap[type]!,
      ),
    ),
  );
}

Widget _buildElementItem(ElementControle element) {
  return Container(
    margin: EdgeInsets.only(bottom: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: element.conforme != null ? Colors.green.shade200 : Colors.red.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                element.elementControle,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: element.conforme != null  ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                element.conforme != null ? 'OUI' : 'NON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: element.conforme != null ? Colors.green : Colors.red,
                ),
              ),
            ),
            if (element.priorite != null) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPrioriteColor(element.priorite!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getPrioriteColor(element.priorite!)),
                ),
                child: Text(
                  'N${element.priorite}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPrioriteColor(element.priorite!),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Observation
        if (element.observation != null && element.observation!.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            'Observation: ${element.observation}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold
            ),
          ),
        ],

                // Référence normative 
        if (element.referenceNormative != null && element.referenceNormative!.isNotEmpty) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.article_outlined, size: 12, color: Colors.blue),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Référence: ${element.referenceNormative}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        
        // Photos (uniquement si l'élément n'est pas conforme)
        if (element.photos.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            "Photos de l'observation(${element.photos.length}):",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:element.conforme != null ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 4),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: element.photos.length,
              itemBuilder: (context, photoIndex) {
                return GestureDetector(
                  onTap: () => _previsualiserPhoto(element.photos, photoIndex),
                  child: Container(
                    width: 60,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(element.photos[photoIndex]),
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
  );
}
  Widget _buildCoffretCard(CoffretArmoire coffret, int index) {
    final pointsConformes = coffret.pointsVerification.where((p) => p.conformite == 'oui').length;
    final totalPoints = coffret.pointsVerification.length;
    final pourcentage = totalPoints > 0 ? (pointsConformes / totalPoints * 100).round() : 0;

    final isComplet = coffret.statut == 'complet' || _isCoffretComplet(coffret);
    final isDraft = coffret.statut == 'incomplet';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDraft ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplet ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDraft ? Colors.orange.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDraft ? Icons.drafts_outlined : Icons.electrical_services,
            color: isDraft ? Colors.orange : AppTheme.primaryBlue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                coffret.nom.isEmpty ? 'Sans nom' : coffret.nom,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Badge "Incomplet"
            if (!isComplet)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  'Incomplet',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            // Badge "Complet"
            if (isComplet && !isDraft)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  'Complet',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(coffret.type),
            SizedBox(height: 4),
            if (totalPoints > 0) ...[
              LinearProgressIndicator(
                value: pointsConformes / totalPoints,
                backgroundColor: Colors.grey.shade200,
                color: _getProgressColor(pourcentage),
              ),
              SizedBox(height: 4),
              Text('$pourcentage% conforme ($pointsConformes/$totalPoints)'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              if (isDraft) {
                _ouvrirBrouillon(coffret);
              } else {
                _voirCoffret(index);
              }
            }
            if (value == 'edit') {
              if (isDraft) {
                _ouvrirBrouillon(coffret);
              } else {
                _editerCoffret(index);
              }
            }
            if (value == 'delete') {
              if (isDraft) {
                _supprimerBrouillon(coffret);
              } else {
                _supprimerCoffret(index);
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Text(isDraft ? 'Continuer' : 'Voir détails'),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text('Éditer'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
          if (isDraft) {
            _ouvrirBrouillon(coffret);
          } else {
            _voirCoffret(index);
          }
        },
      ),
    );
  }


  Color _getProgressColor(int pourcentage) {
    if (pourcentage >= 80) return Colors.green;
    if (pourcentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getPrioriteColor(int priorite) {
    switch (priorite) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
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

  Widget _buildLocalStats() {
    // Calculer le nombre total de photos (local + toutes les observations)
    int totalPhotos = _localPhotos.length;
    for (var observation in _local.observationsLibres) {
      totalPhotos += observation.photos.length as int;
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
          _buildZoneStat('Coffrets', _coffrets.length),
          _buildZoneStat('Photos', totalPhotos),
          _buildZoneStat('Observations', _local.observationsLibres.length),
        ],
      ),
    );
  }

  Widget _buildZoneStat(String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
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

  @override
  Widget build(BuildContext context) {
    // Vérifier si c'est un local MT ET de type transformateur
    final isTransformateur = widget.isMoyenneTension && _local.type == 'LOCAL_TRANSFORMATEUR';
    // Pour BT, pas de cellule/transformateur
    final hasCelluleTransfo = widget.isMoyenneTension && _local.type == 'LOCAL_TRANSFORMATEUR' && _local.cellule != null;
    
    final tabCount = isTransformateur ? 7 : 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(_local.nom),
        backgroundColor: widget.isMoyenneTension ? Colors.blue : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editerLocal,
            tooltip: 'Modifier le local',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _ajouterCoffret,
            tooltip: 'Ajouter un coffret',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocalStats(),
          Expanded(
            child: DefaultTabController(
              length: tabCount,
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
                        Tab(text: 'OBSERVATIONS (${_local.observationsLibres.length})'),
                        Tab(text: 'PHOTOS (${_localPhotos.length})'),
                        Tab(text: 'VÉRIFICATIONS'),
                        // Seulement pour MT transformateur
                        if (isTransformateur) Tab(text: 'CELLULE'),
                        if (isTransformateur) Tab(text: 'TRANSFORMATEUR'),
                        Tab(text: 'ÉQUIPEMENTS (${_coffrets.length})'),
                        Tab(text: 'CLASSEMENT'),
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

                        // Tab VÉRIFICATIONS
                        ListView(
                          padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                          children: [
                            _buildSection('DISPOSITIONS CONSTRUCTIVES', _local.dispositionsConstructives ?? []),
                            _buildSection('CONDITIONS D\'EXPLOITATION', _local.conditionsExploitation ?? []),
                          ],
                        ),

                        // Tab CELLULE (seulement pour MT transformateur)
                        if (isTransformateur && _local.cellule != null)
                          ListView(
                            padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'INFORMATIONS CELLULE',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      _buildInfoRow('Fonction', _local.cellule!.fonction),
                                      _buildInfoRow('Type', _local.cellule!.type),
                                      _buildInfoRow('Marque/Modèle/Année', _local.cellule!.marqueModeleAnnee),
                                      _buildInfoRow('Tension assignée', _local.cellule!.tensionAssignee),
                                      _buildInfoRow('Pouvoir de coupure', _local.cellule!.pouvoirCoupure),
                                      _buildInfoRow('Numérotation', _local.cellule!.numerotation),
                                      _buildInfoRow('Parafoudres', _local.cellule!.parafoudres),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSection('ÉLÉMENTS VÉRIFIÉS - CELLULE', _local.cellule!.elementsVerifies),
                            ],
                          )
                        else if (isTransformateur && _local.cellule == null)
                          const Center(child: Text('Aucune information cellule')),

                        // Tab TRANSFORMATEUR (seulement pour MT transformateur)
                        if (isTransformateur && _local.transformateur != null)
                          ListView(
                            padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'INFORMATIONS TRANSFORMATEUR',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      _buildInfoRow('Type', _local.transformateur!.typeTransformateur),
                                      _buildInfoRow('Marque/Année', _local.transformateur!.marqueAnnee),
                                      _buildInfoRow('Puissance assignée', _local.transformateur!.puissanceAssignee),
                                      _buildInfoRow('Tension primaire/secondaire', _local.transformateur!.tensionPrimaireSecondaire),
                                      _buildInfoRow('Relais Buchholz', _local.transformateur!.relaisBuchholz),
                                      _buildInfoRow('Type refroidissement', _local.transformateur!.typeRefroidissement),
                                      _buildInfoRow('Régime neutre', _local.transformateur!.regimeNeutre),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSection('ÉLÉMENTS VÉRIFIÉS - TRANSFORMATEUR', _local.transformateur!.elementsVerifies),
                            ],
                          )
                        else if (isTransformateur && _local.transformateur == null)
                          const Center(child: Text('Aucune information transformateur')),

                        // Tab COFFRETS
                        RefreshIndicator(
                          onRefresh: _refreshLocal,
                          child: _coffrets.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.electrical_services_outlined, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun coffret ajouté',
                                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _ajouterCoffret,
                                        icon: const Icon(Icons.add),
                                        label: const Text('AJOUTER UN COFFRET'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                                  itemCount: _coffrets.length,
                                  itemBuilder: (context, index) {
                                    return _buildCoffretCard(_coffrets[index], index);
                                  },
                                ),
                        ),

                        _buildClassementTab(),
                      ].where((widget) => widget != null).toList(), // Filtrer les nulls
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _coffrets.isEmpty
          ? FloatingActionButton(
              onPressed: _ajouterCoffret,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _nouvelleObservationController.dispose();
    super.dispose();
  }
}