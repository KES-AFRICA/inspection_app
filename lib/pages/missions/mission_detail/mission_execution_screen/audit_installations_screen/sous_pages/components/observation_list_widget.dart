// lib/pages/.../components/observation_list_widget.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';

class ObservationListWidget extends StatefulWidget {
  final String title;
  final List<dynamic> initialObservations;
  final Function(List<dynamic>) onObservationsChanged;
  final dynamic Function(String) createObservation;
  final void Function(dynamic, String) updateObservation;
  final bool isSmallScreen;

  const ObservationListWidget({
    super.key,
    required this.title,
    required this.initialObservations,
    required this.onObservationsChanged,
    required this.createObservation,
    required this.updateObservation,
    required this.isSmallScreen,
  });

  @override
  State<ObservationListWidget> createState() => _ObservationListWidgetState();
}

class _ObservationListWidgetState extends State<ObservationListWidget> {
  late List<dynamic> _observations;

  @override
  void initState() {
    super.initState();
    _observations = List.from(widget.initialObservations);
  }

  @override
  void didUpdateWidget(covariant ObservationListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si les observations parentes ont changé, mettre à jour
    if (widget.initialObservations != oldWidget.initialObservations) {
      _observations = List.from(widget.initialObservations);
    }
  }

  void _notifyParent() {
    widget.onObservationsChanged(List.from(_observations));
  }

  void _ajouterObservation() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ajouter ${widget.title.toLowerCase()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Saisissez votre observation...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final texte = controller.text.trim();
              controller.dispose();
              if (texte.isNotEmpty) {
                Navigator.pop(dialogContext, texte);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _observations.add(widget.createObservation(result));
      });
      _notifyParent();
    }
  }

  void _editerObservation(dynamic observation, int index) async {
    final controller = TextEditingController(text: observation.texte);
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier ${widget.title.toLowerCase()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Modifiez votre observation...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final texte = controller.text.trim();
              controller.dispose();
              if (texte.isNotEmpty) {
                Navigator.pop(dialogContext, texte);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        widget.updateObservation(observation, result);
        _observations[index] = observation;
      });
      _notifyParent();
    }
  }

  void _supprimerObservation(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette observation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _observations.removeAt(index);
      });
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkBlue,
                ),
              ),
              TextButton.icon(
                onPressed: _ajouterObservation,
                icon: Icon(Icons.add_circle_outline, size: 18),
                label: Text('Ajouter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._observations.asMap().entries.map((entry) {
            final index = entry.key;
            final obs = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _editerObservation(obs, index),
                      child: Text(
                        obs.texte,
                        style: TextStyle(
                          fontSize: widget.isSmallScreen ? 13 : 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => _supprimerObservation(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}