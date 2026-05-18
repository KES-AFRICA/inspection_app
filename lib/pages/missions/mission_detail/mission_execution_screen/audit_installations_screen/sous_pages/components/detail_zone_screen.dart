import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/observation_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/qr_scan_coffret_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_coffret_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

class DetailZoneScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final int zoneIndex;
  final dynamic zone; // MoyenneTensionZone ou BasseTensionZone

  const DetailZoneScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    required this.zoneIndex,
    required this.zone,
  });

  @override
  State<DetailZoneScreen> createState() => _DetailZoneScreenState();
}

class _DetailZoneScreenState extends State<DetailZoneScreen> {
  late dynamic _zone;
  final ImagePicker _picker = ImagePicker();
  List<String> _zonePhotos = [];
  bool _isLoadingZonePhotos = false;
  
  // Listes combinées (brouillons + coffrets existants)
  List<CoffretArmoire> _coffretsDirects = [];
  List<CoffretArmoire> _coffretsDansLocaux = []; // Pour les coffrets dans les locaux
  
  // Pour les nouvelles observations
  final _nouvelleObservationController = TextEditingController();
  List<String> _photosPourNouvelleObservation = [];
  bool _isLoadingObservationPhotos = false;

  @override
  void initState() {
    super.initState();
    _zone = widget.zone;
    _chargerPhotosZone();
    _loadCoffrets();
  }

  // Charger les coffrets (existants + brouillons)
  void _loadCoffrets() {
    // Récupérer les coffrets déjà sauvegardés
    final savedCoffrets = widget.isMoyenneTension 
        ? List<CoffretArmoire>.from(_zone.coffrets)
        : List<CoffretArmoire>.from(_zone.coffretsDirects);
    
    // Récupérer les brouillons pour cette zone
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: widget.isMoyenneTension ? 'zone_mt' : 'zone_bt',
      parentIndex: widget.zoneIndex,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: null,
    );
    
    // Filtrer les brouillons qui ne sont PAS déjà dans les coffrets sauvegardés
    final savedQrCodes = savedCoffrets.map((c) => c.qrCode).toSet();
    final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
    
