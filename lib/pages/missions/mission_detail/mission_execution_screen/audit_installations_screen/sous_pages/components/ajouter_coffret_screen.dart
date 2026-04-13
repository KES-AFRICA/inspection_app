import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ================================================================
// EXTENSION RESPONSIVE
// ================================================================
extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  
  double get fontSizeXXL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get fontSizeXL => isSmallScreen ? 16 : (isMediumScreen ? 17 : 18);
  double get fontSizeL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get fontSizeM => isSmallScreen ? 13 : (isMediumScreen ? 14 : 15);
  double get fontSizeS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get fontSizeXS => isSmallScreen ? 11 : (isMediumScreen ? 12 : 13);
  
  double get spacingXXL => isSmallScreen ? 24 : (isMediumScreen ? 28 : 32);
  double get spacingXL => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get spacingL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get spacingM => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get spacingS => isSmallScreen ? 8 : (isMediumScreen ? 10 : 12);
  double get spacingXS => isSmallScreen ? 6 : (isMediumScreen ? 7 : 8);
  
  double get iconSizeXL => isSmallScreen ? 22 : (isMediumScreen ? 24 : 26);
  double get iconSizeL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get iconSizeM => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get iconSizeS => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get iconSizeXS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
}

// ================================================================
// ÉTAPE 1 : INFORMATIONS DE BASE + PHOTOS + OBSERVATION ÉQUIPEMENT
// ================================================================
class _EtapeInformationsBase extends StatefulWidget {
  final TextEditingController nomController;
  final TextEditingController repereController;
  final String? selectedType;
  final Function(String?) onTypeChanged;
  final bool typeValid;
  final bool nomValid;
  final bool repereValid;
  final VoidCallback onValidateNom;
  final VoidCallback onValidateRepere;
  final List<String> photosExterne;
  final List<String> photosInterne;
  final Function() onPrendrePhotoExterne;
  final Function() onChoisirPhotoExterne;
  final Function() onPrendrePhotoInterne;
  final Function() onChoisirPhotoInterne;
  final bool isLoadingPhotosExterne;
  final bool isLoadingPhotosInterne;
  final Function(int) onSupprimerPhotoExterne;
  final Function(int) onSupprimerPhotoInterne;
  final bool isInZone;
  
  // Observation équipement
  final TextEditingController observationController;
  final List<String> observationPhotos;
  final Function() onPrendrePhotoObservation;
  final Function() onChoisirPhotoObservation;
  final String? selectedNiveauPuissance;
  final Function(String?) onNiveauPuissanceChanged;

  const _EtapeInformationsBase({
    required this.nomController,
    required this.repereController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.typeValid,
    required this.nomValid,
    required this.repereValid,
    required this.onValidateNom,
    required this.onValidateRepere,
    required this.photosExterne,
    required this.photosInterne,
    required this.onPrendrePhotoExterne,
    required this.onChoisirPhotoExterne,
    required this.onPrendrePhotoInterne,
    required this.onChoisirPhotoInterne,
    required this.isLoadingPhotosExterne,
    required this.isLoadingPhotosInterne,
    required this.onSupprimerPhotoExterne,
    required this.onSupprimerPhotoInterne,
    required this.isInZone,
    required this.observationController,
    required this.observationPhotos,
    required this.onPrendrePhotoObservation,
    required this.onChoisirPhotoObservation,
    required this.selectedNiveauPuissance,
    required this.onNiveauPuissanceChanged,
  });

  @override
  State<_EtapeInformationsBase> createState() => _EtapeInformationsBaseState();
}

