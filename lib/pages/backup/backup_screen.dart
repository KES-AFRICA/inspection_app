// lib/pages/backup/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:intl/intl.dart';

class BackupScreen extends StatefulWidget {
  final Verificateur user;
  const BackupScreen({super.key, required this.user});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  // ── Export ────────────────────────────────────────────────────
  Future<void> _handleExport() async {
    final missions =
        HiveService.getMissionsByMatricule(widget.user.matricule);
    if (missions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune mission disponible à exporter.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // 1 seule mission → export direct
    if (missions.length == 1) {
      await _exportMission(missions.first);
      return;
    }

    // Plusieurs → dialogue de sélection
    final chosen = await _showMissionSelectionDialog(missions);
    if (chosen == null) return;

    if (chosen == '__ALL__') {
      await _exportAll();
    } else {
      final mission = missions.firstWhere((m) => m.id == chosen,
          orElse: () => missions.first);
      await _exportMission(mission);
    }
  }

  Future<void> _exportMission(Mission mission) async {
    setState(() => _isExporting = true);
    final result = await BackupService.exporterMission(mission.id);
    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? 'Export réussi.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      _showErrorDialog(
          result.message ?? "Erreur lors de l'export.", result.errorDetail);
    }
  }

  Future<void> _exportAll() async {
    setState(() => _isExporting = true);
    final result =
        await BackupService.exporterMissions(widget.user.matricule);
    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? 'Export réussi.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      _showErrorDialog(
          result.message ?? "Erreur lors de l'export.", result.errorDetail);
    }
  }

  Future<String?> _showMissionSelectionDialog(List<Mission> missions) =>
      showDialog<String>(
        context: context,
        builder: (ctx) => _MissionSelectionDialog(missions: missions),
      );

  // ── Import ────────────────────────────────────────────────────
  Future<void> _handleImport() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final filePath = picked.files.first.path;
    if (filePath == null) return;

    final opts = await _showImportOptionsDialog();
    if (opts == null) return;

    setState(() => _isImporting = true);
    final result = await BackupService.importerMissions(
      filePath,
      ecraserExistants: opts['ecraser'] as bool,
      importeurMatricule: widget.user.matricule,
      importeurNom: widget.user.nom,
      importeurPrenom: widget.user.prenom,
    );
    if (!mounted) return;
    setState(() => _isImporting = false);
    _showImportReport(result);
  }

  Future<Map<String, dynamic>?> _showImportOptionsDialog() {
    bool ecraser = false;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.file_download_outlined, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Expanded(child: Text('Importer une sauvegarde')),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Restaurer les missions depuis ce fichier ?',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.verified_user_outlined,
                      color: Colors.orange, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'L\'intégrité du fichier sera vérifiée automatiquement.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ]),
              ),
              CheckboxListTile(
                value: ecraser,
                onChanged: (v) => setS(() => ecraser = v ?? false),
                title: const Text('Écraser les missions existantes',
                    style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {'ecraser': ecraser}),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Importer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportReport(ImportResult result) {
    final hasNew = result.importedMissions > 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
              result.success ? Icons.check_circle : Icons.error_outline,
              color: result.success ? Colors.green : Colors.red,
              size: 20),
          const SizedBox(width: 8),
          const Text("Rapport d'import",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _reportRow(Icons.file_download, 'Importées',
                  '${result.importedMissions}', Colors.green),
              _reportRow(Icons.skip_next, 'Ignorées',
                  '${result.skippedMissions}', Colors.orange),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Avertissements :',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                ...result.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 12, color: Colors.orange),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(w,
                                    style:
                                        const TextStyle(fontSize: 11))),
                          ]),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (hasNew) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg, String? detail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18),
          SizedBox(width: 8),
          Text('Erreur',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, style: const TextStyle(fontSize: 13)),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _reportRow(
          IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
        ]),
      );

  @override
  @override
  Widget build(BuildContext context) {
    final missions =
        HiveService.getMissionsByMatricule(widget.user.matricule);
    final missionCount = missions.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Sauvegarde & Restauration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bandeau info premium ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.08),
                    AppTheme.lightBlue.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_outlined,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protection de vos données',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$missionCount mission${missionCount > 1 ? 's' : ''} disponible${missionCount > 1 ? 's' : ''} localement.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Card Export ───────────────────────────────────────
            _buildActionCard(
              icon: Icons.file_upload_outlined,
              color: AppTheme.primaryBlue,
              title: 'Exporter mes missions',
              subtitle:
                  'Sélectionnez une mission ou exportez toutes vos missions. '
                  'Chaque export inclut données, photos et brouillons.',
              tip:
                  'Partagez ou stockez sur Google Drive, OneDrive ou email.',
              buttonLabel: 'Sélectionner et exporter',
              isLoading: _isExporting,
              onPressed: _isExporting ? null : _handleExport,
            ),

            const SizedBox(height: 16),

            // ── Card Import ───────────────────────────────────────
            _buildActionCard(
              icon: Icons.file_download_outlined,
              color: Colors.teal,
              title: 'Importer une sauvegarde',
              subtitle:
                  'Restaure les données depuis un fichier .json. '
                  'L\'intégrité est vérifiée automatiquement (checksum).',
              tip:
                  'Sélectionnez le fichier depuis votre appareil ou cloud.',
              buttonLabel: 'Sélectionner et importer',
              isLoading: _isImporting,
              onPressed: _isImporting ? null : _handleImport,
            ),

            const SizedBox(height: 24),

            // ── Bonnes pratiques ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Bonnes pratiques',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _tip(
                    Icons.touch_app_outlined,
                    'Export rapide',
                    'Depuis la liste, appuyez sur ⋮ sur une carte mission pour l\'exporter ou la supprimer.',
                  ),
                  _tip(
                    Icons.calendar_today_outlined,
                    'Fréquence',
                    'Exportez après chaque journée d\'inspection.',
                  ),
                  _tip(
                    Icons.cloud_upload_outlined,
                    'Stockage cloud',
                    'Conservez sur Google Drive, OneDrive ou par email.',
                  ),
                  _tip(
                    Icons.verified_user_outlined,
                    'Intégrité',
                    'Chaque export est signé par un checksum SHA-256.',
                  ),
                  _tip(
                    Icons.phone_android_outlined,
                    'Multi-appareil',
                    'Sur un nouveau téléphone, importez votre sauvegarde.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String tip,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(icon, size: 18),
                label: Text(
                  isLoading ? 'Traitement en cours…' : buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tip(IconData icon, String label, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ════════════════════════════════════════════════════════════════
//  DIALOGUE SÉLECTION DE MISSION
// ════════════════════════════════════════════════════════════════
class _MissionSelectionDialog extends StatefulWidget {
  final List<Mission> missions;
  const _MissionSelectionDialog({required this.missions});

  @override
  State<_MissionSelectionDialog> createState() =>
      _MissionSelectionDialogState();
}

class _MissionSelectionDialogState
    extends State<_MissionSelectionDialog> {
  String _search = '';

  List<Mission> get _filtered {
    final q = _search.toLowerCase();
    return widget.missions
        .where((m) =>
            m.nomClient.toLowerCase().contains(q) ||
            (m.nomSite?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'terminee':
        return Colors.green;
      case 'en_cours':
        return AppTheme.primaryBlue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'terminee':
        return 'Terminée';
      case 'en_cours':
        return 'En cours';
      default:
        return 'En attente';
    }
  }

  String _fmt(DateTime? d) =>
      d != null ? DateFormat('dd/MM/yyyy').format(d) : '-';

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.file_upload_outlined,
                      color: AppTheme.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Choisir une mission',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, size: 17),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue)),
                  ),
                ),
              ],
            ),
          ),

          // Liste
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.42,
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aucune mission trouvée.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final m = filtered[i];
                      final sc = _statusColor(m.status);
                      return InkWell(
                        onTap: () => Navigator.pop(context, m.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: sc.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                              child: Icon(
                                  Icons.assignment_outlined,
                                  color: sc,
                                  size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(m.nomClient,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis),
                                    if (m.nomSite?.isNotEmpty ==
                                        true)
                                      Text(m.nomSite!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors
                                                  .grey.shade600),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sc.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                        ),
                                        child: Text(
                                            _statusLabel(m.status),
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: sc)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_fmt(m.dateIntervention),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors
                                                  .grey.shade400)),
                                    ]),
                                  ]),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 16),
                          ]),
                        ),
                      );
                    },
                  ),
          ),

          // Footer — exporter toutes
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
            child: Column(children: [
              const Divider(height: 16),
              InkWell(
                onTap: () => Navigator.pop(context, '__ALL__'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.select_all,
                          color: Colors.teal, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Exporter toutes mes missions',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                                '${widget.missions.length} mission${widget.missions.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ]),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 13, color: Colors.grey),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}