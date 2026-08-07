// lib/features/backup/presentation/widgets/microsoft_account_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/backup_providers.dart';
import '../../domain/models/microsoft_user_profile.dart';

class MicrosoftAccountHeader extends ConsumerWidget {
  const MicrosoftAccountHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(microsoftAuthNotifierProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (err, _) => _buildLoggedOutView(context, ref),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, WidgetRef ref, MicrosoftUserProfile profile) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0078D4).withOpacity(0.2),
            border: Border.all(color: const Color(0xFF0078D4), width: 2),
          ),
          child: Center(
            child: Text(
              profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Microsoft 365 Cloud Enterprise',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            await ref.read(microsoftAuthNotifierProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          tooltip: 'Se déconnecter de Microsoft',
        ),
      ],
    );
  }

  Widget _buildLoggedOutView(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 26),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compte Microsoft 365',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Non connecté (Mode Local)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _showLoginDialog(context, ref);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0078D4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.login_rounded, size: 16),
          label: const Text('Connexion'),
        ),
      ],
    );
  }

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    final authService = ref.read(microsoftAuthServiceProvider);
    final verifier = authService.createCodeVerifier();
    final challenge = authService.createCodeChallenge(verifier);
    final authUrl = authService.buildAuthUrl(challenge);

    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF0078D4)),
            SizedBox(width: 8),
            Text('Connexion Microsoft 365'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Cliquez ci-dessous pour vous connecter avec votre compte professionnel Microsoft M365.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(authUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF0078D4)),
                label: const Text('Ouvrir la page de connexion Microsoft'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Entrez le code d\'autorisation fourni :',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'Collez le code d\'autorisation ici...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ref
                    .read(microsoftAuthNotifierProvider.notifier)
                    .loginWithCode(code: code, verifier: verifier);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Connexion Microsoft réussie !'
                            : 'Échec de la connexion. Vérifiez le code.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0078D4)),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
