import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/backup_providers.dart';
import '../../domain/models/microsoft_user_profile.dart';

class MicrosoftAccountHeader extends ConsumerWidget {
  const MicrosoftAccountHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(microsoftAuthNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: authState.when(
        data: (profile) {
          if (profile == null) {
            return _buildLoggedOutView(context, ref);
          }
          return _buildLoggedInView(context, ref, profile);
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(color: Color(0xFF0078D4)),
          ),
        ),
        error: (err, _) => _buildLoggedOutView(context, ref),
      ),
    );
  }

  Widget _buildLoggedInView(
    BuildContext context,
    WidgetRef ref,
    MicrosoftUserProfile profile,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: TextStyle(color: subTextColor, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              tooltip: 'Se déconnecter de Microsoft',
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Badge de statut connecté
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Connecté • Synchronisation Cloud KES Active',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedOutView(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? Colors.white70 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Icône Cloud M365 moderne avec dégradé bleu Microsoft & ombre douce
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0078D4), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF0078D4).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0078D4).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_queue_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compte Microsoft 365',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sauvegardez vos missions sur OneDrive KES',
                    style: TextStyle(color: subTextColor, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton de connexion moderne avec effet de dégradé et ombre
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0078D4).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLoginDialog(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0078D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text(
                  'Connexion',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Badge de statut moderne et épuré en bas avec puce rouge clignotante/fixe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Non connecté (Mode Local)',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Déconnexion Microsoft 365',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte professionnel Microsoft 365 ?\n\nLes sauvegardes automatiques sur OneDrive seront suspendues jusqu\'à votre prochaine connexion.',
          style: TextStyle(
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              side: BorderSide(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(microsoftAuthNotifierProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Déconnexion de Microsoft 365 effectuée.'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    final authService = ref.read(microsoftAuthServiceProvider);
    final verifier = authService.createCodeVerifier();
    final challenge = authService.createCodeChallenge(verifier);
    final authUrl = authService.buildAuthUrl(challenge);

    final codeController = TextEditingController();
    final appLinks = AppLinks();
    StreamSubscription? linkSubscription;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
            final dialogBorder = isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
            final primaryText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
            final subText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final cardBg = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9);
            final cardBorder = isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
            final inputFill = isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
            final inputBorder = isDarkMode ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1);
            final inputText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
            final closeIconColor = isDarkMode ? Colors.white60 : const Color(0xFF64748B);

            // Écouter automatiquement le retour Deep Link mobile MSAL
            linkSubscription ??= appLinks.uriLinkStream.listen((uri) async {
              if (uri.queryParameters.containsKey('code')) {
                final code = uri.queryParameters['code']!;
                codeController.text = code;
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                final success = await ref
                    .read(microsoftAuthNotifierProvider.notifier)
                    .loginWithCode(code: code, verifier: verifier);

                if (ctx.mounted) {
                  linkSubscription?.cancel();
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text('Connexion Microsoft 365 réussie !'),
                          ],
                        ),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    setState(() {
                      isLoading = false;
                      errorMessage =
                          'Échec de l\'authentification automatique. Réessayez.';
                    });
                  }
                }
              }
            });

            return Dialog(
              backgroundColor: dialogBg,
              elevation: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: dialogBorder,
                  width: 1,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header : Badge Microsoft + Titre responsive + Bouton fermer
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0078D4),
                                    Color(0xFF0284C7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0078D4,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connexion Microsoft 365',
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Authentification KES Enterprise',
                                    style: TextStyle(
                                      color: subText,
                                      fontSize: 11.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(
                                Icons.close_rounded,
                                color: closeIconColor,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Étape 1 : Bouton d'ouverture du navigateur
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0078D4,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ÉTAPE 1',
                                      style: TextStyle(
                                        color: Color(0xFF0078D4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Connexion via le navigateur',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ouvrez la page officielle Microsoft pour vous connecter avec vos identifiants KES.',
                                style: TextStyle(
                                  color: subText,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(authUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0078D4),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFF0078D4,
                                      ).withValues(alpha: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.open_in_browser_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Ouvrir la page Microsoft',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Étape 2 : Saisie du code d'autorisation
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0078D4,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ÉTAPE 2',
                                      style: TextStyle(
                                        color: Color(0xFF0078D4),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Validation du code',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Collez le code obtenu après la connexion :',
                                style: TextStyle(
                                  color: subText,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: codeController,
                                style: TextStyle(
                                  color: inputText,
                                  fontSize: 13,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText:
                                      'Code d\'autorisation (ex: M.R3_BAY...)',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.key_rounded,
                                    color: Color(0xFF0078D4),
                                    size: 18,
                                  ),
                                  suffixIcon: codeController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: closeIconColor,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            codeController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: inputFill,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: inputBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: inputBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0078D4),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFFCA5A5),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFCA5A5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Actions : Annuler & Valider (100% Responsive & Zero Overflow)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        linkSubscription?.cancel();
                                        Navigator.pop(ctx);
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: subText,
                                  side: BorderSide(
                                    color: inputBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    if (codeController.text.trim().isNotEmpty &&
                                        !isLoading)
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0078D4,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      (codeController.text.trim().isEmpty ||
                                          isLoading)
                                      ? null
                                      : () async {
                                          setState(() {
                                            isLoading = true;
                                            errorMessage = null;
                                          });

                                          final code = codeController.text
                                              .trim();
                                          final success = await ref
                                              .read(
                                                microsoftAuthNotifierProvider
                                                    .notifier,
                                              )
                                              .loginWithCode(
                                                code: code,
                                                verifier: verifier,
                                              );

                                          if (ctx.mounted) {
                                            if (success) {
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Connexion Microsoft 365 réussie !',
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFF10B981,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              setState(() {
                                                isLoading = false;
                                                errorMessage =
                                                    'Échec de l\'authentification. Veuillez vérifier votre code et réessayer.';
                                              });
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0078D4),
                                    disabledBackgroundColor: const Color(
                                      0xFF0078D4,
                                    ).withValues(alpha: 0.3),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white
                                        .withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Valider la connexion',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
