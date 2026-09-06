import 'dart:async';
import 'package:flutter/foundation.dart';

/// File d'attente d'écritures asynchrones séquentielles thread-safe (Mutex par clé).
///
/// Garantit que les opérations de persistance pour une même entité (ex: missionId)
/// s'exécutent de façon strictement ordonnée et atomique, évitant ainsi
/// les race conditions où une sauvegarde concurrente plus lente écrase
/// des modifications plus récentes.
class PersistenceQueue {
  static final Map<String, Future<dynamic>> _queues = {};

  /// Exécute [action] de manière strictement séquentielle pour la [key] donnée.
  ///
  /// Si une opération est déjà en cours pour cette clé, [action] attendra
  /// sa complétion (qu'elle réussisse ou échoue) avant de démarrer.
  static Future<T> enqueue<T>(String key, Future<T> Function() action) {
    final previousFuture = _queues[key] ?? Future.value(null);
    final completer = Completer<T>();

    _queues[key] = previousFuture.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
        return result;
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ [PersistenceQueue] Erreur pendant l\'exécution pour la clé "$key": $e');
        }
        completer.completeError(e, st);
        return null;
      }
    }).catchError((e) {
      // Ignorer l'erreur précédente pour ne pas bloquer les actions suivantes
      return null;
    });

    // Nettoyer la référence si la file devient inactive
    completer.future.whenComplete(() {
      if (_queues[key] != null) {
        _queues[key]!.then((_) {
          // Si aucune nouvelle action n'a été chaînée entre-temps, libérer la clé
          _queues.remove(key);
        }).catchError((_) {});
      }
    });

    return completer.future;
  }

  /// Indique si une opération est actuellement en cours pour la clé donnée.
  static bool isBusy(String key) => _queues.containsKey(key);

  /// Réinitialiser les files (principalement pour les tests unitaires).
  @visibleForTesting
  static void clear() {
    _queues.clear();
  }
}
