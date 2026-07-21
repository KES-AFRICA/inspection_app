import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/logo/client_logo_screen.dart';
import 'package:inspec_app/pages/missions/jsa/jsa_standalone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class MissionHubScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;

  const MissionHubScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<MissionHubScreen> createState() => _MissionHubScreenState();
}

class _MissionHubScreenState extends State<MissionHubScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isJsaDone = HiveService.isJsaCompleted(widget.mission.id);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: isSmallScreen ? 20 : 24, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Column(
          children: [
            Text(
              widget.mission.nomClient,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.mission.nomSite != null && widget.mission.nomSite!.isNotEmpty)
              Text(
                widget.mission.nomSite!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'MODULES DE LA MISSION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.greyDark,
                ),
              ),
              const SizedBox(height: 12),

              // ── Les Cartes dans l'Ordre Souhaité (JSA -> Elec -> Éclairage -> Logo) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Column(
                      children: [
                        _buildJsaCard(context, isJsaDone),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildElectricCard(context, isJsaDone)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildLightingCard(context, isJsaDone)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildClientLogoCard(context),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildJsaCard(context, isJsaDone),
                        const SizedBox(height: 16),
                        _buildElectricCard(context, isJsaDone),
                        const SizedBox(height: 16),
                        _buildLightingCard(context, isJsaDone),
                        const SizedBox(height: 16),
                        _buildClientLogoCard(context),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte 1 : JSA (Analyse de Sécurité du Travail) - Prérequis Obligatoire
  Widget _buildJsaCard(BuildContext context, bool isJsaDone) {
    return _buildInspectionCard(
      context: context,
      title: 'JSA - Analyse de Sécurité',
      subtitle: isJsaDone
          ? 'Analyse des risques et consignes de sécurité validées. Vous pouvez accéder aux volets d\'inspection.'
          : 'Analyse des risques, EPI, plan d\'urgence et consignes de sécurité obligatoires avant d\'effectuer les inspections.',
      badgeText: isJsaDone ? 'JSA Validée' : '1. Prérequis Obligatoire',
      iconBgColor: isJsaDone ? Colors.green.shade100 : Colors.teal.shade100,
      iconColor: isJsaDone ? Colors.green.shade800 : Colors.teal.shade800,
      icon: isJsaDone ? Icons.verified_user_rounded : Icons.health_and_safety_rounded,
      isDisabled: false,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JsaStandaloneScreen(
              mission: widget.mission,
            ),
          ),
        );
        setState(() {}); // Rafraîchir l'état après validation du JSA
      },
    );
  }

  /// Carte 2 : Vérification électrique
  Widget _buildElectricCard(BuildContext context, bool isJsaDone) {
    return _buildInspectionCard(
      context: context,
      title: 'Vérification électrique',
      subtitle: isJsaDone
          ? 'Audit complet des installations électriques MT/BT, transformateurs, armoires et mesures de sécurité.'
          : 'Complétez et validez d\'abord la JSA pour déverrouiller le volet de vérification électrique.',
      badgeText: isJsaDone ? '2. Audit Électrique' : 'Verrouillé - JSA requise',
      iconBgColor: isJsaDone
          ? AppTheme.primaryBlue.withValues(alpha: 0.12)
          : Colors.grey.shade200,
      iconColor: isJsaDone ? AppTheme.primaryBlue : Colors.grey.shade500,
      icon: isJsaDone ? Icons.bolt : Icons.lock_outline_rounded,
      isDisabled: !isJsaDone,
      onTap: () {
        if (!isJsaDone) {
          _showLockedDialog('la vérification électrique');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MissionDetailScreen(
              mission: widget.mission,
              user: widget.user,
            ),
          ),
        );
      },
    );
  }

  /// Carte 3 : Vérification éclairage
  Widget _buildLightingCard(BuildContext context, bool isJsaDone) {
    return _buildInspectionCard(
      context: context,
      title: 'Vérification éclairage',
      subtitle: isJsaDone
          ? 'Contrôle de conformité des luminaires, détection des non-conformités et état de fonctionnement.'
          : 'Complétez et validez d\'abord la JSA pour déverrouiller le module éclairage.',
      badgeText: isJsaDone ? '3. Module Éclairage' : 'Verrouillé - JSA requise',
      iconBgColor: isJsaDone ? Colors.amber.shade100 : Colors.grey.shade200,
      iconColor: isJsaDone ? Colors.amber.shade900 : Colors.grey.shade500,
      icon: isJsaDone ? Icons.lightbulb : Icons.lock_outline_rounded,
      isDisabled: !isJsaDone,
      onTap: () {
        if (!isJsaDone) {
          _showLockedDialog('la vérification éclairage');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LightingMissionDetailScreen(
              mission: widget.mission,
            ),
          ),
        );
      },
    );
  }

  /// Carte 4 : Logo du client
  Widget _buildClientLogoCard(BuildContext context) {
    final hasLogo =
        widget.mission.logoClient != null && widget.mission.logoClient!.isNotEmpty;
    return _buildInspectionCard(
      context: context,
      title: 'Logo du client',
      subtitle: hasLogo
          ? 'Identité visuelle configurée. Le logo sera positionné automatiquement sur tous les rapports PDF.'
          : 'Gestion et personnalisation de l\'identité visuelle du client pour tous les rapports.',
      badgeText: '4. Identité Visuelle',
      iconBgColor: Colors.indigo.shade100,
      iconColor: Colors.indigo.shade800,
      icon: Icons.branding_watermark_rounded,
      isDisabled: false,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientLogoScreen(
              mission: widget.mission,
            ),
          ),
        );
        setState(() {}); // Rafraîchir l'état après le retour de l'écran Logo
      },
    );
  }

  /// Message d'avertissement lorsqu'une carte verrouillée est cliquée
  void _showLockedDialog(String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lock_rounded, color: Colors.amber.shade900, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'JSA Obligatoire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Veuillez d\'abord remplir et valider l\'Analyse de Sécurité (JSA) pour déverrouiller $moduleName.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('COMPRIS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Constructeur de Carte d'inspection aligné sur AppTheme Card sans overflow
  Widget _buildInspectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isDisabled ? 0.5 : 2,
      color: isDisabled ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDisabled
            ? BorderSide(color: Colors.grey.shade300, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDisabled
                                ? Colors.grey.shade600
                                : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isDisabled ? Icons.lock_outline_rounded : Icons.chevron_right,
                    color: isDisabled ? Colors.grey.shade400 : AppTheme.greyDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isDisabled ? Colors.grey.shade500 : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
