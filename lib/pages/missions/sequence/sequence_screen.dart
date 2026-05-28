// lib/pages/missions/sequence/sequence_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/pages/missions/sequence/steps/general_info_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/jsa_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/documents_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/description_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/audit_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/schema_step.dart';
import 'package:inspec_app/pages/missions/sequence/steps/summary_step.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/moyenne_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/basse_tension_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/foudre_screen.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/mesures_essais_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES DU SOMMAIRE
// ─────────────────────────────────────────────────────────────────────────────

/// Représente une sous-section du drawer (cliquable ou informatif).
class _Sub {
  final String key;          // Clé unique pour la complétion
  final String label;
  final IconData icon;
  final int? jsaSubIndex;    // index dans JSA (0-5) si applicable
  final int? descSectionIndex; // index dans Description si applicable
  final bool isAuditNav;     // navigation vers écran Audit

  const _Sub({
    required this.key,
    required this.label,
    required this.icon,
    this.jsaSubIndex,
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
    title: 'JSA',
    icon: Icons.engineering_outlined,
    isRequired: true,
    hasSubs: true,
    subs: [
      _Sub(key: 'jsa_0', label: 'Opération & Équipe',        icon: Icons.people_outline,         jsaSubIndex: 0),
      _Sub(key: 'jsa_1', label: "Plan d'intervention",        icon: Icons.emergency_outlined,      jsaSubIndex: 1),
      _Sub(key: 'jsa_2', label: 'Dangers',                   icon: Icons.warning_amber_outlined,  jsaSubIndex: 2),
      _Sub(key: 'jsa_3', label: 'Exigences générales (EPC)', icon: Icons.security_outlined,       jsaSubIndex: 3),
      _Sub(key: 'jsa_4', label: 'EPI',                       icon: Icons.health_and_safety_outlined, jsaSubIndex: 4),
      _Sub(key: 'jsa_5', label: 'Vérification finale',       icon: Icons.verified_outlined,       jsaSubIndex: 5),
    ],
  ),
  _Item(
    stepIndex: 1,
    title: 'Renseignements généraux',
    icon: Icons.info_outline,
    isRequired: true,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 2,
    title: 'Documents nécessaires',
    icon: Icons.folder_outlined,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 3,
    title: 'Description des installations',
    icon: Icons.description_outlined,
    hasSubs: true,
    subs: [
      _Sub(key: 'alimentation_moyenne_tension', label: 'Alimentation MT',       icon: Icons.bolt_outlined,                   descSectionIndex: 0),
      _Sub(key: 'alimentation_basse_tension',   label: 'Alimentation BT',       icon: Icons.electrical_services_outlined,    descSectionIndex: 1),
      _Sub(key: 'groupe_electrogene',           label: 'Groupe électrogène',    icon: Icons.power_outlined,                  descSectionIndex: 2),
      _Sub(key: 'alimentation_carburant',       label: 'Alimentation carburant',icon: Icons.local_gas_station_outlined,      descSectionIndex: 3),
      _Sub(key: 'inverseur',                    label: 'Inverseur',             icon: Icons.swap_horiz_outlined,             descSectionIndex: 4),
      _Sub(key: 'stabilisateur',                label: 'Stabilisateur',         icon: Icons.tune_outlined,                   descSectionIndex: 5),
      _Sub(key: 'onduleurs',                    label: 'Onduleurs',             icon: Icons.battery_charging_full_outlined,  descSectionIndex: 6),
      _Sub(key: 'regime_neutre',                label: 'Régime du neutre',      icon: Icons.settings_ethernet_outlined,      descSectionIndex: 7),
      _Sub(key: 'eclairage_securite',           label: 'Éclairage de sécurité', icon: Icons.lightbulb_outline,              descSectionIndex: 8),
      _Sub(key: 'modifications_installations',  label: 'Modifications',         icon: Icons.build_outlined,                  descSectionIndex: 9),
      _Sub(key: 'note_calcul',                  label: 'Notes de calcul',       icon: Icons.calculate_outlined,              descSectionIndex: 10),
      _Sub(key: 'paratonnerre',                 label: 'Paratonnerre',          icon: Icons.thunderstorm_outlined,           descSectionIndex: 11),
      _Sub(key: 'registre_securite',            label: 'Registre de sécurité',  icon: Icons.menu_book_outlined,              descSectionIndex: 12),
    ],
  ),
  _Item(
    stepIndex: 4,
    title: 'Audit des installations',
    icon: Icons.electrical_services_outlined,
    hasSubs: true,
    subs: [
      _Sub(key: 'audit_mt',      label: 'Moyenne tension',   icon: Icons.high_quality_outlined,  isAuditNav: true),
      _Sub(key: 'audit_bt',      label: 'Basse tension',     icon: Icons.low_priority_outlined,  isAuditNav: true),
      _Sub(key: 'audit_foudre',  label: 'Observations foudre', icon: Icons.thunderstorm_outlined, isAuditNav: true),
      _Sub(key: 'audit_mesures', label: 'Mesures et essais', icon: Icons.science_outlined,       isAuditNav: true),
    ],
  ),
  _Item(
    stepIndex: 5,
    title: 'Schéma des installations',
    icon: Icons.schema_outlined,
    isRequired: true,
    hasSubs: false,
  ),
  _Item(
    stepIndex: 6,
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
  final Set<int> _expandedSteps = {0}; // JSA ouvert par défaut

  // ── Complétion dynamique (chargée async) ──
  Map<String, bool> _descProgress = {};    // clé → complété (Description)
  Map<String, bool> _auditProgress = {};   // clé → complété (Audit)

  // ── Keys ──
  final GlobalKey<JsaStepState> _jsaKey = GlobalKey<JsaStepState>();
  final GlobalKey<GeneralInfoStepState> _generalInfoKey = GlobalKey<GeneralInfoStepState>();
  final GlobalKey<DescriptionStepState> _descKey = GlobalKey<DescriptionStepState>();

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
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  Future<void> _ensureStatusIsEnCours() async {
    if (widget.initialStep == 6) return;
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null && mission.isEnAttente) {
      await HiveService.updateMissionStatus(missionId: widget.mission.id, newStatus: 'en_cours');
      widget.mission.status = 'en_cours';
    }
  }

  void _initializeSteps() {
    _steps = [
      {
        'title': 'JSA',
        'widget': JsaStep(
          key: _jsaKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('jsa', data),
          onNextStep: _goToNextStep,
        ),
      },
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
        'widget': DocumentsStep(mission: widget.mission, onDataChanged: (data) => _saveStepData('documents', data)),
      },
      {
        'title': 'Description des installations',
        'widget': DescriptionStep(
          key: _descKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('description', data),
          onPreviousStep: _goToPreviousStep,
          onNextStep: _goToNextStep,
        ),
      },
      {
        'title': 'Audit des installations',
        'widget': AuditStep(mission: widget.mission, onDataChanged: (data) => _saveStepData('audit', data)),
      },
      {
        'title': 'Schéma des installations',
        'widget': SchemaStep(mission: widget.mission, onDataChanged: (data) => _saveStepData('schema', data)),
      },
      {
        'title': 'Sommaire',
        'widget': SummaryStep(
          mission: widget.mission, user: widget.user,
          onDataChanged: (data) => _saveStepData('summary', data),
          onPrevious: _goToPreviousStep,
        ),
      },
    ];
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await SequenceProgressService.getProgress(widget.mission.id);
    _completedSteps = List<int>.from(progress['completedSteps'] as List<dynamic>? ?? []);

    var savedStep = progress['currentStep'] ?? 0;
    if (widget.initialStep > 0 && widget.initialStep < _steps.length) {
      savedStep = widget.initialStep;
      await SequenceProgressService.saveCurrentStep(widget.mission.id, savedStep);
    } else if (savedStep >= _steps.length) {
      savedStep = _steps.length - 1;
    }

    _currentStep = savedStep;
    _pageController = PageController(initialPage: _currentStep);

    // Charger progression Description et Audit
    await _refreshSubProgress();

    setState(() => _isLoading = false);
  }

