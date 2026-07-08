// lib/.../description_installations_form.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/description_installations/domain/entities/installation_item_entity.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/add_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/remove_installation_item_use_case.dart';

// ============================================================
// GAMMES DE CELLULES → TYPES ASSOCIÉS
// ============================================================
class CelluleGammes {
  static const Map<String, List<String>> gammeTypes = {
    'Cellules RM6': [
      'I : Interrupteur‑sectionneur',
      'IM : Interrupteur‑sectionneur avec mise à la terre',
      'IQ : Interrupteur avec disjoncteur',
      'ID : Interrupteur départ ligne',
      'Q : Disjoncteur HTA',
      'IF : Interrupteur‑fusibles',
      'D : Départ direct',
      'DM : Départ avec mise à la terre',
      'M : Mesure HTA',
      'DE : Cellule de mise à la terre',
    ],
    'Cellules SM6': [
      'IM : interrupteur',
      'IMC : interrupteur',
      'IMB : interrupteur',
      'EMB : mise à la terre du jeu de barres',
      'PM : interrupteur-fusibles associés',
      'QM : combiné interrupteur-fusibles',
      'QMC : combiné interrupteur-fusibles',
      'QMB : combiné interrupteur-fusibles',
      'CRM : contacteur et contacteur-fusibles',
      'DM1-A : disjoncteur (SF6) simple sectionnement',
      'DM1-D : disjoncteur (SF6) simple sectionnement',
      'DM1-S : disjoncteur (SF6) simple sectionnement',
      'DMV-A : disjoncteur (vide) simple sectionnement',
      'DMV-D : disjoncteur (vide) simple sectionnement',
      'DMV-S : disjoncteur (vide) simple sectionnement',
      'DM1-W : disjoncteur (SF6) débrochable simple sectionnement',
      'DM1-Z : disjoncteur (SF6) débrochable simple sectionnement',
      'DM2 : disjoncteur (SF6) double sectionnement',
      'CM : transformateurs de potentiel',
      'CM2 : transformateurs de potentiel',
      'GBC-A : mesures d’intensité et/ou de tension',
      'GBC-B : mesures d’intensité et/ou de tension',
      'NSM-câbles : pour arrivée prioritaire et secours',
      'NSM-barres : pour arrivée prioritaire et câbles pour secours',
      'GIM : gaine intercalaire',
      'GEM : gaine d’extension',
      'GBM : gaine de liaison',
      'GAM2 : gaine d’arrivée',
      'GAM : gaine d’arrivée',
      'SM : sectionneur',
      'TM : transformateur MT/BT pour auxiliaires',
    ],
    'Cellules MCset': [
      'Incoming (I) : Arrivée réseau',
      'Outgoing (O) : Départ ligne ou câble',
      'Bus Coupler (BC) : Couplage jeux de barres',
      'Transformer Feeder (TF) : Départ transformateur',
      'Generator Feeder (GF) : Groupe électrogène',
      'Motor Feeder (MF) : Moteur HTA',
      'Capacitor Feeder (CF) : Batterie de condensateurs',
      'Metering (M) : Mesure HTA',
      'Bus Riser (BR) : Liaison tableau',
    ],
    'UniSwitch': [
      'SDC : Cellule interrupteur-sectionneur',
      'SDF : Cellule interrupteur-sectionneur fusibles',
      'CBC : Cellule disjoncteur',
      'DBC : Cellule raccordement direct sur jeu de barres',
      'SEC : Cellule de sectionnement type',
      'BRC : Cellule remontée de barres',
      'SBC : Cellule de sectionnement avec disjoncteur',
      'SMC : Cellule de sectionnement avec comptage',
    ],
    'UniSec': [
      'SDC : Cellule interrupteur-sectionneur',
      'SDS : Cellule de couplage interrupteur-sectionneur',
      'SDD : Cellule double interrupteur-sectionneur',
      'SDM : Cellule interrupteur-sectionneur de mesure',
      'UMP : Cellule de mesure universelle',
      'DRC : Cellule de remontée avec raccordement câbles',
      'DRS : Cellule de remontée pour raccordement barres',
      'SFV : Cellule de mesure avec interrupteur-sectionneur fusibles',
      'SFC : Cellule interrupteur-sectionneur fusibles',
      'SFS : Cellule de couplage interrupteur-sectionneur fusibles',
      'SBC : Cellule simple interrupteur-sectionneur et disjoncteur',
      'SBC-W : Cellule simple interrupteur-sectionneur et disjoncteur débrochable',
      'SBS : Cellule de couplage simple interrupteur-sectionneur et disjoncteur',
      'SBS-W : Cellule de couplage simple interrupteur-sectionneur et disjoncteur débrochable',
      'SBM : Cellule de couplage double interrupteur-sectionneur et disjoncteur',
      'SBR : Cellule inversée disjoncteur et simple interrupteur-sectionneur',
      'HBC : Cellule disjoncteur et interrupteur-sectionneur intégrés',
      'SCC : Cellule interrupteur-sectionneur et contacteur',
      'HBS : Cellule de couplage interrupteur-sectionneur et disjoncteur intégrés',
      'RLC : Caisson de remontée de câble latéral gauche',
      'RRC : Caisson de remontée de câble latéral droit',
      'WBC : Cellule disjoncteur débrochable',
      'WBS : Cellule de couplage disjoncteur débrochable',
      'BME : Cellule directe avec mesure et mise à la terre des barres',
    ],
  };


