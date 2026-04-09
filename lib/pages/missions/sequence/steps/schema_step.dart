import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';

class SchemaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onComplete;

  const SchemaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onComplete,
  });

  @override
  State<SchemaStep> createState() => _SchemaStepState();
}

class _SchemaStepState extends State<SchemaStep> {
  String? _selectedOption;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    // TODO: Charger depuis la progression sauvegardée
    setState(() {});
  }

  void _notifyDataChanged() {
    widget.onDataChanged({
      'schema_option': _selectedOption,
      'schema_comment': _commentController.text,
    });
  }

  void _handleComplete() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner Oui ou Non'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.timeline, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Schéma des installations électriques existantes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Question
          const Text(
            'Un schéma des installations électriques existantes a-t-il été fourni ?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          
          const SizedBox(height: 16),
          
          // Options Oui/Non
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Oui'),
                  value: 'oui',
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() => _selectedOption = value);
                    _notifyDataChanged();
                  },
                  activeColor: Colors.green,
                ),
                const Divider(height: 0),
                RadioListTile<String>(
                  title: const Text('Non'),
                  value: 'non',
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() => _selectedOption = value);
                    _notifyDataChanged();
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Commentaire (optionnel)
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Précisez si le schéma est disponible ou non...',
            ),
            maxLines: 3,
            onChanged: (_) => _notifyDataChanged(),
          ),
          
          const SizedBox(height: 32),
          
          // Indication sur le bouton "Terminer"
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Après avoir sélectionné votre réponse, cliquez sur "Terminer" pour finaliser la mission.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton Terminer
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'TERMINER LA MISSION',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}