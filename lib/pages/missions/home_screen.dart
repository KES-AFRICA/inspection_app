import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/create_mission_screen.dart';
import 'package:inspec_app/pages/stats/stats_screen.dart';
import 'package:inspec_app/pages/missions/components/filter_dialog.dart';
import 'package:inspec_app/pages/missions/components/home_app_bar.dart';
import 'package:inspec_app/pages/missions/components/mission_card.dart';
import 'package:inspec_app/pages/missions/components/search_dialog.dart';
import 'package:inspec_app/pages/missions/components/sidebar_menu.dart';
import 'package:inspec_app/pages/missions/components/sort_dialog.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Écran principal "Mes Missions"
/// Refonte visuelle complète avec bannière KPI d'accueil, filtres dynamiques,
/// recherche rapide et intégration du menu d'édition des missions.
class HomeScreen extends StatefulWidget {
  final Verificateur user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Mission> _missions = [];
  List<Mission> _filteredMissions = [];
  bool _showSidebar = false;
  int _currentPageIndex = 0;

  // Variables pour la recherche et le filtre
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  // Variable pour stocker la période sélectionnée pour les stats
  String _statsSelectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadLocalMissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('encour') || s.contains('en cours')) return 'En cours';
    if (s.contains('termine') || s.contains('terminé')) return 'Terminé';
    if (s.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _applyFilters() {
    List<Mission> result = List.from(_missions);

    // Filtrer par statut sélectionné (via les chips horizontaux)
    if (_selectedFilter != 'Tous') {
      result = result.where((m) => _normalizeStatus(m.status) == _selectedFilter).toList();
    }

    // Filtrer par recherche textuelle (via le TextField)
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((m) {
        final client = m.nomClient.toLowerCase();
        final site = (m.nomSite ?? '').toLowerCase();
        final adresse = (m.adresseClient ?? '').toLowerCase();
        return client.contains(query) ||
            site.contains(query) ||
            adresse.contains(query);
      }).toList();
    }

    // Tri par défaut : du plus récent au plus ancien
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredMissions = result;
    });
  }

  void _loadLocalMissions() {
    setState(() {
      _missions = HiveService.getMissionsByMatricule(widget.user.matricule);
    });
    _applyFilters();
  }

  void _onNavigationItemSelected(int index) {
    setState(() {
      _currentPageIndex = index;
      _showSidebar = false;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
    _applyFilters();
  }

  void _updateSelectedFilter(String filter) {
    String finalFilter = filter;
    if (filter.startsWith('Par statut: ')) {
      finalFilter = filter.replaceAll('Par statut: ', '');
    }
    setState(() {
      _selectedFilter = finalFilter;
    });
    _applyFilters();
  }

  void _updateFilteredMissions(List<Mission> missions) {
    setState(() {
      _filteredMissions = missions;
    });
  }

  void _handleStatsPeriodChange(String period) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _statsSelectedPeriod = period;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Contenu principal
            Column(
              children: [
                // AppBar personnalisé
                HomeAppBar(
                  currentPageIndex: _currentPageIndex,
                  onMenuPressed: () {
                    setState(() {
                      _showSidebar = !_showSidebar;
                    });
                  },
                  onFilterPressed: () => showDialog(
                    context: context,
                    builder: (context) => FilterDialog(
                      selectedFilter: _selectedFilter,
                      missions: _missions,
                      onFilterApplied: _updateFilteredMissions,
                      onFilterSelected: _updateSelectedFilter,
                    ),
                  ),
                  onSearchPressed: () => showDialog(
                    context: context,
                    builder: (context) => SearchDialog(
                      searchQuery: _searchQuery,
                      missions: _missions,
                      onSearchApplied: _updateFilteredMissions,
                      onSearchQueryChanged: _updateSearchQuery,
                    ),
                  ),
                  onSortPressed: () => showDialog(
                    context: context,
                    builder: (context) => SortDialog(
                      selectedFilter: _selectedFilter,
                      missions: _missions,
                      onFilterApplied: _updateFilteredMissions,
                      onFilterSelected: _updateSelectedFilter,
                    ),
                  ),
                  onStatsPeriodSelected: _handleStatsPeriodChange,
                ),

                // Corps de l'application
                Expanded(
                  child: _currentPageIndex == 0
                      ? _buildHomeContent(isDarkMode)
                      : StatsScreen(
                          user: widget.user,
                          initialPeriod: _statsSelectedPeriod,
                          onPeriodChanged: _handleStatsPeriodChange,
                        ),
                ),
              ],
            ),

            // Floating Action Button
            if (_currentPageIndex == 0)
              Positioned(
                right: 20,
                bottom: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateMissionScreen(currentUser: widget.user),
                        ),
                      );
                      if (result == true) {
                        _loadLocalMissions();
                      }
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    label: const Text(
                      'Nouvelle mission',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

            // Overlay flou quand le sidebar est ouvert
            if (_showSidebar)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showSidebar = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),

            // Sidebar menu
            SidebarMenu(
              showSidebar: _showSidebar,
              user: widget.user,
              filteredMissions: _filteredMissions,
              selectedFilter: _selectedFilter,
              searchQuery: _searchQuery,
              currentPageIndex: _currentPageIndex,
              onNavigationItemSelected: _onNavigationItemSelected,
              onClose: () => setState(() => _showSidebar = false),
              onRefreshMissions: _loadLocalMissions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(bool isDarkMode) {
    // Calcul des KPIs
    final totalMissions = _missions.length;
    final enCoursCount = _missions.where((m) => _normalizeStatus(m.status) == 'En cours').length;
    final termineesCount = _missions.where((m) => _normalizeStatus(m.status) == 'Terminé').length;
    final enAttenteCount = _missions.where((m) => _normalizeStatus(m.status) == 'En attente').length;

    return Column(
      children: [
        // 1. Bannière d'accueil & KPIs
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message de bienvenue avec avatar utilisateur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${widget.user.prenom}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vérificateur agréé KES',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          widget.user.matricule,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cartes KPI interactives
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Total',
                      count: totalMissions,
                      color: AppTheme.primaryBlue,
                      bgColor: const Color(0xFFEFF6FF),
                      isSelected: _selectedFilter == 'Tous',
                      onTap: () => _updateSelectedFilter('Tous'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'En cours',
                      count: enCoursCount,
                      color: AppTheme.primaryBlue,
                      bgColor: const Color(0xFFDBEAFE),
                      isSelected: _selectedFilter == 'En cours',
                      onTap: () => _updateSelectedFilter('En cours'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Attente',
                      count: enAttenteCount,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      isSelected: _selectedFilter == 'En attente',
                      onTap: () => _updateSelectedFilter('En attente'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'Terminées',
                      count: termineesCount,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFDCFCE7),
                      isSelected: _selectedFilter == 'Terminé',
                      onTap: () => _updateSelectedFilter('Terminé'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barre de recherche & Bouton de tri
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _updateSearchQuery,
                        style: TextStyle(fontSize: 13.5, color: isDarkMode ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Rechercher client, site, adresse...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
                                  onPressed: () {
                                    _searchController.clear();
                                    _updateSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton Trier
                  _buildQuickActionButton(
                    icon: Icons.swap_vert_rounded,
                    tooltip: 'Trier',
                    isDarkMode: isDarkMode,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => SortDialog(
                        selectedFilter: _selectedFilter,
                        missions: _missions,
                        onFilterApplied: _updateFilteredMissions,
                        onFilterSelected: _updateSelectedFilter,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Compteur de résultats s'il y a un filtre actif
        if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  '${_filteredMissions.length} mission(s) trouvée(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade300 : AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'Tous';
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Liste des missions
        Expanded(
          child: _filteredMissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_late_rounded,
                          size: 54,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _missions.isEmpty ? 'Aucune mission disponible' : 'Aucun résultat trouvé',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : AppTheme.greyDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _missions.isEmpty
                            ? 'Créez une nouvelle mission pour commencer'
                            : 'Essayez de modifier vos critères de recherche',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredMissions.length,
                  itemBuilder: (context, index) {
                    final mission = _filteredMissions[index];
                    return MissionCard(
                      mission: mission,
                      user: widget.user,
                      onDeleted: _loadLocalMissions,
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Widget Carte KPI d'accueil
  Widget _buildKpiCard({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDarkMode,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
      ),
    );
  }
}