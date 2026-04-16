// lib/pages/missions/sequence/steps/jsa_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/widgets/app_bottom_sheet.dart';

class JsaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const JsaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<JsaStep> createState() => JsaStepState();
}

class JsaStepState extends State<JsaStep> {
  late JSA _jsa;
  bool _isLoading = true;

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

  // État de validation
  bool _hasAttemptedValidation = false;

  static const _subCategories = [
    'Opération & Équipe',
    'Plan d\'urgence',
    'Dangers',
    'Exigences générales (EPC)',
    'EPI',
    'Vérification finale',
  ];

  int get totalSubCategories => _subCategories.length;
  int get currentSubCategory => _jsa.currentSubCategory;

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
    } catch (e) {
      print('❌ Erreur chargement JSA: $e');
    } finally {
      setState(() => _isLoading = false);
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
    widget.onDataChanged({'jsa_saved': true});
  }

  bool _isCurrentSubCategoryValid() {
    switch (currentSubCategory) {
      case 0:
        return _operationController.text.trim().isNotEmpty && _jsa.inspecteurs.isNotEmpty;
      default:
        return true;
    }
  }

  String? _getCurrentSubCategoryError() {
    if (currentSubCategory == 0) {
      if (_operationController.text.trim().isEmpty) return 'L\'opération à effectuer est requise';
      if (_jsa.inspecteurs.isEmpty) return 'Au moins un inspecteur est requis';
    }
    return null;
  }

  void _nextSubCategory() {
    if (!_isCurrentSubCategoryValid()) {
      _showError(_getCurrentSubCategoryError() ?? 'Veuillez compléter cette section');
      return;
    }
    if (currentSubCategory < totalSubCategories - 1) {
      setState(() => _jsa.currentSubCategory++);
      _saveJSA();
    }
  }

  void _previousSubCategory() {
    if (currentSubCategory > 0) {
      setState(() => _jsa.currentSubCategory--);
      _saveJSA();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ───────────────────────────────────────────────────
  // Inspecteurs
  // ───────────────────────────────────────────────────
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
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                children: [
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  TextField(
                    controller: prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 14),
                  TextField(
                    controller: signatureController,
                    decoration: const InputDecoration(
                      labelText: 'Signature',
                      prefixIcon: Icon(Icons.draw_outlined),
                      border: OutlineInputBorder(),
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
          bottomButton: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitInspecteur(
                    nomController, prenomController, signatureController,
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
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
    
    Navigator.pop(context);
    setState(() {
      _jsa.inspecteurs.add(JSAInspecteur(
        nom: nom,
        prenom: prenom,
        signature: signatureCtrl.text.trim(),
      ));
    });
    _saveJSA();
  }

  void _removeInspecteur(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet inspecteur ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _jsa.inspecteurs.removeAt(index));
              _saveJSA();
              Navigator.pop(context);
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Build principal
  // ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final error = _getCurrentSubCategoryError();

    return Column(
      children: [
        // En-tête avec indicateur de sous-catégorie
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: error != null ? Colors.red.shade50 : AppTheme.primaryBlue.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: error != null ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentSubCategory + 1}/${totalSubCategories}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  _subCategories[currentSubCategory],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: error != null ? Colors.red : AppTheme.darkBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (error != null)
                Flexible(
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),

        // Barre de progression
        LinearProgressIndicator(
          value: (currentSubCategory + 1) / totalSubCategories,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 3,
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
              if (currentSubCategory > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousSubCategory,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Précédent'),
                  ),
                ),
              if (currentSubCategory > 0) SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextSubCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(currentSubCategory == totalSubCategories - 1 ? 'Terminer' : 'Suivant'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 1 : Opération & Équipe
  // ───────────────────────────────────────────────────
  Widget _buildSub1Operation(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opération à effectuer *',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _operationController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Décrivez l\'opération à effectuer...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _saveJSA(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inspecteurs *',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: _jsa.inspecteurs.isEmpty ? Colors.red : AppTheme.darkBlue,
                ),
              ),
              if (_jsa.inspecteurs.length < 6)
                TextButton.icon(
                  onPressed: _addInspecteur,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_jsa.inspecteurs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Center(
                child: Text(
                  'Au moins un inspecteur est requis',
                  style: TextStyle(color: Colors.red),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${insp.prenom} ${insp.nom}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onPressed: () => _removeInspecteur(i),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 2 : Plan d'urgence
  // ───────────────────────────────────────────────────
  Widget _buildSub2PlanUrgence(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildCheckbox(
            'Voies d\'issues de secours identifiées',
            _jsa.planUrgence.voiesIssuesIdentifiees,
            (v) => setState(() => _jsa.planUrgence.voiesIssuesIdentifiees = v!),
          ),
          _buildCheckbox(
            'Zones de rassemblement identifiées',
            _jsa.planUrgence.zonesRassemblementIdentifiees,
            (v) => setState(() => _jsa.planUrgence.zonesRassemblementIdentifiees = v!),
          ),
          _buildCheckbox(
            'Consignes de sécurité internes',
            _jsa.planUrgence.consignesSecuriteInternes,
            (v) => setState(() => _jsa.planUrgence.consignesSecuriteInternes = v!),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _personneContactClientController,
            label: 'Personne de contact chez le client',
            onChanged: (_) => _saveJSA(),
          ),
          _buildTextField(
            controller: _personneContactKESController,
            label: 'Personne de contact KES',
            onChanged: (_) => _saveJSA(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 3 : Dangers
  // ───────────────────────────────────────────────────
  Widget _buildSub3Dangers(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Lié à l\'environnement'),
          _buildCheckbox('Choc électrique', _jsa.dangers.chocElectrique, (v) => setState(() => _jsa.dangers.chocElectrique = v!)),
          _buildCheckbox('Bruit', _jsa.dangers.bruit, (v) => setState(() => _jsa.dangers.bruit = v!)),
          _buildCheckbox('Stress thermique', _jsa.dangers.stressThermique, (v) => setState(() => _jsa.dangers.stressThermique = v!)),
          _buildCheckbox('Éclairage inadapté', _jsa.dangers.eclairageInadapte, (v) => setState(() => _jsa.dangers.eclairageInadapte = v!)),
          _buildCheckbox('Zone circulation mal définie', _jsa.dangers.zoneCirculationMalDefinie, (v) => setState(() => _jsa.dangers.zoneCirculationMalDefinie = v!)),
          _buildCheckbox('Sol accidenté', _jsa.dangers.solAccidente, (v) => setState(() => _jsa.dangers.solAccidente = v!)),
          _buildCheckbox('Émission (gaz, poussière)', _jsa.dangers.emissionGazPoussiere, (v) => setState(() => _jsa.dangers.emissionGazPoussiere = v!)),
          _buildCheckbox('Espace confiné', _jsa.dangers.espaceConfine, (v) => setState(() => _jsa.dangers.espaceConfine = v!)),
          _buildTextField(controller: _autreEnvironnementController, label: 'Autre', onChanged: (_) => _saveJSA()),
          
          const SizedBox(height: 16),
          _buildSectionTitle('Physiques'),
          _buildCheckbox('Chute d\'objets', _jsa.dangers.chuteObjets, (v) => setState(() => _jsa.dangers.chuteObjets = v!)),
          _buildCheckbox('Coactivité', _jsa.dangers.coactivite, (v) => setState(() => _jsa.dangers.coactivite = v!)),
          _buildCheckbox('Port de charge', _jsa.dangers.portCharge, (v) => setState(() => _jsa.dangers.portCharge = v!)),
          _buildCheckbox('Exposition produits chimiques', _jsa.dangers.expositionProduitsChimiques, (v) => setState(() => _jsa.dangers.expositionProduitsChimiques = v!)),
          _buildCheckbox('Chute de hauteur', _jsa.dangers.chuteHauteur, (v) => setState(() => _jsa.dangers.chuteHauteur = v!)),
          _buildCheckbox('Électrocution', _jsa.dangers.electrification, (v) => setState(() => _jsa.dangers.electrification = v!)),
          _buildCheckbox('Incendies/explosion', _jsa.dangers.incendiesExplosion, (v) => setState(() => _jsa.dangers.incendiesExplosion = v!)),
          _buildCheckbox('Mauvaises postures', _jsa.dangers.mauvaisesPostures, (v) => setState(() => _jsa.dangers.mauvaisesPostures = v!)),
          _buildCheckbox('Chute de plain-pied', _jsa.dangers.chutePlainPied, (v) => setState(() => _jsa.dangers.chutePlainPied = v!)),
          _buildTextField(controller: _autrePhysiqueController, label: 'Autre', onChanged: (_) => _saveJSA()),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 4 : Exigences générales (EPC)
  // ───────────────────────────────────────────────────
  Widget _buildSub4Exigences(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildCheckbox('Signalétique sécurité', _jsa.exigencesGenerales.signaletiqueSecurite, (v) => setState(() => _jsa.exigencesGenerales.signaletiqueSecurite = v!)),
          _buildCheckbox('Fiche données sécurité', _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible, (v) => setState(() => _jsa.exigencesGenerales.ficheDonneeSecuriteDisponible = v!)),
          _buildCheckbox('1 minute ma sécurité', _jsa.exigencesGenerales.uneMinuteMaSecurite, (v) => setState(() => _jsa.exigencesGenerales.uneMinuteMaSecurite = v!)),
          _buildCheckbox('Balise', _jsa.exigencesGenerales.balise, (v) => setState(() => _jsa.exigencesGenerales.balise = v!)),
          _buildCheckbox('Zone de travail propre', _jsa.exigencesGenerales.zoneTravailPropre, (v) => setState(() => _jsa.exigencesGenerales.zoneTravailPropre = v!)),
          _buildCheckbox('Toolbox meeting', _jsa.exigencesGenerales.toolboxMeeting, (v) => setState(() => _jsa.exigencesGenerales.toolboxMeeting = v!)),
          _buildCheckbox('Permis de travail', _jsa.exigencesGenerales.permisTravail, (v) => setState(() => _jsa.exigencesGenerales.permisTravail = v!)),
          _buildCheckbox('Extincteurs', _jsa.exigencesGenerales.extincteurs, (v) => setState(() => _jsa.exigencesGenerales.extincteurs = v!)),
          _buildCheckbox('Matériels isolants', _jsa.exigencesGenerales.outilsMaterielsIsolants, (v) => setState(() => _jsa.exigencesGenerales.outilsMaterielsIsolants = v!)),
          _buildCheckbox('Boite à pharmacie', _jsa.exigencesGenerales.boitePharmacie, (v) => setState(() => _jsa.exigencesGenerales.boitePharmacie = v!)),
          _buildTextField(controller: _autreExigenceController, label: 'Autre', onChanged: (_) => _saveJSA()),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 5 : EPI
  // ───────────────────────────────────────────────────
  Widget _buildSub5EPI(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildCheckbox('Casque de sécurité', _jsa.epi.casqueSecurite, (v) => setState(() => _jsa.epi.casqueSecurite = v!)),
          _buildCheckbox('Bouchons d\'oreille', _jsa.epi.bouchonsOreille, (v) => setState(() => _jsa.epi.bouchonsOreille = v!)),
          _buildCheckbox('Lunettes de protection', _jsa.epi.lunettesProtection, (v) => setState(() => _jsa.epi.lunettesProtection = v!)),
          _buildCheckbox('Harnais de sécurité', _jsa.epi.harnaisSecurite, (v) => setState(() => _jsa.epi.harnaisSecurite = v!)),
          _buildCheckbox('Chaussure de sécurité', _jsa.epi.chaussureSecurite, (v) => setState(() => _jsa.epi.chaussureSecurite = v!)),
          _buildCheckbox('Masque de sécurité', _jsa.epi.masqueSecurite, (v) => setState(() => _jsa.epi.masqueSecurite = v!)),
          _buildCheckbox('Combinaison longue manche', _jsa.epi.combinaisonLongueManche, (v) => setState(() => _jsa.epi.combinaisonLongueManche = v!)),
          _buildCheckbox('Gants isolants', _jsa.epi.gantsIsolants, (v) => setState(() => _jsa.epi.gantsIsolants = v!)),
          _buildCheckbox('Cache-nez', _jsa.epi.cacheNez, (v) => setState(() => _jsa.epi.cacheNez = v!)),
          _buildCheckbox('Gilet', _jsa.epi.gilet, (v) => setState(() => _jsa.epi.gilet = v!)),
          _buildTextField(controller: _autreEPIController, label: 'Autre', onChanged: (_) => _saveJSA()),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Sous-catégorie 6 : Vérification finale
  // ───────────────────────────────────────────────────
  Widget _buildSub6Verification(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          _buildNARow(
            'Le travail est terminé',
            _jsa.verificationFinale.travailTermineNA,
            _jsa.verificationFinale.travailTermineApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.travailTermineNA = na;
              _jsa.verificationFinale.travailTermineApplicable = app;
            }),
          ),
          _buildNARow(
            'En cas de consignation, a retiré le cadenas',
            _jsa.verificationFinale.consignationCadenasRetireNA,
            _jsa.verificationFinale.consignationCadenasRetireApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.consignationCadenasRetireNA = na;
              _jsa.verificationFinale.consignationCadenasRetireApplicable = app;
            }),
          ),
          _buildNARow(
            'Absence consignataire : procédure appliquée',
            _jsa.verificationFinale.absenceConsignataireProcedureNA,
            _jsa.verificationFinale.absenceConsignataireProcedureApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.absenceConsignataireProcedureNA = na;
              _jsa.verificationFinale.absenceConsignataireProcedureApplicable = app;
            }),
          ),
          _buildNARow(
            'Consignataire absent, procédure appliquée',
            _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA,
            _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeNA = na;
              _jsa.verificationFinale.consignataireAbsentProcedureAppliqueeApplicable = app;
            }),
          ),
          _buildNARow(
            'Matériel enlevé, zone nettoyée',
            _jsa.verificationFinale.materielEnleveZoneNettoyeeNA,
            _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.materielEnleveZoneNettoyeeNA = na;
              _jsa.verificationFinale.materielEnleveZoneNettoyeeApplicable = app;
            }),
          ),
          _buildNARow(
            'Risques supprimés, équipement prêt',
            _jsa.verificationFinale.risquesSupprimesEquipementPretNA,
            _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable,
            (na, app) => setState(() {
              _jsa.verificationFinale.risquesSupprimesEquipementPretNA = na;
              _jsa.verificationFinale.risquesSupprimesEquipementPretApplicable = app;
            }),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _autresPointsVerifController,
            label: 'Autres points',
            onChanged: (_) => _saveJSA(),
          ),
          const SizedBox(height: 16),
          Text(
            'Signatures',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _donneurOrdreSignatureController,
            label: 'Donneur d\'ordre',
            onChanged: (_) => _saveJSA(),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _chargeAffairesSignatureController,
            label: 'Chargé d\'affaires',
            onChanged: (_) => _saveJSA(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // Widgets utilitaires
  // ───────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: (v) {
        onChanged(v);
        _saveJSA();
      },
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppTheme.primaryBlue,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNARow(String title, bool na, bool app, Function(bool, bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('NA', style: TextStyle(fontSize: 12)),
              Checkbox(
                value: na,
                onChanged: (v) {
                  onChanged(v ?? false, app);
                  _saveJSA();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('App', style: TextStyle(fontSize: 12)),
              Checkbox(
                value: app,
                onChanged: (v) {
                  onChanged(na, v ?? false);
                  _saveJSA();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
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
    super.dispose();
  }
}