  /// Rafraîchit la progression des sous-sections Description et Audit
  Future<void> _refreshSubProgress() async {
    // ── Description ──
    _descProgress = await HiveService.getMissionProgress(widget.mission.id);
    final descCompleted = _descProgress.values.any((v) => v); // au moins une section remplie
    if (descCompleted && !_completedSteps.contains(3)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 3);
      setState(() { if (!_completedSteps.contains(3)) _completedSteps.add(3); });
    }

    // ── Audit ──
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    final foudreList = HiveService.getFoudreObservationsByMissionId(widget.mission.id);
    final mesures = HiveService.getMesuresEssaisByMissionId(widget.mission.id);

    final auditMtOk      = audit != null && (audit.moyenneTensionLocaux.isNotEmpty || audit.moyenneTensionZones.isNotEmpty);
    final auditBtOk      = audit != null && audit.basseTensionZones.isNotEmpty;
    final auditFoudreOk  = foudreList.isNotEmpty;
    final auditMesuresOk = mesures != null;

    _auditProgress = {
      'audit_mt':      auditMtOk,
      'audit_bt':      auditBtOk,
      'audit_foudre':  auditFoudreOk,
      'audit_mesures': auditMesuresOk,
    };

    // Marquer Audit comme complet si AU MOINS UNE sous-section est remplie
    final auditHasData = auditMtOk && auditBtOk;
    if (auditHasData && !_completedSteps.contains(4)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 4);
      setState(() { if (!_completedSteps.contains(4)) _completedSteps.add(4); });
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveStepData(String stepKey, dynamic data) async {
    await SequenceProgressService.saveStepData(widget.mission.id, stepKey, data);
  }

