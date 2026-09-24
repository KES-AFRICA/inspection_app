// lib/services/intervenants_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Service centralisé assurant que la JSA est la Source de Vérité Unique (SSOT)
/// pour l'ensemble des intervenants / inspecteurs d'une mission.
/// 
/// Garantit :
/// - Enrôlement automatique et idempotent de l'utilisateur courant.
/// - Préservation intégrale des inspecteurs lors des cycles export / import.
/// - Migration transparente et non destructive des missions historiques (legacy).
/// - Synchronisation unidirectionnelle JSA -> mission.verificateurs / rg.verificateurs
///   pour rétrocompatibilité totale avec les composants d'interface existants.
class IntervenantsService {
  /// S'assure que l'utilisateur courant (ou les données transmises en repli)
  /// est inscrit dans la JSA de la mission de façon strictement idempotente.
  static Future<void> ensureCurrentUserInJSA(
    String missionId, {
    String? fallbackMatricule,
    String? fallbackNom,
    String? fallbackPrenom,
  }) async {
    try {
      if (missionId.trim().isEmpty) return;

      final currentUser = HiveService.getCurrentUser();
      String nom = currentUser?.nom.trim() ?? '';
      String prenom = currentUser?.prenom.trim() ?? '';
      String? matricule = currentUser?.matricule.trim();
      String? email = currentUser?.email.trim();
      String role = 'Inspecteur';

      if (nom.isEmpty && fallbackNom != null) {
        nom = fallbackNom.trim();
      }
      if (prenom.isEmpty && fallbackPrenom != null) {
        prenom = fallbackPrenom.trim();
      }
      if ((matricule == null || matricule.isEmpty) && fallbackMatricule != null) {
        matricule = fallbackMatricule.trim();
      }

      // Si aucune identité n'est disponible, rien à enrôler
      if (nom.isEmpty && prenom.isEmpty && (matricule == null || matricule.isEmpty)) {
        return;
      }

      // 1. Récupérer ou initialiser la JSA
      var jsa = HiveService.getJSAByMissionId(missionId);
      bool isNewJsa = false;
      if (jsa == null) {
        jsa = await HiveService.getOrCreateJSA(missionId);
        isNewJsa = true;
      }

      bool jsaModified = false;

      // 2. Migration automatique à chaud des missions historiques si la JSA est vierge
      if (jsa.inspecteurs.isEmpty) {
        final mission = HiveService.getMissionById(missionId);
        final rg = HiveService.getRenseignementsGenerauxByMissionId(missionId);
        final migratedCount = syncLegacyInspectorsToJSA(jsa, mission, rg);
        if (migratedCount > 0) {
          jsaModified = true;
        }
      }

      // 3. Enrôler l'utilisateur courant s'il est absent (idempotent)
      final added = JSAUtils.addInspectorIfAbsent(
        jsa.inspecteurs,
        nom,
        prenom,
        matricule: matricule,
        email: email,
        role: role,
      );

      if (added || isNewJsa || jsaModified) {
        await HiveService.saveJSA(jsa);
      }

      // 4. Maintien de la cohérence pour les composants legacy
      await _syncLegacyFieldsWithJsa(missionId, jsa.inspecteurs);
    } catch (e, st) {
      if (kDebugMode) {
        print('⚠️ IntervenantsService.ensureCurrentUserInJSA error: $e\n$st');
      }
    }
  }

  /// Récupère la liste des intervenants JSA pour une mission.
  /// Si la JSA est vide ou absente, résout automatiquement depuis les sources
  /// historiques ou l'utilisateur connecté sans altérer les données.
  static List<JSAInspecteur> getMissionIntervenants(
    String missionId, {
    Mission? mission,
    RenseignementsGeneraux? rg,
    JSA? jsa,
  }) {
    // 1. Vérifier la JSA fournie ou en cache Hive
    final effectiveJsa = jsa ?? HiveService.getJSAByMissionId(missionId);
    if (effectiveJsa != null && effectiveJsa.inspecteurs.isNotEmpty) {
      return List<JSAInspecteur>.from(effectiveJsa.inspecteurs);
    }

    // 2. Fallback de migration à chaud pour anciennes missions
    final effectiveMission = mission ?? HiveService.getMissionById(missionId);
    final effectiveRg = rg ?? HiveService.getRenseignementsGenerauxByMissionId(missionId);
    final fallbackList = <JSAInspecteur>[];

    // Depuis mission.verificateurs
    if (effectiveMission?.verificateurs != null && effectiveMission!.verificateurs!.isNotEmpty) {
      for (final v in effectiveMission.verificateurs!) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vMatricule = (v['matricule'] ?? '').toString().trim();
        final vRole = (v['role'] ?? 'Inspecteur').toString().trim();
        JSAUtils.addInspectorIfAbsent(
          fallbackList,
          vNom,
          vPrenom,
          matricule: vMatricule.isNotEmpty ? vMatricule : null,
          role: vRole.isNotEmpty ? vRole : null,
        );
      }
    }

