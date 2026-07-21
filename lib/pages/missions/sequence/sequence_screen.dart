// lib/pages/missions/sequence/sequence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/audit_installations.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/foudre_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/moyenne_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/mesures_essais_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

import 'package:inspec_app/pages/missions/sequence/steps/general_info_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/documents_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/description_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/audit_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/schema_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/summary_step.dart';


// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES INTERNES POUR LE SOMMAIRE DE NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────
class _Sub {
  final String key;
  final String label;
  final IconData icon;
  final int? descSectionIndex;
  final bool isAuditNav;

  const _Sub({
    required this.key,
    required this.label,
    required this.icon,
    this.descSectionIndex,
    this.isAuditNav = false,
  });
}

class _Item {
  final int stepIndex;
  final String title;
  final IconData icon;
  final bool isRequired;
  final bool hasSubs;
  final List<_Sub> subs;

  const _Item({
    required this.stepIndex,
    required this.title,
    required this.icon,
    this.isRequired = false,
    this.hasSubs = false,
    this.subs = const [],
  });
}

const List<_Item> _items = [
  _Item(
    stepIndex: 0,
    title: 'Renseignements généraux',
    icon: Icons.info_outline,
    isRequired: true,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 1,
    title: 'Documents nécessaires',
    icon: Icons.folder_outlined,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 2,
    title: 'Description des installations',
    icon: Icons.description_outlined,
    hasSubs: true,
    subs: [
      _Sub(
        key: 'alimentation_moyenne_tension',
        label: 'Alimentation MT',
        icon: Icons.bolt_outlined,
        descSectionIndex: 0,
      ),
      _Sub(
        key: 'alimentation_basse_tension',
        label: 'Alimentation BT',
        icon: Icons.electrical_services_outlined,
        descSectionIndex: 1,
      ),
      _Sub(
        key: 'groupe_electrogene',
        label: 'Groupe électrogène',
        icon: Icons.power_outlined,
        descSectionIndex: 2,
      ),
      _Sub(
        key: 'alimentation_carburant',
        label: 'Alimentation carburant',
        icon: Icons.local_gas_station_outlined,
        descSectionIndex: 3,
      ),
      _Sub(
        key: 'inverseur',
        label: 'Inverseur',
        icon: Icons.swap_horiz_outlined,
        descSectionIndex: 4,
      ),
      _Sub(
        key: 'stabilisateur',
        label: 'Stabilisateur',
        icon: Icons.tune_outlined,
        descSectionIndex: 5,
      ),
      _Sub(
        key: 'onduleurs',
        label: 'Onduleurs',
        icon: Icons.battery_charging_full_outlined,
        descSectionIndex: 6,
      ),
      _Sub(
        key: 'regime_neutre',
        label: 'Régime du neutre',
        icon: Icons.settings_ethernet_outlined,
        descSectionIndex: 7,
      ),
      _Sub(
        key: 'eclairage_securite',
        label: 'Éclairage de sécurité',
        icon: Icons.lightbulb_outline,
        descSectionIndex: 8,
      ),
      _Sub(
        key: 'modifications_installations',
        label: 'Modifications',
        icon: Icons.build_outlined,
        descSectionIndex: 9,
      ),
      _Sub(
        key: 'note_calcul',
        label: 'Notes de calcul',
        icon: Icons.calculate_outlined,
        descSectionIndex: 10,
      ),
      _Sub(
        key: 'paratonnerre',
        label: 'Paratonnerre',
        icon: Icons.thunderstorm_outlined,
        descSectionIndex: 11,
      ),
      _Sub(
        key: 'registre_securite',
        label: 'Registre de sécurité',
        icon: Icons.menu_book_outlined,
        descSectionIndex: 12,
      ),
    ],
  ),
  _Item(
    stepIndex: 3,
    title: 'Audit des installations',
    icon: Icons.electrical_services_outlined,
    hasSubs: true,
    subs: [
      _Sub(
        key: 'audit_mt',
        label: 'Moyenne tension',
        icon: Icons.high_quality_outlined,
        isAuditNav: true,
      ),
      _Sub(
        key: 'audit_bt',
        label: 'Basse tension',
        icon: Icons.low_priority_outlined,
        isAuditNav: true,
      ),
      _Sub(
        key: 'audit_foudre',
        label: 'Observations foudre',
        icon: Icons.thunderstorm_outlined,
        isAuditNav: true,
      ),
      _Sub(
        key: 'audit_mesures',
        label: 'Mesures et essais',
        icon: Icons.science_outlined,
        isAuditNav: true,
      ),
    ],
  ),
  _Item(
    stepIndex: 4,
    title: 'Schéma des installations',
    icon: Icons.schema_outlined,
    isRequired: true,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 5,
    title: 'Sommaire',
    icon: Icons.summarize_outlined,
    hasSubs: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SEQUENCE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SequenceScreen extends StatefulWidget {
  final Mission mission;
  final Verificateur user;
  final int initialStep;

  const SequenceScreen({
    super.key,
    required this.mission,
    required this.user,
    this.initialStep = 0,
  });

  @override
  State<SequenceScreen> createState() => _SequenceScreenState();
}

class _SequenceScreenState extends State<SequenceScreen>
    with SingleTickerProviderStateMixin {
  // ── Workflow ──
  late int _currentStep;
  late List<Map<String, dynamic>> _steps;
  late PageController _pageController;
  bool _isLoading = true;
  List<int> _completedSteps = [];

  // ── Drawer ──
  bool _drawerOpen = false;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  Set<int> _expandedSteps = {};

  // ── Complétion dynamique ──
  Map<String, bool> _descProgress = {};
  Map<String, bool> _auditProgress = {};

  // ── Keys ──
  final GlobalKey<GeneralInfoStepState> _generalInfoKey =
      GlobalKey<GeneralInfoStepState>();
  final GlobalKey<DescriptionStepState> _descKey =
      GlobalKey<DescriptionStepState>();

  // ═══════════════════════════════════════════════════════════
  //  INIT
  // ═══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _initAnim();
    _initializeSteps();
    _loadProgress();
    _ensureStatusIsEnCours();
  }

  void _initAnim() {
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  Future<void> _ensureStatusIsEnCours() async {
    if (widget.initialStep == 5) return;
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null && mission.isEnAttente) {
      await HiveService.updateMissionStatus(
        missionId: widget.mission.id,
        newStatus: 'en_cours',
      );
      widget.mission.status = 'en_cours';
    }
  }

  void _initializeSteps() {
    _steps = [
      {
        'title': 'Renseignements généraux',
        'widget': GeneralInfoStep(
          key: _generalInfoKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('general_info', data),
          onValidationChanged: (isValid) => setState(() {}),
        ),
      },
      {
        'title': 'Documents nécessaires',
        'widget': DocumentsStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('documents', data),
        ),
      },
      {
        'title': 'Description des installations',
        'widget': DescriptionStep(
          key: _descKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('description', data),
          onPreviousStep: _goToPreviousStep,
          onNextStep: _goToNextStep,
          onSubStepChanged: () => setState(() {}),
        ),
      },
      {
        'title': 'Audit des installations',
        'widget': AuditStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('audit', data),
        ),
      },
      {
        'title': 'Schéma des installations',
        'widget': SchemaStep(
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('schema', data),
        ),
      },
      {
        'title': 'Sommaire',
        'widget': SummaryStep(
          mission: widget.mission,
          user: widget.user,
          onDataChanged: (data) => _saveStepData('summary', data),
          onPrevious: _goToPreviousStep,
        ),
      },
    ];
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await SequenceProgressService.getProgress(
      widget.mission.id,
    );
    _completedSteps = List<int>.from(
      progress['completedSteps'] as List<dynamic>? ?? [],
    );

    var savedStep = progress['currentStep'] ?? 0;
    if (widget.initialStep > 0 && widget.initialStep < _steps.length) {
      savedStep = widget.initialStep;
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        savedStep,
      );
    } else if (savedStep >= _steps.length) {
      savedStep = _steps.length - 1;
    }

    _currentStep = savedStep;
    _pageController = PageController(initialPage: _currentStep);

    await _refreshSubProgress();
    setState(() => _isLoading = false);
  }

  // ── Rafraîchit tout depuis Hive ──────────────────────────────────────────
  Future<void> _refreshSubProgress() async {
    // Description (Étape 2)
    _descProgress = await HiveService.getMissionProgress(widget.mission.id);
    final descHasData = _descProgress.values.any((v) => v);
    if (descHasData && !_completedSteps.contains(2)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 2);
      _completedSteps.add(2);
    }

    // Audit (Étape 3)
    final audit = HiveService.getAuditInstallationsByMissionId(
      widget.mission.id,
    );
    final foudres = HiveService.getFoudreObservationsByMissionId(
      widget.mission.id,
    );
    final mesures = HiveService.getMesuresEssaisByMissionId(widget.mission.id);

    final auditMt =
        audit != null &&
        (audit.moyenneTensionLocaux.isNotEmpty ||
            audit.moyenneTensionZones.isNotEmpty);
    final auditBt = audit != null && audit.basseTensionZones.isNotEmpty;
    final auditFoudre = foudres.isNotEmpty;
    final auditMesures = mesures != null;

    _auditProgress = {
      'audit_mt': auditMt,
      'audit_bt': auditBt,
      'audit_foudre': auditFoudre,
      'audit_mesures': auditMesures,
    };

    final auditHasData = auditMt || auditBt || auditFoudre || auditMesures;
    if (auditHasData && !_completedSteps.contains(3)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 3);
      _completedSteps.add(3);
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveStepData(String stepKey, dynamic data) async {
    await SequenceProgressService.saveStepData(
      widget.mission.id,
      stepKey,
      data,
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // ── Gestion du Drawer ───────────────────────────────────────────────────
  void _toggleDrawer() {
    _dismissKeyboard();
    if (_drawerOpen) {
      _closeDrawer();
    } else {
      _refreshSubProgress().then((_) {
        _expandedSteps.clear();
        final currentItem = _items.firstWhere(
          (i) => i.stepIndex == _currentStep,
          orElse: () => _items.first,
        );
        if (currentItem.hasSubs) {
          _expandedSteps.add(_currentStep);
        }
        setState(() => _drawerOpen = true);
        _animCtrl.forward();
      });
    }
  }

  void _closeDrawer() {
    if (!_drawerOpen) return;
    setState(() => _drawerOpen = false);
    _animCtrl.reverse();
  }

  // ── Vérifications des blocages ──────────────────────────────────────────
  bool get _renseignementsComplete =>
      _generalInfoKey.currentState?.isFormValid ?? _completedSteps.contains(0);

  bool get _schemaComplete {
    final mission = HiveService.getMissionById(widget.mission.id);
    return mission?.schemaOption != null;
  }

  String? _blockMessage(int targetStep) {
    if (targetStep >= 1 && !_renseignementsComplete) {
      return 'Les Renseignements généraux doivent être complétés.';
    }
    if (targetStep == 5 && !_schemaComplete) {
      return 'Le Schéma des installations doit être renseigné avant d\'accéder au Sommaire.';
    }
    return null;
  }

  Future<void> _navigateToStep(int stepIndex) async {
    final block = _blockMessage(stepIndex);
    if (block != null) {
      _closeDrawer();
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(block, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    if (stepIndex != _currentStep) {
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
      setState(() => _currentStep = stepIndex);
      _pageController.jumpToPage(stepIndex);
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        stepIndex,
      );
    }
  }

  void _navigateToDescSub(int subIndex) {
    _navigateToStep(2).then((_) {
      _descKey.currentState?.jumpToSection(subIndex);
    });
  }

  void _navigateToAuditSub(String subKey) {
    _navigateToStep(3).then((_) {
      Widget targetScreen;
      switch (subKey) {
        case 'audit_mt':
          targetScreen = MoyenneTensionScreen(mission: widget.mission);
          break;
        case 'audit_bt':
          targetScreen = BasseTensionScreen(mission: widget.mission);
          break;
        case 'audit_foudre':
          targetScreen = FoudreScreen(mission: widget.mission);
          break;
        case 'audit_mesures':
          targetScreen = MesuresEssaisScreen(mission: widget.mission);
          break;
        default:
          targetScreen = AuditInstallationsScreen(mission: widget.mission);
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => targetScreen,
        ),
      );
    });
  }

  // ── Dialogue de confirmation de sortie ──────────────────────────────────
  Future<void> _showExitDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 24),
            SizedBox(width: 10),
            Text('Quitter l\'inspection ?', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Toutes vos modifications sont automatiquement enregistrées.\nVous pourrez reprendre à tout moment.',
          style: TextStyle(fontSize: 14, color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CONTINUER',
              style: TextStyle(color: AppTheme.greyDark),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ── Navigation générale ────────────────────────────────────────────────
  Future<void> _goToNextStep() async {
    _dismissKeyboard();
    _closeDrawer();

    if (_currentStep == 0) {
      _generalInfoKey.currentState?.triggerValidation();
      final isValid = _generalInfoKey.currentState?.isFormValid ?? false;
      if (!isValid) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez remplir tous les champs obligatoires (marqués en rouge)',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    if (_currentStep == 2) {
      final descState = _descKey.currentState;
      if (descState != null) {
        final handled = descState.next();
        if (handled) return;
      }
    }

    if (_currentStep == 4 && !_schemaComplete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez sélectionner Oui ou Non pour le schéma des installations',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_currentStep < _steps.length - 1) {
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
      await SequenceProgressService.markStepCompleted(
        widget.mission.id,
        _currentStep,
      );
      if (!_completedSteps.contains(_currentStep)) {
        setState(() => _completedSteps.add(_currentStep));
      }

      setState(() => _currentStep++);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
    }
  }

  Future<void> _goToPreviousStep() async {
    _dismissKeyboard();
    _closeDrawer();

    if (_currentStep == 2) {
      final descState = _descKey.currentState;
      if (descState != null) {
        final handled = descState.previous();
        if (handled) return;
      }
    }

    if (_currentStep > 0) {
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
      setState(() => _currentStep--);
      final bool jump = (_currentStep + 1) == 2 && _currentStep == 1;
      if (jump) {
        _pageController.jumpToPage(_currentStep);
      } else {
        await _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentStep >= _steps.length) _currentStep = _steps.length - 1;

    final title = _steps[_currentStep]['title'] as String;
    final total = _steps.length;
    final isLast = _currentStep == total - 1;

    return GestureDetector(
      onTap: _drawerOpen ? _closeDrawer : null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _drawerOpen
                  ? const Icon(
                      Icons.close,
                      key: ValueKey('c'),
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.menu_book_outlined,
                      key: ValueKey('o'),
                      color: Colors.white,
                    ),
            ),
            tooltip: 'Sommaire',
            onPressed: _toggleDrawer,
          ),
          actions: [
            if (_currentStep != 5)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Quitter',
                onPressed: () {
                  _dismissKeyboard();
                  _closeDrawer();
                  _showExitDialog();
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / total,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.3),
                  color: Colors.white,
                  minHeight: 4,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _steps.map((s) => s['widget'] as Widget).toList(),
                  ),
                ),
                if (_currentStep != 5) _buildNavButtons(isLast),
              ],
            ),

            if (_drawerOpen)
              FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),

            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0),
                  end: Offset.zero,
                ).animate(_slideAnim),
                child: GestureDetector(
                  onTap: () {},
                  child: _buildDrawer(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButtons(bool isLast) {
    bool showPrevious = _currentStep > 0;
    String nextLabel = isLast ? 'TERMINER' : 'SUIVANT';

    if (_currentStep == 2) {
      final descState = _descKey.currentState;
      if (descState != null) {
        if (descState.isLastSlide) {
          nextLabel = 'Audit';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showPrevious) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'PRÉCÉDENT',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer UI ────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final drawerWidth = (size.width * 0.82).clamp(280.0, 360.0);

    return Container(
      width: drawerWidth,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _items.length,
                itemBuilder: (ctx, idx) => _buildDrawerItem(_items[idx]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOMMAIRE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Navigation du rapport',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: _closeDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(_Item item) {
    final isCurrent = item.stepIndex == _currentStep;
    final isDone = _completedSteps.contains(item.stepIndex);
    final blocked = _blockMessage(item.stepIndex) != null;
    final isExpanded = _expandedSteps.contains(item.stepIndex);

    Color iconColor;
    Color textColor;
    FontWeight fontWeight;
    Color tileBg;

    if (isCurrent) {
      iconColor = AppTheme.primaryBlue;
      textColor = AppTheme.primaryBlue;
      fontWeight = FontWeight.w700;
      tileBg = AppTheme.primaryBlue.withOpacity(0.08);
    } else if (blocked) {
      iconColor = Colors.grey.shade300;
      textColor = Colors.grey.shade400;
      fontWeight = FontWeight.normal;
      tileBg = Colors.transparent;
    } else if (isDone) {
      iconColor = Colors.green.shade600;
      textColor = Colors.black87;
      fontWeight = FontWeight.w500;
      tileBg = Colors.transparent;
    } else {
      iconColor = Colors.grey.shade500;
      textColor = Colors.grey.shade700;
      fontWeight = FontWeight.normal;
      tileBg = Colors.transparent;
    }

    return Column(
      children: [
        Material(
          color: tileBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: blocked ? null : () => _navigateToStep(item.stepIndex),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.primaryBlue.withOpacity(0.15)
                          : isDone
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone && !isCurrent
                          ? Icons.check_rounded
                          : blocked
                              ? Icons.lock_outline_rounded
                              : item.icon,
                      size: 17,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: fontWeight,
                            ),
                          ),
                        ),
                        if (item.isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.hasSubs && !blocked)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isCurrent ? AppTheme.primaryBlue : Colors.grey.shade500,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedSteps.remove(item.stepIndex);
                          } else {
                            _expandedSteps.add(item.stepIndex);
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 28, height: 28),
                    )
                  else if (!blocked && !isCurrent && !isDone)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
            ),
          ),
        ),

        if (item.hasSubs)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSubs(item),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildSubs(_Item item) {
    return Container(
      margin: const EdgeInsets.only(left: 38, right: 12, bottom: 6, top: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        children: item.subs.map((sub) {
          bool subComplete = false;
          if (sub.descSectionIndex != null) {
            subComplete = _descProgress[sub.key] ?? false;
          } else if (sub.isAuditNav) {
            subComplete = _auditProgress[sub.key] ?? false;
          }

          final blocked = _blockMessage(item.stepIndex) != null;
          final subColor = blocked
              ? Colors.grey.shade300
              : subComplete
                  ? Colors.green.shade600
                  : Colors.grey.shade500;

          return InkWell(
            onTap: blocked
                ? null
                : () {
                    if (sub.descSectionIndex != null) {
                      _navigateToDescSub(sub.descSectionIndex!);
                    } else if (sub.isAuditNav) {
                      _navigateToAuditSub(sub.key);
                    }
                  },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: subComplete
                    ? Colors.green.withOpacity(0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    subComplete ? Icons.check_circle_rounded : sub.icon,
                    size: 15,
                    color: subColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sub.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: blocked
                            ? Colors.grey.shade400
                            : subComplete
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                        fontWeight: subComplete
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!blocked)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
