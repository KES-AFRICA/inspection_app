import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import '../models/verificateur.dart';
import '../models/mission.dart';
import '../models/renseignements_generaux.dart';

class HiveService {
  static const String _verificateurBox = 'verificateurs';
  static const String _missionBox = 'missions';
  static const String _currentUserKey = 'current_user';
  static const String _descriptionBox = 'description_installations';
  static const String _auditBox = 'audit_installations_electriques';
  static const String _classementBox = 'classement_locaux';
  static const String _foudreBox = 'foudre_observations';
  static const String _mesuresEssaisBox = 'mesures_essais';
  static const String _jsaBox = 'jsa';
  static const String _coffretDraftsBox = 'coffret_drafts';

  // Initialiser Hive
  static Future<void> init() async {
    await Hive.initFlutter();

  Hive.registerAdapter(VerificateurAdapter());
  Hive.registerAdapter(MissionAdapter());
  Hive.registerAdapter(DescriptionInstallationsAdapter());
  Hive.registerAdapter(AuditInstallationsElectriquesAdapter());
  Hive.registerAdapter(MoyenneTensionLocalAdapter());
  Hive.registerAdapter(MoyenneTensionZoneAdapter());
  Hive.registerAdapter(BasseTensionZoneAdapter());
  Hive.registerAdapter(BasseTensionLocalAdapter());
  Hive.registerAdapter(ElementControleAdapter());
  Hive.registerAdapter(CelluleAdapter());
  Hive.registerAdapter(TransformateurMTBTAdapter());
  Hive.registerAdapter(CoffretArmoireAdapter());
  Hive.registerAdapter(AlimentationAdapter());
  Hive.registerAdapter(PointVerificationAdapter());
  Hive.registerAdapter(ClassementEmplacementAdapter());
  Hive.registerAdapter(FoudreAdapter()); 
  Hive.registerAdapter(MesuresEssaisAdapter());
  Hive.registerAdapter(ConditionMesureAdapter());
  Hive.registerAdapter(EssaiDemarrageAutoAdapter());
  Hive.registerAdapter(TestArretUrgenceAdapter());
  Hive.registerAdapter(PriseTerreAdapter());
  Hive.registerAdapter(AvisMesuresTerreAdapter());
  Hive.registerAdapter(EssaiDeclenchementDifferentielAdapter());
  Hive.registerAdapter(ContinuiteResistanceAdapter());
  Hive.registerAdapter(ObservationLibreAdapter());
  Hive.registerAdapter(InstallationItemAdapter()); 
  Hive.registerAdapter(RenseignementsGenerauxAdapter());
  Hive.registerAdapter(JSAAdapter());
  Hive.registerAdapter(JSAInspecteurAdapter());
  Hive.registerAdapter(JSAPlanUrgenceAdapter());
  Hive.registerAdapter(JSADangersAdapter());
  Hive.registerAdapter(JSAExigencesGeneralesAdapter());
  Hive.registerAdapter(JSAEPIAdapter());
  Hive.registerAdapter(JSAVerificationFinaleAdapter());
  

    // Ouvrir les boxes
    await Hive.openBox<Verificateur>(_verificateurBox);
    await Hive.openBox<Mission>(_missionBox);
    await Hive.openBox<DescriptionInstallations>(_descriptionBox); 
    await Hive.openBox<AuditInstallationsElectriques>(_auditBox);
    await Hive.openBox<ClassementEmplacement>(_classementBox);
    await Hive.openBox<Foudre>(_foudreBox); 
    await Hive.openBox<MesuresEssais>(_mesuresEssaisBox);
    await Hive.openBox(_currentUserKey);
    await Hive.openBox<RenseignementsGeneraux>(_renseignementsGenerauxBox);
    await Hive.openBox<JSA>(_jsaBox);
    await Hive.openBox<Map>(_coffretDraftsBox);
  
  }

  // ============================================================
  //                      GESTION UTILISATEUR
  // ============================================================

  /// Sauvegarder l'utilisateur (clé = email)
  static Future<void> saveCurrentUser(Verificateur user) async {
    final box = Hive.box<Verificateur>(_verificateurBox);
    await box.put(user.email.toLowerCase(), user);  // Clé = email en minuscule

    final currentBox = Hive.box(_currentUserKey);
    await currentBox.put('email', user.email.toLowerCase());
    await currentBox.put('isLoggedIn', true);
  }

  /// Vérifier si un matricule existe déjà
  static bool matriculeExists(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.any((user) => user.matricule.toUpperCase() == matricule.toUpperCase());
    } catch (e) {
      return false;
    }
  }

  /// Récupérer l’utilisateur ACTUELLEMENT connecté
  static Verificateur? getCurrentUser() {
    try {
      final currentBox = Hive.box(_currentUserKey);
      final email = currentBox.get('email');
      final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);

      if (email == null || !isLoggedIn) return null;

      final box = Hive.box<Verificateur>(_verificateurBox);
      final user = box.get(email);

      if (user == null) {
        currentBox.delete('email');
        currentBox.delete('isLoggedIn');
      }

      return user;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  /// Vérifier si un email existe déjà
  static bool emailExists(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.containsKey(email.toLowerCase());
  }

  static Verificateur? getUserByEmail(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.get(email);
  }

  /// Vérifier si un utilisateur existe (par email)
  static bool userExists(String email) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.containsKey(email);
  }

  /// Vérifier les identifiants (email + password)
  static Verificateur? authenticateUser(String email, String password) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    final user = box.get(email.toLowerCase());
    
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  //liste de tous les verificateurs
  static List<Verificateur> getAllVerificateurs() {
    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.values.toList();
  }

  /// Récupérer un utilisateur par son matricule
  static Verificateur? getUserByMatricule(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.firstWhere(
        (user) => user.matricule.toUpperCase() == matricule.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un utilisateur est connecté
  static bool isUserLoggedIn() {
    final currentBox = Hive.box(_currentUserKey);
    return currentBox.get('isLoggedIn', defaultValue: false);
  }

  /// Déconnecter l’utilisateur mais conserver ses données
  static Future<void> logout() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.put('isLoggedIn', false);
      print('🟡 Utilisateur déconnecté proprement.');
    } catch (e) {
      print('❌ Erreur lors de logout: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  /// Effacer toute la session utilisateur
  static Future<void> logoutCompletely() async {
    try {
      final currentBox = Hive.box(_currentUserKey);
      await currentBox.clear();
      print('🔴 Déconnexion complète : session effacée.');
    } catch (e) {
      print('❌ Erreur logoutCompletely: $e');
      throw Exception('Erreur lors de la déconnexion complète');
    }
  }

  /// Debug de l’état des utilisateurs
  static void debugUserState() {
    final currentBox = Hive.box(_currentUserKey);
    final matricule = currentBox.get('matricule');
    final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);
    final userBox = Hive.box<Verificateur>(_verificateurBox);

    print('====== DEBUG USER STATE ======');
    print('Matricule current_user : $matricule');
    print('isLoggedIn : $isLoggedIn');
    print('Liste users locaux : ${userBox.keys.toList()}');

    if (matricule != null) {
      final user = userBox.get(matricule);
      print('User actuel : ${user?.nom}');
    }
    print('==============================');
  }

  static Verificateur? getUserByMatriculeAndPassword(String matricule, String password) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    final user = box.get(matricule);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  

  // ============================================================
  //                      GESTION MISSIONS
  // ============================================================

  static Future<void> saveMission(Mission mission) async {
    final box = Hive.box<Mission>(_missionBox);
    await box.put(mission.id, mission);
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final box = Hive.box<Mission>(_missionBox);
    for (var m in missions) {
      await box.put(m.id, m);
    }
  }

  static List<Mission> getAllMissions() {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.toList();
  }

  static List<Mission> getMissionsByMatricule(String matricule) {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.where((mission) {
      if (mission.verificateurs == null) return false;
      return mission.verificateurs!.any((v) => v['matricule'] == matricule);
    }).toList();
  }

  static bool missionExists(String id) {
    final box = Hive.box<Mission>(_missionBox);
    return box.containsKey(id);
  }

  static Future<void> clearMissions() async {
    final box = Hive.box<Mission>(_missionBox);
    await box.clear();
  }

  static int getMissionsCount() {
    final box = Hive.box<Mission>(_missionBox);
    return box.length;
  }

  static List<Verificateur> getAllUsers() {
    try {
      final box = Hive.box<Verificateur>(_verificateurBox);
      return box.values.toList();
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  // Récupérer un vérificateur par matricule
  static Verificateur? getVerificateurByMatricule(String matricule) {
    final box = Hive.box<Verificateur>(_verificateurBox);
    try {
      return box.values.firstWhere((v) => v.matricule == matricule);
    } catch (e) {
      return null;
    }
  }

// ============================================================
//          GESTION DES ACCOMPAGNATEURS
// ============================================================

/// Ajouter un accompagnateur à une mission
static Future<bool> addAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Initialiser la liste si null
    mission.accompagnateurs ??= [];

    // Vérifier si l'accompagnateur n'existe pas déjà
    if (!mission.accompagnateurs!.contains(accompagnateur)) {
      mission.accompagnateurs!.add(accompagnateur);
      mission.updatedAt = DateTime.now();
      await mission.save();
      print('✅ Accompagnateur ajouté: $accompagnateur');
      return true;
    } else {
      print('⚠️ Accompagnateur déjà présent: $accompagnateur');
      return false;
    }
  } catch (e) {
    print('❌ Erreur addAccompagnateur: $e');
    return false;
  }
}

/// Supprimer un accompagnateur d'une mission
static Future<bool> removeAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null || mission.accompagnateurs == null) {
      print('❌ Mission non trouvée ou liste vide: $missionId');
      return false;
    }

    // Supprimer l'accompagnateur
    final removed = mission.accompagnateurs!.remove(accompagnateur);
    
    if (removed) {
      mission.updatedAt = DateTime.now();
      await mission.save();
      print('✅ Accompagnateur supprimé: $accompagnateur');
      return true;
    } else {
      print('⚠️ Accompagnateur non trouvé: $accompagnateur');
      return false;
    }
  } catch (e) {
    print('❌ Erreur removeAccompagnateur: $e');
    return false;
  }
}

/// Modifier un accompagnateur (renommer)
static Future<bool> updateAccompagnateur({
  required String missionId,
  required String oldAccompagnateur,
  required String newAccompagnateur,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null || mission.accompagnateurs == null) {
      print('❌ Mission non trouvée ou liste vide: $missionId');
      return false;
    }

    final index = mission.accompagnateurs!.indexOf(oldAccompagnateur);
    if (index == -1) {
      print('❌ Ancien accompagnateur non trouvé: $oldAccompagnateur');
      return false;
    }

    // Vérifier si le nouveau nom n'existe pas déjà
    if (mission.accompagnateurs!.contains(newAccompagnateur)) {
      print('⚠️ Nouvel accompagnateur déjà présent: $newAccompagnateur');
      return false;
    }

    // Remplacer l'ancien par le nouveau
    mission.accompagnateurs![index] = newAccompagnateur;
    mission.updatedAt = DateTime.now();
    await mission.save();
    
    print('✅ Accompagnateur modifié: $oldAccompagnateur -> $newAccompagnateur');
    return true;
  } catch (e) {
    print('❌ Erreur updateAccompagnateur: $e');
    return false;
  }
}

/// Récupérer la liste des accompagnateurs d'une mission
static List<String>? getAccompagnateurs(String missionId) {
  try {
    final mission = getMissionById(missionId);
    return mission?.accompagnateurs;
  } catch (e) {
    print('❌ Erreur getAccompagnateurs: $e');
    return null;
  }
}

/// Vérifier si un accompagnateur existe dans une mission
static bool hasAccompagnateur({
  required String missionId,
  required String accompagnateur,
}) {
  try {
    final mission = getMissionById(missionId);
    return mission?.accompagnateurs?.contains(accompagnateur) ?? false;
  } catch (e) {
    print('❌ Erreur hasAccompagnateur: $e');
    return false;
  }
}
  // ============================================================
  //                  MODIFICATION STATUT MISSION
  // ============================================================

  /// Mettre à jour le statut d'une mission localement
  static Future<bool> updateMissionStatus({
    required String missionId,
    required String newStatus,
  }) async {
    try {
      final box = Hive.box<Mission>(_missionBox);
      final mission = box.get(missionId);

      if (mission == null) {
        print('❌ Mission non trouvée: $missionId');
        return false;
      }

      // Normaliser le statut
      String normalizedStatus = newStatus.toLowerCase();
      if (normalizedStatus == 'en cours') normalizedStatus = 'en_cours';
      if (normalizedStatus == 'terminé') normalizedStatus = 'termine';
      if (normalizedStatus == 'en attente') normalizedStatus = 'en_attente';

      mission.status = normalizedStatus;
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      print('✅ Statut mis à jour: $missionId -> $normalizedStatus');
      return true;

    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      return false;
    }
  }

  /// Récupérer une mission par son ID
  static Mission? getMissionById(String missionId) {
    try {
      final box = Hive.box<Mission>(_missionBox);
      return box.get(missionId);
    } catch (e) {
      print('❌ Erreur getMissionById: $e');
      return null;
    }
  }

  // ============================================================
//                  MODIFICATION DOCUMENTS MISSION
// ============================================================

/// Mettre à jour l'état d'un document spécifique pour une mission
static Future<bool> updateDocumentStatus({
  required String missionId,
  required String documentField,
  required bool value,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Mettre à jour le document spécifique
    switch (documentField) {
      case 'doc_cahier_prescriptions':
        mission.docCahierPrescriptions = value;
        break;
      case 'doc_notes_calculs':
        mission.docNotesCalculs = value;
        break;
      case 'doc_schemas_unifilaires':
        mission.docSchemasUnifilaires = value;
        break;
      case 'doc_plan_masse':
        mission.docPlanMasse = value;
        break;
      case 'doc_plans_architecturaux':
        mission.docPlansArchitecturaux = value;
        break;
      case 'doc_declarations_ce':
        mission.docDeclarationsCe = value;
        break;
      case 'doc_liste_installations':
        mission.docListeInstallations = value;
        break;
      case 'doc_plan_locaux_risques':
        mission.docPlanLocauxRisques = value;
        break;
      case 'doc_rapport_analyse_foudre':
        mission.docRapportAnalyseFoudre = value;
        break;
      case 'doc_rapport_etude_foudre':
        mission.docRapportEtudeFoudre = value;
        break;
      case 'doc_registre_securite':
        mission.docRegistreSecurite = value;
        break;
      case 'doc_rapport_derniere_verif':
        mission.docRapportDerniereVerif = value;
        break;
      case 'doc_autre':
        mission.docAutre = value;
        break;
      default:
        print('❌ Champ document inconnu: $documentField');
        return false;
    }

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    print('✅ Document mis à jour: $documentField -> $value pour mission $missionId');
    return true;

  } catch (e) {
    print('❌ Erreur mise à jour document local: $e');
    return false;
  }
}
static const String _renseignementsGenerauxBox = 'renseignements_generaux';
/// Mettre à jour plusieurs documents en une seule opération
static Future<bool> updateMultipleDocuments({
  required String missionId,
  required Map<String, bool> documentUpdates,
}) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Appliquer toutes les mises à jour
    documentUpdates.forEach((documentField, value) {
      switch (documentField) {
        case 'doc_cahier_prescriptions':
          mission.docCahierPrescriptions = value;
          break;
        case 'doc_notes_calculs':
          mission.docNotesCalculs = value;
          break;
        case 'doc_schemas_unifilaires':
          mission.docSchemasUnifilaires = value;
          break;
        case 'doc_plan_masse':
          mission.docPlanMasse = value;
          break;
        case 'doc_plans_architecturaux':
          mission.docPlansArchitecturaux = value;
          break;
        case 'doc_declarations_ce':
          mission.docDeclarationsCe = value;
          break;
        case 'doc_liste_installations':
          mission.docListeInstallations = value;
          break;
        case 'doc_plan_locaux_risques':
          mission.docPlanLocauxRisques = value;
          break;
        case 'doc_rapport_analyse_foudre':
          mission.docRapportAnalyseFoudre = value;
          break;
        case 'doc_rapport_etude_foudre':
          mission.docRapportEtudeFoudre = value;
          break;
        case 'doc_registre_securite':
          mission.docRegistreSecurite = value;
          break;
        case 'doc_rapport_derniere_verif':
          mission.docRapportDerniereVerif = value;
          break;
        case 'doc_autre':
          mission.docAutre = value;
          break;
        default:
          print('❌ Champ document inconnu: $documentField');
      }
    });

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    print('✅ ${documentUpdates.length} documents mis à jour pour mission $missionId');
    return true;

  } catch (e) {
    print('❌ Erreur mise à jour multiples documents: $e');
    return false;
  }
}

