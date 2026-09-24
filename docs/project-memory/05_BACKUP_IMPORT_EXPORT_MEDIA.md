# 05_BACKUP_IMPORT_EXPORT_MEDIA.md — Sauvegarde, Import/Export & Gestion des Médias

> **Module** : KES Inspection App — Pilier 5  
> **Dernière révision** : 24 Septembre 2026  
> **Source de vérité** : `lib/services/backup_service.dart`, `lib/features/backup/`, `lib/services/file_storage_service.dart`

---

## 1. ARCHITECTURE DES SAUVEGARDES (FORMATS V1 À V4)

Fichier principal : [lib/services/backup_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/backup_service.dart)

L'application utilise un format de conteneur d'archive compressée (ZIP) portant l'extension `.inspec` ou `.zip`.

### Évolution des Formats et Magic Strings

| Format | Magic Header | Fonctionnalités Clés |
|---|---|---|
| **V1** | `INSPEC_BACKUP_V1` | Export global de toutes les boîtes sans signature SHA-256 (format legacy pris en charge en lecture seule). |
| **V2** | `INSPEC_BACKUP_V2` | Introduction du contrôle d'intégrité SHA-256 et de l'export unitaire par mission (`exporterMission(missionId)`). |
| **V3** | `INSPEC_BACKUP_V3` | Support des nouveaux champs de départs BT et conformité normalisée. |
| **V4** (Actuel) | `INSPEC_BACKUP_V4` | Sérialisation complète des 18 boîtes, prise en charge de la corbeille, des audits photométriques (Lighting) et des métadonnées de synchronisation M365. |

### Structure Interne d'une Archive `.inspec`
```text
archive.inspec (Archive ZIP)
 ├── manifest.json            # Magic, SchemaVersion, ExportType, Date, Checksum SHA-256
 ├── missions.json            # Flux JSON de la boîte 'missions'
 ├── audit_installations.json # Flux JSON de la boîte 'audit_installations_electriques'
 ├── description.json         # Flux JSON de la boîte 'description_installations'
 ├── mesures_essais.json      # Flux JSON de la boîte 'mesures_essais'
 ├── [autres_boites].json     # Renseignements, Foudre, JSA, Classements
 └── photos/                  # Répertoire contenant tous les clichés JPG compressés
      ├── photo_1727192837_1.jpg
      └── photo_1727192837_2.jpg
```

---

## 2. INTÉGRITÉ CRYPTOGRAPHIQUE & VÉRIFICATION SHA-256

Pour prévenir la corruption de données lors des transferts par câble, clé USB ou messagerie :
1. **À l'exportation** :
   - Les fichiers JSON et les photos sont rassemblés dans l'archive.
   - Une empreinte **SHA-256** est calculée sur le flux complet des données métier et inscrite dans `manifest.json`.
2. **À l'importation** :
   - L'archive est inspectée avant écriture (`BackupService.inspecterSauvegarde(filePath)`).
   - L'empreinte SHA-256 est recalculée et comparée à celle du manifeste. En cas d'incohérence, l'importation est bloquée avec une erreur explicite sans corrompre la base locale.

---

## 3. SYNCHRONISATION EN ARRIÈRE-PLAN (CLOUD M365 / ONEDRIVE)

Fichier : `lib/features/backup/data/datasources/backup_queue_service.dart`

L'application fonctionne à 100 % hors-ligne, mais dispose d'un moteur de rattrapage automatique dès que la connectivité réseau est rétablie :
1. **File d'Attente (`backup_queue`)** :
   - À chaque sauvegarde d'étape (`saveAudit`, `saveMesures`, etc.), `MissionActivityTracker` enregistre la mission modifiée dans la boîte Hive `backup_queue`.
2. **Orchestrateur Réseau (`BackupOrchestrator`)** :
   - Surveille l'état du réseau via `connectivity_plus`.
   - Dépile séquentiellement les missions en attente, génère l'archive V4 et la transfère via l'API Microsoft Graph sur le compte OneDrive d'entreprise.
   - Un widget global (`GlobalBackupProgressOverlay`) affiche discrètement la progression sans bloquer la saisie.

---

## 4. GESTION DES MÉDIAS & DES PHOTOGRAPHIES

### Compression Adaptative à la Prise de Vue
- Les appareils photo industriels actuels produisent des fichiers bruts de 10 à 25 Mo (4000x3000 px). Stocker et charger 300 photos brutes provoquerait un dépassement de mémoire immédiat (OOM).
- Dès la capture ou la sélection galerie, toute image passe par `FlutterImageCompress` :
  - **Largeur cible** : 1200 px max.
  - **Qualité de compression** : 75 % JPEG.
  - **Poids moyen résultant** : 150 à 350 Ko (qualité probante irréprochable tout en divisant le poids par 40).

### Cache Mémoire de Session dans le Générateur PDF
- Afin qu'une photo réutilisée à plusieurs endroits du rapport (ex. dans le tableau de l'armoire ET dans la planche de schémas) ne soit pas encodée deux fois en mémoire :
  - `PdfReportService._sessionMemoryImageCache` stocke l'instance `pw.MemoryImage` indexée par le chemin du fichier.
  - Le cache est intégralement vidé (`clearSessionCache()`) à la fin de la génération du rapport dans le bloc `finally`.
