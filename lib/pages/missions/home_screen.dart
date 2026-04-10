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
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  // Variable pour stocker la période sélectionnée pour les stats
  String _statsSelectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadLocalMissions();
  }
  

  void _loadLocalMissions() {
    setState(() {
      _missions = HiveService.getMissionsByMatricule(widget.user.matricule);
      _filteredMissions = _missions;
    });
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
    });
  }

  void _updateSelectedFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
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
      
            // Floating Action Button (seulement sur la page d'accueil)
            if (_currentPageIndex == 0)
              Positioned(
                left: 16,
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
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle mission'),
                  backgroundColor: Colors.green,
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
              onClose: () {
                setState(() {
                  _showSidebar = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Indicateurs de filtre/recherche actifs
        if (_selectedFilter != 'Tous' || _searchQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFilter != 'Tous' 
                      ? 'Filtre: $_selectedFilter (${_filteredMissions.length} résultat(s))'
                      : 'Recherche: "$_searchQuery" (${_filteredMissions.length} résultat(s))',
                    style: TextStyle(fontSize: 14, color: AppTheme.darkBlue),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'Tous';
                      _searchQuery = '';
                      _filteredMissions = _missions;
                    });
                  },
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
                        style: TextStyle(fontSize: 16, color: AppTheme.greyDark),
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
                    return MissionCard(mission: mission, user: widget.user);
                  },
                ),
        ),
      ],
    );
  }
}