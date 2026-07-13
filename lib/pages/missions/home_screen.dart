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

  // IMPLÉMENTATION COMPLÈTE DE LA GESTION DES PÉRIODES STATS
  void _handleStatsPeriodChange(String period) {
    print('🔄 Changement de période pour les stats: $period');
    
    // Utiliser un délai pour éviter les appels pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _statsSelectedPeriod = period;
        });

        // Sauvegarder la préférence
        _saveStatsPeriodPreference(period);
      }
    });
  }

  void _saveStatsPeriodPreference(String period) {
    // Sauvegarder dans les préférences locales
    print('💾 Sauvegarde préférence période: $period');
  
  // Exemple avec Hive si vous avez un service de préférences :
  // HiveService.saveStatsPeriodPreference(period);
}

  Widget _buildQuickActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    final themeColor = value == 'Tous'
        ? AppTheme.primaryBlue
        : value == 'En attente'
            ? Colors.orange
            : value == 'En cours'
                ? AppTheme.primaryBlue
                : Colors.green;

    return InkWell(
      onTap: () => _updateSelectedFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _currentPageIndex == 0
                        ? _buildHomeContent()
                        : StatsScreen(
                            user: widget.user,
                            initialPeriod: _statsSelectedPeriod,
                            onPeriodChanged: _handleStatsPeriodChange, 
                          ),
                  ),
                ),
              ],
            ),
      
            // Floating Action Button (repositionné à droite)
            if (_currentPageIndex == 0)
              Positioned(
                right: 16,
                bottom: 16,
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
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nouvelle mission',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
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
                  color: Colors.black.withOpacity(0.5),
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

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Panneau de recherche & filtres premium
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barre de recherche + bouton tri rapide
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un client, site...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.primaryBlue.withOpacity(0.7),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
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
                    icon: Icons.swap_vert,
                    tooltip: 'Trier',
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
              const SizedBox(height: 12),
              // Chips de filtrage horizontaux
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('Tous', 'Toutes'),
                    const SizedBox(width: 8),
                    _buildFilterChip('En attente', 'En attente'),
                    const SizedBox(width: 8),
                    _buildFilterChip('En cours', 'En cours'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terminé', 'Terminées'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Nombre de résultats s'il y a un filtre actif
        if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  '${_filteredMissions.length} résultat(s) trouvé(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
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
                    style: TextStyle(fontSize: 12, color: Colors.red),
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
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: AppTheme.greyDark.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _missions.isEmpty ? 'Aucune mission disponible' : 'Aucun résultat trouvé',
                        style: TextStyle(fontSize: 16, color: AppTheme.greyDark, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _missions.isEmpty 
                          ? 'Appuyez sur le bouton pour synchroniser'
                          : 'Modifiez vos critères de recherche',
                        style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
}