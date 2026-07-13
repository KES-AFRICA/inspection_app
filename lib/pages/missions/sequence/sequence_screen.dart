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
class _Sub {
  final String key;
  final String label;
  final IconData icon;
  final int? jsaSubIndex;
  final int? descSectionIndex;
  final bool isAuditNav;

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
      _Sub(
        key: 'jsa_0',
        label: 'Opération & Équipe',
        icon: Icons.people_outline,
        jsaSubIndex: 0,
      ),
      _Sub(
        key: 'jsa_1',
        label: "Plan d'intervention",
        icon: Icons.emergency_outlined,
        jsaSubIndex: 1,
      ),
      _Sub(
        key: 'jsa_2',
        label: 'Dangers',
        icon: Icons.warning_amber_outlined,
        jsaSubIndex: 2,
      ),
      _Sub(
        key: 'jsa_3',
        label: 'Exigences générales (EPC)',
        icon: Icons.security_outlined,
        jsaSubIndex: 3,
      ),
      _Sub(
        key: 'jsa_4',
        label: 'EPI',
        icon: Icons.health_and_safety_outlined,
        jsaSubIndex: 4,
      ),
      _Sub(
        key: 'jsa_5',
        label: 'Vérification finale',
        icon: Icons.verified_outlined,
        jsaSubIndex: 5,
      ),
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
    stepIndex: 4,
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
// CALCUL COMPLÉTION JSA DEPUIS HIVE (source fiable, indépendante du widget)
// ─────────────────────────────────────────────────────────────────────────────
bool _jsaSubCompleteFromHive(dynamic jsa, int index) {
  if (jsa == null) return false;
  switch (index) {
    case 0:
      return jsa.operationEffectuer?.isNotEmpty == true &&
          (jsa.inspecteurs?.isNotEmpty ?? false);
    case 1:
      final p = jsa.planUrgence;
      return p != null &&
          (p.voiesIssuesIdentifiees == true ||
              p.zonesRassemblementIdentifiees == true ||
              p.consignesSecuriteInternes == true ||
              (p.personneContactClient?.isNotEmpty ?? false) ||
              (p.personneContactKES?.isNotEmpty ?? false));
    case 2:
      final d = jsa.dangers;
      return d != null &&
          (d.chocElectrique == true ||
              d.bruit == true ||
              d.stressThermique == true ||
              d.eclairageInadapte == true ||
              d.zoneCirculationMalDefinie == true ||
              d.solAccidente == true ||
              d.emissionGazPoussiere == true ||
              d.espaceConfine == true ||
              (d.autreEnvironnement?.isNotEmpty ?? false) ||
              d.chuteObjets == true ||
              d.coactivite == true ||
              d.portCharge == true ||
              d.expositionProduitsChimiques == true ||
              d.chuteHauteur == true ||
              d.electrification == true ||
              d.incendiesExplosion == true ||
              d.mauvaisesPostures == true ||
              d.chutePlainPied == true ||
              (d.autrePhysique?.isNotEmpty ?? false));
    case 3:
      final e = jsa.exigencesGenerales;
      return e != null &&
          (e.signaletiqueSecurite == true ||
              e.ficheDonneeSecuriteDisponible == true ||
              e.uneMinuteMaSecurite == true ||
              e.balise == true ||
              e.zoneTravailPropre == true ||
              e.toolboxMeeting == true ||
              e.permisTravail == true ||
              e.extincteurs == true ||
              e.outilsMaterielsIsolants == true ||
              e.boitePharmacie == true ||
              (e.autre?.isNotEmpty ?? false));
    case 4:
      final ep = jsa.epi;
      return ep != null &&
          (ep.casqueSecurite == true ||
              ep.bouchonsOreille == true ||
              ep.lunettesProtection == true ||
              ep.harnaisSecurite == true ||
              ep.chaussureSecurite == true ||
              ep.masqueSecurite == true ||
              ep.combinaisonLongueManche == true ||
              ep.gantsIsolants == true ||
              ep.cacheNez == true ||
              ep.gilet == true ||
              (ep.autre?.isNotEmpty ?? false));
    case 5:
      final v = jsa.verificationFinale;
      return v != null &&
          (v.travailTermineNA == true ||
              v.travailTermineApplicable == true ||
              v.consignationCadenasRetireNA == true ||
              v.consignationCadenasRetireApplicable == true ||
              v.absenceConsignataireProcedureNA == true ||
              v.absenceConsignataireProcedureApplicable == true ||
              v.consignataireAbsentProcedureAppliqueeNA == true ||
              v.consignataireAbsentProcedureAppliqueeApplicable == true ||
              v.materielEnleveZoneNettoyeeNA == true ||
              v.materielEnleveZoneNettoyeeApplicable == true ||
              v.risquesSupprimesEquipementPretNA == true ||
              v.risquesSupprimesEquipementPretApplicable == true ||
              (v.donneurOrdreSignature?.isNotEmpty ?? false) ||
              (v.chargeAffairesSignature?.isNotEmpty ?? false));
    default:
      return false;
  }
}

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
  Set<int> _expandedSteps = {}; // géré dynamiquement à l'ouverture

