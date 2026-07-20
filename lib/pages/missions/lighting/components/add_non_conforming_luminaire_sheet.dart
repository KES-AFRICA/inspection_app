import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/lighting_inspection.dart';

class AddNonConformingLuminaireSheet extends StatefulWidget {
  final NonConformingLuminaire? initialLuminaire;

  const AddNonConformingLuminaireSheet({
    super.key,
    this.initialLuminaire,
  });

  @override
  State<AddNonConformingLuminaireSheet> createState() =>
      _AddNonConformingLuminaireSheetState();
}

class _AddNonConformingLuminaireSheetState
    extends State<AddNonConformingLuminaireSheet> {
  late String _repereLocalisation;
  late List<LuminaireQuestionAnswer> _answers;
  int _currentStep = 0; // 0, 1, 2, 3 (représentant les 4 étapes)

  final ImagePicker _picker = ImagePicker();

  static const List<String> _questionsText = [
    '1. État général du luminaire',
    '2. Fixation correcte et stable',
    '3. Protection contre les contacts directs',
    '4. Absence d\'échauffement ou de brûlure',
    '5. Absence de corrosion ou d\'encrassement',
    '6. Indice IP adapté au local',
    '7. Conducteurs correctement raccordés',
    '8. Présence de la mise à la terre',
    '9. Allumage correct',
    '10. Extinction correcte',
    '11. Absence de scintillement',
    '12. Accessibilité pour la maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _repereLocalisation =
        widget.initialLuminaire?.repereLocalisation ?? '';

    // Initialiser ou récupérer les 12 réponses
    if (widget.initialLuminaire != null &&
        widget.initialLuminaire!.answers.isNotEmpty) {
      _answers = widget.initialLuminaire!.answers
          .map((a) => LuminaireQuestionAnswer(
                questionIndex: a.questionIndex,
                isConform: a.isConform,
                commentaire: a.commentaire,
                photoPaths: List.from(a.photoPaths),
              ))
          .toList();
    } else {
      _answers = List.generate(
        12,
        (i) => LuminaireQuestionAnswer(
          questionIndex: i + 1,
          isConform: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle de drag & Header Bottom Sheet ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialLuminaire != null
                          ? 'Modifier le luminaire'
                          : 'Ajouter un luminaire non conforme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B365D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Étape ${_currentStep + 1} sur 4 (Questions ${_currentStep * 3 + 1} à ${_currentStep * 3 + 3})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF5A6B82),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Progress Bar M3 ──
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4.0,
            backgroundColor:
                isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
            color: const Color(0xFFE65100),
            minHeight: 4,
          ),

          // ── Contenu du Formulaire / Questionnaire ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 0) ...[
                    // Champ de localisation / Repère luminaire
                    Text(
                      'REPÈRE / LOCALISATION DU LUMINAIRE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF5A6B82),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(text: _repereLocalisation)
                        ..selection = TextSelection.collapsed(
                            offset: _repereLocalisation.length),
                      onChanged: (val) => _repereLocalisation = val,
                      decoration: InputDecoration(
                        hintText: 'ex. Plafond central, Allée A, Poste 3...',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // ── Les 3 questions de l'étape courante ──
                  for (int i = _currentStep * 3; i < (_currentStep + 1) * 3; i++) ...[
                    _buildQuestionItem(i, isDark),
                    if (i < (_currentStep + 1) * 3 - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // ── Barre d'Action de Navigation (Précédent / Suivant / Sauvegarder) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 3) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _saveAndClose();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentStep < 3 ? 'Suivant' : 'Valider & Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le composant d'une question avec choix Conforme/Non Conforme, Commentaire & Photos
  Widget _buildQuestionItem(int index, bool isDark) {
    final answer = _answers[index];
    final questionTitle = _questionsText[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          questionTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),

        // ── Boutons Choix Conforme / Non Conforme ──
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16),
                    SizedBox(width: 6),
                    Text('Conforme'),
                  ],
                ),
                selected: answer.isConform,
                selectedColor: const Color(0xFFE8F5E9),
                labelStyle: TextStyle(
                  color: answer.isConform
                      ? const Color(0xFF2E7D32)
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight:
                      answer.isConform ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      answer.isConform = true;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 16),
                    SizedBox(width: 6),
                    Text('Non conforme'),
                  ],
                ),
                selected: !answer.isConform,
                selectedColor: const Color(0xFFFFEBEE),
                labelStyle: TextStyle(
                  color: !answer.isConform
                      ? const Color(0xFFC62828)
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight:
                      !answer.isConform ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      answer.isConform = false;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        // ── Zone Commentaire & Photos par Question (Accessible particulièrement en Non Conforme) ──
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: answer.commentaire)
            ..selection = TextSelection.collapsed(
                offset: (answer.commentaire ?? '').length),
          onChanged: (val) => answer.commentaire = val,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Commentaires / observations sur ce critère...',
            prefixIcon: const Icon(Icons.comment_outlined, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        const SizedBox(height: 10),

        // ── Section Photo Dédiée à cette Question ──
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickPhotoForQuestion(answer),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2C3854) : const Color(0xFFEBF3FC),
                foregroundColor: const Color(0xFF1B365D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: const Text(
                'Ajouter photo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            if (answer.photoPaths.isNotEmpty)
              Text(
                '${answer.photoPaths.length} photo(s)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
          ],
        ),

        // Miniature des photos de la question
        if (answer.photoPaths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: answer.photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, pIndex) {
                final path = answer.photoPaths[pIndex];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        path,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            answer.photoPaths.removeAt(pIndex);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Prise / sélection de photo pour une question spécifique
  Future<void> _pickPhotoForQuestion(LuminaireQuestionAnswer answer) async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null) {
      setState(() {
        answer.photoPaths.add(photo.path);
      });
    }
  }

  /// Valider et retourner le luminaire non conforme
  void _saveAndClose() {
    final newId = 'lum_${DateTime.now().microsecondsSinceEpoch}';
    final luminaire = NonConformingLuminaire(
      id: widget.initialLuminaire?.id ?? newId,
      repereLocalisation: _repereLocalisation.trim().isEmpty
          ? 'Luminaire #${newId.substring(newId.length - 4)}'
          : _repereLocalisation.trim(),
      answers: _answers,
      createdAt: widget.initialLuminaire?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(luminaire);
  }
}