/// Récupérer l'état de tous les documents d'une mission
static Map<String, bool> getMissionDocumentsStatus(String missionId) {
  try {
    final mission = getMissionById(missionId);
    if (mission == null) {
      return {};
    }

    return {
      'doc_cahier_prescriptions': mission.docCahierPrescriptions,
      'doc_notes_calculs': mission.docNotesCalculs,
      'doc_schemas_unifilaires': mission.docSchemasUnifilaires,
      'doc_plan_masse': mission.docPlanMasse,
      'doc_plans_architecturaux': mission.docPlansArchitecturaux,
      'doc_declarations_ce': mission.docDeclarationsCe,
      'doc_liste_installations': mission.docListeInstallations,
      'doc_plan_locaux_risques': mission.docPlanLocauxRisques,
      'doc_rapport_analyse_foudre': mission.docRapportAnalyseFoudre,
      'doc_rapport_etude_foudre': mission.docRapportEtudeFoudre,
      'doc_registre_securite': mission.docRegistreSecurite,
      'doc_rapport_derniere_verif': mission.docRapportDerniereVerif,
      'doc_autre': mission.docAutre,
    };
  } catch (e) {
    print('❌ Erreur getMissionDocumentsStatus: $e');
    return {};
  }
}

/// Réinitialiser tous les documents d'une mission à false
static Future<bool> resetAllDocuments(String missionId) async {
  try {
    final box = Hive.box<Mission>(_missionBox);
    final mission = box.get(missionId);

    if (mission == null) {
      print('❌ Mission non trouvée: $missionId');
      return false;
    }

    // Réinitialiser tous les documents
    mission.docCahierPrescriptions = false;
    mission.docNotesCalculs = false;
    mission.docSchemasUnifilaires = false;
    mission.docPlanMasse = false;
    mission.docPlansArchitecturaux = false;
    mission.docDeclarationsCe = false;
    mission.docListeInstallations = false;
    mission.docPlanLocauxRisques = false;
    mission.docRapportAnalyseFoudre = false;
    mission.docRapportEtudeFoudre = false;
    mission.docRegistreSecurite = false;
    mission.docRapportDerniereVerif = false;
    mission.docAutre = false;

    // Mettre à jour la date de modification
    mission.updatedAt = DateTime.now();

    // Sauvegarder la mission modifiée
    await mission.save();
    
    print('✅ Tous les documents réinitialisés pour mission $missionId');
    return true;

  } catch (e) {
    print('❌ Erreur réinitialisation documents: $e');
    return false;
  }
}

  // ============================================================
  //          GESTION DESCRIPTION DES INSTALLATIONS
  // ============================================================

  /// Créer ou récupérer les données de description des installations pour une mission
static Future<DescriptionInstallations> getOrCreateDescriptionInstallations(String missionId) async {
  final box = await Hive.openBox<DescriptionInstallations>('description_installations'); // OUVERTURE EXPLICITE
  
  try {
    // Chercher par missionId
    for (var desc in box.values) {
      if (desc.missionId == missionId) {
        return desc;
      }
    }
  } catch (e) {
    print('❌ Erreur lors de la recherche: $e');
  }
  
  // Créer une nouvelle instance si non trouvée
  final newDesc = DescriptionInstallations.create(missionId);
  await box.add(newDesc);
  
  // Mettre à jour la référence dans la mission
  final missionBox = Hive.box<Mission>(_missionBox);
  final mission = missionBox.get(missionId);
  if (mission != null) {
    mission.descriptionInstallationsId = newDesc.key.toString();
    await mission.save();
  }
  
  return newDesc;
}
  /// Sauvegarder les données de description des installations
static Future<void> saveDescriptionInstallations(DescriptionInstallations desc) async {
  try {
    final box = await Hive.openBox<DescriptionInstallations>('description_installations');
    desc.updatedAt = DateTime.now();
    await box.put(desc.key, desc);
    await box.close();
  } catch (e) {
    print('❌ Erreur saveDescriptionInstallations: $e');
  }
}

  /// Récupérer les données de description des installations par missionId
  static DescriptionInstallations? getDescriptionInstallationsByMissionId(String missionId) {
    final box = Hive.box<DescriptionInstallations>(_descriptionBox);
    try {
      return box.values.firstWhere((desc) => desc.missionId == missionId);
    } catch (e) {
      return null;
    }
  }

  // Dans hive_service.dart - Ajoutez ces méthodes

// ============================================================
//          GESTION INSTALLATION ITEM AVEC PHOTOS
// ============================================================

/// Ajouter une carte (InstallationItem) à une section spécifique
static Future<bool> addInstallationItemToSection({
  required String missionId,
  required String section,
  required InstallationItem item,
}) async {
  try {
    final box = await Hive.openBox<DescriptionInstallations>('description_installations'); // OUVERTURE EXPLICITE
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        desc.alimentationMoyenneTension.add(item);
        break;
      case 'alimentation_basse_tension':
        desc.alimentationBasseTension.add(item);
        break;
      case 'groupe_electrogene':
        desc.groupeElectrogene.add(item);
        break;
      case 'alimentation_carburant':
        desc.alimentationCarburant.add(item);
        break;
      case 'inverseur':
        desc.inverseur.add(item);
        break;
      case 'stabilisateur':
        desc.stabilisateur.add(item);
        break;
      case 'onduleurs':
        desc.onduleurs.add(item);
        break;
      default:
        print('❌ Section inconnue: $section');
        return false;
    }

    desc.updatedAt = DateTime.now(); // METTRE À JOUR LA DATE
    await box.put(desc.key, desc); // SAUVEGARDER CORRECTEMENT
    await box.close(); // FERMER LA BOX
    
    print('✅ InstallationItem ajouté à la section: $section');
    return true;
  } catch (e) {
    print('❌ Erreur addInstallationItemToSection: $e');
    return false;
  }
}
/// Mettre à jour une InstallationItem existante
static Future<bool> updateInstallationItemInSection({
  required String missionId,
  required String section,
  required int index,
  required InstallationItem item,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        if (index < desc.alimentationMoyenneTension.length) {
          desc.alimentationMoyenneTension[index] = item;
        }
        break;
      case 'alimentation_basse_tension':
        if (index < desc.alimentationBasseTension.length) {
          desc.alimentationBasseTension[index] = item;
        }
        break;
      case 'groupe_electrogene':
        if (index < desc.groupeElectrogene.length) {
          desc.groupeElectrogene[index] = item;
        }
        break;
      case 'alimentation_carburant':
        if (index < desc.alimentationCarburant.length) {
          desc.alimentationCarburant[index] = item;
        }
        break;
      case 'inverseur':
        if (index < desc.inverseur.length) {
          desc.inverseur[index] = item;
        }
        break;
      case 'stabilisateur':
        if (index < desc.stabilisateur.length) {
          desc.stabilisateur[index] = item;
        }
        break;
      case 'onduleurs':
        if (index < desc.onduleurs.length) {
          desc.onduleurs[index] = item;
        }
        break;
      default:
        print('❌ Section inconnue: $section');
        return false;
    }

    await saveDescriptionInstallations(desc);
    print('✅ InstallationItem mis à jour dans la section: $section');
    return true;
  } catch (e) {
    print('❌ Erreur updateInstallationItemInSection: $e');
    return false;
  }
}

/// Récupérer tous les InstallationItems d'une section
static Future<List<InstallationItem>> getInstallationItemsFromSection({
  required String missionId,
  required String section,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        return desc.alimentationMoyenneTension;
      case 'alimentation_basse_tension':
        return desc.alimentationBasseTension;
      case 'groupe_electrogene':
        return desc.groupeElectrogene;
      case 'alimentation_carburant':
        return desc.alimentationCarburant;
      case 'inverseur':
        return desc.inverseur;
      case 'stabilisateur':
        return desc.stabilisateur;
      case 'onduleurs':
        return desc.onduleurs;
      default:
        print('❌ Section inconnue: $section');
        return [];
    }
  } catch (e) {
    print('❌ Erreur getInstallationItemsFromSection: $e');
    return [];
  }
}

/// Supprimer une InstallationItem d'une section
static Future<bool> removeInstallationItemFromSection({
  required String missionId,
  required String section,
  required int index,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    
    switch (section) {
      case 'alimentation_moyenne_tension':
        if (index < desc.alimentationMoyenneTension.length) {
          desc.alimentationMoyenneTension.removeAt(index);
        }
        break;
      case 'alimentation_basse_tension':
        if (index < desc.alimentationBasseTension.length) {
          desc.alimentationBasseTension.removeAt(index);
        }
        break;
      case 'groupe_electrogene':
        if (index < desc.groupeElectrogene.length) {
          desc.groupeElectrogene.removeAt(index);
        }
        break;
      case 'alimentation_carburant':
        if (index < desc.alimentationCarburant.length) {
          desc.alimentationCarburant.removeAt(index);
        }
        break;
      case 'inverseur':
        if (index < desc.inverseur.length) {
          desc.inverseur.removeAt(index);
        }
        break;
      case 'stabilisateur':
        if (index < desc.stabilisateur.length) {
          desc.stabilisateur.removeAt(index);
        }
        break;
      case 'onduleurs':
        if (index < desc.onduleurs.length) {
          desc.onduleurs.removeAt(index);
        }
        break;
      default:
        print('❌ Section inconnue: $section');
        return false;
    }

    await saveDescriptionInstallations(desc);
    print('✅ InstallationItem supprimé de la section: $section');
    return true;
  } catch (e) {
    print('❌ Erreur removeInstallationItemFromSection: $e');
    return false;
  }
}

/// Vérifier si une section est complète
static Future<bool> isSectionComplete({
  required String missionId,
  required String sectionKey,
}) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.isSectionComplete(sectionKey);
  } catch (e) {
    return false;
  }
}

/// Obtenir la progression de la mission
static Future<Map<String, bool>> getMissionProgress(String missionId) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.getProgress();
  } catch (e) {
    print('❌ Erreur getMissionProgress: $e');
    return {};
  }
}

/// Obtenir le pourcentage de complétion
static Future<int> getCompletionPercentage(String missionId) async {
  try {
    final desc = await getOrCreateDescriptionInstallations(missionId);
    return desc.getCompletionPercentage();
  } catch (e) {
    return 0;
  }
}

// Méthodes pour les anciennes compatibilités (à conserver)
static Future<List<Map<String, String>>> getCartesFromSection({
  required String missionId,
  required String section,
}) async {
  try {
    final items = await getInstallationItemsFromSection(
      missionId: missionId,
      section: section,
    );
    return items.map((item) => item.data).toList();
  } catch (e) {
    print('❌ Erreur getCartesFromSection: $e');
    return [];
  }
}

static Future<bool> addCarteToSection({
  required String missionId,
  required String section,
  required Map<String, String> carte,
}) async {
  return await addInstallationItemToSection(
    missionId: missionId,
    section: section,
    item: InstallationItem(data: carte),
  );
}

static Future<bool> updateCarteInSection({
  required String missionId,
  required String section,
  required int index,
  required Map<String, String> carte,
}) async {
  final items = await getInstallationItemsFromSection(
    missionId: missionId,
    section: section,
  );
  
  if (index < items.length) {
    items[index].data = carte;
    return await updateInstallationItemInSection(
      missionId: missionId,
      section: section,
      index: index,
      item: items[index],
    );
  }
  return false;
}

static Future<bool> removeCarteFromSection({
  required String missionId,
  required String section,
  required int index,
}) async {
  return await removeInstallationItemFromSection(
    missionId: missionId,
    section: section,
    index: index,
  );
}

  /// Mettre à jour une sélection radio
  static Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  }) async {
    try {
      final desc = await getOrCreateDescriptionInstallations(missionId);
      
      switch (field) {
        case 'regime_neutre':
          desc.regimeNeutre = value;
          break;
        case 'eclairage_securite':
          desc.eclairageSecurite = value;
          break;
        case 'modifications_installations':
          desc.modificationsInstallations = value;
          break;
        case 'note_calcul':
          desc.noteCalcul = value;
          break;
        case 'registre_securite':
          desc.registreSecurite = value;
          break;
        case 'presence_paratonnerre':
          desc.presenceParatonnerre = value;
          break;
        case 'analyse_risque_foudre':
          desc.analyseRisqueFoudre = value;
          break;
        case 'etude_technique_foudre':
          desc.etudeTechniqueFoudre = value;
          break;
        default:
          print('❌ Champ inconnu: $field');
          return false;
      }

      await saveDescriptionInstallations(desc);
      print('✅ Sélection mise à jour: $field -> $value');
      return true;
    } catch (e) {
      print('❌ Erreur updateSelection: $e');
      return false;
    }
  }

  /// Vérifier si une mission a des données de description
  static bool hasDescriptionInstallations(String missionId) {
    return getDescriptionInstallationsByMissionId(missionId) != null;
  }

/// Créer ou récupérer les données d'audit pour une mission
static Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId) async {
  final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
  
  try {
    final existing = box.values.firstWhere((audit) => audit.missionId == missionId);
    return existing;
  } catch (e) {
    // Créer une nouvelle instance
    final newAudit = AuditInstallationsElectriques.create(missionId);
    await box.add(newAudit);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.auditInstallationsElectriquesId = newAudit.key.toString();
      await mission.save();
    }
    
    return newAudit;
  }
}

/// Sauvegarder les données d'audit
static Future<void> saveAuditInstallations(AuditInstallationsElectriques audit) async {
  final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
  audit.updatedAt = DateTime.now();
  await audit.save();
}

/// Récupérer les données d'audit par missionId
static AuditInstallationsElectriques? getAuditInstallationsByMissionId(String missionId) {
  final box = Hive.box<AuditInstallationsElectriques>(_auditBox);
  try {
    return box.values.firstWhere((audit) => audit.missionId == missionId);
  } catch (e) {
    return null;
  }
}

// ============================================================
//          GESTION COFFRETS/ARMOIRES
// ============================================================

/// Ajouter un coffret à un local moyenne tension
static Future<bool> addCoffretToMoyenneTensionLocal({
  required String missionId,
  required int localIndex,
  required String qrCode, // Nouveau paramètre
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (localIndex < audit.moyenneTensionLocaux.length) {
      // Assurer que le coffret a le bon QR code
      coffret.qrCode = qrCode;
      audit.moyenneTensionLocaux[localIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addCoffretToMoyenneTensionLocal: $e');
    return false;
  }
}

/// Chercher un coffret par son QR code dans toute la mission
static CoffretArmoire? findCoffretByQrCode(String missionId, String qrCode) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return null;
    
    // Chercher dans les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
    }
    
    // Chercher dans les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
      
      // Chercher dans les locaux de la zone
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (coffret.qrCode == qrCode) {
            return coffret;
          }
        }
      }
    }
    
    // Chercher dans les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        if (coffret.qrCode == qrCode) {
          return coffret;
        }
      }
      
      // Chercher dans les locaux de la zone BT
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          if (coffret.qrCode == qrCode) {
            return coffret;
          }
        }
      }
    }
    
    return null;
  } catch (e) {
    print('❌ Erreur findCoffretByQrCode: $e');
    return null;
  }
}
// Vérifier si un QR code existe déjà
static bool qrCodeExists(String missionId, String qrCode) {
  return findCoffretByQrCode(missionId, qrCode) != null;
}

/// Valider qu'un QR code est unique pour la mission
static Future<bool> validateUniqueQrCode({
  required String missionId,
  required String qrCode,
  String? excludeCoffretName, // Pour les mises à jour
}) async {
  final existingCoffret = findCoffretByQrCode(missionId, qrCode);
  
  if (existingCoffret == null) {
    return true; // QR code unique
  }
  
  // Si on exclut un coffret (pour les mises à jour)
  if (excludeCoffretName != null && existingCoffret.nom == excludeCoffretName) {
    return true; // Même coffret, mise à jour autorisée
  }
  
  return false; // QR code déjà utilisé
}

