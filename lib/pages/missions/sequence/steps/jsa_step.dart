// lib/pages/missions/sequence/steps/jsa_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';
import 'package:inspec_app/widgets/app_bottom_sheet.dart';

class JsaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback? onNextStep;

  const JsaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    this.onNextStep,
  });

  @override
  State<JsaStep> createState() => JsaStepState();
}

class JsaStepState extends State<JsaStep> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Préserve l'état entre les navigations

  late JSA _jsa;
  bool _isLoading = true;
  bool _isFirstLoad = true;
  bool _hasAttemptedNext = false; // ✅ Pour contrôler l'affichage des erreurs

  // Contrôleurs
  final _operationController = TextEditingController();
  final _autreEnvironnementController = TextEditingController();
  final _autrePhysiqueController = TextEditingController();
  final _autreExigenceController = TextEditingController();
  final _autreEPIController = TextEditingController();
  final _autresPointsVerifController = TextEditingController();
  final _donneurOrdreSignatureController = TextEditingController();
  final _chargeAffairesSignatureController = TextEditingController();
  final _personneContactClientController = TextEditingController();
  final _personneContactKESController = TextEditingController();

  // ✅ Focus nodes pour meilleure gestion du clavier
  final _operationFocusNode = FocusNode();

  static const _subCategories = [
    'Opération & Équipe',
    "Plan d'intervention en cas d'urgence",
    'Dangers',
    'Exigences Générales (EPC)',
    'EPI',
    'Vérification finale',
  ];

  static const Color _primaryColor = Color(0xFF1E88E5); // Bleu unique

  static const List<IconData> _subCategoryIcons = [
    Icons.engineering_outlined,
    Icons.emergency_outlined,
    Icons.warning_amber_outlined,
    Icons.security_outlined,
    Icons.health_and_safety_outlined,
    Icons.verified_outlined,
  ];

  int get totalSubCategories => _subCategories.length;
  int get currentSubCategory => _jsa.currentSubCategory;
  Color get currentColor => _primaryColor;
  IconData get currentIcon => _subCategoryIcons[currentSubCategory];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _jsa = await HiveService.getOrCreateJSA(widget.mission.id);
      _loadControllersFromJSA();
      
      if (_isFirstLoad) {
        final savedPosition = await SequenceProgressService.getStepData(
          widget.mission.id,
          'jsa_current_subcategory',
        );
        if (savedPosition != null && savedPosition is int && savedPosition < totalSubCategories) {
          _jsa.currentSubCategory = savedPosition;
        }
        _isFirstLoad = false;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement JSA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement des données'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadControllersFromJSA() {
    _operationController.text = _jsa.operationEffectuer;
    _autreEnvironnementController.text = _jsa.dangers.autreEnvironnement;
    _autrePhysiqueController.text = _jsa.dangers.autrePhysique;
    _autreExigenceController.text = _jsa.exigencesGenerales.autre;
    _autreEPIController.text = _jsa.epi.autre;
    _autresPointsVerifController.text = _jsa.verificationFinale.autresPoints;
    _donneurOrdreSignatureController.text = _jsa.verificationFinale.donneurOrdreSignature;
    _chargeAffairesSignatureController.text = _jsa.verificationFinale.chargeAffairesSignature;
    _personneContactClientController.text = _jsa.planUrgence.personneContactClient;
    _personneContactKESController.text = _jsa.planUrgence.personneContactKES;
  }

  Future<void> _saveJSA() async {
    _jsa.operationEffectuer = _operationController.text.trim();
    _jsa.dangers.autreEnvironnement = _autreEnvironnementController.text.trim();
    _jsa.dangers.autrePhysique = _autrePhysiqueController.text.trim();
    _jsa.exigencesGenerales.autre = _autreExigenceController.text.trim();
    _jsa.epi.autre = _autreEPIController.text.trim();
    _jsa.verificationFinale.autresPoints = _autresPointsVerifController.text.trim();
    _jsa.verificationFinale.donneurOrdreSignature = _donneurOrdreSignatureController.text.trim();
    _jsa.verificationFinale.chargeAffairesSignature = _chargeAffairesSignatureController.text.trim();
    _jsa.planUrgence.personneContactClient = _personneContactClientController.text.trim();
    _jsa.planUrgence.personneContactKES = _personneContactKESController.text.trim();
    
    await HiveService.saveJSA(_jsa);
    widget.onDataChanged({'jsa_saved': true, 'current_step': currentSubCategory});
  }

  Future<void> _saveCurrentPosition() async {
    await SequenceProgressService.saveStepData(
      widget.mission.id,
      'jsa_current_subcategory',
      currentSubCategory,
    );
  }

  // ✅ Validation avec messages contextuels
  String? _getCurrentSubCategoryError() {
    if (_hasAttemptedNext) {
      switch (currentSubCategory) {
        case 0:
          if (_operationController.text.trim().isEmpty) {
            return "L'opération à effectuer est requise";
          }
          if (_jsa.inspecteurs.isEmpty) {
            return "Au moins un inspecteur est requis";
          }
          break;
        case 1:
          if (!_jsa.planUrgence.voiesIssuesIdentifiees &&
              !_jsa.planUrgence.zonesRassemblementIdentifiees &&
              !_jsa.planUrgence.consignesSecuriteInternes &&
              _personneContactClientController.text.trim().isEmpty &&
              _personneContactKESController.text.trim().isEmpty) {
            return "Sélectionnez au moins une option ou renseignez un contact";
          }
          break;
        case 2:
          if (!_jsa.dangers.chocElectrique &&
              !_jsa.dangers.bruit &&
              !_jsa.dangers.stressThermique &&
              !_jsa.dangers.eclairageInadapte &&
              !_jsa.dangers.zoneCirculationMalDefinie &&
              !_jsa.dangers.solAccidente &&
              !_jsa.dangers.emissionGazPoussiere &&
              !_jsa.dangers.espaceConfine &&
              _autreEnvironnementController.text.trim().isEmpty &&
              !_jsa.dangers.chuteObjets &&
              !_jsa.dangers.coactivite &&
              !_jsa.dangers.portCharge &&
              !_jsa.dangers.expositionProduitsChimiques &&
              !_jsa.dangers.chuteHauteur &&
              !_jsa.dangers.electrification &&
              !_jsa.dangers.incendiesExplosion &&
              !_jsa.dangers.mauvaisesPostures &&
              !_jsa.dangers.chutePlainPied &&
              _autrePhysiqueController.text.trim().isEmpty) {
            return "Sélectionnez au moins un danger";
          }
          break;
        case 3:
          if (!_jsa.exigencesGenerales.signaletiqueSecurite &&
              !_jsa.exigencesGenerales.ficheDonneeSecuriteDisponible &&
              !_jsa.exigencesGenerales.uneMinuteMaSecurite &&
              !_jsa.exigencesGenerales.balise &&
              !_jsa.exigencesGenerales.zoneTravailPropre &&
              !_jsa.exigencesGenerales.toolboxMeeting &&
              !_jsa.exigencesGenerales.permisTravail &&
              !_jsa.exigencesGenerales.extincteurs &&
              !_jsa.exigencesGenerales.outilsMaterielsIsolants &&
              !_jsa.exigencesGenerales.boitePharmacie &&
              _autreExigenceController.text.trim().isEmpty) {
            return "Sélectionnez au moins une exigence";
          }
          break;
        case 4:
          if (!_jsa.epi.casqueSecurite &&
              !_jsa.epi.bouchonsOreille &&
              !_jsa.epi.lunettesProtection &&
              !_jsa.epi.harnaisSecurite &&
              !_jsa.epi.chaussureSecurite &&
              !_jsa.epi.masqueSecurite &&
              !_jsa.epi.combinaisonLongueManche &&
              !_jsa.epi.gantsIsolants &&
              !_jsa.epi.cacheNez &&
              !_jsa.epi.gilet &&
              _autreEPIController.text.trim().isEmpty) {
            return "Sélectionnez au moins un EPI";
          }
          break;
        case 5:
          if (!_jsa.verificationFinale.travailTermineNA &&
              !_jsa.verificationFinale.travailTermineApplicable &&
              !_jsa.verificationFinale.consignationCadenasRetireNA &&
              !_jsa.verificationFinale.consignationCadenasRetireApplicable &&
              !_jsa.verificationFinale.absenceConsignataireProcedureNA &&
              !_jsa.verificationFinale.absenceConsignataireProcedureApplicable &&
              !_jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA &&
              !_jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable &&
              !_jsa.verificationFinale.materielEnleveZoneNettoyeeNA &&
              !_jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable &&
              !_jsa.verificationFinale.risquesSupprimesEquipementPretNA &&
              !_jsa.verificationFinale.risquesSupprimesEquipementPretApplicable &&
              _autresPointsVerifController.text.trim().isEmpty &&
              _donneurOrdreSignatureController.text.trim().isEmpty &&
              _chargeAffairesSignatureController.text.trim().isEmpty) {
            return "Renseignez au moins un point de vérification";
          }
          break;
      }
    }
    return null;
  }

  bool _isCurrentSubCategoryValid() {
  switch (currentSubCategory) {
    case 0: // Opération & Équipe
      return _operationController.text.trim().isNotEmpty && _jsa.inspecteurs.isNotEmpty;
    case 1: // Plan d'urgence
      return _jsa.planUrgence.voiesIssuesIdentifiees ||
             _jsa.planUrgence.zonesRassemblementIdentifiees ||
             _jsa.planUrgence.consignesSecuriteInternes ||
             _personneContactClientController.text.trim().isNotEmpty ||
             _personneContactKESController.text.trim().isNotEmpty;
    case 2: // Dangers
      return _jsa.dangers.chocElectrique ||
             _jsa.dangers.bruit ||
             _jsa.dangers.stressThermique ||
             _jsa.dangers.eclairageInadapte ||
             _jsa.dangers.zoneCirculationMalDefinie ||
             _jsa.dangers.solAccidente ||
             _jsa.dangers.emissionGazPoussiere ||
             _jsa.dangers.espaceConfine ||
             _autreEnvironnementController.text.trim().isNotEmpty ||
             _jsa.dangers.chuteObjets ||
             _jsa.dangers.coactivite ||
             _jsa.dangers.portCharge ||
             _jsa.dangers.expositionProduitsChimiques ||
             _jsa.dangers.chuteHauteur ||
             _jsa.dangers.electrification ||
             _jsa.dangers.incendiesExplosion ||
             _jsa.dangers.mauvaisesPostures ||
             _jsa.dangers.chutePlainPied ||
             _autrePhysiqueController.text.trim().isNotEmpty;
    case 3: // Exigences générales
      return _jsa.exigencesGenerales.signaletiqueSecurite ||
             _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible ||
             _jsa.exigencesGenerales.uneMinuteMaSecurite ||
             _jsa.exigencesGenerales.balise ||
             _jsa.exigencesGenerales.zoneTravailPropre ||
             _jsa.exigencesGenerales.toolboxMeeting ||
             _jsa.exigencesGenerales.permisTravail ||
             _jsa.exigencesGenerales.extincteurs ||
             _jsa.exigencesGenerales.outilsMaterielsIsolants ||
             _jsa.exigencesGenerales.boitePharmacie ||
             _autreExigenceController.text.trim().isNotEmpty;
    case 4: // EPI
      return _jsa.epi.casqueSecurite ||
             _jsa.epi.bouchonsOreille ||
             _jsa.epi.lunettesProtection ||
             _jsa.epi.harnaisSecurite ||
             _jsa.epi.chaussureSecurite ||
             _jsa.epi.masqueSecurite ||
             _jsa.epi.combinaisonLongueManche ||
             _jsa.epi.gantsIsolants ||
             _jsa.epi.cacheNez ||
             _jsa.epi.gilet ||
             _autreEPIController.text.trim().isNotEmpty;
    case 5: // Vérification finale
      return _jsa.verificationFinale.travailTermineNA ||
             _jsa.verificationFinale.travailTermineApplicable ||
             _jsa.verificationFinale.consignationCadenasRetireNA ||
             _jsa.verificationFinale.consignationCadenasRetireApplicable ||
             _jsa.verificationFinale.absenceConsignataireProcedureNA ||
             _jsa.verificationFinale.absenceConsignataireProcedureApplicable ||
             _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA ||
             _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable ||
             _jsa.verificationFinale.materielEnleveZoneNettoyeeNA ||
             _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable ||
             _jsa.verificationFinale.risquesSupprimesEquipementPretNA ||
             _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable ||
             _autresPointsVerifController.text.trim().isNotEmpty ||
             _donneurOrdreSignatureController.text.trim().isNotEmpty ||
             _chargeAffairesSignatureController.text.trim().isNotEmpty;
    default:
      return false;
  }
}

  void _nextSubCategory() {
    FocusScope.of(context).unfocus();
    
    // ✅ Marquer qu'on a tenté d'avancer (active les messages d'erreur)
    if (!_hasAttemptedNext) {
      setState(() => _hasAttemptedNext = true);
    }
    
    if (!_isCurrentSubCategoryValid()) {
      _showError(_getCurrentSubCategoryError() ?? 'Veuillez compléter cette section');
      return;
    }
    
    if (currentSubCategory < totalSubCategories - 1) {
      setState(() => _jsa.currentSubCategory++);
      _saveJSA();
      _saveCurrentPosition();
    }
  }

  void _previousSubCategory() {
    FocusScope.of(context).unfocus();
    
    if (currentSubCategory > 0) {
      setState(() => _jsa.currentSubCategory--);
      _saveJSA();
      _saveCurrentPosition();
    }
  }

  void _goToRenseignements() {
    // ✅ Marquer qu'on a tenté d'avancer
    if (!_hasAttemptedNext) {
      setState(() => _hasAttemptedNext = true);
    }
    
    if (!_isCurrentSubCategoryValid()) {
      _showError(_getCurrentSubCategoryError() ?? 'Veuillez compléter cette section');
      return;
    }
    
    _saveJSA();
    _saveCurrentPosition();
    if (widget.onNextStep != null) {
      widget.onNextStep!();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== GESTION DES INSPECTEURS ====================
  
  void _addInspecteur() {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final signatureController = TextEditingController();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AppBottomSheet(
          title: 'Ajouter un inspecteur',
          bottomButton: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitInspecteur(
                    nomController, prenomController, signatureController,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ajouter',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                children: [
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person_outline, size: isSmallScreen ? 18 : 20),
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  TextField(
                    controller: prenomController,
                    decoration: InputDecoration(
                      labelText: 'Prénom *',
                      prefixIcon: Icon(Icons.person_outline, size: isSmallScreen ? 18 : 20),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  TextField(
                    controller: signatureController,
                    decoration: InputDecoration(
                      labelText: 'Signature',
                      prefixIcon: Icon(Icons.draw_outlined, size: isSmallScreen ? 18 : 20),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitInspecteur(
                      nomController, prenomController, signatureController,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitInspecteur(
    TextEditingController nomCtrl,
    TextEditingController prenomCtrl,
    TextEditingController signatureCtrl,
  ) {
    final nom = nomCtrl.text.trim();
    final prenom = prenomCtrl.text.trim();
    
    if (nom.isEmpty || prenom.isEmpty) {
      _showError('Le nom et le prénom sont requis');
      return;
    }
    
    // ✅ Limite de 6 inspecteurs
    if (_jsa.inspecteurs.length >= 6) {
      _showError('Nombre maximum d\'inspecteurs atteint (6)');
      return;
    }
    
    Navigator.pop(context);
    setState(() {
      _jsa.inspecteurs.add(JSAInspecteur(
        nom: nom,
        prenom: prenom,
        signature: signatureCtrl.text.trim(),
      ));
    });
    _saveJSA();
    _showSuccess('Inspecteur ajouté');
  }

  void _removeInspecteur(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer cet inspecteur ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _jsa.inspecteurs.removeAt(index));
              _saveJSA();
              Navigator.pop(context);
              _showSuccess('Inspecteur retiré');
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS MODERNES ====================

  Widget _buildStatusBadge(bool isValid, bool isSmallScreen) {
  // ✅ Ne pas afficher "Complété" si rien n'a été rempli
  final hasData = _hasAnyDataInCurrentSection();
  
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12 : 16,
      vertical: isSmallScreen ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: hasData && isValid ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: hasData && isValid ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasData && isValid ? Icons.check_circle : Icons.pending_outlined,
          color: hasData && isValid ? Colors.green : Colors.grey.shade600,
          size: isSmallScreen ? 16 : 18,
        ),
        SizedBox(width: isSmallScreen ? 8 : 10),
        Text(
          hasData && isValid ? 'Complété' : (hasData ? 'En cours' : 'Non commencé'),
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: hasData && isValid ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}

// ✅ Nouvelle méthode pour vérifier si la section courante a des données
bool _hasAnyDataInCurrentSection() {
  switch (currentSubCategory) {
    case 0:
      return _operationController.text.trim().isNotEmpty || _jsa.inspecteurs.isNotEmpty;
    case 1:
      return _jsa.planUrgence.voiesIssuesIdentifiees ||
             _jsa.planUrgence.zonesRassemblementIdentifiees ||
             _jsa.planUrgence.consignesSecuriteInternes ||
             _personneContactClientController.text.trim().isNotEmpty ||
             _personneContactKESController.text.trim().isNotEmpty;
    case 2:
      return _jsa.dangers.chocElectrique ||
             _jsa.dangers.bruit ||
             _jsa.dangers.stressThermique ||
             _jsa.dangers.eclairageInadapte ||
             _jsa.dangers.zoneCirculationMalDefinie ||
             _jsa.dangers.solAccidente ||
             _jsa.dangers.emissionGazPoussiere ||
             _jsa.dangers.espaceConfine ||
             _autreEnvironnementController.text.trim().isNotEmpty ||
             _jsa.dangers.chuteObjets ||
             _jsa.dangers.coactivite ||
             _jsa.dangers.portCharge ||
             _jsa.dangers.expositionProduitsChimiques ||
             _jsa.dangers.chuteHauteur ||
             _jsa.dangers.electrification ||
             _jsa.dangers.incendiesExplosion ||
             _jsa.dangers.mauvaisesPostures ||
             _jsa.dangers.chutePlainPied ||
             _autrePhysiqueController.text.trim().isNotEmpty;
    case 3:
      return _jsa.exigencesGenerales.signaletiqueSecurite ||
             _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible ||
             _jsa.exigencesGenerales.uneMinuteMaSecurite ||
             _jsa.exigencesGenerales.balise ||
             _jsa.exigencesGenerales.zoneTravailPropre ||
             _jsa.exigencesGenerales.toolboxMeeting ||
             _jsa.exigencesGenerales.permisTravail ||
             _jsa.exigencesGenerales.extincteurs ||
             _jsa.exigencesGenerales.outilsMaterielsIsolants ||
             _jsa.exigencesGenerales.boitePharmacie ||
             _autreExigenceController.text.trim().isNotEmpty;
    case 4:
      return _jsa.epi.casqueSecurite ||
             _jsa.epi.bouchonsOreille ||
             _jsa.epi.lunettesProtection ||
             _jsa.epi.harnaisSecurite ||
             _jsa.epi.chaussureSecurite ||
             _jsa.epi.masqueSecurite ||
             _jsa.epi.combinaisonLongueManche ||
             _jsa.epi.gantsIsolants ||
             _jsa.epi.cacheNez ||
             _jsa.epi.gilet ||
             _autreEPIController.text.trim().isNotEmpty;
    case 5:
      return _jsa.verificationFinale.travailTermineNA ||
             _jsa.verificationFinale.travailTermineApplicable ||
             _jsa.verificationFinale.consignationCadenasRetireNA ||
             _jsa.verificationFinale.consignationCadenasRetireApplicable ||
             _jsa.verificationFinale.absenceConsignataireProcedureNA ||
             _jsa.verificationFinale.absenceConsignataireProcedureApplicable ||
             _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA ||
             _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable ||
             _jsa.verificationFinale.materielEnleveZoneNettoyeeNA ||
             _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable ||
             _jsa.verificationFinale.risquesSupprimesEquipementPretNA ||
             _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable ||
             _autresPointsVerifController.text.trim().isNotEmpty ||
             _donneurOrdreSignatureController.text.trim().isNotEmpty ||
             _chargeAffairesSignatureController.text.trim().isNotEmpty;
    default:
      return false;
  }
}

  Widget _buildSectionTitle(String title, Color color, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16, top: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isSmallScreen ? 16 : 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SOUS-CATÉGORIES ====================

  Widget _buildSub1Operation(bool isSmallScreen) {
    final error = _getCurrentSubCategoryError();
    final isValid = _isCurrentSubCategoryValid();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(isValid, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          // Champ Opération
          Text(
            'Opération à effectuer *',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: _hasAttemptedNext && !isValid ? Colors.red : AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: _hasAttemptedNext && !isValid && _operationController.text.trim().isEmpty
                  ? Border.all(color: Colors.red.shade300, width: 1.5)
                  : null,
            ),
            child: TextFormField(
              controller: _operationController,
              focusNode: _operationFocusNode,
              maxLines: 3,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
              decoration: InputDecoration(
                hintText: 'Décrivez l\'opération à effectuer...',
                hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                suffixIcon: _operationController.text.trim().isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green, size: isSmallScreen ? 20 : 22)
                    : null,
              ),
              onChanged: (_) {
                _saveJSA();
                if (_hasAttemptedNext && _operationController.text.trim().isNotEmpty) {
                  setState(() {});
                }
              },
            ),
          ),
          
          // Message d'erreur spécifique
          if (_hasAttemptedNext && !isValid && _operationController.text.trim().isEmpty)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: isSmallScreen ? 14 : 16),
                  const SizedBox(width: 6),
                  Text(
                    error ?? 'Ce champ est requis',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.red),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: isSmallScreen ? 24 : 28),
          
          // Section Inspecteurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inspecteurs *',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: _hasAttemptedNext && _jsa.inspecteurs.isEmpty ? Colors.red : AppTheme.darkBlue,
                ),
              ),
              if (_jsa.inspecteurs.length < 6)
                TextButton.icon(
                  onPressed: _addInspecteur,
                  icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: isSmallScreen ? 18 : 20),
                  label: Text(
                    'Ajouter',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 13 : 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_jsa.inspecteurs.isEmpty)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: _hasAttemptedNext ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasAttemptedNext ? Colors.red.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  _hasAttemptedNext ? 'Au moins un inspecteur est requis' : 'Ajoutez un inspecteur',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: _hasAttemptedNext ? Colors.red.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _jsa.inspecteurs.length,
              itemBuilder: (_, i) {
                final insp = _jsa.inspecteurs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: isSmallScreen ? 36 : 40,
                      height: isSmallScreen ? 36 : 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: AppTheme.primaryBlue, size: isSmallScreen ? 18 : 20),
                    ),
                    title: Text(
                      '${insp.prenom} ${insp.nom}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: insp.signature.isNotEmpty
                        ? Text(
                            insp.signature,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: isSmallScreen ? 18 : 20),
                      onPressed: () => _removeInspecteur(i),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSub2PlanUrgence(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(true, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          _buildModernCheckbox(
            'Voies d\'issues de secours identifiées',
            _jsa.planUrgence.voiesIssuesIdentifiees,
            (v) => setState(() => _jsa.planUrgence.voiesIssuesIdentifiees = v!),
            AppTheme.primaryBlue,
            isSmallScreen,
          ),
          _buildModernCheckbox(
            'Zones de rassemblement identifiées',
            _jsa.planUrgence.zonesRassemblementIdentifiees,
            (v) => setState(() => _jsa.planUrgence.zonesRassemblementIdentifiees = v!),
            AppTheme.primaryBlue,
            isSmallScreen,
          ),
          _buildModernCheckbox(
            'Consignes de sécurité internes',
            _jsa.planUrgence.consignesSecuriteInternes,
            (v) => setState(() => _jsa.planUrgence.consignesSecuriteInternes = v!),
            AppTheme.primaryBlue,
            isSmallScreen,
          ),
          const SizedBox(height: 20),
          
          _buildModernTextField(
            controller: _personneContactClientController,
            label: 'Personne à contacter chez le client',
            onChanged: (_) => _saveJSA(),
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildModernTextField(
            controller: _personneContactKESController,
            label: 'Personne à contacter chez KES',
            onChanged: (_) => _saveJSA(),
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSub3Dangers(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(true, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          _buildSectionTitle('Lié à l\'environnement', AppTheme.primaryBlue, isSmallScreen),
          _buildModernCheckbox('Choc électrique', _jsa.dangers.chocElectrique, (v) => setState(() => _jsa.dangers.chocElectrique = v!), AppTheme.primaryBlue, isSmallScreen),
          _buildModernCheckbox('Bruit', _jsa.dangers.bruit, (v) => setState(() => _jsa.dangers.bruit = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Stress thermique', _jsa.dangers.stressThermique, (v) => setState(() => _jsa.dangers.stressThermique = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Éclairage inadapté', _jsa.dangers.eclairageInadapte, (v) => setState(() => _jsa.dangers.eclairageInadapte = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Zone circulation mal définie', _jsa.dangers.zoneCirculationMalDefinie, (v) => setState(() => _jsa.dangers.zoneCirculationMalDefinie = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Sol accidenté', _jsa.dangers.solAccidente, (v) => setState(() => _jsa.dangers.solAccidente = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Émission (gaz, poussière)', _jsa.dangers.emissionGazPoussiere, (v) => setState(() => _jsa.dangers.emissionGazPoussiere = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Espace confiné', _jsa.dangers.espaceConfine, (v) => setState(() => _jsa.dangers.espaceConfine = v!), currentColor, isSmallScreen),
          _buildModernTextField(controller: _autreEnvironnementController, label: 'Autre (environnement)', onChanged: (_) => _saveJSA(), isSmallScreen: isSmallScreen),
          
          const SizedBox(height: 16),
          _buildSectionTitle('Physiques', currentColor, isSmallScreen),
          _buildModernCheckbox('Chute d\'objets', _jsa.dangers.chuteObjets, (v) => setState(() => _jsa.dangers.chuteObjets = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Coactivité', _jsa.dangers.coactivite, (v) => setState(() => _jsa.dangers.coactivite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Port de charge', _jsa.dangers.portCharge, (v) => setState(() => _jsa.dangers.portCharge = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Exposition produits chimiques', _jsa.dangers.expositionProduitsChimiques, (v) => setState(() => _jsa.dangers.expositionProduitsChimiques = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Chute de hauteur', _jsa.dangers.chuteHauteur, (v) => setState(() => _jsa.dangers.chuteHauteur = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Électrocution', _jsa.dangers.electrification, (v) => setState(() => _jsa.dangers.electrification = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Incendies/explosion', _jsa.dangers.incendiesExplosion, (v) => setState(() => _jsa.dangers.incendiesExplosion = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Mauvaises postures', _jsa.dangers.mauvaisesPostures, (v) => setState(() => _jsa.dangers.mauvaisesPostures = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Chute de plain-pied', _jsa.dangers.chutePlainPied, (v) => setState(() => _jsa.dangers.chutePlainPied = v!), currentColor, isSmallScreen),
          _buildModernTextField(controller: _autrePhysiqueController, label: 'Autre (physique)', onChanged: (_) => _saveJSA(), isSmallScreen: isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSub4Exigences(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(true, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          _buildModernCheckbox('Signalétique sécurité', _jsa.exigencesGenerales.signaletiqueSecurite, (v) => setState(() => _jsa.exigencesGenerales.signaletiqueSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Fiche données sécurité', _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible, (v) => setState(() => _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('1 minute ma sécurité', _jsa.exigencesGenerales.uneMinuteMaSecurite, (v) => setState(() => _jsa.exigencesGenerales.uneMinuteMaSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Balise', _jsa.exigencesGenerales.balise, (v) => setState(() => _jsa.exigencesGenerales.balise = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Zone de travail propre', _jsa.exigencesGenerales.zoneTravailPropre, (v) => setState(() => _jsa.exigencesGenerales.zoneTravailPropre = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Toolbox meeting', _jsa.exigencesGenerales.toolboxMeeting, (v) => setState(() => _jsa.exigencesGenerales.toolboxMeeting = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Permis de travail', _jsa.exigencesGenerales.permisTravail, (v) => setState(() => _jsa.exigencesGenerales.permisTravail = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Extincteurs', _jsa.exigencesGenerales.extincteurs, (v) => setState(() => _jsa.exigencesGenerales.extincteurs = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Matériels isolants', _jsa.exigencesGenerales.outilsMaterielsIsolants, (v) => setState(() => _jsa.exigencesGenerales.outilsMaterielsIsolants = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Boite à pharmacie', _jsa.exigencesGenerales.boitePharmacie, (v) => setState(() => _jsa.exigencesGenerales.boitePharmacie = v!), currentColor, isSmallScreen),
          _buildModernTextField(controller: _autreExigenceController, label: 'Autre exigence', onChanged: (_) => _saveJSA(), isSmallScreen: isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSub5EPI(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(true, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          _buildModernCheckbox('Casque de sécurité', _jsa.epi.casqueSecurite, (v) => setState(() => _jsa.epi.casqueSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Bouchons d\'oreille', _jsa.epi.bouchonsOreille, (v) => setState(() => _jsa.epi.bouchonsOreille = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Lunettes de protection', _jsa.epi.lunettesProtection, (v) => setState(() => _jsa.epi.lunettesProtection = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Harnais de sécurité', _jsa.epi.harnaisSecurite, (v) => setState(() => _jsa.epi.harnaisSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Chaussure de sécurité', _jsa.epi.chaussureSecurite, (v) => setState(() => _jsa.epi.chaussureSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Masque de sécurité', _jsa.epi.masqueSecurite, (v) => setState(() => _jsa.epi.masqueSecurite = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Combinaison longue manche', _jsa.epi.combinaisonLongueManche, (v) => setState(() => _jsa.epi.combinaisonLongueManche = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Gants isolants', _jsa.epi.gantsIsolants, (v) => setState(() => _jsa.epi.gantsIsolants = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Cache-nez', _jsa.epi.cacheNez, (v) => setState(() => _jsa.epi.cacheNez = v!), currentColor, isSmallScreen),
          _buildModernCheckbox('Gilet', _jsa.epi.gilet, (v) => setState(() => _jsa.epi.gilet = v!), currentColor, isSmallScreen),
          _buildModernTextField(controller: _autreEPIController, label: 'Autre EPI', onChanged: (_) => _saveJSA(), isSmallScreen: isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSub6Verification(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBadge(true, isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildModernNARow(
                  'Le travail est terminé',
                  _jsa.verificationFinale.travailTermineNA,
                  _jsa.verificationFinale.travailTermineApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.travailTermineNA = na;
                    _jsa.verificationFinale.travailTermineApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
                const Divider(),
                _buildModernNARow(
                  'En cas de consignation, a retiré le cadenas',
                  _jsa.verificationFinale.consignationCadenasRetireNA,
                  _jsa.verificationFinale.consignationCadenasRetireApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.consignationCadenasRetireNA = na;
                    _jsa.verificationFinale.consignationCadenasRetireApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
                const Divider(),
                _buildModernNARow(
                  'Absence consignataire : procédure appliquée',
                  _jsa.verificationFinale.absenceConsignataireProcedureNA,
                  _jsa.verificationFinale.absenceConsignataireProcedureApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.absenceConsignataireProcedureNA = na;
                    _jsa.verificationFinale.absenceConsignataireProcedureApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
                const Divider(),
                _buildModernNARow(
                  'Consignataire absent, procédure appliquée',
                  _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA,
                  _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA = na;
                    _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
                const Divider(),
                _buildModernNARow(
                  'Matériel enlevé, zone nettoyée',
                  _jsa.verificationFinale.materielEnleveZoneNettoyeeNA,
                  _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.materielEnleveZoneNettoyeeNA = na;
                    _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
                const Divider(),
                _buildModernNARow(
                  'Risques supprimés, équipement prêt',
                  _jsa.verificationFinale.risquesSupprimesEquipementPretNA,
                  _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable,
                  (na, app) => setState(() {
                    _jsa.verificationFinale.risquesSupprimesEquipementPretNA = na;
                    _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable = app;
                  }),
                  currentColor,
                  isSmallScreen,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildModernTextField(
            controller: _autresPointsVerifController,
            label: 'Autres points à vérifier',
            onChanged: (_) => _saveJSA(),
            isSmallScreen: isSmallScreen,
            maxLines: 3,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: currentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.draw_outlined, color: currentColor, size: isSmallScreen ? 18 : 20),
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    Text(
                      'Signatures',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: currentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _donneurOrdreSignatureController,
                  label: 'Donneur d\'ordre',
                  onChanged: (_) => _saveJSA(),
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: _chargeAffairesSignatureController,
                  label: 'Chargé d\'affaires',
                  onChanged: (_) => _saveJSA(),
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS UTILITAIRES ====================

  Widget _buildModernCheckbox(
    String title,
    bool value,
    Function(bool?) onChanged,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: (v) {
          onChanged(v);
          _saveJSA();
        },
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    required bool isSmallScreen,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernNARow(
    String title,
    bool na,
    bool app,
    Function(bool, bool) onChanged,
    Color color,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NA',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: na ? color : Colors.grey.shade600,
                  fontWeight: na ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Checkbox(
                value: na,
                onChanged: (v) {
                  onChanged(v ?? false, app);
                  _saveJSA();
                },
                visualDensity: VisualDensity.compact,
                activeColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'App',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: app ? color : Colors.grey.shade600,
                  fontWeight: app ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Checkbox(
                value: app,
                onChanged: (v) {
                  onChanged(na, v ?? false);
                  _saveJSA();
                },
                visualDensity: VisualDensity.compact,
                activeColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Pour AutomaticKeepAliveClientMixin
    
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _getCurrentSubCategoryError();
    final isValid = _isCurrentSubCategoryValid();
    final isLastSubCategory = currentSubCategory == totalSubCategories - 1;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Carte d'en-tête moderne
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [currentColor, currentColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              boxShadow: [
                BoxShadow(
                  color: currentColor.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 8 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                        ),
                        child: Icon(
                          currentIcon,
                          color: Colors.white,
                          size: isSmallScreen ? 22 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subCategories[currentSubCategory],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Catégorie ${currentSubCategory + 1}/${totalSubCategories}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge de validation
                      if (isValid)
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: isSmallScreen ? 16 : 18,
                          ),
                        ),
                    ],
                  ),
                  
                  // Message d'erreur (si présent)
                  if (error != null) ...[
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  
                  // Barre de progression
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression JSA',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '${((currentSubCategory + 1) / totalSubCategories * 100).round()}%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 5 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (currentSubCategory + 1) / totalSubCategories,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: isSmallScreen ? 4 : 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu de la sous-catégorie
          Expanded(
            child: IndexedStack(
              index: currentSubCategory,
              children: [
                _buildSub1Operation(isSmallScreen),
                _buildSub2PlanUrgence(isSmallScreen),
                _buildSub3Dangers(isSmallScreen),
                _buildSub4Exigences(isSmallScreen),
                _buildSub5EPI(isSmallScreen),
                _buildSub6Verification(isSmallScreen),
              ],
            ),
          ),
          
          // Barre de navigation
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                Expanded(
                  child: OutlinedButton(
                    onPressed: currentSubCategory > 0 ? _previousSubCategory : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                      side: BorderSide(
                        color: currentSubCategory > 0 ? AppTheme.primaryBlue : Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: currentSubCategory > 0 ? AppTheme.primaryBlue : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PRÉCÉDENT',
                          style: TextStyle(
                            color: currentSubCategory > 0 ? AppTheme.primaryBlue : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLastSubCategory ? _goToRenseignements : _nextSubCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastSubCategory ? 'RENSEIGNEMENTS' : 'SUIVANT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!isLastSubCategory) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
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

  @override
  void dispose() {
    _operationController.dispose();
    _autreEnvironnementController.dispose();
    _autrePhysiqueController.dispose();
    _autreExigenceController.dispose();
    _autreEPIController.dispose();
    _autresPointsVerifController.dispose();
    _donneurOrdreSignatureController.dispose();
    _chargeAffairesSignatureController.dispose();
    _personneContactClientController.dispose();
    _personneContactKESController.dispose();
    _operationFocusNode.dispose();
    super.dispose();
  }
}