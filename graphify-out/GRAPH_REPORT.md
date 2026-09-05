# Graph Report - inspection_app  (2026-09-05)

## Corpus Check
- 493 files · ~469,611 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 7708 nodes · 10654 edges · 234 communities (216 shown, 12 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107
- Community 108
- Community 109
- Community 110
- Community 111
- Community 112
- Community 113
- Community 114
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Community 120
- Community 121
- Community 122
- Community 123
- Community 124
- Community 125
- Community 126
- Community 127
- Community 128
- Community 129
- Community 130
- Community 131
- Community 132
- Community 133
- Community 134
- Community 135
- Community 136
- Community 137
- Community 138
- Community 139
- Community 140
- Community 141
- Community 142
- Community 143
- Community 144
- Community 145
- Community 146
- Community 147
- Community 148
- Community 149
- Community 150
- Community 151
- Community 152
- Community 153
- Community 154
- Community 155
- Community 156
- Community 157
- Community 158
- Community 159
- Community 160
- Community 161
- Community 162
- Community 163
- Community 164
- Community 165
- Community 166
- Community 167
- Community 168
- Community 169
- Community 170
- Community 171
- Community 172
- Community 173
- Community 174
- Community 175
- Community 176
- Community 177
- Community 178
- Community 179
- Community 180
- Community 181
- Community 182
- Community 183
- Community 184
- Community 185
- Community 186
- Community 187
- Community 188
- Community 189
- Community 190
- Community 191
- Community 192
- Community 193
- Community 194
- Community 195
- Community 196
- Community 197
- Community 198
- Community 199
- Community 200
- Community 201
- Community 202
- Community 203
- Community 204
- Community 205
- Community 206
- Community 207
- Community 208
- Community 209
- Community 210
- Community 211
- Community 212
- Community 213
- Community 214
- Community 215
- Community 216
- Community 217
- Community 218
- Community 220
- Community 221
- Community 222
- Community 223
- Community 224
- Community 225
- Community 226
- Community 232
- Community 233

## God Nodes (most connected - your core abstractions)
1. `Mission` - 82 edges
2. `descriptionInstallationsProvider` - 34 edges
3. `mesuresEssaisProvider` - 34 edges
4. `AuditInstallationsElectriques` - 19 edges
5. `Verificateur` - 18 edges
6. `class` - 17 edges
7. `Foudre` - 14 edges
8. `MissionRepository` - 13 edges
9. `backupJobManagerProvider` - 11 edges
10. `missionDetailProvider` - 11 edges

## Surprising Connections (you probably didn't know these)
- `MockFailingAiProvider` --implements--> `AiProvider`  [EXTRACTED]
  test/services/ai/mission_executive_summary_service_test.dart → lib/services/ai/ai_provider.dart
- `MockSuccessfulAiProvider` --implements--> `AiProvider`  [EXTRACTED]
  test/services/ai/mission_executive_summary_service_test.dart → lib/services/ai/ai_provider.dart
- `build` --references--> `descriptionInstallationsProvider`  [EXTRACTED]
  lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/alimentation_site_mt_sequence_screen.dart → lib/features/description_installations/presentation/providers/description_installations_provider.dart
- `_saveField` --references--> `descriptionInstallationsProvider`  [EXTRACTED]
  lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/alimentation_site_mt_sequence_screen.dart → lib/features/description_installations/presentation/providers/description_installations_provider.dart
- `build` --references--> `descriptionInstallationsProvider`  [EXTRACTED]
  lib/pages/missions/mission_detail/mission_execution_screen/description_installations_screen/components/cpi_sequence_screen.dart → lib/features/description_installations/presentation/providers/description_installations_provider.dart

## Import Cycles
- None detected.

## Communities (234 total, 12 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.00
Nodes (442): equipment_number_service.dart, installation_description_sync_service.dart, int? zoneIndex,
  bool, add, addAccompagnateur, addBasseTensionZone, addCarteToSection, addCelluleItem (+434 more)

### Community 1 - "Community 1"
Cohesion: 0.01
Nodes (336): ../ai/executive_summary_data.dart, ../ai/mission_executive_summary_service.dart, ../../components/safe_file_image.dart, Font, Font get, accentColor, accessible, ad (+328 more)

### Community 2 - "Community 2"
Cohesion: 0.01
Nodes (298): _accessible, addObservation, _ajouterCellule, _ajouterObservation, _ajouterTransformateur, _annulerEdition, _autoSaveTimer, _baseUrl (+290 more)

### Community 3 - "Community 3"
Cohesion: 0.01
Nodes (265): _accessible, _addCoffretToLocalInMoyenneTensionZone, addObservation, _addObservationToPoint, _addParafoudreObservation, _addSortieInverseur, _ajouterAutrePoint, _ajouterObservation (+257 more)

### Community 4 - "Community 4"
Cohesion: 0.01
Nodes (151): hashCode, operator, read, typeId, write, Cellule? get, accessible, addPhoto (+143 more)

### Community 5 - "Community 5"
Cohesion: 0.01
Nodes (134): Digest?, add, appVersion, BackupResult, buildBackupFileName, checksum, checksumValid, _classementsByMission (+126 more)

### Community 6 - "Community 6"
Cohesion: 0.03
Nodes (102): AuditInstallationsElectriquesAdapter, FoudreAdapter, class FakePathProviderPlatform extends, toEntity, toModel, VerificateurMapper, FoudreMapper, toEntity (+94 more)

### Community 7 - "Community 7"
Cohesion: 0.02
Nodes (116): ../core/utils/source_status_resolver.dart, accessible, AlimentationEntity, alimentations, alimenteeParTransformateur, annee, anneeFabrication, aReverifier (+108 more)

### Community 8 - "Community 8"
Cohesion: 0.04
Nodes (55): package:flutter_test/flutter_test.dart, package:inspec_app/core/utils/source_status_resolver.dart, package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart, package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart, package:inspec_app/models/audit_installations_electriques.dart, package:inspec_app/services/cellule_types_registry.dart, package:inspec_app/services/dispositions_constructives_registry.dart, package:inspec_app/services/equipment_number_service.dart (+47 more)

### Community 9 - "Community 9"
Cohesion: 0.02
Nodes (88): hashCode, JSADangersAdapter, JSAInspecteurAdapter, operator, read, typeId, write, absenceConsignataireProcedureApplicable (+80 more)

### Community 10 - "Community 10"
Cohesion: 0.02
Nodes (84): EssaiDeclenchementDifferentielAdapter, EssaiDemarrageAutoAdapter, hashCode, operator, PriseTerreAdapter, read, TestArretUrgenceAdapter, typeId (+76 more)

### Community 11 - "Community 11"
Cohesion: 0.02
Nodes (80): absenceConsignataireProcedureApplicable, absenceConsignataireProcedureNA, autre, autreEnvironnement, autrePhysique, autresPoints, balise, boitePharmacie (+72 more)

### Community 12 - "Community 12"
Cohesion: 0.02
Nodes (80): AuditFinding, btCount, btPct, cat1Name, cat2Name, CategoryCrossAnalysisTextGenerator, CategoryCrossItem, categoryKey (+72 more)

### Community 13 - "Community 13"
Cohesion: 0.03
Nodes (69): aCoffretPredefini, _ajouterEssai, AjouterEssaiDeclenchementScreen, _AjouterEssaiDeclenchementScreenState, aLocalisationPredefinie, _annuler, _buildCoffretField, _buildDropdown (+61 more)

### Community 14 - "Community 14"
Cohesion: 0.03
Nodes (66): canonical_risk_family_registry.dart, AnalyticsEngine, armoiresCount, backedUpMissions, BackupStats, category, _CategorySummaryAccumulator, cellulesMTCount (+58 more)

### Community 15 - "Community 15"
Cohesion: 0.03
Nodes (66): Color get, IconData get, _addInspecteur, _autreEnvironnementController, _autreEPIController, _autreExigenceController, _autrePhysiqueController, _autresPointsVerifController (+58 more)

### Community 16 - "Community 16"
Cohesion: 0.03
Nodes (66): FocusNode, _accompagnateurs, _activiteController, _activiteFocus, _activiteSurSiteController, _activiteSurSiteFocus, _activiteSurSiteTouched, _activiteTouched (+58 more)

### Community 17 - "Community 17"
Cohesion: 0.03
Nodes (65): _buildCard, _buildEmpty, _buildList, _buildModernDropdown, _buildTextField, CelluleGammes, champs, _controllers (+57 more)

### Community 18 - "Community 18"
Cohesion: 0.03
Nodes (64): appreciation, avisMesuresTerre, AvisMesuresTerreEntity, calibre, coffret, conditionMesure, ConditionMesureEntity, conditionPriseTerre (+56 more)

### Community 19 - "Community 19"
Cohesion: 0.03
Nodes (63): _animCtrl, _auditProgress, _blockMessage, build, _buildDrawer, _buildDrawerHeader, _buildDrawerItem, _buildNavButtons (+55 more)

### Community 20 - "Community 20"
Cohesion: 0.03
Nodes (60): _ajouterPhotoAObservation, build, _buildBadge, _buildCoffretBadge, _buildCoffretCard, _buildCoffretStat, _buildEmptyState, _buildLocalCard (+52 more)

### Community 21 - "Community 21"
Cohesion: 0.03
Nodes (59): hashCode, operator, read, typeId, write, accompagnateurs, activiteClient, activiteSurSite (+51 more)

### Community 22 - "Community 22"
Cohesion: 0.03
Nodes (59): _ajouterEssai, _ajouterObservation, _ajouterPhotoAObservation, build, _buildAlimentationCard, _buildBooleanInfo, _buildCoffretStats, _buildEssaiCard (+51 more)

### Community 23 - "Community 23"
Cohesion: 0.03
Nodes (59): _ajouterPhotoAObservation, build, _buildBadge, _buildCelluleDetailCard, _buildClassementTab, _buildCoffretCard, _buildElementItem, _buildInfluenceChip (+51 more)

### Community 24 - "Community 24"
Cohesion: 0.05
Nodes (46): @Timeout, dart:io, Directory, migrateExistingUsers, MigrationHelper, package:archive/archive_io.dart, package:crypto/crypto.dart, package:flutter/services.dart (+38 more)

### Community 25 - "Community 25"
Cohesion: 0.04
Nodes (58): _sauvegarder, _allerAuClassement, _editerCoffret, _editerEssai, _ajouterCoffret, _ajouterObservation, _allerAuClassement, _editerCoffret (+50 more)

### Community 26 - "Community 26"
Cohesion: 0.05
Nodes (45): Mission, build, _buildSectionTile, mission, MissionExecutionScreen, _navigateToAudit, _navigateToDescription, build (+37 more)

### Community 27 - "Community 27"
Cohesion: 0.04
Nodes (54): actionPlanHeader, actionPlanSteps, appreciationGlobale, assessmentParagraph1, assessmentParagraph2, assessmentParagraph3, bulletPoints, commentaryParagraph (+46 more)

### Community 28 - "Community 28"
Cohesion: 0.04
Nodes (54): calculateIk3Max, couplageOptions, fonctionCelluleOptions, generateYearsList, getPccAmontForTypeReseau, immersionConservateur, immersionHermetique, InstallationFieldsRegistry (+46 more)

### Community 29 - "Community 29"
Cohesion: 0.05
Nodes (43): MyApp, InvalidFormatDialog, AnalyticsKpiCards, build, _buildKpiCard, data, isDarkMode, build (+35 more)

### Community 30 - "Community 30"
Cohesion: 0.06
Nodes (50): _EtapeInformationsGenerales, ForgotPasswordScreen, _ForgotPasswordScreenState, MissionCard, _MissionCardState, LightingMissionDetailScreen, _LightingMissionDetailScreenState, MissionDetailScreen (+42 more)

### Community 31 - "Community 31"
Cohesion: 0.04
Nodes (49): accompagnateurs, activiteClient, activiteSurSite, adresseClient, auditInstallationsElectriquesId, autresDocuments, classementLocauxId, classementReglementaireCategorie (+41 more)

### Community 32 - "Community 32"
Cohesion: 0.04
Nodes (49): _ajouterLocal, _ajouterZone, _audit, build, _buildBadge, _buildClassementTab, _buildDialogButton, _buildEmptyState (+41 more)

### Community 33 - "Community 33"
Cohesion: 0.04
Nodes (49): AjouterCarteScreen, _AjouterCarteScreenState, _annuler, build, _buildActionButtons, _buildAnneeFabricationField, _buildHeader, _buildModernTextField (+41 more)

### Community 34 - "Community 34"
Cohesion: 0.04
Nodes (48): _ajouterEssai, AjouterEssaiIsolementScreen, _AjouterEssaiIsolementScreenState, _allEquipements, _buildAppreciationButton, _buildEssaiCard, _buildMetricItem, _chargerDonneesExistantes (+40 more)

### Community 35 - "Community 35"
Cohesion: 0.05
Nodes (38): Column, _buildContactItem, buildFirstPageFooter, buildOtherPageFooter, _buildVectorIcon, darkSlateGrey, headerGrey, kesBlue (+30 more)

### Community 36 - "Community 36"
Cohesion: 0.04
Nodes (47): _applyFilters, build, _buildCurrentPageContent, _buildHomeContent, _buildKpiChip, _buildQuickIconButton, _buildSearchBar, createState (+39 more)

### Community 37 - "Community 37"
Cohesion: 0.04
Nodes (46): audit_installations_electriques.dart, hashCode, InstallationItemAdapter, operator, read, typeId, write, addInstallationItem (+38 more)

### Community 38 - "Community 38"
Cohesion: 0.05
Nodes (45): ../datasources/backup_job_store.dart, ../datasources/local_backup_store.dart, ../datasources/microsoft_auth_service.dart, ../datasources/microsoft_graph_storage_service.dart, ../../domain/models/cloud_backup_manifest.dart, MicrosoftAuthService, MicrosoftGraphStorageService, authService (+37 more)

### Community 39 - "Community 39"
Cohesion: 0.07
Nodes (44): init, sl, getMissionsUseCaseProvider, AddDocumentPersonnaliseUseCase, GetAllReportsForMissionUseCase, GetMissionByIdUseCase, GetMissionsUseCase, RemoveDocumentPersonnaliseUseCase (+36 more)

### Community 40 - "Community 40"
Cohesion: 0.04
Nodes (46): _addAnnexesPhotos, _addAuditInstallations, _addCelluleDetails, _addClassementEmplacements, _addCodificationInfluences, _addCoffretDetails, _addCoverPage, _addDescriptionInstallations (+38 more)

### Community 41 - "Community 41"
Cohesion: 0.04
Nodes (45): CustomPainter, activeColor, build, cancel, cancellationToken, _checkAnim, _checkController, checkProgress (+37 more)

### Community 42 - "Community 42"
Cohesion: 0.06
Nodes (38): ../entities/foudre_entity.dart, createFoudreObservationUseCaseProvider, deleteFoudreObservationUseCaseProvider, getFoudreObservationsUseCaseProvider, updateFoudreObservationUseCaseProvider, FoudreRepositoryImpl, createFoudreObservation, deleteFoudreObservation (+30 more)

### Community 43 - "Community 43"
Cohesion: 0.05
Nodes (45): getAllReportsForMissionUseCaseProvider, saveLastReportUseCaseProvider, _buildBottomNavigation, _buildCircleActionButton, _buildGenerateButton, _buildMissionInfoCard, _buildReportCard, _buildReportsList (+37 more)

### Community 44 - "Community 44"
Cohesion: 0.06
Nodes (45): @HiveType, AlimentationAdapter, BasseTensionLocalAdapter, BasseTensionZoneAdapter, CelluleAdapter, CircuitTerminalEquipementAdapter, DepartEquipementAdapter, ElementControleAdapter (+37 more)

### Community 45 - "Community 45"
Cohesion: 0.05
Nodes (44): _addObservation, _ajouterObservation, AjouterZoneScreen, _AjouterZoneScreenState, build, _buildObservationsSection, _buildPhotosSection, _buildRiskZoneSelector (+36 more)

### Community 46 - "Community 46"
Cohesion: 0.05
Nodes (43): , KES INSPECTIONS AND, allowed, attempts, _buildEmailTemplate, _buildPlainTextEmail, charset, _checkSecurityLimits (+35 more)

### Community 47 - "Community 47"
Cohesion: 0.05
Nodes (42): AuditDiagnosticEngine, AuditDiagnosticItem, AuditValidationReport, countCellules, countCritiques, countEquipements, countGroupesElectrogenes, countLignesNon (+34 more)

### Community 48 - "Community 48"
Cohesion: 0.05
Nodes (41): _adEffective, _adValid, _aeEffective, _aeValid, _afEffective, _afValid, _agEffective, _agValid (+33 more)

### Community 49 - "Community 49"
Cohesion: 0.05
Nodes (40): allBTConditionsPoints, allBTDispositionsPoints, allCellulePoints, allCoffretPoints, allConditionsExploitation, allDispositionsConstructives, allGEConditionsPoints, allGEDispositionsPoints (+32 more)

### Community 50 - "Community 50"
Cohesion: 0.05
Nodes (40): AuditFindingInventory, CategoryParetoResult, ParetoAnalysisResult, TensionDomainStats, TopNonConformityCategoriesResult, allNonConformities, categoryParetoResult, compute (+32 more)

### Community 51 - "Community 51"
Cohesion: 0.05
Nodes (38): app_update_migration_service.dart, backup_scheduler_service.dart, BackupOrchestratorState get, AppUpdateMigrationService, _boxName, checkAndTriggerPostUpdateMigration, currentAppVersion, _getBox (+30 more)

### Community 52 - "Community 52"
Cohesion: 0.05
Nodes (39): hashCode, operator, read, typeId, write, ad, adEffective, ae (+31 more)

### Community 53 - "Community 53"
Cohesion: 0.06
Nodes (39): auditInstallationsProvider, _ajouterZone, _audit, BasseTensionScreen, _BasseTensionScreenState, build, _buildClassementTab, _buildEmptyState (+31 more)

### Community 54 - "Community 54"
Cohesion: 0.07
Nodes (36): AsyncValue, getAuditInstallationsUseCaseProvider, saveAuditInstallationsUseCaseProvider, getCurrentUserUseCaseProvider, getJsaByMissionUseCaseProvider, saveJsaUseCaseProvider, getMesuresEssaisUseCaseProvider, saveMesuresEssaisUseCaseProvider (+28 more)

### Community 55 - "Community 55"
Cohesion: 0.05
Nodes (38): canonical_defect_category_registry.dart, allFindings, buildInventory, classifiedCount, critiqueCount, getCategoryParetoAnalysis, getCategorySummary, getCrossCategoryAnalysis (+30 more)

### Community 56 - "Community 56"
Cohesion: 0.07
Nodes (29): ../entities/mission_entity.dart, MissionRepositoryImpl, addDocumentPersonnalise, getAllReportsForMission, getMissionById, getMissionsByMatricule, MissionRepository, removeDocumentPersonnalise (+21 more)

### Community 57 - "Community 57"
Cohesion: 0.05
Nodes (37): build, _buildQrCodeDetectedPanel, _buildScannerInstructions, _buildScannerOverlay, cameraController, _continuerAvecQrCode, createState, dispose (+29 more)

### Community 58 - "Community 58"
Cohesion: 0.06
Nodes (36): build, _buildCircleActionButton, _buildFormState, _buildGenerateButton, _buildHeaderClientCard, _buildHomeScreen, _buildJsaCard, _buildReportCard (+28 more)

### Community 59 - "Community 59"
Cohesion: 0.05
Nodes (36): _animController, badgeBgColor, badgeColor, badgeText, build, _buildClientLogoCard, _buildElectricCard, _buildHeroHeaderBackground (+28 more)

### Community 60 - "Community 60"
Cohesion: 0.06
Nodes (35): JSAAdapter, hashCode, LightingInspectionAdapter, LuminaireQuestionAnswerAdapter, NonConformingLuminaireAdapter, operator, read, typeId (+27 more)

### Community 61 - "Community 61"
Cohesion: 0.07
Nodes (35): ../../data/datasources/backup_job_store.dart, ../../data/datasources/backup_queue_service.dart, ../../data/datasources/microsoft_auth_service.dart, ../../data/datasources/microsoft_graph_storage_service.dart, ../../data/repositories/backup_sync_repository_impl.dart, ../../data/services/app_update_migration_service.dart, ../../data/services/backup_job_manager.dart, ../../data/services/backup_scheduler_service.dart (+27 more)

### Community 62 - "Community 62"
Cohesion: 0.06
Nodes (35): build, _buildSectionWidget, createState, _currentStep, DescriptionInstallationsSequenceScreen, DescriptionInstallationsSequenceScreenState, dispose, _getSavedPosition (+27 more)

### Community 63 - "Community 63"
Cohesion: 0.06
Nodes (34): _AjouterPriseTerreScreen, _AjouterPriseTerreScreenState, build, _buildDropdown, _buildInfoRow, _buildTextField, _conditionMesure, _conditionOptions (+26 more)

### Community 64 - "Community 64"
Cohesion: 0.06
Nodes (33): Animation, AnimationController, _animationController, build, _canResend, _confirmPasswordController, createState, _currentStep (+25 more)

### Community 65 - "Community 65"
Cohesion: 0.07
Nodes (32): missionDetailProvider, _ajouterDocumentPersonnalise, build, _buildDocumentTile, createState, dispose, _documentsStandards, DocumentsStep (+24 more)

### Community 66 - "Community 66"
Cohesion: 0.06
Nodes (32): BackupScreen, _BackupScreenState, build, _buildActionCard, _buildInfoRow, createState, _handleExport, _handleImport (+24 more)

### Community 67 - "Community 67"
Cohesion: 0.06
Nodes (33): build, _buildCircleActionButton, _buildGenerateButton, _buildMissionInfoCard, _buildReportCard, _buildStatCard, _buildSummaryRow, _checkAndRequestStoragePermission (+25 more)

### Community 68 - "Community 68"
Cohesion: 0.06
Nodes (33): AjouterContinuiteResistanceScreen, _AjouterContinuiteResistanceScreenState, _ajouterMesure, _annuler, build, _buildDropdown, _buildEssaiSelector, _buildMesureCard (+25 more)

### Community 69 - "Community 69"
Cohesion: 0.06
Nodes (32): _borderColor, _bottomMargin, _buildCell, _buildCheckbox, _buildCheckboxLine, _buildCheckboxPair, _buildDangersTable, _buildEpcTable (+24 more)

### Community 70 - "Community 70"
Cohesion: 0.06
Nodes (33): _bcryptCost, _checkPasswordStrength, createPassword, deletePassword, errorMessage, _getFailedAttempts, _hashPasswordWithBcrypt, hasPassword (+25 more)

### Community 71 - "Community 71"
Cohesion: 0.06
Nodes (32): _activiteClientCtrl, _activiteSurSiteCtrl, _adresseClientCtrl, build, _buildDisplayField, _buildTextField, _classementCategories, _classementReglementaireCategorie (+24 more)

### Community 72 - "Community 72"
Cohesion: 0.07
Nodes (31): descriptionInstallationsProvider, _addItem, build, _confirmDeleteAllDescriptions, _deleteItem, _editItem, _ajouterObservation, _analyseRisqueFoudre (+23 more)

### Community 73 - "Community 73"
Cohesion: 0.06
Nodes (31): accompagnateurs, activiteClient, activiteSurSite, adresseClient, classementReglementaireCategorie, classementReglementaireType, CreateMissionData, dateIntervention (+23 more)

### Community 74 - "Community 74"
Cohesion: 0.08
Nodes (26): ../entities/verificateur_entity.dart, checkLoginStatusUseCaseProvider, VerificateurRepositoryImpl, getCurrentUser, isUserLoggedIn, saveCurrentUser, VerificateurRepository, call (+18 more)

### Community 75 - "Community 75"
Cohesion: 0.06
Nodes (30): _animController, build, _buildInfoCard, _buildInfoRow, _buildMainButton, _buildReportButton, _buildTeamCard, _buildTeamRow (+22 more)

### Community 76 - "Community 76"
Cohesion: 0.07
Nodes (30): _allMissions, _applyFilters, build, _buildHeaderFiltersBar, _buildPeriodTile, _buildStatusChip, createState, _customEndDate (+22 more)

### Community 77 - "Community 77"
Cohesion: 0.07
Nodes (29): hashCode, operator, read, RenseignementsGenerauxAdapter, typeId, write, accompagnateurs, activite (+21 more)

### Community 78 - "Community 78"
Cohesion: 0.07
Nodes (27): ../datasources/description_installations_local_data_source.dart, ../../domain/entities/description_installations_entity.dart, ../../domain/entities/installation_item_entity.dart, ../../domain/repositories/description_installations_repository.dart, addInstallationItemToSection, _descriptionBox, DescriptionInstallationsLocalDataSource, DescriptionInstallationsLocalDataSourceImpl (+19 more)

### Community 79 - "Community 79"
Cohesion: 0.07
Nodes (29): installation_item_entity.dart, alimentationBasseTension, alimentationCarburant, alimentationMoyenneTension, analyseRisqueFoudre, cpi, DescriptionInstallationsEntity, eclairageSecurite (+21 more)

### Community 80 - "Community 80"
Cohesion: 0.07
Nodes (26): isKnown, _noneOptions, _normalize, resolve, SourceStatusResolver, statusConnue, statusInconnue, _validProtectionTypes (+18 more)

### Community 81 - "Community 81"
Cohesion: 0.07
Nodes (29): BackupJob, BackupJobStatus, cancelledAt, completedAt, copyWith, createdAt, fromJson, id (+21 more)

### Community 82 - "Community 82"
Cohesion: 0.07
Nodes (29): TensionDomain, category, classify, compliantCheckpoints, critiqueCount, density, DomainEntityInstance, DomainObjectType (+21 more)

### Community 83 - "Community 83"
Cohesion: 0.07
Nodes (28): FlutterSecureStorage, _authority, _authorizeUrl, buildAuthUrl, _client, clientId, createCodeChallenge, createCodeVerifier (+20 more)

### Community 84 - "Community 84"
Cohesion: 0.07
Nodes (27): build, equipmentType, isAutoLinked, NormativeSearchSuggestionsWidget, onSelect, onUnlink, queryText, selectedCriticite (+19 more)

### Community 85 - "Community 85"
Cohesion: 0.07
Nodes (27): _adValid, _aeValid, _afValid, _agValid, _beValid, build, _buildIndices, _buildSelecteur (+19 more)

### Community 86 - "Community 86"
Cohesion: 0.07
Nodes (26): domain_entity_instance.dart, AuditFindingInventoryEngine, buildInventory, categoryKey, categoryName, _CategoryTracker, compliantPoints, critiqueCount (+18 more)

### Community 87 - "Community 87"
Cohesion: 0.09
Nodes (24): addDocumentPersonnaliseUseCaseProvider, getMissionByIdUseCaseProvider, removeDocumentPersonnaliseUseCaseProvider, updateDocumentStatusUseCaseProvider, updateMissionStatusUseCaseProvider, updateSchemaOptionUseCaseProvider, addDocumentPersonnalise, load (+16 more)

### Community 88 - "Community 88"
Cohesion: 0.07
Nodes (26): AuditInstallationsMapper, _normRef, toAlimentationEntity, toAlimentationModel, toBasseTensionLocalEntity, toBasseTensionLocalModel, toBasseTensionZoneEntity, toBasseTensionZoneModel (+18 more)

### Community 89 - "Community 89"
Cohesion: 0.08
Nodes (26): build, _buildPhotosSection, canAddPhotos, _choisirPhotoDepuisGalerie, createState, _criticite, dispose, equipmentType (+18 more)

### Community 90 - "Community 90"
Cohesion: 0.07
Nodes (26): affectedItems, autoPurgeExpiredItems, emptyTrash, _findParentTrashId, getAllTrashItems, getTrashCount, getTrashedJSAIds, getTrashedLightingInspectionIds (+18 more)

### Community 91 - "Community 91"
Cohesion: 0.08
Nodes (25): BoxFit, AppImageUtils, build, _buildFallback, _cachedDocDir, cacheHeight, cacheWidth, createState (+17 more)

### Community 92 - "Community 92"
Cohesion: 0.08
Nodes (25): hashCode, operator, read, typeId, write, ad, ae, af (+17 more)

### Community 93 - "Community 93"
Cohesion: 0.08
Nodes (23): build, confirmText, LocalDeletionWarningDialog, message, onConfirm, show, title, build (+15 more)

### Community 94 - "Community 94"
Cohesion: 0.08
Nodes (25): _autreController, _autreSavedValue, _cpiAnneeFabrication, _cpiMarqueController, _cpiNumeroSerieController, _cpiReportAlarme, _cpiSeuilController, _cpiTypeController (+17 more)

### Community 95 - "Community 95"
Cohesion: 0.08
Nodes (22): ../datasources/jsa_local_data_source.dart, ../../domain/entities/jsa_entity.dart, ../../domain/repositories/jsa_repository.dart, getOrCreateJSA, _jsaBox, JsaLocalDataSource, JsaLocalDataSourceImpl, _missionBox (+14 more)

### Community 96 - "Community 96"
Cohesion: 0.08
Nodes (23): ../dispositions_constructives_registry.dart, getReferenceForPoint, hasReference, _normativeReferences, NormativeReferenceService, _canonicalToken, criticite, familleRisque (+15 more)

### Community 97 - "Community 97"
Cohesion: 0.08
Nodes (24): _autreController, build, _buildMultiSelectRegimeBody, _buildSingleSelectBody, _cpiAnneeFabrication, _cpiMarqueController, _cpiNumeroSerieController, _cpiReportAlarme (+16 more)

### Community 98 - "Community 98"
Cohesion: 0.08
Nodes (24): categoryStats, clientName, companyName, computeHash, dateRangeText, domainTension, equipmentCount, ExecutiveSummarySnapshot (+16 more)

### Community 99 - "Community 99"
Cohesion: 0.08
Nodes (21): Color, _availableStatuses, build, createState, _getStatusColor, initState, _isUpdating, mission (+13 more)

### Community 100 - "Community 100"
Cohesion: 0.09
Nodes (21): ../../data/services/backup_orchestrator.dart, child, missionId, ref, updateField, build, _buildSectionCard, createState (+13 more)

### Community 101 - "Community 101"
Cohesion: 0.08
Nodes (21): ../../domain/models/backup_preferences.dart, ../../domain/models/local_backup_item.dart, _boxName, _getBox, getLatestLocalBackup, getLocalBackupsForMission, getMissionBackupDir, LocalBackupStore (+13 more)

### Community 102 - "Community 102"
Cohesion: 0.09
Nodes (23): double get, backupSchedulerServiceProvider, _buildCompactSearchBar, _buildExpandedSearchBar, createState, didChangeAppLifecycleState, dispose, initState (+15 more)

### Community 103 - "Community 103"
Cohesion: 0.08
Nodes (23): executive_summary_cache_entry.dart, executive_summary_snapshot.dart, _boxName, buildDeterministicFallback, _buildPrompt, clearAllCache, clearCacheForMission, geminiApiKey (+15 more)

### Community 104 - "Community 104"
Cohesion: 0.09
Nodes (23): AssetType, build, _buildAssetCard, _buildEmptyCard, _buildHeaderBanner, _buildSectionHeader, _buildSourceOption, ClientLogoScreen (+15 more)

### Community 105 - "Community 105"
Cohesion: 0.09
Nodes (23): build, champs, _controllers, createState, _deleteItem, dispose, index, _initializeControllers (+15 more)

### Community 106 - "Community 106"
Cohesion: 0.12
Nodes (15): package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart, package:inspec_app/features/description_installations/domain/entities/description_installations_entity.dart, package:inspec_app/features/description_installations/domain/entities/installation_item_entity.dart, package:inspec_app/models/description_installations.dart, package:inspec_app/models/pdf/installation_description_pdf_data.dart, package:inspec_app/services/installation_description_sync_service.dart, main, main (+7 more)

### Community 107 - "Community 107"
Cohesion: 0.09
Nodes (20): ../datasources/auth_local_data_source.dart, ../../domain/entities/verificateur_entity.dart, ../../domain/repositories/verificateur_repository.dart, AuthLocalDataSource, AuthLocalDataSourceImpl, _currentUserKey, getCurrentUser, isUserLoggedIn (+12 more)

### Community 108 - "Community 108"
Cohesion: 0.09
Nodes (21): ImagePicker, AddNonConformingLuminaireSheet, _AddNonConformingLuminaireSheetState, _answers, _areAllCurrentSlideElementsAnswered, build, _buildQuestionCardItem, _commentControllers (+13 more)

### Community 109 - "Community 109"
Cohesion: 0.09
Nodes (22): build, _buildPasswordStrengthIndicator, _buildStrengthBar, _checkPasswordStrength, _confirmPasswordCtrl, createState, dispose, _emailCtrl (+14 more)

### Community 110 - "Community 110"
Cohesion: 0.09
Nodes (22): AuditSourceCategory, AuditTableType, batiment, CriticalityLevel, criticite, familleRisque, id, intToCriticality (+14 more)

### Community 111 - "Community 111"
Cohesion: 0.09
Nodes (21): @pragma, ../datasources/backup_queue_service.dart, ../../domain/repositories/backup_sync_repository.dart, authService, callbackDispatcher, checkPreFlightConditions, _daily17h30Timer, dispose (+13 more)

### Community 112 - "Community 112"
Cohesion: 0.12
Nodes (21): class MockPathProviderPlatform extends, MockPlatformInterfaceMixin, PathProviderPlatform, MockPathProviderPlatform, MockPathProviderPlatform, getApplicationDocumentsPath, getApplicationSupportPath, getDownloadsPath (+13 more)

### Community 113 - "Community 113"
Cohesion: 0.09
Nodes (21): Client, dart:math, ../../domain/models/backup_cancel_token.dart, cancelUploadSession, _chunkSize, _client, createUploadSession, downloadBackupFile (+13 more)

### Community 114 - "Community 114"
Cohesion: 0.12
Nodes (21): ConsumerWidget, ../../domain/models/mission_sync_state.dart, backupOrchestratorStateProvider, backupQueueServiceProvider, backupSyncNotifierProvider, build, _refresh, build (+13 more)

### Community 115 - "Community 115"
Cohesion: 0.12
Nodes (21): addInstallationItemUseCaseProvider, getDescriptionInstallationsUseCaseProvider, removeInstallationItemUseCaseProvider, updateDescriptionSelectionUseCaseProvider, updateInstallationItemUseCaseProvider, addFoudreObservation, addInstallationItem, clearAllDescriptions (+13 more)

### Community 116 - "Community 116"
Cohesion: 0.09
Nodes (20): _ajouterCarte, build, _buildCarteItem, champs, createState, _editerCarte, _estChampObservations, initState (+12 more)

### Community 117 - "Community 117"
Cohesion: 0.10
Nodes (21): _allItems, _applyFilters, build, _buildTrashItemCard, _categories, _confirmEmptyTrash, _confirmPermanentDelete, CorbeilleScreen (+13 more)

### Community 118 - "Community 118"
Cohesion: 0.09
Nodes (21): alreadyLinkedCount, ambiguousCount, analyses, autoLinkedCount, bestMatch, candidateMatches, confidenceScore, isAmbiguous (+13 more)

### Community 119 - "Community 119"
Cohesion: 0.10
Nodes (20): CoffretArmoireAdapter, CoffretArmoire, calculateSimilarityScore, depart, equipmentId, EquipmentSearchResult, EquipmentSourceSearchService, _getAllCoffretsWithLocation (+12 more)

### Community 120 - "Community 120"
Cohesion: 0.10
Nodes (20): DescriptionInstallationsAdapter, DescriptionInstallations, _areItemListsEqual, _auditBox, buildLocalisationMap, _celluleAliases, clearAllDescriptions, clearSectionDescriptions (+12 more)

### Community 121 - "Community 121"
Cohesion: 0.10
Nodes (20): hashCode, operator, read, TrashItemAdapter, typeId, write, deletedAt, deletedBy (+12 more)

### Community 122 - "Community 122"
Cohesion: 0.10
Nodes (18): ../datasources/mesures_essais_local_data_source.dart, ../../domain/entities/mesures_essais_entities.dart, ../../domain/repositories/mesures_essais_repository.dart, _box, getOrCreateMesuresEssais, _mBox, _mesuresEssaisBox, MesuresEssaisLocalDataSource (+10 more)

### Community 123 - "Community 123"
Cohesion: 0.13
Nodes (16): ../entities/audit_installations_entities.dart, AuditInstallationsRepositoryImpl, AuditInstallationsRepository, getOrCreateAuditInstallations, saveAuditInstallations, call, GetAuditInstallationsUseCase, repository (+8 more)

### Community 124 - "Community 124"
Cohesion: 0.13
Nodes (16): ../entities/jsa_entity.dart, JsaRepositoryImpl, getOrCreateJSA, JsaRepository, saveJSA, call, GetJsaByMissionUseCase, repository (+8 more)

### Community 125 - "Community 125"
Cohesion: 0.13
Nodes (16): ../entities/mesures_essais_entities.dart, MesuresEssaisRepositoryImpl, getOrCreateMesuresEssais, MesuresEssaisRepository, saveMesuresEssais, call, GetMesuresEssaisUseCase, repository (+8 more)

### Community 126 - "Community 126"
Cohesion: 0.10
Nodes (20): build, _buildModernElementPhotos, _buildModernObservationField, _buildModernPrioriteSelector, _buildPrioriteButton, _choisirPhoto, color, createState (+12 more)

### Community 127 - "Community 127"
Cohesion: 0.10
Nodes (20): build, _buildListTile, _buildRadioTile, _buildSimpleTile, _checkAllSectionsStatus, createState, DescriptionInstallationsScreen, _DescriptionInstallationsScreenState (+12 more)

### Community 128 - "Community 128"
Cohesion: 0.12
Nodes (16): ../entities/description_installations_entity.dart, DescriptionInstallationsRepositoryImpl, DescriptionInstallationsRepository, call, GetDescriptionInstallationsUseCase, repository, call, RemoveInstallationItemUseCase (+8 more)

### Community 129 - "Community 129"
Cohesion: 0.10
Nodes (19): accompagnateurs, activite, activiteSurSite, classementReglementaireCategorie, classementReglementaireType, compteRendu, dateDebut, dateFin (+11 more)

### Community 130 - "Community 130"
Cohesion: 0.11
Nodes (19): build, createState, dispose, _emailController, _errorMessage, _formKey, _isLoading, _isLocked (+11 more)

### Community 131 - "Community 131"
Cohesion: 0.11
Nodes (18): _applyFilter, build, FilterDialog, _filterOptions, missions, _normalizeStatus, selectedFilter, _applySearch (+10 more)

### Community 132 - "Community 132"
Cohesion: 0.10
Nodes (19): build, _buildFallbackLogo, _buildLogoWidget, createState, _formatDate, _getStatusBgColor, _getStatusColor, _getStatusIcon (+11 more)

### Community 133 - "Community 133"
Cohesion: 0.11
Nodes (19): _annuler, AvisMesuresScreen, _AvisMesuresScreenState, build, _buildListChip, createState, dispose, _getPourcentageColor (+11 more)

### Community 134 - "Community 134"
Cohesion: 0.11
Nodes (19): _ajouterObservation, _buildDisplayToggleCard, _buildHeaderStats, _buildObservationCard, _buildPriorityFilter, _buildStatCard, createState, _editerObservation (+11 more)

### Community 135 - "Community 135"
Cohesion: 0.11
Nodes (17): ../datasources/mission_local_data_source.dart, ../../domain/entities/mission_entity.dart, ../../domain/repositories/mission_repository.dart, MissionMapper, toEntity, toModel, addDocumentPersonnalise, getAllReportsForMission (+9 more)

### Community 136 - "Community 136"
Cohesion: 0.13
Nodes (15): ../entities/renseignements_generaux_entity.dart, RenseignementsGenerauxRepositoryImpl, getOrCreateRenseignementsGeneraux, RenseignementsGenerauxRepository, saveRenseignementsGeneraux, call, GetRenseignementsGenerauxUseCase, repository (+7 more)

### Community 137 - "Community 137"
Cohesion: 0.11
Nodes (18): FormState, _batimentLocal, build, createState, _dateVerification, _formKey, initState, inspectionToEdit (+10 more)

### Community 138 - "Community 138"
Cohesion: 0.11
Nodes (18): btRows, _collectAllCellules, _collectAllTransformateurs, _createRowFromCellule, _createRowFromCelluleAndItem, _createRowFromItemOnly, _createRowFromTransformateur, _createRowFromTransformateurAndItem (+10 more)

### Community 139 - "Community 139"
Cohesion: 0.11
Nodes (18): coffretPointTitle, conformite, evaluate, _findLocationForCoffret, hashCode, hasIpOrIk, ik, inverseurPointTitle (+10 more)

### Community 140 - "Community 140"
Cohesion: 0.12
Nodes (17): hashCode, operator, read, typeId, VerificateurAdapter, write, createdAt, email (+9 more)

### Community 141 - "Community 141"
Cohesion: 0.11
Nodes (17): int?, copyWith, errorMessage, fromJson, hasLocalBackup, lastBackupDate, lastLocalBackupDate, localChecksum (+9 more)

### Community 142 - "Community 142"
Cohesion: 0.11
Nodes (17): build, _buildPriorityCard, createState, dispose, _formatDate, _formKey, initState, isEdition (+9 more)

### Community 143 - "Community 143"
Cohesion: 0.12
Nodes (17): build, _buildCpiContent, _buildInfoCard, _buildNonItNotice, _buildStatusOption, CpiSequenceScreen, _CpiSequenceScreenState, createState (+9 more)

### Community 144 - "Community 144"
Cohesion: 0.11
Nodes (17): build, _buildContextDetail, _buildMissionContextBanner, _buildTensionChip, createState, _formatDate, mission, _selectedTension (+9 more)

### Community 145 - "Community 145"
Cohesion: 0.11
Nodes (17): copyWith, currentMissionIndex, currentMissionName, currentMissionProgress, currentStep, errorDetail, isCancelRequested, message (+9 more)

### Community 146 - "Community 146"
Cohesion: 0.12
Nodes (17): @visibleForTesting, testParseCoffrets, testSerializeCoffret, buildEquipementsTableForTesting, buildObsRecapTableUnifieForTesting, buildPhotoNumberRegistryForTest, collectEquipementsMTForTesting, collectObservationsBTForTesting (+9 more)

### Community 147 - "Community 147"
Cohesion: 0.12
Nodes (16): audit_finding.dart, audit_finding_inventory_engine.dart, _cacheTtl, collect, collectSummary, getInventory, invalidateCache, _inventoryCache (+8 more)

### Community 148 - "Community 148"
Cohesion: 0.12
Nodes (17): mesuresEssaisProvider, _transfererEssais, _loadMesures, _sauvegarder, _supprimerMesure, build, _loadEssais, _sauvegarder (+9 more)

### Community 149 - "Community 149"
Cohesion: 0.12
Nodes (16): _buildNavigationTile, _buildSectionHeader, _buildStatusBadge, currentPageIndex, filteredMissions, _logout, onClose, onRefreshMissions (+8 more)

### Community 150 - "Community 150"
Cohesion: 0.12
Nodes (16): build, _buildEmptyState, _buildHeaderClientCard, _buildLocalInspectionCard, _buildStatusBadge, _confirmDelete, createState, initState (+8 more)

### Community 151 - "Community 151"
Cohesion: 0.12
Nodes (16): _analyseRisqueFoudre, build, _buildRadioButton, _buildRadioGroup, createState, _etudeTechniqueFoudre, initState, _isLoading (+8 more)

### Community 152 - "Community 152"
Cohesion: 0.12
Nodes (16): _accompagnateurs, _addAccompagnateur, build, _buildAccompagnateursList, _buildVerificateursList, createState, _deleteAccompagnateur, didUpdateWidget (+8 more)

### Community 153 - "Community 153"
Cohesion: 0.13
Nodes (15): AiProvider, generateStructuredText, modelName, providerName, GeminiRestProvider, GroqRestProvider, package:inspec_app/services/ai/ai_provider.dart, package:inspec_app/services/ai/executive_summary_data.dart (+7 more)

### Community 154 - "Community 154"
Cohesion: 0.15
Nodes (13): ../ai_provider.dart, dart:async, dart:convert, apiKey, generateStructuredText, _modelName, providerName, apiKey (+5 more)

### Community 155 - "Community 155"
Cohesion: 0.15
Nodes (15): ../../domain/models/microsoft_user_profile.dart, microsoftAuthNotifierProvider, microsoftAuthServiceProvider, _BackupHeaderSliverDelegate, _buildCompactAuthButton, build, _buildLoggedInView, _buildLoggedOutView (+7 more)

### Community 156 - "Community 156"
Cohesion: 0.12
Nodes (15): executive_summary_data.dart, decodeJson, encodeJson, ExecutiveSummaryCacheEntry, fromJson, generatedAt, missionId, model (+7 more)

### Community 157 - "Community 157"
Cohesion: 0.13
Nodes (15): AuditInstallationsScreen, _AuditInstallationsScreenState, build, _buildSectionTile, createState, initState, mission, _navigateToBasseTension (+7 more)

### Community 158 - "Community 158"
Cohesion: 0.12
Nodes (14): build, completedMissions, inProgressMissions, pendingMissions, StatsGrid, totalMissions, build, completedMissions (+6 more)

### Community 159 - "Community 159"
Cohesion: 0.12
Nodes (14): CelluleTypesRegistry, getAvailableTypes, typesOfficiels, canonicalFamilies, CanonicalRiskFamilyRegistry, defaultObservations, degradationCanalisations, echauffementSurcharge (+6 more)

### Community 160 - "Community 160"
Cohesion: 0.12
Nodes (15): auditAndFixMissionNumbers, _auditBox, AuditNumberReport, _coffretDraftsBox, duplicatesFixed, ensureEquipmentIdentityAndNumber, EquipmentNumberService, _extractAllCoffretsFromAudit (+7 more)

### Community 161 - "Community 161"
Cohesion: 0.13
Nodes (14): _extractAllFreeObservations, MissionNormativeBatchService, processAudit, analyze, dominanceGapThreshold, highConfidenceThreshold, mediumConfidenceThreshold, NormativeMatchingEngine (+6 more)

### Community 162 - "Community 162"
Cohesion: 0.14
Nodes (13): ../datasources/renseignements_generaux_local_data_source.dart, ../../domain/entities/renseignements_generaux_entity.dart, ../../domain/repositories/renseignements_generaux_repository.dart, getOrCreateRenseignementsGeneraux, _missionBox, _renseignementsGenerauxBox, RenseignementsGenerauxLocalDataSource, RenseignementsGenerauxLocalDataSourceImpl (+5 more)

### Community 163 - "Community 163"
Cohesion: 0.13
Nodes (14): GlobalKey, build, createState, initState, isFirstSlide, isLastSlide, jumpToSection, mission (+6 more)

### Community 164 - "Community 164"
Cohesion: 0.13
Nodes (14): backupCreatedAt, clientName, CloudBackupManifest, fileName, fileSizeBytes, fromJson, inspectorMatricule, inspectorName (+6 more)

### Community 165 - "Community 165"
Cohesion: 0.14
Nodes (14): _annuler, build, ConditionsMesureScreen, _ConditionsMesureScreenState, createState, dispose, _hasData, initState (+6 more)

### Community 166 - "Community 166"
Cohesion: 0.15
Nodes (10): Any, Flutter, FlutterAppDelegate, AppDelegate, Bool, RunnerTests, UIApplication, UIKit (+2 more)

### Community 167 - "Community 167"
Cohesion: 0.14
Nodes (13): hashCode, operator, read, typeId, write, create, createdAt, fromJson (+5 more)

### Community 168 - "Community 168"
Cohesion: 0.15
Nodes (13): hashCode, LastReportAdapter, operator, read, typeId, write, int get, fileName (+5 more)

### Community 169 - "Community 169"
Cohesion: 0.14
Nodes (13): ../../../constants/app_theme.dart, build, _buildRightActionWidget, currentPageIndex, _getAppBarTitle, HomeAppBar, onFilterPressed, onMenuPressed (+5 more)

### Community 170 - "Community 170"
Cohesion: 0.14
Nodes (12): DateTime, createdAt, data, InstallationItemEntity, photoPaths, createdAt, FoudreEntity, id (+4 more)

### Community 171 - "Community 171"
Cohesion: 0.21
Nodes (11): saveDescriptionInstallationsUseCaseProvider, call, repository, UpdateDescriptionSelectionUseCase, package:inspec_app/features/description_installations/domain/usecases/add_installation_item_use_case.dart, package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart, package:inspec_app/features/description_installations/domain/usecases/remove_installation_item_use_case.dart, package:inspec_app/features/description_installations/domain/usecases/save_description_installations_use_case.dart (+3 more)

### Community 172 - "Community 172"
Cohesion: 0.14
Nodes (13): appVersion, copyWith, createdAt, fileName, filePath, fileSizeBytes, fromJson, isSyncedToCloud (+5 more)

### Community 173 - "Community 173"
Cohesion: 0.14
Nodes (12): displayName, email, fromJson, id, jobTitle, MicrosoftUserProfile, officeLocation, toJson (+4 more)

### Community 174 - "Community 174"
Cohesion: 0.15
Nodes (13): _applyCustomDateRange, build, _buildSortSection, createState, _filterByPeriod, _filterByStatus, _formatDate, missions (+5 more)

### Community 175 - "Community 175"
Cohesion: 0.15
Nodes (13): build, createState, DemarrageAutoScreen, _DemarrageAutoScreenState, initState, _isLoading, _isSaving, _loadData (+5 more)

### Community 176 - "Community 176"
Cohesion: 0.15
Nodes (12): ../../domain/models/backup_queue_item.dart, BackupQueueService, _boxName, clearQueue, enqueueOrUpdate, _getBox, getNextEligibleItem, getQueue (+4 more)

### Community 177 - "Community 177"
Cohesion: 0.15
Nodes (12): Exception, BackupCancelledException, addListener, cancel, CancellationToken, generationId, _isCancelled, message (+4 more)

### Community 178 - "Community 178"
Cohesion: 0.15
Nodes (12): addedAt, attemptCount, BackupQueueItem, BackupQueueStatus, copyWith, fromJson, lastError, matricule (+4 more)

### Community 179 - "Community 179"
Cohesion: 0.17
Nodes (12): _box, createFoudreObservation, deleteFoudreObservation, _foudreBox, FoudreLocalDataSource, FoudreLocalDataSourceImpl, getFoudreObservationsByMissionId, _mBox (+4 more)

### Community 180 - "Community 180"
Cohesion: 0.17
Nodes (12): addDocumentPersonnalise, getAllReportsForMission, getMissionById, getMissionsByMatricule, _missionBox, MissionLocalDataSource, MissionLocalDataSourceImpl, removeDocumentPersonnalise (+4 more)

### Community 181 - "Community 181"
Cohesion: 0.15
Nodes (12): build, createState, _getButtonColor, _getButtonText, _handleStatusUpdate, _isButtonEnabled, _isUpdating, mission (+4 more)

### Community 182 - "Community 182"
Cohesion: 0.15
Nodes (12): areAllStepsCompleted, getCompletionPercentage, getGlobalCompletionPercentage, getProgress, getStepData, isStepCompleted, markStepCompleted, _progressBox (+4 more)

### Community 183 - "Community 183"
Cohesion: 0.15
Nodes (12): autresAnomalies, cablagesEtCanalisations, CanonicalDefectCategoryRegistry, eclairageSecurite, envelopesEtArmoires, identificationEtReperage, mapToCanonical, organesDeCoupure (+4 more)

### Community 184 - "Community 184"
Cohesion: 0.23
Nodes (12): ConsumerState, ConsumerStatefulWidget, MesuresEssaisScreen, _MesuresEssaisScreenState, AlimentationSiteMtSequenceScreen, _AlimentationSiteMtSequenceScreenState, DescriptionInstallationsForm, _DescriptionInstallationsFormState (+4 more)

### Community 185 - "Community 185"
Cohesion: 0.17
Nodes (10): ../entities/installation_item_entity.dart, addInstallationItemToSection, getOrCreateDescriptionInstallations, removeInstallationItemFromSection, saveDescriptionInstallations, updateInstallationItemInSection, updateSelection, AddInstallationItemUseCase (+2 more)

### Community 186 - "Community 186"
Cohesion: 0.17
Nodes (11): File, deleteClientLogo, deleteClientQrCode, FileStorageService, getReportsDirectory, getReportsForMission, reportFolderName, saveClientLogo (+3 more)

### Community 187 - "Community 187"
Cohesion: 0.17
Nodes (11): BackupSyncRepositoryImpl, backupSingleMission, BackupSyncRepository, checkAuthStatus, checkSyncStateForAllMissions, getCachedSyncStates, loginWithMicrosoft, logout (+3 more)

### Community 188 - "Community 188"
Cohesion: 0.17
Nodes (11): BackupPreferences, copyWith, fromJson, isAutoBackupEnabled, recommendationDismissCount, recommendationLastShown, requiresCharging, scheduleHour (+3 more)

### Community 189 - "Community 189"
Cohesion: 0.18
Nodes (10): AppTheme, darkBlue, greyDark, greyLight, lightBlue, primaryBlue, textDark, textLight (+2 more)

### Community 190 - "Community 190"
Cohesion: 0.18
Nodes (10): build, createState, initState, _isLoading, _isSaving, _loadData, mission, _options (+2 more)

### Community 191 - "Community 191"
Cohesion: 0.20
Nodes (10): build, createState, CustomDateRangeDialog, _CustomDateRangeDialogState, initialEndDate, initialStartDate, initState, _tempEndDate (+2 more)

### Community 192 - "Community 192"
Cohesion: 0.18
Nodes (10): BackupFileFormat, BackupFormatDetector, BackupFormatInfo, detectFormat, extension, format, isJsonHeader, isSupported (+2 more)

### Community 193 - "Community 193"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 194 - "Community 194"
Cohesion: 0.20
Nodes (9): bool get, BackupCancelToken, cancel, _isCancelled, message, onCancel, _reason, throwIfCancelled (+1 more)

### Community 195 - "Community 195"
Cohesion: 0.20
Nodes (9): dart:ui, _cleanUpChunks, _mergeChunkListToDestination, mergePdfFiles, PdfMergeProgressCallback, PdfMergerService, package:pdf_merger/pdf_merger.dart, package:syncfusion_flutter_pdf/pdf.dart (+1 more)

### Community 196 - "Community 196"
Cohesion: 0.20
Nodes (9): ../datasources/foudre_local_data_source.dart, ../../domain/entities/foudre_entity.dart, ../../domain/repositories/foudre_repository.dart, createFoudreObservation, deleteFoudreObservation, getFoudreObservationsByMissionId, localDataSource, updateFoudreObservation (+1 more)

### Community 197 - "Community 197"
Cohesion: 0.20
Nodes (9): ../../domain/models/backup_job.dart, BackupJobStore, _boxName, deleteJob, getActiveJobForMission, _getBox, getIncompleteJobs, getJob (+1 more)

### Community 198 - "Community 198"
Cohesion: 0.20
Nodes (9): ../hive_service.dart, collectInventory, _isNonConforme, MissionTreeVisitor, _resolveCriticality, _visitBTLocal, _visitEquipement, _visitMTLocal (+1 more)

### Community 199 - "Community 199"
Cohesion: 0.20
Nodes (9): createdAt, email, fullName, id, matricule, nom, password, prenom (+1 more)

### Community 200 - "Community 200"
Cohesion: 0.22
Nodes (8): double?, AppBottomSheet, bottomButton, build, children, maxHeight, title, Widget?

### Community 201 - "Community 201"
Cohesion: 0.28
Nodes (8): msalRecommendationServiceProvider, build, createState, _isVisible, MsalRecommendationBanner, _MsalRecommendationBannerState, onConnectPressed, ../providers/backup_providers.dart

### Community 202 - "Community 202"
Cohesion: 0.29
Nodes (7): Box, AuditInstallationsLocalDataSource, AuditInstallationsLocalDataSourceImpl, _box, _boxName, getOrCreateAuditInstallations, saveAuditInstallations

### Community 203 - "Community 203"
Cohesion: 0.25
Nodes (7): ../datasources/audit_installations_local_data_source.dart, ../../domain/entities/audit_installations_entities.dart, ../../domain/repositories/audit_installations_repository.dart, getOrCreateAuditInstallations, localDataSource, saveAuditInstallations, ../mappers/audit_installations_mapper.dart

### Community 204 - "Community 204"
Cohesion: 0.25
Nodes (7): IconData, build, color, icon, StatCardWidget, title, value

### Community 205 - "Community 205"
Cohesion: 0.25
Nodes (7): backups, build, _buildBackupCard, isLoading, onRefresh, RecentBackupsList, package:share_plus/share_plus.dart

### Community 206 - "Community 206"
Cohesion: 0.25
Nodes (7): build, DateSelectorWidget, firstDate, _formatDate, label, lastDate, selectedDate

### Community 207 - "Community 207"
Cohesion: 0.25
Nodes (6): package:inspec_app/services/statistics/audit_finding.dart, package:inspec_app/services/statistics/domain_entity_instance.dart, package:inspec_app/services/statistics/mission_domain_inventory_engine.dart, package:inspec_app/services/statistics/mission_statistics.dart, main, main

### Community 208 - "Community 208"
Cohesion: 0.29
Nodes (6): build, _getStatusColor, _getStatusIcon, MissionStatusBadge, _normalizeStatus, status

### Community 209 - "Community 209"
Cohesion: 0.29
Nodes (6): EmailService, getRemainingSeconds, resendOtp, sendOtpEmail, verifyOtp, package:inspec_app/services/smtp_email_service.dart

### Community 210 - "Community 210"
Cohesion: 0.33
Nodes (6): AutomaticKeepAliveClientMixin, jsaProvider, build, JsaStep, JsaStepState, _saveJSA

### Community 211 - "Community 211"
Cohesion: 0.33
Nodes (4): package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart, package:inspec_app/features/mesures_essais/domain/entities/mesures_essais_entities.dart, main, main

### Community 212 - "Community 212"
Cohesion: 0.40
Nodes (5): foudreObservationsProvider, AjouterFoudreScreen, _AjouterFoudreScreenState, _sauvegarder, build

### Community 213 - "Community 213"
Cohesion: 0.40
Nodes (5): renseignementsGenerauxProvider, build, GeneralInfoStep, GeneralInfoStepState, _saveData

### Community 214 - "Community 214"
Cohesion: 0.50
Nodes (4): BuildContext, ScreenSize, ScreenSize, ScreenSize

### Community 215 - "Community 215"
Cohesion: 0.50
Nodes (3): package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart, package:inspec_app/features/mission/domain/entities/renseignements_generaux_entity.dart, main

## Knowledge Gaps
- **6058 isolated node(s):** `XCTest`, `queryText`, `equipmentType`, `selectedReferenceNormative`, `selectedFamilleRisque` (+6053 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 6313 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Mission` connect `Community 26` to `Community 0`, `Community 2`, `Community 3`, `Community 132`, `Community 133`, `Community 134`, `Community 5`, `Community 6`, `Community 13`, `Community 142`, `Community 143`, `Community 16`, `Community 17`, `Community 15`, `Community 19`, `Community 20`, `Community 21`, `Community 150`, `Community 22`, `Community 23`, `Community 25`, `Community 151`, `Community 152`, `Community 24`, `Community 157`, `Community 32`, `Community 162`, `Community 34`, `Community 163`, `Community 165`, `Community 43`, `Community 44`, `Community 45`, `Community 175`, `Community 48`, `Community 179`, `Community 180`, `Community 53`, `Community 181`, `Community 57`, `Community 58`, `Community 59`, `Community 60`, `Community 190`, `Community 63`, `Community 62`, `Community 65`, `Community 67`, `Community 68`, `Community 71`, `Community 72`, `Community 75`, `Community 85`, `Community 144`, `Community 93`, `Community 94`, `Community 95`, `Community 97`, `Community 99`, `Community 100`, `Community 104`, `Community 105`, `Community 114`, `Community 116`, `Community 122`, `Community 127`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `BackupSyncRepository` connect `Community 187` to `Community 51`, `Community 61`, `Community 111`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `class` connect `Community 100` to `Community 4`, `Community 37`, `Community 72`, `Community 137`, `Community 10`, `Community 108`, `Community 77`, `Community 46`, `Community 17`, `Community 115`, `Community 116`, `Community 54`, `Community 150`, `Community 60`, `Community 62`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `XCTest`, `queryText`, `equipmentType` to the rest of the system?**
  _6058 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.004514672686230248 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.005934718100890208 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.006688963210702341 - nodes in this community are weakly interconnected._