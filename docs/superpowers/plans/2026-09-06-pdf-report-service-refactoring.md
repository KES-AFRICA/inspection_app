# PdfReportService Refactoring (Façade & Builders) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Modularize the monolithic pdf_report_service.dart (~21,700 lines) into a clean Façade + 13 specialized Builders architecture with absolute 100% preservation of visual layout, pagination engine (2-pass PageTracker), calculations, and test backward compatibility.

**Architecture:** The public class PdfReportService remains the sole façade called by the UI and existing tests. It orchestrates a shared PdfReportContext and PdfReportStyles layer, delegating page creation to 13 domain-specific builders in lib/services/pdf/builders/. The 2-pass pagination engine (_generateReportPass) and high-performance binary merger (PdfMergerService) are strictly preserved.

**Architecture Diagram:**

`mermaid
graph TD
    UI[App Screens / UI Controllers] --> Façade[PdfReportService Façade]
    Façade --> PassEngine[2-Pass Engine _generateReportPass]
    
    subgraph Core Shared Infrastructure
        Context[PdfReportContext
Assets, Fonts, Models, TempDir]
        Styles[PdfReportStyles
Palettes, Headers, Footers, Tables]
    end
    
    PassEngine --> Context
    PassEngine --> Styles
    
    subgraph Section Builders in lib/services/pdf/builders/
        B1[PdfCoverBuilder]
        B2[PdfSommaireBuilder]
        B3[PdfRegulatoryBuilder]
        B4[PdfExecutiveSummaryBuilder]
        B5[PdfStatisticsBuilder]
        B6[PdfRenseignementsBuilder]
        B7[PdfDescriptionBuilder]
        B8[PdfEquipementsSynthesisBuilder]
        B9[PdfObservationsRecapBuilder]
        B10[PdfAuditInstallationsBuilder]
        B11[PdfClassementFoudreBuilder]
        B12[PdfMesuresEssaisBuilder]
        B13[PdfPhotosSchemasBuilder]
    end
    
    PassEngine --> B1
    PassEngine --> B2
    PassEngine --> B3
    PassEngine --> B4
    PassEngine --> B5
    PassEngine --> B6
    PassEngine --> B7
    PassEngine --> B8
    PassEngine --> B9
    PassEngine --> B10
    PassEngine --> B11
    PassEngine --> B12
    PassEngine --> B13
    
    PassEngine --> Merger[PdfMergerService]
`

**Tech Stack:** Dart 3.x, Flutter 3.47.x, package:pdf (widgets), Hive, Flutter Image Compress, package:share_plus.