  // ── Complétion dynamique ──
  Map<String, bool> _descProgress = {};
  Map<String, bool> _auditProgress = {};
  Map<int, bool> _jsaSubProgress = {}; // complétion JSA depuis Hive

  // ── Keys ──
  final GlobalKey<JsaStepState> _jsaKey = GlobalKey<JsaStepState>();
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
    if (widget.initialStep == 6) return;
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
        'title': 'JSA',
        'widget': JsaStep(
          key: _jsaKey,
          mission: widget.mission,
          onDataChanged: (data) => _saveStepData('jsa', data),
          onNextStep: _goToNextStep,
          onSubStepChanged: () => setState(() {}),
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
    // JSA — complétion depuis Hive
    final jsa = HiveService.getJSAByMissionId(widget.mission.id);
    final newJsaSub = <int, bool>{};
    for (int i = 0; i < 6; i++) {
      newJsaSub[i] = _jsaSubCompleteFromHive(jsa, i);
    }
    _jsaSubProgress = newJsaSub;

    // JSA entièrement complète
    final jsaAllDone = newJsaSub.values.every((v) => v);
    if (jsaAllDone && !_completedSteps.contains(0)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 0);
      _completedSteps.add(0);
    }

    // Description
    _descProgress = await HiveService.getMissionProgress(widget.mission.id);
    final descHasData = _descProgress.values.any((v) => v);
    if (descHasData && !_completedSteps.contains(3)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 3);
      _completedSteps.add(3);
    }

    // Audit
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
    if (auditHasData && !_completedSteps.contains(4)) {
      await SequenceProgressService.markStepCompleted(widget.mission.id, 4);
      _completedSteps.add(4);
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

  // ═══════════════════════════════════════════════════════════
  //  DRAWER
  // ═══════════════════════════════════════════════════════════
  void _toggleDrawer() {
    _dismissKeyboard();
    if (_drawerOpen) {
      _closeDrawer();
    } else {
      // Rafraîchir les données PUIS ouvrir
      _refreshSubProgress().then((_) {
        if (!mounted) return;
        // Auto-dérouler l'item de l'étape courante s'il a des subs
        _expandedSteps = {};
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
  bool get _jsaComplete {
    // Source primaire : données Hive (fiable même si widget pas encore monté)
    final allDoneFromHive =
        _jsaSubProgress.isNotEmpty && _jsaSubProgress.values.every((v) => v);
    if (allDoneFromHive) return true;
    // Fallback : étapes persistées
    return _completedSteps.contains(0);
  }

  bool get _renseignementsComplete =>
      _generalInfoKey.currentState?.isFormValid ?? _completedSteps.contains(1);

  bool get _schemaComplete {
    final mission = HiveService.getMissionById(widget.mission.id);
    return mission?.schemaOption != null;
  }

  String? _blockMessage(int targetStep) {
    if (targetStep > 0 && !_jsaComplete) {
      return 'Le JSA doit être entièrement complété avant de passer à la suite.';
    }
    if (targetStep >= 2 && !_renseignementsComplete) {
      return 'Les Renseignements généraux doivent être complétés.';
    }
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
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || stepIndex == _currentStep) return;

    _dismissKeyboard();
    await SequenceProgressService.saveCurrentStep(
      widget.mission.id,
      _currentStep,
    );
    setState(() => _currentStep = stepIndex);
    await _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    await SequenceProgressService.saveCurrentStep(widget.mission.id, stepIndex);
  }

  Future<void> _navigateToJsaSub(int subIndex) async {
    _closeDrawer();
    if (_currentStep != 0) {
      setState(() => _currentStep = 0);
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      await SequenceProgressService.saveCurrentStep(widget.mission.id, 0);
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _jsaKey.currentState?.navigateToSubCategory(subIndex);
  }

  Future<void> _navigateToDescSub(int sectionIndex) async {
    final block = _blockMessage(3);
    if (block != null) {
      _closeDrawer();
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(block),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _closeDrawer();
    if (_currentStep != 3) {
      setState(() => _currentStep = 3);
      await _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(block),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    switch (key) {
      case 'audit_mt':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MoyenneTensionScreen(mission: widget.mission),
          ),
        );
        break;
      case 'audit_bt':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasseTensionScreen(mission: widget.mission),
          ),
        );
        break;
      case 'audit_foudre':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoudreScreen(mission: widget.mission),
          ),
        );
        break;
      case 'audit_mesures':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MesuresEssaisScreen(mission: widget.mission),
          ),
        );
        break;
    }
    // Rafraîchir après retour
    await _refreshSubProgress();
  }

  // ═══════════════════════════════════════════════════════════
  //  NAVIGATION SÉQUENTIELLE
  // ═══════════════════════════════════════════════════════════
  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _goToNextStep() async {
    _dismissKeyboard();
    _closeDrawer();

    if (_currentStep == 0) {
      final jsaState = _jsaKey.currentState;
      if (jsaState != null) {
        final handled = await jsaState.next();
        if (handled) return; // Le slide JSA interne a changé
      }
    }

    if (_currentStep == 1) {
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

    if (_currentStep == 3) {
      final descState = _descKey.currentState;
      if (descState != null) {
        final handled = descState.next();
        if (handled) return; // La sous-page description a changé
      }
    }

    if (_currentStep == 5 && !_schemaComplete) {
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

    if (_currentStep == 0) {
      final jsaState = _jsaKey.currentState;
      if (jsaState != null) {
        final handled = await jsaState.previous();
        if (handled) return; // Recul interne de la JSA
      }
    }

    if (_currentStep == 3) {
      final descState = _descKey.currentState;
      if (descState != null) {
        final handled = descState.previous();
        if (handled) return; // Recul interne de la description
      }
    }

    if (_currentStep > 0) {
      await SequenceProgressService.saveCurrentStep(
        widget.mission.id,
        _currentStep,
      );
      setState(() => _currentStep--);
      final bool jump = (_currentStep + 1) == 3 && _currentStep == 2;
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
          automaticallyImplyLeading: false,
          // ── Bouton sommaire à GAUCHE ──────────────────────────
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
          // ── Bouton quitter à DROITE (sauf Sommaire) ──────────
          actions: [
            if (_currentStep != 6)
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
            // ── Contenu principal ──────────────────────────────
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
                if (_currentStep != 6) _buildNavButtons(isLast),
              ],
            ),

            // ── Overlay sombre ─────────────────────────────────
            if (_drawerOpen)
              FadeTransition(
                opacity: _fadeAnim,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),

            // ── Drawer depuis la GAUCHE ────────────────────────
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0), // ← depuis la gauche
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

    // Personnalisation dynamique pour la JSA (Étape 0)
    if (_currentStep == 0) {
      final jsaState = _jsaKey.currentState;
      if (jsaState != null) {
        showPrevious = !jsaState.isFirstSlide;
        if (jsaState.isLastSlide) {
          nextLabel = 'Renseignements';
        }
      }
    }

    // Personnalisation dynamique pour la Description (Étape 3)
    if (_currentStep == 3) {
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
                      'Précédent',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else if (_currentStep > 0) ...[
            // Espace pour garder le bouton Suivant aligné à droite si pas de précédent
            const Spacer(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? Colors.green : AppTheme.primaryBlue,
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
                  if (nextLabel == 'SUIVANT' ||
                      nextLabel == 'RENSEIGNEMENTS' ||
                      nextLabel == 'AUDIT') ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
            ),
          ),
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
          // ← arrondi à droite (drawer depuis la gauche)
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withOpacity(0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  // ← arrondi à droite
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Sommaire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeDrawer,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: done / _steps.length,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              color: Colors.greenAccent,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$done/${_steps.length} sections complétées',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Text(
                  'Touchez une section pour y accéder directement',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
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
    final isCurrent = _currentStep == item.stepIndex;
    final isComplete = _completedSteps.contains(item.stepIndex);
    final isExpanded = item.hasSubs && _expandedSteps.contains(item.stepIndex);
    final isBlocked = _blockMessage(item.stepIndex) != null;

    final Color stateColor = isBlocked
        ? Colors.grey.shade400
        : isCurrent
        ? AppTheme.primaryBlue
        : isComplete
        ? Colors.green
        : Colors.grey.shade500;

    return Column(
      children: [
        InkWell(
          onTap: () => _navigateToStep(item.stepIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.primaryBlue.withOpacity(0.10)
                  : isComplete
                  ? Colors.green.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isCurrent
                  ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: isBlocked
                        ? Icon(Icons.lock_outline, color: stateColor, size: 17)
                        : isComplete && !isCurrent
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        : Icon(item.icon, color: stateColor, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isBlocked
                                    ? Colors.grey.shade500
                                    : isCurrent
                                    ? AppTheme.primaryBlue
                                    : isComplete
                                    ? Colors.black87
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (item.isRequired && !isComplete && !isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                ),
                              ),
                              child: Text(
                                'Requis',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isCurrent)
                        Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue.withOpacity(0.7),
                          ),
                        )
                      else if (isComplete)
                        Text(
                          'Complétée',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                          ),
                        )
                      else if (isBlocked)
                        Text(
                          'Accès verrouillé',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.hasSubs)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedSteps.remove(item.stepIndex);
                      } else {
                        _expandedSteps.add(item.stepIndex);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
              ],
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
          if (sub.jsaSubIndex != null) {
            subComplete = _jsaSubProgress[sub.jsaSubIndex!] ?? false;
          } else if (sub.descSectionIndex != null) {
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

  // ═══════════════════════════════════════════════════════════
  //  EXIT DIALOG
  // ═══════════════════════════════════════════════════════════
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la mission'),
        content: const Text(
          'Votre progression sera sauvegardée. Vous pourrez reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
