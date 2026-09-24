/// Service central et déterministe gérant l'intégrité métier lors d'un changement
/// de type de local (MoyenneTensionLocal ou BasseTensionLocal).
///
/// Règles fondamentales :
/// - Zéro perte de données : les données communes (id, nom, coffrets, photos,
///   observations, accessibilité) sont toujours préservées.
/// - Identité stable : l'id du local NE CHANGE PAS lors d'une transition.
/// - Checklists adaptées : les dispositions et conditions sont normalisées vers
///   le jeu du type cible, en préservant les réponses existantes quand les points
///   existent dans les deux jeux (logique de merge via ensureComplete*).
/// - Cellules / Transformateurs : conservés lors des transitions intra-LONG
///   (LOCAL_TRANSFORMATEUR <-> LOCAL_MTBT), initialisés à [] sinon.
///
/// Transitions supportées :
/// Famille 1 — INTRA-CLASSE (même classe Dart) :
///   LOCAL_TRANSFORMATEUR <-> LOCAL_MTBT         (MoyenneTensionLocal)
///   LOCAL_TGBT <-> LOCAL_ONDULEUR <-> LOCAL_GROUPE_ELECTROGENE ...
///   LOCAL_TGBT -> LOCAL_MTBT (BT zone, flow standard -> long)
/// Famille 2 — INTER-CLASSE (MoyenneTensionLocal <-> BasseTensionLocal) :
///   HORS PERIMETRE — non supportée (implique un déplacement physique dans
///   deux listes Hive distinctes et une logique de zone).
library;

import '../models/audit_installations_electriques.dart';
import 'dispositions_constructives_registry.dart';
import 'hive_service.dart';

/// Famille de transition selon les types source et cible.
enum LocalTransitionFamily {
  /// Même classe Dart, même sémantique de checklist (MT <-> MT ou BT-standard <-> BT-standard).
  intraClassSameFamily,

  /// Même classe Dart, checklists différentes (ex. BT-standard -> BT-long, ou
  /// LOCAL_GROUPE_ELECTROGENE <-> LOCAL_TGBT).
  intraClassDifferentFamily,

  /// Inter-classe (MoyenneTensionLocal <-> BasseTensionLocal) — hors périmètre.
  interClass,
}

/// Résultat d'une opération de transition.
class LocalTransitionResult {
  /// Indique si la transition a réussi.
  final bool success;

  /// Message d'erreur si la transition a échoué.
  final String? errorMessage;

  /// Avertissements non bloquants (ex. cellules perdues lors d'un passage LONG -> standard).
  final List<String> warnings;

  const LocalTransitionResult._({
    required this.success,
    this.errorMessage,
    this.warnings = const [],
  });

  factory LocalTransitionResult.success({List<String> warnings = const []}) =>
      LocalTransitionResult._(success: true, warnings: warnings);

  factory LocalTransitionResult.failure(String message) =>
      LocalTransitionResult._(success: false, errorMessage: message);
}

class LocalTypeTransitionService {
  // ---------------------------------------------------------------------------
  // CLASSIFICATION DES TYPES
  // ---------------------------------------------------------------------------

  /// Types associés au flow long (cellules + transformateurs requis).
  static const Set<String> _longFlowTypes = {
    'LOCAL_TRANSFORMATEUR',
    'LOCAL_MTBT',
  };

  /// Types dont la checklist normative est celle de la Moyenne Tension.
  static const Set<String> _mtChecklistTypes = {
    'LOCAL_TRANSFORMATEUR',
    'LOCAL_MTBT',
  };

  /// Retourne true si le type implique le flow long (cellules + transformateurs).
  static bool isLongFlow(String type) => _longFlowTypes.contains(type);

  /// Retourne true si le type utilise la checklist MT (LOCAL_TRANSFORMATEUR ou LOCAL_MTBT).
  static bool isMTChecklistType(String type) => _mtChecklistTypes.contains(type);

