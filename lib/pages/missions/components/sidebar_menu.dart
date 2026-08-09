// lib/pages/missions/components/sidebar_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/features/backup/presentation/screens/sauvegardes_screen.dart';
import 'package:inspec_app/features/backup/presentation/providers/backup_providers.dart';
import 'package:inspec_app/features/backup/data/services/backup_orchestrator.dart';
import 'package:inspec_app/features/backup/domain/models/mission_sync_state.dart';
import 'package:inspec_app/pages/backup/backup_screen.dart';
import 'package:inspec_app/pages/login_screen.dart';
import 'package:inspec_app/pages/trash/corbeille_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/trash_service.dart';

class SidebarMenu extends ConsumerWidget {
  final bool showSidebar;
  final Verificateur user;
  final List<Mission> filteredMissions;
  final String selectedFilter;
  final String searchQuery;
  final int currentPageIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onClose;
  final VoidCallback? onRefreshMissions;

  const SidebarMenu({
    super.key,
    required this.showSidebar,
    required this.user,
    required this.filteredMissions,
    required this.selectedFilter,
    required this.searchQuery,
    required this.currentPageIndex,
    required this.onNavigationItemSelected,
    required this.onClose,
    this.onRefreshMissions,
  });

  Future<void> _logout(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirmer la déconnexion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de votre compte inspecteur (${user.prenom} ${user.nom}) ?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final trashCount = TrashService.getTrashCount();

    // Ingestion de l'état réactif de sauvegarde pour le badge dynamique
    final syncStates = ref.watch(backupSyncNotifierProvider);
    final orchestratorState = ref.watch(backupOrchestratorStateProvider).value ?? const BackupOrchestratorState();
    final isGlobalSyncing = orchestratorState.isActive;
    final hasPendingModifications = syncStates.values.any((s) => s.status == SyncStatus.localModifications);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: showSidebar ? 0 : -295,
      top: 0,
      bottom: 0,
      width: 295,
      child: Material(
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        child: Container(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: Column(
            children: [
              // 1. EN-TÊTE UTILISATEUR IMMERSIF ET ÉLÉGANT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              '${user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : ""}${user.nom.isNotEmpty ? user.nom[0].toUpperCase() : ""}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.prenom} ${user.nom}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.badge_rounded, size: 12, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Matricule : ${user.matricule}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (selectedFilter != 'Tous' || searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_alt_rounded, size: 12, color: Color(0xFF93C5FD)),
                            const SizedBox(width: 6),
                            Text(
                              selectedFilter != 'Tous' ? 'Filtre : $selectedFilter' : 'Recherche active',
                              style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. LISTE DES MENUS DE NAVIGATION HIÉRARCHISÉS
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Section 1 : NAVIGATION PRINCIPALE
                    _buildSectionHeader('NAVIGATION PRINCIPALE', isDarkMode),
                    _buildNavigationTile(
                      icon: Icons.space_dashboard_rounded,
                      title: 'Accueil Missions',
                      isSelected: currentPageIndex == 0,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        onNavigationItemSelected(0);
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.insights_rounded,
                      title: 'Statistiques & KPI',
                      isSelected: currentPageIndex == 1,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        onNavigationItemSelected(1);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Section 2 : SYNCHRONISATION & CLOUD
                    _buildSectionHeader('SYNCHRONISATION & CLOUD', isDarkMode),
                    _buildNavigationTile(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Sauvegardes Cloud',
                      isSelected: currentPageIndex == 2,
                      isDarkMode: isDarkMode,
                      statusBadge: isGlobalSyncing
                          ? _buildStatusBadge('EN COURS', const Color(0xFFDBEAFE), const Color(0xFF1E40AF), Icons.sync_rounded)
                          : hasPendingModifications
                              ? _buildStatusBadge('MODIFIÉE', const Color(0xFFFEF3C7), const Color(0xFF92400E), Icons.edit_note_rounded)
                              : _buildStatusBadge('À JOUR', const Color(0xFFD1FAE5), const Color(0xFF065F46), Icons.check_circle_rounded),
                      onTap: () {
                        onClose();
                        onNavigationItemSelected(2);
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.folder_zip_rounded,
                      title: 'Import / Export',
                      isSelected: currentPageIndex == 3,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        onNavigationItemSelected(3);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Section 3 : STOCKAGE & CORBEILLE (En dernier)
                    _buildSectionHeader('STOCKAGE', isDarkMode),
                    _buildNavigationTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Corbeille',
                      isSelected: currentPageIndex == 4,
                      badgeCount: trashCount,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        onNavigationItemSelected(4);
                      },
                    ),
                  ],
                ),
              ),

              // 3. PIED DE PAGE : DÉCONNEXION (Séparée et sécurisée)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    label: const Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.35), width: 1.5),
                      backgroundColor: Colors.red.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
    Widget? statusBadge,
    int? badgeCount,
  }) {
    final activeBg = isDarkMode ? AppTheme.primaryBlue.withValues(alpha: 0.2) : const Color(0xFFEFF6FF);
    final activeTextColor = isDarkMode ? const Color(0xFF60A5FA) : AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? activeTextColor
              : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? activeTextColor
                : (isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusBadge != null) statusBadge,
            if (badgeCount != null && badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 18, color: activeTextColor),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}