import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/stats/components/custom_date_range_dialog.dart';
import 'package:inspec_app/pages/stats/components/stats_app_bar.dart';
import 'package:inspec_app/pages/stats/components/stats_empty_state.dart';
import 'package:inspec_app/pages/stats/components/stats_grid.dart';
import 'package:inspec_app/pages/stats/components/stats_recent_missions.dart';
import 'package:inspec_app/pages/stats/components/stats_status_distribution.dart';
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
      print('📊 Mise à jour de la période: ${widget.initialPeriod}');
      setState(() {
        _selectedPeriod = widget.initialPeriod;
      });
      _loadMissions();
    }
  }

  void _loadMissions() {
    print('📥 Chargement des missions pour la période: $_selectedPeriod');
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);
    _applyPeriodFilter(missions, _selectedPeriod);
  }

  void _applyPeriodFilter(List<Mission> missions, String period) {
    print('🔍 Application du filtre de période: $period');
    
    if (period == 'custom') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomDateRangeDialog();
      });
      return;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, 1, 1);
    }

    final filtered = missions.where((mission) {
      final missionDate = mission.createdAt;
      return missionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    setState(() {
      _selectedPeriod = period;
      _filteredMissions = filtered;
    });

    widget.onPeriodChanged?.call(period);
  }

  void _showCustomDateRangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDateRangeDialog(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
        onDateRangeApplied: _applyCustomDateRange,
      ),
    );
  }

  void _applyCustomDateRange(DateTime startDate, DateTime endDate) {
    
    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate;
      _selectedPeriod = 'custom';
    });
    
    final missions = HiveService.getMissionsByMatricule(widget.user.matricule);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    final filtered = missions.where((mission) {
      final missionDate = mission.createdAt;
      return missionDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
             missionDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
    
    setState(() {
      _filteredMissions = filtered;
    });
    
    widget.onPeriodChanged?.call('custom');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Période: ${_formatDate(startDate)} - ${_formatDate(endDate)} (${filtered.length} missions)',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}';
        }
        return 'Période personnalisée';
      default:
        return 'Ce mois';
    }
  }

  // Méthodes de calcul des statistiques
  int _getTotalMissions() => _filteredMissions.length;
  
  int _getMissionsByStatus(String status) {
    return _filteredMissions.where((mission) => _normalizeStatus(mission.status) == status).length;
  }
  
  String _normalizeStatus(String status) {
    final lowerStatus = status.toLowerCase().trim();
    if (lowerStatus.contains('encour') || lowerStatus.contains('en cours')) return 'En cours';
    if (lowerStatus.contains('termine') || lowerStatus.contains('terminé')) return 'Terminé';
    if (lowerStatus.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _resetToDefaultPeriod() {
    setState(() {
      _selectedPeriod = 'month';
      _customStartDate = null;
      _customEndDate = null;
    });
    _loadMissions();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          StatsAppBar(
            selectedPeriod: _selectedPeriod,
            periodLabel: _getPeriodLabel(),
            isCustomPeriod: _selectedPeriod == 'custom',
            onResetPeriod: _resetToDefaultPeriod,
            onPeriodSelected: (period) => _applyPeriodFilter(
              HiveService.getMissionsByMatricule(widget.user.matricule),
              period,
            ),
          ),

          Expanded(
            child: _filteredMissions.isEmpty
                ? StatsEmptyState(onResetPeriod: _resetToDefaultPeriod)
                : ListView(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 0),
                    children: [
                      StatsGrid(
                        totalMissions: _getTotalMissions(),
                        pendingMissions: _getMissionsByStatus('En attente'),
                        inProgressMissions: _getMissionsByStatus('En cours'),
                        completedMissions: _getMissionsByStatus('Terminé'),
                      ),
                      SizedBox(height: 20),
                      StatsStatusDistribution(
                        pendingMissions: _getMissionsByStatus('En attente'),
                        inProgressMissions: _getMissionsByStatus('En cours'),
                        completedMissions: _getMissionsByStatus('Terminé'),
                        totalMissions: _getTotalMissions(),
                      ),
                      SizedBox(height: 20),
                      StatsRecentMissions(
                        recentMissions: List<Mission>.from(_filteredMissions)
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
                          ..take(5).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}