import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class AjouterCarteScreen extends StatefulWidget {
  final List<String> champs;
  final Map<String, String>? carte;
  final String? sectionKey; // Ajouté pour identifier la section MT

  const AjouterCarteScreen({
    super.key,
    required this.champs,
    this.carte,
    this.sectionKey,
  });

  @override
  State<AjouterCarteScreen> createState() => _AjouterCarteScreenState();
}

class _AjouterCarteScreenState extends State<AjouterCarteScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  
  // Variables pour la section MT
  String? _selectedNatureReseau;
  String? _selectedIacm;
  bool _showIacmOption = false;

  @override
  void initState() {
    super.initState();
    for (var champ in widget.champs) {
      // Pour la section MT, pré-remplir avec les valeurs existantes
      if (champ == 'NATURE DU RESEAU' && widget.carte != null) {
        _selectedNatureReseau = widget.carte![champ];
        _showIacmOption = (_selectedNatureReseau == 'Aérien');
        if (_showIacmOption && widget.carte!.containsKey('PRESENCE IACM')) {
          _selectedIacm = widget.carte!['PRESENCE IACM'];
        }
      }
      _controllers[champ] = TextEditingController(
        text: widget.carte?[champ] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// Vérifie si au moins un champ (hors IACM) a une valeur
  bool _hasAtLeastOneFieldFilled() {
    for (var champ in widget.champs) {
      final value = _controllers[champ]!.text.trim();
      if (value.isNotEmpty) {
        return true;
      }
    }
    // Vérifier aussi la nature du réseau si elle est sélectionnée
    if (_selectedNatureReseau != null && _selectedNatureReseau!.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Vérifie si la sous-option IACM est valide (si applicable)
  bool _isIacmValid() {
    if (_showIacmOption) {
      return _selectedIacm != null && _selectedIacm!.isNotEmpty;
    }
    return true;
  }

  void _sauvegarder() {
    // Vérifier qu'au moins un champ est rempli
    if (!_hasAtLeastOneFieldFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir au moins un champ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Vérifier la sous-option IACM si applicable
    if (!_isIacmValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer la présence d\'une IACM'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final nouvelleCarte = <String, String>{};
    
    for (var champ in widget.champs) {
      final value = _controllers[champ]!.text.trim();
      if (value.isNotEmpty) {
        nouvelleCarte[champ] = value;
      }
    }
    
    // Ajouter la nature du réseau si sélectionnée
    if (_selectedNatureReseau != null && _selectedNatureReseau!.isNotEmpty) {
      nouvelleCarte['NATURE DU RESEAU'] = _selectedNatureReseau!;
      // Ajouter l'IACM si aérien
      if (_selectedNatureReseau == 'Aérien' && _selectedIacm != null) {
        nouvelleCarte['PRESENCE IACM'] = _selectedIacm!;
      }
    }
    
    Navigator.of(context).pop(nouvelleCarte);
  }

  void _annuler() {
    Navigator.of(context).pop();
  }

  bool _estChampObservations(String champ) {
    return champ.toLowerCase().contains('observation') || 
           champ.toLowerCase().contains('remarque') ||
           champ.toLowerCase().contains('note');
  }

  bool _isMoyenneTensionSection() {
    return widget.sectionKey == 'alimentation_moyenne_tension';
  }

  @override
  Widget build(BuildContext context) {
    final isEdition = widget.carte != null;
    final isMoyenneTension = _isMoyenneTensionSection();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdition ? 'Modifier la carte' : 'Ajouter une carte'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _annuler,
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ...widget.champs.map((champ) {
                  // Pour la section MT, remplacer "NATURE DU RESEAU" par un dropdown
                  if (isMoyenneTension && champ == 'NATURE DU RESEAU') {
                  return Column(
                    children: [
                      // Dropdown NATURE DU RESEAU
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              champ,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedNatureReseau,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                hint: const Text('Sélectionnez...'),
                                items: const [
                                  DropdownMenuItem(value: 'Souterrain', child: Text('Souterrain')),
                                  DropdownMenuItem(value: 'Aérien', child: Text('Aérien')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNatureReseau = value;
                                    _showIacmOption = (value == 'Aérien');
                                    if (!_showIacmOption) {
                                      _selectedIacm = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Sous-option IACM - Design amélioré
                      if (_showIacmOption)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
      
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Présence d\'une IACM',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedIacm,
                                  hint: const Text('Sélectionnez...'),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Oui', 
                                      child: Row(
                                        children: [
                                          Text('Oui'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Non', 
                                      child: Row(
                                        children: [
                                          Text('Non'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedIacm = value;
                                    });
                                  },
                                ),
                              ),
                              
                              // Message d'aide optionnel
                              if (_selectedIacm == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    'Indiquez si une Installation À Courant Mesuré est présente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                }
      
                  
                  
                  final estObservations = _estChampObservations(champ);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          champ,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        estObservations
                            ? TextFormField(
                                controller: _controllers[champ],
                                maxLines: 4,
                                minLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Saisissez vos observations...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 12,
                                  ),
                                ),
                              )
                            : TextFormField(
                                controller: _controllers[champ],
                                decoration: InputDecoration(
                                  hintText: 'Saisissez ${champ.toLowerCase()}...',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 16,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                }).toList(),
                
                
                const SizedBox(height: 20),
                
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sauvegarder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SAUVEGARDER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _annuler,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ANNULER',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}