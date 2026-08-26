import 'package:flutter/foundation.dart';

/// Exception spécifique levée lorsqu'une génération documentaire est annulée par l'utilisateur.
class ReportGenerationCancelledException implements Exception {
  final String generationId;
  final String message;

  const ReportGenerationCancelledException({
    required this.generationId,
    this.message = 'La génération documentaire a été annulée par l\'utilisateur.',
  });

  @override
  String toString() => 'ReportGenerationCancelledException(generationId: $generationId): $message';
}

/// Jeton centralisé d'annulation coopérative pour les traitements asynchrones de génération documentaire.
class CancellationToken {
  final String generationId;
  bool _isCancelled = false;
  final List<VoidCallback> _onCancelCallbacks = [];

  CancellationToken({String? generationId})
      : generationId = generationId ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Indique si l'annulation a été demandée.
  bool get isCancelled => _isCancelled;

  /// Enregistre une fonction de rappel à exécuter immédiatement lors de l'annulation.
  void addListener(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _onCancelCallbacks.add(callback);
    }
  }

  /// Déclenche l'annulation coopérative.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final callback in List<VoidCallback>.from(_onCancelCallbacks)) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur dans un listener CancellationToken: $e');
        }
      }
    }
  }

  /// Vérifie si l'annulation a été demandée et lève immédiatement une exception si c'est le cas.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw ReportGenerationCancelledException(generationId: generationId);
    }
  }
}
