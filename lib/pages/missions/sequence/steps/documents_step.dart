// lib/pages/missions/sequence/steps/documents_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/features/mission/presentation/providers/mission_detail_provider.dart';

class DocumentsStep extends ConsumerStatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const DocumentsStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  ConsumerState<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends ConsumerState<DocumentsStep> {

  final TextEditingController _nouveauDocumentController = TextEditingController();

  final List<Map<String, dynamic>> _documentsStandards = [
    {'field': 'doc_cahier_prescriptions', 'title': 'Cahier des prescriptions techniques ayant permis la réalisation des installations'},
    {'field': 'doc_notes_calculs', 'title': 'Notes de calculs justifiant le dimensionnement des canalisations électriques et des dispositifs de protection'},
    {'field': 'doc_schemas_unifilaires', 'title': 'Schémas unifilaires des installations électriques'},
    {'field': 'doc_plan_masse', 'title': 'Plan de masse à l\'échelle des installations avec implantations des prises de terre et électriques enterrés'},
    {'field': 'doc_plans_architecturaux', 'title': 'Plans architecturaux d\'implantation des différents circuits'},
    {'field': 'doc_declarations_ce', 'title': 'Déclaration CE de conformité et notices des appareillages et câbles installés'},
    {'field': 'doc_liste_installations', 'title': 'Liste des installations de sécurité et effectif maximal des différents locaux ou bâtiments'},
    {'field': 'doc_rapport_derniere_verif', 'title': 'Rapport de dernière vérification'},
    {'field': 'doc_plan_locaux_risques', 'title': 'Plan des locaux, avec indications des locaux à risques particuliers d\'influences externes'},
    {'field': 'doc_rapport_analyse_foudre', 'title': 'Rapport d\'analyse risque foudre'},
    {'field': 'doc_rapport_etude_foudre', 'title': 'Rapport d\'étude technique foudre'},
    {'field': 'doc_registre_securite', 'title': 'Registre de sécurité (si applicable)'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nouveauDocumentController.dispose();
    super.dispose();
  }

  Future<void> _handleDocumentChanged(String documentField, bool value) async {
    final notifier = ref.read(missionDetailProvider(widget.mission.id).notifier);
    await notifier.updateDocumentStatus(documentField, value);
    final current = ref.read(missionDetailProvider(widget.mission.id)).value;
    if (current != null) {
      _notifyDataChanged(current);
    }
  }

  Future<void> _ajouterDocumentPersonnalise() async {
    _nouveauDocumentController.clear();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un document'),
        content: TextField(
          controller: _nouveauDocumentController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom du document',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (_nouveauDocumentController.text.trim().isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true) {
      final nouveauNom = _nouveauDocumentController.text.trim();
      if (nouveauNom.isNotEmpty) {
        final notifier = ref.read(missionDetailProvider(widget.mission.id).notifier);
        final success = await notifier.addDocumentPersonnalise(nouveauNom);
        
        if (success) {
          final current = ref.read(missionDetailProvider(widget.mission.id)).value;
          if (current != null) {
            _notifyDataChanged(current);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document "$nouveauNom" ajouté'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce document existe déjà'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _supprimerDocumentPersonnalise(String documentNom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Voulez-vous vraiment supprimer "$documentNom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(missionDetailProvider(widget.mission.id).notifier);
      final success = await notifier.removeDocumentPersonnalise(documentNom);
      
      if (success) {
        final current = ref.read(missionDetailProvider(widget.mission.id)).value;
        if (current != null) {
          _notifyDataChanged(current);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "$documentNom" supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _notifyDataChanged(Mission mission) {
    widget.onDataChanged({
      'documents': {
        'doc_cahier_prescriptions': mission.docCahierPrescriptions,
        'doc_notes_calculs': mission.docNotesCalculs,
        'doc_schemas_unifilaires': mission.docSchemasUnifilaires,
        'doc_plan_masse': mission.docPlanMasse,
        'doc_plans_architecturaux': mission.docPlansArchitecturaux,
        'doc_declarations_ce': mission.docDeclarationsCe,
        'doc_liste_installations': mission.docListeInstallations,
        'doc_plan_locaux_risques': mission.docPlanLocauxRisques,
        'doc_rapport_analyse_foudre': mission.docRapportAnalyseFoudre,
        'doc_rapport_etude_foudre': mission.docRapportEtudeFoudre,
        'doc_registre_securite': mission.docRegistreSecurite,
        'doc_rapport_derniere_verif': mission.docRapportDerniereVerif,
        'doc_autre': mission.docAutre,
      }
    });
  }

  Widget _buildDocumentTile({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: value ? Colors.green.shade50 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value ? Colors.green.shade800 : null,
                  ),
                ),
                value: value,
                onChanged: onChanged,
                activeColor: Colors.green,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(missionDetailProvider(widget.mission.id));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erreur: $err')),
      data: (mission) {
        // Optionnel : notifier le changement d'état au premier chargement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyDataChanged(mission);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
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
              
              // Documents standards
              ..._documentsStandards.map((doc) => _buildDocumentTile(
                title: doc['title'] as String,
                value: _getDocumentValue(mission, doc['field'] as String),
                onChanged: (val) => _handleDocumentChanged(doc['field'] as String, val ?? false),
              )),
              
              // Documents personnalisés
              ...mission.autresDocuments.map((doc) => _buildDocumentTile(
                title: doc,
                value: true,
                onChanged: (_) {},
                onDelete: () => _supprimerDocumentPersonnalise(doc),
              )),
              
              const SizedBox(height: 16),
              
              // Bouton "Autre"
              TextButton.icon(
                onPressed: _ajouterDocumentPersonnalise,
                icon: const Icon(Icons.add),
                label: const Text('Autre'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _getDocumentValue(Mission mission, String field) {
    switch (field) {
      case 'doc_cahier_prescriptions': return mission.docCahierPrescriptions;
      case 'doc_notes_calculs': return mission.docNotesCalculs;
      case 'doc_schemas_unifilaires': return mission.docSchemasUnifilaires;
      case 'doc_plan_masse': return mission.docPlanMasse;
      case 'doc_plans_architecturaux': return mission.docPlansArchitecturaux;
      case 'doc_declarations_ce': return mission.docDeclarationsCe;
      case 'doc_liste_installations': return mission.docListeInstallations;
      case 'doc_plan_locaux_risques': return mission.docPlanLocauxRisques;
      case 'doc_rapport_analyse_foudre': return mission.docRapportAnalyseFoudre;
      case 'doc_rapport_etude_foudre': return mission.docRapportEtudeFoudre;
      case 'doc_registre_securite': return mission.docRegistreSecurite;
      case 'doc_rapport_derniere_verif': return mission.docRapportDerniereVerif;
      case 'doc_autre': return mission.docAutre;
      default: return false;
    }
  }
}