  // ═══════════════════════════════════════════════════════════
  //  DRAWER
  // ═══════════════════════════════════════════════════════════
  void _toggleDrawer() {
    _dismissKeyboard();
    if (_drawerOpen) {
      _closeDrawer();
    } else {
      _refreshSubProgress(); // Rafraîchir avant ouverture
      setState(() => _drawerOpen = true);
      _animCtrl.forward();
    }
  }

  void _closeDrawer() {
    if (!_drawerOpen) return;
    setState(() => _drawerOpen = false);
    _animCtrl.reverse();
  }

  // ── Vérifications des blocages ──
  bool get _jsaComplete {
    final state = _jsaKey.currentState;
    // Si le state n'existe pas ou charge encore → fallback sur les étapes complétées persistées
    if (state == null || state.isLoading) return _completedSteps.contains(0);
    return state.isFullyComplete;
  }
  bool get _renseignementsComplete => _generalInfoKey.currentState?.isFormValid ?? _completedSteps.contains(1);
  bool get _schemaComplete {
    final mission = HiveService.getMissionById(widget.mission.id);
    return mission?.schemaOption != null;
  }

  /// Retourne le message de blocage si on ne peut pas aller à [targetStep], null si libre.
  String? _blockMessage(int targetStep) {
    // JSA obligatoire avant toute autre étape
    if (targetStep > 0 && !_jsaComplete) {
      return 'Le JSA doit être entièrement complété avant de passer à la suite.';
    }
    // Renseignements généraux obligatoire avant étape 3+
    if (targetStep >= 2 && !_renseignementsComplete) {
      return 'Les Renseignements généraux doivent être complétés (champs obligatoires manquants).';
    }
    // Schéma obligatoire avant Sommaire
    if (targetStep == 6 && !_schemaComplete) {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(block, style: const TextStyle(fontSize: 13))),
          ]),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || stepIndex == _currentStep) return;

    _dismissKeyboard();
    await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    setState(() => _currentStep = stepIndex);
    await _pageController.animateToPage(stepIndex,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    await SequenceProgressService.saveCurrentStep(widget.mission.id, stepIndex);
  }

  Future<void> _navigateToJsaSub(int subIndex) async {
    final block = _blockMessage(0);
    if (block != null) return; // JSA déjà sur step 0, pas de blocage

    _closeDrawer();
    // D'abord aller sur JSA si pas dessus
    if (_currentStep != 0) {
      await _navigateToStep(0);
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _jsaKey.currentState?.navigateToSubCategory(subIndex);
  }

  Future<void> _navigateToDescSub(int sectionIndex) async {
    final block = _blockMessage(3);
    if (block != null) {
      _closeDrawer();
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(block),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    _closeDrawer();
    if (_currentStep != 3) {
      setState(() => _currentStep = 3);
      await _pageController.animateToPage(3,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      await SequenceProgressService.saveCurrentStep(widget.mission.id, 3);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _descKey.currentState?.jumpToSection(sectionIndex);
  }

  Future<void> _navigateToAuditSub(String key) async {
    final block = _blockMessage(4);
    if (block != null) {
      _closeDrawer();
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(block),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Naviguer directement vers le sous-écran Audit
    switch (key) {
      case 'audit_mt':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MoyenneTensionScreen(mission: widget.mission)));
        break;
      case 'audit_bt':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BasseTensionScreen(mission: widget.mission)));
        break;
      case 'audit_foudre':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoudreScreen(mission: widget.mission)));
        break;
      case 'audit_mesures':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MesuresEssaisScreen(mission: widget.mission)));
        break;
    }

    // Rafraîchir la progression à la fermeture de l'écran Audit
    Future.delayed(const Duration(milliseconds: 500), _refreshSubProgress);
  }

  // ═══════════════════════════════════════════════════════════
  //  NAVIGATION SÉQUENTIELLE
  // ═══════════════════════════════════════════════════════════
  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _goToNextStep() async {
    _dismissKeyboard();
    _closeDrawer();

    // JSA — doit être entièrement complété
    if (_currentStep == 0) {
      final jsaState = _jsaKey.currentState;
      if (jsaState != null && !jsaState.isFullyComplete) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez compléter toutes les sections du JSA avant de continuer.'),
          backgroundColor: Colors.red, duration: Duration(seconds: 3),
        ));
        return;
      }
    }

    // Renseignements généraux
    if (_currentStep == 1) {
      _generalInfoKey.currentState?.triggerValidation();
      final isValid = _generalInfoKey.currentState?.isFormValid ?? false;
      if (!isValid) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires (marqués en rouge)'),
          backgroundColor: Colors.red, duration: Duration(seconds: 3),
        ));
        return;
      }
    }

    // Schéma
    if (_currentStep == 5 && !_schemaComplete) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner Oui ou Non pour le schéma des installations'),
        backgroundColor: Colors.red, duration: Duration(seconds: 3),
      ));
      return;
    }

    if (_currentStep < _steps.length - 1) {
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
      await SequenceProgressService.markStepCompleted(widget.mission.id, _currentStep);
      if (!_completedSteps.contains(_currentStep)) setState(() => _completedSteps.add(_currentStep));

      setState(() => _currentStep++);
      await _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    }
  }

  Future<void> _goToPreviousStep() async {
    _dismissKeyboard();
    _closeDrawer();

    if (_currentStep > 0) {
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
      setState(() => _currentStep--);
      final bool jump = (_currentStep + 1) == 3 && _currentStep == 2;
      if (jump) {
        _pageController.jumpToPage(_currentStep);
      } else {
        await _pageController.animateToPage(_currentStep,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      await SequenceProgressService.saveCurrentStep(widget.mission.id, _currentStep);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  DISPOSE
  // ═══════════════════════════════════════════════════════════
  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
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
          iconTheme: const IconThemeData(color: Colors.white),
          leading: _currentStep == 6 ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () { _dismissKeyboard(); _closeDrawer(); _showExitDialog(); },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _drawerOpen
                      ? const Icon(Icons.close, key: ValueKey('c'), color: Colors.white)
                      : const Icon(Icons.menu_book_outlined, key: ValueKey('o'), color: Colors.white),
                ),
                tooltip: 'Sommaire',
                onPressed: _toggleDrawer,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // ── Contenu principal
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
                if (_currentStep != 0 && _currentStep != 3 && _currentStep != 6)
                  _buildNavButtons(isLast),
              ],
            ),

            // ── Overlay
            if (_drawerOpen)
              FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),

            // ── Drawer (depuis la droite)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(_slideAnim),
                child: GestureDetector(
                  onTap: () {}, // absorber les taps
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
      ]),
      child: Row(
        children: [
          if (_currentStep > 0) Expanded(child: OutlinedButton(
            onPressed: _goToPreviousStep,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_back, size: 18), SizedBox(width: 8), Text('Précédent'),
            ]),
          )),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _goToNextStep,
            style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? Colors.green : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(isLast ? 'TERMINER' : 'SUIVANT'),
              if (!isLast) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)],
            ]),
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DRAWER PANEL
  // ═══════════════════════════════════════════════════════════
  Widget _buildDrawer(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final panelW = w < 360 ? w * 0.88 : 310.0;
    final done = _completedSteps.length;
    final pct = (done / _steps.length * 100).round();

    return Material(
      elevation: 16,
      color: Colors.transparent,
      child: Container(
        width: panelW,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.82)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.menu_book_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Sommaire',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: done / _steps.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: Colors.greenAccent, minHeight: 6,
                      ),
                    )),
                    const SizedBox(width: 10),
                    Text('$pct%', style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Text('$done/${_steps.length} sections complétées',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ]),
              ),

              // Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) => _buildItem(_items[i]),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200))),
                child: Text(
                  'Touchez une section pour y accéder directement',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_Item item) {
    final isCurrent  = _currentStep == item.stepIndex;
    final isComplete = _completedSteps.contains(item.stepIndex);
    final isExpanded = item.hasSubs && _expandedSteps.contains(item.stepIndex);
    final isBlocked  = _blockMessage(item.stepIndex) != null;

    Color stateColor = isBlocked ? Colors.grey.shade400
        : isCurrent   ? AppTheme.primaryBlue
        : isComplete   ? Colors.green
        : Colors.grey.shade500;

    return Column(
      children: [
        // ── Item principal
        InkWell(
          onTap: () => _navigateToStep(item.stepIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isCurrent ? AppTheme.primaryBlue.withOpacity(0.10)
                  : isComplete ? Colors.green.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))
                  : null,
            ),
            child: Row(children: [
              // Icône état
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: isBlocked
                      ? Icon(Icons.lock_outline, color: stateColor, size: 17)
                      : isComplete && !isCurrent
                          ? Icon(Icons.check_circle, color: Colors.green, size: 18)
                          : Icon(item.icon, color: stateColor, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.title, style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isBlocked ? Colors.grey.shade500
                          : isCurrent ? AppTheme.primaryBlue
                          : isComplete ? Colors.black87 : Colors.grey.shade700,
                    ))),
                    if (item.isRequired && !isComplete && !isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text('Requis', style: TextStyle(
                            fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  if (isCurrent)
                    Text('En cours', style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue.withOpacity(0.7)))
                  else if (isComplete)
                    Text('Complétée', style: TextStyle(fontSize: 11, color: Colors.green.shade600))
                  else if (isBlocked)
                    Text('Accès verrouillé', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ),
              // Bouton expand (seulement si hasSubs)
              if (item.hasSubs)
                GestureDetector(
                  onTap: () => setState(() {
                    if (isExpanded) _expandedSteps.remove(item.stepIndex);
                    else _expandedSteps.add(item.stepIndex);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          size: 18, color: Colors.grey.shade500),
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // ── Sous-sections collapsibles
        if (item.hasSubs)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSubs(item),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildSubs(_Item item) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 10, bottom: 4),
      child: Column(
        children: item.subs.map((sub) {
          // Déterminer si la sous-section est complète
          bool subComplete = false;
          if (sub.jsaSubIndex != null) {
            subComplete = _jsaKey.currentState?.isSubCategoryComplete(sub.jsaSubIndex!) ?? false;
          } else if (sub.descSectionIndex != null) {
            subComplete = _descProgress[sub.key] ?? false;
          } else if (sub.isAuditNav) {
            subComplete = _auditProgress[sub.key] ?? false;
          }

          final blocked = _blockMessage(item.stepIndex) != null;
          final subColor = blocked ? Colors.grey.shade400 : subComplete ? Colors.green : Colors.grey.shade500;

          return InkWell(
            onTap: blocked ? null : () {
              if (sub.jsaSubIndex != null) {
                _navigateToJsaSub(sub.jsaSubIndex!);
              } else if (sub.descSectionIndex != null) {
                _navigateToDescSub(sub.descSectionIndex!);
              } else if (sub.isAuditNav) {
                _navigateToAuditSub(sub.key);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: subComplete ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: subComplete ? Border.all(color: Colors.green.withOpacity(0.2)) : null,
              ),
              child: Row(children: [
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(color: subColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Icon(subComplete ? Icons.check_circle : sub.icon,
                    size: 14, color: subColor),
                const SizedBox(width: 8),
                Expanded(child: Text(sub.label, style: TextStyle(
                  fontSize: 12,
                  color: blocked ? Colors.grey.shade400 : subComplete ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: subComplete ? FontWeight.w500 : FontWeight.normal,
                ))),
                if (!blocked)
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EXIT DIALOG
  // ═══════════════════════════════════════════════════════════
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la mission'),
        content: const Text('Votre progression sera sauvegardée. Vous pourrez reprendre plus tard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}