// lib/pages/missions/mission_detail_screen.dart
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentMission = widget.mission;
  }

  Future<void> _updateMissionStatus(String newStatus) async {
    setState(() => _isLoading = true);
    
    final success = await HiveService.updateMissionStatus(
      missionId: _currentMission.id,
      newStatus: newStatus,
    );
    
    if (success) {
      setState(() {
        _currentMission.status = newStatus;
        _currentMission.updatedAt = DateTime.now();
      });
    }
    
    setState(() => _isLoading = false);
  }

  String _getButtonText() {
    if (_currentMission.isEnAttente) {
      return 'DÉBUTER';
    } else if (_currentMission.isEnCours) {
      return 'CONTINUER';
    } else {
      return 'VOIR LE RAPPORT';
    }
  }

  IconData _getButtonIcon() {
    if (_currentMission.isEnAttente) {
      return Icons.play_arrow;
    } else if (_currentMission.isEnCours) {
      return Icons.play_circle_filled;
    } else {
      return Icons.assessment;
    }
  }

  Color _getStatusColor() {
    if (_currentMission.isEnAttente) {
      return Colors.orange;
    } else if (_currentMission.isEnCours) {
      return AppTheme.primaryBlue;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (_currentMission.isEnAttente) {
      return 'EN ATTENTE';
    } else if (_currentMission.isEnCours) {
      return 'EN COURS';
    } else {
      return 'TERMINÉ';
    }
  }

  Future<void> _handleMainAction() async {
    if (_currentMission.isEnAttente) {
      // Passer de "en_attente" à "en_cours"
      await _updateMissionStatus('en_cours');
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SequenceScreen(
              mission: _currentMission,
              user: widget.user,
            ),
          ),
        ).then((_) {
          // Rafraîchir la mission au retour
          _refreshMission();
        });
      }
    } else if (_currentMission.isEnCours) {
      // Continuer la mission
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SequenceScreen(
            mission: _currentMission,
            user: widget.user,
          ),
        ),
      ).then((_) {
        _refreshMission();
      });
    } else {
      // Mission terminée - Voir/Générer le rapport
      _generateReport();
    }
  }

  void _refreshMission() {
    final refreshedMission = HiveService.getMissionById(_currentMission.id);
    if (refreshedMission != null) {
      setState(() {
        _currentMission = refreshedMission;
      });
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
      final file = await PdfReportService.generateMissionReport(_currentMission.id);

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
                subject: 'Rapport - ${_currentMission.nomClient}',
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec couleur dynamique
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: statusColor,
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor,
                      statusColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
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
                          _getStatusText(),
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
                // Bouton principal
                _buildMainButton(statusColor),
                
                const SizedBox(height: 16),
                
                // Carte d'informations
                _buildInfoCard(),
                
                const SizedBox(height: 16),
                
                // Carte de l'équipe
                _buildTeamCard(),
                
                const SizedBox(height: 24),
                
                // Bouton Générer rapport PDF (toujours visible)
                _buildPdfButton(),
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(Color statusColor) {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();

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
        onPressed: _isLoading ? null : _handleMainAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
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
                overflow: TextOverflow.ellipsis,
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