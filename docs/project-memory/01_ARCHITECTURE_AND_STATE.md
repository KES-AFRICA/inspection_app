# 01_ARCHITECTURE_AND_STATE.md — Architecture Logicielle & Gestion d'État

> **Module** : KES Inspection App — Pilier 1  
> **Dernière révision** : 24 Septembre 2026  
> **Source de vérité** : `lib/features/`, `lib/core/`, `lib/pages/`

---

## 1. ARCHITECTURE GLOBALE DU SYSTÈME

Le projet KES Inspection App applique une **Clean Architecture modulaire orientée fonctionnalités (Feature-First)**. Chaque fonctionnalité métier est découpée de manière étanche en trois couches concentriques :

```text
┌─────────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                          │
│ Écrans (pages/), Widgets de terrain, Providers Riverpod     │
└──────────────────────────────┬──────────────────────────────┘
                               │ appelle via UseCases
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   DOMAIN LAYER                              │
│ Entités pures Dart, Interfaces Repositories, Use Cases      │
└──────────────────────────────▲──────────────────────────────┘
                               │ implémenté par
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                               │
│ RepositoriesImpl, DataSources (Hive), Mappers DTO <-> Entity│
└─────────────────────────────────────────────────────────────┘
```

### Répertoire des fonctionnalités (`lib/features/`)

| Module Feature | Rôle Métier | Emplacement Code |
|---|---|---|
| `auth` | Authentification des vérificateurs locaux, gestion de session et hachage bcrypt | `lib/features/auth/` |
| `mission` | Cycle de vie de la mission, métadonnées administratives, périmètre et documents | `lib/features/mission/` |
| `audit_installations` | Arborescence technique complète : Moyenne Tension (Locaux, Zones, Cellules, Transfos) et Basse Tension (Zones, Locaux, TGBT, Armoires, Coffrets, Départs) | `lib/features/audit_installations/` |
| `description_installations` | Fiche descriptive générale, caractéristiques des postes MT, sources de secours et régimes de neutre | `lib/features/description_installations/` |
| `mesures_essais` | Campagnes d'essais physiques : Prises de terre, continuités PE, isolements, DDR, CPI, arrêt d'urgence, démarrage automatique | `lib/features/mesures_essais/` |
| `foudre` | Protection foudre : paratonnerres PDA, parafoudres amont/aval, conducteurs de descente et liaisons équipotentielles | `lib/features/foudre/` |
| `jsa` | Job Safety Analysis : évaluation des risques d'intervention, EPI requis et plan d'urgence | `lib/features/jsa/` |
| `backup` | File d'attente d'arrière-plan, synchronisation cloud (Graph API / OneDrive) et indicateur global | `lib/features/backup/` |

---

## 2. INJECTION DE DÉPENDANCES (`lib/core/di/injection_container.dart`)

L'injection de dépendances est orchestrée par **GetIt** (`sl = GetIt.instance`).  
Elle est initialisée au démarrage dans `main.dart` via `await di.init();`.

### Structure d'enregistrement
1. **Services d'infrastructure** :
   - `HiveService` (Singleton)
   - `BackupService` (Singleton)
2. **DataSources** :
   - Ex: `sl.registerLazySingleton<AuditInstallationsLocalDataSource>(() => AuditInstallationsLocalDataSourceImpl());`
3. **Repositories** :
   - Ex: `sl.registerLazySingleton<AuditInstallationsRepository>(() => AuditInstallationsRepositoryImpl(localDataSource: sl()));`
4. **Use Cases** :
   - Ex: `sl.registerLazySingleton<GetAuditInstallationsUseCase>(() => GetAuditInstallationsUseCase(repository: sl()));`
   - Ex: `sl.registerLazySingleton<SaveAuditInstallationsUseCase>(() => SaveAuditInstallationsUseCase(repository: sl()));`

---

## 3. GESTION D'ÉTAT RÉACTIVE AVEC FLUTTER RIVERPOD

