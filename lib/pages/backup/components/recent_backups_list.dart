// lib/pages/backup/components/recent_backups_list.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class RecentBackupsList extends StatelessWidget {
  final List<File> backups;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(File) onDeleteFile;

  const RecentBackupsList({
    super.key,
    required this.backups,
    required this.isLoading,
    required this.onRefresh,
    required this.onDeleteFile,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Conserver strictement les 4 plus récentes générations
    final recent4 = backups.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Sauvegardes locales',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primaryBlue),
              tooltip: 'Actualiser',
              onPressed: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (recent4.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Text(
              'Aucune sauvegarde récente disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent4.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = recent4[index];
              return _buildBackupCard(file, context, isDarkMode);
            },
          ),
      ],
    );
  }

  Widget _buildBackupCard(File file, BuildContext context, bool isDarkMode) {
    final fileName = file.path.split('/').last;
    final stat = file.statSync();
    final sizeInMb = (stat.size / (1024 * 1024)).toStringAsFixed(1);
    final modDate = stat.modified;
    final formattedDate =
        '${modDate.day.toString().padLeft(2, '0')}/${modDate.month.toString().padLeft(2, '0')}/${modDate.year} à ${modDate.hour.toString().padLeft(2, '0')}:${modDate.minute.toString().padLeft(2, '0')}';

    final isInspecFormat = fileName.toLowerCase().endsWith('.inspec');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isInspecFormat
                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isInspecFormat ? Icons.folder_zip_rounded : Icons.description_rounded,
              color: isInspecFormat ? AppTheme.primaryBlue : Colors.orange.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.darkBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$sizeInMb Mo • $formattedDate',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Réussi',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions : Partager & Supprimer
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 18, color: AppTheme.primaryBlue),
            tooltip: 'Partager / Exporter',
            onPressed: () async {
              try {
                await Share.shareXFiles([XFile(file.path)], text: fileName);
              } catch (_) {}
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
            tooltip: 'Supprimer',
            onPressed: () => onDeleteFile(file),
          ),
        ],
      ),
    );
  }
}