/// Mettre à jour les informations d'un coffret après scan du QR code
static Future<bool> updateCoffretAfterQrScan({
  required String missionId,
  required String qrCode,
  required CoffretArmoire updatedCoffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Fonction de recherche et remplacement
    bool replaceInList(List<CoffretArmoire> coffrets) {
      final index = coffrets.indexWhere((c) => c.qrCode == qrCode);
      if (index != -1) {
        coffrets[index] = updatedCoffret;
        return true;
      }
      return false;
    }
    
    // Chercher dans tous les endroits possibles
    for (var local in audit.moyenneTensionLocaux) {
      if (replaceInList(local.coffrets)) {
        found = true;
        break;
      }
    }
    
    if (!found) {
      for (var zone in audit.moyenneTensionZones) {
        if (replaceInList(zone.coffrets)) {
          found = true;
          break;
        }
        for (var local in zone.locaux) {
          if (replaceInList(local.coffrets)) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      for (var zone in audit.basseTensionZones) {
        if (replaceInList(zone.coffretsDirects)) {
          found = true;
          break;
        }
        for (var local in zone.locaux) {
          if (replaceInList(local.coffrets)) {
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      print('✅ Coffret mis à jour après scan QR code: $qrCode');
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erreur updateCoffretAfterQrScan: $e');
    return false;
  }
}

/// Créer un nouveau coffret avec QR code
static CoffretArmoire createNewCoffretWithQrCode({
  required String qrCode,
  required String nom,
  required String type,
  String? description,
}) {
  return CoffretArmoire(
    qrCode: qrCode,
    nom: nom,
    type: type,
    description: description,
    zoneAtex: false,
    domaineTension: '',
    identificationArmoire: false,
    signalisationDanger: false,
    presenceSchema: false,
    presenceParafoudre: false,
    verificationThermographie: false,
    alimentations: [],
    pointsVerification: [],
    observationsLibres: [],
    photos: [],
  );
}
/// Ajouter un coffret à un local basse tension
static Future<bool> addCoffretToBasseTensionLocal({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length && 
        localIndex < audit.basseTensionZones[zoneIndex].locaux.length) {
      audit.basseTensionZones[zoneIndex].locaux[localIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addCoffretToBasseTensionLocal: $e');
    return false;
  }
}

/// Ajouter un coffret directement dans une zone
static Future<bool> addCoffretToMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      audit.moyenneTensionZones[zoneIndex].coffrets.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addCoffretToMoyenneTensionZone: $e');
    return false;
  }
}

/// Ajouter un coffret directement dans une zone basse tension
static Future<bool> addCoffretToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required CoffretArmoire coffret,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      audit.basseTensionZones[zoneIndex].coffretsDirects.add(coffret);
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addCoffretToBasseTensionZone: $e');
    return false;
  }
}

// ============================================================
//          MÉTHODES UTILITAIRES
// ============================================================

/// Vérifier si une mission a des données d'audit
static bool hasAuditInstallations(String missionId) {
  return getAuditInstallationsByMissionId(missionId) != null;
}

/// Obtenir tous les types de coffrets disponibles
static List<String> getCoffretTypes() {
  return [
    'Tableau urbain réduit (TUR)',
    'INVERSEUR',
    'TGBT',
    'ARMOIRE',
    'COFFRET',
    //'ARMOIRE CENTRAL CLIMATISATION',
    //'COFFRET ALIMANTATION DU COFFRET AC',
    // 'COFFRET GESTION ADMINISTRATIVE',
    // 'COFFRET NORMAL 1',
    // 'COFFRET NORMAL 2',
    // 'COFFRET SERVICE JURIDIQUE',
    // 'COFFRET CLIENTELE PROFESSIONNEL',
    // 'COFFRET DIRECTION GENERALE',
    //'COFFRET CLIENTELE ENTREPRISE',
    'TABLEAU ALIMENTATION PRINCIPAL ONDULEUR (TAOP)',
    'TABLEAU DIVISIONNAIRE ONDULEUR SERVEUR (TDOSA)',
    'TABLEAU DIVISIONNAIRE ONDULEUR SERVEUR (TDOSB)',
    'TABLEAU DIVISIONNAIRE CLIM SERVEUR (TDCS)',
    'TABLEAU GENERAL ONDULEUR (TGO)',
    // 'COFFRET LOCAL TECHNIQUE ASCENCEUR',
    // 'COFFRET ELCTRIQUE ONDULE REZ DE CHAUSSEE',
    // 'COFFRET ELCTRIQUE ONDULE SOUS SOL - 2',
    // 'ARMOIRE ELECTRIQUE TT + VENT',
    // 'ARMOIRE ELECTRIQUE TD ETAGE 2',
    //'COFFRET NORMAL',
    //'COFFRET ELCTRIQUE ONDULE SOUS ETAGE 1',
    // 'COFFRET ELCTRIQUE ONDULE SOUS ETAGE 2',
    // 'COFFRET SOUS SOL – 2 LOCAL DE CONTROLE',
  ];
}

/// Obtenir tous les types de locaux disponibles
static Map<String, String> getLocalTypes() {
  return {
    'LOCAL_TRANSFORMATEUR': 'Local HTA/HTB',
    'LOCAL_GROUPE_ELECTROGENE': 'Local Groupe Électrogène',
    'LOCAL_TGBT': 'Local TGBT',
    'LOCAL_ONDULEUR': 'Local Onduleur',
    'GAINE_TECHNIQUE': 'Gaine Technique',
    'LOCAL_TECHNIQUE_ASCENCEUR': 'Local Technique Ascenseur',
    'BAIE_INFORMATIQUE': 'Baie Informatique',
    'LOCAL_ELECTRIQUE': 'Local Électrique',
    'LOCAL_DE_CONTROLE': 'Local de Contrôle',
  };
}

/// Obtenir les éléments de contrôle pour un type de local
static List<String> getDispositionsConstructivesForLocal(String localType) {
  switch (localType) {
    case 'LOCAL_TRANSFORMATEUR':
      return [
        'Le local est exclusivement réservé à l\'usage électrique',
        'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
        'Dimensions',
        'Parois, plancher et plafond en matériaux non combustibles',
        'Présence d\'une porte pleine, ouvrant vers l\'extérieur, munie d\'un dispositif anti-panique',
        'Verrouillage empêchant tout accès non autorisé',
        'Absence de communication directe avec les locaux à risque',
        'Revêtement de sol isolant ou antidérapant',
        'Éclairage normal',
        'Éclairage de secours conforme',
        'Ventilation / Climatisation',
        'Présence de canalisations étrangères',
        'Présence d\'un revêtement diélectrique ou isolant au sol',
        'Absence de stockage d\'objets non électriques',
        'Mise à la terre de toutes les masses métalliques',
        'Présence de la terre du neutre',
        'Présence de la terre des masses',
      ];
    
    case 'LOCAL_GROUPE_ELECTROGENE':
      return [
        'Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d\'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.',
        'Canalisations du combustible',
        'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
        'Dimensions',
        'Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures',
        'Présence d\'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l\'extérieur, munie d\'un dispositif antipanique',
        'Verrouillage empêchant tout accès non autorisé',
        'Absence de communication directe avec les locaux à risque',
        'Éclairage normal',
        'Éclairage de secours conforme',
        'Ventilation',
        'Absence de canalisations étrangères',
        'Moyens d\'extinction adaptés aux risques électriques et de carburant',
        'Absence de stockage d\'objets non électriques',
        'Mise à la terre de toutes les masses métalliques',
      ];
    
    case 'LOCAL_TGBT':
    case 'LOCAL_ONDULEUR':
    case 'LOCAL_ELECTRIQUE':
      return [
        'Le local est exclusivement réservé à l\'usage électrique',
        'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
        'Dimensions',
        'Parois, plancher et plafond en matériaux non combustibles',
        'Présence d\'une porte pleine, ouvrant vers l\'extérieur, munie d\'un dispositif anti-panique',
        'Verrouillage empêchant tout accès non autorisé',
        'Absence de communication directe avec les locaux à risque',
        'Revêtement de sol isolant ou antidérapant',
        'Éclairage normal',
        'Éclairage de secours conforme',
        'Ventilation / Climatisation',
        'Présence de canalisations étrangères',
        'Présence d\'un revêtement diélectrique ou isolant au sol',
        'Présence de stockage d\'objets non électriques',
        'Mise à la terre de toutes les masses métalliques',
        'Présence de la terre du neutre',
        'Présence de la terre des masses',
      ];
    
    default:
      return [];
  }
}

/// Obtenir les conditions d'exploitation pour un type de local
static List<String> getConditionsExploitationForLocal(String localType) {
  return [
    'Accès réservé au personnel habilité (habilitation électrique à jour)',
    'Présence d\'un plan d\'intervention et de consignation affiché',
    'Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible',
    'Présence d\'un dispositif de mise hors tension générale du local',
    'Présence et accessibilité des EPI électriques (gants, visière, tapis)',
    'Zone dégagée et propre, sans obstruction des voies d\'accès',
    'Extincteur CO₂ disponible et vérifié (date de validité à jour)',
    if (localType == 'LOCAL_ONDULEUR' || localType == 'LOCAL_ELECTRIQUE')
      'Présence de stockage de matériaux inflammables'
    else
      'Absence de stockage de matériaux inflammables',
  ];
}

/// Obtenir les points de vérification pour un type de coffret
static List<String> getPointsVerificationForCoffret(String coffretType) {
  final pointsBase = [
    'Emplacement / Dégagement autour',
    'Protection IP/IK adaptée au local d\'installation',
    'Etat du coffret / Armoire',
    'Identification complète des circuits',
    'Protection contre les contacts directs (capots, caches, bornes protégées)',
    'Présence et fonctionnement des dispositifs de coupure / arrêt d\'urgence',
    'Présence et fonctionnement des dispositifs de protection',
    'Câblage',
    'Répartiteur de circuit',
    'Répartition des circuits',
    'Adéquation des dispositifs de protection',
    'Section des câbles d\'alimentation adaptée au courant nominal des disjoncteurs associés',
    'Section des câbles de départs adaptée au courant nominal des disjoncteurs associés',
    'Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)',
    'Coordination entre disjoncteurs et contacteurs',
    'Coordination entre disjoncteurs',
    'Protection contre les contacts indirects',
    'Sélectivité et coordination des protections (montée sélective des calibres)',
    'Continuité du conducteur de protection (PE)',
    'Respect code couleur des câbles',
    'Présence de double alimentation électrique',
  ];

  // Personnaliser selon le type de coffret
  switch (coffretType) {
    case 'INVERSEUR':
      return [
        ...pointsBase,
        'Dispositif de connexion',
        'Autre',
      ];
    
    case 'Tableau urbain réduit (TUR)':
      return [
        ...pointsBase.take(20), // Prend les 20 premiers points de base
      ];
    
    default:
      return pointsBase;
  }
}

// ============================================================
//          GESTION MOYENNE TENSION
// ============================================================

/// Ajouter un local moyenne tension
static Future<bool> addMoyenneTensionLocal({
  required String missionId,
  required MoyenneTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // S'assurer que la liste est modifiable
    if (audit.moyenneTensionLocaux.isEmpty) {
      audit.moyenneTensionLocaux = [];
    }
    
    audit.moyenneTensionLocaux.add(local);
    await saveAuditInstallations(audit);
    print('✅ Local moyenne tension ajouté: ${local.nom}');
    return true;
  } catch (e) {
    print('❌ Erreur addMoyenneTensionLocal: $e');
    return false;
  }
}

/// Ajouter une zone moyenne tension
static Future<bool> addMoyenneTensionZone({
  required String missionId,
  required MoyenneTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // S'assurer que la liste est modifiable
    if (audit.moyenneTensionZones.isEmpty) {
      audit.moyenneTensionZones = [];
    }
    
    audit.moyenneTensionZones.add(zone);
    await saveAuditInstallations(audit);
    print('✅ Zone moyenne tension ajoutée: ${zone.nom}');
    return true;
  } catch (e) {
    print('❌ Erreur addMoyenneTensionZone: $e');
    return false;
  }
}

/// Ajouter une zone basse tension
static Future<bool> addBasseTensionZone({
  required String missionId,
  required BasseTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // S'assurer que la liste est modifiable
    if (audit.basseTensionZones.isEmpty) {
      audit.basseTensionZones = [];
    }
    
    audit.basseTensionZones.add(zone);
    await saveAuditInstallations(audit);
    print('✅ Zone basse tension ajoutée: ${zone.nom}');
    return true;
  } catch (e) {
    print('❌ Erreur addBasseTensionZone: $e');
    return false;
  }
}

/// Ajouter un local dans une zone basse tension
static Future<bool> addLocalToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required BasseTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      
      // S'assurer que la liste est modifiable
      if (zone.locaux.isEmpty) {
        zone.locaux = [];
      }
      
      zone.locaux.add(local);
      await saveAuditInstallations(audit);
      print('✅ Local basse tension ajouté: ${local.nom}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addLocalToBasseTensionZone: $e');
    return false;
  }
}

/// Mettre à jour un local moyenne tension
static Future<bool> updateMoyenneTensionLocal({
  required String missionId,
  required int localIndex,
  required MoyenneTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (localIndex < audit.moyenneTensionLocaux.length) {
      audit.moyenneTensionLocaux[localIndex] = local;
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateMoyenneTensionLocal: $e');
    return false;
  }
}

/// Mettre à jour une zone moyenne tension
static Future<bool> updateMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required MoyenneTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      audit.moyenneTensionZones[zoneIndex] = zone;
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateMoyenneTensionZone: $e');
    return false;
  }
}

/// Mettre à jour une zone basse tension
static Future<bool> updateBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required BasseTensionZone zone,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      audit.basseTensionZones[zoneIndex] = zone;
      await saveAuditInstallations(audit);
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateBasseTensionZone: $e');
    return false;
  }
}

/// Mettre à jour un local basse tension
static Future<bool> updateBasseTensionLocal({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required BasseTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      if (localIndex < zone.locaux.length) {
        zone.locaux[localIndex] = local;
        await saveAuditInstallations(audit);
        return true;
      }
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateBasseTensionLocal: $e');
    return false;
  }
}

// ============================================================
//          GESTION LOCAUX DANS LES ZONES MOYENNE TENSION
// ============================================================

/// Ajouter un local dans une zone moyenne tension
static Future<bool> addLocalToMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required MoyenneTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    if (zoneIndex < audit.moyenneTensionZones.length) {
      final zone = audit.moyenneTensionZones[zoneIndex];
      
      // S'assurer que la liste est modifiable
      if (zone.locaux.isEmpty) {
        zone.locaux = [];
      }
      
      zone.locaux.add(local);
      await saveAuditInstallations(audit);
      print('✅ Local moyenne tension ajouté dans zone: ${local.nom}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addLocalToMoyenneTensionZone: $e');
    return false;
  }
}

/// Mettre à jour un local dans une zone moyenne tension
static Future<bool> updateLocalInMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required MoyenneTensionLocal local,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      final zone = audit.moyenneTensionZones[zoneIndex];
      if (localIndex < zone.locaux.length) {
        zone.locaux[localIndex] = local;
        await saveAuditInstallations(audit);
        return true;
      }
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateLocalInMoyenneTensionZone: $e');
    return false;
  }
}

/// Supprimer un local d'une zone moyenne tension
static Future<bool> deleteLocalFromMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      final zone = audit.moyenneTensionZones[zoneIndex];
      if (localIndex < zone.locaux.length) {
        zone.locaux.removeAt(localIndex);
        await saveAuditInstallations(audit);
        return true;
      }
    }
    return false;
  } catch (e) {
    print('❌ Erreur deleteLocalFromMoyenneTensionZone: $e');
    return false;
  }
}

// Récupérer les locaux d'une zone moyenne tension
static List<MoyenneTensionLocal> getLocauxInMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
}) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null || zoneIndex >= audit.moyenneTensionZones.length) {
      return [];
    }
    return audit.moyenneTensionZones[zoneIndex].locaux;
  } catch (e) {
    print('❌ Erreur getLocauxInMoyenneTensionZone: $e');
    return [];
  }
}

// ============================================================
//          GESTION CLASSEMENT DES LOCAUX (COMPLET)
// ============================================================