    setState(() {
      _coffretsDirects = [...uniqueDrafts, ...savedCoffrets];
    });
  }
  
  void _loadCoffretsDansLocaux() {
    final allCoffretsInLocaux = <CoffretArmoire>[];
    
    for (var local in _zone.locaux) {
      // Coffrets existants dans ce local
      final savedCoffrets = List<CoffretArmoire>.from(local.coffrets);
      allCoffretsInLocaux.addAll(savedCoffrets);
    }
    
    setState(() {
      _coffretsDansLocaux = allCoffretsInLocaux;
    });
  }

  void _chargerPhotosZone() {
    if (_zone.photos.isNotEmpty) {
      setState(() {
        _zonePhotos = List.from(_zone.photos);
      });
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
        setState(() => _isLoadingZonePhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
        
        setState(() {
          _zonePhotos.add(savedPath);
          _zone.photos = _zonePhotos;
        });
        
        await _sauvegarderZone();
        _showSuccess('Photo ajoutée à la zone');
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingZonePhotos = false);
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
        setState(() => _isLoadingZonePhotos = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'zones');
        
        setState(() {
          _zonePhotos.add(savedPath);
          _zone.photos = _zonePhotos;
        });
        
        await _sauvegarderZone();
        _showSuccess('Photo ajoutée depuis la galerie');
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingZonePhotos = false);
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
                  
                  // Si c'est une photo de la zone, mettre à jour la zone
                  if (photos == _zonePhotos) {
                    _zone.photos = _zonePhotos;
                  }
                });
                
                // Sauvegarder si c'est une photo de la zone
                if (photos == _zonePhotos) {
                  await _sauvegarderZone();
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
        'Photos de la zone',
        _zonePhotos,
        _prendrePhotoZone,
        _choisirPhotoZoneDepuisGalerie,
        isLoading: _isLoadingZonePhotos,
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
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_zones');
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
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations_zones');
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
              _zone.observationsLibres.add(observation);
            });
            await _sauvegarderZone();
            _showSuccess('Observation ajoutée');
          },
        ),
      ),
    );
    
    // Rafraîchir la liste même si l'utilisateur a annulé
    _rechargerZone();
  }

  void _editerObservation(int index) async {
    final observation = _zone.observationsLibres[index];
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObservationScreen(
          observation: observation,
          title: 'Modifier l\'observation',
          onSave: (ObservationLibre updatedObservation) async {
            setState(() {
              _zone.observationsLibres[index] = updatedObservation;
            });
            await _sauvegarderZone();
            _showSuccess('Observation modifiée');
          },
        ),
      ),
    );
    
    // Rafraîchir après retour
    _rechargerZone();
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
              final observation = _zone.observationsLibres[index];
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
                _zone.observationsLibres.removeAt(index);
              });
              
              await _sauvegarderZone();
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
    final observations = _zone.observationsLibres;
    
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
                      'Ajoutez vos observations pour documenter cette zone',
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

  // ===== MÉTHODES POUR LOCAUX DANS ZONES MT =====

  void _ajouterLocalMT() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    );

    if (result == true) {
      await _refreshZone();
      _showSuccess('Local ajouté avec succès');
    }
  }

  void _voirLocalMT(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          localIndex: index,
          local: _zone.locaux[index],
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    ).then((_) => _rechargerZone());
  }

  void _editerLocalMT(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          local: _zone.locaux[index],
          localIndex: index,
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
    }
  }

  void _supprimerLocalMT(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce local ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await HiveService.deleteLocalFromMoyenneTensionZone(
                missionId: widget.mission.id,
                zoneIndex: widget.zoneIndex,
                localIndex: index,
              );
              
              if (success) {
                _rechargerZone();
                _showSuccess('Local supprimé');
              } else {
                _showError('Erreur lors de la suppression');
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== MÉTHODES POUR LOCAUX DANS ZONES BT =====

  void _ajouterLocalBT() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    );

    if (result == true) {
      await _refreshZone();
      _showSuccess('Local ajouté avec succès');
    }
  }

  void _voirLocalBT(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLocalScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          localIndex: index,
          local: _zone.locaux[index],
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    ).then((_) => _rechargerZone());
  }

  void _editerLocalBT(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          local: _zone.locaux[index],
          localIndex: index,
          zoneIndex: widget.zoneIndex,
          isInZone: true,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
    }
  }

  void _supprimerLocalBT(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce local ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
              
              if (widget.zoneIndex < audit.basseTensionZones.length) {
                if (index < audit.basseTensionZones[widget.zoneIndex].locaux.length) {
                  audit.basseTensionZones[widget.zoneIndex].locaux.removeAt(index);
                  await HiveService.saveAuditInstallations(audit);
                  
                  _rechargerZone();
                  _showSuccess('Local supprimé');
                }
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== MÉTHODES POUR COFFRETS DANS ZONES MT =====

  void _ajouterCoffretMT() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => 
        QrScanCoffretScreen(
          mission: widget.mission,
          parentType: 'zone_mt',
          parentIndex: widget.zoneIndex,
          isMoyenneTension: true,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
      _showSuccess('Equipement ajouté avec succès');
    }
  }

  void _voirCoffretMT(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailCoffretScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          parentType: 'zone_mt',
          parentIndex: widget.zoneIndex,
          coffretIndex: index,
          coffret: _zone.coffrets[index],
        ),
      ),
    ).then((_) => _rechargerZone());
  }

  void _editerCoffretMT(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: 'zone_mt',
          parentIndex: widget.zoneIndex,
          isMoyenneTension: true,
          coffret: _zone.coffrets[index],
          coffretIndex: index,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
    }
  }

  void _supprimerCoffretMT(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet Équipement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
              
              if (widget.zoneIndex < audit.moyenneTensionZones.length) {
                if (index < audit.moyenneTensionZones[widget.zoneIndex].coffrets.length) {
                  audit.moyenneTensionZones[widget.zoneIndex].coffrets.removeAt(index);
                  await HiveService.saveAuditInstallations(audit);
                  
                  _rechargerZone();
                  _showSuccess('Équipement supprimé');
                }
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== MÉTHODES POUR COFFRETS DIRECTS DANS ZONES BT =====

  void _ajouterCoffretDirectBT() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScanCoffretScreen(
          mission: widget.mission,
          parentType: 'zone_bt',
          parentIndex: widget.zoneIndex,
          isMoyenneTension: false,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
      _showSuccess('Équipement ajouté avec succès');
    }
  }

  void _voirCoffretDirectBT(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailCoffretScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          parentType: 'zone_bt',
          parentIndex: widget.zoneIndex,
          coffretIndex: index,
          coffret: _zone.coffretsDirects[index],
        ),
      ),
    ).then((_) => _rechargerZone());
  }

  void _editerCoffretDirectBT(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: 'zone_bt',
          parentIndex: widget.zoneIndex,
          isMoyenneTension: false,
          coffret: _zone.coffretsDirects[index],
          coffretIndex: index,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
    }
  }

  void _supprimerCoffretDirectBT(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce Équipement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
              
              if (widget.zoneIndex < audit.basseTensionZones.length) {
                if (index < audit.basseTensionZones[widget.zoneIndex].coffretsDirects.length) {
                  audit.basseTensionZones[widget.zoneIndex].coffretsDirects.removeAt(index);
                  await HiveService.saveAuditInstallations(audit);
                  
                  _rechargerZone();
                  _showSuccess('Équipement supprimé');
                }
              }
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ===== MÉTHODES COMMUNES =====

  void _editerZone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: widget.isMoyenneTension,
          zone: _zone,
          zoneIndex: widget.zoneIndex,
        ),
      ),
    );

    if (result == true) {
      _rechargerZone();
    }
  }

  void _showActionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton pour ajouter un local
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.isMoyenneTension ? _ajouterLocalMT() : _ajouterLocalBT();
                },
                icon: Icon(Icons.domain, size: 24),
                label: Text(
                  'Ajouter un local',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            
            // Bouton pour ajouter un coffret
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.isMoyenneTension ? _ajouterCoffretMT() : _ajouterCoffretDirectBT();
                },
                icon: Icon(Icons.electrical_services, size: 24),
                label: Text(
                  widget.isMoyenneTension 
                    ? 'Ajouter un Équipement' 
                    : 'Ajouter un Équipement direct',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            
            // Bouton pour annuler
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _rechargerZone() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
  
    setState(() {
      if (widget.isMoyenneTension) {
        if (widget.zoneIndex < audit.moyenneTensionZones.length) {
          _zone = audit.moyenneTensionZones[widget.zoneIndex];
        }
      } else {
        if (widget.zoneIndex < audit.basseTensionZones.length) {
          _zone = audit.basseTensionZones[widget.zoneIndex];
        }
      }
      _chargerPhotosZone();
      _loadCoffrets();
    });
  }

  Future<void> _sauvegarderZone() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    if (widget.isMoyenneTension) {
      if (widget.zoneIndex < audit.moyenneTensionZones.length) {
        audit.moyenneTensionZones[widget.zoneIndex] = _zone;
      }
    } else {
      if (widget.zoneIndex < audit.basseTensionZones.length) {
        audit.basseTensionZones[widget.zoneIndex] = _zone;
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

  // === WIDGETS POUR LES LISTES ===

  Widget _buildLocalCard(dynamic local, int index, bool isMoyenneTension) {
    // Résolution sûre des éléments (sans crash null)
    final List<ElementControle> dispositions = local is MoyenneTensionLocal
        ? local.dispositionsConstructives
        : local is BasseTensionLocal
            ? (local.dispositionsConstructives ?? [])
            : <ElementControle>[];

    final conformiteCount = dispositions.where((e) => e.conforme == true).length;
    final nonConformeCount = dispositions.where((e) => e.conforme == false && !e.estNA).length;
    final totalCount = dispositions.length;
    final pourcentage = totalCount > 0 ? (conformiteCount / totalCount * 100).round() : 0;

    final int totalPhotos = (local.photos as List).length +
        (local.observationsLibres as List).fold<int>(
            0, (sum, obs) => sum + (obs.photos as List).length);

    final localTypes = HiveService.getLocalTypes();
    final typeLabel = localTypes[local.type] ?? local.type ?? '';
    final isFlowLong = local.type == 'LOCAL_TRANSFORMATEUR' || local.type == 'LOCAL_MTBT';
    final inaccessible = !(local.accessible ?? true);
    final aReverifier = local.aReverifier ?? false;

    // ── Icône et couleur selon l'état ──
    final Color cardColor = inaccessible
        ? Colors.red.shade50
        : Colors.white;
    final Color borderColor = inaccessible
        ? Colors.red.shade200
        : aReverifier
            ? Colors.orange.shade300
            : Colors.grey.shade200;
    final Color accentColor = inaccessible
        ? Colors.red
        : aReverifier
            ? Colors.orange
            : AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => isMoyenneTension ? _voirLocalMT(index) : _voirLocalBT(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header : icône + nom + badges ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      inaccessible
                          ? Icons.lock_outline
                          : Icons.domain,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local.nom ?? 'Sans nom',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (aReverifier)
                        _buildBadge('À revérifier', Colors.orange),
                      if (inaccessible)
                        _buildBadge('Inaccessible', Colors.red),
                    ],
                  ),
                ],
              ),

              if (!inaccessible) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ── Stats ──
                Row(
                  children: [
                    _buildMiniStat(Icons.electrical_services_outlined,
                        '${(local.coffrets as List).length}', 'coffrets'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.photo_outlined,
                        '$totalPhotos', 'photos'),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.comment_outlined,
                        '${(local.observationsLibres as List).length}', 'obs.'),
                    if (isFlowLong && local is MoyenneTensionLocal) ...[
                      const SizedBox(width: 12),
                      _buildMiniStat(Icons.memory_outlined,
                          '${local.cellules.length}', 'cellules'),
                    ],
                  ],
                ),

                // ── Barre de conformité ──
                if (totalCount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? conformiteCount / totalCount : 0,
                            backgroundColor: Colors.grey.shade200,
                            color: _getProgressColor(pourcentage),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pourcentage%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(pourcentage),
                        ),
                      ),
                      if (nonConformeCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge('$nonConformeCount NC', Colors.red),
                      ],
                    ],
                  ),
                ] else
                  Text(
                    'Aucune vérification enregistrée',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Local inaccessible lors de l\'inspection',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],

              // ── Actions ──
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        isMoyenneTension ? _editerLocalMT(index) : _editerLocalBT(index),
                    icon: Icon(Icons.edit_outlined,
                        size: 15, color: AppTheme.primaryBlue),
                    label: Text('Éditer',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () =>
                        isMoyenneTension ? _supprimerLocalMT(index) : _supprimerLocalBT(index),
                    icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                    label: const Text('Supprimer',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // MODIFIER : _buildCoffretCard pour gérer les brouillons
  Widget _buildCoffretCard(CoffretArmoire coffret, int index, bool isMoyenneTension) {
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
          color: isDraft ? Colors.orange.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDraft ? Icons.drafts_outlined : Icons.electrical_services,
          color: isDraft ? Colors.orange : Colors.orange,
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
          Text('${coffret.type} • ${coffret.photos.length} photo(s) • ${coffret.observationsLibres.length} observation(s)'),
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
          if (value == 'edit') {
            _editerCoffret(coffret, index, isMoyenneTension);
          } else if (value == 'delete') {
            if (isDraft) {
              _supprimerBrouillon(coffret);
            } else {
              _supprimerCoffret(coffret, isMoyenneTension);
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 8),
                Text('Éditer'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Supprimer', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        if (isDraft) {
          _ouvrirBrouillon(coffret);
        } else {
          // Calculer le vrai index dans _zone.coffretsDirects / _zone.coffrets
          // (sans les brouillons qui sont en tête de _coffretsDirects)
          final realIndex = isMoyenneTension
              ? _zone.coffrets.indexWhere((c) => c.qrCode == coffret.qrCode)
              : _zone.coffretsDirects.indexWhere((c) => c.qrCode == coffret.qrCode);
          if (realIndex >= 0) {
            _voirCoffret(realIndex, isMoyenneTension);
          }
        }
      },
    ),
  );
}