    // Depuis rg.verificateurs
    if (effectiveRg != null && effectiveRg.verificateurs.isNotEmpty) {
      for (final v in effectiveRg.verificateurs) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vFonction = (v['fonction'] ?? 'Inspecteur').toString().trim();
        JSAUtils.addInspectorIfAbsent(
          fallbackList,
          vNom,
          vPrenom,
          role: vFonction.isNotEmpty ? vFonction : null,
        );
      }
    }

    // Depuis l'utilisateur courant si toujours vide
    if (fallbackList.isEmpty) {
      final currentUser = HiveService.getCurrentUser();
      if (currentUser != null && (currentUser.nom.isNotEmpty || currentUser.prenom.isNotEmpty)) {
        fallbackList.add(JSAInspecteur(
          nom: currentUser.nom.trim(),
          prenom: currentUser.prenom.trim(),
          matricule: currentUser.matricule.trim().isNotEmpty ? currentUser.matricule.trim() : null,
          email: currentUser.email.trim().isNotEmpty ? currentUser.email.trim() : null,
          role: 'Inspecteur',
        ));
      }
    }

    return fallbackList;
  }

  /// Retourne la liste des noms formatés des intervenants pour les rapports
  /// (ex: `['JEAN DUPONT', 'PIERRE MARTIN']`).
  static List<String> getMissionIntervenantsNoms(
    String missionId, {
    Mission? mission,
    RenseignementsGeneraux? rg,
    JSA? jsa,
    bool uppercase = true,
  }) {
    final intervenants = getMissionIntervenants(
      missionId,
      mission: mission,
      rg: rg,
      jsa: jsa,
    );

    final noms = <String>[];
    for (final insp in intervenants) {
      final fullName = '${insp.prenom} ${insp.nom}'.trim();
      if (fullName.isNotEmpty) {
        final formatted = uppercase ? fullName.toUpperCase() : fullName;
        if (!noms.contains(formatted)) {
          noms.add(formatted);
        }
      }
    }

    if (noms.isEmpty) {
      return ['Non spécifié'];
    }
    return noms;
  }

  /// Migre les intervenants legacy depuis `mission.verificateurs` et `rg.verificateurs`
  /// vers la JSA sans créer de doublon. Retourne le nombre d'inspecteurs ajoutés.
  static int syncLegacyInspectorsToJSA(
    JSA jsa,
    Mission? mission,
    RenseignementsGeneraux? rg,
  ) {
    int addedCount = 0;

    // A. Depuis mission.verificateurs
    if (mission?.verificateurs != null && mission!.verificateurs!.isNotEmpty) {
      for (final v in mission.verificateurs!) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vMatricule = (v['matricule'] ?? '').toString().trim();
        final vRole = (v['role'] ?? '').toString().trim();
        final added = JSAUtils.addInspectorIfAbsent(
          jsa.inspecteurs,
          vNom,
          vPrenom,
          matricule: vMatricule.isNotEmpty ? vMatricule : null,
          role: vRole.isNotEmpty ? vRole : null,
        );
        if (added) addedCount++;
      }
    }

    // B. Depuis rg.verificateurs
    if (rg != null && rg.verificateurs.isNotEmpty) {
      for (final v in rg.verificateurs) {
        final vNom = (v['nom'] ?? '').toString().trim();
        final vPrenom = (v['prenom'] ?? '').toString().trim();
        final vFonction = (v['fonction'] ?? '').toString().trim();
        final added = JSAUtils.addInspectorIfAbsent(
          jsa.inspecteurs,
          vNom,
          vPrenom,
          role: vFonction.isNotEmpty ? vFonction : null,
        );
        if (added) addedCount++;
      }
    }

    return addedCount;
  }

  /// Synchronise en tâche de fond `mission.verificateurs` et `rg.verificateurs`
  /// à partir de la liste des inspecteurs JSA pour assurer la rétrocompatibilité.
  static Future<void> _syncLegacyFieldsWithJsa(
    String missionId,
    List<JSAInspecteur> inspecteurs,
  ) async {
    try {
      final syncList = inspecteurs.map((i) => {
        'nom': i.nom,
        'prenom': i.prenom,
        'matricule': i.matricule ?? '',
        'role': i.role ?? 'Inspecteur',
        'email': i.email ?? '',
      }).toList();

      // Synchroniser Mission
      if (Hive.isBoxOpen('missions')) {
        final missionBox = Hive.box<Mission>('missions');
        final mission = missionBox.get(missionId);
        if (mission != null) {
          mission.verificateurs = syncList;
          await mission.save();
        }
      }

      // Synchroniser RenseignementsGeneraux
      if (Hive.isBoxOpen('renseignements_generaux')) {
        final rgBox = Hive.box<RenseignementsGeneraux>('renseignements_generaux');
        final rg = rgBox.values.cast<RenseignementsGeneraux?>().firstWhere(
          (r) => r?.missionId == missionId,
          orElse: () => null,
        );
        if (rg != null) {
          rg.verificateurs = syncList;
          await rg.save();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ _syncLegacyFieldsWithJsa silent error: $e');
      }
    }
  }
}