/// Synchroniser automatiquement les emplacements depuis l'audit
/// MODIFICATION : Ne synchroniser que les LOCAUX, pas les zones
static Future<List<ClassementEmplacement>> syncEmplacementsFromAudit(String missionId) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  final auditBox = Hive.box<AuditInstallationsElectriques>(_auditBox);
  
  try {
    // Récupérer l'audit de la mission
    final audit = auditBox.values.firstWhere((audit) => audit.missionId == missionId);
    
    final List<ClassementEmplacement> emplacements = [];
    final List<String> emplacementNoms = []; // Pour éviter les doublons
    
    // ===========================================
    // 1. SEULEMENT LES LOCAUX MOYENNE TENSION
    // ===========================================
    for (var local in audit.moyenneTensionLocaux) {
      if (emplacementNoms.contains(local.nom)) continue;
      
      final existant = classementBox.values.firstWhere(
        (e) => e.missionId == missionId && e.localisation == local.nom,
        orElse: () => ClassementEmplacement.create(
          missionId: missionId,
          localisation: local.nom,
          zone: null, // Ces locaux ne sont PAS dans une zone
          typeLocal: local.type,
        ),
      );
      
      if (existant.key == null) {
        await classementBox.add(existant);
      }
      
      emplacements.add(existant);
      emplacementNoms.add(local.nom);
    }
    
    // ===========================================
    // 2. IGNORER LES ZONES MOYENNE TENSION 
    // (Ce ne sont pas des locaux, ce sont des zones)
    // ===========================================
    // NE PAS AJOUTER LES ZONES MOYENNE TENSION
    // for (var zone in audit.moyenneTensionZones) {
    //   if (emplacementNoms.contains(zone.nom)) continue;
    //   // ... code supprimé ...
    // }
    
    // ===========================================
    // 3. IGNORER LES ZONES BASSE TENSION 
    // (Ce ne sont pas des locaux, ce sont des zones)
    // ===========================================
    // NE PAS AJOUTER LES ZONES BASSE TENSION
    // for (var zone in audit.basseTensionZones) {
    //   if (emplacementNoms.contains(zone.nom)) continue;
    //   // ... code supprimé ...
    // }
    
    // ===========================================
    // 4. SEULEMENT LES LOCAUX DANS LES ZONES BASSE TENSION
    // ===========================================
    for (var zone in audit.basseTensionZones) {
      // Ajouter les locaux dans la zone
      for (var local in zone.locaux) {
        // IMPORTANT: Ici, on utilise local.nom comme nom, pas "zone.nom - local.nom"
        if (emplacementNoms.contains(local.nom)) continue;
        
        final existantLocal = classementBox.values.firstWhere(
          (e) => e.missionId == missionId && e.localisation == local.nom,
          orElse: () => ClassementEmplacement.create(
            missionId: missionId,
            localisation: local.nom, // Juste le nom du local
            zone: zone.nom, // On garde la référence à la zone
            typeLocal: local.type,
          ),
        );
        
        if (existantLocal.key == null) {
          await classementBox.add(existantLocal);
        }
        
        emplacements.add(existantLocal);
        emplacementNoms.add(local.nom);
      }
    }
    
    // ===========================================
    // 5. LOCAUX DANS LES ZONES MOYENNE TENSION (si existent)
    // ===========================================
    for (var zone in audit.moyenneTensionZones) {
      // Ajouter les locaux dans la zone MT
      for (var local in zone.locaux) {
        if (emplacementNoms.contains(local.nom)) continue;
        
        final existantLocal = classementBox.values.firstWhere(
          (e) => e.missionId == missionId && e.localisation == local.nom,
          orElse: () => ClassementEmplacement.create(
            missionId: missionId,
            localisation: local.nom,
            zone: zone.nom, // On garde la référence à la zone
            typeLocal: local.type,
          ),
        );
        
        if (existantLocal.key == null) {
          await classementBox.add(existantLocal);
        }
        
        emplacements.add(existantLocal);
        emplacementNoms.add(local.nom);
      }
    }
    
    // ===========================================
    // 6. Mettre à jour la référence dans la mission
    // ===========================================
    await _updateMissionClassementReference(missionId, emplacements);
    
    print('✅ ${emplacements.length} LOCAUX (seulement) synchronisés pour mission $missionId');
    return emplacements;
    
  } catch (e) {
    print('❌ Erreur syncEmplacementsFromAudit: $e');
    return [];
  }
}
/// Mettre à jour la référence de classement dans la mission
static Future<void> _updateMissionClassementReference(String missionId, List<ClassementEmplacement> emplacements) async {
  final missionBox = Hive.box<Mission>(_missionBox);
  final mission = missionBox.get(missionId);
  
  if (mission != null) {
    if (emplacements.isNotEmpty) {
      // Créer un ID de référence unique pour cette mission
      mission.classementLocauxId = 'classement_${missionId}';
    } else {
      mission.classementLocauxId = null;
    }
    await mission.save();
    print('✅ Référence classement mise à jour pour mission $missionId');
  }
}

/// Récupérer tous les emplacements d'une mission
static List<ClassementEmplacement> getEmplacementsByMissionId(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  try {
    return box.values.where((e) => e.missionId == missionId).toList();
  } catch (e) {
    print('❌ Erreur getEmplacementsByMissionId: $e');
    return [];
  }
}

/// Récupérer un emplacement par son nom
static ClassementEmplacement? getEmplacementByNom(String missionId, String localisation) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  try {
    return box.values.firstWhere(
      (e) => e.missionId == missionId && e.localisation == localisation,
    );
  } catch (e) {
    return null;
  }
}

/// Mettre à jour un emplacement
static Future<bool> updateEmplacement(ClassementEmplacement emplacement) async {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    
    // Recalculer les indices avant sauvegarde
    emplacement.calculerIndices();
    emplacement.updatedAt = DateTime.now();
    
    await emplacement.save();
    print('✅ Emplacement mis à jour: ${emplacement.localisation}');
    return true;
  } catch (e) {
    print('❌ Erreur updateEmplacement: $e');
    return false;
  }
}

/// Supprimer un emplacement
static Future<bool> deleteEmplacement(ClassementEmplacement emplacement) async {
  try {
    await emplacement.delete();
    print('✅ Emplacement supprimé: ${emplacement.localisation}');
    return true;
  } catch (e) {
    print('❌ Erreur deleteEmplacement: $e');
    return false;
  }
}

/// Supprimer tous les emplacements d'une mission
static Future<bool> clearEmplacementsForMission(String missionId) async {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    final emplacements = box.values.where((e) => e.missionId == missionId).toList();
    
    for (var emplacement in emplacements) {
      await emplacement.delete();
    }
    
    // Supprimer la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.classementLocauxId = null;
      await mission.save();
    }
    
    print('✅ ${emplacements.length} emplacements supprimés pour mission $missionId');
    return true;
  } catch (e) {
    print('❌ Erreur clearEmplacementsForMission: $e');
    return false;
  }
}

/// Vérifier si un emplacement existe
static bool emplacementExists(String missionId, String localisation) {
  return getEmplacementByNom(missionId, localisation) != null;
}

/// Obtenir les statistiques des emplacements
static Map<String, dynamic> getEmplacementsStats(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final complet = emplacements.where((e) => 
    e.af != null && e.be != null && e.ae != null && e.ad != null && e.ag != null
  ).length;
  
  final incomplet = emplacements.length - complet;
  
  return {
    'total': emplacements.length,
    'complet': complet,
    'incomplet': incomplet,
    'pourcentage_complet': emplacements.isNotEmpty ? (complet / emplacements.length * 100).round() : 0,
  };
}

// ============================================================
//          OPTIONS ET DESCRIPTIONS (COMPLET)
// ============================================================

/// Obtenir les options pour chaque type d'influence
static List<String> getOptionsAF() => ['AF1', 'AF2', 'AF3', 'AF4'];
static List<String> getOptionsBE() => ['BE1', 'BE2', 'BE3', 'BE4'];
static List<String> getOptionsAE() => ['AE1', 'AE2', 'AE3', 'AE4'];
static List<String> getOptionsAD() => ['AD1', 'AD2', 'AD3', 'AD4', 'AD5', 'AD6', 'AD7', 'AD8', 'AD9'];
static List<String> getOptionsAG() => ['AG1', 'AG2', 'AG3', 'AG4'];

/// Obtenir toutes les options groupées
static Map<String, List<String>> getAllOptions() {
  return {
    'AF': getOptionsAF(),
    'BE': getOptionsBE(),
    'AE': getOptionsAE(),
    'AD': getOptionsAD(),
    'AG': getOptionsAG(),
  };
}

/// Récupérer la description d'une option
static String getDescriptionAF(String code) {
  final descriptions = {
    'AF1': 'Négligeable',
    'AF2': 'Agents d\'origine atmosphérique',
    'AF3': 'Intermittente ou accidentelle',
    'AF4': 'Permanente',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionBE(String code) {
  final descriptions = {
    'BE1': 'Risques négligeables',
    'BE2': 'Risques d\'incendie',
    'BE3': 'Risques d\'explosion',
    'BE4': 'Risques de contamination',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAE(String code) {
  final descriptions = {
    'AE1': 'Négligeable → IP 2X',
    'AE2': 'Petits objets (≥ 2,5 mm) → IP 3X',
    'AE3': 'Très petits objets (1 à 2,5 mm) → IP 4X',
    'AE4': 'Poussières → IP 5X (Protégé)',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAD(String code) {
  final descriptions = {
    'AD1': 'Négligeable → IP X0',
    'AD2': 'Chutes de gouttes d\'eau → IP X1',
    'AD3': 'Chutes de gouttes d\'eau jusqu\'à 15° → IP X2',
    'AD4': 'Aspersion d\'eau → IP X3',
    'AD5': 'Projections d\'eau → IP X4',
    'AD6': 'Jets d\'eau → IP X5',
    'AD7': 'Paquets d\'eau → IP X6',
    'AD8': 'Immersion → IP X7',
    'AD9': 'Submersion → IP X8',
  };
  return descriptions[code] ?? code;
}

static String getDescriptionAG(String code) {
  final descriptions = {
    'AG1': 'Faibles (0,225 J) → IK 02',
    'AG2': 'Moyens (2 J) → IK 07',
    'AG3': 'Importants (5 J) → IK 08',
    'AG4': 'Très importants (20 J) → IK 10',
  };
  return descriptions[code] ?? code;
}

/// Obtenir la description pour n'importe quel code
static String getDescriptionForCode(String code) {
  if (code.startsWith('AF')) return getDescriptionAF(code);
  if (code.startsWith('BE')) return getDescriptionBE(code);
  if (code.startsWith('AE')) return getDescriptionAE(code);
  if (code.startsWith('AD')) return getDescriptionAD(code);
  if (code.startsWith('AG')) return getDescriptionAG(code);
  return code;
}

// ============================================================
//          CALCUL DES INDICES (COMPLET)
// ============================================================

/// Calculer l'indice IP à partir de AE et AD
static String? calculateIP(String? ae, String? ad) {
  if (ae == null || ad == null) return null;
  
  final aeNum = _extractAENumber(ae);
  final adNum = _extractADNumber(ad);
  
  if (aeNum == null || adNum == null) return null;
  
  return 'IP${aeNum}${adNum}';
}

/// Calculer l'indice IK à partir de AG
static String? calculateIK(String? ag) {
  if (ag == null) return null;
  
  switch (ag) {
    case 'AG1': return 'IK02';
    case 'AG2': return 'IK07';
    case 'AG3': return 'IK08';
    case 'AG4': return 'IK10';
    default: return null;
  }
}

/// Extraire le numéro pour AE
static int? _extractAENumber(String ae) {
  switch (ae) {
    case 'AE1': return 2;
    case 'AE2': return 3;
    case 'AE3': return 4;
    case 'AE4': return 5; // ou 6 selon spécification
    default: return null;
  }
}

/// Extraire le numéro pour AD
static int? _extractADNumber(String ad) {
  switch (ad) {
    case 'AD1': return 0;
    case 'AD2': return 1;
    case 'AD3': return 2;
    case 'AD4': return 3;
    case 'AD5': return 4;
    case 'AD6': return 5;
    case 'AD7': return 6;
    case 'AD8': return 7;
    case 'AD9': return 8;
    default: return null;
  }
}

// ============================================================
//          UTILITAIRES (COMPLET)
// ============================================================

/// Vérifier si un emplacement est complet
static bool isEmplacementComplet(ClassementEmplacement emplacement) {
  return emplacement.af != null && 
         emplacement.be != null && 
         emplacement.ae != null && 
         emplacement.ad != null && 
         emplacement.ag != null;
}

/// Obtenir le pourcentage de complétion
// static int getCompletionPercentage(ClassementEmplacement emplacement) {
//   int filled = 0;
//   if (emplacement.af != null) filled++;
//   if (emplacement.be != null) filled++;
//   if (emplacement.ae != null) filled++;
//   if (emplacement.ad != null) filled++;
//   if (emplacement.ag != null) filled++;
  
//   return (filled / 5 * 100).round();
// }

/// Obtenir le type d'icône pour un emplacement
static Future<IconData> getIconForEmplacement(ClassementEmplacement emplacement) async {
  if (isEmplacementComplet(emplacement)) {
    return Icons.check_circle_outline;
  } else if (await getCompletionPercentage(emplacement.missionId) > 0) {
    return Icons.info_outline;
  } else {
    return Icons.location_on_outlined;
  }
}

/// Obtenir la couleur pour un emplacement
static Future<Color> getColorForEmplacement(ClassementEmplacement emplacement) async {
  final percentage = await getCompletionPercentage(emplacement.missionId);
  
  if (percentage == 100) return Colors.green;
  if (percentage >= 50) return Colors.orange;
  return Colors.blue;
}

/// Exporter les données de classement au format CSV
static String exportClassementToCSV(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final csv = StringBuffer();
  
  // En-tête
  csv.writeln('Localisation;Zone;Origine classement;AF;BE;AE;AD;AG;IP;IK');
  
  // Données
  for (var emp in emplacements) {
    csv.writeln('${emp.localisation};${emp.zone ?? ""};${emp.origineClassement};'
                '${emp.af ?? ""};${emp.be ?? ""};${emp.ae ?? ""};${emp.ad ?? ""};${emp.ag ?? ""};'
                '${emp.ip ?? ""};${emp.ik ?? ""}');
  }
  
  return csv.toString();
}

/// Importer les données de classement depuis CSV
static Future<bool> importClassementFromCSV(String missionId, String csvData) async {
  try {
    final lines = csvData.split('\n');
    
    // Ignorer l'en-tête
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(';');
      if (parts.length < 3) continue;
      
      final localisation = parts[0];
      final zone = parts[1].isEmpty ? null : parts[1];
      final origineClassement = parts[2];
      
      // Chercher l'emplacement existant ou en créer un nouveau
      var emplacement = getEmplacementByNom(missionId, localisation);
      
      if (emplacement == null) {
        emplacement = ClassementEmplacement.create(
          missionId: missionId,
          localisation: localisation,
          zone: zone,
          typeLocal: null,
        );
        final box = Hive.box<ClassementEmplacement>(_classementBox);
        await box.add(emplacement);
      }
      
      // Mettre à jour les valeurs
      emplacement.origineClassement = origineClassement;
      
      if (parts.length > 3 && parts[3].isNotEmpty) emplacement.af = parts[3];
      if (parts.length > 4 && parts[4].isNotEmpty) emplacement.be = parts[4];
      if (parts.length > 5 && parts[5].isNotEmpty) emplacement.ae = parts[5];
      if (parts.length > 6 && parts[6].isNotEmpty) emplacement.ad = parts[6];
      if (parts.length > 7 && parts[7].isNotEmpty) emplacement.ag = parts[7];
      
      // Recalculer les indices
      emplacement.calculerIndices();
      emplacement.updatedAt = DateTime.now();
      
      await emplacement.save();
    }
    
    print('✅ Données de classement importées pour mission $missionId');
    return true;
    
  } catch (e) {
    print('❌ Erreur importClassementFromCSV: $e');
    return false;
  }
}

/// Vérifier la cohérence des données d'audit
static Map<String, dynamic> checkAuditConsistency(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final issues = <String>[];
  
  if (audit == null) {
    issues.add('Aucun audit trouvé pour cette mission');
    return {'hasIssues': true, 'issues': issues, 'suggestions': ['Créer d\'abord un audit']};
  }
  
  // Vérifier les locaux moyenne tension
  for (var local in audit.moyenneTensionLocaux) {
    if (!emplacements.any((e) => e.localisation == local.nom)) {
      issues.add('Local MT "${local.nom}" non synchronisé');
    }
  }
  
  // Vérifier les zones moyenne tension
  for (var zone in audit.moyenneTensionZones) {
    if (!emplacements.any((e) => e.localisation == zone.nom)) {
      issues.add('Zone MT "${zone.nom}" non synchronisée');
    }
  }
  
  // Vérifier les zones basse tension
  for (var zone in audit.basseTensionZones) {
    if (!emplacements.any((e) => e.localisation == zone.nom)) {
      issues.add('Zone BT "${zone.nom}" non synchronisée');
    }
    
    // Vérifier les locaux dans les zones
    for (var local in zone.locaux) {
      final nomLocal = '${zone.nom} - ${local.nom}';
      if (!emplacements.any((e) => e.localisation == nomLocal)) {
        issues.add('Local BT "$nomLocal" non synchronisé');
      }
    }
  }
  
  return {
    'hasIssues': issues.isNotEmpty,
    'issues': issues,
    'totalIssues': issues.length,
    'suggestions': issues.isEmpty 
      ? ['Tout est synchronisé ✓'] 
      : ['Cliquez sur "Synchroniser" pour corriger']
  };
}

/// Obtenir un résumé du classement
static Map<String, dynamic> getClassementSummary(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  final stats = getEmplacementsStats(missionId);
  final consistency = checkAuditConsistency(missionId);
  
  // Calculer les influences les plus fréquentes
  final influenceCounts = <String, int>{};
  
  for (var emp in emplacements) {
    if (emp.af != null) influenceCounts['AF'] = (influenceCounts['AF'] ?? 0) + 1;
    if (emp.be != null) influenceCounts['BE'] = (influenceCounts['BE'] ?? 0) + 1;
    if (emp.ae != null) influenceCounts['AE'] = (influenceCounts['AE'] ?? 0) + 1;
    if (emp.ad != null) influenceCounts['AD'] = (influenceCounts['AD'] ?? 0) + 1;
    if (emp.ag != null) influenceCounts['AG'] = (influenceCounts['AG'] ?? 0) + 1;
  }
  
  return {
    'total_emplacements': stats['total'],
    'complet': stats['complet'],
    'incomplet': stats['incomplet'],
    'pourcentage_complet': stats['pourcentage_complet'],
    'consistency_issues': consistency['totalIssues'],
    'influence_counts': influenceCounts,
    'last_updated': emplacements.isNotEmpty 
      ? emplacements.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
      : null,
  };
}

/// Forcer la synchronisation (supprime et recrée)
static Future<bool> forceSyncEmplacements(String missionId) async {
  try {
    // 1. Supprimer les anciens emplacements
    await clearEmplacementsForMission(missionId);
    
    // 2. Synchroniser à nouveau
    await syncEmplacementsFromAudit(missionId);
    
    print('✅ Synchronisation forcée terminée pour mission $missionId');
    return true;
    
  } catch (e) {
    print('❌ Erreur forceSyncEmplacements: $e');
    return false;
  }
}

/// Obtenir les emplacements groupés par type
static Map<String, List<ClassementEmplacement>> getEmplacementsByType(String missionId) {
  final emplacements = getEmplacementsByMissionId(missionId);
  
  final result = <String, List<ClassementEmplacement>>{
    'LOCAUX_MT': [],
    'ZONES_MT': [],
    'ZONES_BT': [],
    'LOCAUX_BT': [],
    'AUTRES': [],
  };
  
  for (var emp in emplacements) {
    if (emp.typeLocal == 'LOCAL_TRANSFORMATEUR') {
      result['LOCAUX_MT']!.add(emp);
    } else if (emp.typeLocal == 'ZONE_MT') {
      result['ZONES_MT']!.add(emp);
    } else if (emp.typeLocal == 'ZONE_BT') {
      result['ZONES_BT']!.add(emp);
    } else if (emp.typeLocal?.contains('LOCAL_') == true && emp.zone != null) {
      result['LOCAUX_BT']!.add(emp);
    } else {
      result['AUTRES']!.add(emp);
    }
  }
  
  return result;
}

/// Obtenir les statistiques par type
static Map<String, Map<String, dynamic>> getStatsByType(String missionId) {
  final grouped = getEmplacementsByType(missionId);
  final result = <String, Map<String, dynamic>>{};
  
  for (var entry in grouped.entries) {
    final type = entry.key;
    final emplacements = entry.value;
    
    final complet = emplacements.where((e) => isEmplacementComplet(e)).length;
    final incomplet = emplacements.length - complet;
    
    result[type] = {
      'total': emplacements.length,
      'complet': complet,
      'incomplet': incomplet,
      'pourcentage': emplacements.isNotEmpty ? (complet / emplacements.length * 100).round() : 0,
    };
  }
  
  return result;
}

// ============================================================
//          LISTENERS ET OBSERVATEURS
// ============================================================

/// Écouter les changements dans les emplacements
static ValueListenable<Box<ClassementEmplacement>> watchEmplacements(String missionId) {
  final box = Hive.box<ClassementEmplacement>(_classementBox);
  return box.listenable();
}

/// Filtrer les emplacements par critères
static List<ClassementEmplacement> filterEmplacements({
  required String missionId,
  String? searchQuery,
  bool? onlyComplete,
  String? typeLocal,
}) {
  var emplacements = getEmplacementsByMissionId(missionId);
  
  // Filtrer par recherche
  if (searchQuery != null && searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    emplacements = emplacements.where((e) =>
      e.localisation.toLowerCase().contains(query) ||
      (e.zone?.toLowerCase() ?? '').contains(query) ||
      (e.typeLocal?.toLowerCase() ?? '').contains(query)
    ).toList();
  }
  
  // Filtrer par complétude
  if (onlyComplete != null) {
    if (onlyComplete) {
      emplacements = emplacements.where((e) => isEmplacementComplet(e)).toList();
    } else {
      emplacements = emplacements.where((e) => !isEmplacementComplet(e)).toList();
    }
  }
  
  // Filtrer par type
  if (typeLocal != null && typeLocal.isNotEmpty) {
    emplacements = emplacements.where((e) => e.typeLocal == typeLocal).toList();
  }
  
  return emplacements;
}

/// Trier les emplacements
static List<ClassementEmplacement> sortEmplacements({
  required List<ClassementEmplacement> emplacements,
  String sortBy = 'localisation',
  bool ascending = true,
}) {
  List<ClassementEmplacement> sorted = List.from(emplacements);
  
  switch (sortBy) {
    case 'localisation':
      sorted.sort((a, b) => a.localisation.compareTo(b.localisation));
      break;
    case 'zone':
      sorted.sort((a, b) => (a.zone ?? '').compareTo(b.zone ?? ''));
      break;
    case 'completude':
      sorted.sort((a, b) {
        final aComplete = isEmplacementComplet(a);
        final bComplete = isEmplacementComplet(b);
        if (aComplete == bComplete) return 0;
        return aComplete ? 1 : -1;
      });
      break;
    case 'updated':
      sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
  }
  
  if (!ascending) {
    sorted = sorted.reversed.toList();
  }
  
  return sorted;
}

// ============================================================
//          GESTION DES OBSERVATIONS FOUDRES ``
// ============================================================

/// Créer une nouvelle observation foudre
static Future<Foudre> createFoudreObservation({
  required String missionId,
  required String observation,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    
    // Créer la nouvelle observation
    final foudre = Foudre.create(
      missionId: missionId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
    
    // Sauvegarder dans Hive
    await box.add(foudre);
    
    // Mettre à jour la référence dans la mission (si nécessaire)
    await _updateFoudreReferenceInMission(missionId, foudre);
    
    print('✅ Observation foudre créée: ${foudre.key}');
    return foudre;
  } catch (e) {
    print('❌ Erreur createFoudreObservation: $e');
    rethrow;
  }
}

/// Récupérer toutes les observations foudre d'une mission
static List<Foudre> getFoudreObservationsByMissionId(String missionId) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.values
        .where((foudre) => foudre.missionId == missionId)
        .toList();
  } catch (e) {
    print('❌ Erreur getFoudreObservationsByMissionId: $e');
    return [];
  }
}

/// Récupérer une observation foudre par son ID (clé Hive)
static Foudre? getFoudreObservationById(dynamic id) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.get(id);
  } catch (e) {
    print('❌ Erreur getFoudreObservationById: $e');
    return null;
  }
}

/// Récupérer les observations foudre par niveau de priorité
static List<Foudre> getFoudreObservationsByPriority(String missionId, int niveauPriorite) {
  try {
    final allObservations = getFoudreObservationsByMissionId(missionId);
    return allObservations
        .where((foudre) => foudre.niveauPriorite == niveauPriorite)
        .toList();
  } catch (e) {
    print('❌ Erreur getFoudreObservationsByPriority: $e');
    return [];
  }
}

// ============================================================
//          MISE À JOUR FOUDRES
// ============================================================

/// Mettre à jour une observation foudre existante
static Future<bool> updateFoudreObservation({
  required dynamic foudreId,
  required String observation,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    // Valider le niveau de priorité
    if (niveauPriorite < 1 || niveauPriorite > 3) {
      print('❌ Niveau de priorité invalide: $niveauPriorite');
      return false;
    }
    
    // Mettre à jour les propriétés
    foudre.observation = observation;
    foudre.niveauPriorite = niveauPriorite;
    foudre.updatedAt = DateTime.now();
    
    // Sauvegarder les modifications
    await foudre.save();
    
    print('✅ Observation foudre mise à jour: $foudreId');
    return true;
  } catch (e) {
    print('❌ Erreur updateFoudreObservation: $e');
    return false;
  }
}

/// Mettre à jour uniquement l'observation (sans changer la priorité)
static Future<bool> updateFoudreObservationText({
  required dynamic foudreId,
  required String observation,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    foudre.observation = observation;
    foudre.updatedAt = DateTime.now();
    
    await foudre.save();
    
    print('✅ Texte observation foudre mis à jour: $foudreId');
    return true;
  } catch (e) {
    print('❌ Erreur updateFoudreObservationText: $e');
    return false;
  }
}

/// Mettre à jour uniquement la priorité
static Future<bool> updateFoudreObservationPriority({
  required dynamic foudreId,
  required int niveauPriorite,
}) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    // Valider le niveau de priorité
    if (niveauPriorite < 1 || niveauPriorite > 3) {
      print('❌ Niveau de priorité invalide: $niveauPriorite');
      return false;
    }
    
    foudre.niveauPriorite = niveauPriorite;
    foudre.updatedAt = DateTime.now();
    
    await foudre.save();
    
    print('✅ Priorité observation foudre mise à jour: $foudreId -> $niveauPriorite');
    return true;
  } catch (e) {
    print('❌ Erreur updateFoudreObservationPriority: $e');
    return false;
  }
}

