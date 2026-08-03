import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/pages/missions/sequence/sequence_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:share_plus/share_plus.dart';

/// Page de détails d'une mission avec refonte visuelle premium
/// et gestion intelligente des workflows d'exécution et de rapport.
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

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with SingleTickerProviderStateMixin {
  late Mission _currentMission;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentMission = widget.mission;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

  /// Intitulé du bouton principal (DÉBUTER LA MISSION / CONTINUER LA MISSION / VOIR LA MISSION)
  String _getButtonText() {
    if (_currentMission.isEnAttente) {
      return 'DÉBUTER LA MISSION';
    } else if (_currentMission.isEnCours) {
      return 'CONTINUER LA MISSION';
    } else {
      return 'VOIR LA MISSION';
    }
  }

  IconData _getButtonIcon() {
    if (_currentMission.isEnAttente) {
      return Icons.play_arrow_rounded;
    } else if (_currentMission.isEnCours) {
      return Icons.play_circle_fill_rounded;
    } else {
      return Icons.visibility_rounded;
    }
  }

  Color _getStatusColor() {
    if (_currentMission.isEnAttente) {
      return const Color(0xFFF59E0B); // Amber / Orange
    } else if (_currentMission.isEnCours) {
      return AppTheme.primaryBlue; // Bleu marque
    } else {
      return const Color(0xFF10B981); // Emerald / Vert
    }
  }

  String _getStatusText() {
    if (_currentMission.isEnAttente) {
      return 'EN ATTENTE';
    } else if (_currentMission.isEnCours) {
      return 'EN COURS';
    } else {
      return 'TERMINÉE';
    }
  }

  /// Action sur le bouton principal (DÉBUTER / CONTINUER / VOIR LA MISSION)
  /// Ramène l'inspecteur exactement au dernier endroit où il était dans la mission.
  Future<void> _handleMainAction() async {
    setState(() => _isLoading = true);

    final progress = await SequenceProgressService.getProgress(_currentMission.id);
    final lastStep = (progress['currentStep'] as int?) ?? 0;

    if (_currentMission.isEnAttente) {
      await _updateMissionStatus('en_cours');
    }

    setState(() => _isLoading = false);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SequenceScreen(
            mission: _currentMission,
            user: widget.user,
            initialStep: lastStep,
          ),
        ),
      );
      _refreshMission();
    }
  }

  /// Navigation explicite vers l'étape de synthèse (Summary Step - Étape 5)
  void _goToSummaryStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SequenceScreen(
          mission: _currentMission,
          user: widget.user,
          initialStep: 5,
        ),
      ),
    ).then((_) => _refreshMission());
  }

  /// Action du bouton "GÉNÉRER LE RAPPORT"
  /// - Si la mission est Terminée -> Redirection vers Summary Step (Étape 6)
  /// - Si la mission est En cours / En attente -> Génération directe du PDF intermédiaire
  Future<void> _handleReportAction() async {
    if (_currentMission.isTermine) {
      _goToSummaryStep();
    } else {
      await _generateIntermediateReport();
    }
  }

  /// Génération intermédiaire du rapport PDF pour les missions en cours
  Future<void> _generateIntermediateReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Génération du rapport intermédiaire PDF...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Veuillez patienter quelques instants',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Rapport généré !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Le rapport PDF intermédiaire représentant l\'état actuel de la mission a été généré avec succès.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(file.path)],
                subject: 'Rapport - ${_currentMission.nomClient}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Partager', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _refreshMission() {
    final refreshedMission = HiveService.getMissionById(_currentMission.id);
    if (refreshedMission != null) {
      setState(() {
        _currentMission = refreshedMission;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 360;

    final appBarExpandedHeight = screenHeight * 0.28;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. En-tête SliverAppBar Moderne avec Dégradé Dynamique
            SliverAppBar(
              expandedHeight: appBarExpandedHeight,
              pinned: true,
              backgroundColor: statusColor,
              elevation: 0,
              leading: Container(
                margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
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
                        Color.lerp(statusColor, Colors.black, 0.25)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Motifs de fond géométriques subtils
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Icon(
                          Icons.assignment_rounded,
                          size: 180,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: mediaQuery.padding.top + (isSmallScreen ? 10 : 20)),
                            Container(
                              width: isSmallScreen ? 56 : 72,
                              height: isSmallScreen ? 56 : 72,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _currentMission.isTermine
                                    ? Icons.task_alt_rounded
                                    : Icons.engineering_rounded,
                                size: isSmallScreen ? 28 : 36,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                _currentMission.nomClient,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusText(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Contenu principal de la page
            SliverPadding(
              padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Bouton Action Principal (DÉBUTER / CONTINUER / VOIR LA MISSION)
                  _buildMainButton(statusColor, isSmallScreen),

                  const SizedBox(height: 16),

                  // Bouton "GÉNÉRER LE RAPPORT" (avec comportement dynamique)
                  if (!_currentMission.isEnAttente) ...[
                    _buildReportButton(isSmallScreen),
                    const SizedBox(height: 20),
                  ],

                  // Carte d'informations Générales
                  _buildInfoCard(isSmallScreen),

                  const SizedBox(height: 16),

                  // Carte de l'Équipe d'Inspection
                  _buildTeamCard(isSmallScreen),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton Action Principal (DÉBUTER / CONTINUER / VOIR LA MISSION)
  Widget _buildMainButton(Color statusColor, bool isSmallScreen) {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, Color.lerp(statusColor, Colors.black, 0.15)!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.35),
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
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, size: 24, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Bouton "GÉNÉRER LE RAPPORT"
  /// Redirige vers Summary Step si Terminée, ou Génère un PDF Intermédiaire si En cours.
  Widget _buildReportButton(bool isSmallScreen) {
    final isFinished = _currentMission.isTermine;
    final labelText = isFinished ? 'PRÉPARER & GÉRER LE RAPPORT' : 'GÉNÉRER LE RAPPORT';
    final subText = isFinished
        ? 'Accéder strictement au résumé et à la préparation finale'
        : 'Générer directement un rapport PDF intermédiaire';

    final btnColor = isFinished ? AppTheme.primaryBlue : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: btnColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: btnColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _handleReportAction,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: btnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFinished ? Icons.summarize_rounded : Icons.picture_as_pdf_rounded,
                    color: btnColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labelText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: btnColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: btnColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Carte "Informations Générales"
  Widget _buildInfoCard(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: 10),
                Text(
                  'Informations générales',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.business_rounded,
                  label: 'Client',
                  value: _currentMission.nomClient,
                ),
                if (_currentMission.activiteClient != null &&
                    _currentMission.activiteClient!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.work_outline_rounded,
                    label: 'Activité',
                    value: _currentMission.activiteClient!,
                  ),
                ],
                if (_currentMission.nomSite != null &&
                    _currentMission.nomSite!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.location_city_rounded,
                    label: 'Site d\'inspection',
                    value: _currentMission.nomSite!,
                  ),
                ],
                if (_currentMission.adresseClient != null &&
                    _currentMission.adresseClient!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.place_outlined,
                    label: 'Adresse',
                    value: _currentMission.adresseClient!,
                    multiline: true,
                  ),
                ],
                const Divider(height: 20),
                _buildInfoRow(
                  icon: Icons.assignment_outlined,
                  label: 'Nature de la mission',
                  value: _currentMission.natureMission ?? 'Non spécifiée',
                ),
                if (_currentMission.perimetreMission != null &&
                    _currentMission.perimetreMission!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.domain_verification_rounded,
                    label: 'Périmètre de vérification',
                    value: _currentMission.perimetreMission!.join(', '),
                    multiline: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte "Équipe d'Inspection"
  Widget _buildTeamCard(bool isSmallScreen) {
    final hasVerificateurs =
        _currentMission.verificateurs != null && _currentMission.verificateurs!.isNotEmpty;
    final hasAccompagnateurs =
        _currentMission.accompagnateurs != null && _currentMission.accompagnateurs!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 10),
                Text(
                  'Équipe d\'inspection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
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
                    icon: Icons.verified_user_rounded,
                    label: 'Vérificateurs habilités',
                    values: _currentMission.verificateurs!
                        .map((v) => '${v['prenom']} ${v['nom']} (${v['matricule']})')
                        .toList(),
                    color: AppTheme.primaryBlue,
                  ),
                if (hasVerificateurs && hasAccompagnateurs) const Divider(height: 20),
                if (hasAccompagnateurs)
                  _buildTeamRow(
                    icon: Icons.person_pin_rounded,
                    label: 'Accompagnateurs du client',
                    values: _currentMission.accompagnateurs!,
                    color: Colors.indigo.shade600,
                  ),
                if (!hasVerificateurs && !hasAccompagnateurs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Aucune information d\'équipe enregistrée',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
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
  }) {
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
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
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
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
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: values
                    .map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $v',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}