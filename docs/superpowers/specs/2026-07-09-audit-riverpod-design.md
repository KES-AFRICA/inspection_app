# Spécification technique : Migration des modules d'Audit vers Riverpod

Ce document décrit l'architecture et l'implémentation de la gestion d'état réactive avec Riverpod pour les trois sections de l'Audit : **Audit Installations MT/BT**, **Observations Foudre** et **Mesures & Essais**.

## 1. Objectifs
- Supprimer les appels obsolètes de `GetIt` ou la gestion d'état locale `setState` complexe dans les écrans d'audit.
- Introduire des providers d'état Riverpod distincts pour chaque sous-module afin de respecter la séparation des responsabilités.
- Assurer une persistance transparente dans la base de données SQLite/Hive existante via les Use Cases de la Clean Architecture.

---

## 2. Architecture des Providers

### A. Providers de Use Cases (Core)
Nous allons exposer les Use Cases de chaque domaine dans des fichiers de providers dédiés :
1. **audit_installations_providers.dart**
   - `getAuditInstallationsUseCaseProvider`
   - `saveAuditInstallationsUseCaseProvider`
2. **foudre_providers.dart**
   - `getFoudreObservationsUseCaseProvider`
   - `createFoudreObservationUseCaseProvider`
   - `updateFoudreObservationUseCaseProvider`
   - `deleteFoudreObservationUseCaseProvider`
3. **mesures_essais_providers.dart**
   - `getMesuresEssaisUseCaseProvider`
   - `saveMesuresEssaisUseCaseProvider`

### B. Notifiers d'État Réactifs
1. **auditInstallationsProvider** (StateNotifier indexé par `missionId`)
   - État : `AsyncValue<AuditInstallationsEntity>` (ou modèle correspondant).
   - Méthodes : `load()`, `saveAudit(AuditInstallationsEntity audit)`.
2. **foudreObservationsProvider** (StateNotifier indexé par `missionId`)
   - État : `AsyncValue<List<FoudreEntity>>` (ou modèle correspondant).
   - Méthodes : `load()`, `addObservation(FoudreEntity obs)`, `updateObservation(FoudreEntity obs)`, `deleteObservation(String id)`.
3. **mesuresEssaisProvider** (StateNotifier indexé par `missionId`)
   - État : `AsyncValue<MesuresEssaisEntity>` (ou modèle correspondant).
   - Méthodes : `load()`, `saveMesures(MesuresEssaisEntity mesures)`.

---

## 3. Stratégie de Refactoring UI
- **MoyenneTensionScreen** & **BasseTensionScreen** : Convertis en `ConsumerStatefulWidget` ou consommant `ref.watch(auditInstallationsProvider(mission.id))`. Les formulaires mettront à jour l'état réactif et déclencheront la persistance automatique en base de données.
- **FoudreScreen** : Connecté à `ref.watch(foudreObservationsProvider(mission.id))`. Toutes les opérations de création, mise à jour ou suppression d'observations mettront à jour la liste de façon réactive.
- **MesuresEssaisScreen** : Connecté à `ref.watch(mesuresEssaisProvider(mission.id))`. Les formulaires mettront à jour l'état réactif et persisteront les mesures automatiquement.

---

## 4. Plan de Validation & Non-régression
- **Analyse statique** : Exécution de `flutter analyze`.
- **Tests unitaires** : Exécution et validation de tous les tests avec `flutter test`.
- **Tests d'Intégration** : Validation du bon fonctionnement de la persistance locale en base de données sans aucune perte.
