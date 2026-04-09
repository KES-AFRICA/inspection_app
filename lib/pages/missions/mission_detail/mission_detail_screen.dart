import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/home_screen.dart';
import 'package:inspec_app/pages/missions/sequence/sequence_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:share_plus/share_plus.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;

  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.user,
  });

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  late Mission _currentMission;
  late Map<String, dynamic> _sequenceProgress;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _currentMission = widget.mission;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    // TODO: Charger la progression depuis SequenceProgressService
    setState(() => _isLoadingProgress = false);
  }

  void _handleStatusChanged(String newStatus) {
    setState(() {
      _currentMission.status = newStatus;
      _currentMission.updatedAt = DateTime.now();
    });
    
    HiveService.updateMissionStatus(
      missionId: _currentMission.id,
      newStatus: newStatus,
    );
  }

  String _getButtonText() {
    switch (_currentMission.status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return 'CONTINUER';
      case 'termine':
      case 'terminé':
        return 'VOIR LE RAPPORT';
      default:
        return 'DÉMARRER';
    }
  }

  IconData _getButtonIcon() {
    switch (_currentMission.status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return Icons.play_circle_filled;
      case 'termine':
      case 'terminé':
        return Icons.assessment;
      default:
        return Icons.play_arrow;
    }
  }

  void _handleMainAction() {
    if (_currentMission.status.toLowerCase() == 'terminé' || 
        _currentMission.status.toLowerCase() == 'termine') {
      _generateReport();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SequenceScreen(
            mission: _currentMission,
            user: widget.user,
          ),
        ),
      );
    }
  }

  Future<void> _generateReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Génération du rapport PDF en cours...'),
          ],
        ),
      ),
    );

    try {
      final file = await PdfReportService.generateMissionReport(widget.mission.id);

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (file != null && file.existsSync()) {
        _showSuccessDialog(file);
      } else {
        _showError('Erreur lors de la génération du rapport');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Erreur: $e');
    }
  }

  void _showSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rapport généré !'),
        content: const Text('Le rapport a été généré avec succès.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(file.path)],
                subject: 'Rapport - ${widget.mission.nomClient}',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor() {
    switch (_currentMission.status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return Colors.orange;
      case 'termine':
      case 'terminé':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // AppBar moderne
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _getStatusColor(),
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(),
                      _getStatusColor().withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in,
                          size: 40,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentMission.nomClient,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentMission.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Carte d'informations modernes
                _buildInfoCard(),
                const SizedBox(height: 16),
                
                // Carte de l'équipe
                _buildTeamCard(),
                const SizedBox(height: 24),
                
                // Bouton principal (Démarrer/Continuer/Voir rapport)
                _buildMainButton(),
                
                // Bouton Générer rapport PDF
                const SizedBox(height: 12),
                _buildPdfButton(),
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Client',
                  value: _currentMission.nomClient,
                ),
                const Divider(height: 24),
                if (_currentMission.activiteClient != null)
                  _buildInfoRow(
                    icon: Icons.work,
                    label: 'Activité',
                    value: _currentMission.activiteClient!,
                  ),
                if (_currentMission.activiteClient != null) const Divider(height: 24),
                if (_currentMission.adresseClient != null)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: _currentMission.adresseClient!,
                    multiline: true,
                  ),
                if (_currentMission.adresseClient != null) const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.description,
                  label: 'Nature',
                  value: _currentMission.natureMission ?? 'Non spécifiée',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard() {
    final hasVerificateurs = _currentMission.verificateurs != null && _currentMission.verificateurs!.isNotEmpty;
    final hasAccompagnateurs = _currentMission.accompagnateurs != null && _currentMission.accompagnateurs!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Équipe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (hasVerificateurs)
                  _buildTeamRow(
                    icon: Icons.verified_user,
                    label: 'Vérificateurs',
                    values: _currentMission.verificateurs!
                        .map((v) => '${v['prenom']} ${v['nom']} (${v['matricule']})')
                        .toList(),
                  ),
                if (hasVerificateurs && hasAccompagnateurs) const SizedBox(height: 16),
                if (hasAccompagnateurs)
                  _buildTeamRow(
                    icon: Icons.person_add,
                    label: 'Accompagnateurs',
                    values: _currentMission.accompagnateurs!,
                  ),
                if (!hasVerificateurs && !hasAccompagnateurs)
                  const Text(
                    'Aucune information d\'équipe',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();
    final statusColor = _getStatusColor();

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleMainAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(buttonIcon, size: 24),
            const SizedBox(width: 12),
            Text(
              buttonText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateReport,
        icon: const Icon(Icons.picture_as_pdf, size: 22),
        label: const Text(
          'GÉNÉRER RAPPORT PDF',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: multiline ? 3 : 1,
                overflow: multiline ? TextOverflow.ellipsis : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow({
    required IconData icon,
    required String label,
    required List<String> values,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: values.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $v',
                    style: const TextStyle(fontSize: 13),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}