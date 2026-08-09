import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/components/sort_dialog.dart';
import 'package:inspec_app/pages/missions/create_mission_screen.dart';
import 'package:inspec_app/pages/stats/stats_screen.dart';
import 'package:inspec_app/pages/missions/components/filter_dialog.dart';
import 'package:inspec_app/pages/missions/components/home_app_bar.dart';
import 'package:inspec_app/pages/missions/components/mission_card.dart';
import 'package:inspec_app/pages/missions/components/search_dialog.dart';
import 'package:inspec_app/pages/missions/components/sidebar_menu.dart';
import 'package:inspec_app/features/backup/presentation/screens/sauvegardes_screen.dart';
import 'package:inspec_app/pages/backup/backup_screen.dart';
import 'package:inspec_app/pages/trash/corbeille_screen.dart';
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
  String _statsSelectedPeriod = 'year';

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
    if (index == 0) {
      _loadLocalMissions();
    }
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

  Widget _buildCurrentPageContent(bool isDarkMode) {
    switch (_currentPageIndex) {
      case 0:
        return _buildHomeContent(isDarkMode);
      case 1:
        return StatsScreen(
          user: widget.user,
          initialPeriod: _statsSelectedPeriod,
          onPeriodChanged: _handleStatsPeriodChange,
        );
      case 2:
        return const SauvegardesScreen();
      case 3:
        return BackupScreen(user: widget.user);
      case 4:
        return CorbeilleScreen(onRefreshParent: _loadLocalMissions);
      default:
        return _buildHomeContent(isDarkMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentPageIndex == 0 && !_showSidebar,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showSidebar) {
          setState(() {
            _showSidebar = false;
          });
        } else if (_currentPageIndex != 0) {
          setState(() {
            _currentPageIndex = 0;
          });
        }
      },
      child: GestureDetector(
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
                    child: _buildCurrentPageContent(isDarkMode),
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
    ),
  );
}

  Widget _buildHomeContent(bool isDarkMode) {
    // Calcul des KPIs
    final totalMissions = _missions.length;
    final enCoursCount = _missions.where((m) => _normalizeStatus(m.status) == 'En cours').length;
    final termineesCount = _missions.where((m) => _normalizeStatus(m.status) == 'Terminé').length;
    final enAttenteCount = _missions.where((m) => _normalizeStatus(m.status) == 'En attente').length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // 1. Message de bienvenue d'accueil (Non pinned)
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
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
          ),
        ),

        // 2. Header Pinned & Collapsible (Cartes KPI qui disparaissent au scroll -> Barre recherche + filtre compacte fixe)
        SliverPersistentHeader(
          pinned: true,
          delegate: _HomeFilterHeaderSliverDelegate(
            isDarkMode: isDarkMode,
            selectedFilter: _selectedFilter,
            searchQuery: _searchQuery,
            searchController: _searchController,
            totalMissions: totalMissions,
            enCoursCount: enCoursCount,
            enAttenteCount: enAttenteCount,
            termineesCount: termineesCount,
            onFilterSelected: (filter) => _updateSelectedFilter(filter),
            onSearchChanged: (query) => _updateSearchQuery(query),
            onFilterPressed: () => showDialog(
              context: context,
              builder: (context) => FilterDialog(
                selectedFilter: _selectedFilter,
                missions: _missions,
                onFilterApplied: _updateFilteredMissions,
                onFilterSelected: _updateSelectedFilter,
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
          ),
        ),

        // 3. Compteur de résultats s'il y a un filtre actif
        if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
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
          ),

        // 4. Liste des cartes de missions
        if (_filteredMissions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
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
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mission = _filteredMissions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MissionCard(
                      mission: mission,
                      user: widget.user,
                      onDeleted: _loadLocalMissions,
                    ),
                  );
                },
                childCount: _filteredMissions.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIVER DELEGATE POUR LES CARTES KPI ET FILTRES D'ACCUEIL
