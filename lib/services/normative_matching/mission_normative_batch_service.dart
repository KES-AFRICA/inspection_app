import '../../models/audit_installations_electriques.dart';
import 'normative_matching_engine.dart';
import 'normative_matching_result.dart';

/// Service d'analyse et de rapprochement automatique par lots (batch) sur toute une mission d'audit
class MissionNormativeBatchService {
  /// Exécute l'analyse et applique le rattachement automatique sur un audit complet
  static MissionNormativeBatchReport processAudit(AuditInstallationsElectriques audit) {
    int totalAnalysed = 0;
    int autoLinkedCount = 0;
    int ambiguousCount = 0;
    int uncertainCount = 0;
    int alreadyLinkedCount = 0;

    final List<NormativeMatchAnalysis> analyses = [];
    final List<ObservationLibre> allObservations = _extractAllFreeObservations(audit);

    for (final obs in allObservations) {
      if (obs.hasNormativeReference && !obs.isAutoLinked) {
        alreadyLinkedCount++;
        continue;
      }

      totalAnalysed++;
      final analysis = NormativeMatchingEngine.analyze(obs);
      analyses.add(analysis);

      switch (analysis.status) {
        case MatchingConfidenceLevel.certain:
          if (analysis.bestMatch != null) {
            final match = analysis.bestMatch!;
            obs.linkToNormativePoint(
              key: match.key,
              refNormative: match.referenceNormative,
              famille: match.familleRisque,
              crit: match.criticite,
              auto: true,
            );
            autoLinkedCount++;
          }
          break;
        case MatchingConfidenceLevel.ambiguous:
          ambiguousCount++;
          break;
        case MatchingConfidenceLevel.uncertain:
          uncertainCount++;
          break;
      }
    }

    if (autoLinkedCount > 0) {
      audit.updatedAt = DateTime.now();
    }

    return MissionNormativeBatchReport(
      totalObservationsAnalysed: totalAnalysed,
      autoLinkedCount: autoLinkedCount,
      ambiguousCount: ambiguousCount,
      uncertainCount: uncertainCount,
      alreadyLinkedCount: alreadyLinkedCount,
      analyses: analyses,
    );
  }

  /// Extrait toutes les observations libres présentes dans les 9 emplacements de l'audit
  static List<ObservationLibre> _extractAllFreeObservations(AuditInstallationsElectriques audit) {
    final List<ObservationLibre> list = [];

    // 1. Locaux Moyenne Tension
    for (final local in audit.moyenneTensionLocaux) {
      list.addAll(local.observationsLibres);

      // Cellules dans ce local
      for (final cel in local.cellules) {
        if (cel.observations != null) {
          for (final el in cel.observations!) {
            if (el.observation != null && el.observation!.trim().isNotEmpty) {
              list.add(ObservationLibre(
                texte: el.observation!,
                referenceNormative: el.referenceNormative,
                familleRisque: el.familleRisque,
                criticite: el.criticite,
              ));
            }
          }
        }
      }

      // Transformateurs dans ce local
      for (final trans in local.transformateurs) {
        if (trans.observations != null) {
          for (final el in trans.observations!) {
            if (el.observation != null && el.observation!.trim().isNotEmpty) {
              list.add(ObservationLibre(
                texte: el.observation!,
                referenceNormative: el.referenceNormative,
                familleRisque: el.familleRisque,
                criticite: el.criticite,
              ));
            }
          }
        }
      }

      // Coffrets dans ce local MT
      for (final coffret in local.coffrets) {
        list.addAll(coffret.observationsLibres);
        list.addAll(coffret.observationsParafoudre);
      }
    }

    // 2. Zones Moyenne Tension
    for (final zone in audit.moyenneTensionZones) {
      list.addAll(zone.observationsLibres);
    }

    // 3. Zones Basse Tension
    for (final zone in audit.basseTensionZones) {
      list.addAll(zone.observationsLibres);

      // Coffrets directs dans cette zone BT
      for (final coffret in zone.coffretsDirects) {
        list.addAll(coffret.observationsLibres);
        list.addAll(coffret.observationsParafoudre);
      }

      // Locaux BT dans cette zone
      for (final local in zone.locaux) {
        list.addAll(local.observationsLibres);
        for (final coffret in local.coffrets) {
          list.addAll(coffret.observationsLibres);
          list.addAll(coffret.observationsParafoudre);
        }
      }
    }

    return list;
  }
}
