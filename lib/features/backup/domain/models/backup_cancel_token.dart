// lib/features/backup/domain/models/backup_cancel_token.dart

/// Token d'annulation filaire propagé à travers toute la chaîne (UI -> Controller -> Service -> Graph HTTP)
class BackupCancelToken {
  bool _isCancelled = false;
  String? _reason;
  final List<void Function(String reason)> _listeners = [];

  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  /// Annule le jeton avec une raison explicite
  void cancel([String reason = 'Sauvegarde annulée par l\'utilisateur']) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;

    for (final listener in List.from(_listeners)) {
      try {
        listener(reason);
      } catch (_) {}
    }
  }

  /// S'abonne aux notifications d'annulation
  void onCancel(void Function(String reason) listener) {
    if (_isCancelled && _reason != null) {
      listener(_reason!);
    } else {
      _listeners.add(listener);
    }
  }

  /// Lève une exception d'annulation si le jeton est annulé
  void throwIfCancelled() {
    if (_isCancelled) {
      throw BackupCancelledException(_reason ?? 'Sauvegarde annulée');
    }
  }
}

/// Exception explicite levée lors de l'annulation d'une sauvegarde
class BackupCancelledException implements Exception {
  final String message;
  BackupCancelledException(this.message);

  @override
  String toString() => 'BackupCancelledException: $message';
}