// MODIFIER : Éditer un Équipement (brouillon ou complet)
void _editerCoffret(CoffretArmoire coffret, int index, bool isMoyenneTension) async {
  // Recalculer le vrai index dans la liste source (sans brouillons)
  final realIndex = isMoyenneTension
      ? _zone.coffrets.indexWhere((c) => c.qrCode == coffret.qrCode)
      : _zone.coffretsDirects.indexWhere((c) => c.qrCode == coffret.qrCode);

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AjouterCoffretScreen(
        mission: widget.mission,
        parentType: widget.isMoyenneTension ? 'zone_mt' : 'zone_bt',
        parentIndex: widget.zoneIndex,
        isMoyenneTension: widget.isMoyenneTension,
        isInZone: false,
        qrCode: coffret.qrCode,
        coffret: coffret.statut == 'complet' ? coffret : null,
        coffretIndex: coffret.statut == 'complet' ? realIndex : null,
      ),
    ),
  );

  if (result == true) {
    _rechargerZone();
  }
}

// MODIFIER : Voir un Équipement complet
void _voirCoffret(int index, bool isMoyenneTension) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailCoffretScreen(
        mission: widget.mission,
        isMoyenneTension: widget.isMoyenneTension,
        parentType: widget.isMoyenneTension ? 'zone_mt' : 'zone_bt',
        parentIndex: widget.zoneIndex,
        coffretIndex: index,
        coffret: isMoyenneTension ? _zone.coffrets[index] : _zone.coffretsDirects[index],
      ),
    ),
  ).then((_) => _rechargerZone());
}