**Spec:** [docs/superpowers/specs/2026-09-06-pdf-report-service-refactoring-design.md](file:///C:/Users/TeufackAndelson/OneDrive%20-%20Kamer%20Engineering%20Solutions/Documents/Projets%20KES/inspection_app/docs/superpowers/specs/2026-09-06-pdf-report-service-refactoring-design.md)

## Global Constraints

- Never break existing public signatures of PdfReportService (generateMissionReport, uildElectricalReportFileName, shareReport).
- Retain all 17 @visibleForTesting methods on PdfReportService as delegates to builders to keep all 27 unit test files green without touching a single test file.
- Strict preservation of the 2-pass algorithm: Pass 1 computes dynamic page numbers; Pass 2 injects them into TOC and footers.
- Strict preservation of PageTracker widget keys and chunk boundaries to avoid Android OOM.
- Zero modification to mathematical and statistical formulas (Pareto, criticality counts, risk matrix, earth resistance thresholds).
- Frequent commits formatted with markdown: [REFAC] <description>.

---

### Task 1: Scaffolding Core Shared Infrastructure (PdfReportContext & PdfReportStyles)

**Files:**
- Create: lib/services/pdf/pdf_report_context.dart
- Create: lib/services/pdf/pdf_report_styles.dart
- Test: 	est/features/pdf_filename_format_test.dart

**Interfaces:**
- Produces: PdfReportContext, PdfReportStyles

- [ ] **Step 1: Create pdf_report_context.dart**
Define the class PdfReportContext to hold all shared resources for a report generation session:
`dart
class PdfReportContext {
  final Mission mission;
  final String missionId;
  final AuditInstallationsElectriques? audit;
  final DescriptionInstallations? description;
  final dynamic classements;
  final dynamic classementsZones;
  final dynamic mesures;
  final dynamic foudres;
  final dynamic renseignements;
  final dynamic currentUser;
  final String nomSiteHeader;
  final String numeroRapportDoc;
  final Directory tempDir;
  final bool saveFilesToDisk;
  final int? overrideTotalPages;
  final CancellationToken? cancellationToken;
  final PdfProgressCallback? onProgress;
  final Map<String, int> trackedPages;
  final Map<String, List<int>> photoRegistry;

  PdfReportContext({...});
}
`

- [ ] **Step 2: Create pdf_report_styles.dart**
Extract color constants (kesBlue = PdfColor.fromInt(0xFF003366), kesOrange = PdfColor.fromInt(0xFFFF6600)), font loaders, watermark builder, page headers (uildPageHeaderWidget), footers (uildFooterAbsolute), and cell primitives (uildTableHeaderCell, uildTableCell, sectionBox, subTitle, odyText, ulletItem).

- [ ] **Step 3: Run existing baseline tests**
Run: lutter test test/features/pdf_filename_format_test.dart
Expected: PASS (0 errors)

- [ ] **Step 4: Commit**
[REFAC] Add PdfReportContext and PdfReportStyles shared infrastructure

---

### Task 2: Extract PdfCoverBuilder and PdfSommaireBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_cover_builder.dart
- Create: lib/services/pdf/builders/pdf_sommaire_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/sommaire_dynamic_test.dart

**Interfaces:**
- Produces: PdfCoverBuilder.buildCoverPage, PdfCoverBuilder.buildIntervenantsPage, PdfSommaireBuilder.addSommairePages, PdfSommaireBuilder.collectSommaireEntries
- Consumes: PdfReportContext, PdfReportStyles

- [ ] **Step 1: Write pdf_cover_builder.dart**
Extract _buildCoverPage, _buildIntervenantsEtResponsabilitesPage, and _preloadCoverImages.

- [ ] **Step 2: Write pdf_sommaire_builder.dart**
Extract _addSommairePages, _buildSommaireEntryLine, _collectSommaireEntries, and getSommaireEntriesForTesting.

- [ ] **Step 3: Delegate in PdfReportService**
In pdf_report_service.dart, point cover and sommaire generation to PdfCoverBuilder and PdfSommaireBuilder.

- [ ] **Step 4: Run tests**
Run: lutter test test/features/sommaire_dynamic_test.dart
Expected: PASS

- [ ] **Step 5: Commit**
[REFAC] Extract PdfCoverBuilder and PdfSommaireBuilder

---

### Task 3: Extract PdfRegulatoryBuilder (Normes, Matériel, Périmètre)

**Files:**
- Create: lib/services/pdf/builders/pdf_regulatory_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_filename_format_test.dart

**Interfaces:**
- Produces: PdfRegulatoryBuilder.buildNormesTable, PdfRegulatoryBuilder.buildMaterielTable, PdfRegulatoryBuilder.buildPerimetreTable

- [ ] **Step 1: Write pdf_regulatory_builder.dart**
Extract _buildNormesTable, _buildMaterielTable, and _buildPerimetreTable.

- [ ] **Step 2: Delegate in PdfReportService**
Wire _generateReportPass Sub-chunk 1.2 to use PdfRegulatoryBuilder.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_filename_format_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfRegulatoryBuilder

---

### Task 4: Extract PdfExecutiveSummaryBuilder & PdfStatisticsBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_executive_summary_builder.dart
- Create: lib/services/pdf/builders/pdf_statistics_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_statistics_verification_test.dart, 	est/features/pdf_statistics_expanded_test.dart

**Interfaces:**
- Produces: PdfExecutiveSummaryBuilder.buildResumeExecutif, PdfStatisticsBuilder.buildAnalyseStatistique

- [ ] **Step 1: Write pdf_executive_summary_builder.dart**
Extract _buildResumeExecutif, criticality summary tables, and risk factor matrix tables.

- [ ] **Step 2: Write pdf_statistics_builder.dart**
Extract _buildAnalyseStatistique, Pareto chart, and non-conformity histograms.

- [ ] **Step 3: Delegate in PdfReportService**
Wire Sub-chunk 1.3 to use the new builders.

- [ ] **Step 4: Run tests**
Run: lutter test test/features/pdf_statistics_verification_test.dart test/features/pdf_statistics_expanded_test.dart
Expected: PASS

- [ ] **Step 5: Commit**
[REFAC] Extract PdfExecutiveSummaryBuilder and PdfStatisticsBuilder

---

### Task 5: Extract PdfRenseignementsBuilder & PdfDescriptionBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_renseignements_builder.dart
- Create: lib/services/pdf/builders/pdf_description_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_description_installations_test.dart, 	est/features/pdf_description_mapping_test.dart, 	est/features/pdf_description_poste_grouping_test.dart

**Interfaces:**
- Produces: PdfRenseignementsBuilder.buildRenseignementsGeneraux, PdfDescriptionBuilder.buildDescriptionInstallationsMulti

- [ ] **Step 1: Write pdf_renseignements_builder.dart**
Extract general info tables.

- [ ] **Step 2: Write pdf_description_builder.dart**
Extract MT/BT description tables, post groupings, transformer specs, and collectRiskZonesAndLocauxForTesting.

- [ ] **Step 3: Delegate in PdfReportService**
Wire Sub-chunks 1.4 & 1.5.

- [ ] **Step 4: Run tests**
Run: lutter test test/features/pdf_description_installations_test.dart test/features/pdf_description_mapping_test.dart
Expected: PASS

- [ ] **Step 5: Commit**
[REFAC] Extract PdfRenseignementsBuilder and PdfDescriptionBuilder

---

### Task 6: Extract PdfEquipementsSynthesisBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_equipements_synthesis_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_equipements_synthesis_test.dart, 	est/features/pdf_equipements_summary_table_test.dart, 	est/features/pdf_equipements_synthesis_evolution_test.dart

**Interfaces:**
- Produces: PdfEquipementsSynthesisBuilder.addSyntheseEquipementsSectionChunked, and testing delegates (collectEquipementsMTForTesting, getEquipementsBTForTesting, uildEquipementsTableForTesting)

- [ ] **Step 1: Write pdf_equipements_synthesis_builder.dart**
Extract equipment synthesis grouping, chunk flush logic, unknown sources tables, and testing helpers.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunk 1.6 and test delegates.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_equipements_synthesis_test.dart test/features/pdf_equipements_summary_table_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfEquipementsSynthesisBuilder

---

### Task 7: Extract PdfObservationsRecapBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_observations_recap_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_observations_synthesis_evolution_test.dart, 	est/features/pdf_obs_synthesis_real_equipment_classification_test.dart

**Interfaces:**
- Produces: PdfObservationsRecapBuilder.addListeRecapitulativeSectionChunked, _buildObsRecapTableUnifie, and testing delegates (createObsRecapForTesting, groupByZoneLocalEquipForTesting, uildObsRecapTableUnifieForTesting)

- [ ] **Step 1: Write pdf_observations_recap_builder.dart**
Extract observation aggregation, sorting, grouping by Zone/Local/Equip, and table building.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunk 1.7 and test delegates.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_observations_synthesis_evolution_test.dart test/features/pdf_obs_synthesis_real_equipment_classification_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfObservationsRecapBuilder

---

### Task 8: Extract PdfAuditInstallationsBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_audit_installations_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_audit_coffret_tables_test.dart, 	est/features/pdf_photo_references_in_audit_tables_test.dart

**Interfaces:**
- Produces: PdfAuditInstallationsBuilder.addAuditSectionChunked, _buildCoffret, _buildCelluleSection, _buildTransformateurSection, _buildDispositionsTable, and testing delegates

- [ ] **Step 1: Write pdf_audit_installations_builder.dart**
Extract detailed audit grids for coffrets, cellules, transformers, constructives dispositions, and verification points.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunk 1.8.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_audit_coffret_tables_test.dart test/features/pdf_photo_references_in_audit_tables_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfAuditInstallationsBuilder

---

### Task 9: Extract PdfClassementFoudreBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_classement_foudre_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_classement_table_test.dart, 	est/features/pdf_foudre_surtension_test.dart, 	est/features/pdf_continuite_and_classement_test.dart

**Interfaces:**
- Produces: PdfClassementFoudreBuilder.buildClassementEmplacementsMulti, PdfClassementFoudreBuilder.buildFoudre, and testing delegates (collectParafoudreRowsForTest, getFormattedPhotoLabelForTest)

- [ ] **Step 1: Write pdf_classement_foudre_builder.dart**
Extract location classification tables, external influences, lightning risk evaluation, and surge protector tables.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunk 1.9.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_classement_table_test.dart test/features/pdf_foudre_surtension_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfClassementFoudreBuilder

---

### Task 10: Extract PdfMesuresEssaisBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_mesures_essais_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_section2_essais_landscape_test.dart, 	est/features/pdf_isolement_sans_objet_test.dart, 	est/features/pdf_isolement_zone_integration_test.dart

**Interfaces:**
- Produces: PdfMesuresEssaisBuilder.addMesuresEssaisPages (Landscape multi-page tables for earth, continuity, and insulation)

- [ ] **Step 1: Write pdf_mesures_essais_builder.dart**
Extract landscape page setup, earth loop measurement table, equipotential continuity table, and insulation test table.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunk 1.10.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_section2_essais_landscape_test.dart test/features/pdf_isolement_sans_objet_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfMesuresEssaisBuilder

---

### Task 11: Extract PdfPhotosSchemasBuilder

**Files:**
- Create: lib/services/pdf/builders/pdf_photos_schemas_builder.dart
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: 	est/features/pdf_photos_structure_test.dart, 	est/features/pdf_photos_deduplication_test.dart, 	est/features/pdf_schema_section_test.dart

**Interfaces:**
- Produces: PdfPhotosSchemasBuilder.addPhotosSectionChunked, PdfPhotosSchemasBuilder.addSchemaSection

- [ ] **Step 1: Write pdf_photos_schemas_builder.dart**
Extract photo grid rendering, chunked memory protection, photo labelling, and single-line diagram schemas.

- [ ] **Step 2: Delegate in PdfReportService**
Wire Sub-chunks 1.11 & 1.12.

- [ ] **Step 3: Run tests**
Run: lutter test test/features/pdf_photos_structure_test.dart test/features/pdf_schema_section_test.dart
Expected: PASS

- [ ] **Step 4: Commit**
[REFAC] Extract PdfPhotosSchemasBuilder

---

### Task 12: Finalize PdfReportService Façade Cleanup

**Files:**
- Modify: lib/services/pdf/pdf_report_service.dart
- Test: All 27 PDF tests in 	est/features/

- [ ] **Step 1: Clean up unused private functions in pdf_report_service.dart**
Ensure pdf_report_service.dart is reduced from 21,700 lines down to ~600-800 lines of clean, readable orchestration code.

- [ ] **Step 2: Verify all 27 PDF unit tests**
Run: lutter test test/features/pdf_*.dart test/features/sommaire_*.dart
Expected: ALL PASS with 0 errors.

- [ ] **Step 3: Commit**
[REFAC] Complete PdfReportService façade modularization

---

### Task 13: Full System & Regression Verification

**Files:**
- Test: 	est/features/guinness_bassa_audit_test.dart, 	est/data_integrity_test.dart

- [ ] **Step 1: Run full automated test suite**
Run: lutter test
Expected: 101/101 test files passing.

- [ ] **Step 2: Verify build and runtime integrity**
Run: lutter build apk --debug
Expected: SUCCESS

- [ ] **Step 3: Final Commit**
[REFAC] Verify 100% regression-free modular PDF generation engine
