import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import '../providers/backup_providers.dart';
import '../widgets/microsoft_account_header.dart';
import '../widgets/mission_backup_card.dart';
import '../../domain/models/microsoft_user_profile.dart';
import '../../domain/models/mission_sync_state.dart';
import '../widgets/msal_recommendation_banner.dart';

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
      final user = HiveService.getCurrentUser();
      if (user != null) {
        ref.read(backupSchedulerServiceProvider).initializeWorkManager(user.matricule);
      }
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

  Future<void> _refresh() async {
    final user = HiveService.getCurrentUser();
    if (user != null) {
      await ref.read(backupSyncNotifierProvider.notifier).refreshAll(user.matricule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = HiveService.getCurrentUser();
    final missions = user != null ? HiveService.getMissionsByMatricule(user.matricule) : <Mission>[];
    final syncStates = ref.watch(backupSyncNotifierProvider);
    final msAuth = ref.watch(microsoftAuthNotifierProvider);
    final isConnected = msAuth.value != null;
    final hasOfflineIssue = syncStates.values.any((s) => s.status == SyncStatus.interrupted);

    final filtered = missions.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.nomClient.toLowerCase().contains(_searchQuery) ||
          (m.adresseClient ?? '').toLowerCase().contains(_searchQuery) ||
          (m.natureMission ?? '').toLowerCase().contains(_searchQuery);
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: 215.0,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Header Pinned & Collapsible avec transition fluide Sliver (sans filtres dupliqués)
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
                  isDarkMode: isDarkMode,
                ),
              ),

              // Bannière de recommandation MSAL si l'inspecteur n'est pas encore connecté
              if (!isConnected)
                SliverToBoxAdapter(
                  child: MsalRecommendationBanner(
                    onConnectPressed: () {
                      ref.read(microsoftAuthNotifierProvider.notifier).checkStatus();
                    },
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: AppTheme.primaryBlue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sauvegarde automatique planifiée activée • Du Lun. au Sam. à 17h10',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIVER DELEGATE POUR LE HEADER D'ÉTAT & BARRE DE RECHERCHE (SAUVEGARDES)
// ─────────────────────────────────────────────────────────────

class _BackupHeaderSliverDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final WidgetRef ref;
  final bool isDarkMode;

  _BackupHeaderSliverDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.ref,
    required this.isDarkMode,
  });

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 205.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkPercent = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final authState = ref.watch(microsoftAuthNotifierProvider);
    final profile = authState.asData?.value;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        boxShadow: shrinkPercent > 0.8
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Mode Déplié (Header Compte Microsoft + Barre de Recherche)
          Opacity(
            opacity: (1.0 - shrinkPercent * 2.2).clamp(0.0, 1.0),
            child: OverflowBox(
              minHeight: maxExtent,
              maxHeight: maxExtent,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const MicrosoftAccountHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _buildExpandedSearchBar(),
                  ),
                ],
              ),
            ),
          ),

          // 2. Mode Replié (Header Compact Persistant Pinned)
          if (shrinkPercent > 0.45)
            Opacity(
              opacity: ((shrinkPercent - 0.45) / 0.55).clamp(0.0, 1.0),
              child: Container(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Barre de recherche compacte
                    Expanded(
                      child: _buildCompactSearchBar(),
                    ),
                    const SizedBox(width: 8),

                    // Icône compacte d'état Cloud
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
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(
          fontSize: 13.5,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher une mission...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
              : null,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 12.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryBlue,
            size: 18,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCompactAuthButton(BuildContext context, MicrosoftUserProfile? profile) {
    if (profile == null) {
      return ElevatedButton(
        onPressed: () {
          ref.read(microsoftAuthNotifierProvider.notifier).checkStatus();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          minimumSize: const Size(36, 36),
          elevation: 0,
        ),
        child: const Icon(Icons.login_rounded, size: 18),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
      ),
      child: Icon(
        Icons.cloud_done_rounded,
        color: const Color(0xFF10B981),
        size: 18,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BackupHeaderSliverDelegate oldDelegate) {
    return oldDelegate.searchController.text != searchController.text ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
