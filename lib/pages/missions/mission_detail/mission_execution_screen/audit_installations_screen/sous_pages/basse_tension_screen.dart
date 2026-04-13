// basse_tension_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class BasseTensionScreen extends StatefulWidget {
  final Mission mission;

  const BasseTensionScreen({super.key, required this.mission});

  @override
  State<BasseTensionScreen> createState() => _BasseTensionScreenState();
}

class _BasseTensionScreenState extends State<BasseTensionScreen> {
  AuditInstallationsElectriques? _audit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  void _loadAudit() async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      setState(() {
        _audit = audit;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement audit: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _ajouterZone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: false,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zone ajoutée avec succès')),
      );
    }
  }

  void _editerZone(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          zone: _audit!.basseTensionZones[index],
          zoneIndex: index,
        ),
      ),
    );

    if (result == true) {
      _loadAudit();
    }
  }

  void _voirZone(int index) {
    if (_audit == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailZoneScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          zoneIndex: index,
          zone: _audit!.basseTensionZones[index],
        ),
      ),
    ).then((_) => _loadAudit());
  }

  void _supprimerZone(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cette zone ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _audit!.basseTensionZones.removeAt(index);
              });
              await HiveService.saveAuditInstallations(_audit!);
              _loadAudit();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Zone supprimée')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _getTotalLocaux() {
    if (_audit == null) return 0;
    
    int total = 0;
    for (var zone in _audit!.basseTensionZones) {
      total += zone.locaux.length;
    }
    return total;
  }

  int _getTotalCoffrets() {
    if (_audit == null) return 0;
    
    int total = 0;
    for (var zone in _audit!.basseTensionZones) {
      total += zone.coffretsDirects.length;
      for (var local in zone.locaux) {
        total += local.coffrets.length;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_audit == null) {
      return Center(child: Text('Erreur de chargement'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Basse Tension'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _ajouterZone,
            tooltip: 'Ajouter une zone',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Zones', _audit!.basseTensionZones.length, Icons.map_outlined),
                _buildStatCard('Locaux', _getTotalLocaux(), Icons.domain),
                _buildStatCard('Équipements', _getTotalCoffrets(), Icons.electrical_services),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: _audit!.basseTensionZones.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                    itemCount: _audit!.basseTensionZones.length,
                    itemBuilder: (context, index) {
                      final zone = _audit!.basseTensionZones[index];
                      return _buildZoneCard(zone, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterZone,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Aucune zone ajoutée',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Commencez par ajouter une zone',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _ajouterZone,
            icon: Icon(Icons.add),
            label: Text('AJOUTER UNE ZONE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(BasseTensionZone zone, int index) {
    final totalLocaux = zone.locaux.length;
    final totalCoffrets = zone.coffretsDirects.length + zone.locaux.fold(0, (sum, local) => sum + local.coffrets.length);

    return  Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
        ),
      ),
      child: InkWell(
        onTap: () => _voirZone(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map_outlined, color: Colors.blue),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.nom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (zone.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            zone.description!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') _voirZone(index);
                      if (value == 'edit') _editerZone(index);
                      if (value == 'delete') _supprimerZone(index);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'view', child: Text('Voir détails')),
                      PopupMenuItem(value: 'edit', child: Text('Éditer')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildZoneStat('Locaux', totalLocaux, Icons.domain),
                    _buildZoneStat('Équipements directs', zone.coffretsDirects.length, Icons.electrical_services),
                    _buildZoneStat('Total Équipements', totalCoffrets as int, Icons.assessment),
                  ],
                ),
              ),
              if (zone.observationsLibres.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Observations: ${zone.observationsLibres.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneStat(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}