  // ---------------------------------------------------------------------------
  // ANALYSE DE TRANSITION
  // ---------------------------------------------------------------------------

  /// Détermine la famille de transition entre [sourceType] et [targetType],
  /// pour un local dans un contexte [isMoyenneTension].
  static LocalTransitionFamily classifyTransition({
    required String sourceType,
    required String targetType,
    required bool isMoyenneTension,
  }) {
    if (sourceType == targetType) return LocalTransitionFamily.intraClassSameFamily;

    // LOCAL_TRANSFORMATEUR et LOCAL_MTBT sont les deux seuls types MT
    // Un local MT ne peut pas aller vers un type BT pur via ce service
    if (isMoyenneTension) {
      // Dans une zone MT, les deux types sont MT => intra-classe, même famille MT
      return LocalTransitionFamily.intraClassSameFamily;
    }

    // Dans une zone BT
    final sourceBtFamily = _btChecklistFamily(sourceType);
    final targetBtFamily = _btChecklistFamily(targetType);
    if (sourceBtFamily == targetBtFamily) {
      return LocalTransitionFamily.intraClassSameFamily;
    }
    return LocalTransitionFamily.intraClassDifferentFamily;
  }

  /// Famille de checklists BT. Retourne : 'GE' | 'LONG' | 'STANDARD'.
  static String _btChecklistFamily(String type) {
    if (type == 'LOCAL_GROUPE_ELECTROGENE') return 'GE';
    if (type == 'LOCAL_MTBT') return 'LONG';
    return 'STANDARD';
  }

  // ---------------------------------------------------------------------------
  // TRANSITION — MoyenneTensionLocal
  // ---------------------------------------------------------------------------

  /// Applique un changement de type sur [local] (MoyenneTensionLocal).
  ///
  /// Comportement garanti :
  /// - id, nom, coffrets, photos, observations, accessible, aReverifier, isRiskZone : intacts.
  /// - Checklists normalisées pour le nouveau type (même jeu MT pour les deux types MT).
  /// - Cellules et transformateurs : toujours conservés (les deux types MT les utilisent).
  static LocalTransitionResult transitionMTLocal({
    required MoyenneTensionLocal local,
    required String newType,
  }) {
    if (local.type == newType) return LocalTransitionResult.success();

    local.type = newType;
    local.updatedAt = DateTime.now().toUtc();

    // LOCAL_TRANSFORMATEUR et LOCAL_MTBT partagent la même checklist MT.
    // On normalise : les réponses existantes sur les points communs sont préservées.
    DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
      dispositionsConstructives: local.dispositionsConstructives,
      conditionsExploitation: local.conditionsExploitation,
    );

