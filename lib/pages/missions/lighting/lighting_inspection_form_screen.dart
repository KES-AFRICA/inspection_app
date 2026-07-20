import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    final edit = widget.inspectionToEdit;
    _batimentLocal = edit?.batimentLocal ?? '';
    _typeLuminaire = edit?.typeLuminaire ?? '';
    _dateVerification = edit?.dateVerification ?? DateTime.now();
    _nbLuminairesConformes = edit?.nbLuminairesConformes ?? 0;
    _nonConformingLuminaires = edit != null
        ? List.from(edit.nonConformingLuminaires)
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isEditing = widget.inspectionToEdit != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          isEditing
              ? 'Modifier l\'inspection'
              : 'Nouvelle inspection éclairage',
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _saveInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 20.0),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Étape 1 : Informations du Local (Aéré & Sans Icônes) ──
                const Text(
                  'INFORMATIONS GÉNÉRALES DU LOCAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.greyDark,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Champ Bâtiment / Local (Sans icône devant)
                        const Text(
                          'Bâtiment / Local *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _batimentLocal,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Veuillez saisir le nom du local ou bâtiment'
                              : null,
                          onChanged: (val) => _batimentLocal = val,
                          decoration: const InputDecoration(
                            hintText: 'ex. Bâtiment A - Bureau 101...',
                            prefixIcon: null, // SANS ICÔNE
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Champ Type de Luminaire (Sans icône devant)
                        const Text(
                          'Type de luminaire *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _typeLuminaire,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Veuillez saisir le type de luminaire'
                              : null,
                          onChanged: (val) => _typeLuminaire = val,
                          decoration: const InputDecoration(
                            hintText:
                                'ex. Dalle LED 60x60, Réglette Fluorescente...',
                            prefixIcon: null, // SANS ICÔNE
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date de vérification
                        const Text(
                          'Date de vérification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.greyLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_dateVerification),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Étape 2 : Comptage des Luminaires ──
                const Text(
                  'COMPTAGE ET CONFORMITÉ DES LUMINAIRES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.greyDark,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Counter : Nombre de luminaires conformes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luminaires conformes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton.filledTonal(
                                  onPressed: _nbLuminairesConformes > 0
                                      ? () => setState(
                                          () => _nbLuminairesConformes--,
                                        )
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '$_nbLuminairesConformes',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () =>
                                      setState(() => _nbLuminairesConformes++),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luminaires non conformes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _nonConformingLuminaires.isNotEmpty
                                    ? Colors.red.shade50
                                    : AppTheme.greyLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_nonConformingLuminaires.length}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _nonConformingLuminaires.isNotEmpty
                                      ? Colors.red.shade800
                                      : AppTheme.greyDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Étape 3 : Liste des luminaires non conformes (Annotation #0001, #0002) ──
                Text(
                  'LUMINAIRES NON CONFORMES (${_nonConformingLuminaires.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.greyDark,
                  ),
                ),
                const SizedBox(height: 12),

                if (_nonConformingLuminaires.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 36,
                            color: Colors.green,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Aucun luminaire non conforme pour l\'instant',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Si vous constatez des défaillances sur un luminaire, ajoutez-le ci-dessous.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
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
                      // Format d'annotation exigé par le client : #0001, #0002, etc.
                      final annotation =
                          '#${(index + 1).toString().padLeft(4, '0')}';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade50,
                            child: Text(
                              annotation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                          title: Text(
                            'Luminaire $annotation',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${lum.nbNonConformities} point(s) non conforme(s)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openLuminaireSheet(
                                  initial: lum,
                                  index: index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
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
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add),
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
    ),
  );
  }

  void _pickDate() async {
    FocusScope.of(context).unfocus();
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

  void _openLuminaireSheet({
    NonConformingLuminaire? initial,
    int? index,
  }) async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<NonConformingLuminaire>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddNonConformingLuminaireSheet(initialLuminaire: initial),
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final newId = 'insp_l_${DateTime.now().microsecondsSinceEpoch}';
    final inspection = LightingInspection(
      id: widget.inspectionToEdit?.id ?? newId,
      missionId: widget.missionId,
      batimentLocal: _batimentLocal.trim(),
      typeLuminaire: _typeLuminaire.trim(),
      dateVerification: _dateVerification,
      nbLuminairesConformes: _nbLuminairesConformes,
      nonConformingLuminaires: _nonConformingLuminaires,
      createdAt: widget.inspectionToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await HiveService.saveLightingInspection(inspection);

    // Mise à jour automatique du statut réel de la mission globale si elle était en attente
    final mission = HiveService.getMissionById(widget.missionId);
    if (mission != null && (mission.status == 'en_attente' || mission.status == 'en attente')) {
      mission.status = 'en_cours';
      mission.updatedAt = DateTime.now();
      await mission.save();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection éclairage enregistrée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }
}