// ============================================================
//          SUPPRESSION FOUDRES
// ============================================================

/// Supprimer une observation foudre
static Future<bool> deleteFoudreObservation(dynamic foudreId) async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    final foudre = box.get(foudreId);
    
    if (foudre == null) {
      print('❌ Observation foudre non trouvée: $foudreId');
      return false;
    }
    
    // Supprimer la référence dans la mission (si nécessaire)
    await _removeFoudreReferenceFromMission(foudre.missionId, foudreId);
    
    // Supprimer l'observation
    await foudre.delete();
    
    print('✅ Observation foudre supprimée: $foudreId');
    return true;
  } catch (e) {
    print('❌ Erreur deleteFoudreObservation: $e');
    return false;
  }
}

/// Supprimer toutes les observations foudre d'une mission
static Future<bool> deleteAllFoudreObservationsForMission(String missionId) async {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    for (var foudre in observations) {
      await foudre.delete();
    }
    
    // Supprimer les références dans la mission (si nécessaire)
    await _clearFoudreReferencesFromMission(missionId);
    
    print('✅ ${observations.length} observations foudre supprimées pour mission $missionId');
    return true;
  } catch (e) {
    print('❌ Erreur deleteAllFoudreObservationsForMission: $e');
    return false;
  }
}

// ============================================================
//          GESTION DES RÉFÉRENCES DANS LA MISSION (FACULTATIF)
// ============================================================

/// Mettre à jour la référence d'une observation foudre dans la mission
static Future<void> _updateFoudreReferenceInMission(String missionId, Foudre foudre) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null) {
      // Initialiser la liste si nécessaire
      mission.foudreIds ??= [];
      
      // Ajouter l'ID de l'observation (key est l'ID Hive)
      final foudreId = foudre.key.toString();
      if (!mission.foudreIds!.contains(foudreId)) {
        mission.foudreIds!.add(foudreId);
        mission.updatedAt = DateTime.now();
        await mission.save();
        
        print('✅ Référence foudre ajoutée à la mission $missionId: $foudreId');
      }
    }
  } catch (e) {
    print('❌ Erreur _updateFoudreReferenceInMission: $e');
  }
}

/// Supprimer la référence d'une observation foudre d'une mission
static Future<void> _removeFoudreReferenceFromMission(String missionId, dynamic foudreId) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null && mission.foudreIds != null) {
      final foudreIdStr = foudreId.toString();
      mission.foudreIds!.remove(foudreIdStr);
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      print('✅ Référence foudre supprimée de la mission $missionId: $foudreIdStr');
    }
  } catch (e) {
    print('❌ Erreur _removeFoudreReferenceFromMission: $e');
  }
}

/// Supprimer toutes les références foudre d'une mission
static Future<void> _clearFoudreReferencesFromMission(String missionId) async {
  try {
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    
    if (mission != null) {
      mission.foudreIds = null;
      mission.updatedAt = DateTime.now();
      await mission.save();
      
      print('✅ Toutes les références foudre supprimées de la mission $missionId');
    }
  } catch (e) {
    print('❌ Erreur _clearFoudreReferencesFromMission: $e');
  }
}

// ============================================================
//          STATISTIQUES FOUDRES
// ============================================================

/// Obtenir les statistiques des observations foudre pour une mission
static Map<String, dynamic> getFoudreStatsForMission(String missionId) {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    final total = observations.length;
    
    // Compter par priorité
    final byPriority = {
      1: observations.where((f) => f.niveauPriorite == 1).length,
      2: observations.where((f) => f.niveauPriorite == 2).length,
      3: observations.where((f) => f.niveauPriorite == 3).length,
    };
    
    // Dates des observations
    final latestObservation = observations.isNotEmpty
        ? observations.map((f) => f.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    final latestUpdate = observations.isNotEmpty
        ? observations.map((f) => f.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    return {
      'total': total,
      'priorite_1': byPriority[1] ?? 0,
      'priorite_2': byPriority[2] ?? 0,
      'priorite_3': byPriority[3] ?? 0,
      'derniere_creation': latestObservation,
      'derniere_modification': latestUpdate,
      'pourcentage_priorite_1': total > 0 ? ((byPriority[1] ?? 0) / total * 100).round() : 0,
      'pourcentage_priorite_2': total > 0 ? ((byPriority[2] ?? 0) / total * 100).round() : 0,
      'pourcentage_priorite_3': total > 0 ? ((byPriority[3] ?? 0) / total * 100).round() : 0,
    };
  } catch (e) {
    print('❌ Erreur getFoudreStatsForMission: $e');
    return {
      'total': 0,
      'priorite_1': 0,
      'priorite_2': 0,
      'priorite_3': 0,
      'derniere_creation': null,
      'derniere_modification': null,
      'pourcentage_priorite_1': 0,
      'pourcentage_priorite_2': 0,
      'pourcentage_priorite_3': 0,
    };
  }
}

/// Obtenir le label de priorité (texte)
static String getPrioriteLabel(int niveauPriorite) {
  switch (niveauPriorite) {
    case 1: return 'Priorité Haute';
    case 2: return 'Priorité Moyenne';
    case 3: return 'Priorité Basse';
    default: return 'Non défini';
  }
}

/// Obtenir la couleur pour une priorité
static String getPrioriteColor(int niveauPriorite) {
  switch (niveauPriorite) {
    case 1: return '#FF0000'; // Rouge
    case 2: return '#FFA500'; // Orange
    case 3: return '#008000'; // Vert
    default: return '#000000'; // Noir
  }
}

/// Vérifier si une mission a des observations foudre
static bool hasFoudreObservations(String missionId) {
  return getFoudreObservationsByMissionId(missionId).isNotEmpty;
}

/// Obtenir le nombre total d'observations foudre pour une mission
static int getFoudreCountForMission(String missionId) {
  return getFoudreObservationsByMissionId(missionId).length;
}

// ============================================================
//          FILTRAGE ET TRI FOUDRES
// ============================================================

/// Filtrer les observations foudre
static List<Foudre> filterFoudreObservations({
  required String missionId,
  String? searchQuery,
  int? niveauPriorite,
}) {
  var observations = getFoudreObservationsByMissionId(missionId);
  
  // Filtrer par recherche textuelle
  if (searchQuery != null && searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    observations = observations
        .where((f) => f.observation.toLowerCase().contains(query))
        .toList();
  }
  
  // Filtrer par priorité
  if (niveauPriorite != null) {
    observations = observations
        .where((f) => f.niveauPriorite == niveauPriorite)
        .toList();
  }
  
  return observations;
}

/// Trier les observations foudre
static List<Foudre> sortFoudreObservations({
  required List<Foudre> observations,
  String sortBy = 'created_at',
  bool ascending = true,
}) {
  List<Foudre> sorted = List.from(observations);
  
  switch (sortBy) {
    case 'created_at':
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case 'updated_at':
      sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case 'priorite':
      sorted.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));
      break;
    case 'observation':
      sorted.sort((a, b) => a.observation.compareTo(b.observation));
      break;
  }
  
  if (!ascending) {
    sorted = sorted.reversed.toList();
  }
  
  return sorted;
}

// ============================================================
//          IMPORT/EXPORT FOUDRES
// ============================================================

/// Exporter les observations foudre au format CSV
static String exportFoudreToCSV(String missionId) {
  try {
    final observations = getFoudreObservationsByMissionId(missionId);
    
    final csv = StringBuffer();
    
    // En-tête
    csv.writeln('ID;Observation;Priorité;Date création;Date modification');
    
    // Données
    for (var foudre in observations) {
      csv.writeln('${foudre.key};'
                  '${foudre.observation.replaceAll(';', ',')};'
                  '${foudre.niveauPriorite};'
                  '${foudre.createdAt.toIso8601String()};'
                  '${foudre.updatedAt.toIso8601String()}');
    }
    
    return csv.toString();
  } catch (e) {
    print('❌ Erreur exportFoudreToCSV: $e');
    return '';
  }
}

