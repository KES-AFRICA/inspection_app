// item_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/features/description_installations/presentation/providers/description_installations_provider.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final Mission mission;
  final String sectionKey;
  final InstallationItem item;
  final int index;
  final List<String> champs;
  final List<String> requiredFields;

  const ItemDetailScreen({
    super.key,
    required this.mission,
    required this.sectionKey,
    required this.item,
    required this.index,
    required this.champs,
    required this.requiredFields,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var champ in widget.champs) {
      _controllers[champ] = TextEditingController(
        text: widget.item.data[champ] ?? '',
      );
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
            // Image en plein écran
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(
                  File(widget.item.photoPaths[index]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bouton de fermeture
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Numéro de la photo
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Photo ${index + 1}/${widget.item.photoPaths.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Bouton suppression
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
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

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        widget.item.addPhoto(photo.path);
      });
      await _saveChanges();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        widget.item.addPhoto(photo.path);
      });
      await _saveChanges();
    }
  }

  Future<void> _removePhoto(int photoIndex) async {
    setState(() {
      widget.item.removePhoto(widget.item.photoPaths[photoIndex]);
    });
    await _saveChanges();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mettre à jour les données
      for (var champ in widget.champs) {
        widget.item.updateField(champ, _controllers[champ]!.text.trim());
      }

      final success = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).updateInstallationItem(
        widget.sectionKey,
        widget.index,
        widget.item,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modifications enregistrées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await ref.read(descriptionInstallationsProvider(widget.mission.id).notifier).removeInstallationItem(
          widget.sectionKey,
          widget.index,
        );

        if (success) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'élément'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saveChanges,
              icon: Icon(Icons.save),
              tooltip: 'Enregistrer',
            ),
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Annuler' : 'Modifier',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Informations de l'élément
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.champs.map((champ) {
                      final isRequired = widget.requiredFields.contains(champ);
                      final isObservationField = champ.toLowerCase().contains('observation') || 
                                                champ.toLowerCase().contains('note') || 
                                                champ.toLowerCase().contains('commentaire');
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isRequired)
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            _isEditing
                                ? TextFormField(
                                    controller: _controllers[champ],
                                    maxLines: isObservationField ? 5 : 1,
                                    minLines: isObservationField ? 3 : 1,
                                    decoration: InputDecoration(
                                      hintText: 'Saisissez ${champ.toLowerCase()}...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, 
                                        vertical: isObservationField ? 12 : 10
                                      ),
                                      alignLabelWithHint: isObservationField,
                                    ),
                                    enabled: _isEditing,
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Text(
                                      _controllers[champ]!.text.isNotEmpty
                                          ? _controllers[champ]!.text
                                          : 'Non renseigné',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _controllers[champ]!.text.isNotEmpty
                                            ? Colors.black87
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  Divider(),

                  // Section photos
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Photos (${widget.item.photoPaths.length})',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          if (_isEditing)
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _takePhoto,
                                  icon: Icon(Icons.camera_alt_outlined),
                                  tooltip: 'Prendre une photo',
                                ),
                                IconButton(
                                  onPressed: _pickFromGallery,
                                  icon: Icon(Icons.photo_library_outlined),
                                  tooltip: 'Choisir depuis la galerie',
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (widget.item.photoPaths.isEmpty)
                        Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                'Aucune photo',
                                style: TextStyle(color: Colors.grey.shade500),
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
                          itemCount: widget.item.photoPaths.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showPhotoFullScreen(index),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(File(widget.item.photoPaths[index])),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Overlay au survol
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.black.withOpacity(0.1),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.zoom_in,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Numéro de la photo
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bouton de suppression
                                  if (_isEditing)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(index),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
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
                    ],
                  ),

                  SizedBox(height: 32),

                  // Bouton de suppression
                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteItem,
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        label: Text(
                          'SUPPRIMER CET ÉLÉMENT',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}