  static List<String> get gammes => gammeTypes.keys.toList();

  static List<String> getTypesForGamme(String? gamme) {
    if (gamme == null || gamme.isEmpty) return [];
    return gammeTypes[gamme] ?? gammeTypes['Autre / Inconnu']!;
  }
}

// ============================================================
// WIDGET PRINCIPAL : LISTE DES ITEMS
// ============================================================
class DescriptionInstallationsForm extends StatefulWidget {
  final Mission mission;
  final String title;
  final String sectionKey;
  final List<String> champs;
  final Function(String) onComplete;
  final bool isComplete;
  final VoidCallback onTerminate;

  const DescriptionInstallationsForm({
    super.key,
    required this.mission,
    required this.title,
    required this.sectionKey,
    required this.champs,
    required this.onComplete,
    required this.isComplete,
    required this.onTerminate,
  });

  @override
  State<DescriptionInstallationsForm> createState() => _DescriptionInstallationsFormState();
}

class _DescriptionInstallationsFormState extends State<DescriptionInstallationsForm> {
  List<InstallationItem> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;

  static const Map<String, String> _numericFieldsWithUnit = {
    'Calibre Du Disjoncteur': 'A',
    'Section Du Cable': 'mm²',
    'Puissance Transformateur': 'kVA',
    'Calibre Du Disjoncteur Sortie Transformateur': 'A',
    'Tension': 'V',
    'Puissance (Kva)': 'kVA',
    'Intensite': 'A',
    'Capacite': 'L',
    'Intensite (A)': 'A',
    'Entree': 'V',
    'Sortie': 'V',
    'Nombre De Phase': '',
  };

