// lib/pages/missions/sequence/steps/description_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/description_installations_sequence.dart';

class DescriptionStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onPreviousStep;
  final VoidCallback onNextStep;

  const DescriptionStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onPreviousStep,
    required this.onNextStep,
  });

  @override
  State<DescriptionStep> createState() => _DescriptionStepState();
}

class _DescriptionStepState extends State<DescriptionStep> {
  @override
  void initState() {
    super.initState();
    widget.onDataChanged({'description_active': true});
  }

  @override
  Widget build(BuildContext context) {
    return DescriptionInstallationsSequenceScreen(
      mission: widget.mission,
      onPreviousStep: widget.onPreviousStep,
      onNextStep: widget.onNextStep,
    );
  }
}