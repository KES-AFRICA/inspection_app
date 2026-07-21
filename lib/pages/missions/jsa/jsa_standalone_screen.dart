import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/sequence/steps/jsa_step.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Écran Autonome de gestion de la JSA (Analyse de Sécurité du Travail) au niveau de la Mission
class JsaStandaloneScreen extends StatefulWidget {
  final Mission mission;

  const JsaStandaloneScreen({
    super.key,
    required this.mission,
  });

  @override
  State<JsaStandaloneScreen> createState() => _JsaStandaloneScreenState();
}

class _JsaStandaloneScreenState extends State<JsaStandaloneScreen> {
  final GlobalKey<JsaStepState> _jsaKey = GlobalKey<JsaStepState>();
  int _currentSubCategoryIndex = 0;

  static const List<String> _subCategoryTitles = [
    'Opération & Équipe',
    'Plan d\'urgence',
    'Dangers',
    'Exigences (EPC)',
    'EPI',
    'Validation finale',
  ];

  static const List<IconData> _subCategoryIcons = [
    Icons.engineering_outlined,
    Icons.emergency_outlined,
    Icons.warning_amber_outlined,
    Icons.security_outlined,
    Icons.health_and_safety_outlined,
    Icons.verified_outlined,
  ];

  void _onSubCategoryTap(int index) {
    setState(() {
      _currentSubCategoryIndex = index;
    });
    _jsaKey.currentState?.navigateToSubCategory(index);
  }

  Future<void> _handleNext() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.next();
      if (handled) {
        setState(() {
          _currentSubCategoryIndex = jsaState.currentSubCategory;
        });
      } else {
        // Si la validation de la dernière étape est réussie et que JSA est complète
        final isCompleted = HiveService.isJsaCompleted(widget.mission.id);
        if (isCompleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ JSA validée avec succès ! Les modules d\'inspection sont déverrouillés.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _handlePrevious() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.previous();
      if (handled) {
        setState(() {
          _currentSubCategoryIndex = jsaState.currentSubCategory;
        });
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentSubCategoryIndex == _subCategoryTitles.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'JSA - Analyse de Sécurité',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.mission.nomClient}${widget.mission.nomSite != null ? ' • ${widget.mission.nomSite}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Barre de navigation des 6 sous-catégories JSA ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_subCategoryTitles.length, (index) {
                  final isSelected = index == _currentSubCategoryIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _onSubCategoryTap(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _subCategoryIcons[index],
                              size: 16,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${index + 1}. ${_subCategoryTitles[index]}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),

          // ── Corps principal JsaStep ──
          Expanded(
            child: JsaStep(
              key: _jsaKey,
              mission: widget.mission,
              onDataChanged: (data) {},
              onSubStepChanged: () {
                if (mounted && _jsaKey.currentState != null) {
                  setState(() {
                    _currentSubCategoryIndex =
                        _jsaKey.currentState!.currentSubCategory;
                  });
                }
              },
            ),
          ),

          // ── Barre de commande inférieure ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handlePrevious,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      _currentSubCategoryIndex == 0 ? 'RETOUR HUB' : 'PRÉCÉDENT',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleNext,
                    icon: Icon(
                      isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(
                      isLastStep ? 'VALIDER LA JSA' : 'SUIVANT',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep ? Colors.green.shade700 : AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