  static const List<String> _natureReseauOptions = ['Aérien', 'Souterrain', 'Mixte'];
  static const List<String> _sectionCableOptions = [
    '0,5', '0,75', '1', '1,5', '2,5', '4', '6',
    '10', '16', '25', '35', '50', '70', '95',
    '120', '150', '185', '240', '300', '400', '500', '630',
  ];
  static const List<String> _modeOptions = ['Pompe électrique', 'Gravitaire', 'Manuel', 'Autre'];
  static const List<String> _ouiNonOptions = ['Oui', 'Non'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final getDescUseCase = GetIt.instance<GetDescriptionInstallationsUseCase>();
      final desc = await getDescUseCase(widget.mission.id);
      
      List<InstallationItemEntity> items = [];
      switch (widget.sectionKey) {
        case 'alimentation_moyenne_tension':
          items = desc.alimentationMoyenneTension;
          break;
        case 'alimentation_basse_tension':
          items = desc.alimentationBasseTension;
          break;
        case 'groupe_electrogene':
          items = desc.groupeElectrogene;
          break;
        case 'alimentation_carburant':
          items = desc.alimentationCarburant;
          break;
        case 'inverseur':
          items = desc.inverseur;
          break;
        case 'stabilisateur':
          items = desc.stabilisateur;
          break;
        case 'onduleurs':
          items = desc.onduleurs;
          break;
      }
      
      final modelItems = items.map((e) => DescriptionInstallationsMapper.toItemModel(e)).toList();
      if (mounted) setState(() { _items = modelItems; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _addItem() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => _AddEditItemScreen(
        title: widget.title, champs: widget.champs,
        numericFieldsWithUnit: _numericFieldsWithUnit,
        natureReseauOptions: _natureReseauOptions,
        sectionCableOptions: _sectionCableOptions,
        modeOptions: _modeOptions, ouiNonOptions: _ouiNonOptions,
      ),
    ));
    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      final addUseCase = GetIt.instance<AddInstallationItemUseCase>();
      final success = await addUseCase(
        missionId: widget.mission.id, section: widget.sectionKey,
        item: InstallationItemEntity(data: result, createdAt: DateTime.now()));
      if (success) {
        await _loadData();
        _checkAndNotifyComplete();
        if (mounted) {
          final shouldContinue = await showDialog<bool>(
            context: context, barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(20),
              title: const Row(children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 12),
                Expanded(child: Text('Enregistrement réussi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ]),
              content: const Text('Voulez-vous continuer à ajouter ou terminer ?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONTINUER', style: TextStyle(fontWeight: FontWeight.bold))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('TERMINER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (shouldContinue == true) { _addItem(); } else { widget.onTerminate(); }
        }
      }
      setState(() => _isSaving = false);
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => _AddEditItemScreen(
        title: widget.title, champs: widget.champs, initialData: item.data,
        numericFieldsWithUnit: _numericFieldsWithUnit,
        natureReseauOptions: _natureReseauOptions,
        sectionCableOptions: _sectionCableOptions,
        modeOptions: _modeOptions, ouiNonOptions: _ouiNonOptions,
      ),
    ));
    if (result != null && result is Map<String, String>) {
      setState(() => _isSaving = true);
      final updateUseCase = GetIt.instance<UpdateInstallationItemUseCase>();
      final success = await updateUseCase(
        missionId: widget.mission.id, section: widget.sectionKey, index: index,
        item: InstallationItemEntity(data: result, photoPaths: item.photoPaths, createdAt: item.createdAt));
      if (success) {
        await _loadData(); _checkAndNotifyComplete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifié avec succès'), backgroundColor: Colors.green, duration: Duration(milliseconds: 700)));
        }
      }
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem(int index) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer'),
      content: const Text('Voulez-vous vraiment supprimer cet élément ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
      ],
    ));
    if (confirm == true) {
      setState(() => _isSaving = true);
      final removeUseCase = GetIt.instance<RemoveInstallationItemUseCase>();
      final success = await removeUseCase(
        missionId: widget.mission.id, section: widget.sectionKey, index: index);
      if (success) {
        await _loadData(); _checkAndNotifyComplete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supprimé'), backgroundColor: Colors.green, duration: Duration(milliseconds: 500)));
        }
      }
      setState(() => _isSaving = false);
    }
  }

  void _checkAndNotifyComplete() {
    if (_items.isNotEmpty && !widget.isComplete) widget.onComplete(widget.sectionKey);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(children: [
      _items.isEmpty ? _buildEmpty(isSmallScreen) : _buildList(isSmallScreen),
      Positioned(
        bottom: isSmallScreen ? 16 : 20, right: isSmallScreen ? 16 : 20,
        child: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _addItem,
          backgroundColor: AppTheme.primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(_items.isEmpty ? 'Ajouter' : 'Ajouter un autre',
            style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 13 : 14)),
        ),
      ),
    ]);
  }

  Widget _buildEmpty(bool isSmallScreen) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.add_circle_outline, size: isSmallScreen ? 56 : 64, color: Colors.grey.shade300),
    const SizedBox(height: 16),
    Text('Aucun élément', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
    const SizedBox(height: 8),
    Text('Appuyez sur le bouton pour ajouter', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey.shade400)),
  ]));

  Widget _buildList(bool isSmallScreen) => ListView.builder(
    padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, isSmallScreen ? 16 : 20, isSmallScreen ? 16 : 20, 90),
    itemCount: _items.length,
    itemBuilder: (ctx, i) => _buildCard(_items[i], i, isSmallScreen),
  );

  Widget _buildCard(InstallationItem item, int index, bool isSmallScreen) => Container(
    margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: InkWell(
      onTap: () => _editItem(index), borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: isSmallScreen ? 32 : 36, height: isSmallScreen ? 32 : 36,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)]), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: isSmallScreen ? 13 : 15, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.title, style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis)),
            IconButton(icon: Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: isSmallScreen ? 18 : 20), onPressed: () => _editItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 8),
            IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: isSmallScreen ? 18 : 20), onPressed: () => _deleteItem(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: widget.champs.where((c) => item.data.containsKey(c) && item.data[c]!.isNotEmpty).map((champ) {
              final value = item.data[champ]!;
              final unit = _numericFieldsWithUnit[champ] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15))),
                child: Text(unit.isNotEmpty ? '$value $unit' : value,
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ),
        ]),
      ),
    ),
  );
}

