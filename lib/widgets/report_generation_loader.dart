import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

/// Composant de chargement premium réutilisable pour la génération de rapports.
///
/// Affiche une animation circulaire progressive avec transition fluide vers
/// une icône de validation (✔) lorsque le traitement est terminé.
///
/// Usage :
/// ```dart
/// final controller = ReportGenerationLoaderController();
/// ReportGenerationLoader.show(context, controller: controller, message: '...');
/// // ... lorsque terminé :
/// await controller.complete(); // joue l'animation check puis ferme
/// ```
class ReportGenerationLoader extends StatefulWidget {
  final ReportGenerationLoaderController controller;
  final String message;

  const ReportGenerationLoader({
    super.key,
    required this.controller,
    this.message = 'Génération du rapport en cours...',
  });

  /// Affiche le loader en overlay dialog
  static void show(
    BuildContext context, {
    required ReportGenerationLoaderController controller,
    String message = 'Génération du rapport en cours...',
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ReportLoader',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim,
              curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim, secondAnim) {
        return ReportGenerationLoader(
          controller: controller,
          message: message,
        );
      },
    );
  }

  @override
  State<ReportGenerationLoader> createState() => _ReportGenerationLoaderState();
}

class _ReportGenerationLoaderState extends State<ReportGenerationLoader>
    with TickerProviderStateMixin {
  // Animation principale du cercle de progression
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  // Animation de rotation pour l'effet "spinner"
  late AnimationController _rotationController;

  // Animation de transition cercle → check
  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  // Animation du pourcentage affiché
  late AnimationController _percentController;
  late Animation<double> _percentAnim;

  // Animation de pulsation du cercle complet
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _isCompleted = false;
  bool _showCheck = false;
  double _displayPercent = 0;
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.message;

    // Progression du cercle (de 0 à ~85% en boucle lors du chargement)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressAnim.addListener(() {
      if (!_isCompleted && widget.controller._onProgress == null) {
        setState(() {
          _displayPercent = (_progressAnim.value * 100).clamp(0, 85);
        });
      }
    });

    // Rotation continue
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Animation check (cercle → check)
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCubic,
    );

    // Animation du pourcentage vers 100%
    _percentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Animation de pulsation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Démarrer l'animation de progression
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        _progressController.reverse();
      } else if (status == AnimationStatus.dismissed && !_isCompleted) {
        _progressController.forward();
      }
    });

    // Enregistrer les callbacks de complétion, fermeture, annulation et progression
    widget.controller._onComplete = _handleComplete;
    widget.controller._onDismiss = _handleDismiss;
    widget.controller._onCancel = _handleCancel;
    widget.controller._onProgress = _handleProgress;
  }

  void _handleProgress(double progressRatio, String message) {
    if (!mounted || _isCompleted) return;
    setState(() {
      _displayPercent = (progressRatio * 100).clamp(0, 99);
      if (message.isNotEmpty) {
        _currentMessage = message;
      }
    });
  }

  void _handleDismiss() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _handleCancel() {
    if (mounted) {
      try {
        _progressController.stop();
        _rotationController.stop();
      } catch (_) {}
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleComplete() async {
    if (_isCompleted) return;
    _isCompleted = true;

    try {
      // Arrêter la boucle de progression
      _progressController.stop();
      _rotationController.stop();

      // Animer le pourcentage vers 100%
      final currentPercent = _displayPercent;
      _percentAnim = Tween<double>(begin: currentPercent, end: 100).animate(
        CurvedAnimation(parent: _percentController, curve: Curves.easeOut),
      );
      _percentAnim.addListener(() {
        if (mounted) {
          setState(() {
            _displayPercent = _percentAnim.value;
          });
        }
      });

      try {
        await _percentController.forward(from: 0.0).orCancel;
      } catch (_) {}

      // Petit délai avant la transition check
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        // Pulsation puis transition vers le check
        try {
          await _pulseController.forward().orCancel;
          await _pulseController.reverse().orCancel;
        } catch (_) {}

        if (mounted) {
          setState(() => _showCheck = true);
        }

        // Dessiner le check
        try {
          await _checkController.forward().orCancel;
        } catch (_) {}

        // Pause de confirmation visuelle
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } catch (_) {
      // Ignorer toute interruption d'animation
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    _checkController.dispose();
    _percentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur circulaire animé
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _progressAnim,
                    _rotationController,
                    _checkAnim,
                    _pulseAnim,
                  ]),
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _CircularProgressCheckPainter(
                            progress: _isCompleted ? 1.0 : _progressAnim.value,
                            rotation: _rotationController.value,
                            checkProgress: _checkAnim.value,
                            showCheck: _showCheck,
                            isCompleted: _isCompleted,
                            activeColor: AppTheme.primaryBlue,
                            trackColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Pourcentage animé
                AnimatedBuilder(
                  animation: _percentController.isAnimating
                      ? _percentController
                      : _progressAnim,
                  builder: (context, _) {
                    final percent = _displayPercent.round().clamp(0, 100);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showCheck
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryBlue,
                              size: 28,
                              key: const ValueKey('check_icon'),
                            )
                          : Text(
                              '$percent%',
                              key: const ValueKey('percent_text'),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Message de statut
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _showCheck ? 'Rapport généré !' : (_currentMessage.isNotEmpty ? _currentMessage : widget.message),
                    key: ValueKey(_showCheck ? 'done' : _currentMessage),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _showCheck
                          ? AppTheme.primaryBlue
                          : AppTheme.textLight,
                      height: 1.3,
                    ),
                  ),
                ),

                // Bouton Annuler la génération (Rouge)
                if (!_showCheck) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.controller.cancel();
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Annuler la génération',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.red.shade200, width: 1.2),
                      backgroundColor: Colors.red.shade50.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contrôleur pour piloter le loader depuis l'extérieur.
///
/// ```dart
/// final ctrl = ReportGenerationLoaderController();
/// ReportGenerationLoader.show(context, controller: ctrl);
/// // ... attendre la fin de la génération
/// await ctrl.complete();
/// ```
class ReportGenerationLoaderController {
  Future<void> Function()? _onComplete;
  void Function()? _onDismiss;
  void Function()? _onCancel;
  void Function(double progress, String message)? _onProgress;
  bool _isCancelled = false;

  /// Indique si l'utilisateur a annulé la génération.
  bool get isCancelled => _isCancelled;

  /// Annule la génération et ferme le dialogue.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    if (_onCancel != null) {
      _onCancel!();
    } else {
      dismiss();
    }
  }

  /// Met à jour la progression et le message affiché en temps réel.
  void updateProgress(double progressRatio, String message) {
    if (_isCancelled) return;
    if (_onProgress != null) {
      _onProgress!(progressRatio, message);
    }
  }

  /// Déclenche l'animation de complétion (cercle → check → fermeture).
  /// Retourne un Future qui se résout lorsque le dialog est fermé.
  Future<void> complete() async {
    if (_isCancelled) return;
    if (_onComplete != null) {
      await _onComplete!();
    }
  }

  /// Ferme immédiatement le dialogue de chargement sans animation.
  void dismiss() {
    if (_onDismiss != null) {
      _onDismiss!();
    }
  }
}

