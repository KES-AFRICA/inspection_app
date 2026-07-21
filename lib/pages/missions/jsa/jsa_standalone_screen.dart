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

  Future<void> _handleNext() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.next();
      if (mounted) setState(() {});
      if (!handled) {
        // La validation du dernier slide (slide 5) est demandée
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
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez compléter toutes les sous-sections de la JSA.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePrevious() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.previous();
      if (mounted) setState(() {});
      if (!handled) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jsaState = _jsaKey.currentState;
    final isLastStep = jsaState?.isLastSlide ?? false;
    final isFirstStep = jsaState?.isFirstSlide ?? true;

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
          // ── Corps principal JsaStep ──
          Expanded(
            child: JsaStep(
              key: _jsaKey,
              mission: widget.mission,
              onDataChanged: (data) {},
              onSubStepChanged: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
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
                      isFirstStep ? 'RETOUR HUB' : 'PRÉCÉDENT',
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
                      isLastStep ? 'VALIDER' : 'SUIVANT',
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
