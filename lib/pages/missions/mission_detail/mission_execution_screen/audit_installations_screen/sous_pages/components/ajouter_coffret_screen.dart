import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/essais_declenchement_screen.dart';
import 'package:inspec_app/services/normative_reference_service.dart';
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
// ÉTAPE 1 : INFORMATIONS DE BASE + PHOTOS
// ================================================================
class _EtapeInformationsBase extends StatefulWidget {
  final TextEditingController nomController;
  final TextEditingController repereController;
  final TextEditingController numeroEquipementController;
  final String? selectedType;
  final Function(String?) onTypeChanged;
  final bool typeValid;
  final bool numeroEquipementValid;
  final bool nomValid;
  final bool repereValid;
  final VoidCallback onValidateNom;
  final VoidCallback onValidateNumeroEquipement;
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

  const _EtapeInformationsBase({
    required this.nomController,
    required this.numeroEquipementController,
    required this.repereController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.typeValid,
    required this.nomValid,
    required this.repereValid,
    required this.numeroEquipementValid,
    required this.onValidateNumeroEquipement,
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
  });

  @override
  State<_EtapeInformationsBase> createState() => _EtapeInformationsBaseState();
}

class _EtapeInformationsBaseState extends State<_EtapeInformationsBase> {
  final PageController _photosExterneController = PageController();
  final PageController _photosInterneController = PageController();
  int _currentExterneIndex = 0;
  int _currentInterneIndex = 0;

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
      
        // NOUVEAU : Numéro de l'équipement
        _buildModernTextField(
          context,
          controller: widget.numeroEquipementController,
          label: 'Numéro de l\'équipement',
          icon: Icons.numbers_outlined,
          isValid: widget.numeroEquipementValid,
          onChanged: (_) => widget.onValidateNumeroEquipement(),
          isRequired: false,
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

  // ... (méthodes _buildModernHeader, _buildModernTextField, _buildModernTypeSelector, 
  // _buildModernPhotoCarousel, _buildModernPhotoButton inchangées - garder le code existant)
  
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
    bool isRequired = true,
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
          labelText: isRequired ? '$label *' : label,
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
  const types = ['INVERSEUR', 'ARMOIRE', 'COFFRET', 'TGBT'];
  
  // S'assurer que la valeur est valide
  final validValue = (widget.selectedType != null && types.contains(widget.selectedType)) 
      ? widget.selectedType 
      : null;
  
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
              // Utiliser la valeur validée
              value: validValue,
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
}

// ================================================================
// ÉTAPE 2 : INFORMATIONS GÉNÉRALES (inchangée)
// ================================================================
class _EtapeInformationsGenerales extends StatefulWidget {
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
  
  // ✅ NOUVEAUX PARAMÈTRES
  final List<ObservationLibre> observationsParafoudre;
  final Function(String, List<String>) onAddParafoudreObservation;
  final Function(int) onDeleteParafoudreObservation;
  final Function(ObservationLibre) onEditParafoudreObservation;

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
    required this.observationsParafoudre,
    required this.onAddParafoudreObservation,
    required this.onDeleteParafoudreObservation,
    required this.onEditParafoudreObservation,
  });

  @override
  State<_EtapeInformationsGenerales> createState() => _EtapeInformationsGeneralesState();
}

