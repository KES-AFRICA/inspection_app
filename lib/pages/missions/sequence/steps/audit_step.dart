import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/audit_installations.dart';

class AuditStep extends StatefulWidget {
  final Mission mission;
  final Function(Map<String, dynamic>) onDataChanged;

  const AuditStep({
    super.key,
    required this.mission,
    required this.onDataChanged,
  });

  @override
  State<AuditStep> createState() => _AuditStepState();
}

class _AuditStepState extends State<AuditStep> {
  @override
  void initState() {
    super.initState();
    // Notifier que l'étape est active (sans données spécifiques)
    widget.onDataChanged({'audit_active': true});
  }

  @override
  Widget build(BuildContext context) {
    return AuditInstallationsScreen(mission: widget.mission);
  }
}