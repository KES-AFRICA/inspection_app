import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/ajouter_carte.dart';
import 'package:inspec_app/services/hive_service.dart';

class InstallationDetailScreen extends StatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;

  const InstallationDetailScreen({
    super.key,
    required this.mission,
    required this.title,
    required this.sectionKey,
    required this.champs,
  });

  @override
  State<InstallationDetailScreen> createState() => _InstallationDetailScreenState();
}

class _InstallationDetailScreenState extends State<InstallationDetailScreen> {
  List<Map<String, String>> _cartes = [];

  @override
  void initState() {
    super.initState();
    _loadCartes();
  }

  void _loadCartes() async {
    final cartes = await HiveService.getCartesFromSection(
      missionId: widget.mission.id,
      section: widget.sectionKey,
    );
    
    setState(() {
      _cartes = cartes;
    });
  }

  void _ajouterCarte() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCarteScreen(
          champs: widget.champs,
          carte: null,
          sectionKey: widget.sectionKey, // Passer la sectionKey
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final success = await HiveService.addCarteToSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        carte: result,
      );

      if (success) {
        _loadCartes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carte ajoutée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ajout')),
        );
      }
    }
  }

  void _editerCarte(int index) async {
    final carte = _cartes[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCarteScreen(
          champs: widget.champs,
          carte: carte,
          sectionKey: widget.sectionKey, // Passer la sectionKey
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final success = await HiveService.updateCarteInSection(
        missionId: widget.mission.id,
        section: widget.sectionKey,
        index: index,
        carte: result,
      );

      if (success) {
        _loadCartes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carte modifiée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la modification')),
        );
      }
    }
  }

  void _supprimerCarte(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette carte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await HiveService.removeCarteFromSection(
                missionId: widget.mission.id,
                section: widget.sectionKey,
                index: index,
              );

              if (success) {
               _loadCartes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carte supprimée')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur lors de la suppression')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _cartes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune carte ajoutée',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur le + pour ajouter une carte',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
              itemCount: _cartes.length,
              itemBuilder: (context, index) {
                final carte = _cartes[index];
                return _buildCarteItem(carte, index);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterCarte,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCarteItem(Map<String, String> carte, int index) {
    // Vérifier si c'est la section MT pour afficher l'IACM
    final isMoyenneTension = widget.sectionKey == 'alimentation_moyenne_tension';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _editerCarte(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.champs.map((champ) {
                String valeur = carte[champ] ?? '';
                
                // Pour la section MT, afficher aussi l'IACM si présent
                if (isMoyenneTension && champ == 'NATURE DU RESEAU' && carte.containsKey('PRESENCE IACM')) {
                  valeur = '$valeur (IACM: ${carte['PRESENCE IACM']})';
                }
                
                final estObservations = _estChampObservations(champ);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        champ,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: valeur.isEmpty
                            ? Text(
                                'Non renseigné',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                valeur,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              // Séparateur
              Container(
                height: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              
              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _editerCarte(index),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  ElevatedButton.icon(
                    onPressed: () => _supprimerCarte(index),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _estChampObservations(String champ) {
    return champ.toLowerCase().contains('observation') || 
           champ.toLowerCase().contains('remarque') ||
           champ.toLowerCase().contains('note');
  }
}