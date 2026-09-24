# 06_ADR_AND_FORENSIC_REGISTER.md — Décisions Architecturales & Registre Forensic

> **Module** : KES Inspection App — Pilier 6  
> **Dernière révision** : 24 Septembre 2026  
> **Source de vérité** : Historique Git, Registre d'erreurs, `test/features/`

---

## 1. REGISTRE DES DÉCISIONS ARCHITECTURALES (ADR)

### ADR-001 — Migration Clean Architecture & Découpage en 3 Couches
- **Date** : Juillet 2026
- **Contexte** : Le code historique couplait directement les widgets Flutter avec les boîtes Hive, rendant les tests unitaires impossibles sans mock complet de la persistance.
- **Décision** : Séparer l'application en modules Feature-First comprenant `domain/` (entités pures, use cases), `data/` (repositories, mappers, sources Hive) et `presentation/` (Riverpod, écrans).
- **Conséquences** : Tests unitaires instantanés et découplés, réactivité via Riverpod, zéro fuite de types Hive dans l'interface.

### ADR-002 — Moteur PDF V3 par Micro-Lots et Découpage 2-Passes
- **Date** : Août 2026
- **Contexte** : Les rapports volumineux (ex. Cimencam, Camrail : 100+ pages, 300+ photos) provoquaient des crashs système par manque de mémoire (Out-Of-Memory) sur les smartphones de terrain.
- **Décision** : Abandonner le document monolithique unique. Mettre en place un pré-calcul en mémoire (Passe 1) pour mesurer exactement le sommaire, générer des tronçons indépendants sur disque (Passe 2) avec injection du total global, puis fusionner via `PdfMergerService`.
- **Conséquences** : Consommation mémoire plafonnée quel que soit le volume de pages, suppression totale des OOM sur le terrain.

### ADR-003 — Refactorisation de `PdfReportService` en Façade & 13 Builders
- **Date** : Septembre 2026
- **Contexte** : `PdfReportService.dart` avait dépassé 21 000 lignes de code, rendant toute maintenance risquée et l'IDE instable.
- **Décision** : Éclater le fichier en 13 builders spécialisés coordonnés par `PdfReportContext` et `PdfReportStyles` dans `lib/services/pdf/builders/`.
- **Conséquences** : Code clair, lisible et testable unitairement, tout en conservant une façade publique inchangée pour le reste de l'application.

### ADR-004 — Centralisation de la Numérotation des Équipements
- **Date** : Septembre 2026
- **Contexte** : Lors de suppressions ou de tris, des doublons ou des trous apparaissaient dans la numérotation des armoires, et des tensions ("400V") ou années ("2024") s'infiltraient dans le compteur séquentiel.
- **Décision** : Créer [EquipmentNumberService](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/equipment_number_service.dart) avec validation numérique stricte (`parseNumericSequence`) et assignation monotone croissante au-delà du maximum existant.
- **Conséquences** : Immuabilité absolue de la numérotation N° à travers toute la mission (locaux MT, zones, BT et brouillons).

---

## 2. REGISTRE DES RISQUES DE RÉGRESSION PAR ZONE SENSIBLE

| Zone Critique | Risque Principal | Cause Potentielle | Mode de Vérification Obligatoire |
|---|---|---|---|
| **Hive / Persistence** | Crash au démarrage ou désérialisation null | Réutilisation d'un `@HiveField` ou non-respect de la nullabilité | `test/features/data_integrity_test.dart` |
| **Équipements & Départs** | Mélange d'équipements ou perte de liaisons amont/aval | Utilisation d'un index de liste au lieu d'`equipmentId` ou `departId` | `test/features/equipment_departures_circuits_forensic_test.dart` |
| **Numérotation N°** | Saut de numérotation ou séquence faussée | Saisie d'une chaîne contenant des chiffres interprétée comme séquence | `test/features/equipment_number_test.dart` |
| **Pagination PDF** | Numéros de page décalés ou faux compteurs locaux | Omission d'`offset` dans `PageTracker` ou usage de `ctx.pagesCount` | `test/features/pdf_report_full_simulation_test.dart` |
| **Statistiques MT / BT** | Données polluées ou dénominateurs faussés | Inclusion d'un coffret BT situé en local MT dans les statistiques MT | `test/features/mt_bt_equipment_separation_forensic_test.dart` |
| **Import / Export** | Rejet d'une archive valide ou perte de photos | Mauvais calcul du hash SHA-256 ou chemins de photos absolus | `test/features/backup_system_overhaul_test.dart` |

---

## 3. PROBLÈMES CONNUS & PIÈGES FORENSIC RÉSOLUS

### 1. Collision de Timestamps en Microsecondes
- **Symptôme historique** : Deux équipements créés lors d'une boucle rapide de test unitaire recevaient le même identifiant de secours.
- **Cause racine** : `DateTime.now().microsecondsSinceEpoch` peut renvoyer la même valeur sur des itérations exécutées dans le même cycle CPU.
- **Solution définitive** : Combiner systématiquement le timestamp avec une entropie hashée du nom ou de la signature (`stableHash`).

### 2. Piège de l'Offset dans `PageTracker`
- **Symptôme historique** : Dans le sommaire PDF, un chapitre commençant à la page 52 affichait « Page 3 ».
- **Cause racine** : Le builder de ce chapitre n'injectait pas `currentOffset` dans l'instance de `PageTracker`, comptant les pages relativement à son chunk local.
- **Règle absolue** : Tout widget tracé dans le sommaire doit obligatoirement recevoir et appliquer `offset: currentOffset`.

### 3. Verrouillage Fichier sous Windows lors des Builds Android
- **Symptôme** : Échec `mergeReleaseNativeLibs` avec `AccessDeniedException` sur des fichiers `.so`.
- **Cause racine** : Processus Gradle ou antivirus maintenant un descripteur de fichier ouvert.
- **Solution** : Toujours exécuter `.\gradlew --stop` dans le dossier `android/` avant de relancer le packaging.