// ============================================================
// ÉCRAN D'AJOUT / MODIFICATION — DESIGN MODERNE
// ============================================================
class _AddEditItemScreen extends StatefulWidget {
  final String title;
  final List<String> champs;
  final Map<String, String>? initialData;
  final Map<String, String> numericFieldsWithUnit;
  final List<String> natureReseauOptions;
  final List<String> sectionCableOptions;
  final List<String> modeOptions;
  final List<String> ouiNonOptions;

  const _AddEditItemScreen({
    required this.title, required this.champs, this.initialData,
    required this.numericFieldsWithUnit, required this.natureReseauOptions,
    required this.sectionCableOptions, required this.modeOptions, required this.ouiNonOptions,
  });

  @override
  State<_AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<_AddEditItemScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedValues = {};
  String? _selectedGamme;

  @override
  void initState() {
    super.initState();
    _selectedGamme = widget.initialData?['Gamme De Cellule'];
    for (var champ in widget.champs) {
      if (_isGammeField(champ)) {
        // handled via _selectedGamme
      } else if (_isDropdownField(champ)) {
        _selectedValues[champ] = widget.initialData?[champ];
      } else {
        _controllers[champ] = TextEditingController(text: widget.initialData?[champ] ?? '');
      }
    }
  }

  @override
  void dispose() { for (var c in _controllers.values) {
    c.dispose();
  } super.dispose(); }

  bool _isGammeField(String c) => c == 'Gamme De Cellule';
  bool _isTypeCelluleField(String c) => c == 'Type De Cellule';
  bool _isSectionCableField(String c) => c == 'Section Du Cable';
  bool _isNatureReseauField(String c) => c == 'Nature Du Reseau';
  bool _isModeField(String c) => c == 'Mode';
  bool _isOuiNonField(String c) => c == 'Cuve De Retention' || c == 'Indicateur De Niveau' || c == 'Mise A La Terre';
  bool _isAnneeField(String c) => c == 'Annee De Fabrication' || c == "Annee D'Installation";
  bool _isDropdownField(String c) => _isGammeField(c) || _isTypeCelluleField(c) || _isSectionCableField(c) || _isNatureReseauField(c) || _isModeField(c) || _isOuiNonField(c) || _isAnneeField(c);

  List<String> _getAnneeOptions() {
    final y = DateTime.now().year;
    return List.generate(y - 1900 + 1, (i) => (y - i).toString());
  }

  List<String> _optionsFor(String champ) {
    if (_isTypeCelluleField(champ)) return CelluleGammes.getTypesForGamme(_selectedGamme);
    if (_isSectionCableField(champ)) return widget.sectionCableOptions;
    if (_isNatureReseauField(champ)) return widget.natureReseauOptions;
    if (_isModeField(champ)) return widget.modeOptions;
    if (_isOuiNonField(champ)) return widget.ouiNonOptions;
    if (_isAnneeField(champ)) return _getAnneeOptions();
    return [];
  }

  bool _hasAtLeastOneFieldFilled() {
    if (_selectedGamme != null && _selectedGamme!.isNotEmpty) return true;
    for (var c in widget.champs) {
      if (_isGammeField(c)) continue;
      if (_isDropdownField(c)) { if (_selectedValues[c] != null && _selectedValues[c]!.isNotEmpty) return true; }
      else { if (_controllers[c]?.text.trim().isNotEmpty == true) return true; }
    }
    return false;
  }

  void _save() {
    if (!_hasAtLeastOneFieldFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir au moins un champ'), backgroundColor: Colors.orange));
      return;
    }
    final result = <String, String>{};
    for (var champ in widget.champs) {
      if (_isGammeField(champ)) {
        if (_selectedGamme != null && _selectedGamme!.isNotEmpty) result[champ] = _selectedGamme!;
      } else if (_isDropdownField(champ)) {
        final v = _selectedValues[champ]; if (v != null && v.isNotEmpty) result[champ] = v;
      } else {
        final v = _controllers[champ]?.text.trim() ?? ''; if (v.isNotEmpty) result[champ] = v;
      }
    }
    Navigator.pop(context, result);
  }

