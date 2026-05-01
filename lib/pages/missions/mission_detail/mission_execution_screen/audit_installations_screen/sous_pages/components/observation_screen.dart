// observation_screen.dart
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'dart:io';
import 'package:inspec_app/services/safe_image_service.dart';
import 'package:inspec_app/mixins/photo_safe_state_mixin.dart';

class ObservationScreen extends StatefulWidget {
  final ObservationLibre? observation;
  final String title;
  final Function(ObservationLibre) onSave;
  final bool canAddPhotos;

  const ObservationScreen({
    super.key,
    this.observation,
    required this.title,
    required this.onSave,
    this.canAddPhotos = true,
  });

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen>
    with PhotoSafeStateMixin<ObservationScreen> {
  final _texteController = TextEditingController();

  List<String> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.observation != null) {
      _texteController.text = widget.observation!.texte;
      _photos = List.from(widget.observation!.photos);
    }
  }

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  Future<String> _savePhotoToAppDirectory(File photoFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/observations');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName = 'obs_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    await photoFile.copy(newPath);
    return newPath;
  }

  // ✅ Sécurisation loading + mounted
  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _isLoading = v);
  }

  Future<void> _prendrePhoto() async {
    if (!widget.canAddPhotos) return;

    await runPhotoAction(() async {
      try {
        _setLoading(true);

        final File? photoFile = await SafeImageService.takePhoto(
          mounted: mounted,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        // Annulé ou écran déjà détruit
        if (photoFile == null || !mounted) return;

        final savedPath = await _savePhotoToAppDirectory(photoFile);
        if (!mounted) return;

        setState(() {
          _photos.add(savedPath);
        });
      } catch (e) {
        _showError('Erreur lors de la prise de photo: $e');
      } finally {
        _setLoading(false);
      }
    });
  }

  Future<void> _choisirPhotoDepuisGalerie() async {
    if (!widget.canAddPhotos) return;

    await runPhotoAction(() async {
      try {
        _setLoading(true);

        final File? photoFile = await SafeImageService.pickFromGallery(
          mounted: mounted,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        // Annulé ou écran déjà détruit
        if (photoFile == null || !mounted) return;

        final savedPath = await _savePhotoToAppDirectory(photoFile);
        if (!mounted) return;

        setState(() {
          _photos.add(savedPath);
        });
      } catch (e) {
        _showError('Erreur lors de la sélection: $e');
      } finally {
        _setLoading(false);
      }
    });
  }

  void _supprimerPhoto(int index) {
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
              if (!mounted) return;
              setState(() {
                _photos.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _previsualiserPhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
                  File(_photos[index]),
                  fit: BoxFit.contain,
                  // ✅ Limite mémoire (préview)
                  cacheWidth: 1024,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    if (!widget.canAddPhotos) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos associées (${_photos.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBlue,
          ),
        ),
        SizedBox(height: 8),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_photos.isEmpty)
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
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _previsualiserPhoto(index),
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
                          File(_photos[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          // ✅ Limite mémoire (miniatures)
                          cacheWidth: 600,
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
                        onTap: () => _supprimerPhoto(index),
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
        if (widget.canAddPhotos)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _prendrePhoto,
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
                  onPressed: _choisirPhotoDepuisGalerie,
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              final texte = _texteController.text.trim();
              if (texte.isEmpty) {
                _showError('Veuillez saisir une observation');
                return;
              }
              final observation = ObservationLibre(
                texte: texte,
                photos: List.from(_photos),
                dateCreation: widget.observation?.dateCreation ?? DateTime.now(),
                dateModification: DateTime.now(),
              );
              widget.onSave(observation);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _texteController,
                decoration: InputDecoration(
                  hintText: 'Saisissez votre observation...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 24),
              _buildPhotosSection(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}