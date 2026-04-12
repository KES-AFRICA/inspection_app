// foudre_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_foudre_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class FoudreScreen extends StatefulWidget {
  final Mission mission;

  const FoudreScreen({super.key, required this.mission});

  @override
  State<FoudreScreen> createState() => _FoudreScreenState();
}

class _FoudreScreenState extends State<FoudreScreen> {
  late List<Foudre> _observations;
  bool _isLoading = false;
  String _searchQuery = '';
  int? _filterPriorite;

  @override
  void initState() {
    super.initState();
    _loadObservations();
  }

  Future<void> _loadObservations() async {
    setState(() => _isLoading = true);
    _observations = HiveService.getFoudreObservationsByMissionId(widget.mission.id);
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterObservation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterFoudreScreen(mission: widget.mission),
      ),
    );

    if (result == true) {
      await _loadObservations();
    }
  }

  Future<void> _editerObservation(Foudre observation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterFoudreScreen(
          mission: widget.mission,
          observation: observation,
        ),
      ),
    );

    if (result == true) {
      await _loadObservations();
    }
  }

  Future<void> _supprimerObservation(Foudre observation) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression',style: TextStyle(fontSize: 18),),
        content: Text('Voulez-vous vraiment supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.deleteFoudreObservation(observation.key);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Observation supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _loadObservations();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  List<Foudre> _getFilteredObservations() {
    var filtered = List<Foudre>.from(_observations);

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((obs) =>
        obs.observation.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filtrer par priorité
    if (_filterPriorite != null) {
      filtered = filtered.where((obs) =>
        obs.niveauPriorite == _filterPriorite
      ).toList();
    }

    // Trier par priorité (1,2,3) puis date
    filtered.sort((a, b) {
      if (a.niveauPriorite != b.niveauPriorite) {
        return a.niveauPriorite.compareTo(b.niveauPriorite);
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final stats = HiveService.getFoudreStatsForMission(widget.mission.id);
    
    return Container(
      padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard('Total', stats['total'] ?? 0, AppTheme.primaryBlue),
         
          _buildStatCard('P1', stats['priorite_1'] ?? 0, Colors.blue),
         
          _buildStatCard('P2', stats['priorite_2'] ?? 0, Colors.orange),
         
          _buildStatCard('P3', stats['priorite_3'] ?? 0, Colors.red),
        ],
      ),
    );
  }

  Widget _buildObservationCard(Foudre observation) {
    final priorityColor = _getPriorityColor(observation.niveauPriorite);
    final priorityText = _getPriorityText(observation.niveauPriorite);
    
    return  Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey
        ),
      ),
      child: InkWell(
        onTap: () => _editerObservation(observation),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor),
                    ),
                    child: Text(
                      priorityText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editerObservation(observation);
                      } else if (value == 'delete') {
                        _supprimerObservation(observation);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              
              Text(
                observation.observation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Créé le ${_formatDate(observation.createdAt)}',
              //       style: TextStyle(
              //         fontSize: 12,
              //         color: Colors.grey.shade600,
              //       ),
              //     ),
              //     if (observation.updatedAt != observation.createdAt)
              //       Text(
              //         'Modifié le ${_formatDate(observation.updatedAt)}',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Colors.grey.shade600,
              //         ),
              //       ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: TextField(
  //       onChanged: (value) {
  //         setState(() {
  //           _searchQuery = value;
  //         });
  //       },
  //       decoration: InputDecoration(
  //         hintText: 'Rechercher une observation...',
  //         prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: BorderSide(color: Colors.grey.shade300),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: BorderSide(color: Colors.grey.shade300),
  //         ),
  //         filled: true,
  //         fillColor: Colors.grey.shade50,
  //         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPriorityFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: _filterPriorite == null,
              label: Text('Toutes'),
              onSelected: (selected) {
                setState(() {
                  _filterPriorite = null;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: _filterPriorite == null ? Colors.white : Colors.grey.shade700,
              ),
              checkmarkColor: Colors.white,
            ),
            SizedBox(width: 8),
            FilterChip(
              selected: _filterPriorite == 1,
              label: Text('Priorité 1'),
              onSelected: (selected) {
                setState(() {
                  _filterPriorite = selected ? 1 : null;
                });
              },
              backgroundColor: Colors.blue.shade50,
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: _filterPriorite == 1 ? Colors.white : Colors.blue.shade700,
              ),
              checkmarkColor: Colors.white,
            ),
            SizedBox(width: 8),
            FilterChip(
              selected: _filterPriorite == 2,
              label: Text('Priorité 2'),
              onSelected: (selected) {
                setState(() {
                  _filterPriorite = selected ? 2 : null;
                });
              },
              backgroundColor: Colors.orange.shade50,
              selectedColor: Colors.orange,
              labelStyle: TextStyle(
                color: _filterPriorite == 2 ? Colors.white : Colors.orange.shade700,
              ),
              checkmarkColor: Colors.white,
            ),
            SizedBox(width: 8),
            FilterChip(
              selected: _filterPriorite == 3,
              label: Text('Priorité 3'),
              onSelected: (selected) {
                setState(() {
                  _filterPriorite = selected ? 3 : null;
                });
              },
              backgroundColor: Colors.red.shade50,
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: _filterPriorite == 3 ? Colors.white : Colors.red.shade700,
              ),
              checkmarkColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int niveau) {
    switch (niveau) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(int niveau) {
    switch (niveau) {
      case 1: return 'PRIORITÉ 1';
      case 2: return 'PRIORITÉ 2';
      case 3: return 'PRIORITÉ 3';
      default: return 'NON DÉFINI';
    }
  }

  // String _formatDate(DateTime date) {
  //   return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  // }

  @override
  Widget build(BuildContext context) {
    final filteredObservations = _getFilteredObservations();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Observations Foudre'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _ajouterObservation,
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          child: Icon(Icons.add),
        ),
        body: Column(
          children: [
            _buildHeaderStats(),
            SizedBox(height: 8),
            //_buildSearchBar(),
            _buildPriorityFilter(),
            SizedBox(height: 8),
            
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredObservations.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _observations.isEmpty
                            ? 'Aucune observation foudre'
                            : 'Aucune observation correspondante',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cliquez sur le bouton + pour ajouter une observation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadObservations,
                  child: ListView.builder(
                    itemCount: filteredObservations.length,
                    itemBuilder: (context, index) {
                      return _buildObservationCard(filteredObservations[index]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}