// ─────────────────────────────────────────────────────────────

class _HomeFilterHeaderSliverDelegate extends SliverPersistentHeaderDelegate {
  final bool isDarkMode;
  final String selectedFilter;
  final String searchQuery;
  final TextEditingController searchController;
  final int totalMissions;
  final int enCoursCount;
  final int enAttenteCount;
  final int termineesCount;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;

  _HomeFilterHeaderSliverDelegate({
    required this.isDarkMode,
    required this.selectedFilter,
    required this.searchQuery,
    required this.searchController,
    required this.totalMissions,
    required this.enCoursCount,
    required this.enAttenteCount,
    required this.termineesCount,
    required this.onFilterSelected,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onSortPressed,
  });

  @override
  double get minExtent => 64.0;

  @override
  double get maxExtent => 165.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkPercent = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shrinkPercent > 0.8 ? (isDarkMode ? 0.3 : 0.06) : 0.03),
            blurRadius: shrinkPercent > 0.8 ? 8 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Mode Déplié : Cartes KPI + Barre de Recherche & Bouton Trier
          Opacity(
            opacity: (1.0 - shrinkPercent * 2.2).clamp(0.0, 1.0),
            child: OverflowBox(
              minHeight: maxExtent,
              maxHeight: maxExtent,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  // Cartes KPI interactives
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiChip(
                          title: 'Total',
                          count: totalMissions,
                          color: const Color(0xFF475569),
                          bgColor: const Color(0xFFF1F5F9),
                          isSelected: selectedFilter == 'Tous',
                          onTap: () => onFilterSelected('Tous'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiChip(
                          title: 'En cours',
                          count: enCoursCount,
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          isSelected: selectedFilter == 'En cours',
                          onTap: () => onFilterSelected('En cours'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiChip(
                          title: 'Attente',
                          count: enAttenteCount,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          isSelected: selectedFilter == 'En attente',
                          onTap: () => onFilterSelected('En attente'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiChip(
                          title: 'Terminées',
                          count: termineesCount,
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                          isSelected: selectedFilter == 'Terminé',
                          onTap: () => onFilterSelected('Terminé'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barre de recherche & Bouton Trier
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchBar(isCompact: false),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickIconButton(
                        icon: Icons.swap_vert_rounded,
                        tooltip: 'Trier',
                        onPressed: onSortPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Mode Replié : Recherche Compacte Pinned + Icône Filtre avec Badge + Icône Trier
          if (shrinkPercent > 0.45)
            Opacity(
              opacity: ((shrinkPercent - 0.45) / 0.55).clamp(0.0, 1.0),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSearchBar(isCompact: true),
                    ),
                    const SizedBox(width: 8),

                    // Bouton Filtre avec badge réactif si filtre actif
                    Stack(
                      children: [
                        _buildQuickIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Filtrer',
                          onPressed: onFilterPressed,
                          isActive: selectedFilter != 'Tous',
                        ),
                        if (selectedFilter != 'Tous')
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),

                    // Bouton Trier
                    _buildQuickIconButton(
                      icon: Icons.swap_vert_rounded,
                      tooltip: 'Trier',
                      onPressed: onSortPressed,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildSearchBar({required bool isCompact}) {
    return Container(
      height: isCompact ? 38 : 42,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: isCompact ? 'Rechercher...' : 'Rechercher client, site, adresse...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryBlue,
            size: isCompact ? 18 : 20,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade600),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildQuickIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.primaryBlue : (isDarkMode ? Colors.white70 : AppTheme.darkBlue),
            size: 19,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeFilterHeaderSliverDelegate oldDelegate) {
    return oldDelegate.selectedFilter != selectedFilter ||
        oldDelegate.searchQuery != searchQuery ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.totalMissions != totalMissions ||
        oldDelegate.enCoursCount != enCoursCount ||
        oldDelegate.enAttenteCount != enAttenteCount ||
        oldDelegate.termineesCount != termineesCount;
  }
}