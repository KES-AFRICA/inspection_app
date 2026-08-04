import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Utilitaire global de résolution dynamique des chemins d'images de l'application.
class AppImageUtils {
  static String? _cachedDocDir;

  /// Récupère ou met en cache le chemin des documents de l'app.
  static Future<String> getAppDocDir() async {
    if (_cachedDocDir != null) return _cachedDocDir!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedDocDir = dir.path;
    return _cachedDocDir!;
  }

  /// Résolution synchrone (rapide si le fichier existe ou si le dossier app_flutter est en cache).
  static String? resolvePathSync(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.trim();

    try {
      // 1. Accès direct
      final direct = File(cleanPath);
      if (direct.existsSync()) return direct.path;

      // 2. Ré-ancrage si le répertoire app_flutter courant est déjà en mémoire cache
      if (_cachedDocDir != null) {
        for (final folderKeyword in ['audit_photos', 'client_logos']) {
          if (cleanPath.contains(folderKeyword)) {
            final separator = cleanPath.contains('\\$folderKeyword') ? '\\' : '/';
            final idx = cleanPath.indexOf(folderKeyword);
            if (idx != -1) {
              final subPath = cleanPath.substring(idx);
              final reanchored = File('$_cachedDocDir$separator$subPath');
              if (reanchored.existsSync()) return reanchored.path;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Résolution asynchrone complète avec récupération du répertoire documents de l'app.
  static Future<String?> resolvePathAsync(String? path) async {
    final syncRes = resolvePathSync(path);
    if (syncRes != null) return syncRes;

    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.trim();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cachedDocDir = appDir.path;

      final direct = File(cleanPath);
      if (await direct.exists()) return direct.path;

      for (final folderKeyword in ['audit_photos', 'client_logos']) {
        if (cleanPath.contains(folderKeyword)) {
          final separator = cleanPath.contains('\\$folderKeyword') ? '\\' : '/';
          final idx = cleanPath.indexOf(folderKeyword);
          if (idx != -1) {
            final subPath = cleanPath.substring(idx);
            final reanchored = File('${appDir.path}$separator$subPath');
            if (await reanchored.exists()) return reanchored.path;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}

/// Widget sécurisé pour l'affichage des images fichiers (`SafeFileImage`).
/// 
/// Avantages :
/// 1. Ré-ancre automatiquement les chemins absolus transférés ou obsolètes vers le dossier `app_flutter` courant.
/// 2. Vérifie l'existence effective du fichier AVANT de créer le `FileImage` (évite les exceptions `_File.length`).
/// 3. Attrape tout échec de décodage avec un fallback propre (`Icons.broken_image_outlined`).
class SafeFileImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? errorBuilder;
  final Widget? errorWidget;

  const SafeFileImage({
    Key? key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<SafeFileImage> createState() => _SafeFileImageState();
}

class _SafeFileImageState extends State<SafeFileImage> {
  String? _resolvedPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolvePath();
  }

  @override
  void didUpdateWidget(SafeFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _resolvePath();
    }
  }

  Future<void> _resolvePath() async {
    final syncPath = AppImageUtils.resolvePathSync(widget.path);
    if (syncPath != null) {
      if (mounted) {
        setState(() {
          _resolvedPath = syncPath;
          _isLoading = false;
        });
      }
      return;
    }

    final asyncPath = await AppImageUtils.resolvePathAsync(widget.path);
    if (mounted) {
      setState(() {
        _resolvedPath = asyncPath;
        _isLoading = false;
      });
    }
  }

  Widget _buildFallback(BuildContext context) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade100,
      );
    }

    if (_resolvedPath == null) {
      return _buildFallback(context);
    }

    return Image.file(
      File(_resolvedPath!),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) => _buildFallback(context),
    );
  }
}
