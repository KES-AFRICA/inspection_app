// lib/pages/stats/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/stats/components/custom_date_range_dialog.dart';
import 'package:inspec_app/pages/stats/components/mission_summary_card.dart';
import 'package:inspec_app/pages/stats/components/stats_empty_state.dart';
import 'package:inspec_app/pages/stats/mission_analytics_detail_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class StatsScreen extends StatefulWidget {
  final Verificateur user;
  final String initialPeriod;
  final Function(String)? onPeriodChanged;

  const StatsScreen({
    super.key,
    required this.user,
    this.initialPeriod = 'year',
    this.onPeriodChanged,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late String _selectedPeriod;
  String _selectedStatus = 'Tous'; // 'Tous', 'En cours', 'Terminé', 'En attente'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Mission> _allMissions = [];
  List<Mission> _filteredMissions = [];

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _loadMissions();
  }

  @override
  void didUpdateWidget(StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPeriod != widget.initialPeriod) {
      setState(() {
        _selectedPeriod = widget.initialPeriod;
      });
      _loadMissions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMissions() {
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);
    _allMissions = missions;
    _applyFilters();
  }

  void _applyFilters() {
    List<Mission> list = List.from(_allMissions);

    // 1. Filtre par Période
    final now = DateTime.now();
    DateTime? startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        final startWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startWeek.year, startWeek.month, startWeek.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
          endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
        }
        break;
      default:
        startDate = null;
    }

    if (startDate != null) {
      list = list.where((m) {
        final d = m.createdAt;
        return d.isAfter(startDate!.subtract(const Duration(seconds: 1))) &&
            d.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();
    }

    // 2. Filtre par Statut
    if (_selectedStatus != 'Tous') {
      list = list.where((m) => _normalizeStatus(m.status) == _selectedStatus).toList();
    }

    // 3. Filtre par Recherche
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((m) {
        final client = m.nomClient.toLowerCase();
        final site = (m.nomSite ?? '').toLowerCase();
        final adresse = (m.adresseClient ?? '').toLowerCase();
        return client.contains(q) || site.contains(q) || adresse.contains(q);
      }).toList();
    }

    // Tri par date de création descendante
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredMissions = list;
    });
  }

  String _normalizeStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('encour') || lower.contains('en cours')) return 'En cours';
    if (lower.contains('termine') || lower.contains('terminé')) return 'Terminé';
    return 'En attente';
  }

  void _showCustomDateRangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDateRangeDialog(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
        onDateRangeApplied: (start, end) {
          setState(() {
            _customStartDate = start;
            _customEndDate = end;
            _selectedPeriod = 'custom';
          });
          _applyFilters();
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedPeriod = 'year';
      _selectedStatus = 'Tous';
      _searchQuery = '';
      _searchController.clear();
      _customStartDate = null;
      _customEndDate = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100,
      body: Column(
        children: [
          // 1. En-tête de Filtrage & Recherche (Niveau 1)
          _buildHeaderFiltersBar(isDarkMode),

          // 2. Liste des cartes de missions analytiques
          Expanded(
            child: _filteredMissions.isEmpty
                ? StatsEmptyState(onResetPeriod: _resetFilters)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredMissions.length,
                    itemBuilder: (context, index) {
                      final mission = _filteredMissions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MissionSummaryCard(
                          mission: mission,
                          isDarkMode: isDarkMode,
                          onTap: () {
                            // Navigation vers le Niveau 2 : Dashboard analytique dédié à cette mission
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionAnalyticsDetailScreen(mission: mission),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFiltersBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : Barre de Recherche Client / Site
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une mission (client, site)...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade600),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton sélecteur de période
              IconButton(
                icon: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryBlue),
                tooltip: 'Période',
                onPressed: () => _showPeriodBottomSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Ligne 2 : Chips de Statut ('Tous', 'En cours', 'Terminé', 'En attente') & Nombre de résultats
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatusChip('Tous'),
                      const SizedBox(width: 6),
                      _buildStatusChip('En cours'),
                      const SizedBox(width: 6),
                      _buildStatusChip('Terminé'),
                      const SizedBox(width: 6),
                      _buildStatusChip('En attente'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_filteredMissions.length} mission(s)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade400 : AppTheme.darkBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedStatus == label;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = label;
        });
        _applyFilters();
      },
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showPeriodBottomSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryBlue),
              title: const Text('Aujourd\'hui'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedPeriod = 'today');
                _applyFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded, color: AppTheme.primaryBlue),
              title: const Text('Cette semaine'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedPeriod = 'week');
                _applyFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month_rounded, color: AppTheme.primaryBlue),
              title: const Text('Ce mois'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedPeriod = 'month');
                _applyFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: AppTheme.primaryBlue),
              title: const Text('Cette année'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedPeriod = 'year');
                _applyFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded, color: AppTheme.primaryBlue),
              title: const Text('Période personnalisée...'),
              onTap: () {
                Navigator.pop(ctx);
                _showCustomDateRangeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}