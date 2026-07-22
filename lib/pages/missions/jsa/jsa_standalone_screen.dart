import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/pages/missions/sequence/steps/jsa_step.dart';
import 'package:inspec_app/services/file_storage_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_jsa_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:inspec_app/widgets/report_generation_loader.dart';

/// Écran Autonome de gestion du module JSA (Analyse de Sécurité du Travail)
/// Dispose de deux états d'affichage :
/// 1. État "Inspection en cours" (formulaire JsaStep direct si incomplète)
/// 2. État "Inspection terminée" (Accueil du module avec résumé et section Rapport)
class JsaStandaloneScreen extends StatefulWidget {
  final Mission mission;

  const JsaStandaloneScreen({
    super.key,
    required this.mission,
  });

  @override
  State<JsaStandaloneScreen> createState() => _JsaStandaloneScreenState();
}

class _JsaStandaloneScreenState extends State<JsaStandaloneScreen> {
  final GlobalKey<JsaStepState> _jsaKey = GlobalKey<JsaStepState>();
  
  bool _isEditingForm = false;
  File? _pdfFile;
  String? _pdfFileName;
  bool _showPdfPreview = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _loadLastReports();
  }

  void _checkInitialState() {
    final isCompleted = HiveService.isJsaCompleted(widget.mission.id);
    // Si la JSA est incomplète, ouvrir directement le formulaire JsaStep
    _isEditingForm = !isCompleted;
  }

  /// Rechargement automatique du dernier rapport JSA généré dans Hive
  Future<void> _loadLastReports() async {
    try {
      final reports = await HiveService.getAllReportsForMission(
        '${widget.mission.id}_jsa',
      );
      if (reports.isNotEmpty) {
        final lastReport = reports.last;
        final file = File(lastReport.filePath);
        if (await file.exists()) {
          setState(() {
            _pdfFile = file;
            _pdfFileName = lastReport.fileName;
            _showPdfPreview = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur rechargement dernier rapport JSA: $e');
      }
    }
  }

  void _openForm() {
    setState(() {
      _isEditingForm = true;
    });
  }

  void _closeForm() {
    final isCompleted = HiveService.isJsaCompleted(widget.mission.id);
    if (isCompleted) {
      setState(() {
        _isEditingForm = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleNext() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.next();
      if (mounted) setState(() {});
      if (!handled) {
        // Validation du dernier slide (slide 5)
        final isCompleted = HiveService.isJsaCompleted(widget.mission.id);
        if (isCompleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ JSA validée avec succès ! Les modules d\'inspection sont déverrouillés.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Transition fluide vers l'écran d'accueil du module JSA
          setState(() {
            _isEditingForm = false;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez compléter toutes les sous-sections de la JSA.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePrevious() async {
    final jsaState = _jsaKey.currentState;
    if (jsaState != null) {
      final handled = await jsaState.previous();
      if (mounted) setState(() {});
      if (!handled) {
        _closeForm();
      }
    }
  }

  /// Dialogue d'information lors du choix du format de rapport
  void _showReportTypeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Générer le rapport JSA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
              ),
              title: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Générer un rapport au format PDF'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _generateJsaPdfReport();
              },
            ),
            const Divider(height: 0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description, color: Colors.blue.shade700),
              ),
              title: const Text('Word', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Générer un rapport au format Word'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showReportPendingDialog('Word');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _generateJsaPdfReport() async {
    setState(() => _isGenerating = true);

    final loaderController = ReportGenerationLoaderController();
    ReportGenerationLoader.show(
      context,
      controller: loaderController,
      message: 'Génération du rapport JSA en cours...',
    );

    try {
      final file = await PdfReportJsaService.generateJsaReport(
        missionId: widget.mission.id,
      );

      if (file != null && file.existsSync()) {
        final fileName = 'Rapport_JSA_${widget.mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final savedFile = await FileStorageService.saveReport(file, fileName);

        final lastReport = LastReport(
          missionId: '${widget.mission.id}_jsa',
          filePath: savedFile.path,
          fileName: fileName,
          generatedAt: DateTime.now(),
          reportType: 'pdf',
        );
        await HiveService.saveLastReport(lastReport);

        // Déclencher l'animation de validation (check) puis fermeture auto
        await loaderController.complete();

        if (mounted) {
          setState(() {
            _pdfFile = savedFile;
            _pdfFileName = fileName;
            _showPdfPreview = true;
          });
        }
      } else {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showError('Erreur lors de la génération');
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showReportPendingDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 6,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Rapport JSA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La génération automatique du document $format pour l\'Analyse de Sécurité (JSA) est préparée.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toutes les données saisies (Opérations, Plan d\'urgence, Dangers, EPC, EPI et Signatures) sont enregistrées et verrouillées.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.green.shade900,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'COMPRIS',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewReport(File file) async {
    try {
      if (!await file.exists()) {
        _showError('Fichier PDF non trouvé');
        return;
      }
      final pdfBytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: path.basename(file.path),
      );
    } catch (e) {
      _showError('Erreur de prévisualisation: $e');
    }
  }

  Future<void> _downloadReport(File file, String fileName) async {
    final hasPermission = await _checkAndRequestStoragePermission();
    if (!hasPermission) {
      _showError('Permission de stockage refusée.');
      return;
    }
    try {
      final savedFile = await FileStorageService.saveReport(file, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport sauvegardé dans ${savedFile.parent.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      if (await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rapport JSA - ${widget.mission.nomClient}',
      text: 'Voici le rapport JSA pour ${widget.mission.nomClient}',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isEditingForm && HiveService.isJsaCompleted(widget.mission.id)) {
              setState(() => _isEditingForm = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _isEditingForm
                  ? 'Formulaire JSA'
                  : 'Analyse de Sécurité (JSA)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isEditingForm
          ? _buildFormState()
          : _buildHomeScreen(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. ÉTAT FORMULAIRE JSA (JsaStep)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFormState() {
    final jsaState = _jsaKey.currentState;
    final isLastStep = jsaState?.isLastSlide ?? false;
    final isFirstStep = jsaState?.isFirstSlide ?? true;

    return Column(
      children: [
        Expanded(
          child: JsaStep(
            key: _jsaKey,
            mission: widget.mission,
            onDataChanged: (data) {},
            onSubStepChanged: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            },
          ),
        ),

        // Barre de commande inférieure
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handlePrevious,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(
                    isFirstStep ? 'RETOUR' : 'PRÉCÉDENT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleNext,
                  icon: Icon(
                    isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(
                    isLastStep ? 'VALIDER' : 'SUIVANT',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastStep ? Colors.green.shade700 : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ÉTAT ÉCRAN D'ACCUEIL DU MODULE JSA (Statut Terminée)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeScreen() {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Carte En-tête Client / Site / Adresse avec Badge de statut
          _buildHeaderClientCard(isSmallScreen),

          const SizedBox(height: 16),

          // 2. Carte Récapitulative JSA
          _buildJsaCard(isSmallScreen),

          const SizedBox(height: 24),

          // 3. Section Rapport JSA
          const Text(
            'RAPPORT D\'ANALYSE DE SÉCURITÉ (JSA)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),

          // Bouton Générer le rapport JSA
          _buildGenerateButton(),

          const SizedBox(height: 16),

          // Affichage du rapport s'il est généré
          if (_showPdfPreview && _pdfFile != null) ...[
            const Text(
              'RAPPORT DISPONIBLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            _buildReportCard(
              file: _pdfFile!,
              fileName: _pdfFileName,
              reportType: 'pdf',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  /// En-tête Carte Client / Site réutilisant les repères visuels des autres modules
  Widget _buildHeaderClientCard(bool isSmallScreen) {
    final currentMission = HiveService.getMissionById(widget.mission.id) ?? widget.mission;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMission.nomClient,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de statut "Terminée"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Terminée',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SITE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.greyDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentMission.nomSite ?? 'Non renseigné',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentMission.adresseClient != null &&
                    currentMission.adresseClient!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'ADRESSE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.greyDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentMission.adresseClient!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Carte Récapitulative de la JSA avec actions et détails
  Widget _buildJsaCard(bool isSmallScreen) {
    final jsa = HiveService.getJSAByMissionId(widget.mission.id);
    final nbInspecteurs = jsa?.inspecteurs.length ?? 0;
    final operation = jsa?.operationEffectuer ?? '';
    final updatedAt = jsa?.updatedAt;
    final dateStr = updatedAt != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(updatedAt)
        : 'Validée';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _openForm,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Analyse de Sécurité (JSA)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Statut : Validée • $dateStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    if (operation.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.work_outline, size: 15, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Opération : $operation',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 15, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Équipe d\'inspection : $nbInspecteurs inspecteur(s)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Consulter / Modifier',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton de génération de rapport identique à celui de SummaryStep et LightingSummaryScreen
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _showReportTypeDialog,
        icon: _isGenerating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_showPdfPreview ? Icons.refresh : Icons.add),
        label: Text(_showPdfPreview ? 'RÉGÉNÉRER' : 'GÉNÉRER'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Carte du rapport disponible — identique à SummaryStep
  Widget _buildReportCard({
    required File file,
    required String? fileName,
    required String reportType,
    required IconData icon,
    required Color color,
  }) {
    final cleanFileName = fileName?.split('/').last ?? 'Rapport généré';
    final isPdf = reportType == 'pdf';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _previewReport(file),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge Type Fichier Stylisé
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPdf
                              ? [Colors.red.shade600, Colors.red.shade400]
                              : [Colors.blue.shade600, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isPdf ? 'PDF' : 'DOCX',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Détails Fichier
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cleanFileName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Cliquez pour prévisualiser',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Boutons d'Action Premium alignés à droite
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCircleActionButton(
                      icon: Icons.download_rounded,
                      tooltip: 'Télécharger',
                      onTap: () => _downloadReport(file, cleanFileName),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleActionButton(
                      icon: Icons.share_rounded,
                      tooltip: 'Partager',
                      onTap: () => _shareReport(file),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleActionButton(
                      icon: Icons.print_rounded,
                      tooltip: 'Imprimer',
                      onTap: () => _previewReport(file),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.grey.shade700),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        tooltip: tooltip,
      ),
    );
  }
}
