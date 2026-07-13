// lib/pages/missions/sequence/steps/description_step.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/description_installations_sequence.dart';

class DescriptionStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onPreviousStep;
  final VoidCallback onNextStep;
  final VoidCallback? onSubStepChanged;

  const DescriptionStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
    required this.onPreviousStep,
    required this.onNextStep,
    this.onSubStepChanged,
  });

  @override
  State<DescriptionStep> createState() => DescriptionStepState();
}

class DescriptionStepState extends State<DescriptionStep> {
  final GlobalKey<DescriptionInstallationsSequenceScreenState> _subKey =
      GlobalKey<DescriptionInstallationsSequenceScreenState>();

  /// Appelé depuis le drawer pour aller directement à une section.
  void jumpToSection(int index) {
    _subKey.currentState?.jumpToSection(index);
    if (widget.onSubStepChanged != null) {
      widget.onSubStepChanged!();
    }
  }

  bool get isFirstSlide => _subKey.currentState?.isFirstSlide ?? true;
  bool get isLastSlide => _subKey.currentState?.isLastSlide ?? true;

  bool next() {
    return _subKey.currentState?.next() ?? false;
  }

  bool previous() {
    return _subKey.currentState?.previous() ?? false;
  }

  @override
  void initState() {
    super.initState();
    widget.onDataChanged({'description_active': true});
  }

  @override
  Widget build(BuildContext context) {
    return DescriptionInstallationsSequenceScreen(
      key: _subKey,
      mission: widget.mission,
      onPreviousStep: widget.onPreviousStep,
      onNextStep: widget.onNextStep,
      onSubStepChanged: widget.onSubStepChanged,
    );
  }
}