// MODIFIER : Supprimer un Équipement complet
void _supprimerCoffret(CoffretArmoire coffret, bool isMoyenneTension) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: const Text('Voulez-vous vraiment supprimer ce coffret ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
            if (isMoyenneTension) {
              if (widget.zoneIndex < audit.moyenneTensionZones.length) {
                final realIndex = audit.moyenneTensionZones[widget.zoneIndex].coffrets
                    .indexWhere((c) => c.qrCode == coffret.qrCode);
                if (realIndex >= 0) {
                  audit.moyenneTensionZones[widget.zoneIndex].coffrets.removeAt(realIndex);
                  await HiveService.saveAuditInstallations(audit);
                }
              }
            } else {
              if (widget.zoneIndex < audit.basseTensionZones.length) {
                final realIndex = audit.basseTensionZones[widget.zoneIndex].coffretsDirects
                    .indexWhere((c) => c.qrCode == coffret.qrCode);
                if (realIndex >= 0) {
                  audit.basseTensionZones[widget.zoneIndex].coffretsDirects.removeAt(realIndex);
                  await HiveService.saveAuditInstallations(audit);
                }
              }
            }
            _rechargerZone();
            _showSuccess('Coffret supprimé');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}


  // Ouvrir un brouillon pour continuer
  void _ouvrirBrouillon(CoffretArmoire draft) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCoffretScreen(
          mission: widget.mission,
          parentType: widget.isMoyenneTension ? 'zone_mt' : 'zone_bt',
          parentIndex: widget.zoneIndex,
          isMoyenneTension: widget.isMoyenneTension,
          isInZone: false,
          qrCode: draft.qrCode,
          coffret: null,
        ),
      ),
    );
    
    if (result == true) {
      _rechargerZone();
    }
  }

  // Supprimer un brouillon
  void _supprimerBrouillon(CoffretArmoire draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le brouillon'),
        content: Text('Voulez-vous vraiment supprimer ce brouillon ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.deleteCoffretDraft(draft.qrCode);
              _loadCoffrets();
              _showSuccess('Brouillon supprimé');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Vérifier si un Équipement est complet
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

  Color _getProgressColor(int pourcentage) {
    if (pourcentage >= 80) return Colors.green;
    if (pourcentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState(String type, String message, Function? onTap, IconData icon, String buttonText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          if (onTap != null) ...[
            SizedBox(height: 8),
            Text(
              'Commencez par ajouter un $type',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => onTap(),
              icon: Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshZone() async {
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    
    setState(() {
      if (widget.isMoyenneTension) {
        if (widget.zoneIndex < audit.moyenneTensionZones.length) {
          _zone = audit.moyenneTensionZones[widget.zoneIndex];
        }
      } else {
        if (widget.zoneIndex < audit.basseTensionZones.length) {
          _zone = audit.basseTensionZones[widget.zoneIndex];
        }
      }
      _chargerPhotosZone();
      _loadCoffrets();
    });
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

  Widget _buildZoneHeader() {
    // Calculer le nombre total de photos (zone + toutes les observations de la zone)
    int totalPhotos = _zonePhotos.length;
    for (var observation in _zone.observationsLibres) {
      totalPhotos += observation.photos.length as int;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_zone.description != null && _zone.description!.isNotEmpty) ...[
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(_zone.description!),
            SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildZoneStat('Locaux', _zone.locaux.length),
              _buildZoneStat(
                'Coffrets', 
                widget.isMoyenneTension ? _zone.coffrets.length : _zone.coffretsDirects.length
              ),
              _buildZoneStat('Photos', totalPhotos),
              _buildZoneStat('Observations', _zone.observationsLibres.length),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMoyenneTension = widget.isMoyenneTension;
  
    final hasCoffrets = _coffretsDirects.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_zone.nom),
        backgroundColor: isMoyenneTension ? Colors.blue : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editerZone,
            tooltip: 'Modifier la zone',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildZoneHeader(),

            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryBlue,
                tabs: [
                  Tab(text: 'OBSERVATIONS (${_zone.observationsLibres.length})'),
                  Tab(text: 'PHOTOS (${_zonePhotos.length})'),
                  Tab(text: 'LOCAUX (${_zone.locaux.length})'),
                  Tab(text: isMoyenneTension 
                    ? 'ÉQUIPEMENTS (${_coffretsDirects.length})'
                    : 'ÉQUIPEMENTS DIRECTS (${_coffretsDirects.length})'
                  ),
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

                  // Tab LOCAUX
                  Builder(
                    builder: (context) {
                      final drafts = widget.isMoyenneTension
                          ? HiveService.getLocalDraftsForMoyenneTensionZone(
                              missionId: widget.mission.id,
                              zoneIndex: widget.zoneIndex,
                            )
                          : HiveService.getLocalDraftsForBasseTensionZone(
                              missionId: widget.mission.id,
                              zoneIndex: widget.zoneIndex,
                            );

                      final locauxExistants = _zone.locaux;
                      final nomsExistants = locauxExistants.map((l) => l.nom).toSet();
                      final uniqueDrafts = drafts
                          .where((d) => !nomsExistants.contains(d['nomLocal']))
                          .toList();

                      if (locauxExistants.isEmpty && uniqueDrafts.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshZone,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: _buildEmptyState(
                                'locaux',
                                'Aucun local dans cette zone',
                                widget.isMoyenneTension ? _ajouterLocalMT : _ajouterLocalBT,
                                Icons.domain,
                                'AJOUTER UN LOCAL',
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshZone,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                          itemCount: (uniqueDrafts.length + locauxExistants.length) as int,
                          itemBuilder: (context, index) {
                            if (index < uniqueDrafts.length) {
                              return _buildLocalDraftCard(uniqueDrafts[index], widget.isMoyenneTension);
                            } else {
                              final localIndex = index - uniqueDrafts.length;
                              return _buildLocalCard(locauxExistants[localIndex], localIndex, widget.isMoyenneTension);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  
                  // Tab COFFRETS
                  !hasCoffrets
                  ? RefreshIndicator(
                        onRefresh: _refreshZone,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: _buildEmptyState(
                              'coffrets', 
                              isMoyenneTension 
                                ? 'Aucun Équipement dans cette zone' 
                                : 'Aucun Équipement direct dans cette zone',
                              isMoyenneTension ? _ajouterCoffretMT : _ajouterCoffretDirectBT,
                              Icons.electrical_services,
                              'AJOUTER UN ÉQUIPEMENTS',
                            )
                          ),
                        ),
                      )
                  
                  : RefreshIndicator(
                      onRefresh: _refreshZone,
                      color: AppTheme.primaryBlue,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                        itemCount: _coffretsDirects.length,
                        itemBuilder: (context, index) {
                          return _buildCoffretCard(
                            _coffretsDirects[index],
                            index,
                            isMoyenneTension,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionModal,
        backgroundColor: AppTheme.primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLocalDraftCard(Map<String, dynamic> draftData, bool isMoyenneTension) {
    final local = draftData['local'];
    final nomLocal = draftData['nomLocal'] as String? ?? 'Sans nom';
    final currentStep = draftData['currentStep'] as int? ?? 0;
    final draftId = draftData['localId'] as String?;

    final localTypes = HiveService.getLocalTypes();
    String typeLabel = 'Local';
    if (local is MoyenneTensionLocal || local is BasseTensionLocal) {
      typeLabel = localTypes[local.type] ?? local.type ?? 'Local';
    }

    final isFlowLong = local?.type == 'LOCAL_TRANSFORMATEUR' || local?.type == 'LOCAL_MTBT';
    final totalSteps = isFlowLong ? 4 : 3;
    final progress = totalSteps > 0 ? (currentStep / totalSteps).clamp(0.0, 1.0) : 0.0;
    final pourcentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        onTap: () => _ouvrirBrouillonLocal(draftData, isMoyenneTension),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomLocal,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          typeLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge('Brouillon', Colors.amber),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Étape $currentStep / $totalSteps',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                            Text('$pourcentage%',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _ouvrirBrouillonLocal(draftData, isMoyenneTension),
                    icon: const Icon(Icons.play_arrow, size: 15, color: Colors.amber),
                    label: const Text('Continuer',
                        style: TextStyle(fontSize: 12, color: Colors.amber)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer le brouillon ?'),
                          content: const Text(
                              'Ce brouillon sera supprimé définitivement.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && draftId != null) {
                        await HiveService.deleteLocalDraft(draftId);
                        _refreshZone();
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                    label: const Text('Supprimer',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

void _ouvrirBrouillonLocal(Map<String, dynamic> draftData, bool isMoyenneTension) async {
  final draftId = draftData['localId'] as String?;
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AjouterLocalScreen(
        mission: widget.mission,
        isMoyenneTension: isMoyenneTension,
        zoneIndex: widget.zoneIndex,
        isInZone: true,
        local: null,
        draftId: draftId,
      ),
    ),
  );
  
  if (result == true) {
    _rechargerZone();
  }
}

void _supprimerBrouillonLocal(String? draftId, String nomLocal) {
  if (draftId == null) return;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer le brouillon'),
      content: Text('Voulez-vous vraiment supprimer le brouillon "$nomLocal" ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await HiveService.deleteLocalDraft(draftId);
            _rechargerZone();
            _showSuccess('Brouillon supprimé');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Supprimer'),
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