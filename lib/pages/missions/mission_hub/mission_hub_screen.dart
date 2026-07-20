import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_detail_screen.dart';
import 'package:inspec_app/pages/missions/lighting/lighting_mission_detail_screen.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.mission.nomClient,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.mission.nomSite ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1B365D),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête d'information de la mission ──
              _buildMissionHeaderCard(isDark),

              const SizedBox(height: 28),

              Text(
                'VOLETS D\'INSPECTION DISPONIBLES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF5A6B82),
                ),
              ),
              const SizedBox(height: 14),

              // ── Les 2 Grandes Cartes de Volets (Responsive Layout) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 700) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildElectricCard(context, isDark)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildLightingCard(context, isDark)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildElectricCard(context, isDark),
                        const SizedBox(height: 20),
                        _buildLightingCard(context, isDark),
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

  /// Card Header de la Mission
  Widget _buildMissionHeaderCard(bool isDark) {
    final nature = widget.mission.natureMission;
    final inst = widget.mission.installation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3854) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B365D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Color(0xFF1B365D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mission.nomClient,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B365D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Site : ${widget.mission.nomSite ?? ""}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.mission.status ?? 'En cours'),
            ],
          ),
          if ((nature != null && nature.isNotEmpty) ||
              (inst != null && inst.isNotEmpty)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                if (nature != null && nature.isNotEmpty) ...[
                  Icon(Icons.assignment_outlined,
                      size: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    nature,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (inst != null && inst.isNotEmpty) ...[
                  Icon(Icons.power_outlined,
                      size: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Installation : $inst',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Badge de statut de mission
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'terminee':
      case 'terminée':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Terminée';
        break;
      case 'en_cours':
      case 'en cours':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = 'En cours';
        break;
      default:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF455A64);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  /// Carte 1 : Vérification électrique
  Widget _buildElectricCard(BuildContext context, bool isDark) {
    return _buildInspectionCard(
      context: context,
      isDark: isDark,
      title: 'Vérification électrique',
      subtitle:
          'Audit complet des installations électriques MT/BT, transformateurs, armoires et mesures de sécurité.',
      badgeText: 'Audit Électrique',
      badgeColor: const Color(0xFF1B365D),
      gradientColors: isDark
          ? [const Color(0xFF1E2A3A), const Color(0xFF17202D)]
          : [const Color(0xFFEBF3FC), const Color(0xFFDCE8F7)],
      icon: Icons.bolt_rounded,
      secondaryIcon: Icons.electrical_services_rounded,
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
  Widget _buildLightingCard(BuildContext context, bool isDark) {
    return _buildInspectionCard(
      context: context,
      isDark: isDark,
      title: 'Vérification éclairage',
      subtitle:
          'Contrôle de conformité des luminaires, détection des non-conformités et état de fonctionnement.',
      badgeText: 'Nouveau Module',
      badgeColor: const Color(0xFFE65100),
      gradientColors: isDark
          ? [const Color(0xFF2C2219), const Color(0xFF231911)]
          : [const Color(0xFFFFF4E6), const Color(0xFFFFE8CC)],
      icon: Icons.lightbulb_rounded,
      secondaryIcon: Icons.wb_incandescent_rounded,
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

  /// Constructeur de Carte d'inspection
  Widget _buildInspectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required List<Color> gradientColors,
    required IconData icon,
    required IconData secondaryIcon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Zone Illustration Supérieure ──
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Stack(
                  children: [
                    // Arrière-plan décoratif
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        secondaryIcon,
                        size: 140,
                        color: badgeColor.withOpacity(0.08),
                      ),
                    ),
                    // Badge supérieur
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Central Icon Illustration
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: 42,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Zone d'Information et Titre Inférieure ──
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
