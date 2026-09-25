import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class MissionDocumentsSection extends StatelessWidget {
  final Mission mission;
  final Function(String, bool)? onDocumentChanged;

  const MissionDocumentsSection({
    super.key,
    required this.mission,
    this.onDocumentChanged,
  });

  Widget _buildDocumentItem(BuildContext context, String label, bool hasDocument, IconData icon, String documentField) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: hasDocument ? AppTheme.primaryBlue : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: hasDocument ? AppTheme.darkBlue : Colors.grey,
            fontSize: 14,
            fontWeight: hasDocument ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Checkbox(
          value: hasDocument,
          onChanged: (value) {
            if (value != null) {
              // Appeler la callback pour mettre à jour l'état
              onDocumentChanged?.call(documentField, value);
              
              // Snackbar de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label ${value ? 'coché' : 'décoché'}'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          activeColor: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Documents Associés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildDocumentItem(
              context,
              'Cahier des prescriptions',
              mission.docCahierPrescriptions,
              Icons.description_outlined,
              'doc_cahier_prescriptions',
            ),
            
            _buildDocumentItem(
              context,
              'Notes de calculs',
              mission.docNotesCalculs,
              Icons.calculate_outlined,
              'doc_notes_calculs',
            ),
            
            _buildDocumentItem(
              context,
              'Schémas unifilaires',
              mission.docSchemasUnifilaires,
              Icons.bolt_outlined,
              'doc_schemas_unifilaires',
            ),
            
            _buildDocumentItem(
              context,
              'Plan de masse',
              mission.docPlanMasse,
              Icons.map_outlined,
              'doc_plan_masse',
            ),
            
            _buildDocumentItem(
              context,
              'Plans architecturaux',
              mission.docPlansArchitecturaux,
              Icons.architecture_outlined,
              'doc_plans_architecturaux',
            ),
            
            _buildDocumentItem(
              context,
              'Déclarations CE',
              mission.docDeclarationsCe,
              Icons.assignment_outlined,
              'doc_declarations_ce',
            ),
            
            _buildDocumentItem(
              context,
              'Liste des installations',
              mission.docListeInstallations,
              Icons.list_alt_outlined,
              'doc_liste_installations',
            ),
            
            _buildDocumentItem(
              context,
              'Plan locaux à risques',
              mission.docPlanLocauxRisques,
              Icons.warning_outlined,
              'doc_plan_locaux_risques',
            ),
            
            _buildDocumentItem(
              context,
              'Rapport analyse foudre',
              mission.docRapportAnalyseFoudre,
              Icons.analytics_outlined,
              'doc_rapport_analyse_foudre',
            ),
            
            _buildDocumentItem(
              context,
              'Rapport étude foudre',
              mission.docRapportEtudeFoudre,
              Icons.analytics_outlined,
              'doc_rapport_etude_foudre',
            ),
            
            _buildDocumentItem(
              context,
              'Registre de sécurité',
              mission.docRegistreSecurite,
              Icons.security_outlined,
              'doc_registre_securite',
            ),
            
            _buildDocumentItem(
              context,
              'Rapport dernière vérification',
              mission.docRapportDerniereVerif,
              Icons.history_outlined,
              'doc_rapport_derniere_verif',
            ),
            _buildDocumentItem(
              context,
              'Rapport Q18 précédent',
              mission.docRapportQ18,
              Icons.assignment_outlined,
              'doc_rapport_q18',
            ),
             _buildDocumentItem(
              context,
              'Autre Document',
              mission.docAutre,
              Icons.outbox_sharp,
              'doc_autre',
            ),
          ],
        ),
      ),
    );
  }
}