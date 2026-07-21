import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/logo/client_logo_screen.dart';

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

              const SizedBox(height: 24),

              Text(
                'VOLETS D\'INSPECTION DISPONIBLES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.greyDark,
                ),
              ),
              const SizedBox(height: 12),

              // ── Les Cartes de Volets (Responsive Layout Anti-Overflow) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildElectricCard(context)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildLightingCard(context)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildClientLogoCard(context),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildElectricCard(context),
                        const SizedBox(height: 16),
                        _buildLightingCard(context),
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

  /// Carte 1 : Vérification électrique
  Widget _buildElectricCard(BuildContext context) {
    return _buildInspectionCard(
      context: context,
      title: 'Vérification électrique',
      subtitle:
          'Audit complet des installations électriques MT/BT, transformateurs, armoires et mesures de sécurité.',
      badgeText: 'Audit Électrique',
      iconBgColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
      iconColor: AppTheme.primaryBlue,
      icon: Icons.bolt,
      onTap: () {
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

  /// Carte 2 : Vérification éclairage
  Widget _buildLightingCard(BuildContext context) {
    return _buildInspectionCard(
      context: context,
      title: 'Vérification éclairage',
      subtitle:
          'Contrôle de conformité des luminaires, détection des non-conformités et état de fonctionnement.',
      badgeText: 'Module Éclairage',
      iconBgColor: Colors.amber.shade100,
      iconColor: Colors.amber.shade900,
      icon: Icons.lightbulb,
      onTap: () {
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

  /// Carte 3 : Logo du client
  Widget _buildClientLogoCard(BuildContext context) {
    final hasLogo =
        widget.mission.logoClient != null && widget.mission.logoClient!.isNotEmpty;
    return _buildInspectionCard(
      context: context,
      title: 'Logo du client',
      subtitle: hasLogo
          ? 'Identité visuelle configurée. Le logo sera positionné automatiquement sur tous les rapports PDF.'
          : 'Gestion et personnalisation de l\'identité visuelle du client pour tous les rapports.',
      badgeText: 'Identité Visuelle',
      iconBgColor: Colors.indigo.shade100,
      iconColor: Colors.indigo.shade800,
      icon: Icons.branding_watermark_rounded,
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

  /// Constructeur de Carte d'inspection aligné sur AppTheme Card sans overflow
  Widget _buildInspectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.greyDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
