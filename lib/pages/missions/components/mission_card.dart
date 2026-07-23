import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/create_mission_screen.dart';
import 'package:inspec_app/pages/missions/mission_hub/mission_hub_screen.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/trash_service.dart';

/// Carte de mission moderne avec micro-interactions, badges dynamiques et menu 3-dots.
class MissionCard extends StatefulWidget {
  final Mission mission;
  final Verificateur user;
  final VoidCallback? onDeleted;

  const MissionCard({
    super.key,
    required this.mission,
    required this.user,
    this.onDeleted,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  bool _isPressed = false;

  String _normalizeStatus(String status) {
    final s = status.toLowerCase().trim();
    if (s.contains('encour') || s.contains('en cours')) return 'En cours';
    if (s.contains('termine') || s.contains('terminé')) return 'Terminé';
    if (s.contains('attente')) return 'En attente';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Color _getStatusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'En attente':
        return const Color(0xFFD97706); // Orange Ambre
      case 'En cours':
        return const Color(0xFF2563EB); // Bleu Royal
      default:
        return const Color(0xFF059669); // Vert Émeraude
    }
  }

  Color _getStatusBgColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'En attente':
        return const Color(0xFFFEF3C7);
      case 'En cours':
        return const Color(0xFFEFF6FF);
      default:
        return const Color(0xFFECFDF5);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (_normalizeStatus(status)) {
      case 'En attente':
        return Icons.schedule_rounded;
      case 'En cours':
        return Icons.sync_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  void _showMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              const Text('Éditer les infos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'export',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.file_upload_outlined, size: 18, color: AppTheme.darkBlue),
              const SizedBox(width: 10),
              const Text('Exporter la mission', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600),
              const SizedBox(width: 10),
              Text(
                'Supprimer',
                style: TextStyle(fontSize: 13, color: Colors.red.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == 'edit') _handleEdit(context);
      if (val == 'export') _handleExport(context);
      if (val == 'delete') _handleDelete(context);
    });
  }

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateMissionScreen(
          currentUser: widget.user,
          missionToEdit: widget.mission,
        ),
      ),
    );
    if (result == true) {
      widget.onDeleted?.call();
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Génération de l\'exportation…',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );

    final result = await BackupService.exporterMission(widget.mission.id);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Fermer le dialogue de chargement

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? (result.success ? 'Exportation réussie.' : 'Erreur exportation.'),
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Supprimer la mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'La mission "${widget.mission.nomClient}" sera déplacée dans la Corbeille. Vous pourrez la restaurer à tout moment.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('DÉPLACER À LA CORBEILLE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await TrashService.moveMissionToTrash(
      widget.mission,
      deletedBy: widget.user.nom,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.orange.shade800 : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    if (result.success) widget.onDeleted?.call();
  }

  Widget _buildLogoWidget() {
    final logoPath = widget.mission.logoClient;
    if (logoPath != null && logoPath.isNotEmpty) {
      Widget imageWidget;
      if (logoPath.startsWith('http')) {
        imageWidget = Image.network(
          logoPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackLogo(),
        );
      } else {
        final file = File(logoPath);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: BoxFit.contain,
          );
        } else {
          return _buildFallbackLogo();
        }
      }

      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Center(child: imageWidget),
        ),
      );
    }
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    final initials = widget.mission.nomClient.trim().isNotEmpty
        ? (widget.mission.nomClient.trim().length >= 2
            ? widget.mission.nomClient.trim().substring(0, 2).toUpperCase()
            : widget.mission.nomClient.trim().substring(0, 1).toUpperCase())
        : 'MI';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.darkBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.mission.status);
    final statusBgColor = _getStatusBgColor(widget.mission.status);
    final statusIcon = _getStatusIcon(widget.mission.status);
    final normalizedStatus = _normalizeStatus(widget.mission.status);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF334155)
                : statusColor.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MissionHubScreen(
                  mission: widget.mission,
                  user: widget.user,
                ),
              ),
            ).then((_) => widget.onDeleted?.call()),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête : Logo/Initiales + Titre/Activité + Menu 3 dots
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Logo Client
                      _buildLogoWidget(),
                      const SizedBox(width: 14),

                      // Informations Principales Client & Site
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mission.nomClient,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode ? Colors.white : AppTheme.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (widget.mission.nomSite != null &&
                                widget.mission.nomSite!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.mission.nomSite!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Bouton Menu 3-dots (Éditer / Exporter / Supprimer)
                      GestureDetector(
                        onTapDown: (details) => _showMenu(context, details.globalPosition),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // Ligne du bas : Badges de Nature & Statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Nature de la vérification
                      if (widget.mission.natureMission != null &&
                          widget.mission.natureMission!.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.mission.natureMission!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      const SizedBox(width: 8),

                      // Badge de Statut (En cours / En attente / Terminée)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              normalizedStatus == 'Terminé' ? 'Terminée' : normalizedStatus,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
