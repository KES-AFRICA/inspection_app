// lib/services/statistics/audit_finding.dart

import 'package:flutter/foundation.dart';

/// Modèle d'occurrence individuelle d'inventaire représentant une ligne non conforme constatée.
class AuditFinding {
  final String id;
  final String missionId;

  // Localisation & Contexte
  final String origin;           // "Local MT", "Local BT", "Zone MT", "Zone BT", "Groupe Électrogène", "Foudre"
  final String objectType;       // "Local MT", "Local BT", "Cellule MT", "Transformateur MT/BT", "Coffret", "Armoire", "TGBT", "Inverseur", "Foudre"
  final String objectName;       // Nom de l'équipement ou du local
  final String? objectRepere;    // Repère équipement ou numéro de série
  final String tableName;        // "Dispositions constructives", "Conditions d'exploitation", "Points de vérification", "Cellule audit", etc.

  // Constat & Normes
  final String verificationPoint;// Libellé du point de contrôle
  final String observationText;  // Description détaillée de la non-conformité
  final String conformity;       // "non", "non conforme", "false"
  final String criticality;      // "Critique", "Majeure", "Mineure", "Non spécifiée"
  final int? priority;           // Priorité d'intervention (1, 2, 3)
  final String? riskFamily;      // Famille de risque
  final String? normativeReference; // Référence normée
  final List<String> photos;

  AuditFinding({
    required this.id,
    required this.missionId,
    required this.origin,
    required this.objectType,
    required this.objectName,
    this.objectRepere,
    required this.tableName,
    required this.verificationPoint,
    required this.observationText,
    required this.conformity,
    required this.criticality,
    this.priority,
    this.riskFamily,
    this.normativeReference,
    List<String>? photos,
  }) : photos = photos ?? [];
}

/// Collection certifiée d'inventaire brut d'une mission.
class AuditFindingInventory {
  final String missionId;
  final List<AuditFinding> findings;

  AuditFindingInventory({
    required this.missionId,
    required this.findings,
  });

  int get totalFindings => findings.length;

  int get critiqueCount => findings.where((f) => f.criticality == 'Critique').length;
  int get majeureCount => findings.where((f) => f.criticality == 'Majeure').length;
  int get mineureCount => findings.where((f) => f.criticality == 'Mineure').length;
  int get unspecifiedCount => findings.where((f) => f.criticality != 'Critique' && f.criticality != 'Majeure' && f.criticality != 'Mineure').length;

  double get pctCritique => totalFindings > 0 ? (critiqueCount / totalFindings) * 100 : 0.0;
  double get pctMajeure => totalFindings > 0 ? (majeureCount / totalFindings) * 100 : 0.0;
  double get pctMineure => totalFindings > 0 ? (mineureCount / totalFindings) * 100 : 0.0;

  /// Affiche le diagnostic certifié d'inventaire dans la console système stdout (print).
  void printDiagnostic() {
    print('================================================================================');
    print('📊 INVENTAIRE EXHAUSTIF DES NON-CONFORMITÉS — MISSION: $missionId');
    print('================================================================================');
    print('🔍 Total des non-conformités recensées : $totalFindings');
    print('--------------------------------------------------------------------------------');
    print('🔴 CRITIQUE  : $critiqueCount (${pctCritique.toStringAsFixed(1)}%)');
    print('🟠 MAJEURE   : $majeureCount (${pctMajeure.toStringAsFixed(1)}%)');
    print('🔵 MINEURE   : $mineureCount (${pctMineure.toStringAsFixed(1)}%)');
    if (unspecifiedCount > 0) {
      print('⚪ AUTRES    : $unspecifiedCount (Observations sans criticité normée)');
    }
    print('================================================================================');
  }

  /// Imprime l'inventaire complet ligne par ligne dans la console système.
  void printFullInventoryDetails() {
    printDiagnostic();
    print('--- DÉTAIL LIGNE PAR LIGNE DES $totalFindings OCCURRENCES ---');
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      print('[#${i + 1}] [${f.criticality.toUpperCase()}] ${f.origin} > ${f.objectType} "${f.objectName}" > ${f.tableName} | Point: ${f.verificationPoint} | Constat: ${f.observationText}');
    }
    print('================================================================================');
  }
}