  // ── Dropdown moderne avec option vide ──
  Widget _buildModernDropdown(BuildContext context, String champ, {
    required String? currentValue, required List<String> options,
    required ValueChanged<String?> onChanged, String? unitPrefixLabel,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final hasValue = currentValue != null && currentValue.isNotEmpty;
    final accent = AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasValue ? accent.withOpacity(0.5) : Colors.grey.shade300, width: hasValue ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: hasValue ? currentValue : null,
        isExpanded: true,
        iconSize: 0,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: champ,
          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: hasValue ? accent : Colors.grey.shade500, fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            if (hasValue) GestureDetector(
              onTap: () => onChanged(null),
              child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.clear, size: 16, color: Colors.grey.shade400)),
            ),
            Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Icons.keyboard_arrow_down_rounded, color: hasValue ? accent : Colors.grey.shade400, size: 22)),
          ]),
          prefixIcon: unitPrefixLabel != null
              ? Padding(padding: const EdgeInsets.only(left: 12, right: 4, top: 16),
                  child: Text(unitPrefixLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
              : null,
        ),
        hint: Text('Sélectionnez...', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade400)),
        items: [
          DropdownMenuItem<String>(value: '',
            child: Row(children: [
              Icon(Icons.remove_circle_outline, size: 14, color: Colors.grey.shade400), const SizedBox(width: 8),
              Text('— Aucun —', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ])),
          ...options.map((opt) => DropdownMenuItem<String>(value: opt,
            child: Text(opt, style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis))),
        ],
        onChanged: (v) => onChanged(v == '' ? null : v),
        selectedItemBuilder: (ctx) => [
          Text('—', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade400)),
          ...options.map((opt) => Text(opt, style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String champ, TextEditingController controller) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final unit = widget.numericFieldsWithUnit[champ];
    final isNumeric = unit != null;
    final hasValue = controller.text.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasValue ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.grey.shade300, width: hasValue ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        maxLines: champ == 'Observations' ? 3 : 1,
        onChanged: (_) => setState(() {}),
        style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey.shade800),
        decoration: InputDecoration(
          labelText: champ,
          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: hasValue ? AppTheme.primaryBlue : Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14),
          suffixIcon: (unit != null && unit.isNotEmpty)
              ? Padding(padding: const EdgeInsets.only(right: 14, top: 16),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)))
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.initialData != null ? 'Modifier' : 'Ajouter',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Info header
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.08), AppTheme.primaryBlue.withOpacity(0.03)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: isSmallScreen ? 18 : 20)),
                const SizedBox(width: 12),
                Expanded(child: Text('Tous les champs sont optionnels.',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppTheme.primaryBlue.withOpacity(0.8)))),
              ]),
            ),

            // Champs
            ...widget.champs.map((champ) {
              // Gamme → contrôle le type de cellule
              if (_isGammeField(champ)) {
                return _buildModernDropdown(context, champ,
                  currentValue: _selectedGamme, options: CelluleGammes.gammes,
                  onChanged: (v) => setState(() {
                    _selectedGamme = v;
                    final curType = _selectedValues['Type De Cellule'];
                    if (curType != null && !CelluleGammes.getTypesForGamme(v).contains(curType)) {
                      _selectedValues['Type De Cellule'] = null;
                    }
                  }),
                );
              }

              // Type de cellule → dépend de la gamme
              if (_isTypeCelluleField(champ)) {
                final types = CelluleGammes.getTypesForGamme(_selectedGamme);
                final locked = _selectedGamme == null || _selectedGamme!.isEmpty;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (locked) Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700), const SizedBox(width: 8),
                      Text("Sélectionnez d'abord une gamme de cellule", style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                    ]),
                  ),
                  IgnorePointer(
                    ignoring: locked,
                    child: Opacity(opacity: locked ? 0.4 : 1.0,
                      child: _buildModernDropdown(context, champ, currentValue: _selectedValues[champ], options: types,
                        onChanged: (v) => setState(() => _selectedValues[champ] = v))),
                  ),
                ]);
              }

              // Section de câble avec unité à gauche (préfixe)
              if (_isSectionCableField(champ)) {
                return _buildModernDropdown(context, champ, currentValue: _selectedValues[champ],
                  options: widget.sectionCableOptions, unitPrefixLabel: 'mm²',
                  onChanged: (v) => setState(() => _selectedValues[champ] = v));
              }

              // Dropdowns standard
              if (_isDropdownField(champ)) {
                return _buildModernDropdown(context, champ, currentValue: _selectedValues[champ],
                  options: _optionsFor(champ), onChanged: (v) => setState(() => _selectedValues[champ] = v));
              }

              // TextField
              return _buildTextField(context, champ, _controllers[champ]!);
            }),

            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.initialData != null ? 'Mettre à jour' : 'Enregistrer',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            )),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ]),
        ),
      ),
    );
  }
}