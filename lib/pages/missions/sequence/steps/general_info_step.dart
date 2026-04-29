// lib/pages/missions/sequence/steps/general_info_step.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/widgets/app_bottom_sheet.dart';

// Liste des vérificateurs prédéfinis
const List<Map<String, String>> _verificateursPredefinis = [
  {'nom': 'Patrick ESSAME', 'email': 'patrick.essame@kes-africa.com'},
  {'nom': 'Lucien BOYOMO', 'email': 'lucien.boyomo@kes-africa.com'},
  {'nom': 'Leandre MBAMACK', 'email': 'leandre.mbamack@kes-africa.com'},
  {'nom': 'Fabrice NKOUASSI', 'email': 'fabrice.nkouassi@kes-africa.com'},
];

class GeneralInfoStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final Function(bool) onValidationChanged;

  const GeneralInfoStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onValidationChanged,
  });

  @override
  State<GeneralInfoStep> createState() => GeneralInfoStepState();
}

class GeneralInfoStepState extends State<GeneralInfoStep> {
  // Contrôleurs
  late TextEditingController _etablissementController;
  late TextEditingController _installationController;
  late TextEditingController _activiteController;
  late TextEditingController _nomSiteController;

  // Données
  DateTime? _dateDebut;
  DateTime? _dateFin;
  int _dureeJours = 0;

  // Sélections
  String? _verificationType;
  String? _registreControle;
  List<String> _compteRenduDestinataires = [];

  // Listes
  List<Map<String, String>> _accompagnateurs = [];
  List<Map<String, String>> _verificateurs = [];

  // Focus
  final FocusNode _etablissementFocus = FocusNode();
  final FocusNode _installationFocus = FocusNode();
  final FocusNode _activiteFocus = FocusNode();
  final FocusNode _nomSiteFocus = FocusNode();

  // Flags de validation
  bool _hasAttemptedValidation = false;

  // États de focus pour savoir si l'utilisateur a interagi
  bool _etablissementTouched = false;
  bool _installationTouched = false;
  bool _activiteTouched = false;
  bool _nomSiteTouched = false;

  // Options pour les dropdowns stylisés
  final List<Map<String, dynamic>> _verificationOptions = [
    {
      'value': 'Périodique réglementaire',
      'title': 'Périodique réglementaire',
      'description': 'Vérification périodique selon la réglementation en vigueur',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
    },
    {
      'value': 'Initiale réglementaire',
      'title': 'Initiale réglementaire',
      'description': 'Vérification initiale avant mise en service',
      'icon': Icons.note_add,
      'color': Colors.green,
    },
    {
      'value': 'Audit',
      'title': 'Audit',
      'description': 'Audit complet de conformité réglementaire',
      'icon': Icons.assignment,
      'color': Colors.purple,
    },
    {
      'value': 'Expertise',
      'title': 'Expertise',
      'description': 'Expertise technique approfondie',
      'icon': Icons.engineering,
      'color': Colors.teal,
    },
  ];

