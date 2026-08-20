// observation_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/utils/image_compress_helper.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/components/safe_file_image.dart';

class ObservationScreen extends StatefulWidget {
  final ObservationLibre? observation; // null pour création, non-null pour édition
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

class _ObservationScreenState extends State<ObservationScreen> {
  final _texteController = TextEditingController();
  final _picker = ImagePicker();
  List<String> _photos = [];
  bool _isLoading = false;

  String? _pointVerificationKey;
  String? _referenceNormative;
  String? _familleRisque;
  String? _criticite;

  List<NormativeSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.observation != null) {
      _texteController.text = widget.observation!.texte;
      _photos = List.from(widget.observation!.photos);
      _pointVerificationKey = widget.observation!.pointVerificationKey;
      _referenceNormative = widget.observation!.referenceNormative;
      _familleRisque = widget.observation!.familleRisque;
      _criticite = widget.observation!.criticite;
    }

    _texteController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _texteController.text.trim();
    if (text.length >= 3) {
      final results = NormativeSearchService.search(text);
      setState(() {
        _searchResults = results;
      });
    } else {
      if (_searchResults.isNotEmpty) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _texteController.removeListener(_onTextChanged);
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
    
    await ImageCompressHelper.compressImage(photoFile, newPath);
    return newPath;
  }

  Future<void> _prendrePhoto() async {
    if (!widget.canAddPhotos) return;
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoading = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path));
        
        setState(() {
          _photos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _choisirPhotoDepuisGalerie() async {
    if (!widget.canAddPhotos) return;
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (photo != null) {
        setState(() => _isLoading = true);
        
        final savedPath = await _savePhotoToAppDirectory(File(photo.path));
        
        setState(() {
          _photos.add(savedPath);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _supprimerPhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${_photos.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 12),
        if (_photos.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Aucune photo ajoutée',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
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
              childAspectRatio: 1,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photoPath = _photos[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SafeFileImage(
                        path: photoPath,
                        fit: BoxFit.cover,
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
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNormativeLinkBadge() {
    if (_referenceNormative == null || _referenceNormative!.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Référence normative associée',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  _referenceNormative!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (_familleRisque != null && _familleRisque!.isNotEmpty)
                  Text(
                    'Risque : $_familleRisque (${_criticite ?? ""})',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
            tooltip: 'Supprimer le rattachement normatif',
            onPressed: () {
              setState(() {
                _pointVerificationKey = null;
                _referenceNormative = null;
                _familleRisque = null;
                _criticite = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNormativeSuggestions() {
    if (_searchResults.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade800, size: 18),
              SizedBox(width: 6),
              Text(
                'Suggestions de points de vérification normatifs (${_searchResults.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          ..._searchResults.map((res) {
            final isSelected = _pointVerificationKey == res.key;
            return InkWell(
              onTap: () {
                setState(() {
                  _pointVerificationKey = res.key;
                  _referenceNormative = res.referenceNormative;
                  _familleRisque = res.familleRisque;
                  _criticite = res.criticite;
                  _searchResults = [];
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber.shade200 : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.pointVerification,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            res.referenceNormative,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${res.familleRisque} (${res.criticite})',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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
                pointVerificationKey: _pointVerificationKey,
                referenceNormative: _referenceNormative,
                familleRisque: _familleRisque,
                criticite: _criticite,
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
                maxLines: 4,
              ),
              _buildNormativeLinkBadge(),
              _buildNormativeSuggestions(),
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