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
  final VoidCallback onSupprimerPhoto;
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
    required this.onSupprimerPhoto,
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
          isRequired: true,
        ),
        SizedBox(height: context.spacingXL),
        
        _buildModernObservationCard(context),
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
            Container(
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
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.spacingS),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(context.spacingS),
                          child: Image.file(File(photos[index]), fit: BoxFit.cover),
                        ),
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
          
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Prendre',
                    onTap: onPrendrePhoto,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: onChoisirPhoto,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.spacingS),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingS),
          decoration: BoxDecoration(
            gradient: isSecondary ? null : LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isSecondary ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: isSecondary ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.iconSizeS, color: isSecondary ? Colors.grey.shade700 : Colors.white),
              SizedBox(width: context.spacingS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isSecondary ? Colors.grey.shade700 : Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernObservationCard(BuildContext context) {
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
                Icon(Icons.notes_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'OBSERVATION SUR L\'ÉQUIPEMENT',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonFormField<String>(
                value: widget.selectedNiveauPuissance,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(context.spacingS),
                hint: Row(
                  children: [
                    Icon(Icons.speed, size: context.iconSizeS, color: Colors.grey.shade500),
                    SizedBox(width: context.spacingS),
                    Flexible(
                      child: Text(
                        'Niveau de puissance',
                        style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
                ),
                items: _niveauPuissanceOptions.map<DropdownMenuItem<String>>((option) => DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Row(
                    children: [
                      Icon(option['icon'] as IconData, size: context.iconSizeS, color: AppTheme.primaryBlue),
                      SizedBox(width: context.spacingS),
                      Flexible(
                        child: Text(
                          option['label'] as String,
                          style: TextStyle(fontSize: context.fontSizeS),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: widget.onNiveauPuissanceChanged,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextFormField(
                controller: widget.observationController,
                style: TextStyle(fontSize: context.fontSizeS),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Saisissez votre observation...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: context.fontSizeS),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(context.spacingM),
                ),
              ),
            ),
          ),
          if (widget.observationPhotos.isNotEmpty)
            Container(
              height: context.screenHeight * 0.08,
              margin: EdgeInsets.symmetric(horizontal: context.spacingL),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.observationPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: context.screenWidth * 0.18,
                    margin: EdgeInsets.only(right: context.spacingS),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.spacingS),
                      child: Image.file(File(widget.observationPhotos[index]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Photo',
                    onTap: widget.onPrendrePhotoObservation,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: widget.onChoisirPhotoObservation,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacingL),
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
            value: domaineTension,
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

  // Contrôleurs pour chaque champ (pour le focus et la validation)
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
// ÉTAPE 4 : POINTS DE VÉRIFICATION
// ================================================================
class _EtapePointsVerification extends StatefulWidget {
  final List<PointVerification> pointsVerification;
  final Map<int, List<String>> pointSuggestions;
  final Map<int, bool> pointLoading;
  final Function(int, String) onObservationChanged;
  final Function(int, String, PointVerification) onUseSuggestion;

  const _EtapePointsVerification({
    super.key,
    required this.pointsVerification,
    required this.pointSuggestions,
    required this.pointLoading,
    required this.onObservationChanged,
    required this.onUseSuggestion,
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
    // 3 éléments par slide
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
      // Vérifier uniquement la conformité et la priorité (l'observation n'est plus obligatoire)
      if (point.conformite.isEmpty || point.conformite == 'non_applicable') {
        continue; // Non applicable est acceptable
      }
      if (point.priorite == null) {
        return false;
      }
    }
    return true;
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      _showError('Veuillez sélectionner la conformité et la priorité pour tous les points');
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
        // En-tête compact
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
        
        // Barre de progression
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
        
        // Liste des points - 3 par slide
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              final slidePoints = _pointsSlides[slideIndex];
              // Calculer l'index de départ pour les numéros
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
          // Numéro et question
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
          
          // Conformité et Priorité - côte à côte
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConformiteSelector(context, point)),
              SizedBox(width: context.spacingS),
              Expanded(child: _buildPrioriteSelector(context, point)),
            ],
          ),
          
          // Suggestions (optionnel)
          if (suggestions.isNotEmpty) ...[
            SizedBox(height: context.spacingS),
            Container(
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
          ],
          
          // Loading indicator
          if (isLoading)
            Padding(
              padding: EdgeInsets.only(top: context.spacingS),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
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
              default: color = Colors.orange; text = 'Non applicable';
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

  Widget _buildPrioriteSelector(BuildContext context, PointVerification point) {
    final isValid = point.priorite != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: isValid ? Colors.grey.shade300 : Colors.red.shade300,
          width: isValid ? 1 : 1.5,
        ),
      ),
      child: DropdownButtonFormField<int>(
        value: point.priorite,
        hint: Text(
          'Priorité *',
          style: TextStyle(fontSize: context.fontSizeS, color: isValid ? Colors.grey.shade500 : Colors.red.shade400),
        ),
        isExpanded: true,
        onChanged: (v) {
          setState(() {
            point.priorite = v;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
        ),
        items: [
          DropdownMenuItem(
            value: 1,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('N1 - Basse', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 2,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('N2 - Moyenne', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 3,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('N3 - Haute', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
        ],
        selectedItemBuilder: (BuildContext context) {
          return [1, 2, 3].map<Widget>((value) {
            Color color;
            String text;
            switch (value) {
              case 1: color = Colors.blue; text = 'N1 - Basse'; break;
              case 2: color = Colors.orange; text = 'N2 - Moyenne'; break;
              default: color = Colors.red; text = 'N3 - Haute';
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
}

// ================================================================
// WIDGET PRINCIPAL : AjouterCoffretScreen
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
  String _domaineTension = '230/400';
  bool _identificationArmoire = false;
  bool _signalisationDanger = false;
  bool _presenceSchema = false;
  bool _presenceParafoudre = false;
  bool _verificationThermographie = false;

  List<Alimentation> _alimentations = [];
  Alimentation? _protectionTete;
  List<PointVerification> _pointsVerification = [];

  final _observationController = TextEditingController();
  List<String> _observationPhotos = [];
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

  bool _nomValid = false;
  bool _typeValid = false;
  bool _repereValid = false;
  bool _alimentationsValid = false;
  bool _pointsValid = false;
  bool _domaineTensionValid = true;

  final PageController _mainPageController = PageController();
  int _currentStep = 0;
  
  GlobalKey<_EtapePointsVerificationState>? _etapePointsKey;

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
        print('❌ Alimentation invalide: type=${a.typeProtection}, pdc=${a.pdcKA}, calibre=${a.calibre}, cable=${a.sectionCable}');
        break;
      }
    }
    if (_protectionTete != null) {
      if (_protectionTete!.typeProtection.isEmpty || 
          _protectionTete!.pdcKA.isEmpty || 
          _protectionTete!.calibre.isEmpty || 
          _protectionTete!.sectionCable.isEmpty) {
        isValid = false;
        print('❌ Protection tête invalide: type=${_protectionTete!.typeProtection}, pdc=${_protectionTete!.pdcKA}, calibre=${_protectionTete!.calibre}, cable=${_protectionTete!.sectionCable}');
      }
    }
    setState(() => _alimentationsValid = isValid);
  }

  void _validatePoints() {
    bool isValid = true;
    for (var point in _pointsVerification) {
      if (point.conformite.isEmpty || point.priorite == null) {
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
    if (_coffretPhotosExterne.isEmpty) { allValid = false; _showError('Photo EXTERNE requise'); }
    if (_coffretPhotosInterne.isEmpty) { allValid = false; _showError('Photo INTERNE requise'); }
    
    setState(() {});
    return allValid;
  }

  void _validateQrCode(String qrCode) {
    if (qrCode.isEmpty) { setState(() => _isQrCodeValid = false); return; }
    final existing = HiveService.findCoffretByQrCode(widget.mission.id, qrCode);
    _isQrCodeValid = widget.isEdition ? true : existing == null;
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
      priorite: point.priorite ?? 3,
    )));
    if (coffret.photos.isNotEmpty) {
      _coffretPhotosExterne = List.from(coffret.photos);
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
        setState(() => _coffretPhotosExterne.add(savedPath));
      }
    } catch (e) { _showError('Erreur photo externe: $e'); } finally { setState(() => _isLoadingPhotosExterne = false); }
  }

  Future<void> _choisirPhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosExterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_externe');
        setState(() => _coffretPhotosExterne.add(savedPath));
      }
    } catch (e) { _showError('Erreur sélection photo externe: $e'); } finally { setState(() => _isLoadingPhotosExterne = false); }
  }

  Future<void> _prendrePhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        setState(() => _coffretPhotosInterne.add(savedPath));
      }
    } catch (e) { _showError('Erreur photo interne: $e'); } finally { setState(() => _isLoadingPhotosInterne = false); }
  }

  Future<void> _choisirPhotoInterne() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotosInterne = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'coffrets_interne');
        setState(() => _coffretPhotosInterne.add(savedPath));
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
        pointVerification: point, conformite: '', priorite: 3,
      )).toList();
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
      if (_nomValid && _typeValid && _repereValid) {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showError('Veuillez remplir tous les champs obligatoires');
      }
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
                    onSupprimerPhoto: () {},
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
                      onDomaineTensionChanged: (v) { setState(() { _domaineTension = v ?? '230/400'; _validateDomaineTension(v); }); },
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
                      onObservationChanged: (index, text) {
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
                      },
                      onUseSuggestion: (index, suggestion, point) {
                        point.observation = suggestion;
                        setState(() => _pointSuggestions[index]?.clear());
                      },
                    ),
                ].whereType<Widget>().toList(),
              ),
            ),
            
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