### Principe Directeur
- L'UI ne communique **jamais directement avec les DataSources ou Hive**.
- Les widgets consomment l'état via `ref.watch(provider(missionId))` et déclenchent des mutations via `ref.read(provider(missionId).notifier).action()`.
- L'isolation est stricte par `missionId` grâce aux providers de famille (`.family`).

### Pattern d'un Provider de Domaine (Exemple `auditInstallationsProvider`)
Fichier : `lib/features/audit_installations/presentation/providers/audit_installations_provider.dart`

```dart
final auditInstallationsProvider = StateNotifierProvider.family
    .autoDispose<AuditInstallationsNotifier, AsyncValue<AuditInstallationsElectriques>, String>(
  (ref, missionId) {
    ref.keepAlive(); // Maintient l'état en mémoire durant la navigation entre étapes
    return AuditInstallationsNotifier(ref: ref, missionId: missionId);
  },
);
```

### Mécanismes clés de `AuditInstallationsNotifier`
1. **Chargement non-bloquant et dédoublé** :
   - `_performLoad()` utilise `getAuditInstallationsUseCaseProvider` pour récupérer l'Entity pure, puis `AuditInstallationsMapper.toModel()` pour l'usage UI.
   - Les appels simultanés réutilisent `_loadFuture` pour éliminer tout double chargement Hive.
2. **Sauvegarde asynchrone non-bloquante** :
   - `saveAudit(AuditInstallationsElectriques audit)` mappe vers l'Entity, exécute `SaveAuditInstallationsUseCase`, et met à jour l'état UI en `AsyncValue.data(audit)`.
3. **Mise en file d'attente de sauvegarde** :
   - Toute persistance réussie notifie automatiquement `MissionActivityTracker` et empile la mission dans `BackupQueueService`.

---

## 4. FORMULAIRES DYNAMIQUES & ERGONOMIE TERRAIN

### Navigation Séquentielle (`SequenceScreen`)
Fichier : `lib/pages/missions/sequence/sequence_screen.dart`  
L'inspection se déroule en étapes chronologiques assistées par `SequenceProgressService` :
1. **Informations générales** (`general_info_step.dart`)
2. **Description des installations** (`description_step.dart`)
3. **Audit des installations électriques** (`audit_step.dart`)
4. **Schémas & Documents** (`schema_step.dart`, `documents_step.dart`)
5. **Job Safety Analysis** (`jsa_step.dart`)
6. **Synthèse & Génération des rapports** (`summary_step.dart`)

### Ergonomie Chantier & Cibles Tactiles
- Conforme aux règles d'inspection en environnement industriel (inspecteurs munis de gants de protection) :
  - **Cibles tactiles minimales de 48x48 dp** pour tout bouton, case à cocher ou interrupteur.
  - Sélecteurs assistés de valeurs fréquentes avec champ libre *« Autre / Saisir »*.
  - Saisie incrémentale avec persistance automatique à la sortie des champs (`onChanged` avec debounce ou `onEditingComplete`).

---

## 5. CYCLE DE VIE COMPLET D'UNE MUTATION DE DONNÉES

```text
[Utilisateur modifie un Départ dans un Coffret]
                         │
                         ▼
           CoffretFormScreen.onSave()
                         │
                         ▼
        ref.read(auditInstallationsProvider(missionId).notifier).saveAudit(updatedAudit)
                         │
                         ▼
        SaveAuditInstallationsUseCase.call(auditEntity)
                         │
                         ▼
        AuditInstallationsRepositoryImpl.saveAuditInstallations(auditEntity)
                         │
                         ▼
        AuditInstallationsMapper.toModel(auditEntity)
                         │
                         ▼
        AuditInstallationsLocalDataSourceImpl.saveAuditInstallations(auditModel)
                         │
                         ▼
        Hive.box<AuditInstallationsElectriques>('audit_installations_electriques').put(...)
                         │
                         ├────────────────────────────────────────┐
                         ▼                                        ▼
   InstallationDescriptionSyncService.syncFromAudit(missionId)  BackupQueueService.enqueue(...)
   (Met à jour automatiquement les transfos/cellules            (Inscrit la mission pour
    dans DescriptionInstallations si nécessaire)                 sauvegarde M365 en tâche de fond)
```