  final List<Map<String, dynamic>> _registreOptions = [
    {
      'value': 'Présenté',
      'title': 'Présenté',
      'description': 'Le registre de contrôle a été fourni et est à jour',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'value': 'Non présenté',
      'title': 'Non présenté',
      'description': 'Le registre de contrôle n\'a pas été fourni',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  bool _isLoading = true;
  bool _isFirstLoad = true;
  RenseignementsGeneraux? _data;

  // Getters pour la validation
  bool get isFormValid {
    return _etablissementController.text.trim().isNotEmpty &&
           _installationController.text.trim().isNotEmpty &&
           _activiteController.text.trim().isNotEmpty &&
           _nomSiteController.text.trim().isNotEmpty &&
           _verificationType != null &&
           _dateDebut != null &&
           _dateFin != null &&
           _accompagnateurs.isNotEmpty &&
           _verificateurs.isNotEmpty &&
           _registreControle != null &&
           _compteRenduDestinataires.isNotEmpty;
  }

  // Méthode pour déclencher la validation (appelée depuis le parent)
  void triggerValidation() {
    setState(() {
      _hasAttemptedValidation = true;
      _etablissementTouched = true;
      _installationTouched = true;
      _activiteTouched = true;
      _nomSiteTouched = true;
    });
    _notifyValidation();
  }

  // Vérifie si un champ doit afficher une erreur
  bool _shouldShowError({required bool hasValue, required bool isTouched}) {
    return !hasValue && (_hasAttemptedValidation || isTouched);
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();

    _etablissementFocus.addListener(() {
      if (!_etablissementFocus.hasFocus) {
        setState(() => _etablissementTouched = true);
      }
    });
    _installationFocus.addListener(() {
      if (!_installationFocus.hasFocus) {
        setState(() => _installationTouched = true);
      }
    });
    _activiteFocus.addListener(() {
      if (!_activiteFocus.hasFocus) {
        setState(() => _activiteTouched = true);
      }
    });
    _nomSiteFocus.addListener(() {
      if (!_nomSiteFocus.hasFocus) {
        setState(() => _nomSiteTouched = true);
      }
    });
  }

  void _initControllers() {
    _etablissementController = TextEditingController();
    _installationController = TextEditingController();
    _activiteController = TextEditingController();
    _nomSiteController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _data = await HiveService.getOrCreateRenseignementsGeneraux(widget.mission.id);

      // ✅ Ajouter le vérificateur courant avec une copie modifiable
      final currentUser = HiveService.getCurrentUser();
      if (currentUser != null) {
        // S'assurer que la liste est modifiable
        if (_data!.verificateurs.isEmpty) {
          _data!.verificateurs = [];
        }
        
        final currentUserExists = _data!.verificateurs.any((v) =>
            v['nom'] == '${currentUser.prenom} ${currentUser.nom}' ||
            v['email'] == currentUser.email);
        
        if (!currentUserExists) {
          _data!.verificateurs.add({
            'nom': '${currentUser.prenom} ${currentUser.nom}',
            'email': currentUser.email,
          });
          await HiveService.saveRenseignementsGeneraux(_data!);
        }
      }

      setState(() {
        _etablissementController.text = _data!.etablissement;
        _installationController.text = _data!.installation;
        _activiteController.text = _data!.activite;
        _nomSiteController.text = _data!.nomSite;

        _dateDebut = _data!.dateDebut;
        _dateFin = _data!.dateFin;
        _dureeJours = _data!.dureeJours;
        _verificationType = _data!.verificationType;
        _registreControle = _data!.registreControle.isNotEmpty ? _data!.registreControle : null;
        _compteRenduDestinataires = List.from(_data!.compteRendu);
        _accompagnateurs = List.from(_data!.accompagnateurs);
        _verificateurs = List.from(_data!.verificateurs);

        if (_etablissementController.text.isNotEmpty) _etablissementTouched = true;
        if (_installationController.text.isNotEmpty) _installationTouched = true;
        if (_activiteController.text.isNotEmpty) _activiteTouched = true;
        if (_nomSiteController.text.isNotEmpty) _nomSiteTouched = true;

        _isFirstLoad = false;
      });

      _notifyValidation();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _notifyValidation() {
    widget.onValidationChanged(isFormValid);
  }

  Future<void> _saveData() async {
    if (_data == null) return;

    _data!.etablissement = _etablissementController.text;
    _data!.installation = _installationController.text;
    _data!.activite = _activiteController.text;
    _data!.nomSite = _nomSiteController.text;
    _data!.dateDebut = _dateDebut;
    _data!.dateFin = _dateFin;
    _data!.dureeJours = _dureeJours;
    _data!.verificationType = _verificationType;
    _data!.registreControle = _registreControle ?? '';
    _data!.compteRendu = _compteRenduDestinataires;
    _data!.accompagnateurs = List.from(_accompagnateurs);
    _data!.verificateurs = List.from(_verificateurs);
    _data!.updatedAt = DateTime.now();

    await HiveService.saveRenseignementsGeneraux(_data!);

    widget.onDataChanged(_data!.toMap());
    _notifyValidation();
    if (kDebugMode) {
      print('✅ Renseignements généraux sauvegardés');
    }
  }

  void _calculateDuree() {
    if (_dateDebut != null && _dateFin != null) {
      _dureeJours = _dateFin!.difference(_dateDebut!).inDays;
    } else {
      _dureeJours = 0;
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
        _calculateDuree();
      });
      await _saveData();
    }
  }

  void _showVerificationPicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: 'Type de vérification',
        children: _verificationOptions.map((option) {
          final isSelected = _verificationType == option['value'];
          return InkWell(
            onTap: () async {
              setState(() => _verificationType = option['value']);
              await _saveData();
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: isSelected ? (option['color'] as Color).withOpacity(0.05) : Colors.transparent,
                border: isSelected
                    ? Border(
                        left: BorderSide(color: option['color'], width: 4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: (option['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    ),
                    child: Icon(
                      option['icon'],
                      color: option['color'],
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? option['color'] : Colors.black87,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          option['description'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: option['color'],
                      size: isSmallScreen ? 20 : 24,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showRegistrePicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: 'Registre de contrôle',
        children: _registreOptions.map((option) {
          final isSelected = _registreControle == option['value'];
          return InkWell(
            onTap: () async {
              setState(() => _registreControle = option['value']);
              await _saveData();
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: isSelected ? (option['color'] as Color).withOpacity(0.05) : Colors.transparent,
                border: isSelected
                    ? Border(
                        left: BorderSide(color: option['color'], width: 4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
                    decoration: BoxDecoration(
                      color: (option['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    ),
                    child: Icon(
                      option['icon'],
                      color: option['color'],
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? option['color'] : Colors.black87,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          option['description'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: option['color'],
                      size: isSmallScreen ? 20 : 24,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCompteRenduBottomSheet() {
    if (_accompagnateurs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ajouter des accompagnateurs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final Set<String> tempSelection = Set<String>.from(_compteRenduDestinataires);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottom) => AppBottomSheet(
          title: 'Compte rendu fait à',
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
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() {
                      _compteRenduDestinataires = tempSelection.toList();
                    });
                    await _saveData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Valider (${tempSelection.length})',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: isSmallScreen ? 16 : 18, color: Colors.blue),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Text(
                      'Vous pouvez sélectionner plusieurs destinataires',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

            ..._accompagnateurs.map((accomp) {
              final nom = accomp['nom']!;
              final isSelected = tempSelection.contains(nom);

              return CheckboxListTile(
                title: Text(
                  nom,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: accomp['poste']?.isNotEmpty == true ||
                        accomp['email']?.isNotEmpty == true ||
                        accomp['telephone']?.isNotEmpty == true
                    ? Text(
                        [accomp['poste'], accomp['email'], accomp['telephone']]
                            .where((e) => e != null && e!.isNotEmpty)
                            .join(' • '),
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade600),
                      )
                    : null,
                value: isSelected,
                onChanged: (checked) {
                  setStateBottom(() {
                    if (checked == true) {
                      tempSelection.add(nom);
                    } else {
                      tempSelection.remove(nom);
                    }
                  });
                },
                activeColor: AppTheme.primaryBlue,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showVerificateurBottomSheet() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final currentUser = HiveService.getCurrentUser();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: 'Ajouter un vérificateur',
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        children: [
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: isSmallScreen ? 16 : 18, color: Colors.blue),
                SizedBox(width: isSmallScreen ? 8 : 10),
                Expanded(
                  child: Text(
                    'Le vérificateur courant (vous) est déjà sélectionné.',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),

          ..._verificateursPredefinis.map((verif) {
            final isAlreadyAdded = _verificateurs.any((v) => v['nom'] == verif['nom'] && v['email'] == verif['email']);
            final isCurrentUser = currentUser != null &&
                '${currentUser.prenom} ${currentUser.nom}' == verif['nom'] &&
                currentUser.email == verif['email'];

            return ListTile(
              leading: Container(
                width: isSmallScreen ? 40 : 44,
                height: isSmallScreen ? 40 : 44,
                decoration: BoxDecoration(
                  color: isAlreadyAdded ? Colors.grey.shade300 : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person,
                  color: isAlreadyAdded ? Colors.grey : AppTheme.primaryBlue,
                  size: isSmallScreen ? 20 : 22,
                ),
              ),
              title: Text(
                verif['nom']!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  color: isAlreadyAdded ? Colors.grey : Colors.black87,
                ),
              ),
              subtitle: Text(
                verif['email']!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: isAlreadyAdded
                  ? Icon(Icons.check_circle, color: Colors.green, size: isSmallScreen ? 20 : 22)
                  : (isCurrentUser
                      ? Icon(Icons.person_outline, color: Colors.blue, size: isSmallScreen ? 20 : 22)
                      : null),
              enabled: !isAlreadyAdded && !isCurrentUser,
              onTap: (isAlreadyAdded || isCurrentUser)
                  ? null
                  : () {
                      Navigator.pop(context);
                      setState(() {
                        _verificateurs.add({
                          'nom': verif['nom']!,
                          'email': verif['email']!,
                        });
                      });
                      _saveData();
                    },
            );
          }).toList(),

          const Divider(),

          ListTile(
            leading: Container(
              width: isSmallScreen ? 40 : 44,
              height: isSmallScreen ? 40 : 44,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: Colors.orange, size: isSmallScreen ? 20 : 22),
            ),
            title: Text(
              'Autre (saisie manuelle)',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
            subtitle: Text(
              'Ajouter un vérificateur non listé',
              style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade600),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAjouterVerificateurManuelDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAjouterVerificateurManuelDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        title: Text(
          'Ajouter un vérificateur',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, size: isSmallScreen ? 18 : 20),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom est obligatoire'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              // Vérifier si déjà ajouté
              final alreadyExists = _verificateurs.any(
                  (v) => v['nom'] == nom && v['email'] == emailController.text.trim());
              if (alreadyExists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ce vérificateur est déjà ajouté'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              setState(() {
                _verificateurs.add({
                  'nom': nom,
                  'email': emailController.text.trim(),
                });
              });
              await _saveData();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Ajouter',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccompagnateurBottomSheet() {
  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final posteController = TextEditingController();
  final telephoneController = TextEditingController();
  final isSmallScreen = MediaQuery.of(context).size.width < 360;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ Permet au bottom sheet de prendre toute la hauteur
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      // ✅ Ajout d'un padding en bas égal à la hauteur du clavier
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          // ✅ Hauteur maximale = 90% de l'écran moins le clavier
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
              width: isSmallScreen ? 30 : 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Text(
                'Ajouter un accompagnateur',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 0),
            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  children: [
                    // Nom complet *
                    TextField(
                      controller: nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet *',
                        prefixIcon: Icon(Icons.person, size: isSmallScreen ? 18 : 20),
                        border: const OutlineInputBorder(),
                      ),
                      autofocus: true, // ✅ Ouvre le clavier automatiquement
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, size: isSmallScreen ? 18 : 20),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Téléphone
                    TextField(
                      controller: telephoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone, size: isSmallScreen ? 18 : 20),
                        border: const OutlineInputBorder(),
                        hintText: 'Ex: +237 6 12 34 56 78',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Poste / Fonction
                    TextField(
                      controller: posteController,
                      decoration: InputDecoration(
                        labelText: 'Poste / Fonction',
                        prefixIcon: Icon(Icons.work, size: isSmallScreen ? 18 : 20),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitAccompagnateur(
                        nomController,
                        emailController,
                        telephoneController,
                        posteController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Boutons d'action
            const Divider(height: 0),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
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
                      onPressed: () => _submitAccompagnateur(
                        nomController,
                        emailController,
                        telephoneController,
                        posteController,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
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
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
        ),
      ),
    ),
  );
}

// Méthode séparée pour la soumission (évite la duplication de code)
void _submitAccompagnateur(
  TextEditingController nomController,
  TextEditingController emailController,
  TextEditingController telephoneController,
  TextEditingController posteController,
) async {
  final nom = nomController.text.trim();
  if (nom.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le nom est obligatoire'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Validation du téléphone (optionnel mais format si présent)
  final telephone = telephoneController.text.trim();
  if (telephone.isNotEmpty && !_isValidPhoneNumber(telephone)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Format de téléphone invalide'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Navigator.pop(context);
  setState(() {
    _accompagnateurs.add({
      'nom': nom,
      'email': emailController.text.trim(),
      'poste': posteController.text.trim(),
      'telephone': telephone,
    });
  });
  await _saveData();
}

  bool _isValidPhoneNumber(String phone) {
    // Format accepté : +XXXXXXXXXXXXX ou chiffres (9-15 caractères)
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  void _supprimerAccompagnateur(int index) async {
    final accompagnateurSupprime = _accompagnateurs[index];
    setState(() {
      _accompagnateurs.removeAt(index);
      _compteRenduDestinataires.remove(accompagnateurSupprime['nom']);
    });
    await _saveData();
  }

  void _supprimerVerificateur(int index) async {
    final verificateurSupprime = _verificateurs[index];
    final currentUser = HiveService.getCurrentUser();

    // Empêcher la suppression du vérificateur courant
    if (currentUser != null &&
        verificateurSupprime['nom'] == '${currentUser.prenom} ${currentUser.nom}') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas supprimer le vérificateur courant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _verificateurs.removeAt(index);
    });
    await _saveData();
  }

  @override
  void dispose() {
    _etablissementController.dispose();
    _installationController.dispose();
    _activiteController.dispose();
    _nomSiteController.dispose();
    _etablissementFocus.dispose();
    _installationFocus.dispose();
    _activiteFocus.dispose();
    _nomSiteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Chargement des données...',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Renseignements Principaux',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFormValid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      border: Border.all(
                        color: isFormValid ? Colors.green : Colors.orange,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFormValid ? Icons.check_circle : Icons.info_outline,
                          size: isSmallScreen ? 14 : 16,
                          color: isFormValid ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          isFormValid ? 'Complet' : 'En cours',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: isFormValid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Établissement
              _buildTextField(
                controller: _etablissementController,
                label: 'Établissement vérifié',
                icon: Icons.business,
                focusNode: _etablissementFocus,
                isRequired: true,
                showError: _shouldShowError(
                  hasValue: _etablissementController.text.trim().isNotEmpty,
                  isTouched: _etablissementTouched,
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Installation vérifiée
              _buildTextField(
                controller: _installationController,
                label: 'Installation vérifiée',
                icon: Icons.location_city,
                hint: 'Ex: Bâtiment A',
                focusNode: _installationFocus,
                isRequired: true,
                showError: _shouldShowError(
                  hasValue: _installationController.text.trim().isNotEmpty,
                  isTouched: _installationTouched,
                ),
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Activité principale
              _buildTextField(
                controller: _activiteController,
                label: 'Activité principale',
                icon: Icons.work_outline,
                hint: 'Ex: BTP, Industrie, Services...',
                focusNode: _activiteFocus,
                isRequired: true,
                showError: _shouldShowError(
                  hasValue: _activiteController.text.trim().isNotEmpty,
                  isTouched: _activiteTouched,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Nom du site (NOUVEAU)
              _buildTextField(
                controller: _nomSiteController,
                label: 'Nom du site',
                icon: Icons.location_city,
                hint: 'Ex: Siège Social, Agence Centrale...',
                focusNode: _nomSiteFocus,
                isRequired: true,
                showError: _shouldShowError(
                  hasValue: _nomSiteController.text.trim().isNotEmpty,
                  isTouched: _nomSiteTouched,
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 24),

              // Type de vérification
              _buildDisplayField(
                label: 'Nature de vérification',
                value: _verificationType,
                hint: 'Sélectionnez le type de vérification',
                icon: Icons.verified_outlined,
                onTap: _showVerificationPicker,
                color: _verificationType != null ? Colors.blue : null,
                isRequired: true,
                showError: _hasAttemptedValidation,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Dates
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _hasAttemptedValidation && (_dateDebut == null || _dateFin == null)
                        ? Colors.red.shade300
                        : Colors.transparent,
                    width: _hasAttemptedValidation && (_dateDebut == null || _dateFin == null) ? 1.5 : 0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.orange,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Période d\'intervention',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ' *',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        children: [
                          _buildDateField(
                            label: 'Date de début',
                            date: _dateDebut,
                            icon: Icons.play_arrow,
                            onTap: () => _selectDate(context, true),
                            isRequired: true,
                            showError: _hasAttemptedValidation,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildDateField(
                            label: 'Date de fin',
                            date: _dateFin,
                            icon: Icons.check,
                            onTap: () => _selectDate(context, false),
                            isRequired: true,
                            showError: _hasAttemptedValidation,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                                  ),
                                  child: Icon(
                                    Icons.timer_outlined,
                                    color: AppTheme.primaryBlue,
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 10 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Durée',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '$_dureeJours jour(s)',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 16 : 18,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Accompagnateurs
              _buildDynamicListSection(
                title: 'Accompagnateurs',
                icon: Icons.people,
                color: Colors.blue,
                items: _accompagnateurs,
                itemBuilder: (accomp) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accomp['nom']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    if (accomp['email']!.isNotEmpty)
                      Text(
                        accomp['email']!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (accomp['telephone']!.isNotEmpty)
                      Text(
                        accomp['telephone']!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (accomp['poste']!.isNotEmpty)
                      Text(
                        accomp['poste']!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                onAdd: _showAccompagnateurBottomSheet,
                onDelete: _supprimerAccompagnateur,
                isRequired: true,
                showError: _hasAttemptedValidation,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Vérificateurs
              _buildDynamicListSection(
                title: 'Vérificateurs',
                icon: Icons.verified_user,
                color: Colors.green,
                items: _verificateurs,
                itemBuilder: (verif) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verif['nom']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    if (verif['email']!.isNotEmpty)
                      Text(
                        verif['email']!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                onAdd: _showVerificateurBottomSheet,
                onDelete: _supprimerVerificateur,
                isRequired: true,
                showError: _hasAttemptedValidation,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Registre de contrôle
              _buildDisplayField(
                label: 'Registre de contrôle',
                value: _registreControle,
                hint: 'Sélectionnez l\'état du registre',
                icon: Icons.book_outlined,
                onTap: _showRegistrePicker,
                color: _registreControle != null
                    ? (_registreControle == 'Présenté' ? Colors.green : Colors.red)
                    : null,
                isRequired: true,
                showError: _hasAttemptedValidation,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Compte rendu de fin de visite fait à
              _buildDisplayField(
                label: 'Compte rendu de fin de visite fait à',
                value: _compteRenduDestinataires.isEmpty
                    ? null
                    : _compteRenduDestinataires.join(', '),
                hint: _accompagnateurs.isEmpty
                    ? 'Ajoutez d\'abord des accompagnateurs'
                    : 'Sélectionnez les destinataires',
                icon: Icons.description_outlined,
                onTap: _showCompteRenduBottomSheet,
                color: _compteRenduDestinataires.isNotEmpty ? Colors.purple : null,
                isRequired: true,
                showError: _hasAttemptedValidation,
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    String? hint,
    bool isRequired = false,
    bool showError = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasText = controller.text.trim().isNotEmpty;

    final borderColor = showError && !hasText
        ? Colors.red.shade300
        : (hasText ? AppTheme.primaryBlue.withOpacity(0.3) : Colors.grey.shade200);

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            border: Border.all(color: borderColor),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (_) {
              _saveData();
              if (!_etablissementTouched && controller == _etablissementController) {
                setState(() => _etablissementTouched = true);
              } else if (!_installationTouched && controller == _installationController) {
                setState(() => _installationTouched = true);
              } else if (!_activiteTouched && controller == _activiteController) {
                setState(() => _activiteTouched = true);
              } else if (!_nomSiteTouched && controller == _nomSiteController) {
                setState(() => _nomSiteTouched = true);
              }
            },
            decoration: InputDecoration(
              labelText: isRequired ? '$label *' : label,
              labelStyle: TextStyle(
                color: showError && !hasText ? Colors.red : Colors.grey.shade600,
              ),
              hintText: hint,
              prefixIcon: Icon(
                icon,
                size: isSmallScreen ? 18 : 20,
                color: focusNode.hasFocus
                    ? AppTheme.primaryBlue
                    : (showError && !hasText ? Colors.red : (hasText ? AppTheme.primaryBlue : Colors.grey)),
              ),
              suffixIcon: hasText
                  ? Icon(Icons.check_circle, color: Colors.green, size: isSmallScreen ? 16 : 18)
                  : (showError && isRequired ? Icon(Icons.error_outline, color: Colors.red, size: isSmallScreen ? 16 : 18) : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: isSmallScreen ? 14 : 18,
              ),
            ),
            onEditingComplete: () => focusNode.unfocus(),
          ),
        );
      },
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isRequired = false,
    bool showError = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final hasError = showError && value == null;
    final displayColor = hasError
        ? Colors.red
        : (color ?? (value != null ? AppTheme.primaryBlue : Colors.grey));
    final borderColor = hasError
        ? Colors.red.shade300
        : (value != null ? displayColor.withOpacity(0.3) : Colors.grey.shade200);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(icon, size: isSmallScreen ? 18 : 20, color: displayColor),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: hasError ? Colors.red : Colors.grey,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: hasError ? Colors.red : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? Colors.red.shade400
                          : (value != null ? Colors.black87 : Colors.grey.shade500),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: displayColor,
              size: isSmallScreen ? 22 : 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
    bool showError = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasError = showError && date == null;
    final borderColor = hasError
        ? Colors.red.shade300
        : (date != null ? Colors.grey.shade200 : Colors.grey.shade200);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red.withOpacity(0.1)
                    : (date != null ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(
                icon,
                size: isSmallScreen ? 16 : 18,
                color: hasError ? Colors.red : (date != null ? AppTheme.primaryBlue : Colors.grey),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: hasError ? Colors.red : Colors.grey,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: hasError ? Colors.red : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Non définie',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? Colors.red.shade400
                          : (date != null ? Colors.black87 : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: isSmallScreen ? 16 : 18,
              color: hasError ? Colors.red.shade300 : (date != null ? AppTheme.primaryBlue : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> items,
    required Widget Function(Map<String, String>) itemBuilder,
    required VoidCallback onAdd,
    required Function(int) onDelete,
    bool isRequired = false,
    bool showError = false,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasError = showError && items.isEmpty;
    final borderColor = hasError ? Colors.red.shade300 : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: borderColor, width: hasError ? 1.5 : 0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: hasError ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                  child: Icon(
                    icon,
                    color: hasError ? Colors.red : color,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: hasError ? Colors.red : Colors.black87,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: hasError ? Colors.red : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasError)
                  Icon(
                    Icons.warning_amber_rounded,
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                if (items.isNotEmpty)
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: itemBuilder(item)),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.red,
                            ),
                            onPressed: () => onDelete(index),
                            constraints: BoxConstraints(
                              minWidth: isSmallScreen ? 32 : 40,
                              minHeight: isSmallScreen ? 32 : 40,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                if (hasError)
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.red.shade700,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        Expanded(
                          child: Text(
                            'Au moins un élément est requis',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      'AJOUTER UN $title'.toUpperCase(),
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
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
}