    return LocalTransitionResult.success();
  }

  // ---------------------------------------------------------------------------
  // TRANSITION — BasseTensionLocal
  // ---------------------------------------------------------------------------

  /// Applique un changement de type sur [local] (BasseTensionLocal).
  ///
  /// Comportement garanti :
  /// - id, nom, coffrets, photos, observations, accessible, aReverifier, isRiskZone : intacts.
  /// - Checklists normalisées pour le nouveau type.
  /// - Cellules/transformateurs :
  ///     standard -> LONG : initialisés à [] (le local n'en avait pas).
  ///     LONG -> standard : vidés avec avertissement si non vides.
  ///     LONG -> LONG ou standard -> standard : inchangés.
  static LocalTransitionResult transitionBTLocal({
    required BasseTensionLocal local,
    required String newType,
  }) {
    if (local.type == newType) return LocalTransitionResult.success();

    final oldType = local.type;
    final warnings = <String>[];
    final oldIsLong = isLongFlow(oldType);
    final newIsLong = isLongFlow(newType);

    local.type = newType;
    local.updatedAt = DateTime.now().toUtc();

    // Gestion des cellules et transformateurs
    if (!oldIsLong && newIsLong) {
      // standard -> long : initialiser (le local n'en avait structurellement pas)
      local.cellules = [];
      local.transformateurs = [];
    } else if (oldIsLong && !newIsLong) {
      // long -> standard : vider (incompatible structurellement)
      final nbCellules = local.cellules.length;
      final nbTransfos = local.transformateurs.length;
      if (nbCellules > 0 || nbTransfos > 0) {
        warnings.add(
          'Le passage de "${_labelForType(oldType)}" vers "${_labelForType(newType)}" '
          'a supprimé $nbCellules cellule(s) et $nbTransfos transformateur(s) '
          'incompatibles avec ce type de local.',
        );
      }
      local.cellules = [];
      local.transformateurs = [];
    }
    // long -> long ou standard -> standard : aucun changement sur cellules/transfo

    // Normalisation des checklists selon la famille du nouveau type
    _applyChecklistsForBTType(
      dispositionsConstructives: local.dispositionsConstructives ?? [],
      conditionsExploitation: local.conditionsExploitation ?? [],
      newType: newType,
    );

    return LocalTransitionResult.success(warnings: warnings);
  }

  // ---------------------------------------------------------------------------
  // INITIALISATION (création d'un nouveau local, pas édition)
  // ---------------------------------------------------------------------------

  /// Initialise les checklists d'un NOUVEAU local MT (type non renseigné).
  /// Tous les points sont créés en état "Sans objet" (estNA = true, conforme = null).
  static void initChecklistsForNewMTLocal({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
    required String type,
  }) {
    _buildFreshChecklists(
      dispositionsConstructives: dispositionsConstructives,
      conditionsExploitation: conditionsExploitation,
      dispTitles: HiveService.getDispositionsConstructivesForLocal(type),
      condTitles: HiveService.getConditionsExploitationForLocal(type),
    );
  }

  /// Initialise les checklists d'un NOUVEAU local BT (type non renseigné).
  /// Tous les points sont créés en état "Sans objet" (estNA = true, conforme = null).
  static void initChecklistsForNewBTLocal({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
    required String type,
  }) {
    _buildFreshChecklists(
      dispositionsConstructives: dispositionsConstructives,
      conditionsExploitation: conditionsExploitation,
      dispTitles: HiveService.getDispositionsConstructivesForLocal(type),
      condTitles: HiveService.getConditionsExploitationForLocal(type),
    );
  }

  // ---------------------------------------------------------------------------
  // UTILITAIRES PRIVÉS
  // ---------------------------------------------------------------------------

  static void _applyChecklistsForBTType({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
    required String newType,
  }) {
    switch (_btChecklistFamily(newType)) {
      case 'GE':
        DispositionsConstructivesRegistry.ensureCompleteGELocalChecklists(
          dispositionsConstructives: dispositionsConstructives,
          conditionsExploitation: conditionsExploitation,
        );
        break;
      case 'LONG':
        // LOCAL_MTBT dans une zone BT utilise la checklist MT
        DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
          dispositionsConstructives: dispositionsConstructives,
          conditionsExploitation: conditionsExploitation,
        );
        break;
      default:
        DispositionsConstructivesRegistry.ensureCompleteBTLocalChecklists(
          dispositionsConstructives: dispositionsConstructives,
          conditionsExploitation: conditionsExploitation,
        );
        break;
    }
  }

  static void _buildFreshChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
    required List<String> dispTitles,
    required List<String> condTitles,
  }) {
    dispositionsConstructives.clear();
    conditionsExploitation.clear();

    for (final title in dispTitles) {
      dispositionsConstructives.add(ElementControle(
        elementControle: title,
        conforme: null,
        estNA: true,
        priorite: 3,
      ));
    }
    for (final title in condTitles) {
      conditionsExploitation.add(ElementControle(
        elementControle: title,
        conforme: null,
        estNA: true,
        priorite: 3,
      ));
    }
  }

  static String _labelForType(String type) =>
      HiveService.getLocalTypes()[type] ?? type;
}
