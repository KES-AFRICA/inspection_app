// lib/pages/missions/sequence/steps/jsa_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';

class JsaStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const JsaStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<JsaStep> createState() => _JsaStepState();
}

class _JsaStepState extends State<JsaStep> {
  @override
  void initState() {
    super.initState();
    // Initialiser les données vides
    widget.onDataChanged({});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message informatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La section JSA (Job Safety Analysis) sera disponible dans une prochaine version.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          
          ],
        ),
      ),
    );
  }
}