/// Importer les observations foudre depuis JSON
static Future<bool> importFoudreFromJson(String missionId, List<Map<String, dynamic>> jsonData) async {
  try {
    int imported = 0;
    
    for (var data in jsonData) {
      try {
        // Créer l'observation depuis le JSON
        final foudre = Foudre.fromJson(data);
        
        // S'assurer que la missionId est correcte
        foudre.missionId = missionId;
        
        // Sauvegarder dans Hive
        final box = Hive.box<Foudre>(_foudreBox);
        await box.add(foudre);
        
        imported++;
      } catch (e) {
        print('❌ Erreur lors de l\'import d\'une observation: $e');
      }
    }
    
    print('✅ $imported observations foudre importées pour mission $missionId');
    return true;
    
  } catch (e) {
    print('❌ Erreur importFoudreFromJson: $e');
    return false;
  }
}

// ============================================================
//          ÉCOUTEUR ET OBSERVATEURS FOUDRES
// ============================================================

/// Écouter les changements dans les observations foudre d'une mission
static ValueListenable<Box<Foudre>> watchFoudreObservations(String missionId) {
  final box = Hive.box<Foudre>(_foudreBox);
  return box.listenable();
}

/// Obtenir un stream des observations filtrées
static Stream<List<Foudre>> streamFoudreObservations({
  required String missionId,
  int? niveauPriorite,
}) {
  final box = Hive.box<Foudre>(_foudreBox);
  
  return box.watch().map((event) {
    return filterFoudreObservations(
      missionId: missionId,
      niveauPriorite: niveauPriorite,
    );
  });
}

// ============================================================
//          UTILITAIRES FOUDRES
// ============================================================

/// Vérifier si une observation existe
static bool foudreObservationExists(dynamic foudreId) {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.containsKey(foudreId);
  } catch (e) {
    print('❌ Erreur foudreObservationExists: $e');
    return false;
  }
}

/// Obtenir toutes les observations foudre (toutes missions confondues)
static List<Foudre> getAllFoudreObservations() {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    return box.values.toList();
  } catch (e) {
    print('❌ Erreur getAllFoudreObservations: $e');
    return [];
  }
}

/// Vider complètement la table foudre
static Future<bool> clearAllFoudreObservations() async {
  try {
    final box = Hive.box<Foudre>(_foudreBox);
    await box.clear();
    
    // Supprimer aussi toutes les références dans les missions
    final missionBox = Hive.box<Mission>(_missionBox);
    for (var mission in missionBox.values) {
      mission.foudreIds = null;
      await mission.save();
    }
    
    print('✅ Toutes les observations foudre supprimées');
    return true;
  } catch (e) {
    print('❌ Erreur clearAllFoudreObservations: $e');
    return false;
  }
}

/// Copier les observations foudre d'une mission à une autre
static Future<bool> copyFoudreObservations({
  required String sourceMissionId,
  required String targetMissionId,
}) async {
  try {
    final sourceObservations = getFoudreObservationsByMissionId(sourceMissionId);
    
    for (var sourceFoudre in sourceObservations) {
      // Créer une nouvelle observation pour la mission cible
      await createFoudreObservation(
        missionId: targetMissionId,
        observation: sourceFoudre.observation,
        niveauPriorite: sourceFoudre.niveauPriorite,
      );
    }
    
    print('✅ ${sourceObservations.length} observations foudre copiées de $sourceMissionId vers $targetMissionId');
    return true;
  } catch (e) {
    print('❌ Erreur copyFoudreObservations: $e');
    return false;
  }
}

// ============================================================
//          GESTION MESURES ET ESSAIS (NOUVEAU)
// ============================================================

/// Créer ou récupérer les données de mesures et essais pour une mission
static Future<MesuresEssais> getOrCreateMesuresEssais(String missionId) async {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  
  try {
    final existing = box.values.firstWhere((mesures) => mesures.missionId == missionId);
    return existing;
  } catch (e) {
    // Créer une nouvelle instance
    final newMesures = MesuresEssais.create(missionId);
    await box.add(newMesures);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.mesuresEssaisId = newMesures.key.toString();
      await mission.save();
    }
    
    print('✅ MesuresEssais créé pour mission: $missionId');
    return newMesures;
  }
}

/// Sauvegarder les données de mesures et essais
static Future<void> saveMesuresEssais(MesuresEssais mesures) async {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  mesures.updatedAt = DateTime.now();
  await mesures.save();
  print('✅ MesuresEssais sauvegardé pour mission: ${mesures.missionId}');
}

/// Récupérer les données de mesures et essais par missionId
static MesuresEssais? getMesuresEssaisByMissionId(String missionId) {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  try {
    return box.values.firstWhere((mesures) => mesures.missionId == missionId);
  } catch (e) {
    return null;
  }
}

/// Vérifier si une mission a des données de mesures et essais
static bool hasMesuresEssais(String missionId) {
  return getMesuresEssaisByMissionId(missionId) != null;
}

/// Obtenir les statistiques des mesures et essais pour une mission
static Map<String, dynamic> getMesuresEssaisStats(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  if (mesures == null) {
    return {
      'total_prises_terre': 0,
      'total_essais_differ': 0,
      'total_continuites': 0,
      'condition_mesure_renseignee': false,
      'demarrage_auto_renseigne': false,
      'arret_urgence_renseigne': false,
      'avis_mesures_renseigne': false,
    };
  }
  
  return mesures.calculerStatistiques();
}

// ============================================================
//          SECTION 1: CONDITIONS DE MESURE
// ============================================================

/// Mettre à jour les conditions de mesure
static Future<bool> updateConditionMesure({
  required String missionId,
  required String observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.conditionMesure.observation = observation;
    await saveMesuresEssais(mesures);
    print('✅ Conditions de mesure mises à jour');
    return true;
  } catch (e) {
    print('❌ Erreur updateConditionMesure: $e');
    return false;
  }
}

// ============================================================
//          SECTION 2: ESSAIS DE DÉMARRAGE AUTOMATIQUE
// ============================================================

/// Mettre à jour les essais de démarrage automatique
static Future<bool> updateEssaiDemarrageAuto({
  required String missionId,
  required String observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.essaiDemarrageAuto.observation = observation;
    await saveMesuresEssais(mesures);
    print('✅ Essais démarrage auto mis à jour');
    return true;
  } catch (e) {
    print('❌ Erreur updateEssaiDemarrageAuto: $e');
    return false;
  }
}

// ============================================================
//          SECTION 3: TEST D'ARRÊT D'URGENCE
// ============================================================

/// Mettre à jour les tests d'arrêt d'urgence
static Future<bool> updateTestArretUrgence({
  required String missionId,
  required String observation,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.testArretUrgence.observation = observation;
    await saveMesuresEssais(mesures);
    print('✅ Tests arrêt urgence mis à jour');
    return true;
  } catch (e) {
    print('❌ Erreur updateTestArretUrgence: $e');
    return false;
  }
}

// ============================================================
//          SECTION 4: PRISES DE TERRE
// ============================================================

/// Ajouter une prise de terre
static Future<bool> addPriseTerre({
  required String missionId,
  required PriseTerre priseTerre,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.prisesTerre.add(priseTerre);
    await saveMesuresEssais(mesures);
    print('✅ Prise de terre ajoutée: ${priseTerre.identification}');
    return true;
  } catch (e) {
    print('❌ Erreur addPriseTerre: $e');
    return false;
  }
}

/// Mettre à jour une prise de terre existante
static Future<bool> updatePriseTerre({
  required String missionId,
  required int index,
  required PriseTerre priseTerre,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.prisesTerre.length) {
      mesures.prisesTerre[index] = priseTerre;
      await saveMesuresEssais(mesures);
      print('✅ Prise de terre mise à jour: ${priseTerre.identification}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updatePriseTerre: $e');
    return false;
  }
}

/// Supprimer une prise de terre
static Future<bool> deletePriseTerre({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.prisesTerre.length) {
      final pt = mesures.prisesTerre.removeAt(index);
      await saveMesuresEssais(mesures);
      print('✅ Prise de terre supprimée: ${pt.identification}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur deletePriseTerre: $e');
    return false;
  }
}

/// Récupérer toutes les prises de terre d'une mission
static List<PriseTerre> getPrisesTerre(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.prisesTerre ?? [];
}

// ============================================================
//          SECTION 5: AVIS SUR LES MESURES
// ============================================================

/// Mettre à jour l'avis sur les mesures
static Future<bool> updateAvisMesuresTerre({
  required String missionId,
  String? observation,
  List<String>? satisfaisants,
  List<String>? nonSatisfaisants,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    
    if (observation != null) {
      mesures.avisMesuresTerre.observation = observation;
    }
    
    if (satisfaisants != null) {
      mesures.avisMesuresTerre.satisfaisants = satisfaisants;
    }
    
    if (nonSatisfaisants != null) {
      mesures.avisMesuresTerre.nonSatisfaisants = nonSatisfaisants;
    }
    
    await saveMesuresEssais(mesures);
    print('✅ Avis sur les mesures mis à jour');
    return true;
  } catch (e) {
    print('❌ Erreur updateAvisMesuresTerre: $e');
    return false;
  }
}

// ============================================================
//          SECTION 6: ESSAIS DÉCLENCHEMENT DIFFÉRENTIELS
// ============================================================

/// Ajouter un essai de déclenchement différentiel
static Future<bool> addEssaiDeclenchement({
  required String missionId,
  required EssaiDeclenchementDifferentiel essai,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.essaisDeclenchement.add(essai);
    await saveMesuresEssais(mesures);
    print('✅ Essai déclenchement ajouté: ${essai.designationCircuit}');
    return true;
  } catch (e) {
    print('❌ Erreur addEssaiDeclenchement: $e');
    return false;
  }
}

/// Mettre à jour un essai de déclenchement différentiel existant
static Future<bool> updateEssaiDeclenchement({
  required String missionId,
  required int index,
  required EssaiDeclenchementDifferentiel essai,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.essaisDeclenchement.length) {
      mesures.essaisDeclenchement[index] = essai;
      await saveMesuresEssais(mesures);
      print('✅ Essai déclenchement mis à jour: ${essai.designationCircuit}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateEssaiDeclenchement: $e');
    return false;
  }
}

/// Supprimer un essai de déclenchement différentiel
static Future<bool> deleteEssaiDeclenchement({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.essaisDeclenchement.length) {
      final essai = mesures.essaisDeclenchement.removeAt(index);
      await saveMesuresEssais(mesures);
      print('✅ Essai déclenchement supprimé: ${essai.designationCircuit}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur deleteEssaiDeclenchement: $e');
    return false;
  }
}

/// Récupérer tous les essais de déclenchement d'une mission
static List<EssaiDeclenchementDifferentiel> getEssaisDeclenchement(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.essaisDeclenchement ?? [];
}

/// Récupérer les localisations disponibles depuis l'audit pour les essais
static List<String> getLocalisationsForEssais(String missionId) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];
  
  final localisations = <String>[];
  
  // Locaux moyenne tension
  for (var local in audit.moyenneTensionLocaux) {
    localisations.add(local.nom);
  }
  
  // Zones moyenne tension
  for (var zone in audit.moyenneTensionZones) {
    localisations.add(zone.nom);
  }
  
  // Zones basse tension
  for (var zone in audit.basseTensionZones) {
    localisations.add(zone.nom);
    // Locaux dans les zones
    for (var local in zone.locaux) {
      localisations.add('${zone.nom} - ${local.nom}');
    }
  }
  
  // Ajouter aussi les classements existants
  final classements = getEmplacementsByMissionId(missionId);
  for (var classement in classements) {
    if (!localisations.contains(classement.localisation)) {
      localisations.add(classement.localisation);
    }
  }
  
  return localisations;
}

/// Récupérer les coffrets pour une localisation spécifique
static List<String> getCoffretsForLocalisation(String missionId, String localisation) {
  final audit = getAuditInstallationsByMissionId(missionId);
  if (audit == null) return [];
  
  final coffrets = <String>[];
  
  // Chercher dans tous les locaux et zones
  // (Cette méthode pourrait être améliorée selon votre structure exacte)
  for (var local in audit.moyenneTensionLocaux) {
    if (local.nom == localisation || localisation.contains(local.nom)) {
      for (var coffret in local.coffrets) {
        coffrets.add(coffret.nom);
      }
    }
  }
  
  for (var zone in audit.moyenneTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffrets) {
        coffrets.add(coffret.nom);
      }
    }
  }
  
  for (var zone in audit.basseTensionZones) {
    if (zone.nom == localisation || localisation.contains(zone.nom)) {
      for (var coffret in zone.coffretsDirects) {
        coffrets.add(coffret.nom);
      }
      for (var local in zone.locaux) {
        if (localisation.contains(local.nom)) {
          for (var coffret in local.coffrets) {
            coffrets.add(coffret.nom);
          }
        }
      }
    }
  }
  
  return coffrets;
}

// ============================================================
//          SECTION 7: CONTINUITÉ ET RÉSISTANCE
// ============================================================

/// Ajouter une mesure de continuité et résistance
static Future<bool> addContinuiteResistance({
  required String missionId,
  required ContinuiteResistance mesure,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    mesures.continuiteResistances.add(mesure);
    await saveMesuresEssais(mesures);
    print('✅ Continuité/résistance ajoutée: ${mesure.designationTableau}');
    return true;
  } catch (e) {
    print('❌ Erreur addContinuiteResistance: $e');
    return false;
  }
}

/// Mettre à jour une mesure de continuité et résistance existante
static Future<bool> updateContinuiteResistance({
  required String missionId,
  required int index,
  required ContinuiteResistance mesure,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.continuiteResistances.length) {
      mesures.continuiteResistances[index] = mesure;
      await saveMesuresEssais(mesures);
      print('✅ Continuité/résistance mise à jour: ${mesure.designationTableau}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur updateContinuiteResistance: $e');
    return false;
  }
}

/// Supprimer une mesure de continuité et résistance
static Future<bool> deleteContinuiteResistance({
  required String missionId,
  required int index,
}) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    if (index < mesures.continuiteResistances.length) {
      final mesure = mesures.continuiteResistances.removeAt(index);
      await saveMesuresEssais(mesures);
      print('✅ Continuité/résistance supprimée: ${mesure.designationTableau}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur deleteContinuiteResistance: $e');
    return false;
  }
}

/// Récupérer toutes les mesures de continuité et résistance d'une mission
static List<ContinuiteResistance> getContinuiteResistances(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  return mesures?.continuiteResistances ?? [];
}

// ============================================================
//          MÉTHODES UTILITAIRES MESURES ESSAIS
// ============================================================

/// Obtenir les options pour les types de dispositifs différentiels
static List<String> getTypesDispositifDifferentiel() {
  return ['DDR', 'RD', 'IDR'];
}

/// Obtenir les options pour les résultats d'essai
static List<String> getResultatsEssai() {
  return ['OK', 'NON OK', 'NE'];
}

/// Obtenir les options pour les statuts des prises de terre
static List<String> getStatutsPriseTerre() {
  return ['Satisfaisant', 'Non satisfaisant', 'Non accessible'];
}

/// Obtenir les options pour les statuts de continuité
static List<String> getStatutsContinuite() {
  return ['Conforme', 'Non conforme'];
}

/// Obtenir les natures de prise de terre courantes
static List<String> getNaturesPriseTerre() {
  return [
    'Boucle en fond de fouille',
    'Piquet de terre',
    'Plaque de terre',
    'Fond de fouille interconnecté',
    'Autre',
  ];
}

/// Obtenir les méthodes de mesure courantes
static List<String> getMethodesMesure() {
  return [
    'Impédance de boucle',
    'Résistance de terre',
    'Méthode des 62%',
    'Méthode de chute de potentiel',
    'Autre',
  ];
}

/// Supprimer toutes les mesures et essais d'une mission
static Future<bool> deleteAllMesuresEssaisForMission(String missionId) async {
  try {
    final mesures = getMesuresEssaisByMissionId(missionId);
    if (mesures != null) {
      await mesures.delete();
      
      // Supprimer la référence dans la mission
      final missionBox = Hive.box<Mission>(_missionBox);
      final mission = missionBox.get(missionId);
      if (mission != null) {
        mission.mesuresEssaisId = null;
        await mission.save();
      }
      
      print('✅ Toutes les mesures et essais supprimés pour mission $missionId');
      return true;
    }
    return true; // Aucune donnée à supprimer
  } catch (e) {
    print('❌ Erreur deleteAllMesuresEssaisForMission: $e');
    return false;
  }
}

