// lib/widgets/photo_picker_button.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/photo_service.dart';

class PhotoPickerButton extends StatefulWidget {
  final String subDirectory;
  final Function(String) onPhotoTaken;
  final Widget? child;
  final String? buttonLabel;
  final bool isSecondary;
  final VoidCallback? onError;

  const PhotoPickerButton({
    super.key,
    required this.subDirectory,
    required this.onPhotoTaken,
    this.child,
    this.buttonLabel,
    this.isSecondary = false,
    this.onError,
  });

  @override
  State<PhotoPickerButton> createState() => _PhotoPickerButtonState();
}

class _PhotoPickerButtonState extends State<PhotoPickerButton> {
  bool _isLoading = false;
  
  Future<void> _takePhoto() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final photoPath = await PhotoService.takePhoto(widget.subDirectory);
      if (photoPath != null && mounted) {
        widget.onPhotoTaken(photoPath);
      }
    } catch (e) {
      if (mounted && widget.onError != null) {
        widget.onError!();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _pickPhoto() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final photoPath = await PhotoService.pickPhoto(widget.subDirectory);
      if (photoPath != null && mounted) {
        widget.onPhotoTaken(photoPath);
      }
    } catch (e) {
      if (mounted && widget.onError != null) {
        widget.onError!();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return GestureDetector(
        onTap: _takePhoto,
        child: widget.child,
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            icon: Icons.camera_alt,
            label: widget.buttonLabel ?? 'Prendre',
            onTap: _takePhoto,
            isPrimary: !widget.isSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildButton(
            icon: Icons.photo_library,
            label: 'Galerie',
            onTap: _pickPhoto,
            isPrimary: false,
          ),
        ),
      ],
    );
  }
  
  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: !isPrimary ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(8),
            border: !isPrimary ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: isPrimary ? Colors.white : Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? Colors.white : Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}