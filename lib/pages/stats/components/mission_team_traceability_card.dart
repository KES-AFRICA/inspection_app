// lib/pages/stats/components/mission_team_traceability_card.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';

class MissionTeamTraceabilityCard extends StatelessWidget {
  final Mission mission;
  final bool isDarkMode;

  const MissionTeamTraceabilityCard({
    super.key,
    required this.mission,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final verificateurs = mission.verificateurs ?? [];
    final accompagnateurs = mission.accompagnateurs ?? [];
    final dgResponsable = mission.dgResponsable;

    final hasVerificateurs = verificateurs.isNotEmpty;
    final hasAccompagnateurs = accompagnateurs.isNotEmpty;
    final hasDg = dgResponsable != null && dgResponsable.trim().isNotEmpty;

    if (!hasVerificateurs && !hasAccompagnateurs && !hasDg) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_rounded, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Personnes ayant travaillé sur cette mission',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun intervenant spécifique répertorié sur la fiche mission.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.engineering_rounded, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Personnes ayant travaillé sur cette mission',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Traçabilité certifiée des intervenants, vérificateurs et accompagnateurs',
            style: TextStyle(
              fontSize: 11.5,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Directeur Général / Responsable Technique
          if (hasDg) ...[
            _buildPersonTile(
              name: dgResponsable,
              role: 'Directeur / Responsable Technique',
              icon: Icons.verified_user_rounded,
              accentColor: const Color(0xFF7C3AED),
              badgeText: 'Responsable',
            ),
            const SizedBox(height: 8),
          ],

          // 2. Vérificateurs Agréés
          if (hasVerificateurs) ...[
            ...verificateurs.map((v) {
              final nom = v['nom'] ?? v['name'] ?? 'Vérificateur Agréé';
              final prenom = v['prenom'] ?? '';
              final fullName = '$prenom $nom'.trim();
              final matricule = v['matricule'] ?? '';
              final role = v['role'] ?? 'Vérificateur Agréé KES';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPersonTile(
                  name: fullName.isEmpty ? 'Vérificateur Agréé' : fullName,
                  role: role,
                  matricule: matricule,
                  icon: Icons.shield_rounded,
                  accentColor: AppTheme.primaryBlue,
                  badgeText: 'Vérificateur',
                ),
              );
            }),
          ],

          // 3. Accompagnateurs
          if (hasAccompagnateurs) ...[
            ...accompagnateurs.map((acc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPersonTile(
                  name: acc,
                  role: 'Accompagnateur Client / Site',
                  icon: Icons.person_pin_rounded,
                  accentColor: const Color(0xFF059669),
                  badgeText: 'Accompagnateur',
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonTile({
    required String name,
    required String role,
    String? matricule,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (matricule != null && matricule.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Matricule : $matricule',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