class _EtapeInformationsGeneralesState extends State<_EtapeInformationsGenerales> {
  final TextEditingController _observationParafoudreController = TextEditingController();
  final List<String> _observationParafoudrePhotos = [];
  bool _addParafoudreObservation = false;

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(photos[index])),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prendrePhotoParafoudre() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/audit_photos/parafoudre');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final fileName = 'parafoudre_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${photosDir.path}/$fileName';
      await File(photo.path).copy(newPath);
      setState(() => _observationParafoudrePhotos.add(newPath));
    }
  }

  Future<void> _choisirPhotoParafoudre() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (photo != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/audit_photos/parafoudre');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final fileName = 'parafoudre_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = '${photosDir.path}/$fileName';
      await File(photo.path).copy(newPath);
      setState(() => _observationParafoudrePhotos.add(newPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations générales', 2, 4),
        SizedBox(height: context.spacingXL),
        
        _buildModernCheckbox(context, 'Zone ATEX', widget.zoneAtex, widget.onZoneAtexChanged),
        _buildModernCheckbox(context, 'Identification de l\'armoire', widget.identificationArmoire, widget.onIdentificationArmoireChanged),
        _buildModernCheckbox(context, 'Signalisation de danger électrique', widget.signalisationDanger, widget.onSignalisationDangerChanged),
        _buildModernCheckbox(context, 'Présence de schéma électrique', widget.presenceSchema, widget.onPresenceSchemaChanged),
        _buildModernCheckbox(context, 'Présence de parafoudre', widget.presenceParafoudre, widget.onPresenceParafoudreChanged),
        _buildModernCheckbox(context, 'Vérification par thermographie', widget.verificationThermographie, widget.onVerificationThermographieChanged),
        
        SizedBox(height: context.spacingXL),
        
        // ✅ Domaine de tension avec valeur par défaut "230/400"
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: !widget.domaineTensionValid ? Colors.red.shade300 : Colors.grey.shade300,
              width: !widget.domaineTensionValid ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: widget.domaineTension.isNotEmpty ? widget.domaineTension : '230/400', // ✅ Valeur par défaut
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue, size: context.iconSizeM),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(context.spacingS),
            decoration: const InputDecoration(
              labelText: 'Domaine',
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
                      color: widget.domaineTension == t ? AppTheme.primaryBlue : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    ),
                    child: widget.domaineTension == t ? Icon(Icons.check, size: context.spacingXS, color: Colors.white) : null,
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(child: Text(t, style: TextStyle(fontSize: context.fontSizeM))),
                ],
              ),
            )).toList(),
            onChanged: widget.onDomaineTensionChanged,
          ),
        ),
        
        SizedBox(height: context.spacingXL),
        
        //Observation état du parafoudre
        _buildParafoudreObservationsSection(context),
        
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
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: context.spacingS, offset: Offset(0, context.spacingXS))],
              ),
              child: Icon(Icons.info_outline, color: Colors.white, size: context.iconSizeM),
            ),
            SizedBox(width: context.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                  SizedBox(height: context.spacingXS),
                  Text('Étape $currentStep sur $totalSteps', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2))],
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

  //Section des observations du parafoudre
  Widget _buildParafoudreObservationsSection(BuildContext context) {
    //Ne pas afficher si la case "Présence de parafoudre" n'est pas cochée
    if (!widget.presenceParafoudre) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange, size: context.iconSizeM),
                SizedBox(width: context.spacingS),
                Flexible(
                  child: Text(
                    'Observation état du parafoudre',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des observations existantes (tap = dialogue)
          if (widget.observationsParafoudre.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacingL),
              child: Column(
                children: widget.observationsParafoudre.asMap().entries.map((entry) {
                  final index = entry.key;
                  final obs = entry.value;
                  return GestureDetector(
                    onTap: () => _voirObservationDetail(obs),
                    child: Container(
                      margin: EdgeInsets.only(bottom: context.spacingS),
                      padding: EdgeInsets.all(context.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(context.spacingS),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              obs.texte,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade800),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: context.iconSizeS, color: AppTheme.primaryBlue),
                            onPressed: () => widget.onEditParafoudreObservation(obs),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: context.iconSizeS, color: Colors.red),
                            onPressed: () => widget.onDeleteParafoudreObservation(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Nouvelle observation
          Padding(
            padding: EdgeInsets.all(context.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _observationParafoudreController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Nouvelle observation',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                    hintText: 'Saisissez votre observation...',
                  ),
                ),
                SizedBox(height: context.spacingS),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _ajouterParafoudreObservation,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      backgroundColor: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('AJOUTER'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _voirObservationDetail(ObservationLibre observation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Détail de l\'observation'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Text(
              observation.texte,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _ajouterParafoudreObservation() {
    final texte = _observationParafoudreController.text.trim();
    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une observation'), backgroundColor: Colors.red),
      );
      return;
    }

    widget.onAddParafoudreObservation(texte, []);
    
    setState(() {
      _observationParafoudreController.clear();
    });
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
  final List<String> sourcesDisponibles;

  const _EtapeAlimentations({
    required this.selectedType,
    required this.alimentations,
    required this.protectionTete,
    required this.onDataChanged,
    required this.sourcesDisponibles,
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
    'Inconnu',
  ];

  static const List<String> _sourceOptions = [
    'Inverseur',
    'Armoire',
    'Coffret',
    'TGBT',
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
        case 'source': a.source = value; break;
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
        
        // Message informatif : champs non obligatoires
        Container(
          padding: EdgeInsets.all(context.spacingM),
          margin: EdgeInsets.only(bottom: context.spacingL),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: context.iconSizeS),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  'Les champs d\'alimentation sont optionnels. Remplissez uniquement les informations disponibles.',
                  style: TextStyle(fontSize: context.fontSizeXS, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        
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
            label: 'Type de protection',
            value: a.typeProtection,
            items: _typeProtectionOptions,
            onChanged: (v) => onChanged('typeProtection', v),
          ),
          SizedBox(height: context.spacingS),

          if (title == 'ORIGINE DE LA SOURCE') ...[
            _buildModernDropdown(
              context,
              label: 'Source',
              value: a.source,
              items: _sourceOptions,
              onChanged: (v) => onChanged('source', v),
            ),
            SizedBox(height: context.spacingS),
          ],
          
          _buildModernTextField(
            context,
            label: 'PDC kA',
            controller: isProtectionTete 
                ? _controllers['prot_pdc']!
                : _controllers['alim${index}_pdc']!,
            onChanged: (v) => onChanged('pdcKA', v),
          ),
          SizedBox(height: context.spacingS),
          
          _buildModernTextField(
            context,
            label: isProtectionTete ? 'Calibre protection' : 'Calibre',
            controller: isProtectionTete 
                ? _controllers['prot_calibre']!
                : _controllers['alim${index}_calibre']!,
            onChanged: (v) => onChanged('calibre', v),
          ),
          SizedBox(height: context.spacingS),
          
          _buildModernDropdown(
            context,
            label: 'Section de câble',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value.isNotEmpty ? value : null,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
        hint: Text(
          'Sélectionnez...',
          style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
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
// ÉTAPE 4 : POINTS DE VÉRIFICATION (CONFORMITÉ EN BOUTONS + RÉFÉRENCE NORMATIVE TOGGLE)
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
  
  // Map pour gérer l'affichage de la référence normative
  final Map<int, bool> _showReferenceNormative = {};final Map<int, List<ObservationLibre>> _pointObservations = {};
  final Map<int, TextEditingController> _newObservationControllers = {};

  @override
  void initState() {
    super.initState();
    _buildSlides();
    for (int i = 0; i < widget.pointsVerification.length; i++) {
      _pointObservations[i] = [];
      _newObservationControllers[i] = TextEditingController();
          
      // Charger les observations existantes depuis le point
      if (widget.pointsVerification[i].observation != null && widget.pointsVerification[i].observation!.isNotEmpty) {
         _pointObservations[i]!.add(ObservationLibre(texte: widget.pointsVerification[i].observation!));
      }
    }
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
      // Vérifier la conformité
      if (point.conformite.isEmpty) {
        return false;
      }
      
      // Si conformité = "non", l'observation est OBLIGATOIRE
      if (point.conformite == 'non') {
        final pointIndex = _getPointIndex(point);
        final hasObservation = widget.hasObservation[pointIndex] ?? false;
        
        // L'observation doit être activée ET non vide
        if (!hasObservation) {
          return false;
        }
        if (point.observation == null || point.observation!.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  // Méthode helper pour retrouver l'index d'un point
  int _getPointIndex(PointVerification point) {
    final globalIndex = widget.pointsVerification.indexOf(point);
    return globalIndex;
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      // Message plus précis
      for (var point in _pointsSlides[_currentSlide]) {
        if (point.conformite.isEmpty) {
          _showError('Veuillez sélectionner Oui ou Non pour tous les points');
          return;
        }
        if (point.conformite == 'non') {
          final pointIndex = _getPointIndex(point);
          final hasObservation = widget.hasObservation[pointIndex] ?? false;
          if (!hasObservation) {
            _showError('L\'observation est obligatoire quand la conformité est "Non"');
            return;
          }
          if (point.observation == null || point.observation!.trim().isEmpty) {
            _showError('Veuillez saisir une observation pour le point non conforme');
            return;
          }
        }
      }
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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool canGoNext() {
    if (!_isCurrentSlideValid()) return false;
    return _isLastSlide;
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (var controller in _newObservationControllers.values) {
      controller.dispose();
    }
    super.dispose();
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


  void _addPointObservation(int pointIndex) {
    final text = _newObservationControllers[pointIndex]?.text.trim() ?? '';
    if (text.isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }
    
    setState(() {
      _pointObservations[pointIndex]!.add(ObservationLibre(texte: text));
      _newObservationControllers[pointIndex]?.clear();
    });
    
    // Mettre à jour le point avec la dernière observation (pour la compatibilité)
    widget.pointsVerification[pointIndex].observation = text;
    widget.onObservationChanged(pointIndex, text);
  }

  void _deletePointObservation(int pointIndex, int obsIndex) {
    setState(() {
      _pointObservations[pointIndex]!.removeAt(obsIndex);
    });
    
    // Mettre à jour le point avec la première observation restante ou null
    if (_pointObservations[pointIndex]!.isNotEmpty) {
      widget.pointsVerification[pointIndex].observation = _pointObservations[pointIndex]!.first.texte;
    } else {
      widget.pointsVerification[pointIndex].observation = null;
    }
    widget.onObservationChanged(pointIndex, widget.pointsVerification[pointIndex].observation ?? '');
  }

  void _editPointObservation(int pointIndex, int obsIndex) {
    final obs = _pointObservations[pointIndex]![obsIndex];
    final controller = TextEditingController(text: obs.texte);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier l\'observation'),
        content: TextFormField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Observation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  _pointObservations[pointIndex]![obsIndex] = ObservationLibre(texte: newText);
                  widget.pointsVerification[pointIndex].observation = newText;
                });
                widget.onObservationChanged(pointIndex, newText);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _viewPointObservationDetail(ObservationLibre observation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Détail de l\'observation'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Text(
              observation.texte,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPointCard(BuildContext context, PointVerification point, int pointIndex) {
    final suggestions = widget.pointSuggestions[pointIndex] ?? [];
    final isLoading = widget.pointLoading[pointIndex] ?? false;
    final hasObservation = widget.hasObservation[pointIndex] ?? false;
    final showReference = _showReferenceNormative[pointIndex] ?? false;
    
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
          
          //Conformité en boutons Oui/Non
          _buildConformiteToggle(context, point, pointIndex),
          
          //Bouton pour afficher/masquer la référence normative
          SizedBox(height: context.spacingS),
          _buildReferenceNormativeToggle(context, point, pointIndex, showReference),
          
          // Toggle Observation
          SizedBox(height: context.spacingM),
          _buildObservationToggle(context, pointIndex, hasObservation),
          
          // Champ Observation (conditionnel)
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            _buildObservationField(context, point, pointIndex),
          ],
        ],
      ),
    );
  }

  // Widget de conformité en boutons Oui/Non
  Widget _buildConformiteToggle(BuildContext context, PointVerification point, int pointIndex) {
    final isValid = point.conformite.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conformité *',
          style: TextStyle(
            fontSize: context.fontSizeS,
            fontWeight: FontWeight.w600,
            color: isValid ? Colors.grey.shade700 : Colors.red,
          ),
        ),
        SizedBox(height: context.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Oui',
                isSelected: point.conformite == 'oui',
                color: Colors.green,
                onTap: () {
                  setState(() {
                    point.conformite = 'oui';
                    // Quand on passe à Oui, on vide la référence
                    point.referenceNormative = null;
                  });
                  widget.onObservationToggleChanged(pointIndex, false);
                },
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Non',
                isSelected: point.conformite == 'non',
                color: Colors.red,
                onTap: () {
                  setState(() {
                    point.conformite = 'non';
                  });
                  // UNIQUEMENT ICI : on préremplit la référence
                  final reference = NormativeReferenceService.getReferenceForPoint(point.pointVerification);
                  if (reference != null) {
                    point.referenceNormative = reference;
                  }
                  widget.onObservationToggleChanged(pointIndex, true);
                },
              ),
            ),
          ],
        ),
        if (!isValid)
          Padding(
            padding: EdgeInsets.only(top: context.spacingXS),
            child: Text(
              'Veuillez sélectionner Oui ou Non',
              style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red),
            ),
          ),
      ],
    );
  }

  //méthode pour notifier les changements
  void _notifyConformiteChanged(int pointIndex, String value) {
    if (kDebugMode) {
      print('Point $pointIndex conformité: $value');
    }
  }

  Widget _buildConformiteButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: context.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.spacingS),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected 
                  ? (label == 'Oui' ? Icons.check_circle : Icons.cancel)
                  : (label == 'Oui' ? Icons.check_circle_outline : Icons.cancel_outlined),
              size: context.iconSizeS,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            SizedBox(width: context.spacingS),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fontSizeM,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bouton toggle pour la référence normative
  Widget _buildReferenceNormativeToggle(
    BuildContext context,
    PointVerification point,
    int pointIndex,
    bool showReference,
  ) {
    //Le point bleu est visible si une référence existe (donc si conformité = "non")
    final hasReference = point.referenceNormative != null && point.referenceNormative!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton pour afficher/masquer - LE POINT BLEU EST ICI (visible sans ouvrir)
        GestureDetector(
          onTap: () {
            setState(() {
              _showReferenceNormative[pointIndex] = !showReference;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacingS,
              vertical: context.spacingXS,
            ),
            decoration: BoxDecoration(
              color: showReference ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showReference ? Icons.article : Icons.article_outlined,
                  size: context.iconSizeXS,
                  color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500),
                ),
                SizedBox(width: context.spacingXS),
                Text(
                  'Référence normative',
                  style: TextStyle(
                    fontSize: context.fontSizeXS,
                    color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500),
                    fontWeight: hasReference ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                // POINT BLEU ICI - visible SANS ouvrir le champ
                if (hasReference)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  showReference ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: context.iconSizeXS,
                  color: hasReference ? Colors.blue : (showReference ? AppTheme.primaryBlue : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
        
        // Champ de référence (affiché conditionnellement - le contenu n'est visible qu'ici)
        if (showReference)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(top: context.spacingS),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(
                  color: hasReference ? Colors.blue.shade200 : Colors.grey.shade200,
                  width: hasReference ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                initialValue: point.referenceNormative ?? '',
                style: TextStyle(
                  fontSize: context.fontSizeS,
                  color: hasReference ? Colors.blue.shade800 : Colors.grey.shade700,
                ),
                readOnly: true,  //Lecture seule
                decoration: InputDecoration(
                  hintText: hasReference ? 'Référence préremplie' : 'Aucune référence',
                  hintStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(context.spacingM),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _updateReferenceNormative(int pointIndex, String conformite) {
    final point = widget.pointsVerification[pointIndex];
    
    if (conformite == 'non') {
      //Si conformité = non, préremplir la référence normative
      final reference = NormativeReferenceService.getReferenceForPoint(point.pointVerification);
      if (reference != null) {
        point.referenceNormative = reference;
      }
    } else if (conformite == 'oui') {
      // Si conformité = oui, on laisse vide (l'utilisateur ne peut pas modifier)
      // On ne supprime pas, on laisse tel quel
    }
  }

  Widget _buildObservationToggle(BuildContext context, int pointIndex, bool hasObservation) {
    final point = widget.pointsVerification[pointIndex];
    final isConformiteNon = point.conformite == 'non';
    
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
          onTap: () {
            if (isConformiteNon) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('L\'observation est obligatoire quand la conformité est "Non"'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            widget.onObservationToggleChanged(pointIndex, true);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: hasObservation ? Colors.green.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
              border: Border.all(color: hasObservation ? Colors.green : Colors.grey.shade300, width: hasObservation ? 2 : 1),
            ),
            child: Text('Oui', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: hasObservation ? Colors.green : Colors.grey.shade600)),
          ),
        ),
        SizedBox(width: context.spacingS),
        GestureDetector(
          onTap: () {
            if (isConformiteNon) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('L\'observation est obligatoire quand la conformité est "Non"'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            widget.onObservationToggleChanged(pointIndex, false);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: !hasObservation && !isConformiteNon ? Colors.red.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
              border: Border.all(color: (!hasObservation && !isConformiteNon) ? Colors.red : Colors.grey.shade300, width: (!hasObservation && !isConformiteNon) ? 2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Non',
                  style: TextStyle(
                    fontSize: context.fontSizeXS,
                    fontWeight: FontWeight.w600,
                    color: isConformiteNon ? Colors.grey.shade400 : (!hasObservation ? Colors.red : Colors.grey.shade600),
                  ),
                ),
                if (isConformiteNon)
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.lock_outline, size: context.fontSizeXS, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObservationField(BuildContext context, PointVerification point, int pointIndex) {
    final observations = _pointObservations[pointIndex] ?? [];
    final controller = _newObservationControllers[pointIndex]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liste des observations existantes (affichage 2 lignes max)
        if (observations.isNotEmpty)
          ...observations.asMap().entries.map((entry) {
            final obsIndex = entry.key;
            final obs = entry.value;
            return GestureDetector(
              onTap: () => _viewPointObservationDetail(obs),
              child: Container(
                margin: EdgeInsets.only(bottom: context.spacingS),
                padding: EdgeInsets.all(context.spacingM),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(context.spacingS),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        obs.texte,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade800),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: context.iconSizeS, color: AppTheme.primaryBlue),
                      onPressed: () => _editPointObservation(pointIndex, obsIndex),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: context.iconSizeS, color: Colors.red),
                      onPressed: () => _deletePointObservation(pointIndex, obsIndex),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            );
          }),
        
        // Champ pour nouvelle observation
        TextFormField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Nouvelle observation...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingS)),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingM),
          ),
        ),
        
        SizedBox(height: context.spacingM),
        
        // Bouton AJOUTER aligné à droite
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () => _addPointObservation(pointIndex),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
                  minimumSize: const Size(0, 0),
                ),
                child: const Text('AJOUTER'),
              ),
            ),
          ],
        ),
      ],
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
  final _numeroEquipementController = TextEditingController();
  final _repereController = TextEditingController();
  String? _selectedType;
  final _qrCodeController = TextEditingController();
  bool _isQrCodeValid = false;

  bool _zoneAtex = false;
  String _domaineTension = '';
  bool _identificationArmoire = false;
  bool _numeroEquipementValid = false;
  bool _signalisationDanger = false;
  bool _presenceSchema = false;
  bool _presenceParafoudre = false;
  bool _verificationThermographie = false;

  List<Alimentation> _alimentations = [];
  Alimentation? _protectionTete;
  List<PointVerification> _pointsVerification = [];

  // SUPPRIMÉ : _observationController, _observationPhotos, _selectedNiveauPuissance

  List<String> _coffretPhotosExterne = [];
  List<String> _coffretPhotosInterne = [];
  bool _isLoadingPhotosExterne = false;
  bool _isLoadingPhotosInterne = false;
  
  List<ObservationLibre> _observationsParafoudre = [];

  final ImagePicker _picker = ImagePicker();

  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _pointSuggestions = {};
  Map<int, bool> _pointLoading = {};
  Map<int, Timer?> _pointDebounceTimers = {};
  Map<int, bool> _hasObservation = {};

  bool _nomValid = false;
  bool _typeValid = false;
  bool _repereValid = false;
  // MODIFIÉ : Alimentations non obligatoires
  bool _alimentationsValid = true;
  bool _pointsValid = false;
  bool _domaineTensionValid = false;

  bool _photosExterneValid = false;
  bool _photosInterneValid = false;

  final PageController _mainPageController = PageController();
  int _currentStep = 0;
  
  GlobalKey<_EtapePointsVerificationState>? _etapePointsKey;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  String? _draftQrCode;

  @override
  void initState() {
    super.initState();
    _etapePointsKey = GlobalKey<_EtapePointsVerificationState>();
    _autoFillRepere();
    
    if (widget.qrCode != null) {
      _qrCodeController.text = widget.qrCode!;
      _validateQrCode(widget.qrCode!);
      _draftQrCode = widget.qrCode;
    }
    if (widget.isEdition) {
      _chargerDonneesExistantes();
    } else {
      _initializeAlimentations();
      _loadDraft;
      // Si on a un QR code, charger le brouillon existant
      if (_draftQrCode != null && _draftQrCode!.isNotEmpty) {
        _loadDraftByQrCode(_draftQrCode!);
      }
    }
  }

  // Charger un brouillon par QR code
  Future<void> _loadDraftByQrCode(String qrCode) async {
    final draft = HiveService.getCoffretDraftByQrCode(qrCode);
    if (draft != null) {
      setState(() {
        _nomController.text = draft.nom;
        _numeroEquipementController.text = draft.numeroEquipement ?? '';
        _repereController.text = draft.repere ?? '';
        _selectedType = draft.type;
        _zoneAtex = draft.zoneAtex;
        _domaineTension = draft.domaineTension;
        _identificationArmoire = draft.identificationArmoire;
        _signalisationDanger = draft.signalisationDanger;
        _presenceSchema = draft.presenceSchema;
        _presenceParafoudre = draft.presenceParafoudre;
        _verificationThermographie = draft.verificationThermographie;
        _alimentations = List.from(draft.alimentations);
        _protectionTete = draft.protectionTete;
        _pointsVerification = List.from(draft.pointsVerification);
        _coffretPhotosExterne = draft.photos.where((p) => p.contains('externe')).toList();
        _coffretPhotosInterne = draft.photos.where((p) => p.contains('interne')).toList();
        _currentStep = draft.currentStep;
        _observationsParafoudre = List.from(draft.observationsParafoudre ?? []);
        
        // Initialiser hasObservation
        for (int i = 0; i < _pointsVerification.length; i++) {
          final point = _pointsVerification[i];
          if (point.conformite == 'non') {
            _hasObservation[i] = true;
          } else {
            _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
          }
        }
        
        // Positionner le PageController
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mainPageController.hasClients) {
            _mainPageController.jumpToPage(_currentStep);
          }
        });
        
        _validateNom(_nomController.text);
        _validateType(_selectedType);
        _validateRepere(_repereController.text);
        _validateDomaineTension(_domaineTension);
        _validatePhotosExterne();
        _validatePhotosInterne();
        _validatePoints();
      });
    }
  }

  Future<void> _loadDraft() async {
    if (_draftQrCode == null || _draftQrCode!.isEmpty) return;
    
    final draftData = HiveService.getCoffretDraftData(_draftQrCode!);
    
    if (draftData != null) {
      final draft = draftData['coffret'] as CoffretArmoire;
      final savedStep = draftData['currentStep'] as int? ?? 0;
      
      setState(() {
        _nomController.text = draft.nom;
        _numeroEquipementController.text = draft.numeroEquipement ?? '';
        _repereController.text = draft.repere ?? '';
        _selectedType = draft.type;
        _zoneAtex = draft.zoneAtex;
        _domaineTension = draft.domaineTension;
        _identificationArmoire = draft.identificationArmoire;
        _signalisationDanger = draft.signalisationDanger;
        _presenceSchema = draft.presenceSchema;
        _presenceParafoudre = draft.presenceParafoudre;
        _verificationThermographie = draft.verificationThermographie;
        _alimentations = List.from(draft.alimentations);
        _protectionTete = draft.protectionTete;
        _pointsVerification = List.from(draft.pointsVerification);
        
        // CHARGER LES PHOTOS SÉPARÉMENT
        if (draft.photosExternes.isNotEmpty || draft.photosInternes.isNotEmpty) {
          _coffretPhotosExterne = List.from(draft.photosExternes);
          _coffretPhotosInterne = List.from(draft.photosInternes);
        } else if (draft.photos.isNotEmpty) {
          _coffretPhotosExterne = draft.photos.where((p) => p.contains('externe')).toList();
          _coffretPhotosInterne = draft.photos.where((p) => p.contains('interne')).toList();
          if (_coffretPhotosExterne.isEmpty && _coffretPhotosInterne.isEmpty) {
            _coffretPhotosExterne = List.from(draft.photos);
          }
        }
        
        _currentStep = savedStep;
        
        // VALIDER LES PHOTOS
        _validatePhotosExterne();
        _validatePhotosInterne();
        
        // Initialiser hasObservation
        for (int i = 0; i < _pointsVerification.length; i++) {
          final point = _pointsVerification[i];
          if (point.conformite == 'non') {
            _hasObservation[i] = true;
          } else {
            _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
          }
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mainPageController.hasClients) {
            _mainPageController.jumpToPage(_currentStep);
          }
        });
        
        _validateNom(_nomController.text);
        _validateNumeroEquipement(_numeroEquipementController.text);
        _validateType(_selectedType);
        _validateRepere(_repereController.text);
        _validateDomaineTension(_domaineTension);
        _validatePoints();
      });
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  void _addParafoudreObservation(String texte, List<String> photos) {
    setState(() {
      _observationsParafoudre.add(ObservationLibre(texte: texte, photos: photos));
    });
    _saveDraft();
  }

  void _deleteParafoudreObservation(int index) {
    setState(() {
      _observationsParafoudre.removeAt(index);
    });
    _saveDraft();
  }

  void _editParafoudreObservation(ObservationLibre observation) async {
    final controller = TextEditingController(text: observation.texte);
    List<String> tempPhotos = List.from(observation.photos);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier l\'observation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final index = _observationsParafoudre.indexOf(observation);
              if (index != -1) {
                setState(() {
                  _observationsParafoudre[index] = ObservationLibre(
                    texte: controller.text.trim(),
                    photos: tempPhotos,
                  );
                });
                _saveDraft();
              }
              Navigator.pop(context, true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    
    String qrCode = _qrCodeController.text.trim();
    if (qrCode.isEmpty) {
      qrCode = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
      _qrCodeController.text = qrCode;
      _draftQrCode = qrCode;
    }
    
    final toutesPhotos = [..._coffretPhotosExterne, ..._coffretPhotosInterne];
    
    final draft = CoffretArmoire(
      qrCode: qrCode,
      nom: _nomController.text.trim(),
      type: _selectedType ?? '',
      numeroEquipement: _numeroEquipementController.text.trim().isEmpty 
          ? null 
          : _numeroEquipementController.text.trim(),
      repere: _repereController.text.trim().isEmpty ? null : _repereController.text.trim(),
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
      photos: [..._coffretPhotosExterne, ..._coffretPhotosInterne],
      photosExternes: List.from(_coffretPhotosExterne),
      photosInternes: List.from(_coffretPhotosInterne),
      statut: 'incomplet',
      currentStep: _currentStep,
      observationsParafoudre: _observationsParafoudre,
    );
    
    await HiveService.saveCoffretDraft(
      missionId: widget.mission.id,
      parentType: widget.parentType,
      parentIndex: widget.parentIndex,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
      coffret: draft,
      currentStep: _currentStep,
    );
    
    _hasUnsavedChanges = false;
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
    // SUPPRIMÉ : _observationController.dispose();
    _qrCodeController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  void _validateNom(String value) {
    setState(() => _nomValid = value.trim().isNotEmpty);
    _scheduleAutoSave();
  }
  void _validateNumeroEquipement(String value) {
    setState(() => _numeroEquipementValid = true); 
    _scheduleAutoSave();
  }
  void _validateType(String? value){
    setState(() => _typeValid = value != null && value.isNotEmpty);
    _scheduleAutoSave();
  }
  void _validateRepere(String value){
    setState(() => _repereValid = value.trim().isNotEmpty);
    _scheduleAutoSave();
  }
  void _validateDomaineTension(String? value){
    setState(() => _domaineTensionValid = value != null && value.isNotEmpty);
    _scheduleAutoSave();
  }

  void _validateAlimentations() {
    setState(() => _alimentationsValid = true);
    _scheduleAutoSave();
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
    _scheduleAutoSave();
  }

  bool _validateAllFields() {
    bool allValid = true;
    if (_nomController.text.trim().isEmpty) { _nomValid = false; allValid = false; }
    if (_selectedType == null || _selectedType!.isEmpty) { _typeValid = false; allValid = false; }
    if (_repereController.text.trim().isEmpty) { _repereValid = false; allValid = false; }
    
    // Alimentations optionnelles - pas de validation
    _alimentationsValid = true;
    
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
    _scheduleAutoSave();
    return allValid;
  }

  void _validateQrCode(String qrCode) {
    if (qrCode.isEmpty) { setState(() => _isQrCodeValid = false); return; }
    final existing = HiveService.findCoffretByQrCode(widget.mission.id, qrCode);
    _isQrCodeValid = widget.isEdition ? true : existing == null;
    _scheduleAutoSave();
  }

  void _validatePhotosExterne() {
    setState(() {
      _photosExterneValid = _coffretPhotosExterne.isNotEmpty;
    });
    _scheduleAutoSave();
  }

  void _validatePhotosInterne() {
    setState(() {
      _photosInterneValid = _coffretPhotosInterne.isNotEmpty;
    });
    _scheduleAutoSave();
  }

  void _chargerDonneesExistantes() {
    final coffret = widget.coffret!;
    _nomController.text = coffret.nom;
    _numeroEquipementController.text = coffret.numeroEquipement ?? '';
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

    // CHARGER LES PHOTOS SÉPARÉMENT
    // Priorité aux nouveaux champs, sinon fallback sur l'ancien
    if (coffret.photosExternes.isNotEmpty || coffret.photosInternes.isNotEmpty) {
      _coffretPhotosExterne = List.from(coffret.photosExternes);
      _coffretPhotosInterne = List.from(coffret.photosInternes);
    } else if (coffret.photos.isNotEmpty) {
      // Pour la rétrocompatibilité, on essaie de deviner
      // Si le chemin contient "externe" ou "interne"
      _coffretPhotosExterne = coffret.photos
          .where((p) => p.contains('externe') || p.contains('externe'))
          .toList();
      _coffretPhotosInterne = coffret.photos
          .where((p) => p.contains('interne') || p.contains('interne'))
          .toList();
      
      // Si aucun critère, on met tout dans externe (comportement actuel)
      if (_coffretPhotosExterne.isEmpty && _coffretPhotosInterne.isEmpty) {
        _coffretPhotosExterne = List.from(coffret.photos);
      }
    }
    
    // VALIDER LES PHOTOS APRÈS CHARGEMENT
    _validatePhotosExterne();
    _validatePhotosInterne();
    
    for (int i = 0; i < _pointsVerification.length; i++) {
      final point = _pointsVerification[i];
      // Si conformité = "non", forcer hasObservation = true
      if (point.conformite == 'non') {
        _hasObservation[i] = true;
      } else {
        _hasObservation[i] = point.observation != null && point.observation!.isNotEmpty;
      }
    }
    
    if (coffret.photos.isNotEmpty) {
      // Supposons que la première moitié sont externes, deuxième moitié internes
      // Dans la pratique, il faudrait distinguer, mais on simplifie
      _coffretPhotosExterne = List.from(coffret.photos);
    }
    _initializeForCoffretType(_selectedType);
    _validateNom(coffret.nom);
    _validateNumeroEquipement(coffret.numeroEquipement ?? '');
    _validateType(coffret.type);
    _validateRepere(coffret.repere ?? '');
    _validateAlimentations();
    _validatePoints();
    _validateDomaineTension(coffret.domaineTension);
  }

  Future<void> _prendrePhotoExterne() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
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
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
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
      final points = HiveService.getPointsVerificationForCoffret(type);
      _pointsVerification = points.map((point) {
        // Récupérer la référence normative si elle existe
        final reference = NormativeReferenceService.getReferenceForPoint(point);
        return PointVerification(
          pointVerification: point,
          conformite: '',
          observation: null,
          referenceNormative: null,
          priorite: null,
        );
      }).toList();
      
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
    final point = _pointsVerification[index];
    
    // Si on essaie de mettre "Non" alors que conformité = "non", on bloque
    if (!value && point.conformite == 'non') {
      _showError('L\'observation est obligatoire quand la conformité est "Non"');
      return;
    }
    
    setState(() {
      _hasObservation[index] = value;
      if (!value) {
        _pointsVerification[index].observation = null;
      }
    });
    _scheduleAutoSave();
  }

  

  void _sauvegarder() async {
  if (!_validateAllFields()) { 
    _showError('Veuillez remplir tous les champs obligatoires'); 
    return; 
  }
  
  try {
    final toutesPhotos = [..._coffretPhotosExterne, ..._coffretPhotosInterne];
    final nouveauCoffret = CoffretArmoire(
      qrCode: _qrCodeController.text.trim(),
      nom: _nomController.text.trim(),
      type: _selectedType!,
      numeroEquipement: _numeroEquipementController.text.trim().isEmpty 
          ? null 
          : _numeroEquipementController.text.trim(),
      repere: _repereController.text.trim().isEmpty ? null : _repereController.text.trim(),
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
      photosExternes: List.from(_coffretPhotosExterne),
      photosInternes: List.from(_coffretPhotosInterne),
      statut: 'complet',
      currentStep: 0,
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
              missionId: widget.mission.id, 
              localIndex: widget.parentIndex, 
              coffret: nouveauCoffret, 
              qrCode: widget.qrCode!,
            );
          }
        } else {
          success = await HiveService.addCoffretToBasseTensionLocal(
            missionId: widget.mission.id, 
            zoneIndex: widget.zoneIndex ?? 0, 
            localIndex: widget.parentIndex, 
            coffret: nouveauCoffret,
          );
        }
      } else {
        if (widget.isMoyenneTension) {
          success = await HiveService.addCoffretToMoyenneTensionZone(
            missionId: widget.mission.id, 
            zoneIndex: widget.parentIndex, 
            coffret: nouveauCoffret,
          );
        } else {
          success = await HiveService.addCoffretToBasseTensionZone(
            missionId: widget.mission.id, 
            zoneIndex: widget.parentIndex, 
            coffret: nouveauCoffret,
          );
        }
      }
    }

    if (success) {
      // Supprimer le brouillon si existant
      await HiveService.deleteCoffretDraft(_draftQrCode ?? _qrCodeController.text.trim());
      
      if (widget.isEdition) {
        // En édition, on retourne simplement à l'écran précédent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Équipement mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // En création, on propose d'ajouter un essai
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
            mission: widget.mission, 
            localisationPredefinie: localisation, 
            coffretPredefini: nouveauCoffret.nom,
          ),
        ));
        Navigator.pop(context, true);
      }
    } else {
      _showError('Erreur lors de la sauvegarde');
    }
  } catch (e) { 
    _showError('Erreur: $e'); 
  }
}

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter sans sauvegarder ?'),
        content: const Text('Les modifications non sauvegardées seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context); // Quitter l'écran
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
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
      // MODIFIÉ : Pas de validation bloquante pour les alimentations
      _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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

  void _onPresenceParafoudreChanged(bool? value) {
    setState(() {
      _presenceParafoudre = value ?? false;
      if (!_presenceParafoudre) {
        _observationsParafoudre.clear();
      }
    });
    _saveDraft();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_hasUnsavedChanges) {
                _showExitConfirmation();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (widget.isEdition)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _sauvegarder,
              tooltip: 'Enregistrer les modifications',
            ),
          // Ancien bouton (pour création seulement)
          if (!widget.isEdition && _currentStep == totalSteps - 1)
            IconButton(
              icon: Icon(Icons.check, size: context.iconSizeM),
              onPressed: _sauvegarder,
            ),
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
                  // Étape 1 : Informations de base (sans observation équipement)
                  _EtapeInformationsBase(
                    nomController: _nomController,
                    numeroEquipementController: _numeroEquipementController,
                    repereController: _repereController,
                    selectedType: _selectedType,
                    onTypeChanged: _onTypeChanged,
                    typeValid: _typeValid,
                    nomValid: _nomValid,
                    numeroEquipementValid: _numeroEquipementValid,
                    repereValid: _repereValid,
                    onValidateNom: () => _validateNom(_nomController.text),
                    onValidateRepere: () => _validateRepere(_repereController.text),
                    onValidateNumeroEquipement: () => _validateNumeroEquipement(_numeroEquipementController.text),
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
                      onPresenceParafoudreChanged: _onPresenceParafoudreChanged,
                      verificationThermographie: _verificationThermographie,
                      onVerificationThermographieChanged: (v) => setState(() => _verificationThermographie = v ?? false),
                      domaineTension: _domaineTension,
                      onDomaineTensionChanged: (v) { setState(() { _domaineTension = v ?? ''; _validateDomaineTension(v); }); },
                      domaineTensionValid: _domaineTensionValid,
                      observationsParafoudre: _observationsParafoudre,
                      onAddParafoudreObservation: _addParafoudreObservation,
                      onDeleteParafoudreObservation: _deleteParafoudreObservation,
                      onEditParafoudreObservation: _editParafoudreObservation,
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
                      sourcesDisponibles: _getSourcesDisponibles(),
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

// Récupérer les sources disponibles depuis l'audit
List<String> _getSourcesDisponibles() {
  // Récupérer les coffrets existants pour les proposer comme sources
  final sources = <String>['Inverseur', 'Armoire', 'Coffret', 'TGBT'];
  // On pourrait aussi ajouter les noms des coffrets existants
  return sources;
}
