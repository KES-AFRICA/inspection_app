// moyenne_tension_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _hasPreference = await HiveService.hasMoyenneTensionPreference(widget.mission.id);
      _isApplicable = await HiveService.isMoyenneTensionApplicable(widget.mission.id);
      
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      
      setState(() {
        _audit = audit;
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (!_hasPreference) {
            _showMoyenneTensionDialog();
          } else if (!_isApplicable) {
            _showMoyenneTensionDialog();
          }
        }
      });
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
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

    if (result == true) {
      _loadData();
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
        content: const Text('Voulez-vous vraiment supprimer cette zone ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _audit!.moyenneTensionZones.removeAt(index));
              await HiveService.saveAuditInstallations(_audit!);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zone supprimée')));
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
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(text: 'ZONES'),
                      Tab(text: 'LOCAUX'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
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
                        _audit!.moyenneTensionLocaux.isEmpty
                            ? _buildEmptyState('locaux', _ajouterLocal)
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 72),
                                itemCount: _audit!.moyenneTensionLocaux.length,
                                itemBuilder: (context, index) {
                                  final local = _audit!.moyenneTensionLocaux[index];
                                  return _buildLocalCard(local, index);
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
  Widget _buildLocalCard(MoyenneTensionLocal local, int index) {
    final conformiteCount = local.dispositionsConstructives.where((e) => e.conforme).length;
    final totalCount = local.dispositionsConstructives.length;
    final pourcentage = totalCount > 0 ? (conformiteCount / totalCount * 100).round() : 0;
    
    // Récupérer tous les coffrets (existants + brouillons)
    final allCoffrets = _getCoffretsForLocal(local, index);
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
            if (value == 'view') _voirLocal(index);
            if (value == 'edit') _editerLocal(index);
            if (value == 'delete') _supprimerLocal(index);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text('Voir détails')),
            PopupMenuItem(value: 'edit', child: Text('Éditer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => _voirLocal(index),
      ),
    );
  }

  // MODIFIÉ : _buildZoneCard pour afficher les brouillons
  Widget _buildZoneCard(MoyenneTensionZone zone, int index) {
    final totalLocaux = zone.locaux.length;
    
    // Compter tous les coffrets (existants + brouillons)
    int totalCoffrets = zone.coffrets.length;
    for (int i = 0; i < zone.locaux.length; i++) {
      final local = zone.locaux[i];
      totalCoffrets += _getCoffretsForLocalInZone(local, index, i).length;
    }
    
    final hasIncompletCoffrets = _hasIncompletCoffretsInZone(zone, index);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: InkWell(
        onTap: () => _voirZone(index),
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
                            if (hasIncompletCoffrets)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          const SizedBox(height: 4),
                          Text(zone.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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