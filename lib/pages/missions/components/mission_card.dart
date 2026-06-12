import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_detail_screen.dart';
import 'package:inspec_app/services/backup_service.dart';
import '../../../models/mission.dart';
import '../../../constants/app_theme.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final Verificateur user;
  final VoidCallback? onDeleted;

  const MissionCard({
    super.key,
    required this.mission,
    required this.user,
    this.onDeleted,
  });

  // ── Statut ────────────────────────────────────────────────────
  String _normalizeStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('encour') || s.contains('en cours')) return 'En cours';
    if (s.contains('termine') || s.contains('terminé'))  return 'Terminé';
    if (s.contains('attente'))                           return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Statuts affichés : 'En cours' et 'En attente' uniquement.
  // Les missions terminées n'affichent pas le libellé — juste la pastille verte.
  String _badgeLabel(String status) {
    switch (_normalizeStatus(status)) {
      case 'En cours':   return 'En cours';
      case 'En attente': return 'En attente';
      default:           return ''; // terminée → pas de texte de statut
    }
  }

  Color _getStatusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'En attente': return Colors.orange;
      case 'En cours':   return AppTheme.primaryBlue;
      default:           return Colors.green; // terminée
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  // ── Menu ⋮ ───────────────────────────────────────────────────
  void _showMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'export',
          height: 44,
          child: Row(children: [
            Icon(Icons.file_upload_outlined,
                size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 10),
            const Text('Exporter', style: TextStyle(fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text('Supprimer',
                style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
          ]),
        ),
      ],
    ).then((val) {
      if (val == 'export') _handleExport(context);
      if (val == 'delete') _handleDelete(context);
    });
  }

  Future<void> _handleExport(BuildContext context) async {
    // Indicateur non bloquant
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Export en cours…'),
      ]),
      duration: Duration(seconds: 30),
      behavior: SnackBarBehavior.floating,
    ));

    final result = await BackupService.exporterMission(mission.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message ??
          (result.success ? 'Export réussi.' : 'Erreur export.')),
      backgroundColor: result.success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteDialog(missionName: mission.nomClient),
    );
    if (confirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Suppression en cours…'),
      ]),
      duration: Duration(seconds: 30),
      behavior: SnackBarBehavior.floating,
    ));

    final result = await BackupService.deleteMissionCompletely(mission.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message ??
          (result.success ? 'Mission supprimée.' : 'Erreur suppression.')),
      backgroundColor: result.success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));

    if (result.success) onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(mission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                MissionDetailScreen(mission: mission, user: user),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Contenu principal ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + nom + activité
                    Row(children: [
                      if (mission.logoClient != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            mission.logoClient!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.business,
                                  size: 20, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.nomClient,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mission.activiteClient != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                mission.activiteClient!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ]),

                    const SizedBox(height: 10),

                    // Badge statut
                    // Badge statut — sans "Terminé" (pastille suffisante)
                    Builder(builder: (ctx) {
                      final label = _badgeLabel(mission.status);
                      if (label.isEmpty) {
                        // Terminée : pastille colorée seule
                        return Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                          ),
                        ]);
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    }),

                    // Adresse
                    if (mission.adresseClient != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.greyDark),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mission.adresseClient!,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.greyDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],

                    // Date intervention
                    if (mission.dateIntervention != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppTheme.greyDark),
                        const SizedBox(width: 4),
                        Text(
                          'Intervention : ${_formatDate(mission.dateIntervention!)}',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.greyDark),
                        ),
                      ]),
                    ],

                    // Dates créé / modifié
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Créé ${_formatDate(mission.createdAt)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.update,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Modifié ${_formatDate(mission.updatedAt)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ]),

                    // Nature mission
                    if (mission.natureMission != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mission.natureMission!,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.darkBlue,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Bouton ⋮ ──────────────────────────────────────
              GestureDetector(
                onTapDown: (details) =>
                    _showMenu(context, details.globalPosition),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Icon(Icons.more_vert,
                      size: 20, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  DIALOGUE SUPPRESSION — compte à rebours 10 s
// ════════════════════════════════════════════════════════════════
class _DeleteDialog extends StatefulWidget {
  final String missionName;
  const _DeleteDialog({required this.missionName});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _countdown == 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      title: const Row(children: [
        Icon(Icons.warning_rounded, color: Colors.red, size: 20),
        SizedBox(width: 8),
        Text('Supprimer la mission',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de la mission
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.missionName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Avertissement
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              'Action irréversible. Toutes les données, photos et fichiers associés seront définitivement supprimés.',
              style: TextStyle(
                  fontSize: 12, color: Colors.red.shade700),
            ),
          ),
          const SizedBox(height: 14),

          // Compte à rebours
          Center(
            child: ready
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    Text('Vous pouvez confirmer',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600)),
                  ])
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        value: (10 - _countdown) / 10,
                        strokeWidth: 2.5,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Disponible dans $_countdown s',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ]),
          ),
          const SizedBox(height: 6),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler',
              style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            disabledBackgroundColor: Colors.red.shade200,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Supprimer',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}