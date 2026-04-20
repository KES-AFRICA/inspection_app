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
      // Récupérer les brouillons pour cette zone
      final drafts = HiveService.getCoffretDraftsForLocation(
        missionId: widget.mission.id,
        parentType: 'zone_bt',
        parentIndex: _audit!.basseTensionZones.indexOf(zone),
        isMoyenneTension: false,
        zoneIndex: null,
      );
      final savedQrCodes = zone.coffretsDirects.map((c) => c.qrCode).toSet();
      final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
      
      total += zone.coffretsDirects.length + uniqueDrafts.length;
      for (var local in zone.locaux) {
        total += local.coffrets.length;
      }
    }
    return total;
  }

  // Vérifier si un coffret est complet
  bool _isCoffretComplet(CoffretArmoire coffret) {
    if (coffret.nom.isEmpty) return false;
    if (coffret.type.isEmpty) return false;
    if (coffret.domaineTension.isEmpty) return false;
    if (coffret.photos.isEmpty) return false;
    
    for (var point in coffret.pointsVerification) {
      if (point.conformite.isEmpty) return false;
      if (point.conformite == 'non') {
        if (point.observation == null || point.observation!.trim().isEmpty) return false;
      }
    }
    
    return true;
  }

  // Vérifier si une zone a des coffrets incomplets
  bool _hasIncompletCoffretsInZone(BasseTensionZone zone, int zoneIndex) {
    // Vérifier les coffrets directs
    for (var coffret in zone.coffretsDirects) {
      if (!_isCoffretComplet(coffret)) return true;
    }
    
    // Vérifier les brouillons directs
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'zone_bt',
      parentIndex: zoneIndex,
      isMoyenneTension: false,
      zoneIndex: null,
    );
    if (drafts.any((d) => !_isCoffretComplet(d))) return true;
    
    // Vérifier les locaux
    for (var local in zone.locaux) {
      for (var coffret in local.coffrets) {
        if (!_isCoffretComplet(coffret)) return true;
      }
    }
    
    return false;
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
                _buildStatCard('Coffrets', _getTotalCoffrets(), Icons.electrical_services),
              ],
            ),
          ),
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

  // MODIFIÉ : _buildZoneCard pour afficher les brouillons
  Widget _buildZoneCard(BasseTensionZone zone, int index) {
    final totalLocaux = zone.locaux.length;
    
    // Récupérer les brouillons pour cette zone
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'zone_bt',
      parentIndex: index,
      isMoyenneTension: false,
      zoneIndex: null,
    );
    
    final savedQrCodes = zone.coffretsDirects.map((c) => c.qrCode).toSet();
    final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
    
    final allCoffretsDirects = [...uniqueDrafts, ...zone.coffretsDirects];
    
    // Compter tous les coffrets (existants + brouillons)
    int totalCoffrets = allCoffretsDirects.length;
    for (var local in zone.locaux) {
      totalCoffrets += local.coffrets.length;
    }
    
    final hasIncompletCoffrets = _hasIncompletCoffretsInZone(zone, index);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                zone.nom,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (hasIncompletCoffrets)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Text(
                                  'Incomplet',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
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
                    _buildZoneStat('Coffrets directs', allCoffretsDirects.length, Icons.electrical_services),
                    _buildZoneStat('Total coffrets', totalCoffrets as int, Icons.assessment),
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