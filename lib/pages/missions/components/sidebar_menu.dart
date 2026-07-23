import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/backup/backup_screen.dart';
import 'package:inspec_app/pages/login_screen.dart';
import 'package:inspec_app/pages/trash/corbeille_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/trash_service.dart';

class SidebarMenu extends StatelessWidget {
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
            const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de la session "${user.nom}" ?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final trashCount = TrashService.getTrashCount();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: showSidebar ? 0 : -290,
      top: 0,
      bottom: 0,
      width: 290,
      child: Material(
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: Container(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: Column(
            children: [
              // 1. HEADER UTILISATEUR IMMERSIF
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: Colors.white,
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
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Matricule : ${user.matricule}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
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

              // 2. LISTE DES MENUS DE NAVIGATION
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Section GÉNÉRAL
                    _buildSectionHeader('GÉNÉRAL', isDarkMode),
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

                    // Section DONNÉES & SÉCURITÉ
                    _buildSectionHeader('DONNÉES & SÉCURITÉ', isDarkMode),
                    _buildNavigationTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Corbeille Sécurisée',
                      isSelected: false,
                      badgeCount: trashCount,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CorbeilleScreen(
                              onRefreshParent: onRefreshMissions,
                            ),
                          ),
                        ).then((_) => onRefreshMissions?.call());
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Import / Export',
                      isSelected: false,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        onClose();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BackupScreen(user: user),
                          ),
                        ).then((_) => onRefreshMissions?.call());
                      },
                    ),
                  ],
                ),
              ),

              // 3. PIED DE PAGE : DÉCONNEXION
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
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
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
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