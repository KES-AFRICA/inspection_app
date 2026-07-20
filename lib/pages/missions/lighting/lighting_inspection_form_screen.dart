import 'package:flutter/material.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/pages/missions/lighting/components/add_non_conforming_luminaire_sheet.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:intl/intl.dart';

class LightingInspectionFormScreen extends StatefulWidget {
  final String missionId;
  final LightingInspection? inspectionToEdit;

  const LightingInspectionFormScreen({
    super.key,
    required this.missionId,
    this.inspectionToEdit,
  });

  @override
  State<LightingInspectionFormScreen> createState() =>
      _LightingInspectionFormScreenState();
}

class _LightingInspectionFormScreenState
    extends State<LightingInspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _batimentLocal;
  late String _typeLuminaire;
  late DateTime _dateVerification;
  late int _nbLuminairesConformes;
  late List<NonConformingLuminaire> _nonConformingLuminaires;

  final List<String> _typesLuminairesSuggere = [
    'Dalle LED 60x60',
    'Réglette Fluorescente (T8/T5)',
    'Projecteur LED / Extérieur',
    'Éclairage de Sécurité (BAES)',
    'Spot Encastré LED',
    'Hublot Mur ou Plafond',
    'Autre type de luminaire',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.inspectionToEdit;
    _batimentLocal = edit?.batimentLocal ?? '';
    _typeLuminaire = edit?.typeLuminaire ?? 'Dalle LED 60x60';
    _dateVerification = edit?.dateVerification ?? DateTime.now();
    _nbLuminairesConformes = edit?.nbLuminairesConformes ?? 0;
    _nonConformingLuminaires = edit != null
        ? List.from(edit.nonConformingLuminaires)
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.inspectionToEdit != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Modifier l\'inspection'
              : 'Nouvelle inspection éclairage',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1B365D),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _saveInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              isEditing ? 'Mettre à jour' : 'Enregistrer l\'inspection',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Étape 1 : Informations générales du local ──
                Text(
                  'INFORMATIONS GÉNÉRALES DU LOCAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF5A6B82),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ Bâtiment / Local
                      Text(
                        'Bâtiment / Local *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: _batimentLocal,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Veuillez saisir le nom du local ou bâtiment'
                            : null,
                        onChanged: (val) => _batimentLocal = val,
                        decoration: InputDecoration(
                          hintText: 'ex. Bâtiment A - Bureau 101, Couloir...',
                          prefixIcon: const Icon(Icons.meeting_room_outlined),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Champ Type de Luminaire
                      Text(
                        'Type de luminaire *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _typesLuminairesSuggere.contains(_typeLuminaire)
                            ? _typeLuminaire
                            : _typesLuminairesSuggere.first,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _typeLuminaire = val;
                            });
                          }
                        },
                        items: _typesLuminairesSuggere
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lightbulb_outline),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date de vérification
                      Text(
                        'Date de vérification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFF8F9FC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  color: Color(0xFFE65100)),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_dateVerification),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Étape 2 : Comptage des Luminaires ──
                Text(
                  'COMPTAGE ET CONFORMITÉ DES LUMINAIRES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF5A6B82),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Counter : Nombre de luminaires conformes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Luminaires conformes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Luminaires sans aucun défaut répertorié',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: _nbLuminairesConformes > 0
                                    ? () => setState(
                                        () => _nbLuminairesConformes--)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '$_nbLuminairesConformes',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: () => setState(
                                    () => _nbLuminairesConformes++),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),

                      // Champ calculé automatique : Nombre de luminaires non conformes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Luminaires non conformes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Calculé automatiquement via la liste ci-dessous',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _nonConformingLuminaires.isNotEmpty
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_nonConformingLuminaires.length}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _nonConformingLuminaires.isNotEmpty
                                    ? const Color(0xFFC62828)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Étape 3 : Liste des luminaires non conformes ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LUMINAIRES NON CONFORMES (${_nonConformingLuminaires.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF5A6B82),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_nonConformingLuminaires.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 32, color: Color(0xFF2E7D32)),
                        SizedBox(height: 8),
                        Text(
                          'Aucun luminaire non conforme pour l\'instant',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Si vous constatez des défaillances sur un luminaire, ajoutez-le ci-dessous.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _nonConformingLuminaires.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lum = _nonConformingLuminaires[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEBEE),
                            child: Icon(Icons.lightbulb_outline,
                                color: Color(0xFFC62828)),
                          ),
                          title: Text(
                            lum.repereLocalisation ?? 'Luminaire #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${lum.nbNonConformities} critère(s) non conforme(s)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () =>
                                    _openLuminaireSheet(initial: lum, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _nonConformingLuminaires.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Bouton : Ajouter un luminaire non conforme
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openLuminaireSheet(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE65100),
                      side: const BorderSide(
                          color: Color(0xFFE65100), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Ajouter un luminaire non conforme',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateVerification,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateVerification = picked;
      });
    }
  }

  void _openLuminaireSheet({NonConformingLuminaire? initial, int? index}) async {
    final result = await showModalBottomSheet<NonConformingLuminaire>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddNonConformingLuminaireSheet(
        initialLuminaire: initial,
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _nonConformingLuminaires[index] = result;
        } else {
          _nonConformingLuminaires.add(result);
        }
      });
    }
  }

  void _saveInspection() async {
    if (!_formKey.currentState!.validate()) return;

    final newId = 'insp_l_${DateTime.now().microsecondsSinceEpoch}';
    final inspection = LightingInspection(
      id: widget.inspectionToEdit?.id ?? newId,
      missionId: widget.missionId,
      batimentLocal: _batimentLocal.trim(),
      typeLuminaire: _typeLuminaire,
      dateVerification: _dateVerification,
      nbLuminairesConformes: _nbLuminairesConformes,
      nonConformingLuminaires: _nonConformingLuminaires,
      createdAt: widget.inspectionToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await HiveService.saveLightingInspection(inspection);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection éclairage enregistrée avec succès !'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }
}
