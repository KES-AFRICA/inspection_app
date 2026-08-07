// lib/features/backup/data/datasources/microsoft_auth_service.dart
// ============================================================
// SERVICE D'AUTHENTIFICATION OAUTH 2.0 PKCE - MICROSOFT ENTRA ID
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/microsoft_user_profile.dart';

class MicrosoftAuthService {
  static const String _defaultClientId = '79e8b82a-9532-4025-bdfe-dd4f7ae31892'; // Valeur venant d'Azure
  static const String _tenant = '3c1c2bd0-8dfc-4b76-883c-c3c3dcaccb19'; // Tenant ID venant d'Azure
  static const String _redirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient';

  static const String _authority = 'https://login.microsoftonline.com/$_tenant/oauth2/v2.0';
  static const String _authorizeUrl = '$_authority/authorize';
  static const String _tokenUrl = '$_authority/token';

  static const List<String> _scopes = [
    'User.Read',
    'Files.ReadWrite.All',
    'offline_access',
  ];

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client;
  final String clientId;

  MicrosoftAuthService({
    http.Client? client,
    String? customClientId,
  })  : _client = client ?? http.Client(),
        clientId = customClientId ?? _defaultClientId;

  // Keys storage
  static const String _keyAccessToken = 'ms_access_token';
  static const String _keyRefreshToken = 'ms_refresh_token';
  static const String _keyTokenExpiry = 'ms_token_expiry';
  static const String _keyUserProfile = 'ms_user_profile';

  // ─────────────────────────────────────────────────────────────
  // 1. GÉNÉRATION DES CLÉS PKCE (code_verifier & code_challenge)
  // ─────────────────────────────────────────────────────────────

  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  // ─────────────────────────────────────────────────────────────
  // 2. OBTENTION DU JETON D'ACCÈS (AVEC RAFRAÎCHISSEMENT AUTO)
  // ─────────────────────────────────────────────────────────────

  Future<String?> getValidAccessToken() async {
    final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
    final accessToken = await _secureStorage.read(key: _keyAccessToken);
    final refreshToken = await _secureStorage.read(key: _keyRefreshToken);

    if (accessToken != null && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      // Si le jeton est encore valide (avec 5 min de marge de sécurité)
      if (expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        return accessToken;
      }
    }

    // Si le jeton a expiré mais que nous avons un refresh_token, rafraîchir silencieusement
    if (refreshToken != null) {
      return await refreshAccessToken(refreshToken);
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 3. RAFRAÎCHISSEMENT DU JETON EXSPIRÉ
  // ─────────────────────────────────────────────────────────────

  Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': _scopes.join(' '),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;
        final expiresIn = (data['expires_in'] as int? ?? 3600);
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));

        await _secureStorage.write(key: _keyAccessToken, value: newAccessToken);
        await _secureStorage.write(key: _keyRefreshToken, value: newRefreshToken);
        await _secureStorage.write(key: _keyTokenExpiry, value: expiry.toIso8601String());

        return newAccessToken;
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 4. ÉCHANGE DU CODE D'AUTORISATION CONTRE LES JETONS
  // ─────────────────────────────────────────────────────────────

  Future<MicrosoftUserProfile?> exchangeCodeForToken({
    required String authCode,
    required String codeVerifier,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': _redirectUri,
          'code_verifier': codeVerifier,
          'scope': _scopes.join(' '),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String?;
        final expiresIn = (data['expires_in'] as int? ?? 3600);
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));

        await _secureStorage.write(key: _keyAccessToken, value: accessToken);
        if (refreshToken != null) {
          await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
        }
        await _secureStorage.write(key: _keyTokenExpiry, value: expiry.toIso8601String());

        // Récupérer le profil utilisateur depuis Microsoft Graph /v1.0/me
        final profile = await fetchUserProfile(accessToken);
        if (profile != null) {
          await _secureStorage.write(
            key: _keyUserProfile,
            value: json.encode(profile.toJson()),
          );
        }
        return profile;
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 5. RÉCUPÉRATION DU PROFIL UTILISATEUR DEPUIS MICROSOFT GRAPH
  // ─────────────────────────────────────────────────────────────

  Future<MicrosoftUserProfile?> fetchUserProfile(String accessToken) async {
    try {
      final response = await _client.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MicrosoftUserProfile.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 6. PROFIL SAUVEGARDÉ EN LOCAL
  // ─────────────────────────────────────────────────────────────

  Future<MicrosoftUserProfile?> getSavedUserProfile() async {
    final str = await _secureStorage.read(key: _keyUserProfile);
    if (str != null) {
      try {
        return MicrosoftUserProfile.fromJson(json.decode(str));
      } catch (_) {}
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 7. DÉCONNEXION PROPRE
  // ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyTokenExpiry);
    await _secureStorage.delete(key: _keyUserProfile);
  }

  // Helper getters
  String get redirectUri => _redirectUri;
  String get authorizeUrl => _authorizeUrl;
  String get scopesString => _scopes.join(' ');
  String buildAuthUrl(String codeChallenge) {
    return '$_authorizeUrl?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(_redirectUri)}&response_mode=query&scope=${Uri.encodeComponent(scopesString)}&code_challenge=$codeChallenge&code_challenge_method=S256';
  }
  String createCodeVerifier() => _generateCodeVerifier();
  String createCodeChallenge(String verifier) => _generateCodeChallenge(verifier);
}
