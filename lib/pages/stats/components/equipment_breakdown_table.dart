// lib/pages/stats/components/equipment_breakdown_table.dart

import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/statistics/analytics_engine.dart';

class EquipmentBreakdownTable extends StatelessWidget {
  final AnalyticsDashboardData data;
  final bool isDarkMode;

  const EquipmentBreakdownTable({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final items = data.crossCategoryAnalysis;

    return Container(
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
              Icon(Icons.format_list_bulleted_rounded, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Catégorie 5 — Répartition des 10 Catégories Métiers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Analyse croisée certifiée : distinction stricte TGBT ≠ Armoire ≠ Coffret ≠ Inverseur',
            style: TextStyle(
              fontSize: 11.5,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucun équipement ou local récensé.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 44,
                columnSpacing: 16,
                horizontalMargin: 4,
                columns: [
                  DataColumn(
                    label: Text(
                      'Catégorie Métier',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'Éléments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'Contrôlés',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'NC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    numeric: true,
                    label: Text(
                      'Conformité %',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ),
                ],
                rows: items.map((item) {
                  Color rateColor = item.complianceRate >= 90.0
                      ? const Color(0xFF10B981)
                      : (item.complianceRate >= 75.0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(item.categoryKey),
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.equipmentCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey.shade300 : AppTheme.darkBlue,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.totalPointsEvaluated}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${item.nonConformitiesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.nonConformitiesCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: rateColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.complianceRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: rateColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'local_mt':
      case 'local_bt':
      case 'local_ge':
        return Icons.domain_rounded;
      case 'cellule_mt':
        return Icons.grid_view_rounded;
      case 'transfo_mt_bt':
        return Icons.bolt_rounded;
      case 'tgbt':
      case 'armoire':
      case 'coffret':
        return Icons.developer_board_rounded;
      case 'inverseur':
        return Icons.alt_route_rounded;
      case 'prise_terre':
      default:
        return Icons.gavel_rounded;
    }
  }
}
