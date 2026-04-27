// lib/services/secure_password_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';

class SecurePasswordService {
  // ═══════════════════════════════════════════════════════════════
  // FLUTTER SECURE STORAGE
  // ═══════════════════════════════════════════════════════════════
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  // ═══════════════════════════════════════════════════════════════
  // CONFIGURATION BCRYPT (migration depuis Argon2)
  // ═══════════════════════════════════════════════════════════════
  static const int _bcryptCost = 12; // compromis mobile sûr

  // ═══════════════════════════════════════════════════════════════
  // CLÉS DE STOCKAGE (inchangées sauf le sel)
  // ═══════════════════════════════════════════════════════════════
  static const String _keyPasswordHash = 'password_hash_';
  static const String _keyFailedAttempts = 'failed_attempts_';
  static const String _keyLockoutUntil = 'lockout_until_';
  static const String _keyLastAttemptAt = 'last_attempt_at_';
  static const String _keyAttemptTimestamps = 'attempt_timestamps_';

  // ═══════════════════════════════════════════════════════════════
  // CRÉATION D'UN NOUVEAU MOT DE PASSE (INSCRIPTION)
  // ═══════════════════════════════════════════════════════════════

  static Future<PasswordResult> createPassword({
    required String email,
    required String plainPassword,
  }) async {
    try {
      final strengthCheck = _checkPasswordStrength(plainPassword);
      if (!strengthCheck.isValid) {
        return PasswordResult(
          success: false,
          errorMessage: strengthCheck.message,
        );
      }

      // ✅ bcrypt gère lui‑même le sel
      final hash = _hashPasswordWithBcrypt(plainPassword);

      await _secureStorage.write(
        key: '$_keyPasswordHash$email',
        value: hash,
      );

      await _resetSecurityCounters(email);

      return PasswordResult(success: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur création password: $e');
      }
      return PasswordResult(
        success: false,
        errorMessage: 'Erreur lors de la création du mot de passe.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HASH BCRYPT (remplace Argon2)
  // ═══════════════════════════════════════════════════════════════

  static String _hashPasswordWithBcrypt(String password) {
    final salt = BCrypt.gensalt(logRounds: _bcryptCost);
    return BCrypt.hashpw(password, salt);
  }

  // ═══════════════════════════════════════════════════════════════
  // VÉRIFICATION DU MOT DE PASSE (CONNEXION)
  // ═══════════════════════════════════════════════════════════════

  static Future<VerificationResult> verifyPassword({
    required String email,
    required String plainPassword,
  }) async {
    try {
      final lockoutCheck = await _isAccountLocked(email);
      if (lockoutCheck.isLocked) {
        return VerificationResult(
          success: false,
          errorMessage: 'Compte temporairement verrouillé.',
          isLocked: true,
          lockoutRemainingSeconds: lockoutCheck.remainingSeconds,
        );
      }

      final storedHash = await _secureStorage.read(
        key: '$_keyPasswordHash$email',
      );

      if (storedHash == null) {
        return VerificationResult(
          success: false,
          errorMessage: 'Compte non trouvé.',
        );
      }

      final isMatch =
          BCrypt.checkpw(plainPassword, storedHash);

      await _recordAttempt(email, isMatch);

      if (!isMatch) {
        final failedAttempts = await _getFailedAttempts(email);
        final remainingAttempts = 5 - failedAttempts;

        if (failedAttempts >= 5) {
          return VerificationResult(
            success: false,
            errorMessage: 'Compte verrouillé pour 30 minutes.',
            isLocked: true,
            lockoutRemainingSeconds: 1800,
          );
        }

        return VerificationResult(
          success: false,
          errorMessage: 'Mot de passe incorrect.',
          remainingAttempts: remainingAttempts,
        );
      }

      await _resetSecurityCounters(email);

      return VerificationResult(success: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur vérification password: $e');
      }
      return VerificationResult(
        success: false,
        errorMessage: 'Erreur lors de la vérification.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MISE À JOUR DU MOT DE PASSE
  // ═══════════════════════════════════════════════════════════════

  static Future<PasswordResult> updatePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final verification = await verifyPassword(
      email: email,
      plainPassword: oldPassword,
    );

    if (!verification.success) {
      return PasswordResult(
        success: false,
        errorMessage: 'Ancien mot de passe incorrect.',
      );
    }

    return createPassword(
      email: email,
      plainPassword: newPassword,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FORCE DU MOT DE PASSE (inchangée)
  // ═══════════════════════════════════════════════════════════════

  static StrengthCheckResult _checkPasswordStrength(
      String password) {
    if (password.length < 8) {
      return StrengthCheckResult(
        isValid: false,
        message: 'Le mot de passe doit contenir au moins 8 caractères.',
      );
    }

    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasDigit = false;
    bool hasSpecialChar = false;

    for (final c in password.codeUnits) {
      final ch = String.fromCharCode(c);
      if (ch.toUpperCase() != ch.toLowerCase()) {
        if (ch == ch.toUpperCase()) hasUppercase = true;
        if (ch == ch.toLowerCase()) hasLowercase = true;
      } else if (c >= 48 && c <= 57) {
        hasDigit = true;
      } else {
        hasSpecialChar = true;
      }
    }

    if (!hasUppercase) {
      return StrengthCheckResult(
        isValid: false,
        message: 'Au moins une majuscule requise.',
      );
    }
    if (!hasLowercase) {
      return StrengthCheckResult(
        isValid: false,
        message: 'Au moins une minuscule requise.',
      );
    }
    if (!hasDigit) {
      return StrengthCheckResult(
        isValid: false,
        message: 'Au moins un chiffre requis.',
      );
    }
    if (!hasSpecialChar) {
      return StrengthCheckResult(
        isValid: false,
        message: 'Au moins un caractère spécial requis.',
      );
    }

    return StrengthCheckResult(isValid: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // GESTION DES TENTATIVES / LOCKOUT (inchangée)
  // ═══════════════════════════════════════════════════════════════

  static Future<LockoutResult> _isAccountLocked(String email) async {
    final lockoutUntilStr =
        await _secureStorage.read(key: '$_keyLockoutUntil$email');

    if (lockoutUntilStr == null) {
      return LockoutResult(isLocked: false, remainingSeconds: 0);
    }

    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    final now = DateTime.now();

    if (now.isAfter(lockoutUntil)) {
      await _resetSecurityCounters(email);
      return LockoutResult(isLocked: false, remainingSeconds: 0);
    }

    return LockoutResult(
      isLocked: true,
      remainingSeconds: lockoutUntil.difference(now).inSeconds,
    );
  }

  static Future<void> _recordAttempt(
      String email, bool success) async {
    if (success) return;

    final failedAttempts = await _getFailedAttempts(email) + 1;

    await _secureStorage.write(
      key: '$_keyFailedAttempts$email',
      value: failedAttempts.toString(),
    );

    if (failedAttempts >= 5) {
      final lockoutUntil =
          DateTime.now().add(const Duration(minutes: 30));
      await _secureStorage.write(
        key: '$_keyLockoutUntil$email',
        value: lockoutUntil.toIso8601String(),
      );
    }
  }

  static Future<int> _getFailedAttempts(String email) async {
    final value =
        await _secureStorage.read(key: '$_keyFailedAttempts$email');
    return value != null ? int.parse(value) : 0;
  }

  static Future<void> _resetSecurityCounters(String email) async {
    await _secureStorage.write(
        key: '$_keyFailedAttempts$email', value: '0');
    await _secureStorage.delete(key: '$_keyLockoutUntil$email');
    await _secureStorage.delete(key: '$_keyLastAttemptAt$email');
    await _secureStorage.write(
        key: '$_keyAttemptTimestamps$email', value: '');
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES (inchangées)
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> hasPassword(String email) async {
    final hash =
        await _secureStorage.read(key: '$_keyPasswordHash$email');
    return hash != null;
  }

  static Future<void> deletePassword(String email) async {
    await _secureStorage.delete(key: '$_keyPasswordHash$email');
    await _resetSecurityCounters(email);
  }

  static Future<void> resetSecurityCounters(String email) async {
    await _resetSecurityCounters(email.toLowerCase());
  }
}

// ═══════════════════════════════════════════════════════════════
// CLASSES DE RÉSULTATS (inchangées)
 // ═══════════════════════════════════════════════════════════════

class PasswordResult {
  final bool success;
  final String? errorMessage;

  PasswordResult({required this.success, this.errorMessage});
}

class VerificationResult {
  final bool success;
  final String? errorMessage;
  final bool isLocked;
  final int lockoutRemainingSeconds;
  final int remainingAttempts;

  VerificationResult({
    required this.success,
    this.errorMessage,
    this.isLocked = false,
    this.lockoutRemainingSeconds = 0,
    this.remainingAttempts = 5,
  });
}

class StrengthCheckResult {
  final bool isValid;
  final String? message;

  StrengthCheckResult({required this.isValid, this.message});
}

class LockoutResult {
  final bool isLocked;
  final int remainingSeconds;

  LockoutResult({
    required this.isLocked,
    required this.remainingSeconds,
  });
}