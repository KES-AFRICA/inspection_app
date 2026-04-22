// moyenne_tension_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_zone_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_local_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/detail_zone_screen.dart';
import 'package:inspec_app/services/hive_service.dart';

class MoyenneTensionScreen extends StatefulWidget {
  final Mission mission;

  const MoyenneTensionScreen({super.key, required this.mission});

  @override
  State<MoyenneTensionScreen> createState() => _MoyenneTensionScreenState();
}

class _MoyenneTensionScreenState extends State<MoyenneTensionScreen> {
  AuditInstallationsElectriques? _audit;
  bool _isLoading = true;
  bool _isDialogShowing = false;
  bool _hasPreference = false;
  bool _isApplicable = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _refreshAllData() async {
    setState(() => _isLoading = true);
    
    try {
      // Recharger l'audit
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);

      setState(() {
        _audit = audit;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur refresh: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  // Modifiez la méthode _loadData pour appeler refresh :

  Future<void> _loadData() async {
    await _refreshAllData();
  }

  // Récupérer les brouillons pour un local
  List<CoffretArmoire> _getCoffretsForLocal(MoyenneTensionLocal local, int localIndex) {
    final savedCoffrets = List<CoffretArmoire>.from(local.coffrets);
    
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'local',
      parentIndex: localIndex,
      isMoyenneTension: true,
      zoneIndex: null,
    );
    
    // Filtrer les doublons
    final savedQrCodes = savedCoffrets.map((c) => c.qrCode).toSet();
    final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
    
    return [...uniqueDrafts, ...savedCoffrets];
  }

  // Récupérer les coffrets pour un local dans une zone
  List<CoffretArmoire> _getCoffretsForLocalInZone(MoyenneTensionLocal local, int zoneIndex, int localIndex) {
    final savedCoffrets = List<CoffretArmoire>.from(local.coffrets);
    
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'local_in_zone',
      parentIndex: localIndex,
      isMoyenneTension: true,
      zoneIndex: zoneIndex,
    );
    
    final savedQrCodes = savedCoffrets.map((c) => c.qrCode).toSet();
    final uniqueDrafts = drafts.where((d) => !savedQrCodes.contains(d.qrCode)).toList();
    
    return [...uniqueDrafts, ...savedCoffrets];
  }

  // Vérifier si une zone a des coffrets incomplets
  bool _hasIncompletCoffretsInZone(MoyenneTensionZone zone, int zoneIndex) {
    // Vérifier les coffrets directs
    for (var coffret in zone.coffrets) {
      if (!_isCoffretComplet(coffret)) return true;
    }
    
    // Vérifier les brouillons directs
    final drafts = HiveService.getCoffretDraftsForLocation(
      missionId: widget.mission.id,
      parentType: 'zone_mt',
      parentIndex: zoneIndex,
      isMoyenneTension: true,
      zoneIndex: null,
    );
    if (drafts.isNotEmpty) return true;
    
    // Vérifier les locaux
    for (int i = 0; i < zone.locaux.length; i++) {
      final local = zone.locaux[i];
      final allCoffrets = _getCoffretsForLocalInZone(local, zoneIndex, i);
      if (allCoffrets.any((c) => !_isCoffretComplet(c))) return true;
    }
    
    return false;
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

  void _showMoyenneTensionDialog() {
    if (_isDialogShowing) return;
    
    _isDialogShowing = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.bolt, size: 30, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              const Text(
                'Moyenne Tension',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'La moyenne tension est-elle applicable dans cette zone ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      label: 'NON APPLICABLE',
                      icon: Icons.close,
                      color: Colors.red,
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        _isDialogShowing = false;
                        
                        await HiveService.saveMoyenneTensionPreference(widget.mission.id, false);
                        
                        setState(() {
                          _hasPreference = true;
                          _isApplicable = false;
                        });
                        
                        _redirectToBasseTension();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogButton(
                      label: 'APPLICABLE',
                      icon: Icons.check,
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        _isDialogShowing = false;
                        
                        await HiveService.saveMoyenneTensionPreference(widget.mission.id, true);
                        
                        setState(() {
                          _hasPreference = true;
                          _isApplicable = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  Widget _buildDialogButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToBasseTension() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(child: Text('Redirection vers Basse Tension...')),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BasseTensionScreen(mission: widget.mission),
          ),
        );
      }
    });
  }

  void _ajouterLocal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local ajouté avec succès')),
        );
      }
    }
  }

  void _editerLocal(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          local: _audit!.moyenneTensionLocaux[index],
          localIndex: index,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _ajouterZone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
        ),
      ),
    );

    _loadData();

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zone ajoutée avec succès')),
        );
      }
    }
  }

  void _editerZone(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          zone: _audit!.moyenneTensionZones[index],
          zoneIndex: index,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _voirLocal(int index) {
    if (_audit == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLocalScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          localIndex: index,
          local: _audit!.moyenneTensionLocaux[index],
        ),
      ),
    ).then((_) => _loadData());
  }

  void _voirZone(int index) {
    if (_audit == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailZoneScreen(
          mission: widget.mission,
          isMoyenneTension: true,
          zoneIndex: index,
          zone: _audit!.moyenneTensionZones[index],
        ),
      ),
    ).then((_) => _loadData());
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _ajouterZone();
                },
                icon: const Icon(Icons.map_outlined, size: 22),
                label: const Text('Ajouter une zone', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _ajouterLocal();
                },
                icon: const Icon(Icons.domain, size: 22),
                label: const Text('Ajouter un local', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerLocal(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce local ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _audit!.moyenneTensionLocaux.removeAt(index));
              await HiveService.saveAuditInstallations(_audit!);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local supprimé')));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            
            final zone = _audit!.moyenneTensionZones[index];
            final nomZone = zone.nom;
            
            // 1. Supprimer tous les coffrets directs de la zone
            for (var coffret in zone.coffrets) {
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
              _audit!.moyenneTensionZones.removeAt(index);
            });
            await HiveService.saveAuditInstallations(_audit!);
            
            // 4. Supprimer le classement de la zone
            await HiveService.deleteClassementZone(
              missionId: widget.mission.id,
              nomZone: nomZone,
            );
            
            // 5. Rafraîchir
            _loadData();
            
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

  int _getTotalLocaux() {
    if (_audit == null) return 0;
    int total = _audit!.moyenneTensionLocaux.length;
    for (var zone in _audit!.moyenneTensionZones) {
      total += zone.locaux.length;
    }
    return total;
  }

  int _getTotalCoffrets() {
    if (_audit == null) return 0;
    int total = 0;
    for (var local in _audit!.moyenneTensionLocaux) {
      total += _getCoffretsForLocal(local, _audit!.moyenneTensionLocaux.indexOf(local)).length;
    }
    for (var zone in _audit!.moyenneTensionZones) {
      total += zone.coffrets.length;
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        total += _getCoffretsForLocalInZone(local, _audit!.moyenneTensionZones.indexOf(zone), i).length;
      }
    }
    return total;
  }

  Widget _buildNotApplicableScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, size: 40, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Text(
            'Moyenne Tension non applicable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez indiqué que la moyenne tension\nn\'est pas applicable pour cette mission.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasPreference = false;
              });
              _showMoyenneTensionDialog();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Changer la préférence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  if (_isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
  
  if (_audit == null) {
    return const Scaffold(
      body: Center(child: Text('Erreur de chargement')),
    );
  }

  // Si l'utilisateur a choisi "non applicable", afficher l'écran avec option de changer
  if (_hasPreference && !_isApplicable) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moyenne Tension'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildNotApplicableScreen(),
    );
  }

  // Retour principal
  return Scaffold(
    appBar: AppBar(
      title: const Text('Moyenne Tension'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'local') _ajouterLocal();
            if (value == 'zone') _ajouterZone();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'local', child: Text('Ajouter un local')),
            PopupMenuItem(value: 'zone', child: Text('Ajouter une zone')),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Zones', _audit!.moyenneTensionZones.length, Icons.map_outlined),
              _buildStatCard('Locaux', _getTotalLocaux(), Icons.domain),
              _buildStatCard('Coffrets', _getTotalCoffrets(), Icons.electrical_services),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'ZONES'),
                    Tab(text: 'CLASSEMENT'),
                    Tab(text: 'LOCAUX'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Onglet ZONES
                      _audit!.moyenneTensionZones.isEmpty
                          ? _buildEmptyState('zones', _ajouterZone)
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                              itemCount: _audit!.moyenneTensionZones.length,
                              itemBuilder: (context, index) {
                                final zone = _audit!.moyenneTensionZones[index];
                                return _buildZoneCard(zone, index);
                              },
                            ),
                      
                      // Onglet CLASSEMENT
                      _buildClassementTab(),
                      
                      // Onglet LOCAUX
                      _audit!.moyenneTensionLocaux.isEmpty
                        ? _buildEmptyState('locaux', _ajouterLocal)
                        : Builder(
                            builder: (context) {
                              // ✅ Récupérer les brouillons à chaque rebuild (pas en cache)
                              final drafts = HiveService.getLocalDraftsForMoyenneTensionHorsZone(
                                missionId: widget.mission.id,
                              );
                              final locauxExistants = _audit!.moyenneTensionLocaux;
                              
                              // Filtrer les brouillons qui ont déjà un local avec le même nom
                              final nomsExistants = locauxExistants.map((l) => l.nom).toSet();
                              final uniqueDrafts = drafts.where((d) => !nomsExistants.contains(d['nomLocal'])).toList();
                              
                              if (locauxExistants.isEmpty && uniqueDrafts.isEmpty) {
                                return _buildEmptyState('locaux', _ajouterLocal);
                              }
                              
                              return RefreshIndicator(
                                onRefresh: _refreshAllData,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                                  itemCount: uniqueDrafts.length + locauxExistants.length,
                                  itemBuilder: (context, index) {
                                    if (index < uniqueDrafts.length) {
                                      return _buildLocalDraftCard(uniqueDrafts[index]);
                                    } else {
                                      final localIndex = index - uniqueDrafts.length;
                                      return _buildLocalCard(locauxExistants[localIndex], localIndex);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
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
      onPressed: _showAddModal,
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
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

Widget _buildClassementTab() {
  return FutureBuilder<List<ClassementZone>>(
    future: HiveService.syncClassementsZonesFromAudit(widget.mission.id).then(
      (_) => HiveService.getClassementsZonesByMissionId(widget.mission.id)
          .where((cz) => cz.typeZone == 'MT')
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
              Text('Aucune zone à classer', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          Text('IP: ${zone.ip ?? "N/A"}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          Text('IK: ${zone.ik ?? "N/A"}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
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

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(icon, size: 24, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 8),
        Text(count.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(String type, VoidCallback onTap) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'locaux' ? Icons.domain : Icons.map_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Aucun $type ajouté', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Commencez par ajouter un $type', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add),
            label: Text('AJOUTER UN $type'.toUpperCase()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // MODIFIÉ : _buildLocalCard pour afficher les brouillons
  Widget _buildLocalCard(MoyenneTensionLocal local, int localIndex) {
    final conformiteCount = local.dispositionsConstructives.where((e) => e.conforme!).length;
    final totalCount = local.dispositionsConstructives.length;
    final pourcentage = totalCount > 0 ? (conformiteCount / totalCount * 100).round() : 0;
    
    // Récupérer tous les coffrets (existants + brouillons)
    final allCoffrets = _getCoffretsForLocal(local, localIndex);
    final hasIncompletCoffrets = allCoffrets.any((c) => !_isCoffretComplet(c));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.domain, color: AppTheme.primaryBlue),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(local.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (hasIncompletCoffrets)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 6),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${allCoffrets.length} coffret(s)'),
            const SizedBox(height: 4),
            if (totalCount > 0) ...[
              LinearProgressIndicator(
                value: conformiteCount / totalCount,
                backgroundColor: Colors.grey.shade200,
                color: _getProgressColor(pourcentage),
              ),
              const SizedBox(height: 4),
              Text('$pourcentage% conforme'),
            ] else const Text('Aucune vérification', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') _voirLocal(localIndex);
            if (value == 'edit') _editerLocal(localIndex);
            if (value == 'delete') _supprimerLocal(localIndex);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text('Voir détails')),
            PopupMenuItem(value: 'edit', child: Text('Éditer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => _voirLocal(localIndex),
      ),
    );
  }

  Widget _buildLocalDraftCard(Map<String, dynamic> draftData) {
    final local = draftData['local'];
    final nomLocal = draftData['nomLocal'] ?? 'Sans nom';
    final currentStep = draftData['currentStep'] as int? ?? 0;
    final draftId = draftData['localId'] as String?;
    
    // Déterminer le type de local
    String typeLocal = 'Local';
    if (local is MoyenneTensionLocal) {
      final localTypes = HiveService.getLocalTypes();
      typeLocal = localTypes[local.type] ?? local.type;
    }
    
    // Calculer la progression (MT peut avoir 2 ou 3 étapes selon le type)
    final totalSteps = (local is MoyenneTensionLocal && local.type == 'LOCAL_TRANSFORMATEUR') ? 3 : 2;
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

  

  

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _ouvrirBrouillonLocal(Map<String, dynamic> draftData) async {
  final draftId = draftData['localId'] as String?;
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AjouterLocalScreen(
        mission: widget.mission,
        isMoyenneTension: true,
        zoneIndex: draftData['zoneIndex'],
        isInZone: draftData['isInZone'] ?? false,
        local: null,
        draftId: draftId,
      ),
    ),
  );
  
  if (result == true) {
    _loadData();
  }
}

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
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Brouillon supprimé'), backgroundColor: Colors.green),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}


  // MODIFIÉ : _buildZoneCard pour afficher les brouillons
  Widget _buildZoneCard(MoyenneTensionZone zone, int localIndex) {
    final totalLocaux = zone.locaux.length;
    
    // Compter tous les coffrets (existants + brouillons)
    int totalCoffrets = zone.coffrets.length;
    for (int i = 0; i < zone.locaux.length; i++) {
      final local = zone.locaux[i];
      totalCoffrets += _getCoffretsForLocalInZone(local, localIndex, i).length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: InkWell(
        onTap: () => _voirZone(localIndex),
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
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                zone.nom,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        if (zone.description != null) ...[
                          const SizedBox(height: 4),
                          Text(zone.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') _voirZone(localIndex);
                      if (value == 'edit') _editerZone(localIndex);
                      if (value == 'delete') _supprimerZone(localIndex);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('Voir détails')),
                      PopupMenuItem(value: 'edit', child: Text('Éditer')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildZoneStat('Locaux', totalLocaux, Icons.domain),
                    _buildZoneStat('Coffrets directs', zone.coffrets.length, Icons.electrical_services),
                    _buildZoneStat('Total coffrets', totalCoffrets.toInt(), Icons.assessment),
                  ],
                ),
              ),
              if (zone.observationsLibres.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Observations: ${zone.observationsLibres.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
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
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(height: 4),
        Text(count.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
      ],
    );
  }

  Color _getProgressColor(int pourcentage) {
    if (pourcentage >= 80) return Colors.green;
    if (pourcentage >= 50) return Colors.orange;
    return Colors.red;
  }
}