class _EtapeInformationsBaseState extends State<_EtapeInformationsBase> {
  final PageController _photosExterneController = PageController();
  final PageController _photosInterneController = PageController();
  int _currentExterneIndex = 0;
  int _currentInterneIndex = 0;

  
  final List<Map<String, dynamic>> _niveauPuissanceOptions = [
    {'value': 'tres_petites_sections', 'label': 'Très petites sections', 'icon': Icons.energy_savings_leaf},
    {'value': 'installations_domestiques', 'label': 'Installations domestiques / tertiaires', 'icon': Icons.home},
    {'value': 'puissances_moyennes', 'label': 'Puissances moyennes', 'icon': Icons.business},
    {'value': 'puissances_evelees', 'label': 'Puissances élevées / industrie', 'icon': Icons.factory},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations de base', 1, 4),
        SizedBox(height: context.spacingXL),
        
        if (widget.isInZone)
          Container(
            padding: EdgeInsets.all(context.spacingS),
            margin: EdgeInsets.only(bottom: context.spacingM),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(context.spacingS),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: context.iconSizeS),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Cet équipement sera ajouté dans une zone',
                    style: TextStyle(fontSize: context.fontSizeXS, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        
        _buildModernTextField(
          context,
          controller: widget.nomController,
          label: 'Nom de l\'équipement',
          icon: Icons.label_outline,
          isValid: widget.nomValid,
          onChanged: (_) => widget.onValidateNom(),
        ),
        SizedBox(height: context.spacingM),
        
        _buildModernTextField(
          context,
          controller: widget.repereController,
          label: 'Repère',
          icon: Icons.location_on_sharp,
          isValid: widget.repereValid,
          onChanged: (_) => widget.onValidateRepere(),
        ),
        SizedBox(height: context.spacingM),
        
        _buildModernTypeSelector(context),
        SizedBox(height: context.spacingXL),
        
        _buildModernPhotoCarousel(
          context,
          title: 'PHOTO EXTERNE (obligatoire)',
          photos: widget.photosExterne,
          controller: _photosExterneController,
          currentIndex: _currentExterneIndex,
          onPageChanged: (index) => setState(() => _currentExterneIndex = index),
          isLoading: widget.isLoadingPhotosExterne,
          onPrendrePhoto: widget.onPrendrePhotoExterne,
          onChoisirPhoto: widget.onChoisirPhotoExterne,
          onSupprimerPhoto: widget.onSupprimerPhotoExterne,
          isRequired: true,
        ),
        SizedBox(height: context.spacingXL),
        
        _buildModernPhotoCarousel(
          context,
          title: 'PHOTO INTERNE (obligatoire)',
          photos: widget.photosInterne,
          controller: _photosInterneController,
          currentIndex: _currentInterneIndex,
          onPageChanged: (index) => setState(() => _currentInterneIndex = index),
          isLoading: widget.isLoadingPhotosInterne,
          onPrendrePhoto: widget.onPrendrePhotoInterne,
          onChoisirPhoto: widget.onChoisirPhotoInterne,
          onSupprimerPhoto: widget.onSupprimerPhotoInterne,
          isRequired: true,
        ),
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: context.spacingS,
                    offset: Offset(0, context.spacingXS),
                  ),
                ],
              ),
              child: Icon(Icons.edit_note, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isValid,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: context.fontSizeM),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeM),
          prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: context.iconSizeM),
          suffixIcon: isValid ? Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeS) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildModernTypeSelector(BuildContext context) {
    const types = ['INVERSEUR', 'Armoire', 'Coffret', 'TGBT'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.spacingL, context.spacingM, context.spacingL, context.spacingS),
            child: Row(
              children: [
                Icon(Icons.category_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Type d\'équipement',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
                Text(' *', style: TextStyle(color: Colors.red, fontSize: context.fontSizeL)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(
                  color: !widget.typeValid ? Colors.red.shade300 : Colors.grey.shade300,
                  width: !widget.typeValid ? 1.5 : 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: widget.selectedType,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(context.spacingM),
                hint: Row(
                  children: [
                    Icon(Icons.search, size: context.iconSizeS, color: Colors.grey.shade500),
                    SizedBox(width: context.spacingS),
                    Flexible(
                      child: Text(
                        'Sélectionnez un type',
                        style: TextStyle(fontSize: context.fontSizeM, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
                ),
                style: TextStyle(fontSize: context.fontSizeM, color: AppTheme.darkBlue, fontWeight: FontWeight.w500),
                items: types.map((t) => DropdownMenuItem<String>(
                  value: t,
                  child: Row(
                    children: [
                      Container(
                        width: context.spacingS,
                        height: context.spacingS,
                        decoration: BoxDecoration(
                          color: widget.selectedType == t ? AppTheme.primaryBlue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.selectedType == t ? AppTheme.primaryBlue : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: widget.selectedType == t ? Icon(Icons.check, size: context.spacingXS, color: Colors.white) : null,
                      ),
                      SizedBox(width: context.spacingS),
                      Expanded(child: Text(t, style: TextStyle(fontSize: context.fontSizeM))),
                    ],
                  ),
                )).toList(),
                onChanged: widget.onTypeChanged,
                selectedItemBuilder: (BuildContext context) {
                  return types.map<Widget>((t) {
                    return Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: context.iconSizeS),
                        SizedBox(width: context.spacingS),
                        Expanded(child: Text(t, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: AppTheme.darkBlue))),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
          if (!widget.typeValid)
            Padding(
              padding: EdgeInsets.only(left: context.spacingL, bottom: context.spacingM),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: context.iconSizeXS),
                  SizedBox(width: context.spacingXS),
                  Text('Sélectionnez un type', style: TextStyle(color: Colors.red, fontSize: context.fontSizeXS)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoCarousel(
    BuildContext context, {
    required String title,
    required List<String> photos,
    required PageController controller,
    required int currentIndex,
    required Function(int) onPageChanged,
    required bool isLoading,
    required Function() onPrendrePhoto,
    required Function() onChoisirPhoto,
    required Function(int) onSupprimerPhoto,
    bool isRequired = false,
  }) {
    final photoHeight = context.screenHeight * 0.2;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Icon(Icons.photo_camera_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (photos.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.spacingL),
                    ),
                    child: Text(
                      '${photos.length}',
                      style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
          
          if (isLoading)
            SizedBox(
              height: photoHeight,
              width: double.infinity,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            )
          else if (photos.isEmpty)
            Container(
              height: photoHeight,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: context.spacingL),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: isRequired ? Colors.red.shade300 : Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: context.iconSizeXL * 1.2,
                    color: isRequired ? Colors.red.shade400 : Colors.grey.shade400,
                  ),
                  SizedBox(height: context.spacingS),
                  Text(
                    isRequired ? 'Photo obligatoire' : 'Aucune photo',
                    style: TextStyle(color: isRequired ? Colors.red : Colors.grey.shade600, fontSize: context.fontSizeS),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  height: photoHeight,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: context.spacingL),
                  child: PageView.builder(
                    controller: controller,
                    onPageChanged: onPageChanged,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          // Image
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.spacingS),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(context.spacingS),
                              child: Image.file(File(photos[index]), fit: BoxFit.cover),
                            ),
                          ),
                          // Bouton de suppression
                          Positioned(
                            top: context.spacingS,
                            right: context.spacingS + context.spacingXS,
                            child: GestureDetector(
                              onTap: () => onSupprimerPhoto(index),
                              child: Container(
                                padding: EdgeInsets.all(context.spacingXS),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: context.iconSizeS,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Indicateur de numéro de photo (optionnel)
                          Positioned(
                            bottom: context.spacingS,
                            left: context.spacingS + context.spacingXS,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(context.spacingL),
                              ),
                              child: Text(
                                '${index + 1}/${photos.length}',
                                style: TextStyle(
                                  fontSize: context.fontSizeXS,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (photos.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacingS, bottom: context.spacingS),
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: photos.length,
                      effect: WormEffect(
                        dotWidth: context.spacingS,
                        dotHeight: context.spacingS,
                        activeDotColor: AppTheme.primaryBlue,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
              ],
            ),

          // Boutons ajouter photo (toujours visibles pour permettre d'en rajouter)
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrendrePhoto,
                    icon: Icon(Icons.camera_alt_outlined, size: context.iconSizeS),
                    label: Text('Caméra', style: TextStyle(fontSize: context.fontSizeXS)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                      padding: EdgeInsets.symmetric(vertical: context.spacingS),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                    ),
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChoisirPhoto,
                    icon: Icon(Icons.photo_library_outlined, size: context.iconSizeS),
                    label: Text('Galerie', style: TextStyle(fontSize: context.fontSizeXS)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                      padding: EdgeInsets.symmetric(vertical: context.spacingS),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ÉTAPE 2 : INFORMATIONS GÉNÉRALES (Checkboxes + Domaine tension)
// ================================================================
class _EtapeInformationsGenerales extends StatelessWidget {
  final bool zoneAtex;
  final Function(bool?) onZoneAtexChanged;
  final bool identificationArmoire;
  final Function(bool?) onIdentificationArmoireChanged;
  final bool signalisationDanger;
  final Function(bool?) onSignalisationDangerChanged;
  final bool presenceSchema;
  final Function(bool?) onPresenceSchemaChanged;
  final bool presenceParafoudre;
  final Function(bool?) onPresenceParafoudreChanged;
  final bool verificationThermographie;
  final Function(bool?) onVerificationThermographieChanged;
  final String domaineTension;
  final Function(String?) onDomaineTensionChanged;
  final bool domaineTensionValid;

  const _EtapeInformationsGenerales({
    required this.zoneAtex,
    required this.onZoneAtexChanged,
    required this.identificationArmoire,
    required this.onIdentificationArmoireChanged,
    required this.signalisationDanger,
    required this.onSignalisationDangerChanged,
    required this.presenceSchema,
    required this.onPresenceSchemaChanged,
    required this.presenceParafoudre,
    required this.onPresenceParafoudreChanged,
    required this.verificationThermographie,
    required this.onVerificationThermographieChanged,
    required this.domaineTension,
    required this.onDomaineTensionChanged,
    required this.domaineTensionValid,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations générales', 2, 4),
        SizedBox(height: context.spacingXL),
        
        _buildModernCheckbox(context, 'Zone ATEX', zoneAtex, onZoneAtexChanged),
        _buildModernCheckbox(context, 'Identification de l\'armoire', identificationArmoire, onIdentificationArmoireChanged),
        _buildModernCheckbox(context, 'Signalisation de danger électrique', signalisationDanger, onSignalisationDangerChanged),
        _buildModernCheckbox(context, 'Présence de schéma électrique', presenceSchema, onPresenceSchemaChanged),
        _buildModernCheckbox(context, 'Présence de parafoudre', presenceParafoudre, onPresenceParafoudreChanged),
        _buildModernCheckbox(context, 'Vérification par thermographie', verificationThermographie, onVerificationThermographieChanged),
        
        SizedBox(height: context.spacingXL),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: !domaineTensionValid ? Colors.red.shade300 : Colors.grey.shade300,
              width: !domaineTensionValid ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: domaineTension.isNotEmpty ? domaineTension : null,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(context.spacingS),
            hint: Row(
              children: [
                Icon(Icons.electrical_services, size: context.iconSizeS, color: Colors.grey.shade500),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Sélectionnez un domaine',
                    style: TextStyle(fontSize: context.fontSizeM, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(fontSize: context.fontSizeM, color: AppTheme.darkBlue, fontWeight: FontWeight.w500),
            items: ['230/400', '400/690', 'Autre'].map((t) => DropdownMenuItem<String>(
              value: t,
              child: Row(
                children: [
                  Container(
                    width: context.spacingS,
                    height: context.spacingS,
                    decoration: BoxDecoration(
                      color: domaineTension == t ? AppTheme.primaryBlue : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: domaineTension == t ? AppTheme.primaryBlue : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: domaineTension == t ? Icon(Icons.check, size: context.spacingXS, color: Colors.white) : null,
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(fontSize: context.fontSizeM),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
            onChanged: onDomaineTensionChanged,
            selectedItemBuilder: (BuildContext context) {
              return ['230/400', '400/690', 'Autre'].map<Widget>((t) {
                return Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: context.iconSizeS),
                    SizedBox(width: context.spacingS),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: AppTheme.darkBlue),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: context.spacingS,
                    offset: Offset(0, context.spacingXS),
                  ),
                ],
              ),
              child: Icon(Icons.info_outline, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildModernCheckbox(BuildContext context, String label, bool value, Function(bool?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: CheckboxListTile(
        title: Text(label, style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingM)),
      ),
    );
  }
}

// ================================================================
// ÉTAPE 3 : ALIMENTATIONS
// ================================================================
class _EtapeAlimentations extends StatefulWidget {
  final String? selectedType;
  final List<Alimentation> alimentations;
  final Alimentation? protectionTete;
  final VoidCallback onDataChanged;

  const _EtapeAlimentations({
    required this.selectedType,
    required this.alimentations,
    required this.protectionTete,
    required this.onDataChanged,
  });

  @override
  State<_EtapeAlimentations> createState() => _EtapeAlimentationsState();
}

class _EtapeAlimentationsState extends State<_EtapeAlimentations> {
  final List<String> _typeProtectionOptions = const [
    'Sectionneur porte Fusibles',
    'Fusibles',
    'Disjoncteurs magnétothermiques',
    'Interrupteurs-sectionneur',
    'Disjoncteurs différentiels',
    'Interrupteurs différentiels',
  ];

  final List<String> _sectionCableOptions = const [
    '1.5 mm²', '2.5 mm²', '4 mm²', '6 mm²', '10 mm²', '16 mm²',
    '25 mm²', '35 mm²', '50 mm²', '70 mm²', '95 mm²', '120 mm²',
    '150 mm²', '185 mm²', '240 mm²', '300 mm²',
  ];

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (int i = 0; i < widget.alimentations.length; i++) {
      final a = widget.alimentations[i];
      _controllers['alim${i}_pdc'] = TextEditingController(text: a.pdcKA);
      _controllers['alim${i}_calibre'] = TextEditingController(text: a.calibre);
    }
    if (widget.protectionTete != null) {
      _controllers['prot_pdc'] = TextEditingController(text: widget.protectionTete!.pdcKA);
      _controllers['prot_calibre'] = TextEditingController(text: widget.protectionTete!.calibre);
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _updateAlimentation(Alimentation a, String field, String value) {
    setState(() {
      switch (field) {
        case 'typeProtection': a.typeProtection = value; break;
        case 'pdcKA': a.pdcKA = value; break;
        case 'calibre': a.calibre = value; break;
        case 'sectionCable': a.sectionCable = value; break;
      }
      widget.onDataChanged();
    });
  }

  void _updateProtectionTete(String field, String value) {
    if (widget.protectionTete != null) {
      setState(() {
        switch (field) {
          case 'typeProtection': widget.protectionTete!.typeProtection = value; break;
          case 'pdcKA': widget.protectionTete!.pdcKA = value; break;
          case 'calibre': widget.protectionTete!.calibre = value; break;
          case 'sectionCable': widget.protectionTete!.sectionCable = value; break;
        }
        widget.onDataChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Alimentations', 3, 4),
        SizedBox(height: context.spacingXL),
        
        if (widget.selectedType == 'INVERSEUR') ...[
          if (widget.alimentations.length >= 3) ...[
            _buildAlimentationCard(
              context, 
              'ALIMENTATION 1', 
              widget.alimentations[0], 
              (field, value) => _updateAlimentation(widget.alimentations[0], field, value),
              index: 0,
            ),
            _buildAlimentationCard(
              context, 
              'ALIMENTATION 2', 
              widget.alimentations[1], 
              (field, value) => _updateAlimentation(widget.alimentations[1], field, value),
              index: 1,
            ),
            _buildAlimentationCard(
              context, 
              'SORTIE INVERSEUR', 
              widget.alimentations[2], 
              (field, value) => _updateAlimentation(widget.alimentations[2], field, value),
              index: 2,
            ),
          ],
        ] else ...[
          if (widget.alimentations.isNotEmpty)
            _buildAlimentationCard(
              context, 
              'ORIGINE DE LA SOURCE', 
              widget.alimentations[0], 
              (field, value) => _updateAlimentation(widget.alimentations[0], field, value),
              index: 0,
            ),
          if (widget.protectionTete != null)
            _buildAlimentationCard(
              context, 
              'PROTECTION DE TÊTE', 
              widget.protectionTete!, 
              (field, value) => _updateProtectionTete(field, value),
              isProtectionTete: true,
            ),
        ],
        SizedBox(height: context.spacingXXL),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, String title, int currentStep, int totalSteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.iconSizeXL * 1.2,
              height: context.iconSizeXL * 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(context.spacingS),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: context.spacingS,
                    offset: Offset(0, context.spacingXS),
                  ),
                ],
              ),
              child: Icon(Icons.power, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingM),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildAlimentationCard(
    BuildContext context,
    String title,
    Alimentation a,
    Function(String field, String value) onChanged, {
    bool isProtectionTete = false,
    int? index,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingL),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(context.spacingS),
            ),
            child: Text(
              title,
              style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
            ),
          ),
          SizedBox(height: context.spacingM),
          
          _buildModernDropdown(
            context,
            label: 'Type de protection *',
            value: a.typeProtection,
            items: _typeProtectionOptions,
            onChanged: (v) => onChanged('typeProtection', v),
          ),
          SizedBox(height: context.spacingS),
          
          _buildModernTextField(
            context,
            label: 'PDC kA *',
            controller: isProtectionTete 
                ? _controllers['prot_pdc']!
                : _controllers['alim${index}_pdc']!,
            onChanged: (v) => onChanged('pdcKA', v),
          ),
          SizedBox(height: context.spacingS),
          
          _buildModernTextField(
            context,
            label: isProtectionTete ? 'Calibre protection *' : 'Calibre *',
            controller: isProtectionTete 
                ? _controllers['prot_calibre']!
                : _controllers['alim${index}_calibre']!,
            onChanged: (v) => onChanged('calibre', v),
          ),
          SizedBox(height: context.spacingS),
          
          _buildModernDropdown(
            context,
            label: 'Section de câble *',
            value: a.sectionCable,
            items: _sectionCableOptions,
            onChanged: (v) => onChanged('sectionCable', v),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: context.fontSizeS),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
      ),
    );
  }

  Widget _buildModernDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    final isValid = value.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: isValid ? Colors.grey.shade300 : Colors.red.shade300,
          width: isValid ? 1 : 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: isValid ? Colors.grey.shade600 : Colors.red),
        hint: Text(
          'Sélectionnez...',
          style: TextStyle(fontSize: context.fontSizeS, color: isValid ? Colors.grey.shade500 : Colors.red.shade400),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: isValid ? Colors.grey.shade600 : Colors.red.shade400),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: TextStyle(fontSize: context.fontSizeS)),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

// ================================================================
// ÉTAPE 4 : POINTS DE VÉRIFICATION (MODIFIÉ)
// ================================================================
class _EtapePointsVerification extends StatefulWidget {
  final List<PointVerification> pointsVerification;
  final Map<int, List<String>> pointSuggestions;
  final Map<int, bool> pointLoading;
  final Map<int, bool> hasObservation;
  final Function(int, String) onObservationChanged;
  final Function(int, String, PointVerification) onUseSuggestion;
  final Function(int, bool) onObservationToggleChanged;

  const _EtapePointsVerification({
    super.key,
    required this.pointsVerification,
    required this.pointSuggestions,
    required this.pointLoading,
    required this.hasObservation,
    required this.onObservationChanged,
    required this.onUseSuggestion,
    required this.onObservationToggleChanged,
  });

  @override
  State<_EtapePointsVerification> createState() => _EtapePointsVerificationState();
}

class _EtapePointsVerificationState extends State<_EtapePointsVerification> {
  final PageController _slideController = PageController();
  int _currentSlide = 0;
  
  late List<List<PointVerification>> _pointsSlides;

  @override
  void initState() {
    super.initState();
    _buildSlides();
  }

  void _buildSlides() {
    _pointsSlides = [];
    for (int i = 0; i < widget.pointsVerification.length; i += 3) {
      final end = (i + 3).clamp(0, widget.pointsVerification.length);
      _pointsSlides.add(widget.pointsVerification.sublist(i, end));
    }
  }

  int get _totalSlides => _pointsSlides.length;
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;

  bool _isCurrentSlideValid() {
    if (_pointsSlides.isEmpty) return true;
    
    final currentPoints = _pointsSlides[_currentSlide];
    for (var point in currentPoints) {
      if (point.conformite.isEmpty || point.conformite == 'non_applicable') {
        continue;
      }
    }
    return true;
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      _showError('Veuillez sélectionner la conformité pour tous les points');
      return;
    }
    
    if (!_isLastSlide) {
      _slideController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousSlide() {
    if (_currentSlide > 0) {
      _slideController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool canGoNext() {
    if (!_isCurrentSlideValid()) return false;
    return _isLastSlide;
  }

  @override
  Widget build(BuildContext context) {
    if (_totalSlides == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: context.iconSizeXL * 1.5, color: Colors.green),
            SizedBox(height: context.spacingM),
            Text('Aucun point à vérifier', style: TextStyle(fontSize: context.fontSizeL, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.iconSizeXL,
                height: context.iconSizeXL,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Icon(Icons.checklist, color: Colors.white, size: context.iconSizeM),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points de vérification',
                      style: TextStyle(fontSize: context.fontSizeXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                    ),
                    Text(
                      '${widget.pointsVerification.length} points - Slide ${_currentSlide + 1}/${_totalSlides}',
                      style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingS),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              final slidePoints = _pointsSlides[slideIndex];
              final startIndex = slideIndex * 3;
              
              return ListView(
                padding: EdgeInsets.all(context.spacingL),
                children: slidePoints.asMap().entries.map((entry) {
                  final pointIndex = startIndex + entry.key;
                  return _buildModernPointCard(context, entry.value, pointIndex);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernPointCard(BuildContext context, PointVerification point, int pointIndex) {
    final suggestions = widget.pointSuggestions[pointIndex] ?? [];
    final isLoading = widget.pointLoading[pointIndex] ?? false;
    final hasObservation = widget.hasObservation[pointIndex] ?? false;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingL),
      padding: EdgeInsets.all(context.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.iconSizeL,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Center(
                  child: Text(
                    '${pointIndex + 1}',
                    style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  point.pointVerification,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.darkBlue, height: 1.3),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Conformité et Référence normative
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConformiteSelector(context, point)),
              SizedBox(width: context.spacingS),
              Expanded(child: _buildReferenceNormativeField(context, point)),
            ],
          ),
          
          // Toggle Observation
          SizedBox(height: context.spacingM),
          _buildObservationToggle(context, pointIndex, hasObservation),
          
          // Champ Observation (conditionnel)
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            _buildObservationField(context, point, pointIndex, suggestions, isLoading),
          ],
        ],
      ),
    );
  }

  Widget _buildConformiteSelector(BuildContext context, PointVerification point) {
    final isValid = point.conformite.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: isValid ? Colors.grey.shade300 : Colors.red.shade300,
          width: isValid ? 1 : 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: point.conformite.isNotEmpty ? point.conformite : null,
        hint: Text(
          'Conformité *',
          style: TextStyle(fontSize: context.fontSizeS, color: isValid ? Colors.grey.shade500 : Colors.red.shade400),
        ),
        isExpanded: true,
        onChanged: (v) {
          setState(() {
            point.conformite = v!;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
        ),
        items: [
          DropdownMenuItem(
            value: 'oui',
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Oui', style: TextStyle(fontSize: context.fontSizeS, color: Colors.green))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'non',
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Non', style: TextStyle(fontSize: context.fontSizeS, color: Colors.red))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'non_applicable',
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Non applicable', style: TextStyle(fontSize: context.fontSizeS, color: Colors.orange))),
              ],
            ),
          ),
        ],
        selectedItemBuilder: (BuildContext context) {
          return ['oui', 'non', 'non_applicable'].map<Widget>((value) {
            Color color;
            String text;
            switch (value) {
              case 'oui': color = Colors.green; text = 'Oui'; break;
              case 'non': color = Colors.red; text = 'Non'; break;
              default: color = Colors.orange; text = 'NA';
            }
            return Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text(text, style: TextStyle(fontSize: context.fontSizeS, color: color))),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildReferenceNormativeField(BuildContext context, PointVerification point) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        initialValue: point.referenceNormative ?? '',
        style: TextStyle(fontSize: context.fontSizeS),
        onChanged: (value) {
          point.referenceNormative = value.isEmpty ? null : value;
        },
        decoration: InputDecoration(
          labelText: 'Référence normative',
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
          hintText: 'Ex: NFC 15-100',
          hintStyle: TextStyle(fontSize: context.fontSizeXS, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildObservationToggle(BuildContext context, int pointIndex, bool hasObservation) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'Ajouter une observation ?',
            style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: context.spacingS),
        GestureDetector(
          onTap: () => widget.onObservationToggleChanged(pointIndex, true),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: hasObservation ? Colors.green.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
              border: Border.all(
                color: hasObservation ? Colors.green : Colors.grey.shade300,
                width: hasObservation ? 2 : 1,
              ),
            ),
            child: Text('Oui', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: hasObservation ? Colors.green : Colors.grey.shade600)),
          ),
        ),
        SizedBox(width: context.spacingS),
        GestureDetector(
          onTap: () => widget.onObservationToggleChanged(pointIndex, false),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: !hasObservation ? Colors.red.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
              border: Border.all(
                color: !hasObservation ? Colors.red : Colors.grey.shade300,
                width: !hasObservation ? 2 : 1,
              ),
            ),
            child: Text('Non', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: !hasObservation ? Colors.red : Colors.grey.shade600)),
          ),
        ),
      ],
    );
  }

  Widget _buildObservationField(BuildContext context, PointVerification point, int pointIndex, List<String> suggestions, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            initialValue: point.observation ?? '',
            style: TextStyle(fontSize: context.fontSizeS),
            onChanged: (value) {
              point.observation = value;
              widget.onObservationChanged(pointIndex, value);
            },
            decoration: InputDecoration(
              hintText: 'Saisissez votre observation...',
              hintStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.spacingM),
            ),
            maxLines: 3,
          ),
        ),
        
        if (suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: context.spacingS),
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: context.iconSizeXS, color: Colors.amber),
                    SizedBox(width: context.spacingXS),
                    Text('Suggestions', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ],
                ),
                SizedBox(height: context.spacingXS),
                Wrap(
                  spacing: context.spacingS,
                  runSpacing: context.spacingXS,
                  children: suggestions.map((s) => GestureDetector(
                    onTap: () => widget.onUseSuggestion(pointIndex, s, point),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.spacingL),
                      ),
                      child: Text(s, style: TextStyle(fontSize: context.fontSizeXS, color: Colors.green.shade800)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        
        if (isLoading)
          Padding(
            padding: EdgeInsets.only(top: context.spacingS),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
      ],
    );
  }
}

// ================================================================
// ENUM : Phase de capture photo séquentielle après scan QR
// ================================================================
enum _PhotoCapturePhase { none, externe, interne, done }

// ================================================================
// WIDGET PRINCIPAL : AjouterEquipementScreen
// ================================================================

class AjouterCoffretScreen extends StatefulWidget {
  final Mission mission;
  final String parentType;
  final int parentIndex;
  final bool isMoyenneTension;
  final int? zoneIndex;
  final CoffretArmoire? coffret;
  final int? coffretIndex;
  final bool isInZone;
  final String? qrCode;
  final bool shouldAutoCapturePhotos;

  const AjouterCoffretScreen({
    super.key,
    required this.mission,
    required this.parentType,
    required this.parentIndex,
    required this.isMoyenneTension,
    this.zoneIndex,
    this.coffret,
    this.coffretIndex,
    this.isInZone = false,
    this.qrCode,
    this.shouldAutoCapturePhotos = false,
  });

  bool get isEdition => coffret != null;

  @override
  State<AjouterCoffretScreen> createState() => _AjouterCoffretScreenState();
}

class _AjouterCoffretScreenState extends State<AjouterCoffretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _repereController = TextEditingController();
  String? _selectedType;
  final _qrCodeController = TextEditingController();
  bool _isQrCodeValid = false;

  bool _zoneAtex = false;
  String _domaineTension = '';
  bool _identificationArmoire = false;
  bool _signalisationDanger = false;
  bool _presenceSchema = false;
  bool _presenceParafoudre = false;
  bool _verificationThermographie = false;

  List<Alimentation> _alimentations = [];
  Alimentation? _protectionTete;
  List<PointVerification> _pointsVerification = [];

  final _observationController = TextEditingController();
  final List<String> _observationPhotos = [];
  String? _selectedNiveauPuissance;

  List<String> _coffretPhotosExterne = [];
  List<String> _coffretPhotosInterne = [];
  bool _isLoadingPhotosExterne = false;
  bool _isLoadingPhotosInterne = false;

  final ImagePicker _picker = ImagePicker();

  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _pointSuggestions = {};
  Map<int, bool> _pointLoading = {};
  Map<int, Timer?> _pointDebounceTimers = {};
  Map<int, bool> _hasObservation = {};

  bool _nomValid = false;
  bool _typeValid = false;
  bool _repereValid = false;
  bool _alimentationsValid = false;
  bool _pointsValid = false;
  bool _domaineTensionValid = false;

  bool _photosExterneValid = false;
  bool _photosInterneValid = false;

  final PageController _mainPageController = PageController();
  int _currentStep = 0;
  
  GlobalKey<_EtapePointsVerificationState>? _etapePointsKey;

  // ---------------------------------------------------------------
  // NOUVEAU : Gestion de la capture séquentielle post-scan QR
  // ---------------------------------------------------------------
  _PhotoCapturePhase _capturePhase = _PhotoCapturePhase.none;

  @override
  void initState() {
    super.initState();
    _etapePointsKey = GlobalKey<_EtapePointsVerificationState>();
    _autoFillRepere();
    
    if (widget.qrCode != null) {
      _qrCodeController.text = widget.qrCode!;
      _validateQrCode(widget.qrCode!);
    }
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _initializeAlimentations();
    }

    // Lancer le flow séquentiel de capture uniquement si demandé et pas en édition
    if (widget.shouldAutoCapturePhotos && !widget.isEdition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lancerCaptureSequentielle();
      });
    }
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Démarre le flow de capture séquentielle
  // ---------------------------------------------------------------
  Future<void> _lancerCaptureSequentielle() async {
    // --- Photo EXTERNE ---
    setState(() => _capturePhase = _PhotoCapturePhase.externe);
    await _afficherDialogueCapture(
      phase: _PhotoCapturePhase.externe,
      titre: 'Photo externe',
      sousTitre: 'Prenez une photo de l\'extérieur de l\'équipement',
      icone: Icons.camera_rear_outlined,
      couleur: Colors.blue,
      onCapture: _capturerPhotoExternePourFlow,
    );

    if (!mounted) return;

    // Vérifier que la photo externe a bien été prise
    if (_coffretPhotosExterne.isEmpty) {
      setState(() => _capturePhase = _PhotoCapturePhase.none);
      _showError('La photo externe est obligatoire. Veuillez la prendre depuis le formulaire.');
      return;
    }

    // --- Photo INTERNE ---
    setState(() => _capturePhase = _PhotoCapturePhase.interne);
    await _afficherDialogueCapture(
      phase: _PhotoCapturePhase.interne,
      titre: 'Photo interne',
      sousTitre: 'Prenez une photo de l\'intérieur de l\'équipement',
      icone: Icons.camera_front_outlined,
      couleur: Colors.teal,
      onCapture: _capturerPhotoInternePourFlow,
    );

    if (!mounted) return;

    // Vérifier que la photo interne a bien été prise
    if (_coffretPhotosInterne.isEmpty) {
      setState(() => _capturePhase = _PhotoCapturePhase.none);
      _showError('La photo interne est obligatoire. Veuillez la prendre depuis le formulaire.');
      return;
    }

    // --- Tout est bon : on affiche le formulaire normalement ---
    setState(() => _capturePhase = _PhotoCapturePhase.done);
    _showSuccess('Photos enregistrées. Complétez maintenant le formulaire.');
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Dialogue de capture photo (externe ou interne)
  // ---------------------------------------------------------------
  Future<void> _afficherDialogueCapture({
    required _PhotoCapturePhase phase,
    required String titre,
    required String sousTitre,
    required IconData icone,
    required Color couleur,
    required Future<bool> Function() onCapture,
  }) async {
    // On boucle tant que l'utilisateur n'a pas validé une photo
    bool photoValide = false;
    while (!photoValide && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _PhotoCaptureDialog(
            titre: titre,
            sousTitre: sousTitre,
            icone: icone,
            couleur: couleur,
            photosExistantes: phase == _PhotoCapturePhase.externe
                ? _coffretPhotosExterne
                : _coffretPhotosInterne,
            onPrendrePhoto: () async {
              Navigator.of(dialogContext).pop();
              await onCapture();
            },
          );
        },
      );

      // Après fermeture du dialogue, vérifier si une photo a été prise
      final photos = phase == _PhotoCapturePhase.externe
          ? _coffretPhotosExterne
          : _coffretPhotosInterne;

      if (photos.isNotEmpty) {
        photoValide = true;
        // Afficher un dialogue de confirmation avec aperçu et bouton "Valider"
        if (mounted) {
          final validated = await _afficherDialogueValidation(
            phase: phase,
            couleur: couleur,
            titre: titre,
          );
          if (!validated) {
            // L'utilisateur veut reprendre la photo : vider et reboucler
            setState(() {
              if (phase == _PhotoCapturePhase.externe) {
                _coffretPhotosExterne.clear();
                _photosExterneValid = false;
              } else {
                _coffretPhotosInterne.clear();
                _photosInterneValid = false;
              }
            });
            photoValide = false;
          }
        }
      } else {
        // Aucune photo prise : on propose de réessayer ou d'abandonner
        if (mounted) {
          final retry = await _afficherDialogueRetry(titre: titre);
          if (!retry) break; // L'utilisateur abandonne
        }
      }
    }
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Dialogue de validation avec aperçu de la photo
  // ---------------------------------------------------------------
  Future<bool> _afficherDialogueValidation({
    required _PhotoCapturePhase phase,
    required Color couleur,
    required String titre,
  }) async {
    final photos = phase == _PhotoCapturePhase.externe
        ? _coffretPhotosExterne
        : _coffretPhotosInterne;
    final lastPhoto = photos.last;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: couleur.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.check_circle_outline, color: couleur, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Photo prise — validez ou reprenez',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Aperçu photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(lastPhoto),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('Reprendre'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: couleur,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Dialogue de retry si aucune photo n'a été prise
  // ---------------------------------------------------------------
  Future<bool> _afficherDialogueRetry({required String titre}) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            const Text('Photo manquante'),
          ],
        ),
        content: Text(
          'Aucune photo n\'a été prise pour "$titre". Cette photo est obligatoire.\n\nVoulez-vous réessayer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Ignorer', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Capture photo externe pour le flow séquentiel
  // ---------------------------------------------------------------
  Future<bool> _capturerPhotoExternePourFlow() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo != null) {
        setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        setState(() {
          _coffretPhotosExterne.add(savedPath);
          _photosExterneValid = true;
        });
        return true;
      }
      return false;
    } catch (e) {
      _showError('Erreur photo externe: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isLoadingPhotosExterne = false);
    }
  }

  // ---------------------------------------------------------------
  // NOUVEAU : Capture photo interne pour le flow séquentiel
  // ---------------------------------------------------------------
  Future<bool> _capturerPhotoInternePourFlow() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo != null) {
        setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        setState(() {
          _coffretPhotosInterne.add(savedPath);
          _photosInterneValid = true;
        });
        return true;
      }
      return false;
    } catch (e) {
      _showError('Erreur photo interne: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isLoadingPhotosInterne = false);
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _autoFillRepere() {
    if (widget.isEdition) return;
    String parentName = '';
    final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
    if (audit != null) {
      if (widget.parentType == 'local') {
        if (widget.isMoyenneTension) {
          if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length) parentName = zone.locaux[widget.parentIndex].nom;
          } else if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
            parentName = audit.moyenneTensionLocaux[widget.parentIndex].nom;
          }
        } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length) parentName = zone.locaux[widget.parentIndex].nom;
        }
      } else if (widget.parentType == 'zone_mt' || widget.parentType == 'zone_bt') {
        if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length) {
          parentName = audit.moyenneTensionZones[widget.parentIndex].nom;
        } else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length) {
          parentName = audit.basseTensionZones[widget.parentIndex].nom;
        }
      }
    }
    if (parentName.isNotEmpty) {
      _repereController.text = parentName;
      _validateRepere(parentName);
    }
  }

  @override
  void dispose() {
    _pointDebounceTimers.forEach((key, timer) => timer?.cancel());
    _nomController.dispose();
    _repereController.dispose();
    _observationController.dispose();
    _qrCodeController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  void _validateNom(String value) => setState(() => _nomValid = value.trim().isNotEmpty);
  void _validateType(String? value) => setState(() => _typeValid = value != null && value.isNotEmpty);
  void _validateRepere(String value) => setState(() => _repereValid = value.trim().isNotEmpty);
  void _validateDomaineTension(String? value) => setState(() => _domaineTensionValid = value != null && value.isNotEmpty);

  void _validateAlimentations() {
    bool isValid = true;
    for (var a in _alimentations) {
      if (a.typeProtection.isEmpty || a.pdcKA.isEmpty || a.calibre.isEmpty || a.sectionCable.isEmpty) {
        isValid = false;
        break;
      }
    }
    if (_protectionTete != null) {
      if (_protectionTete!.typeProtection.isEmpty || 
          _protectionTete!.pdcKA.isEmpty || 
          _protectionTete!.calibre.isEmpty || 
          _protectionTete!.sectionCable.isEmpty) {
        isValid = false;
      }
    }
    setState(() => _alimentationsValid = isValid);
  }

  void _validatePoints() {
    bool isValid = true;
    for (var point in _pointsVerification) {
      if (point.conformite.isEmpty) {
        isValid = false;
        break;
      }
    }
    setState(() => _pointsValid = isValid);
  }

  bool _validateAllFields() {
    bool allValid = true;
    if (_nomController.text.trim().isEmpty) { _nomValid = false; allValid = false; }
    if (_selectedType == null || _selectedType!.isEmpty) { _typeValid = false; allValid = false; }
    if (_repereController.text.trim().isEmpty) { _repereValid = false; allValid = false; }
    
    _validateAlimentations();
    if (!_alimentationsValid) allValid = false;
    
    _validatePoints();
    if (!_pointsValid) allValid = false;
    
    if (_domaineTension.isEmpty) { _domaineTensionValid = false; allValid = false; }
    
    if (_coffretPhotosExterne.isEmpty) { 
      _photosExterneValid = false; 
      allValid = false; 
      _showError('La photo EXTERNE est obligatoire');
    } else {
      _photosExterneValid = true;
    }
    
    if (_coffretPhotosInterne.isEmpty) { 
      _photosInterneValid = false; 
      allValid = false; 
      _showError('La photo INTERNE est obligatoire');
    } else {
      _photosInterneValid = true;
    }
    
    setState(() {});
    return allValid;
  }

  void _validateQrCode(String qrCode) {
    if (qrCode.isEmpty) { setState(() => _isQrCodeValid = false); return; }
    final existing = HiveService.findCoffretByQrCode(widget.mission.id, qrCode);
    _isQrCodeValid = widget.isEdition ? true : existing == null;
  }

  void _validatePhotosExterne() {
    setState(() {
      _photosExterneValid = _coffretPhotosExterne.isNotEmpty;
    });
  }

  void _validatePhotosInterne() {
    setState(() {
      _photosInterneValid = _coffretPhotosInterne.isNotEmpty;
    });
  }

  void _chargerDonneesExistantes() {
    final coffret = widget.coffret!;
    _nomController.text = coffret.nom;
    _selectedType = coffret.type;
    _repereController.text = coffret.repere ?? '';
    _zoneAtex = coffret.zoneAtex;
    _domaineTension = coffret.domaineTension;
    _identificationArmoire = coffret.identificationArmoire;
    _signalisationDanger = coffret.signalisationDanger;
    _presenceSchema = coffret.presenceSchema;
    _presenceParafoudre = coffret.presenceParafoudre;
    _verificationThermographie = coffret.verificationThermographie;
    _alimentations = List.from(coffret.alimentations);
    _protectionTete = coffret.protectionTete;
    _pointsVerification = List.from(coffret.pointsVerification.map((point) => PointVerification(
      pointVerification: point.pointVerification,
      conformite: point.conformite,
      observation: point.observation,
      referenceNormative: point.referenceNormative,
      photos: List.from(point.photos),
    )));
    
    for (int i = 0; i < _pointsVerification.length; i++) {
      _hasObservation[i] = _pointsVerification[i].observation != null && _pointsVerification[i].observation!.isNotEmpty;
    }
    
    if (coffret.photos.isNotEmpty) {
      _coffretPhotosExterne = List.from(coffret.photos);
      _photosExterneValid = true;
    }
    _initializeForCoffretType(_selectedType);
    _validateNom(coffret.nom);
    _validateType(coffret.type);
    _validateRepere(coffret.repere ?? '');
    _validateAlimentations();
    _validatePoints();
    _validateDomaineTension(coffret.domaineTension);
  }

  Future<void> _prendrePhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        setState(() {
          _coffretPhotosExterne.add(savedPath);
          _validatePhotosExterne(); 
        });
      }
    } catch (e) { _showError('Erreur photo externe: $e'); } finally { setState(() => _isLoadingPhotosExterne = false); }
  }

  Future<void> _choisirPhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        setState(() {
          _coffretPhotosExterne.add(savedPath);
          _validatePhotosExterne(); 
        });
      }
    } catch (e) { _showError('Erreur sélection photo externe: $e'); } finally { setState(() => _isLoadingPhotosExterne = false); }
  }

  Future<void> _prendrePhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        setState(() {
          _coffretPhotosInterne.add(savedPath);
          _validatePhotosInterne();
        });
      }
    } catch (e) { _showError('Erreur photo interne: $e'); } finally { setState(() => _isLoadingPhotosInterne = false); }
  }

  Future<void> _choisirPhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        setState(() {
          _coffretPhotosInterne.add(savedPath);
          _validatePhotosInterne();
        });
      }
    } catch (e) { _showError('Erreur sélection photo interne: $e'); } finally { setState(() => _isLoadingPhotosInterne = false); }
  }

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) { _showError('Erreur photo observation: $e'); }
  }

  Future<void> _choisirPhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) { _showError('Erreur sélection photo observation: $e'); }
  }

  Future<String> _savePhotoToAppDirectory(File photoFile, String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final fileName = '${subDir}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';
    await photoFile.copy(newPath);
    return newPath;
  }

  void _supprimerPhotoExterne(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _coffretPhotosExterne.removeAt(index);
                _validatePhotosExterne();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _supprimerPhotoInterne(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _coffretPhotosInterne.removeAt(index);
                _validatePhotosInterne();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3))
  );

  void _initializeAlimentations() {
    _alimentations = [];
    _protectionTete = null;
  }

  void _onTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      _validateType(newType);
      _initializeForCoffretType(newType);
    });
  }

  void _initializeForCoffretType(String? type) {
    if (type == null) return;
    if (!widget.isEdition) {
      _pointsVerification = HiveService.getPointsVerificationForCoffret(type).map((point) => PointVerification(
        pointVerification: point, conformite: '', observation: null, referenceNormative: null,
      )).toList();
      
      _hasObservation.clear();
      for (int i = 0; i < _pointsVerification.length; i++) {
        _hasObservation[i] = false;
      }
      
      _alimentations.clear();
      _protectionTete = null;
      if (type == 'INVERSEUR') {
        _alimentations.addAll([
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
        ]);
      } else {
        _alimentations.add(Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''));
        _protectionTete = Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: '');
      }
    }
  }

  Future<void> _transfererEssais(String ancienNom, String nouveauNom) async {
    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      for (var essai in mesures.essaisDeclenchement) {
        if (essai.coffret == ancienNom) essai.coffret = nouveauNom;
      }
      await HiveService.saveMesuresEssais(mesures);
    } catch (e) { _showError('Erreur transfert essais'); }
  }

  void _onPointObservationChanged(int index, String text) {
    if (text.length >= 3) {
      _pointDebounceTimers[index]?.cancel();
      _pointDebounceTimers[index] = Timer(const Duration(milliseconds: 500), () async {
        try {
          final res = await http.post(
            Uri.parse('$_baseUrl/api/v1/autocomplete'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'query': text, 'max_results': 5}),
          ).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = json.decode(res.body) as Map<String, dynamic>;
            setState(() => _pointSuggestions[index] = List<String>.from(data['suggestions'] ?? []));
          }
        } catch (e) {}
      });
    } else {
      setState(() => _pointSuggestions[index]?.clear());
    }
  }

  void _onUsePointSuggestion(int index, String suggestion, PointVerification point) {
    point.observation = suggestion;
    setState(() => _pointSuggestions[index]?.clear());
  }

  void _onObservationToggleChanged(int index, bool value) {
    setState(() {
      _hasObservation[index] = value;
      if (!value) {
        _pointsVerification[index].observation = null;
      }
    });
  }

  void _sauvegarder() async {
    if (!_validateAllFields()) { _showError('Veuillez remplir tous les champs obligatoires'); return; }
    try {
      final toutesPhotos = [..._coffretPhotosExterne, ..._coffretPhotosInterne];
      final nouveauCoffret = CoffretArmoire(
        qrCode: _qrCodeController.text.trim(),
        nom: _nomController.text.trim(),
        type: _selectedType!,
        repere: _repereController.text.trim().isNotEmpty ? _repereController.text.trim() : null,
        zoneAtex: _zoneAtex,
        domaineTension: _domaineTension,
        identificationArmoire: _identificationArmoire,
        signalisationDanger: _signalisationDanger,
        presenceSchema: _presenceSchema,
        presenceParafoudre: _presenceParafoudre,
        verificationThermographie: _verificationThermographie,
        alimentations: _alimentations,
        protectionTete: _protectionTete,
        pointsVerification: _pointsVerification,
        observationsLibres: [],
        photos: toutesPhotos,
      );

      if (widget.isEdition && widget.coffret != null && widget.coffret!.nom != _nomController.text.trim()) {
        await _transfererEssais(widget.coffret!.nom, _nomController.text.trim());
      }
      
      bool success = false;
      if (widget.isEdition) {
        success = await _updateCoffret(nouveauCoffret);
      } else {
        if (widget.parentType == 'local') {
          if (widget.isMoyenneTension) {
            if (widget.isInZone && widget.zoneIndex != null) {
              success = await _addCoffretToLocalInMoyenneTensionZone(nouveauCoffret);
            } else {
              success = await HiveService.addCoffretToMoyenneTensionLocal(
                missionId: widget.mission.id, localIndex: widget.parentIndex, coffret: nouveauCoffret, qrCode: widget.qrCode!
              );
            }
          } else {
            success = await HiveService.addCoffretToBasseTensionLocal(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex ?? 0, localIndex: widget.parentIndex, coffret: nouveauCoffret
            );
          }
        } else {
          if (widget.isMoyenneTension) {
            success = await HiveService.addCoffretToMoyenneTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.parentIndex, coffret: nouveauCoffret
            );
          } else {
            success = await HiveService.addCoffretToBasseTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.parentIndex, coffret: nouveauCoffret
            );
          }
        }
      }

      if (success) {
        if (widget.isEdition) {
          Navigator.pop(context, true);
        } else {
          String localisation = '';
          final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
          if (widget.parentType == 'local') {
            if (widget.isMoyenneTension) {
              if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
                final zone = audit.moyenneTensionZones[widget.zoneIndex!];
                if (widget.parentIndex < zone.locaux.length) localisation = zone.locaux[widget.parentIndex].nom;
              } else if (widget.parentIndex < audit.moyenneTensionLocaux.length) {
                localisation = audit.moyenneTensionLocaux[widget.parentIndex].nom;
              }
            } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
              final zone = audit.basseTensionZones[widget.zoneIndex!];
              if (widget.parentIndex < zone.locaux.length) localisation = zone.locaux[widget.parentIndex].nom;
            }
          } else {
            if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length) {
              localisation = audit.moyenneTensionZones[widget.parentIndex].nom;
            } else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length) {
              localisation = audit.basseTensionZones[widget.parentIndex].nom;
            }
          }
          if (localisation.isEmpty) localisation = 'Localisation non définie';
          await Navigator.push(context, MaterialPageRoute(
            builder: (context) => AjouterEssaiDeclenchementScreen(
              mission: widget.mission, localisationPredefinie: localisation, coffretPredefini: nouveauCoffret.nom,
            ),
          ));
          Navigator.pop(context, true);
        }
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
    } catch (e) { _showError('Erreur: $e'); }
  }
  
  Future<bool> _addCoffretToLocalInMoyenneTensionZone(CoffretArmoire coffret) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      if (widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
        final zone = audit.moyenneTensionZones[widget.zoneIndex!];
        if (widget.parentIndex < zone.locaux.length) {
          zone.locaux[widget.parentIndex].coffrets.add(coffret);
          await HiveService.saveAuditInstallations(audit);
          return true;
        }
      }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> _updateCoffret(CoffretArmoire newCoffret) async {
    try {
      final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
      CoffretArmoire? target;
      bool found = false;
      if (widget.parentType == 'local') {
        if (widget.isMoyenneTension) {
          if (widget.isInZone && widget.zoneIndex != null && widget.zoneIndex! < audit.moyenneTensionZones.length) {
            final zone = audit.moyenneTensionZones[widget.zoneIndex!];
            if (widget.parentIndex < zone.locaux.length && widget.coffretIndex! < zone.locaux[widget.parentIndex].coffrets.length) {
              target = zone.locaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true;
            }
          } else if (widget.parentIndex < audit.moyenneTensionLocaux.length && widget.coffretIndex! < audit.moyenneTensionLocaux[widget.parentIndex].coffrets.length) {
            target = audit.moyenneTensionLocaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true;
          }
        } else if (widget.zoneIndex != null && widget.zoneIndex! < audit.basseTensionZones.length) {
          final zone = audit.basseTensionZones[widget.zoneIndex!];
          if (widget.parentIndex < zone.locaux.length && widget.coffretIndex! < zone.locaux[widget.parentIndex].coffrets.length) {
            target = zone.locaux[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true;
          }
        }
      } else {
        if (widget.isMoyenneTension && widget.parentIndex < audit.moyenneTensionZones.length && widget.coffretIndex! < audit.moyenneTensionZones[widget.parentIndex].coffrets.length) {
          target = audit.moyenneTensionZones[widget.parentIndex].coffrets[widget.coffretIndex!]; found = true;
        } else if (!widget.isMoyenneTension && widget.parentIndex < audit.basseTensionZones.length && widget.coffretIndex! < audit.basseTensionZones[widget.parentIndex].coffretsDirects.length) {
          target = audit.basseTensionZones[widget.parentIndex].coffretsDirects[widget.coffretIndex!]; found = true;
        }
      }
      if (found && target != null) {
        target.nom = newCoffret.nom; target.type = newCoffret.type; target.repere = newCoffret.repere;
        target.zoneAtex = newCoffret.zoneAtex; target.domaineTension = newCoffret.domaineTension;
        target.identificationArmoire = newCoffret.identificationArmoire; target.signalisationDanger = newCoffret.signalisationDanger;
        target.presenceSchema = newCoffret.presenceSchema; target.presenceParafoudre = newCoffret.presenceParafoudre;
        target.verificationThermographie = newCoffret.verificationThermographie;
        target.alimentations = newCoffret.alimentations; target.protectionTete = newCoffret.protectionTete;
        target.pointsVerification = newCoffret.pointsVerification; target.photos = newCoffret.photos;
        await HiveService.saveAuditInstallations(audit);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (!_nomValid) {
        _showError('Veuillez saisir le nom de l\'équipement');
        return;
      }
      if (!_typeValid) {
        _showError('Veuillez sélectionner le type d\'équipement');
        return;
      }
      if (!_repereValid) {
        _showError('Veuillez saisir le repère');
        return;
      }
      if (!_photosExterneValid) {
        _showError('La photo EXTERNE est obligatoire');
        return;
      }
      if (!_photosInterneValid) {
        _showError('La photo INTERNE est obligatoire');
        return;
      }
      
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep == 1) {
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (_currentStep == 2) {
      _validateAlimentations();
      if (_alimentationsValid) {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showError('Veuillez remplir tous les champs des alimentations');
      }
    } else if (_currentStep == 3) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null) {
        if (pointsState.canGoNext()) {
          _sauvegarder();
        } else {
          pointsState.nextSlide();
        }
      }
    }
  }

  void _handlePrevious() {
    if (_currentStep == 3) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null && pointsState._currentSlide > 0) {
        pointsState.previousSlide();
      } else {
        _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else if (_currentStep > 0) {
      _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _getNextButtonText() {
    if (_currentStep == 3) {
      final pointsState = _etapePointsKey?.currentState;
      if (pointsState != null && pointsState.canGoNext()) {
        return 'Terminer';
      }
      return 'Suivant';
    }
    return _currentStep == 3 ? 'Terminer' : 'Suivant';
  }

  int _getTotalSteps() => 4;

  // Indique si le flow de capture séquentielle est encore en cours
  bool get _isCaptureFlowActive =>
      _capturePhase == _PhotoCapturePhase.externe ||
      _capturePhase == _PhotoCapturePhase.interne;

  @override
  Widget build(BuildContext context) {
    final totalSteps = _getTotalSteps();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            widget.isEdition ? 'Modifier l\'équipement' : 'Ajouter un équipement',
            style: TextStyle(fontSize: context.fontSizeL),
          ),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!widget.isEdition && _currentStep == totalSteps - 1)
              IconButton(icon: Icon(Icons.check, size: context.iconSizeM), onPressed: _sauvegarder),
          ],
        ),
        body: Column(
          children: [
            // Stepper de navigation (toujours visible)
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: List.generate(totalSteps, (index) {
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: context.iconSizeL,
                          height: context.iconSizeL,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.primaryBlue : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(Icons.check, color: Colors.white, size: context.iconSizeS)
                                : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: context.fontSizeS)),
                          ),
                        ),
                        if (index < totalSteps - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                              color: index < _currentStep ? AppTheme.primaryBlue : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            
            // Contenu principal
            Expanded(
              child: PageView(
                controller: _mainPageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _EtapeInformationsBase(
                    nomController: _nomController,
                    repereController: _repereController,
                    selectedType: _selectedType,
                    onTypeChanged: _onTypeChanged,
                    typeValid: _typeValid,
                    nomValid: _nomValid,
                    repereValid: _repereValid,
                    onValidateNom: () => _validateNom(_nomController.text),
                    onValidateRepere: () => _validateRepere(_repereController.text),
                    photosExterne: _coffretPhotosExterne,
                    photosInterne: _coffretPhotosInterne,
                    onPrendrePhotoExterne: _prendrePhotoExterne,
                    onChoisirPhotoExterne: _choisirPhotoExterne,
                    onPrendrePhotoInterne: _prendrePhotoInterne,
                    onChoisirPhotoInterne: _choisirPhotoInterne,
                    isLoadingPhotosExterne: _isLoadingPhotosExterne,
                    isLoadingPhotosInterne: _isLoadingPhotosInterne,
                    onSupprimerPhotoExterne: _supprimerPhotoExterne,
                    onSupprimerPhotoInterne: _supprimerPhotoInterne,
                    isInZone: widget.isInZone,
                    observationController: _observationController,
                    observationPhotos: _observationPhotos,
                    onPrendrePhotoObservation: _prendrePhotoObservation,
                    onChoisirPhotoObservation: _choisirPhotoObservation,
                    selectedNiveauPuissance: _selectedNiveauPuissance,
                    onNiveauPuissanceChanged: (value) {
                      setState(() {
                        _selectedNiveauPuissance = value;
                        if (value != null) {
                          const options = [
                            {'value': 'tres_petites_sections', 'label': 'Très petites sections'},
                            {'value': 'installations_domestiques', 'label': 'Installations domestiques / tertiaires'},
                            {'value': 'puissances_moyennes', 'label': 'Puissances moyennes'},
                            {'value': 'puissances_evelees', 'label': 'Puissances élevées / industrie'},
                          ];
                          final selected = options.firstWhere((opt) => opt['value'] == value);
                          if (_observationController.text.isEmpty) {
                            _observationController.text = selected['label'] as String;
                          }
                        }
                      });
                    },
                  ),
                  
                  if (_selectedType != null)
                    _EtapeInformationsGenerales(
                      zoneAtex: _zoneAtex,
                      onZoneAtexChanged: (v) => setState(() => _zoneAtex = v ?? false),
                      identificationArmoire: _identificationArmoire,
                      onIdentificationArmoireChanged: (v) => setState(() => _identificationArmoire = v ?? false),
                      signalisationDanger: _signalisationDanger,
                      onSignalisationDangerChanged: (v) => setState(() => _signalisationDanger = v ?? false),
                      presenceSchema: _presenceSchema,
                      onPresenceSchemaChanged: (v) => setState(() => _presenceSchema = v ?? false),
                      presenceParafoudre: _presenceParafoudre,
                      onPresenceParafoudreChanged: (v) => setState(() => _presenceParafoudre = v ?? false),
                      verificationThermographie: _verificationThermographie,
                      onVerificationThermographieChanged: (v) => setState(() => _verificationThermographie = v ?? false),
                      domaineTension: _domaineTension,
                      onDomaineTensionChanged: (v) { setState(() { _domaineTension = v ?? ''; _validateDomaineTension(v); }); },
                      domaineTensionValid: _domaineTensionValid,
                    ),
                  
                  if (_selectedType != null)
                    _EtapeAlimentations(
                      selectedType: _selectedType,
                      alimentations: _alimentations,
                      protectionTete: _protectionTete,
                      onDataChanged: () {
                        _validateAlimentations();
                        setState(() {});
                      },
                    ),
                  
                  if (_selectedType != null && _pointsVerification.isNotEmpty)
                    _EtapePointsVerification(
                      key: _etapePointsKey,
                      pointsVerification: _pointsVerification,
                      pointSuggestions: _pointSuggestions,
                      pointLoading: _pointLoading,
                      hasObservation: _hasObservation,
                      onObservationChanged: _onPointObservationChanged,
                      onUseSuggestion: _onUsePointSuggestion,
                      onObservationToggleChanged: _onObservationToggleChanged,
                    ),
                ].whereType<Widget>().toList(),
              ),
            ),
            
            // Boutons de navigation (désactivés pendant le flow de capture)
            if (!_isCaptureFlowActive)
              Container(
                padding: EdgeInsets.all(context.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.spacingS, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handlePrevious,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: context.spacingM),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                          ),
                          child: Text('Précédent', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: context.spacingM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: context.spacingM),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                          elevation: 2,
                        ),
                        child: Text(_getNextButtonText(), style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// NOUVEAU WIDGET : Dialogue de capture photo séquentielle
// ================================================================
class _PhotoCaptureDialog extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final List<String> photosExistantes;
  final VoidCallback onPrendrePhoto;

  const _PhotoCaptureDialog({
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.photosExistantes,
    required this.onPrendrePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: couleur.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête coloré
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [couleur, couleur.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icone, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sousTitre,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Corps
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  // Instruction
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: couleur.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: couleur, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cette photo est obligatoire pour continuer.',
                            style: TextStyle(
                              fontSize: 13,
                              color: couleur.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton principal : Prendre la photo
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPrendrePhoto,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text(
                        'Prendre la photo',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: couleur,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}