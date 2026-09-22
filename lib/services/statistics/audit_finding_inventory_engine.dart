// lib/services/statistics/audit_finding_inventory_engine.dart

import 'audit_finding.dart';
import 'mission_domain_inventory_engine.dart';

/// Moteur de Recensement et d'Inventaire Unifié des Non-Conformités (`AuditFindingInventoryEngine`).
/// 
/// Responsabilité Unique : Déléguer à `MissionDomainInventoryEngine` pour garantir
/// une SOURCE UNIQUE DE VÉRITÉ absolue entre l'inventaire physique et les non-conformités.
class AuditFindingInventoryEngine {
  /// Génère l'inventaire brut exhaustif pour une mission donnée.
  static AuditFindingInventory buildInventory(String missionId) {
    final domainInventory = MissionDomainInventoryEngine.buildInventory(missionId);

    return AuditFindingInventory(
      missionId: missionId,
      findings: domainInventory.allFindings,
      crossCategoryItems: domainInventory.getCrossCategoryAnalysis(),
    );
  }
}
