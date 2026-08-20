import 'package:flutter/material.dart';
import '../services/normative_search_service.dart';

/// Widget réutilisable d'affichage des suggestions normatives en temps réel et du badge de rattachement.
class NormativeSearchSuggestionsWidget extends StatelessWidget {
  final String queryText;
  final String? selectedReferenceNormative;
  final String? selectedFamilleRisque;
  final String? selectedCriticite;
  final ValueChanged<NormativeSearchResult> onSelect;
  final VoidCallback onUnlink;

  const NormativeSearchSuggestionsWidget({
    super.key,
    required this.queryText,
    this.selectedReferenceNormative,
    this.selectedFamilleRisque,
    this.selectedCriticite,
    required this.onSelect,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final hasRef = selectedReferenceNormative != null && selectedReferenceNormative!.trim().isNotEmpty;
    final results = (queryText.trim().length >= 3)
        ? NormativeSearchService.search(queryText.trim())
        : <NormativeSearchResult>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─────────────────────────────────────────────────────────────
        // BADGE NORME RATTACHÉE (Design Épuré et Clair)
        // ─────────────────────────────────────────────────────────────
        if (hasRef)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NORME RATTACHÉE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedReferenceNormative!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C4A6E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onUnlink,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off_rounded, color: Color(0xFFE11D48), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Détacher',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ─────────────────────────────────────────────────────────────
        // ZONE DE SUGGESTIONS SCROLLABLE (Type Select / Dropdown)
        // ─────────────────────────────────────────────────────────────
        if (!hasRef && results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête sans icône et sans risque d'overflow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'RÉFÉRENTIEL NORMATIF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${results.length} correspondance${results.length > 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3730A3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Liste scrollable limitée en hauteur (Select Dropdown style)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final res = results[index];
                      return InkWell(
                        onTap: () => onSelect(res),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.pointVerification,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      res.referenceNormative,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
