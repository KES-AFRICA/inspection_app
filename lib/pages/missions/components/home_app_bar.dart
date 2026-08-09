import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSortPressed;
  final int currentPageIndex;
  final Function(String)? onStatsPeriodSelected; // NOUVEAU : Callback pour les stats

  const HomeAppBar({
    super.key,
    required this.onMenuPressed,
    required this.onFilterPressed,
    required this.onSearchPressed,
    required this.onSortPressed,
    required this.currentPageIndex,
    this.onStatsPeriodSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getAppBarTitle() {
    switch (currentPageIndex) {
      case 0:
        return 'Mes Missions';
      case 1:
        return 'Statistiques & KPI';
      case 2:
        return 'Sauvegardes Cloud';
      case 3:
        return 'Import / Export';
      case 4:
        return 'Corbeille';
      default:
        return 'Mes Missions';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuPressed,
              tooltip: 'Menu',
            ),
            SizedBox(
              child: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildRightActionWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildRightActionWidget() {
    switch (currentPageIndex) {
      case 0:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'filter') {
              onFilterPressed();
            } else if (value == 'search') {
              onSearchPressed();
            } else if (value == 'sort') {
              onSortPressed();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Filtrer'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Rechercher'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Trier'),
                ],
              ),
            ),
          ],
        );
      case 1:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            onStatsPeriodSelected?.call(value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'today',
              child: Row(
                children: [
                  Icon(Icons.today, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Aujourd\'hui'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'week',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Cette semaine'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'month',
              child: Row(
                children: [
                  Icon(Icons.calendar_view_month, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Ce mois'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'year',
              child: Row(
                children: [
                  Icon(Icons.event_note, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Cette année'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'custom',
              child: Row(
                children: [
                  Icon(Icons.date_range, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Période personnalisée'),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox(width: 48);
    }
  }
}
