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
    await _updateMissionStatus('en_cours');
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SequenceScreen(
            mission: _currentMission,
            user: widget.user,
            initialStep: 0,
          ),
        ),
      ).then((_) {
        _refreshMission();
      });
    }
  } else if (_currentMission.isEnCours) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SequenceScreen(
          mission: _currentMission,
          user: widget.user,
          initialStep: 0,
        ),
      ),
    ).then((_) {
      _refreshMission();
    });
  } else {
    // ✅ Mission terminée - Aller au résumé (étape 6)
    _goToSummaryStep();
  }
}

  void _goToSummaryStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SequenceScreen(
          mission: _currentMission,
          user: widget.user,
          initialStep: 6,
        ),
      ),
    ).then((_) {
      _refreshMission();
    });
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
    // Récupération des dimensions de l'écran pour la responsivité
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    
    // Calcul dynamique de la hauteur de l'appbar
    final appBarExpandedHeight = screenHeight * 0.28; // 28% de la hauteur de l'écran
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec couleur dynamique et hauteur responsive
          SliverAppBar(
            expandedHeight: appBarExpandedHeight,
            pinned: true,
            backgroundColor: statusColor,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: isSmallScreen ? 20 : 24, color: Colors.white),
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
                      // Espacement dynamique pour le status bar
                      SizedBox(height: MediaQuery.of(context).padding.top + (isSmallScreen ? 20 : 30)),
                      Container(
                        width: isSmallScreen ? 60 : 80,
                        height: isSmallScreen ? 60 : 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in,
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Gestion du débordement du texte du client
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _currentMission.nomClient,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : (isLargeScreen ? 28 : 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12, 
                          vertical: isSmallScreen ? 2 : 4
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
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

          // Contenu principal avec padding responsive
          SliverPadding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Bouton principal
                _buildMainButton(statusColor, isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Carte d'informations
                _buildInfoCard(isSmallScreen, isLargeScreen),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Carte de l'équipe
                _buildTeamCard(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 20 : 24),
                
                // Bouton Générer rapport PDF (toujours visible)
                _buildPdfButton(isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(Color statusColor, bool isSmallScreen) {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
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
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          ),
          padding: EdgeInsets.zero, // Important pour éviter les contraintes fixes
        ),
        child: _isLoading
            ? SizedBox(
                width: isSmallScreen ? 20 : 24,
                height: isSmallScreen ? 20 : 24,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, size: isSmallScreen ? 20 : 24),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPdfButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 46 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
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
        icon: Icon(Icons.picture_as_pdf, size: isSmallScreen ? 18 : 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'GÉNÉRER RAPPORT PDF',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.5
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isSmallScreen, bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                topRight: Radius.circular(isSmallScreen ? 16 : 20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.info_outline, 
                    size: isSmallScreen ? 18 : 20, 
                    color: AppTheme.primaryBlue
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Text(
                  'Informations générales',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Client',
                  value: _currentMission.nomClient,
                  isSmallScreen: isSmallScreen,
                ),
                Divider(height: isSmallScreen ? 20 : 24),
                if (_currentMission.activiteClient != null) ...[
                  _buildInfoRow(
                    icon: Icons.work,
                    label: 'Activité',
                    value: _currentMission.activiteClient!,
                    isSmallScreen: isSmallScreen,
                  ),
                  Divider(height: isSmallScreen ? 20 : 24),
                ],
                if (_currentMission.nomSite != null) ...[
                  _buildInfoRow(
                    icon: Icons.location_city,
                    label: 'Site',
                    value: _currentMission.nomSite!,
                    isSmallScreen: isSmallScreen,
                  ),
                  Divider(height: isSmallScreen ? 20 : 24),
                ],
                if (_currentMission.adresseClient != null) ...[
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: _currentMission.adresseClient!,
                    multiline: true,
                    isSmallScreen: isSmallScreen,
                  ),
                  Divider(height: isSmallScreen ? 20 : 24),
                ],
                _buildInfoRow(
                  icon: Icons.description,
                  label: 'Nature',
                  value: _currentMission.natureMission ?? 'Non spécifiée',
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(bool isSmallScreen) {
    final hasVerificateurs = _currentMission.verificateurs != null && _currentMission.verificateurs!.isNotEmpty;
    final hasAccompagnateurs = _currentMission.accompagnateurs != null && _currentMission.accompagnateurs!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                topRight: Radius.circular(isSmallScreen ? 16 : 20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.people, 
                    size: isSmallScreen ? 18 : 20, 
                    color: Colors.orange
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Text(
                  'Équipe',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                if (hasVerificateurs)
                  _buildTeamRow(
                    icon: Icons.verified_user,
                    label: 'Vérificateurs',
                    values: _currentMission.verificateurs!
                        .map((v) => '${v['prenom']} ${v['nom']} (${v['matricule']})')
                        .toList(),
                    isSmallScreen: isSmallScreen,
                  ),
                if (hasVerificateurs && hasAccompagnateurs) 
                  SizedBox(height: isSmallScreen ? 12 : 16),
                if (hasAccompagnateurs)
                  _buildTeamRow(
                    icon: Icons.person_add,
                    label: 'Accompagnateurs',
                    values: _currentMission.accompagnateurs!,
                    isSmallScreen: isSmallScreen,
                  ),
                if (!hasVerificateurs && !hasAccompagnateurs)
                  Text(
                    'Aucune information d\'équipe',
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: isSmallScreen ? 12 : 14
                    ),
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
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: isSmallScreen ? 32 : 36,
          height: isSmallScreen ? 32 : 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          child: Icon(
            icon, 
            size: isSmallScreen ? 16 : 18, 
            color: AppTheme.primaryBlue
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12, 
                  color: Colors.grey.shade600
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14, 
                  fontWeight: FontWeight.w500
                ),
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
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isSmallScreen ? 32 : 36,
          height: isSmallScreen ? 32 : 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          child: Icon(
            icon, 
            size: isSmallScreen ? 16 : 18, 
            color: Colors.grey.shade600
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12, 
                  color: Colors.grey.shade600
                ),
              ),
              SizedBox(height: isSmallScreen ? 3 : 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: values.map((v) => Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 3 : 4),
                  child: Text(
                    '• $v',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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