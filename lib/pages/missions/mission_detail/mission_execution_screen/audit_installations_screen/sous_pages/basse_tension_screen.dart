// basse_tension_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_local_screen.dart';
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

    _loadAudit();

    if (result == true) {
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
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette zone ?\n\n'
          'TOUS les locaux et coffrets contenus dans cette zone seront également supprimés définitivement.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final zone = _audit!.basseTensionZones[index];
              final nomZone = zone.nom;
              
              // 1. Supprimer tous les coffrets directs de la zone
              for (var coffret in zone.coffretsDirects) {
                await HiveService.deleteCoffretDraft(coffret.qrCode);
              }
              
              // 2. Supprimer tous les locaux et leurs coffrets
              for (var local in zone.locaux) {
                for (var coffret in local.coffrets) {
                  await HiveService.deleteCoffretDraft(coffret.qrCode);
                }
                // Supprimer le classement du local
                await HiveService.deleteClassementLocal(
                  missionId: widget.mission.id,
                  nomLocal: local.nom,
                );
              }
              
              // 3. Supprimer la zone de l'audit
              setState(() {
                _audit!.basseTensionZones.removeAt(index);
              });
              await HiveService.saveAuditInstallations(_audit!);
              
              // 4. Supprimer le classement de la zone
              await HiveService.deleteClassementZone(
                missionId: widget.mission.id,
                nomZone: nomZone,
              );
              
              // 5. Rafraîchir
              _loadAudit();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zone et tout son contenu supprimés')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDraftCard(Map<String, dynamic> draftData, int zoneIndex) {
    final local = draftData['local'];
    final nomLocal = draftData['nomLocal'] ?? 'Sans nom';
    final currentStep = draftData['currentStep'] as int? ?? 0;
    final draftId = draftData['localId'] as String?;
    
    // Déterminer le type de local
    String typeLocal = 'Local';
    if (local is BasseTensionLocal) {
      final localTypes = HiveService.getLocalTypes();
      typeLocal = localTypes[local.type] ?? local.type;
    }
    
    // Calculer la progression
    final totalSteps = 2; // Basse tension : toujours 2 étapes (infos + éléments)
    final pourcentage = (currentStep / totalSteps * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.drafts_outlined, color: Colors.orange),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                nomLocal,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                'Brouillon',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$typeLocal • Étape $currentStep/$totalSteps • $pourcentage%'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'continue') {
              _ouvrirBrouillonLocal(draftData);
            } else if (value == 'delete') {
              _supprimerBrouillonLocal(draftId, nomLocal);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'continue',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Continuer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _ouvrirBrouillonLocal(draftData),
      ),
    );
  }

  // Ouvrir un brouillon de local =====
  void _ouvrirBrouillonLocal(Map<String, dynamic> draftData) async {
    final draftId = draftData['localId'] as String?;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: false,
          zoneIndex: draftData['zoneIndex'],
          isInZone: true,
          local: null,
          draftId: draftId, // ← NOUVEAU : Passer l'ID du brouillon
        ),
      ),
    );
    
    if (result == true) {
      _loadAudit();
    }
  }

  // Supprimer un brouillon de local =====
  void _supprimerBrouillonLocal(String? draftId, String nomLocal) {
    if (draftId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le brouillon'),
        content: Text('Voulez-vous vraiment supprimer le brouillon "$nomLocal" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.deleteLocalDraft(draftId);
              _loadAudit();
              _showSuccess('Brouillon supprimé');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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
          child: DefaultTabController(
            length: 2, // ← MODIFIÉ : 2 onglets
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'ZONES'),
                    Tab(text: 'CLASSEMENT'), // ← NOUVEAU
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Onglet ZONES (existantes + contenu)
                      _audit!.basseTensionZones.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.only(top:16,left: 16,right: 16,bottom: 72),
                              itemCount: _audit!.basseTensionZones.length,
                              itemBuilder: (context, index) {
                                final zone = _audit!.basseTensionZones[index];
                                return _buildZoneCard(zone, index);
                              },
                            ),
                      
                      // Onglet CLASSEMENT (NOUVEAU)
                      _buildClassementTab(),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildClassementTab() {
    return FutureBuilder<List<ClassementZone>>(
      future: HiveService.syncClassementsZonesFromAudit(widget.mission.id).then(
        (_) => HiveService.getClassementsZonesByMissionId(widget.mission.id)
            .where((cz) => cz.typeZone == 'BT')
            .toList(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final zones = snapshot.data ?? [];
        
        if (zones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune zone à classer',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez une zone pour la classer',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            final estComplet = zone.estComplet;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _ouvrirClassementZone(zone),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: estComplet ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.map_outlined,
                              color: estComplet ? Colors.green : AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              zone.nomZone,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estComplet ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              estComplet ? 'Classée' : 'À classer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: estComplet ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (estComplet) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfluenceChip('AF', zone.af!),
                            _buildInfluenceChip('BE', zone.be!),
                            _buildInfluenceChip('AE', zone.ae!),
                            _buildInfluenceChip('AD', zone.ad!),
                            _buildInfluenceChip('AG', zone.ag!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'IP: ${zone.ip ?? "N/A"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              'IK: ${zone.ik ?? "N/A"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _ouvrirClassementZone(ClassementZone classement) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementZoneScreen(
          mission: widget.mission,
          classement: classement,
        ),
      ),
    );
    
    if (result == true) {
      setState(() {});
    }
  }

  Widget _buildInfluenceChip(String type, String code) {
    final Map<String, Color> colorMap = {
      'AF': Colors.blue,
      'BE': Colors.purple,
      'AE': Colors.orange,
      'AD': Colors.teal,
      'AG': Colors.red,
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorMap[type]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorMap[type]!.withOpacity(0.3)),
      ),
      child: Text(
        '$type: $code',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorMap[type]!,
        ),
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
    
    // Récupérer les brouillons pour cette zone (pour le compteur uniquement)
    final drafts = HiveService.getLocalDraftsForBasseTensionZone(
      missionId: widget.mission.id,
      zoneIndex: index,
    );
    final nomsExistants = zone.locaux.map((l) => l.nom).toSet();
    final uniqueDrafts = drafts.where((d) => !nomsExistants.contains(d['nomLocal'])).toList();
    
    final totalLocauxAvecBrouillons = totalLocaux + uniqueDrafts.length;
    
    int totalCoffrets = zone.coffretsDirects.length;
    for (var local in zone.locaux) {
      totalCoffrets += local.coffrets.length;
    }

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
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
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
                    _buildZoneStat('Locaux', totalLocauxAvecBrouillons, Icons.domain),
                    _buildZoneStat('Coffrets directs', zone.coffretsDirects.length, Icons.electrical_services),
                    _buildZoneStat('Total coffrets', totalCoffrets, Icons.assessment),
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