/// CustomPainter qui dessine :
/// - Un cercle de fond (track)
/// - Un arc de progression épais avec extrémités arrondies
/// - Une transition fluide vers un check (✔) quand showCheck = true
class _CircularProgressCheckPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final double checkProgress;
  final bool showCheck;
  final bool isCompleted;
  final Color activeColor;
  final Color trackColor;

  _CircularProgressCheckPainter({
    required this.progress,
    required this.rotation,
    required this.checkProgress,
    required this.showCheck,
    required this.isCompleted,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Cercle de fond (track)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = showCheck ? 1.5 : 2.0;
    canvas.drawCircle(center, radius, trackPaint);

    if (!showCheck) {
      // Arc de progression
      final progressPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweepAngle = 2 * math.pi * progress;
      final startAngle = -math.pi / 2 + (isCompleted ? 0 : rotation * 2 * math.pi);

      if (sweepAngle > 0.01) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
      }
    } else {
      // Animation du check (✔)
      _drawAnimatedCheck(canvas, center, radius, checkProgress);
    }
  }

  void _drawAnimatedCheck(Canvas canvas, Offset center, double radius, double progress) {
    if (progress <= 0) return;

    final checkPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Points du check (proportionnels à la taille du cercle)
    final scale = radius * 0.55;
    final startPoint = Offset(center.dx - scale * 0.45, center.dy + scale * 0.05);
    final midPoint = Offset(center.dx - scale * 0.05, center.dy + scale * 0.45);
    final endPoint = Offset(center.dx + scale * 0.55, center.dy - scale * 0.40);

    final path = Path();

    if (progress <= 0.5) {
      // Première branche du check (de start à mid)
      final t = progress / 0.5;
      final currentX = startPoint.dx + (midPoint.dx - startPoint.dx) * t;
      final currentY = startPoint.dy + (midPoint.dy - startPoint.dy) * t;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(currentX, currentY);
    } else {
      // Première branche complète + deuxième branche (de mid à end)
      final t = (progress - 0.5) / 0.5;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(midPoint.dx, midPoint.dy);
      final currentX = midPoint.dx + (endPoint.dx - midPoint.dx) * t;
      final currentY = midPoint.dy + (endPoint.dy - midPoint.dy) * t;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressCheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.showCheck != showCheck ||
        oldDelegate.isCompleted != isCompleted;
  }
}
