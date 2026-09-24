# 00_INDEX.md — Point d'Entrée de la Mémoire Projet KES Inspection App

> **Projet** : KES Inspection App (`inspec_app`)  
> **Organisation** : Kamer Engineering Solutions (KES Inspections & Projects)  
> **Dernière révision** : 24 Septembre 2026  
> **Rôle de ce fichier** : Premier fichier à lire pour tout nouvel agent ou développeur rejoignant le projet.

---

## 🎯 MISSION DE CE SYSTÈME DE MÉMOIRE

Ce dossier `docs/project-memory/` constitue la **mémoire technique vivante et persistante** du projet KES Inspection App. Son objectif est de permettre à un nouvel agent ou développeur de devenir **opérationnel sans briefing oral** en quelques minutes de lecture.

> ⚠️ **Règle d'Or** : Ces fichiers DOIVENT être mis à jour à chaque modification architecturale majeure. Un agent qui modifie un pattern central, crée un nouveau service ou résout un bug forensic critique est tenu de mettre à jour le fichier concerné dans ce dossier.

---

## 📚 STRUCTURE DE LA MÉMOIRE (Ordre de lecture recommandé)

| Ordre | Fichier | Contenu Couvert | Durée estimée |
|---|---|---|---|
| **1** | 01_ARCHITECTURE_AND_STATE.md | Clean Architecture, GetIt DI, Riverpod, cycle de vie mutations | 5 min |
| **2** | 02_DOMAIN_AND_DATA_MODEL.md | Hiérarchie métier Mission→Coffret, entités Hive, règles business | 8 min |
| **3** | 03_PERSISTENCE_AND_MIGRATIONS.md | Registre TypeId Hive, règles migration, boîtes de stockage | 5 min |
| **4** | 04_REPORTING_AND_STATISTICS.md | Moteur PDF V3 (2 passes, 13 builders), statistiques, Excel, Word | 6 min |
| **5** | 05_BACKUP_IMPORT_EXPORT_MEDIA.md | Format INSPEC_BACKUP_V2, SHA-256, photos, OneDrive sync | 4 min |
| **6** | 06_ADR_AND_FORENSIC_REGISTER.md | ADR, pièges forensic résolus, zones de régression | 5 min |
| **7** | 07_UI_UX_FORMS.md | Formulaires terrain, ergonomie 48dp, CoffretFormScreen | 5 min |

---

## ⚡ LECTURE RAPIDE PAR TÂCHE

### Modifier un formulaire de saisie terrain
→ Lire 01 → 02 → 07

### Ajouter un champ à un modèle Hive
→ Lire 02 → 03 → Section "Règle d'or Hive"

### Modifier la génération de rapport PDF
→ Lire 04 → Consulter docs/superpowers/plans/

### Corriger un bug de sauvegarde ou d'import/export
→ Lire 05 → 06 → Consulter test/features/

### Ajouter une nouvelle fonctionnalité métier
→ Lire 01 → 02 → 03 → Créer spec dans docs/superpowers/specs/

---

## 🔑 CONTEXTE PROJET EN 5 LIGNES

KES Inspection App est une **application Flutter offline-first** pour tablettes et smartphones durcis utilisée par des ingénieurs électrotechniciens sur des sites industriels lourds (usines, postes HTA/BT, cimenteries). L'inspecteur saisit des données d'audit réglementaire, des mesures physiques (prises de terre, isolements, DDR) et génère sur site des **rapports PDF professionnels de 50 à 150+ pages** ainsi que des classeurs Excel. Tout fonctionne **100% hors-ligne** (Hive NoSQL local). La stack : **Flutter + Riverpod + GetIt + Hive + package:pdf + Syncfusion Excel**.

---

## 🗂️ CARTE DE LA BASE DE CODE (Raccourci)

```
lib/
├── core/di/injection_container.dart        ← DI GetIt, tous les services
├── constants/app_theme.dart                ← Thème global, couleurs, typography
├── models/                                 ← Modèles Hive (legacy + partagés)
│   ├── mission.dart                        ← Entité racine Mission
│   ├── audit_installations_electriques.dart ← Hiérarchie MT/BT complète
│   └── mesures_essais.dart                 ← Prises de terre, isolements, DDR
├── features/                               ← Clean Architecture Feature-First
│   ├── auth/                               ← Login vérificateur, bcrypt
│   ├── mission/                            ← Cycle de vie et création de mission
│   ├── audit_installations/                ← Formulaires MT/BT, Coffrets, Départs
│   ├── mesures_essais/                     ← Campagnes de mesures physiques
│   ├── foudre/                             ← Protection foudre et éclairage
│   ├── jsa/                                ← Job Safety Analysis
│   └── backup/                             ← Sync cloud M365 / OneDrive
├── services/
│   ├── hive_service.dart                   ← Init Hive, adapters, migrations
│   ├── equipment_number_service.dart       ← Numérotation N° continue et immuable
│   ├── statistics/analytics_engine.dart    ← 16 moteurs statistiques déterministes
│   ├── pdf/pdf_report_service.dart         ← Façade publique PDF (2-passes)
│   ├── pdf/builders/                       ← 13 builders spécialisés
│   └── excel/                              ← Classeurs Excel (Syncfusion XlsIO)
└── pages/missions/sequence/                ← Navigation séquentielle inspection
```

---

## 📋 RÈGLES FONDAMENTALES

1. **Zero Data Loss** : Ne jamais réutiliser un `@HiveField(id)` existant. Toujours ajouter en fin d'index.
2. **Surgical Changes** : Diffs chirurgicaux, jamais de réécriture complète sans raison documentée.
3. **English code / French UI** : Code et variables en anglais. Textes UI, PDF, Excel en français.
4. **No auto-commit** : Ne JAMAIS exécuter `git commit` automatiquement. Fournir le message `[CREATE/UPD/DLT] : message en français`.
5. **Never Guess** : Si une donnée est absente → `Inconnu`, `Non renseigné` ou `Sans objet`.
6. **Tests obligatoires** : Toute modification de calcul ou modèle critique nécessite un test dans `test/features/`.

---

## 🔄 COMMENT MAINTENIR CES FICHIERS

Après chaque session significative :
1. Architecture modifiée → Met à jour `01_ARCHITECTURE_AND_STATE.md`
2. Modèle Hive modifié → Met à jour `02_DOMAIN_AND_DATA_MODEL.md` ET `03_PERSISTENCE_AND_MIGRATIONS.md`
3. PDF/Excel/Stats modifiés → Met à jour `04_REPORTING_AND_STATISTICS.md`
4. Bug forensic résolu → Ajouter dans `06_ADR_AND_FORENSIC_REGISTER.md` section 3
5. Toujours mettre à jour la date `Dernière révision` dans les fichiers modifiés
