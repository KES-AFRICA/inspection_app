// lib/pages/stats/components/risk_analysis_card.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class RiskAnalysisCard extends StatelessWidget {
  final AnalyticsDashboardData data;
  final bool isDarkMode;

  const RiskAnalysisCard({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final risks = data.riskFamiliesStats;
    final norms = data.normativeReferencesStats;
    final riskInstallations = data.riskInstallations;

    return Column(
      children: [
        // Catégorie 7 : Installations à risque
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_rounded, size: 20, color: const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catégorie 7 — Installations & Locaux à Risque',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (riskInstallations.isEmpty)
                Text(
                  'Aucune installation ou local présentant un risque critique particulier.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: riskInstallations.length.clamp(0, 4),
                  itemBuilder: (context, index) {
                    final item = riskInstallations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.place_rounded, size: 14, color: const Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${item.name} (${item.type})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.critiqueCount} critiques',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Catégories 8 & 9 : Références Normatives & Familles de Risques
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Normes (Catégorie 8)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cat. 8 — Normes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (norms.isEmpty)
                      Text(
                        'Aucune référence.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      )
                    else
                      ...norms.take(4).map((n) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  n.reference,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${n.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Familles de Risques (Catégorie 9)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, size: 16, color: const Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cat. 9 — Risques',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (risks.isEmpty)
                      Text(
                        'Aucun risque.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      )
                    else
                      ...risks.take(4).map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  r.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${r.count}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
