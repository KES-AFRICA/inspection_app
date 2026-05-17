import 'package:flutter/material.dart';
import 'package:inspec_app/pages/backup/backup_screen.dart';
import '../../../models/verificateur.dart';
import '../../../models/mission.dart';
import '../../../services/hive_service.dart';
import '../../../constants/app_theme.dart';
import '../../login_screen.dart';

class SidebarMenu extends StatelessWidget {
  final bool showSidebar;
  final Verificateur user;
  final List<Mission> filteredMissions;
  final String selectedFilter;
  final String searchQuery;
  final int currentPageIndex;
  final Function(int) onNavigationItemSelected;
  final VoidCallback onClose;

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
  });

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
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
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: showSidebar ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: Material(
        elevation: 16,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header du sidebar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Matricule: ${user.matricule}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedFilter != 'Tous' || searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedFilter != 'Tous'
                              ? 'Filtre: $selectedFilter'
                              : 'Recherche active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Navigation items
              const SizedBox(height: 20),
              _buildNavigationItem(
                icon: Icons.home_outlined,
                title: 'Accueil',
                isSelected: currentPageIndex == 0,
                onTap: () => onNavigationItemSelected(0),
              ),
              _buildNavigationItem(
                icon: Icons.bar_chart_outlined,
                title: 'Statistiques',
                isSelected: currentPageIndex == 1,
                onTap: () => onNavigationItemSelected(1),
              ),

              // Espace vide
              Expanded(child: Container()),

              // ── Bouton Sauvegarde & Restauration ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    onClose();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => BackupScreen(user: user),
                    ));
                  },
                  icon: const Icon(Icons.cloud_upload_outlined,
                      color: AppTheme.primaryBlue, size: 18),
                  label: const Text('Sauvegarde & Restauration',
                      style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              // Bouton de déconnexion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}