/// Vérifier si les mesures et essais sont complets
static Map<String, bool> checkMesuresEssaisCompletion(String missionId) {
  final mesures = getMesuresEssaisByMissionId(missionId);
  if (mesures == null) {
    return {
      'condition_mesure': false,
      'demarrage_auto': false,
      'arret_urgence': false,
      'prises_terre': false,
      'avis_mesures': false,
      'essais_differ': false,
      'continuites': false,
    };
  }
  
  final stats = mesures.calculerStatistiques();
  
  return {
    'condition_mesure': stats['condition_mesure_renseignee'] as bool,
    'demarrage_auto': stats['demarrage_auto_renseigne'] as bool,
    'arret_urgence': stats['arret_urgence_renseigne'] as bool,
    'prises_terre': (mesures.prisesTerre.isNotEmpty),
    'avis_mesures': stats['avis_mesures_renseigne'] as bool,
    'essais_differ': (mesures.essaisDeclenchement.isNotEmpty),
    'continuites': (mesures.continuiteResistances.isNotEmpty),
  };
}

/// Obtenir le pourcentage de complétion global
static int getMesuresEssaisCompletionPercentage(String missionId) {
  final completion = checkMesuresEssaisCompletion(missionId);
  final sections = completion.values;
  final completed = sections.where((isComplete) => isComplete).length;
  
  return (completed / sections.length * 100).round();
}

/// Écouter les changements dans les mesures et essais d'une mission
static ValueListenable<Box<MesuresEssais>> watchMesuresEssais(String missionId) {
  final box = Hive.box<MesuresEssais>(_mesuresEssaisBox);
  return box.listenable();
}

/// Créer des données de test pour une mission
static Future<void> createTestMesuresEssais(String missionId) async {
  try {
    final mesures = await getOrCreateMesuresEssais(missionId);
    
    // Ajouter quelques prises de terre d'exemple
    mesures.prisesTerre.addAll([
      PriseTerre(
        localisation: 'Extérieur',
        identification: 'PT1',
        conditionMesure: '-',
        naturePriseTerre: 'Boucle en fond de fouille',
        methodeMesure: 'Impédance de boucle',
        valeurMesure: 10.93,
        observation: 'Satisfaisant',
      ),
      PriseTerre(
        localisation: 'Local GE',
        identification: 'PT3',
        conditionMesure: '-',
        naturePriseTerre: 'Boucle en fond de fouille',
        methodeMesure: 'Impédance de boucle',
        valeurMesure: 187.5,
        observation: 'Non satisfaisant',
      ),
    ]);
    
    // Mettre à jour automatiquement l'avis
    mesures.avisMesuresTerre.observation = 'Prévoir un plan d\'exécution\nRenforcer l\'interconnexion avec le réseau de fond de fouille';
    
    // Ajouter quelques essais différentiels
    final localisations = getLocalisationsForEssais(missionId);
    if (localisations.isNotEmpty) {
      mesures.essaisDeclenchement.add(
        EssaiDeclenchementDifferentiel(
          localisation: localisations.first,
          designationCircuit: 'Circuit éclairage bureau',
          typeDispositif: 'DDR',
          reglageIAn: 30,
          tempo: 0.3,
          isolement: 500,
          essai: 'B',
          observation: 'Bon fonctionnement',
        ),
      );
    }
    
    await saveMesuresEssais(mesures);
    print('✅ Données de test créées pour mesures et essais');
  } catch (e) {
    print('❌ Erreur createTestMesuresEssais: $e');
  }
}

// ============================================================
//          GESTION OBSERVATIONS LIBRES AVEC PHOTOS
// ============================================================

/// Ajouter une observation libre avec photos à un local moyenne tension
static Future<bool> addObservationToMoyenneTensionLocal({
  required String missionId,
  required int localIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (localIndex < audit.moyenneTensionLocaux.length) {
      final local = audit.moyenneTensionLocaux[localIndex];
      local.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      print('✅ Observation ajoutée au local MT: ${local.nom}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addObservationToMoyenneTensionLocal: $e');
    return false;
  }
}

/// Ajouter une observation libre avec photos à une zone moyenne tension
static Future<bool> addObservationToMoyenneTensionZone({
  required String missionId,
  required int zoneIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.moyenneTensionZones.length) {
      final zone = audit.moyenneTensionZones[zoneIndex];
      zone.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      print('✅ Observation ajoutée à la zone MT: ${zone.nom}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addObservationToMoyenneTensionZone: $e');
    return false;
  }
}

/// Ajouter une observation libre avec photos à une zone basse tension
static Future<bool> addObservationToBasseTensionZone({
  required String missionId,
  required int zoneIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      zone.observationsLibres.add(ObservationLibre(
        texte: texte,
        photos: photos ?? [],
      ));
      await saveAuditInstallations(audit);
      print('✅ Observation ajoutée à la zone BT: ${zone.nom}');
      return true;
    }
    return false;
  } catch (e) {
    print('❌ Erreur addObservationToBasseTensionZone: $e');
    return false;
  }
}

/// Ajouter une observation libre avec photos à un local basse tension
static Future<bool> addObservationToBasseTensionLocal({
  required String missionId,
  required int zoneIndex,
  required int localIndex,
  required String texte,
  List<String>? photos,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    if (zoneIndex < audit.basseTensionZones.length) {
      final zone = audit.basseTensionZones[zoneIndex];
      if (localIndex < zone.locaux.length) {
        final local = zone.locaux[localIndex];
        local.observationsLibres.add(ObservationLibre(
          texte: texte,
          photos: photos ?? [],
        ));
        await saveAuditInstallations(audit);
        print('✅ Observation ajoutée au local BT: ${local.nom}');
        return true;
      }
    }
    return false;
  } catch (e) {
    print('❌ Erreur addObservationToBasseTensionLocal: $e');
    return false;
  }
}

/// Ajouter une observation libre avec photos à un coffret/armoire
static Future<bool> addObservationToCoffret({
  required String missionId,
  required CoffretArmoire coffret,
  required String texte,
  List<String>? photos,
}) async {
  try {
    // Chercher le coffret dans l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher dans les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      final index = local.coffrets.indexWhere((c) => c.nom== coffret.nom && c.type == coffret.type);
      if (index != -1) {
        local.coffrets[index].observationsLibres.add(ObservationLibre(
          texte: texte,
          photos: photos ?? [],
        ));
        found = true;
        break;
      }
    }
    
    // Chercher dans les zones MT
    if (!found) {
      for (var zone in audit.moyenneTensionZones) {
        final index = zone.coffrets.indexWhere((c) => c.nom == coffret.nom && c.type == coffret.type);
        if (index != -1) {
          zone.coffrets[index].observationsLibres.add(ObservationLibre(
            texte: texte,
            photos: photos ?? [],
          ));
          found = true;
          break;
        }
      }
    }
    
    // Chercher dans les zones BT (coffrets directs)
    if (!found) {
      for (var zone in audit.basseTensionZones) {
        final index = zone.coffretsDirects.indexWhere((c) => c.nom == coffret.nom && c.type == coffret.type);
        if (index != -1) {
          zone.coffretsDirects[index].observationsLibres.add(ObservationLibre(
            texte: texte,
            photos: photos ?? [],
          ));
          found = true;
          break;
        }
        
        // Chercher dans les locaux BT
        for (var local in zone.locaux) {
          final index = local.coffrets.indexWhere((c) => c.nom == coffret.nom && c.type == coffret.type);
          if (index != -1) {
            local.coffrets[index].observationsLibres.add(ObservationLibre(
              texte: texte,
              photos: photos ?? [],
            ));
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      print('✅ Observation ajoutée au coffret: ${coffret.nom}');
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erreur addObservationToCoffret: $e');
    return false;
  }
}

/// Mettre à jour une observation libre existante
static Future<bool> updateObservationLibre({
  required String missionId,
  required ObservationLibre observation,
  required String newTexte,
  List<String>? newPhotos,
}) async {
  try {
    observation.updateTexte(newTexte);
    if (newPhotos != null) {
      observation.photos = newPhotos;
    }
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    print('✅ Observation mise à jour');
    return true;
  } catch (e) {
    print('❌ Erreur updateObservationLibre: $e');
    return false;
  }
}

/// Supprimer une observation libre d'un local/zone/coffret
static Future<bool> deleteObservationLibre({
  required String missionId,
  required dynamic parent, // Peut être MoyenneTensionLocal, MoyenneTensionZone, etc.
  required ObservationLibre observation,
}) async {
  try {
    if (parent is MoyenneTensionLocal) {
      parent.observationsLibres.remove(observation);
    } else if (parent is MoyenneTensionZone) {
      parent.observationsLibres.remove(observation);
    } else if (parent is BasseTensionZone) {
      parent.observationsLibres.remove(observation);
    } else if (parent is BasseTensionLocal) {
      parent.observationsLibres.remove(observation);
    } else if (parent is CoffretArmoire) {
      parent.observationsLibres.remove(observation);
    } else {
      print('❌ Type de parent non supporté');
      return false;
    }
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    print('✅ Observation supprimée');
    return true;
  } catch (e) {
    print('❌ Erreur deleteObservationLibre: $e');
    return false;
  }
}

/// Ajouter une photo à une observation existante
static Future<bool> addPhotoToObservation({
  required String missionId,
  required ObservationLibre observation,
  required String cheminPhoto,
}) async {
  try {
    observation.addPhoto(cheminPhoto);
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    print('✅ Photo ajoutée à l\'observation');
    return true;
  } catch (e) {
    print('❌ Erreur addPhotoToObservation: $e');
    return false;
  }
}

/// Supprimer une photo d'une observation
static Future<bool> removePhotoFromObservation({
  required String missionId,
  required ObservationLibre observation,
  required String cheminPhoto,
}) async {
  try {
    observation.removePhoto(cheminPhoto);
    
    // Sauvegarder l'audit
    final audit = await getOrCreateAuditInstallations(missionId);
    await saveAuditInstallations(audit);
    
    print('✅ Photo supprimée de l\'observation');
    return true;
  } catch (e) {
    print('❌ Erreur removePhotoFromObservation: $e');
    return false;
  }
}

/// Récupérer toutes les observations d'une mission
static List<Map<String, dynamic>> getAllObservationsForMission(String missionId) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return [];
    
    final observations = <Map<String, dynamic>>[];
    
    // Collecter les observations des locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      for (var obs in local.observationsLibres) {
        observations.add({
          'type': 'localMT',
          'entityName': local.nom,
          'entityType': local.type,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var obs in zone.observationsLibres) {
        observations.add({
          'type': 'zoneMT',
          'entityName': zone.nom,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des zones BT
    for (var zone in audit.basseTensionZones) {
      for (var obs in zone.observationsLibres) {
        observations.add({
          'type': 'zoneBT',
          'entityName': zone.nom,
          'observation': obs,
          'photos': obs.photos,
          'dateCreation': obs.dateCreation,
          'dateModification': obs.dateModification,
        });
      }
    }
    
    // Collecter les observations des locaux BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        for (var obs in local.observationsLibres) {
          observations.add({
            'type': 'localBT',
            'entityName': '${zone.nom} - ${local.nom}',
            'zoneName': zone.nom,
            'localName': local.nom,
            'observation': obs,
            'photos': obs.photos,
            'dateCreation': obs.dateCreation,
            'dateModification': obs.dateModification,
          });
        }
      }
    }
    
    // Collecter les observations des coffrets
    // (à implémenter si nécessaire)
    
    return observations;
  } catch (e) {
    print('❌ Erreur getAllObservationsForMission: $e');
    return [];
  }
}

/// Obtenir les statistiques des observations pour une mission
static Map<String, dynamic> getObservationStats(String missionId) {
  final allObservations = getAllObservationsForMission(missionId);
  
  final total = allObservations.length;
  final avecPhotos = allObservations.where((obs) => (obs['photos'] as List<String>).isNotEmpty).length;
  
  // Compter par type d'entité
  final byType = {
    'localMT': allObservations.where((obs) => obs['type'] == 'localMT').length,
    'zoneMT': allObservations.where((obs) => obs['type'] == 'zoneMT').length,
    'zoneBT': allObservations.where((obs) => obs['type'] == 'zoneBT').length,
    'localBT': allObservations.where((obs) => obs['type'] == 'localBT').length,
  };
  
  return {
    'total': total,
    'avec_photos': avecPhotos,
    'sans_photos': total - avecPhotos,
    'par_type': byType,
    'pourcentage_avec_photos': total > 0 ? (avecPhotos / total * 100).round() : 0,
  };
}

/// Convertir les anciennes observations (String) en nouvelles (ObservationLibre)
static Future<bool> migrateOldObservations(String missionId) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool migrated = false;
    
    // Migrer les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      // Vérifier si c'est l'ancien type (List<String>)
      if (local.observationsLibres is List<String>) {
        final oldObservations = local.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        local.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les zones MT
    for (var zone in audit.moyenneTensionZones) {
      if (zone.observationsLibres is List<String>) {
        final oldObservations = zone.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        zone.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les zones BT
    for (var zone in audit.basseTensionZones) {
      if (zone.observationsLibres is List<String>) {
        final oldObservations = zone.observationsLibres as List<String>;
        final newObservations = <ObservationLibre>[];
        
        for (var text in oldObservations) {
          newObservations.add(ObservationLibre(texte: text));
        }
        
        zone.observationsLibres = newObservations;
        migrated = true;
      }
    }
    
    // Migrer les locaux BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        if (local.observationsLibres is List<String>) {
          final oldObservations = local.observationsLibres as List<String>;
          final newObservations = <ObservationLibre>[];
          
          for (var text in oldObservations) {
            newObservations.add(ObservationLibre(texte: text));
          }
          
          local.observationsLibres = newObservations;
          migrated = true;
        }
      }
    }
    
    // Migrer les coffrets
    // (à implémenter si nécessaire)
    
    if (migrated) {
      await saveAuditInstallations(audit);
      print('✅ Anciennes observations migrées pour mission $missionId');
    } else {
      print('✅ Aucune migration nécessaire');
    }
    
    return true;
  } catch (e) {
    print('❌ Erreur migrateOldObservations: $e');
    return false;
  }
}

// ============================================================
//          GESTION PHOTOS DES ÉLÉMENTS DE CONTRÔLE
// ============================================================

