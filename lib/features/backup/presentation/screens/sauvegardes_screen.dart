import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import '../providers/backup_providers.dart';
import '../widgets/microsoft_account_header.dart';
import '../widgets/mission_backup_card.dart';
import '../../domain/models/microsoft_user_profile.dart';
import '../../domain/models/mission_sync_state.dart';

class SauvegardesScreen extends ConsumerStatefulWidget {
  const SauvegardesScreen({super.key});

  @override
  ConsumerState<SauvegardesScreen> createState() => _SauvegardesScreenState();
}

class _SauvegardesScreenState extends ConsumerState<SauvegardesScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  Future<void> _refresh() async {
    final user = HiveService.getCurrentUser();
    if (user != null) {
      await ref.read(backupSyncNotifierProvider.notifier).refreshAll(user.matricule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = HiveService.getCurrentUser();
    final missions = user != null ? HiveService.getMissionsByMatricule(user.matricule) : <Mission>[];
    final syncStates = ref.watch(backupSyncNotifierProvider);
    final hasOfflineIssue = syncStates.values.any((s) => s.status == SyncStatus.interrupted);

    final filtered = missions.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.nomClient.toLowerCase().contains(_searchQuery) ||
          (m.adresseClient ?? '').toLowerCase().contains(_searchQuery) ||
          (m.natureMission ?? '').toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: 215.0, // Fait sortir l'icône de recharge juste en dessous de la barre de recherche
        color: const Color(0xFF0078D4),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // AppBar Fixe & Épurée
            const SliverAppBar(
              pinned: true,
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                'Sauvegardes Cloud M365',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            // Header Pinned & Collapsible (Sliver)
            SliverPersistentHeader(
              pinned: true,
              delegate: _BackupHeaderSliverDelegate(
                searchController: _searchController,
                onSearchChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                ref: ref,
              ),
            ),

            // Bannière d'avertissement si le réseau/cloud est hors-ligne
            if (hasOfflineIssue)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Synchronisation Cloud interrompue (Hors-ligne). Vos données locales restent conservées.',
                          style: TextStyle(color: Color(0xFF92400E), fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: _refresh,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFB45309))),
                      ),
                    ],
                  ),
                ),
              ),

            // Contenu : Liste des missions ou état vide
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        missions.isEmpty ? Icons.assignment_outlined : Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        missions.isEmpty
                            ? 'Aucune mission enregistrée'
                            : 'Aucune mission ne correspond à la recherche.',
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mission = filtered[index];
                      return MissionBackupCard(
                        mission: mission,
                        currentMatricule: user?.matricule ?? '',
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIVER DELEGATE POUR LE HEADER D'ÉTAT & BARRE DE RECHERCHE
// ─────────────────────────────────────────────────────────────

class _BackupHeaderSliverDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final WidgetRef ref;

  _BackupHeaderSliverDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.ref,
  });

  @override
  double get minExtent => 72.0;

  @override
  double get maxExtent => 215.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkPercent = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final authState = ref.watch(microsoftAuthNotifierProvider);
    final profile = authState.asData?.value;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Mode Déplié (Expanded Card + Search Bar)
          Opacity(
            opacity: (1.0 - shrinkPercent * 2.0).clamp(0.0, 1.0),
            child: OverflowBox(
              minHeight: maxExtent,
              maxHeight: maxExtent,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const MicrosoftAccountHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildExpandedSearchBar(),
                  ),
                ],
              ),
            ),
          ),

          // 2. Mode Replié (Sliver Compact Pinned Header)
          if (shrinkPercent > 0.4)
            Opacity(
              opacity: ((shrinkPercent - 0.4) / 0.6).clamp(0.0, 1.0),
              child: Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Icône compacte d'état Cloud
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: profile != null
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        profile != null ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: profile != null ? const Color(0xFF10B981) : Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Barre de recherche compacte
                    Expanded(
                      child: _buildCompactSearchBar(),
                    ),
                    const SizedBox(width: 8),

                    // Bouton de connexion / déconnexion compact (icône sans texte)
                    _buildCompactAuthButton(context, profile),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Rechercher une mission...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAuthButton(BuildContext context, MicrosoftUserProfile? profile) {
    if (profile == null) {
      return ElevatedButton(
        onPressed: () {
          // Triggers login modal in header
          ref.read(microsoftAuthNotifierProvider.notifier).checkStatus();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0078D4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          minimumSize: const Size(36, 36),
        ),
        child: const Icon(Icons.login_rounded, size: 18),
      );
    }

    return IconButton(
      onPressed: () {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            elevation: 24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Déconnexion Microsoft 365',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter de votre compte professionnel Microsoft 365 ?\n\nLes sauvegardes automatiques sur OneDrive seront suspendues.',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(microsoftAuthNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion de Microsoft 365 effectuée.'),
                        backgroundColor: Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
      tooltip: 'Déconnexion M365',
    );
  }

  @override
  bool shouldRebuild(covariant _BackupHeaderSliverDelegate oldDelegate) {
    return oldDelegate.searchController.text != searchController.text;
  }
}
