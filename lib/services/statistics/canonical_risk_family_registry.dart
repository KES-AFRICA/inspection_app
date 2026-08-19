/// Registre centralisé pour la classification et le regroupement canonique des familles de risques.
class CanonicalRiskFamilyRegistry {
  static const String erreurExploitation = 'Erreur d\'exploitation / maintenance';
  static const String electrissationElectrocution = 'Électrisation / électrocution';
  static const String degradationCanalisations = 'Dégradation des canalisations et matériels';
  static const String surintensiteCourtCircuit = 'Surintensité / court-circuit';
  static const String echauffementSurcharge = 'Échauffement / surcharge / risque d\'incendie';

  static const List<String> canonicalFamilies = [
    erreurExploitation,
    electrissationElectrocution,
    degradationCanalisations,
    surintensiteCourtCircuit,
    echauffementSurcharge,
  ];

  static const Map<String, String> defaultObservations = {
    erreurExploitation:
        'Manque d\'identification des circuits, repérage insuffisant et absence de schémas unifilaires à jour.',
    electrissationElectrocution:
        'Défauts d\'interconnexion à la terre, continuités PE interrompues et protections différentielles défaillantes.',
    degradationCanalisations:
        'Câblages détériorés, cheminements non protégés mécaniquement et connexions directes non sécurisées.',
    surintensiteCourtCircuit:
        'Inadéquation des calibres de protection vis-à-vis des sections de conducteurs et des répartiteurs.',
    echauffementSurcharge:
        'Mauvaise répartition de charge, serrages défectueux et utilisation inadaptée des répartiteurs.',
  };

  /// Vérifie si une non-conformité possède une famille de risque ou un point de contrôle valide.
  static bool hasValidRiskFamily(String? rawRisk, {String? verificationPoint}) {
    final riskStr = (rawRisk ?? '').trim();
    if (riskStr.isNotEmpty &&
        riskStr.toLowerCase() != 'non spécifiée' &&
        riskStr.toLowerCase() != 'non specifiee' &&
        riskStr.toLowerCase() != 'indéterminée') {
      return true;
    }
    final pointStr = (verificationPoint ?? '').trim();
    if (pointStr.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Mappe n'importe quel libellé brut de risque ou point de contrôle vers l'une des 5 familles canoniques.
  static String mapToCanonical(String? rawRisk, {String? verificationPoint}) {
    final riskStr = (rawRisk ?? '').trim().toLowerCase();
    final pointStr = (verificationPoint ?? '').trim().toLowerCase();
    final combined = '$riskStr $pointStr';

    if (combined.isEmpty) {
      return erreurExploitation;
    }

    // 1. Électrisation / électrocution
    if (combined.contains('électrocution') ||
        combined.contains('electrocution') ||
        combined.contains('électrisation') ||
        combined.contains('electrisation') ||
        combined.contains('contact direct') ||
        combined.contains('contact indirect') ||
        combined.contains('mise à la terre') ||
        combined.contains('prise de terre') ||
        combined.contains('équipotentiel') ||
        combined.contains('différentiel') ||
        combined.contains('pe ') ||
        combined.contains('isolement') ||
        combined.contains('arc électrique')) {
      return electrissationElectrocution;
    }

    // 2. Dégradation des canalisations / échauffement / court-circuit
    if (combined.contains('canalisation') ||
        combined.contains('cheminement') ||
        combined.contains('câblage') ||
        combined.contains('cables') ||
        combined.contains('câble') ||
        combined.contains('protection mécanique') ||
        combined.contains('détérioré') ||
        combined.contains('gaine') ||
        combined.contains('passage de câble') ||
        combined.contains('passage des cables')) {
      return degradationCanalisations;
    }

    // 3. Surintensité / court-circuit / incendie
    if (combined.contains('surintensité') ||
        combined.contains('calibre') ||
        combined.contains('pouvoir de coupure') ||
        combined.contains('section') ||
        combined.contains('inadéquation') ||
        combined.contains('disjoncteur') ||
        combined.contains('fusible')) {
      return surintensiteCourtCircuit;
    }

    // 4. Échauffement / surcharge / incendie
    if (combined.contains('échauffement') ||
        combined.contains('echauffement') ||
        combined.contains('surcharge') ||
        combined.contains('serrage') ||
        combined.contains('répartiteur') ||
        combined.contains('thermo') ||
        combined.contains('thermique') ||
        combined.contains('incendie') ||
        combined.contains('explosion') ||
        combined.contains('brûlure')) {
      return echauffementSurcharge;
    }

    // 5. Erreur d'exploitation / maintenance (Fallback par défaut pour signalisation, schéma, propreté, etc.)
    return erreurExploitation;
  }
}