/// Ajouter une photo à un élément de contrôle spécifique
static Future<bool> addPhotoToElementControle({
  required String missionId,
  required String localisation, // Nom du local ou zone
  required int elementIndex,
  required String cheminPhoto,
  required String sectionType, // 'dispositions', 'conditions', 'cellule', 'transformateur'
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher le local par son nom
    for (var local in audit.moyenneTensionLocaux) {
      if (local.nom == localisation) {
        found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
        break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones MT
      for (var zone in audit.moyenneTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones BT
      for (var zone in audit.basseTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _processElementPhotos(local, elementIndex, cheminPhoto, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      print('✅ Photo ajoutée à l\'élément $elementIndex');
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erreur addPhotoToElementControle: $e');
    return false;
  }
}

/// Traiter les photos pour un élément spécifique
static bool _processElementPhotos(
  dynamic local, // MoyenneTensionLocal ou BasseTensionLocal
  int elementIndex,
  String cheminPhoto,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length) {
    elements[elementIndex].photos.add(cheminPhoto);
    return true;
  }
  
  return false;
}

/// Supprimer une photo d'un élément de contrôle
static Future<bool> removePhotoFromElementControle({
  required String missionId,
  required String localisation,
  required int elementIndex,
  required int photoIndex,
  required String sectionType,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    bool found = false;
    
    // Chercher le local par son nom
    for (var local in audit.moyenneTensionLocaux) {
      if (local.nom == localisation) {
        found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
        break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones MT
      for (var zone in audit.moyenneTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (!found) {
      // Chercher dans les zones BT
      for (var zone in audit.basseTensionZones) {
        for (var local in zone.locaux) {
          if (local.nom == localisation) {
            found = _removeElementPhoto(local, elementIndex, photoIndex, sectionType);
            break;
          }
        }
        if (found) break;
      }
    }
    
    if (found) {
      await saveAuditInstallations(audit);
      print('✅ Photo supprimée de l\'élément $elementIndex');
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erreur removePhotoFromElementControle: $e');
    return false;
  }
}

static bool _removeElementPhoto(
  dynamic local,
  int elementIndex,
  int photoIndex,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length && 
      photoIndex < elements[elementIndex].photos.length) {
    elements[elementIndex].photos.removeAt(photoIndex);
    return true;
  }
  
  return false;
}

/// Récupérer toutes les photos des éléments non conformes pour une mission
static List<Map<String, dynamic>> getAllElementPhotos(String missionId) {
  try {
    final audit = getAuditInstallationsByMissionId(missionId);
    if (audit == null) return [];
    
    final allPhotos = <Map<String, dynamic>>[];
    
    // Fonction pour collecter les photos
    void collectPhotos(List<ElementControle> elements, String source, String type) {
      for (int i = 0; i < elements.length; i++) {
        final element = elements[i];
        if (element.photos.isNotEmpty) {
          allPhotos.add({
            'element': element.elementControle,
            'photos': element.photos,
            'conforme': element.conforme,
            'priorite': element.priorite,
            'observation': element.observation,
            'source': source,
            'type': type,
            'elementIndex': i,
          });
        }
      }
    }
    
    // Parcourir tous les locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      collectPhotos(local.dispositionsConstructives, local.nom, 'dispositions_mt');
      collectPhotos(local.conditionsExploitation, local.nom, 'conditions_mt');
      
      if (local.cellule != null) {
        collectPhotos(local.cellule!.elementsVerifies, local.nom, 'cellule_mt');
      }
      
      if (local.transformateur != null) {
        collectPhotos(local.transformateur!.elementsVerifies, local.nom, 'transformateur_mt');
      }
    }
    
    // Parcourir les zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        collectPhotos(local.dispositionsConstructives, '${zone.nom}/${local.nom}', 'dispositions_mt_zone');
        collectPhotos(local.conditionsExploitation, '${zone.nom}/${local.nom}', 'conditions_mt_zone');
      }
    }
    
    // Parcourir les zones BT
    for (var zone in audit.basseTensionZones) {
      for (var local in zone.locaux) {
        collectPhotos(local.dispositionsConstructives!, '${zone.nom}/${local.nom}', 'dispositions_bt');
        collectPhotos(local.conditionsExploitation!, '${zone.nom}/${local.nom}', 'conditions_bt');
      }
    }
    
    return allPhotos;
  } catch (e) {
    print('❌ Erreur getAllElementPhotos: $e');
    return [];
  }
}

/// Obtenir les statistiques des photos
static Map<String, dynamic> getElementPhotosStats(String missionId) {
  final allPhotos = getAllElementPhotos(missionId);
  
  int totalPhotos = 0;
  final photosByType = <String, int>{};
  final nonConformeWithPhotos = allPhotos.where((p) => p['conforme'] == false).length;
  
  for (var item in allPhotos) {
    final photos = item['photos'] as List<String>;
    totalPhotos += photos.length;
    
    final type = item['type'] as String;
    photosByType[type] = (photosByType[type] ?? 0) + photos.length;
  }
  
  return {
    'total_elements_avec_photos': allPhotos.length,
    'total_photos': totalPhotos,
    'elements_non_conforme_avec_photos': nonConformeWithPhotos,
    'photos_par_type': photosByType,
  };
}

/// Sauvegarder un élément avec ses photos
static Future<void> saveElementWithPhotos({
  required String missionId,
  required String localisation,
  required ElementControle element,
  required int elementIndex,
  required String sectionType,
}) async {
  try {
    final audit = await getOrCreateAuditInstallations(missionId);
    
    // Chercher et mettre à jour l'élément
    bool updated = _updateElementInAudit(audit, localisation, element, elementIndex, sectionType);
    
    if (updated) {
      await saveAuditInstallations(audit);
      print('✅ Élément avec photos sauvegardé');
    }
  } catch (e) {
    print('❌ Erreur saveElementWithPhotos: $e');
    rethrow;
  }
}

static bool _updateElementInAudit(
  AuditInstallationsElectriques audit,
  String localisation,
  ElementControle element,
  int elementIndex,
  String sectionType,
) {
  // Chercher dans tous les locaux MT
  for (var local in audit.moyenneTensionLocaux) {
    if (local.nom == localisation) {
      return _replaceElement(local, element, elementIndex, sectionType);
    }
  }
  
  // Chercher dans les zones MT
  for (var zone in audit.moyenneTensionZones) {
    for (var local in zone.locaux) {
      if (local.nom == localisation) {
        return _replaceElement(local, element, elementIndex, sectionType);
      }
    }
  }
  
  // Chercher dans les zones BT
  for (var zone in audit.basseTensionZones) {
    for (var local in zone.locaux) {
      if (local.nom == localisation) {
        return _replaceElement(local, element, elementIndex, sectionType);
      }
    }
  }
  
  return false;
}

static bool _replaceElement(
  dynamic local,
  ElementControle element,
  int elementIndex,
  String sectionType,
) {
  List<ElementControle> elements;
  
  switch (sectionType) {
    case 'dispositions':
      elements = local.dispositionsConstructives;
      break;
    case 'conditions':
      elements = local.conditionsExploitation;
      break;
    case 'cellule':
      if (local is MoyenneTensionLocal && local.cellule != null) {
        elements = local.cellule!.elementsVerifies;
      } else {
        return false;
      }
      break;
    case 'transformateur':
      if (local is MoyenneTensionLocal && local.transformateur != null) {
        elements = local.transformateur!.elementsVerifies;
      } else {
        return false;
      }
      break;
    default:
      return false;
  }
  
  if (elementIndex < elements.length) {
    elements[elementIndex] = element;
    return true;
  }
  
  return false;
}

// ============================================================
//          GESTION CLASSEMENT POUR UN LOCAL SPÉCIFIQUE
// ============================================================

/// Créer ou récupérer le classement pour un local spécifique
static Future<ClassementEmplacement> getOrCreateClassementForLocal({
  required String missionId,
  required String localisation,
  String? zone,
  String? typeLocal,
}) async {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    // Méthode 1: Chercher manuellement sans firstWhere
    ClassementEmplacement? existing;
    
    // Parcourir tous les classements pour trouver celui qui correspond
    for (var classement in classementBox.values) {
      if (classement.missionId == missionId && classement.localisation == localisation) {
        existing = classement;
        break;
      }
    }
    
    if (existing != null) {
      // Mettre à jour les informations si elles ont changé
      if (zone != null && existing.zone != zone) {
        existing.zone = zone;
      }
      if (typeLocal != null && existing.typeLocal != typeLocal) {
        existing.typeLocal = typeLocal;
      }
      if (zone != null || typeLocal != null) {
        existing.updatedAt = DateTime.now();
        await existing.save();
      }
      
      print('✅ Classement existant trouvé pour: $localisation');
      return existing;
    } else {
      // Créer un nouveau classement
      final newClassement = ClassementEmplacement.create(
        missionId: missionId,
        localisation: localisation,
        zone: zone,
        typeLocal: typeLocal,
      );
      await classementBox.add(newClassement);
      print('✅ Nouveau classement créé pour: $localisation');
      return newClassement;
    }
    
  } catch (e) {
    print('❌ Erreur getOrCreateClassementForLocal: $e');
    // En cas d'erreur, créer une nouvelle instance
    final newClassement = ClassementEmplacement.create(
      missionId: missionId,
      localisation: localisation,
      zone: zone,
      typeLocal: typeLocal,
    );
    await classementBox.add(newClassement);
    return newClassement;
  }
}

/// Méthode plus simple pour récupérer seulement (pas de création)
static ClassementEmplacement? getClassementForLocal({
  required String missionId,
  required String localisation,
}) {
  final classementBox = Hive.box<ClassementEmplacement>(_classementBox);
  
  try {
    return classementBox.values.firstWhere(
      (c) => c.missionId == missionId && c.localisation == localisation,
    );
  } catch (e) {
    return null;
  }
}

/// Mettre à jour uniquement les informations de zone/type d'un classement existant
static Future<bool> updateClassementInfo({
  required String missionId,
  required String localisation,
  String? zone,
  String? typeLocal,
}) async {
  try {
    final classement = getClassementForLocal(
      missionId: missionId,
      localisation: localisation,
    );
    
    if (classement != null) {
      if (zone != null) classement.zone = zone;
      if (typeLocal != null) classement.typeLocal = typeLocal;
      
      if (zone != null || typeLocal != null) {
        classement.updatedAt = DateTime.now();
        await classement.save();
        print('✅ Informations classement mises à jour pour: $localisation');
      }
      return true;
    }
    
    return false;
  } catch (e) {
    print('❌ Erreur updateClassementInfo: $e');
    return false;
  }
}
/// Récupérer un classement existant sans en créer un nouveau
static ClassementEmplacement? getClassementExisting({
  required String missionId,
  required String localisation,
}) {
  try {
    final box = Hive.box<ClassementEmplacement>(_classementBox);
    return box.values.firstWhere(
      (c) => c.missionId == missionId && c.localisation == localisation,
    );
  } catch (e) {
    return null;
  }
}

// ============================================================
//          GESTION RENSEIGNEMENTS GENERAUX
// ============================================================

/// Créer ou récupérer les renseignements généraux pour une mission
// lib/services/hive_service.dart

// Dans getOrCreateRenseignementsGeneraux, ajouter la synchronisation :

/// Créer ou récupérer les renseignements généraux pour une mission
static Future<RenseignementsGeneraux> getOrCreateRenseignementsGeneraux(String missionId) async {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  
  try {
    // Chercher si des renseignements existent déjà pour cette mission
    final existing = box.values.firstWhere((r) => r.missionId == missionId);
    return existing;
  } catch (e) {
    // Aucun renseignement trouvé, on crée une nouvelle instance
    final mission = getMissionById(missionId);
    final newData = RenseignementsGeneraux.create(missionId);
    
    // ✅ PRÉREMPLISSAGE AUTOMATIQUE depuis la mission
    if (mission != null) {
      // Correspondance : Mission.nomClient → RenseignementsGeneraux.etablissement
      newData.etablissement = mission.nomClient;
      
      // Correspondance : Mission.activiteClient → RenseignementsGeneraux.activite
      newData.activite = mission.activiteClient ?? '';
      
      // Correspondance : Mission.nomSite → RenseignementsGeneraux.nomSite
      newData.nomSite = mission.nomSite ?? '';
      
      // Correspondance : Mission.natureMission → RenseignementsGeneraux.verificationType
      // On garde la même valeur mais on peut aussi mapper si les noms diffèrent
      newData.verificationType = mission.natureMission;
      
      // Optionnel : préremplir l'installation avec le nom du site aussi
      newData.installation = mission.nomSite ?? '';
    }
    
    await box.add(newData);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final missionToUpdate = missionBox.get(missionId);
    if (missionToUpdate != null) {
      missionToUpdate.renseignementsGenerauxId = newData.key.toString();
      await missionToUpdate.save();
    }
    
    print('✅ RenseignementsGeneraux créé et prérempli pour mission: $missionId');
    return newData;
  }
}

/// Sauvegarder les renseignements généraux
static Future<void> saveRenseignementsGeneraux(RenseignementsGeneraux data) async {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  data.updatedAt = DateTime.now();
  await data.save();
  print('✅ Renseignements généraux sauvegardés pour mission ${data.missionId}');
}

/// Récupérer les renseignements généraux par missionId
static RenseignementsGeneraux? getRenseignementsGenerauxByMissionId(String missionId) {
  final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
  try {
    return box.values.firstWhere((r) => r.missionId == missionId);
  } catch (e) {
    return null;
  }
}

// ============================================================
//          GESTION PREFERENCE MOYENNE TENSION
// ============================================================

static const String _mtPreferenceBox = 'mt_preference';

/// Sauvegarder la préférence MT pour une mission
static Future<void> saveMoyenneTensionPreference(String missionId, bool isApplicable) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  await box.put(missionId, {
    'isApplicable': isApplicable,
    'timestamp': DateTime.now().toIso8601String(),
  });
  print('✅ Préférence MT sauvegardée pour mission $missionId: $isApplicable');
}

/// Vérifier si la préférence MT a déjà été définie
static Future<bool> hasMoyenneTensionPreference(String missionId) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  return box.containsKey(missionId);
}

/// Récupérer la préférence MT
static Future<bool> isMoyenneTensionApplicable(String missionId) async {
  final box = await Hive.openBox(_mtPreferenceBox);
  final data = box.get(missionId);
  if (data != null && data is Map) {
    return data['isApplicable'] ?? true;
  }
  return true; // Par défaut applicable
}

// Méthodes JSA
static Future<JSA> getOrCreateJSA(String missionId) async {
  final box = Hive.box<JSA>(_jsaBox);
  
  try {
    final existing = box.values.firstWhere((jsa) => jsa.missionId == missionId);
    return existing;
  } catch (e) {
    final newJSA = JSA.create(missionId);
    await box.add(newJSA);
    
    // Mettre à jour la référence dans la mission
    final missionBox = Hive.box<Mission>(_missionBox);
    final mission = missionBox.get(missionId);
    if (mission != null) {
      mission.jsaId = newJSA.key.toString();
      await mission.save();
    }
    
    return newJSA;
  }
}

static Future<void> saveJSA(JSA jsa) async {
  jsa.updatedAt = DateTime.now();
  await jsa.save();
}

static JSA? getJSAByMissionId(String missionId) {
  final box = Hive.box<JSA>(_jsaBox);
  try {
    return box.values.firstWhere((jsa) => jsa.missionId == missionId);
  } catch (e) {
    return null;
  }
}

// ===== MÉTHODES POUR LES BROUILLONS DE COFFRET =====
  
  /// Sauvegarder un brouillon de coffret
  static Future<void> saveCoffretDraft({
    required String missionId,
    required String parentType,
    required int parentIndex,
    required bool isMoyenneTension,
    required int? zoneIndex,
    required CoffretArmoire coffret,
    required int currentStep,
  }) async {
    final box = Hive.box<Map>(_coffretDraftsBox);
    
    String draftKey = coffret.qrCode;
    if (draftKey.isEmpty) {
      draftKey = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
      coffret.qrCode = draftKey;
    }
    
    // Ajouter les métadonnées de localisation dans une Map
    final draftData = {
      'coffret': coffret,
      'currentStep': currentStep,
      'missionId': missionId,
      'parentType': parentType,
      'parentIndex': parentIndex,
      'isMoyenneTension': isMoyenneTension,
      'zoneIndex': zoneIndex,
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    await box.put(draftKey, draftData);
    print('✅ Brouillon sauvegardé: $draftKey (step $currentStep)');
  }

  /// Récupérer les données complètes du brouillon
  static Map<String, dynamic>? getCoffretDraftData(String qrCode) {
    final box = Hive.box<Map>(_coffretDraftsBox);
    final data = box.get(qrCode);
    
    if (data != null && data['coffret'] is CoffretArmoire) {
      return {
        'coffret': data['coffret'] as CoffretArmoire,
        'currentStep': data['currentStep'] as int? ?? 0,
        'missionId': data['missionId'] as String?,
        'parentType': data['parentType'] as String?,
        'parentIndex': data['parentIndex'] as int?,
        'isMoyenneTension': data['isMoyenneTension'] as bool?,
        'zoneIndex': data['zoneIndex'] as int?,
      };
    }
    return null;
  }

  /// Récupérer un brouillon par QR code
  static CoffretArmoire? getCoffretDraftByQrCode(String qrCode) {
    final data = getCoffretDraftData(qrCode);
    return data?['coffret'] as CoffretArmoire?;
  }

  /// Récupérer tous les brouillons pour une mission
  static List<CoffretArmoire> getAllCoffretDrafts(String missionId) {
    final box = Hive.box<Map>(_coffretDraftsBox);
    final drafts = <CoffretArmoire>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId && data['coffret'] is CoffretArmoire) {
        final coffret = data['coffret'] as CoffretArmoire;
        if (coffret.statut == 'incomplet') {
          drafts.add(coffret);
        }
      }
    }
    
    return drafts;
  }

  /// Supprimer un brouillon
  static Future<void> deleteCoffretDraft(String qrCode) async {
    final box = Hive.box<Map>(_coffretDraftsBox);
    await box.delete(qrCode);
    print('✅ Brouillon supprimé: $qrCode');
  }

  /// Récupérer les brouillons pour un emplacement spécifique
  static List<CoffretArmoire> getCoffretDraftsForLocation({
    required String missionId,
    required String parentType,
    required int parentIndex,
    required bool isMoyenneTension,
    required int? zoneIndex,
  }) {
    final box = Hive.box<Map>(_coffretDraftsBox);
    final drafts = <CoffretArmoire>[];
    
    for (var data in box.values) {
      if (data['missionId'] == missionId &&
          data['parentType'] == parentType &&
          data['parentIndex'] == parentIndex &&
          data['isMoyenneTension'] == isMoyenneTension &&
          data['zoneIndex'] == zoneIndex &&
          data['coffret'] is CoffretArmoire) {
        
        final coffret = data['coffret'] as CoffretArmoire;
        if (coffret.statut == 'incomplet') {
          drafts.add(coffret);
        }
      }
    }
    
    return drafts;
  }

}

