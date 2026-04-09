import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class DocumentsStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const DocumentsStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends State<DocumentsStep> {
  late Mission _mission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    final mission = HiveService.getMissionById(widget.mission.id);
    if (mission != null) {
      setState(() {
        _mission = mission;
        _isLoading = false;
      });
      _notifyDataChanged();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDocumentChanged(String documentField, bool value) async {
    setState(() {
      switch (documentField) {
        case 'doc_cahier_prescriptions':
          _mission.docCahierPrescriptions = value;
          break;
        case 'doc_notes_calculs':
          _mission.docNotesCalculs = value;
          break;
        case 'doc_schemas_unifilaires':
          _mission.docSchemasUnifilaires = value;
          break;
        case 'doc_plan_masse':
          _mission.docPlanMasse = value;
          break;
        case 'doc_plans_architecturaux':
          _mission.docPlansArchitecturaux = value;
          break;
        case 'doc_declarations_ce':
          _mission.docDeclarationsCe = value;
          break;
        case 'doc_liste_installations':
          _mission.docListeInstallations = value;
          break;
        case 'doc_plan_locaux_risques':
          _mission.docPlanLocauxRisques = value;
          break;
        case 'doc_rapport_analyse_foudre':
          _mission.docRapportAnalyseFoudre = value;
          break;
        case 'doc_rapport_etude_foudre':
          _mission.docRapportEtudeFoudre = value;
          break;
        case 'doc_registre_securite':
          _mission.docRegistreSecurite = value;
          break;
        case 'doc_rapport_derniere_verif':
          _mission.docRapportDerniereVerif = value;
          break;
        case 'doc_autre':
          _mission.docAutre = value;
          break;
      }
      _mission.updatedAt = DateTime.now();
    });
    
    await HiveService.updateDocumentStatus(
      missionId: _mission.id,
      documentField: documentField,
      value: value,
    );
    
    _notifyDataChanged();
  }

  void _notifyDataChanged() {
    widget.onDataChanged({
      'documents': {
        'doc_cahier_prescriptions': _mission.docCahierPrescriptions,
        'doc_notes_calculs': _mission.docNotesCalculs,
        'doc_schemas_unifilaires': _mission.docSchemasUnifilaires,
        'doc_plan_masse': _mission.docPlanMasse,
        'doc_plans_architecturaux': _mission.docPlansArchitecturaux,
        'doc_declarations_ce': _mission.docDeclarationsCe,
        'doc_liste_installations': _mission.docListeInstallations,
        'doc_plan_locaux_risques': _mission.docPlanLocauxRisques,
        'doc_rapport_analyse_foudre': _mission.docRapportAnalyseFoudre,
        'doc_rapport_etude_foudre': _mission.docRapportEtudeFoudre,
        'doc_registre_securite': _mission.docRegistreSecurite,
        'doc_rapport_derniere_verif': _mission.docRapportDerniereVerif,
        'doc_autre': _mission.docAutre,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity, // Ajoutez cette ligne
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_open, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Documents nécessaires à la vérification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Cochez les documents qui ont été fournis',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des documents
          _buildDocumentTile(
            title: 'Cahier des prescriptions techniques ayant permis la réalisation des installations',
            value: _mission.docCahierPrescriptions,
            onChanged: (bool? val) => _handleDocumentChanged('doc_cahier_prescriptions', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Notes de calculs justifiant le dimensionnement des canalisations électriques et des dispositifs de protection',
            value: _mission.docNotesCalculs,
            onChanged: (bool? val) => _handleDocumentChanged('doc_notes_calculs', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Schémas unifilaires des installations electriques',
            value: _mission.docSchemasUnifilaires,
            onChanged: (bool? val) => _handleDocumentChanged('doc_schemas_unifilaires', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Plan de masse à l\'échelle des  installations avec implantations des prises de terre et électriques enterrés',
            value: _mission.docPlanMasse,
            onChanged: (bool? val) => _handleDocumentChanged('doc_plan_masse', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Plans architecturaux d\’implantation des différents circuits',
            value: _mission.docPlansArchitecturaux,
            onChanged: (bool? val) => _handleDocumentChanged('doc_plans_architecturaux', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Déclaration CE de conformité et notices des appareillages et câbles installés',
            value: _mission.docDeclarationsCe,
            onChanged: (bool? val) => _handleDocumentChanged('doc_declarations_ce', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Liste des installations de sécurité et effectif maximal des différents locaux ou bâtiments ',
            value: _mission.docListeInstallations,
            onChanged: (bool? val) => _handleDocumentChanged('doc_liste_installations', val ?? false),
          ),

          _buildDocumentTile(
            title: 'Rapport de dernière vérification ',
            value: _mission.docListeInstallations,
            onChanged: (bool? val) => _handleDocumentChanged('doc_liste_installations', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Plan des locaux, avec indications des locaux à risques particuliers d\'influences externes (risque d\'incendie et risque d\'explosion) ',
            value: _mission.docPlanLocauxRisques,
            onChanged: (bool? val) => _handleDocumentChanged('doc_plan_locaux_risques', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Rapport d\'analyse risque foudre',
            value: _mission.docRapportAnalyseFoudre,
            onChanged: (bool? val) => _handleDocumentChanged('doc_rapport_analyse_foudre', val ?? false),
          ),
          
          _buildDocumentTile(
            title: 'Rapport d\'étude technique foudre',
            value: _mission.docRapportEtudeFoudre,
            onChanged: (bool? val) => _handleDocumentChanged('doc_rapport_etude_foudre', val ?? false),
          ),
        
        ],
      ),
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}