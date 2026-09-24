# 04_REPORTING_AND_STATISTICS.md — Reporting Multi-Format & Moteurs Statistiques

> **Module** : KES Inspection App — Pilier 4  
> **Dernière révision** : 24 Septembre 2026  
> **Source de vérité** : `lib/services/pdf/`, `lib/services/excel/`, `lib/services/word_report_service.dart`, `lib/services/statistics/`

---

## 1. ARCHITECTURE PDF V3 (MOTEUR PAR MICRO-LOTS À 2-PASSES)

Fichier orchestrateur : [lib/services/pdf/pdf_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/pdf/pdf_report_service.dart#L3569-L3742)

Pour éliminer définitivement les crashs mémoire (Out-Of-Memory) lors de l'édition de rapports d'usines lourdes (100+ pages, 300+ photographies haute résolution), la génération PDF est découpeé en micro-lots indépendants assemblés par fusion binaire.

```text
                                  DEMANDE DE GÉNÉRATION PDF
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
         PASSE 1 : PRE-FLIGHT EN MÉMOIRE             PASSE 2 : ÉCRITURE SUR DISQUE (CHUNKS)
         - Construit le Sommaire dynamique           - Injecte overrideTotalPages = totalReportPages
           pour calculer son encombrement réel       - Chaque builder écrit son fichier .pdf temporaire
         - Parcourt tous les chunks avec             - Footer : Page (pageNumber + offset) / totalReportPages
           l'offset cumulé                           - Micro-lots photos max 3 pages par lot (Anti-OOM)
         - Enregistre trackedPages[key]                               │
                      │                                               ▼
                      └─────────────────────────────────► FUSION BINAIRE HAUTE PERFORMANCE
                                                          - PdfMergerService.mergePdfFiles()
                                                          - Assemblage séquentiel direct sans ré-encodage
                                                          - Nettoyage final des fichiers temporaires
```

### Registre des 13 Builders Spécialisés (`lib/services/pdf/builders/`)
1. **`PdfCoverBuilder`** : Page de garde officielle KES, intervenants, client, site, date de mission.
2. **`PdfSommaireBuilder`** : Sommaire dynamique multi-pages synchronisé avec la table `trackedPages`.
3. **`PdfRegulatoryBuilder`** : Cadre réglementaire, textes de lois, appareils de mesures étalonnés.
4. **`PdfExecutiveSummaryBuilder`** : Synthèse exécutive, criticité globale du site, facteurs clés.
5. **`PdfStatisticsBuilder`** : Histogrammes et courbe de Pareto déterministes.
6. **`PdfRenseignementsBuilder`** : Tableaux des renseignements administratifs et techniques.
7. **`PdfDescriptionBuilder`** : Description générale MT/BT, postes, régimes de neutre, groupes de secours.
8. **`PdfEquipementsSynthesisBuilder`** : Tableaux unifiés des équipements MT et BT (12 colonnes standardisées).
9. **`PdfObservationsRecapBuilder`** : Liste récapitulative des non-conformités sous forme de cartes d'équipements fermées.
10. **`PdfAuditInstallationsBuilder`** : Grilles détaillées par local, zone et coffret.
11. **`PdfClassementFoudreBuilder`** : Fiches de classement des locaux à risques (BE2, ATEX) et audit foudre.
12. **`PdfMesuresEssaisBuilder`** : Tableaux paysage des mesures physiques (Terre, continuités, isolement, DDR).
13. **`PdfPhotosSchemasBuilder`** : Planches de photos probantes et schémas unifilaires.
14. **`PdfFinalPageBuilder`** : Page de clôture, signatures, cachets et coordonnées KES.

---

## 2. GÉNÉRATION EXCEL (`ExcelReportService`)

Fichier source : [lib/services/excel/excel_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/excel/excel_report_service.dart)  
Moteur : **Syncfusion Flutter XlsIO**.

Le classeur produit contient **2 feuilles normalisées** qui partagent rigoureusement les mêmes métriques et le même filtrage que le rapport PDF :
- **Feuille 1 : « Annexe des équipements »**  
  Tableau unifié de 12 colonnes : `Zone | Repère | N° | Désignation | Type | Départs issus | Vérifié | Présence du parafoudre | Vérification thermo | Observation | Date de réserve | Date de rapport`.
- **Feuille 2 : « Annexe des observations »**  
  Tableau exhaustif de toutes les non-conformités constatées, classées par sévérité, localisation, référence normative et priorité.

---

## 3. GÉNÉRATION WORD (`WordReportService`)

Fichier source : [lib/services/word_report_service.dart](file:///c:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/lib/services/word_report_service.dart)  
Moteur : **`docs_gee`** (génération native OOXML `.docx`).

Produit un document Word structuré reprenant l'intégralité des sections du rapport avec styles typographiques aux couleurs KES (Bleu KES `#1E3A8A`, Bleu d'accent `#2563EB`, alternance zébrée `#F8FAFC`).

---

## 4. MOTEURS STATISTIQUES DÉTERMINISTES (`lib/services/statistics/`)

Le reporting et le tableau de bord de l'application s'appuient sur **16 moteurs déterministes** éliminant toute variation aléatoire :

### 1. Analyse Pareto sur les 10 Catégories Canoniques de Défauts
Classement décroissant des anomalies pour identifier les 20 % de causes générant 80 % des risques :
1. `Interconnexion à la terre et protections différentielles`
2. `Dispositifs de protection contre les surintensités`
3. `Répartition des circuits et répartiteurs`
4. `Identification, repérage et documentation des circuits`
5. `Câblages, raccordements et canalisations`
6. `Intégrité des enveloppes, armoires et coffrets`
7. `Organes de coupure, d'isolement et d'urgence`
8. `Éclairage de sécurité et secours`
9. `Poste et équipements Moyenne Tension`
10. `Autres anomalies d'exploitation`

### 2. Répartition selon les 5 Familles Canoniques de Risques
1. `Erreur d'exploitation / maintenance`
2. `Électrisation / électrocution`
3. `Dégradation des canalisations et matériels`
4. `Surintensité / court-circuit`
5. `Échauffement / surcharge / risque d'incendie`

### 3. Isolation Absolue MT / BT dans les Statistiques
- Le dénominateur MT comprend uniquement les entités MT (Locaux MT, Cellules, Transfos).
- Le dénominateur BT comprend uniquement les entités BT (TGBT, Armoires, Coffrets, Inverseurs, Départs).
- Tout équipement BT localisé dans un poste MT est comptabilisé exclusivement dans la population BT.
