// lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/ajouter_carte.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

// Extension pour la responsivité
extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isSmallScreen => screenWidth < 360;
  
  double fontSize(double base) => isSmallScreen ? base * 0.85 : base;
  double spacing(double base) => isSmallScreen ? base * 0.8 : base;
  double iconSize(double base) => isSmallScreen ? base * 0.85 : base;
}

class AjouterCarteScreen extends StatefulWidget {
  final List<String> champs;
  final Map<String, String>? carte;
  final String? sectionKey;
  final String? sectionTitle; // Nouveau : titre de la section

  const AjouterCarteScreen({
    super.key,
    required this.champs,
    this.carte,
    this.sectionKey,
    this.sectionTitle,
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
  
  // Variable pour la section de câble
  String? _selectedSectionCable;
  
  // Variables pour les champs Oui/Non
  String? _selectedCuveRetention;
  String? _selectedIndicateurNiveau;
  String? _selectedMiseALaTerre;

  // Liste des sections de câble disponibles
  static const List<String> _sectionCableOptions = [
    '0,5 mm²',
    '0,75 mm²',
    '1 mm²',
    '1,5 mm²',
    '2,5 mm²',
    '4 mm²',
    '6 mm²',
    '10 mm²',
    '16 mm²',
    '25 mm²',
    '35 mm²',
    '50 mm²',
    '70 mm²',
    '95 mm²',
    '120 mm²',
    '150 mm²',
    '185 mm²',
    '240 mm²',
    '300 mm²',
    '400 mm²',
    '500 mm²',
    '630 mm²',
  ];

  // Options Oui/Non
  static const List<String> _ouiNonOptions = ['Oui', 'Non'];

  @override
  void initState() {
    super.initState();
    for (var champ in widget.champs) {
      if (champ == 'NATURE DU RESEAU' && widget.carte != null) {
        _selectedNatureReseau = widget.carte![champ];
        _showIacmOption = (_selectedNatureReseau == 'Aérien');
        if (_showIacmOption && widget.carte!.containsKey('PRESENCE IACM')) {
          _selectedIacm = widget.carte!['PRESENCE IACM'];
        }
      }
      
      // Initialiser la section de câble si présente dans la carte
      if (_isSectionCableField(champ) && widget.carte != null) {
        _selectedSectionCable = widget.carte![champ];
      }
      
      // Initialiser les champs Oui/Non
      if (_isCuveRetentionField(champ) && widget.carte != null) {
        _selectedCuveRetention = widget.carte![champ];
      }
      if (_isIndicateurNiveauField(champ) && widget.carte != null) {
        _selectedIndicateurNiveau = widget.carte![champ];
      }
      if (_isMiseALaTerreField(champ) && widget.carte != null) {
        _selectedMiseALaTerre = widget.carte![champ];
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

  bool _isSectionCableField(String champ) {
    final lowerChamp = champ.toLowerCase();
    return lowerChamp.contains('section') && 
           (lowerChamp.contains('cable') || lowerChamp.contains('câble'));
  }

  bool _isNatureReseauField(String champ) {
    return champ == 'NATURE DU RESEAU';
  }

  bool _isCuveRetentionField(String champ) {
    final lowerChamp = champ.toUpperCase();
    return lowerChamp.contains('CUVE') && lowerChamp.contains('RETENTION');
  }

  bool _isIndicateurNiveauField(String champ) {
    final lowerChamp = champ.toUpperCase();
    return lowerChamp.contains('INDICATEUR') && lowerChamp.contains('NIVEAU');
  }

  bool _isMiseALaTerreField(String champ) {
    final lowerChamp = champ.toUpperCase();
    return lowerChamp.contains('MISE') && lowerChamp.contains('TERRE');
  }

  bool _isOuiNonField(String champ) {
    return _isCuveRetentionField(champ) || 
           _isIndicateurNiveauField(champ) || 
           _isMiseALaTerreField(champ);
  }

  String? _getOuiNonFieldValue(String champ) {
    if (_isCuveRetentionField(champ)) return _selectedCuveRetention;
    if (_isIndicateurNiveauField(champ)) return _selectedIndicateurNiveau;
    if (_isMiseALaTerreField(champ)) return _selectedMiseALaTerre;
    return null;
  }

  void _setOuiNonFieldValue(String champ, String? value) {
    setState(() {
      if (_isCuveRetentionField(champ)) {
        _selectedCuveRetention = value;
      } else if (_isIndicateurNiveauField(champ)) {
        _selectedIndicateurNiveau = value;
      } else if (_isMiseALaTerreField(champ)) {
        _selectedMiseALaTerre = value;
      }
    });
  }

  bool _hasAtLeastOneFieldFilled() {
    for (var champ in widget.champs) {
      if (_isSectionCableField(champ)) {
        if (_selectedSectionCable != null && _selectedSectionCable!.isNotEmpty) {
          return true;
        }
      } else if (_isNatureReseauField(champ)) {
        if (_selectedNatureReseau != null && _selectedNatureReseau!.isNotEmpty) {
          return true;
        }
      } else if (_isOuiNonField(champ)) {
        final value = _getOuiNonFieldValue(champ);
        if (value != null && value.isNotEmpty) {
          return true;
        }
      } else {
        final value = _controllers[champ]!.text.trim();
        if (value.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isIacmValid() {
    if (_showIacmOption) {
      return _selectedIacm != null && _selectedIacm!.isNotEmpty;
    }
    return true;
  }

  void _sauvegarder() {
    if (!_hasAtLeastOneFieldFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez remplir au moins un champ',
            style: TextStyle(fontSize: context.fontSize(14)),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    if (!_isIacmValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez indiquer la présence d\'une IACM',
            style: TextStyle(fontSize: context.fontSize(14)),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    final nouvelleCarte = <String, String>{};
    
    for (var champ in widget.champs) {
      if (_isSectionCableField(champ)) {
        if (_selectedSectionCable != null && _selectedSectionCable!.isNotEmpty) {
          nouvelleCarte[champ] = _selectedSectionCable!;
        }
      } else if (_isNatureReseauField(champ)) {
        if (_selectedNatureReseau != null && _selectedNatureReseau!.isNotEmpty) {
          nouvelleCarte[champ] = _selectedNatureReseau!;
          if (_selectedNatureReseau == 'Aérien' && _selectedIacm != null) {
            nouvelleCarte['PRESENCE IACM'] = _selectedIacm!;
          }
        }
      } else if (_isOuiNonField(champ)) {
        final value = _getOuiNonFieldValue(champ);
        if (value != null && value.isNotEmpty) {
          nouvelleCarte[champ] = value;
        }
      } else {
        final value = _controllers[champ]!.text.trim();
        if (value.isNotEmpty) {
          nouvelleCarte[champ] = value;
        }
      }
    }
    
    Navigator.of(context).pop(nouvelleCarte);
  }

  void _annuler() {
    Navigator.of(context).pop();
  }

  bool _estChampObservations(String champ) {
    final lowerChamp = champ.toLowerCase();
    return lowerChamp.contains('observation') || 
           lowerChamp.contains('remarque') ||
           lowerChamp.contains('note');
  }

  bool _isMoyenneTensionSection() {
    return widget.sectionKey == 'alimentation_moyenne_tension';
  }

  String _getHeaderTitle() {
    // Si un titre de section est fourni, l'utiliser
    if (widget.sectionTitle != null && widget.sectionTitle!.isNotEmpty) {
      return widget.sectionTitle!;
    }
    
    // Sinon, essayer de déduire du sectionKey
    if (widget.sectionKey != null) {
      switch (widget.sectionKey) {
        case 'alimentation_moyenne_tension':
          return 'Alimentation Moyenne Tension';
        case 'alimentation_basse_tension':
          return 'Alimentation Basse Tension';
        case 'groupe_electrogene':
          return 'Groupe Électrogène';
        case 'alimentation_carburant':
          return 'Alimentation Carburant';
        case 'inverseur':
          return 'Inverseur';
        case 'stabilisateur':
          return 'Stabilisateur';
        case 'onduleurs':
          return 'Onduleurs';
        default:
          return widget.sectionKey!.replaceAll('_', ' ').split(' ').map((word) => 
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
          ).join(' ');
      }
    }
    
    return 'Nouvelle carte';
  }

  Widget _buildModernTextField({
    required String champ,
    required TextEditingController controller,
    bool isMultiline = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing(16),
              context.spacing(12),
              context.spacing(16),
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.spacing(10)),
                Expanded(
                  child: Text(
                    champ,
                    style: TextStyle(
                      fontSize: context.fontSize(15),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: isMultiline ? 4 : 1,
            minLines: isMultiline ? 3 : 1,
            style: TextStyle(fontSize: context.fontSize(14)),
            decoration: InputDecoration(
              hintText: isMultiline 
                  ? 'Saisissez vos observations...' 
                  : 'Saisissez ${champ.toLowerCase()}...',
              hintStyle: TextStyle(
                fontSize: context.fontSize(14),
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.spacing(16),
                vertical: context.spacing(isMultiline ? 12 : 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? hintText,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing(16),
              context.spacing(12),
              context.spacing(16),
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.spacing(10)),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fontSize(15),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.arrow_drop_down_circle,
              color: AppTheme.primaryBlue,
              size: context.iconSize(22),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            hint: Text(
              hintText ?? 'Sélectionnez...',
              style: TextStyle(
                fontSize: context.fontSize(14),
                color: Colors.grey.shade500,
              ),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.spacing(16),
                vertical: context.spacing(12),
              ),
            ),
            style: TextStyle(
              fontSize: context.fontSize(14),
              color: AppTheme.darkBlue,
              fontWeight: FontWeight.w500,
            ),
            items: items,
            onChanged: onChanged,
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((item) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: context.spacing(4)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryBlue,
                        size: context.iconSize(16),
                      ),
                      SizedBox(width: context.spacing(8)),
                      Expanded(
                        child: item.child,
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOuiNonDropdown(String champ) {
    final currentValue = _getOuiNonFieldValue(champ);
    
    return _buildModernDropdown<String>(
      label: champ,
      value: currentValue,
      hintText: 'Sélectionnez Oui ou Non',
      items: _ouiNonOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: option == 'Oui' ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.spacing(8)),
              Text(
                option,
                style: TextStyle(
                  color: option == 'Oui' ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        _setOuiNonFieldValue(champ, value);
      },
    );
  }

  Widget _buildNatureReseauSection() {
    return Column(
      children: [
        _buildModernDropdown<String>(
          label: 'NATURE DU RESEAU',
          value: _selectedNatureReseau,
          hintText: 'Sélectionnez le type de réseau',
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
        
        if (_showIacmOption)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              children: [
                _buildModernDropdown<String>(
                  label: 'Présence d\'une IACM',
                  value: _selectedIacm,
                  hintText: 'Sélectionnez...',
                  items: const [
                    DropdownMenuItem(value: 'Oui', child: Text('Oui')),
                    DropdownMenuItem(value: 'Non', child: Text('Non')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedIacm = value;
                    });
                  },
                ),
                
                if (_selectedIacm == null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: context.spacing(16),
                      right: context.spacing(16),
                      bottom: context.spacing(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: context.iconSize(14),
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: context.spacing(6)),
                        Expanded(
                          child: Text(
                            'Indiquez si une Installation À Courant Mesuré est présente',
                            style: TextStyle(
                              fontSize: context.fontSize(12),
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCableField(String champ) {
    return _buildModernDropdown<String>(
      label: champ,
      value: _selectedSectionCable,
      hintText: 'Sélectionnez la section de câble',
      items: _sectionCableOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSectionCable = value;
        });
      },
    );
  }

  Widget _buildHeader() {
    final isEdition = widget.carte != null;
    final headerTitle = _getHeaderTitle();
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing(20)),
      padding: EdgeInsets.all(context.spacing(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.spacing(12)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEdition ? Icons.edit_note : Icons.add_card,
              color: Colors.white,
              size: context.iconSize(28),
            ),
          ),
          SizedBox(width: context.spacing(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: TextStyle(
                    fontSize: context.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.spacing(4)),
                Text(
                  isEdition ? 'Modifier les informations' : 'Remplissez les informations ci-dessous',
                  style: TextStyle(
                    fontSize: context.fontSize(14),
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.only(top: context.spacing(24)),
      child: Column(
        children: [
          // Bouton Sauvegarder
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.primaryBlue.withOpacity(0.85),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _sauvegarder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_alt,
                    size: context.iconSize(20),
                    color: Colors.white,
                  ),
                  SizedBox(width: context.spacing(8)),
                  Text(
                    'SAUVEGARDER',
                    style: TextStyle(
                      fontSize: context.fontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: context.spacing(12)),
          
          // Bouton Annuler
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _annuler,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    size: context.iconSize(18),
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: context.spacing(8)),
                  Text(
                    'ANNULER',
                    style: TextStyle(
                      fontSize: context.fontSize(15),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdition = widget.carte != null;
    final isMoyenneTension = _isMoyenneTensionSection();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            isEdition ? 'Modifier la carte' : 'Ajouter une carte',
            style: TextStyle(
              fontSize: context.fontSize(18),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: context.iconSize(18)),
            onPressed: _annuler,
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(context.spacing(16)),
            child: ListView(
              children: [
                _buildHeader(),
                
                ...widget.champs.map((champ) {
                  // Nature du réseau (section MT uniquement)
                  if (isMoyenneTension && _isNatureReseauField(champ)) {
                    return _buildNatureReseauSection();
                  }
                  
                  // Section de câble
                  if (_isSectionCableField(champ)) {
                    return _buildSectionCableField(champ);
                  }
                  
                  // Champs Oui/Non (Cuve de rétention, Indicateur de niveau, Mise à la terre)
                  if (_isOuiNonField(champ)) {
                    return _buildOuiNonDropdown(champ);
                  }
                  
                  // Champs texte standard
                  final estObservations = _estChampObservations(champ);
                  return _buildModernTextField(
                    champ: champ,
                    controller: _controllers[champ]!,
                    isMultiline: estObservations,
                  );
                }),
                
                _buildActionButtons(),
                
                SizedBox(height: context.spacing(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}