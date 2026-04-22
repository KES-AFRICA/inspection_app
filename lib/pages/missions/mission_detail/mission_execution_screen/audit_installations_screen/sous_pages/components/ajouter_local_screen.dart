import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
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

// Extension pour obtenir la taille de l'écran facilement
extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;
  
  // Tailles de police responsives
  double get fontSizeXXXL => isSmallScreen ? 20 : (isMediumScreen ? 22 : 26);
  double get fontSizeXXL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get fontSizeXL => isSmallScreen ? 16 : (isMediumScreen ? 17 : 18);
  double get fontSizeL => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get fontSizeM => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
  double get fontSizeS => isSmallScreen ? 11 : (isMediumScreen ? 12 : 13);
  double get fontSizeXS => isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
  
  // Espacements responsifs
  double get spacingXXL => isSmallScreen ? 20 : (isMediumScreen ? 24 : 28);
  double get spacingXL => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get spacingL => isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
  double get spacingM => isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
  double get spacingS => isSmallScreen ? 8 : (isMediumScreen ? 9 : 10);
  double get spacingXS => isSmallScreen ? 4 : (isMediumScreen ? 5 : 6);
  
  // Tailles d'icônes responsives
  double get iconSizeXL => isSmallScreen ? 20 : (isMediumScreen ? 22 : 24);
  double get iconSizeL => isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
  double get iconSizeM => isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
  double get iconSizeS => isSmallScreen ? 14 : (isMediumScreen ? 15 : 16);
  double get iconSizeXS => isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
}

// ================================================================
// ÉTAPE 1 : INFORMATIONS GÉNÉRALES (Nom, Type, Photos, Observations)
// ================================================================
class _EtapeInformationsGenerales extends StatefulWidget {
  final TextEditingController nomController;
  final String? selectedType;
  final Function(String?) onTypeChanged;
  final List<String> localPhotos;
  final Function() onPrendrePhoto;
  final Function() onChoisirPhoto;
  final VoidCallback onSupprimerPhoto;
  final bool isLoadingPhotos;
  final bool addObservation;
  final Function(bool) onAddObservationChanged;
  final TextEditingController observationController;
  final List<ObservationLibre> observationsExistantes;
  final List<String> observationPhotos;
  final Function() onPrendrePhotoObservation;
  final Function() onChoisirPhotoObservation;
  final Function() onAjouterObservation;
  final Function(int) onSupprimerObservationExistante;
  final bool nomValid;
  final bool typeValid;
  final VoidCallback onValidate;

  const _EtapeInformationsGenerales({
    required this.nomController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.localPhotos,
    required this.onPrendrePhoto,
    required this.onChoisirPhoto,
    required this.onSupprimerPhoto,
    required this.isLoadingPhotos,
    required this.addObservation,
    required this.onAddObservationChanged,
    required this.observationController,
    required this.observationsExistantes,
    required this.observationPhotos,
    required this.onPrendrePhotoObservation,
    required this.onChoisirPhotoObservation,
    required this.onAjouterObservation,
    required this.onSupprimerObservationExistante,
    required this.nomValid,
    required this.typeValid,
    required this.onValidate,
  });

  @override
  State<_EtapeInformationsGenerales> createState() => _EtapeInformationsGeneralesState();
}

class _EtapeInformationsGeneralesState extends State<_EtapeInformationsGenerales> {
  final PageController _photosController = PageController();
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        _buildModernHeader(context, 'Informations générales', 1, 4),
        SizedBox(height: context.spacingXL),
        _buildModernTextField(context),
        SizedBox(height: context.spacingXL),
        _buildModernTypeSelector(context),
        SizedBox(height: context.spacingXL),
        _buildModernPhotoCarousel(context),
        SizedBox(height: context.spacingXL),
        _buildModernObservationsCard(context),
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
                    style: TextStyle(
                      fontSize: context.fontSizeXXL,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  SizedBox(height: context.spacingXS),
                  Text(
                    'Étape $currentStep sur $totalSteps',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
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

  Widget _buildModernTextField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.nomController,
        onChanged: (_) => widget.onValidate(),
        style: TextStyle(fontSize: context.fontSizeM),
        decoration: InputDecoration(
          labelText: 'Nom du local',
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeM),
          prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: context.iconSizeM),
          suffixIcon: widget.nomValid 
              ? Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeS)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.spacingM),
            borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildModernTypeSelector(BuildContext context) {
    final localTypes = HiveService.getLocalTypes();
    final modifiedTypes = localTypes.map((key, value) {
      if (key == 'LOCAL_TRANSFORMATEUR') {
        return MapEntry(key, 'Local Poste/Transformateur');
      }
      return MapEntry(key, value);
    });
    
    final filteredTypes = modifiedTypes.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
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
                    'Type de local',
                    style: TextStyle(
                      fontSize: context.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: context.fontSizeL),
                ),
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
                        'Sélectionnez un type de local',
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
                items: filteredTypes.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Container(
                          width: context.spacingS,
                          height: context.spacingS,
                          decoration: BoxDecoration(
                            color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: widget.selectedType == entry.key
                              ? Icon(Icons.check, size: context.spacingXS, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: context.fontSizeM,
                              fontWeight: widget.selectedType == entry.key ? FontWeight.w600 : FontWeight.w400,
                              color: widget.selectedType == entry.key ? AppTheme.primaryBlue : Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.onTypeChanged,
                selectedItemBuilder: (BuildContext context) {
                  return filteredTypes.map<Widget>((entry) {
                    return Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: context.iconSizeS),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: AppTheme.darkBlue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                  Flexible(
                    child: Text(
                      'Sélectionnez un type de local',
                      style: TextStyle(color: Colors.red, fontSize: context.fontSizeXS),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoCarousel(BuildContext context) {
    final photoHeight = context.screenHeight * 0.25;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
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
                    'Photos du local',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
                const Spacer(),
                if (widget.localPhotos.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.spacingL),
                    ),
                    child: Text(
                      '${widget.localPhotos.length} photo${widget.localPhotos.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
          
          if (widget.isLoadingPhotos)
            Container(
              height: photoHeight,
              width: double.infinity,
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            )
          else if (widget.localPhotos.isEmpty)
            Container(
              height: photoHeight,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: context.spacingL),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: context.iconSizeXL * 1.5, color: Colors.grey.shade400),
                  SizedBox(height: context.spacingM),
                  Flexible(
                    child: Text(
                      'Aucune photo',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeM),
                    ),
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
                    controller: _photosController,
                    onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
                    itemCount: widget.localPhotos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenPhoto(widget.localPhotos, index),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: context.spacingXS),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.spacingS),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.spacingS),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(widget.localPhotos[index]), fit: BoxFit.cover),
                                Positioned(
                                  top: context.spacingS,
                                  right: context.spacingS,
                                  child: GestureDetector(
                                    onTap: () => _confirmDeletePhoto(index),
                                    child: Container(
                                      padding: EdgeInsets.all(context.spacingXS),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.delete_outline, color: Colors.white, size: context.iconSizeS),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.localPhotos.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacingS, bottom: context.spacingS),
                    child: SmoothPageIndicator(
                      controller: _photosController,
                      count: widget.localPhotos.length,
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
                    onTap: widget.onPrendrePhoto,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: _buildModernPhotoButton(
                    context,
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: widget.onChoisirPhoto,
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
                  style: TextStyle(
                    fontSize: context.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: isSecondary ? Colors.grey.shade700 : Colors.white,
                  ),
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

  Widget _buildModernObservationsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: context.spacingS,
            offset: Offset(0, 2),
          ),
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
                    'Observations',
                    style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacingL),
            child: Container(
              padding: EdgeInsets.all(context.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(context.spacingS),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ajouter une observation ?',
                      style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                  ),
                  _buildModernToggleButton(
                    context,
                    label: 'Oui',
                    isSelected: widget.addObservation,
                    onTap: () => widget.onAddObservationChanged(true),
                    color: Colors.green,
                  ),
                  SizedBox(width: context.spacingS),
                  _buildModernToggleButton(
                    context,
                    label: 'Non',
                    isSelected: !widget.addObservation,
                    onTap: () => widget.onAddObservationChanged(false),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.observationsExistantes.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observations existantes',
                    style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: context.spacingS),
                  ...widget.observationsExistantes.asMap().entries.map((entry) {
                    return _buildModernExistingObservation(context, entry.value, entry.key);
                  }),
                ],
              ),
            ),
          
          if (widget.addObservation)
            Padding(
              padding: EdgeInsets.all(context.spacingL),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.spacingS),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextFormField(
                      controller: widget.observationController,
                      style: TextStyle(fontSize: context.fontSizeS),
                      decoration: InputDecoration(
                        hintText: 'Saisissez votre observation...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: context.fontSizeS),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(context.spacingM),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(height: context.spacingM),
                  Row(
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
                  if (widget.observationPhotos.isNotEmpty)
                    Container(
                      height: context.screenHeight * 0.1,
                      margin: EdgeInsets.only(top: context.spacingM),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.observationPhotos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: context.screenWidth * 0.2,
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
                  SizedBox(height: context.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onAjouterObservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: context.spacingM),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
                      ),
                      child: Text('Ajouter cette observation', style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600)),
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

  Widget _buildModernToggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.spacingXL),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildModernExistingObservation(BuildContext context, ObservationLibre observation, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingS),
      padding: EdgeInsets.all(context.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  observation.texte,
                  style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade800),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSupprimerObservationExistante(index),
                child: Container(
                  padding: EdgeInsets.all(context.spacingXS),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline, size: context.iconSizeS, color: Colors.red),
                ),
              ),
            ],
          ),
          if (observation.photos.isNotEmpty) ...[
            SizedBox(height: context.spacingS),
            Container(
              height: context.screenHeight * 0.08,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: observation.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Container(
                    width: context.screenWidth * 0.18,
                    margin: EdgeInsets.only(right: context.spacingS),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.spacingS),
                      child: Image.file(File(observation.photos[photoIndex]), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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

  void _confirmDeletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la photo ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSupprimerPhoto();
              setState(() {
                if (_currentPhotoIndex >= widget.localPhotos.length) {
                  _currentPhotoIndex = widget.localPhotos.length - 1;
                }
                _photosController.jumpToPage(_currentPhotoIndex.clamp(0, widget.localPhotos.length - 1));
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ÉTAPE 2 : ÉLÉMENTS DE CONTRÔLE (Dispositions + Conditions)
// ================================================================
class _EtapeElementsControle extends StatefulWidget {
  final List<ElementControle> dispositionsConstructives;
  final List<ElementControle> conditionsExploitation;
  final Map<int, bool> hasObservation;
  final Map<int, List<String>> elementSuggestions;
  final Map<ElementControle, bool> conformeSelected;
  final Function(ElementControle, int, String) onElementChanged;
  final Function(ElementControle) onConformeChanged;
  final Function(int, bool, String) onObservationToggleChanged;
  final Function(ElementControle, int, String) onPrendrePhotoElement;
  final Function(ElementControle, int, String) onChoisirPhotoElement;
  final Function(ElementControle, int, int, String) onSupprimerPhotoElement;
  final Function(int, String, String) onObservationChanged;
  final Function(int, String, ElementControle, String) onUseSuggestion;
  final Function(String) onAjouterAutre; // Callback pour ajouter "Autre"
  final VoidCallback onRebuildSlides; // NOUVEAU : Callback pour reconstruire les slides après ajout

  const _EtapeElementsControle({
    super.key,
    required this.dispositionsConstructives,
    required this.conditionsExploitation,
    required this.hasObservation,
    required this.elementSuggestions,
    required this.conformeSelected,
    required this.onElementChanged,
    required this.onConformeChanged,
    required this.onObservationToggleChanged,
    required this.onPrendrePhotoElement,
    required this.onChoisirPhotoElement,
    required this.onSupprimerPhotoElement,
    required this.onObservationChanged,
    required this.onUseSuggestion,
    required this.onAjouterAutre,
    required this.onRebuildSlides,
  });

  @override
  State<_EtapeElementsControle> createState() => _EtapeElementsControleState();
}

class _EtapeElementsControleState extends State<_EtapeElementsControle> {
  final PageController _slideController = PageController();
  
  int _currentSection = 0;
  int _currentSlide = 0;
  
  late List<List<ElementControle>> _dispositionsSlides;
  late List<List<ElementControle>> _conditionsSlides;

  @override
  void initState() {
    super.initState();
    _buildSlides();
  }

  void _buildSlides() {
    _dispositionsSlides = [];
    for (int i = 0; i < widget.dispositionsConstructives.length; i += 3) {
      _dispositionsSlides.add(widget.dispositionsConstructives.sublist(
        i, 
        (i + 3).clamp(0, widget.dispositionsConstructives.length)
      ));
    }
    
    _conditionsSlides = [];
    for (int i = 0; i < widget.conditionsExploitation.length; i += 3) {
      _conditionsSlides.add(widget.conditionsExploitation.sublist(
        i, 
        (i + 3).clamp(0, widget.conditionsExploitation.length)
      ));
    }
  }

  List<List<ElementControle>> get _currentSlides => 
      _currentSection == 0 ? _dispositionsSlides : _conditionsSlides;
  
  String get _currentSectionTitle => 
      _currentSection == 0 ? 'DISPOSITIONS CONSTRUCTIVES' : 'CONDITIONS D\'EXPLOITATION';
  
  Color get _currentSectionColor => 
      _currentSection == 0 ? const Color(0xFF2C3E50) : const Color(0xFF34495E);
  
  int get _totalSlides => _currentSlides.length;
  
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;
  
  bool get _isFirstSlide => _currentSlide == 0;
  
  bool get _isLastSection => _currentSection == 1;
  
  bool get _canGoToNextSection => _currentSection == 0 && _isLastSlide;

  bool _isCurrentSlideValid() {
    if (_currentSlides.isEmpty) return true;
    
    final currentElements = _currentSlides[_currentSlide];
    for (var element in currentElements) {
      if (element.conforme == null) return false;
      if (element.priorite == null) return false;
      
      final elementIndex = _getElementIndex(element);
      // Si conformité = Non, l'observation est OBLIGATOIRE
      if (element.conforme == false) {
        if (widget.hasObservation[elementIndex] != true) return false;
        if (element.observation == null || element.observation!.trim().isEmpty) return false;
      } else {
        // Si Oui, l'observation est optionnelle
        if (widget.hasObservation[elementIndex] == true) {
          if (element.observation == null || element.observation!.trim().isEmpty) return false;
        }
      }
    }
    return true;
  }

  int _getElementIndex(ElementControle element) {
    if (_currentSection == 0) {
      return widget.dispositionsConstructives.indexOf(element);
    } else {
      return widget.dispositionsConstructives.length + widget.conditionsExploitation.indexOf(element);
    }
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      _showError('Veuillez remplir tous les champs obligatoires de ce slide');
      return;
    }
    
    if (_isLastSlide) {
      if (_canGoToNextSection) {
        setState(() {
          _currentSection = 1;
          _currentSlide = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(0);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void previousSlide() {
    if (_isFirstSlide) {
      if (_currentSection == 1) {
        setState(() {
          _currentSection = 0;
          _currentSlide = _dispositionsSlides.length - 1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(_dispositionsSlides.length - 1);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  bool canGoNext() {
    if (!_isCurrentSlideValid()) return false;
    if (_isLastSection && _isLastSlide) return true;
    return false;
  }

  bool canGoPrevious() {
    return _isFirstSlide && _currentSection == 0;
  }

  /// Méthode pour reconstruire les slides (appelée depuis le parent après ajout d'un élément)
  void rebuildSlides() {
    _buildSlides();
    setState(() {});
  }

  /// Méthode pour aller au dernier slide de la section courante
  void goToLastSlide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_slideController.hasClients && _totalSlides > 0) {
        _slideController.jumpToPage(_totalSlides - 1);
        setState(() {
          _currentSlide = _totalSlides - 1;
        });
      }
    });
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
            Text('Aucun élément à contrôler', style: TextStyle(fontSize: context.fontSizeL, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // En-tête simplifié
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
                width: context.iconSizeXL * 1.2,
                height: context.iconSizeXL * 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Icon(Icons.checklist, color: Colors.white, size: context.iconSizeM),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Text(
                  'Éléments de contrôle',
                  style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                ),
              ),
            ],
          ),
        ),
        
        // Titre de section avec compteur sur la même ligne
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingS),
          child: Row(
            children: [
              Container(
                width: 4,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: _currentSectionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  _currentSectionTitle,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: _currentSectionColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_currentSlide + 1}/${_totalSlides}',
                style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        // Barre de progression
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_currentSectionColor),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Zone des éléments
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) {
              final slideElements = _currentSlides[slideIndex];
              
              return ListView(
                padding: EdgeInsets.all(context.spacingL),
                children: [
                  ...slideElements.map((element) {
                    final originalIndex = _currentSection == 0 
                        ? widget.dispositionsConstructives.indexOf(element)
                        : widget.conditionsExploitation.indexOf(element);
                    final globalIndex = _currentSection == 0 
                        ? originalIndex 
                        : widget.dispositionsConstructives.length + originalIndex;
                    
                    return _buildModernElementCard(
                      context,
                      element: element,
                      index: originalIndex,
                      globalIndex: globalIndex,
                      sectionType: _currentSection == 0 ? 'dispositions' : 'conditions',
                      color: _currentSectionColor,
                    );
                  }).toList(),
                  
                  // CORRECTION : Le bouton "Autre" n'apparaît que sur le DERNIER slide
                  if (_isLastSlide)
                    _buildAutreButton(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutreButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spacingL),
      child: OutlinedButton.icon(
        onPressed: () async {
          // Appeler le callback pour ajouter un élément "Autre"
          await widget.onAjouterAutre(_currentSection == 0 ? 'dispositions' : 'conditions');
          // Après l'ajout, reconstruire les slides
          widget.onRebuildSlides();
        },
        icon: Icon(Icons.add_circle_outline, size: context.iconSizeM, color: AppTheme.primaryBlue),
        label: Text(
          'AUTRE',
          style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          side: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.spacingS)),
        ),
      ),
    );
  }

  Widget _buildModernElementCard(
    BuildContext context, {
    required ElementControle element,
    required int index,
    required int globalIndex,
    required String sectionType,
    required Color color,
  }) {
    final hasObservation = widget.hasObservation[globalIndex] ?? false;
    final suggestions = widget.elementSuggestions[index] ?? [];
    final isConformiteNon = element.conforme == false;
    
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
          // En-tête avec numéro et titre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.iconSizeL,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  element.elementControle,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.darkBlue, height: 1.3),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          
          SizedBox(height: context.spacingL),
          
          // Ligne 1 : Conformité (seule, sur toute la largeur)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Conformité *',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: element.conforme != null ? Colors.grey.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildConformiteButton(
                      context,
                      label: 'Oui',
                      isSelected: element.conforme == true,
                      color: Colors.green,
                      onTap: () {
                        setState(() {
                          element.conforme = true;
                          widget.onConformeChanged(element);
                          widget.onElementChanged(element, index, 'conformite');
                          // Forcer l'observation à Non
                          widget.onObservationToggleChanged(globalIndex, false, sectionType);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: _buildConformiteButton(
                      context,
                      label: 'Non',
                      isSelected: element.conforme == false,
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          element.conforme = false;
                          widget.onConformeChanged(element);
                          widget.onElementChanged(element, index, 'conformite');
                          // Forcer l'observation à Oui
                          widget.onObservationToggleChanged(globalIndex, true, sectionType);
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (element.conforme == null)
                Padding(
                  padding: EdgeInsets.only(top: context.spacingXS),
                  child: Text(
                    'Veuillez sélectionner Oui ou Non',
                    style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Ligne 2 : Priorité (seule, sur toute la largeur)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Priorité',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              _buildModernPrioriteSelector(context, element, color, index, sectionType),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Toggle Observation
          _buildModernObservationToggle(
            context, globalIndex, hasObservation, color, sectionType, isConformiteNon,
          ),
          
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            _buildModernObservationField(
              context: context,
              element: element,
              index: index,
              globalIndex: globalIndex,
              sectionType: sectionType,
              suggestions: suggestions,
              color: color,
            ),
          ],
          
          SizedBox(height: context.spacingM),
          
          // Photos
          _buildModernElementPhotos(
            context: context,
            element: element,
            index: index,
            sectionType: sectionType,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildModernConformiteToggle(
    BuildContext context,
    ElementControle element,
    Color color,
    int index,
    int globalIndex,
    String sectionType,
  ) {
    final isValid = widget.conformeSelected[element] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Conformité *',
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.w600,
                color: isValid ? Colors.grey.shade700 : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Oui',
                isSelected: element.conforme == true,
                color: Colors.green,
                onTap: () {
                  setState(() {
                    element.conforme = true;
                    widget.onConformeChanged(element);
                    widget.onElementChanged(element, index, 'conformite');
                  });
                },
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildConformiteButton(
                context,
                label: 'Non',
                isSelected: element.conforme == false,
                color: Colors.red,
                onTap: () {
                  setState(() {
                    element.conforme = false;
                    widget.onConformeChanged(element);
                    widget.onElementChanged(element, index, 'conformite');
                    // Forcer l'observation à Oui
                    widget.onObservationToggleChanged(globalIndex, true, sectionType);
                  });
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

  Widget _buildModernConformiteSelector(
    BuildContext context, 
    ElementControle element, 
    Color color, 
    int index, 
    String sectionType, 
    bool isConformeSelected,
    int globalIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: !isConformeSelected ? Colors.red.shade300 : Colors.transparent,
          width: !isConformeSelected ? 1.5 : 0,
        ),
      ),
      child: DropdownButtonFormField<bool?>(
        initialValue: isConformeSelected ? element.conforme : null,
        hint: Text('Sélectionnez *', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500)),
        onChanged: (bool? newValue) {
          if (newValue != null) {
            setState(() {
              element.conforme = newValue;
              widget.onConformeChanged(element);
              widget.onElementChanged(element, index, 'conformite');
              
              if (newValue == false) {
                widget.onObservationToggleChanged(globalIndex, true, sectionType);
              } else {
                widget.onObservationToggleChanged(globalIndex, false, sectionType);
              }
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Conformité *',
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
        items: [
          DropdownMenuItem(
            value: true,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Oui', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Non', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
        ],
        isExpanded: true,
      ),
    );
  }

  Widget _buildModernPrioriteSelector(BuildContext context, ElementControle element, Color color, int index, String sectionType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingS),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N1',
              tooltip: 'Basse priorité',
              isSelected: element.priorite == 1,
              color: Colors.blue,
              onTap: () {
                setState(() {
                  element.priorite = 1;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N2',
              tooltip: 'Moyenne priorité',
              isSelected: element.priorite == 2,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  element.priorite = 2;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButton(
              context,
              label: 'N3',
              tooltip: 'Haute priorité',
              isSelected: element.priorite == 3,
              color: Colors.red,
              onTap: () {
                setState(() {
                  element.priorite = 3;
                  widget.onElementChanged(element, index, 'priorite');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioriteButton(
    BuildContext context, {
    required String label,
    required String tooltip,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.flag : Icons.flag_outlined,
                size: context.iconSizeS,
                color: isSelected ? color : Colors.grey.shade500,
              ),
              SizedBox(height: context.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernObservationToggle(
  BuildContext context,
  int globalIndex,
  bool hasObservation,
  Color color,
  String sectionType,
  bool isConformiteNon,
) {
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
      // Bouton Oui
      GestureDetector(
        onTap: () {
          // Si conformité = Non, on ne peut pas désactiver l'observation
          if (!isConformiteNon) {
            widget.onObservationToggleChanged(globalIndex, true, sectionType);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
          decoration: BoxDecoration(
            color: hasObservation ? Colors.green.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(context.spacingL),
            border: Border.all(
              color: hasObservation ? Colors.green : (isConformiteNon ? Colors.grey.shade300 : Colors.grey.shade300),
              width: hasObservation ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Oui',
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: hasObservation ? Colors.green : (isConformiteNon ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
              if (isConformiteNon && !hasObservation)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.lock_open,
                    size: context.fontSizeXS,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
      SizedBox(width: context.spacingS),
      // Bouton Non
      GestureDetector(
        onTap: isConformiteNon 
            ? null 
            : () => widget.onObservationToggleChanged(globalIndex, false, sectionType),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
          decoration: BoxDecoration(
            color: !hasObservation && !isConformiteNon
                ? Colors.red.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.spacingL),
            border: Border.all(
              color: !hasObservation && !isConformiteNon
                  ? Colors.red
                  : (isConformiteNon ? Colors.grey.shade300 : Colors.grey.shade300),
              width: !hasObservation && !isConformiteNon ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Non',
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isConformiteNon
                      ? Colors.grey.shade400
                      : (!hasObservation ? Colors.red : Colors.grey.shade600),
                ),
              ),
              if (isConformiteNon)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.lock_outline,
                    size: context.fontSizeXS,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildModernObservationField({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required int globalIndex,
    required String sectionType,
    required List<String> suggestions,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: element.observation == null || element.observation!.trim().isEmpty ? Colors.red.shade300 : Colors.transparent,
              width: element.observation == null || element.observation!.trim().isEmpty ? 1.5 : 0,
            ),
          ),
          child: TextFormField(
            initialValue: element.observation,
            style: TextStyle(fontSize: context.fontSizeS),
            onChanged: (value) {
              element.observation = value;
              widget.onObservationChanged(index, value, sectionType);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Saisissez votre observation... *',
              hintStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.spacingM),
            ),
            maxLines: 2,
          ),
        ),
        
        if (suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: context.spacingS),
            padding: EdgeInsets.all(context.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggestions', style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.bold, color: color)),
                SizedBox(height: context.spacingXS),
                ...suggestions.map((s) => GestureDetector(
                  onTap: () => widget.onUseSuggestion(index, s, element, sectionType),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.spacingXS),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: context.iconSizeXS, color: Colors.amber),
                        SizedBox(width: context.spacingS),
                        Expanded(
                          child: Text(s, style: TextStyle(fontSize: context.fontSizeXS, color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildModernElementPhotos({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required String sectionType,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, size: context.iconSizeXS, color: color),
            SizedBox(width: context.spacingS),
            Flexible(
              child: Text(
                'Photos (${element.photos.length})',
                style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        
        if (element.photos.isNotEmpty)
          Container(
            height: context.screenHeight * 0.1,
            margin: EdgeInsets.only(bottom: context.spacingS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: element.photos.length,
              itemBuilder: (context, photoIndex) {
                return Stack(
                  children: [
                    Container(
                      width: context.screenWidth * 0.2,
                      margin: EdgeInsets.only(right: context.spacingS),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.spacingS),
                        child: Image.file(File(element.photos[photoIndex]), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: context.spacingXS,
                      right: context.spacingS + context.spacingXS,
                      child: GestureDetector(
                        onTap: () => widget.onSupprimerPhotoElement(element, index, photoIndex, sectionType),
                        child: Container(
                          padding: EdgeInsets.all(context.spacingXS),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: context.iconSizeXS - 2, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: _buildSmallIconButton(
                context,
                icon: Icons.camera_alt,
                label: 'Prendre',
                onTap: () => widget.onPrendrePhotoElement(element, index, sectionType),
                color: color,
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildSmallIconButton(
                context,
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => widget.onChoisirPhotoElement(element, index, sectionType),
                color: color,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
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
            color: isSecondary ? Colors.grey.shade100 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(color: isSecondary ? Colors.grey.shade300 : color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.iconSizeXS, color: isSecondary ? Colors.grey.shade700 : color),
              SizedBox(width: context.spacingXS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: context.fontSizeXS - 1, fontWeight: FontWeight.w600, color: isSecondary ? Colors.grey.shade700 : color),
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
// ÉTAPE 3 : CELLULE ET TRANSFORMATEUR
// ================================================================

class _EtapeCelluleTransformateur extends StatefulWidget {
  final TextEditingController celluleFonctionController;
  final TextEditingController celluleTypeController;
  final TextEditingController celluleMarqueController;
  final TextEditingController celluleTensionController;
  final TextEditingController cellulePouvoirController;
  final TextEditingController celluleNumerotationController;
  final TextEditingController celluleParafoudresController;
  final List<ElementControle> celluleElements;
  final TextEditingController transfoTypeController;
  final TextEditingController transfoMarqueController;
  final TextEditingController transfoPuissanceController;
  final TextEditingController transfoTensionController;
  final TextEditingController transfoBuchholzController;
  final TextEditingController transfoRefroidissementController;
  final TextEditingController transfoRegimeController;
  final List<ElementControle> transfoElements;
  final Map<int, bool> hasObservation;
  final Map<int, List<String>> elementSuggestions;
  final Map<ElementControle, bool> conformeSelected;
  final Function(ElementControle, int, String) onElementChanged;
  final Function(ElementControle) onConformeChanged;
  final Function(int, bool, String) onObservationToggleChanged;
  final Function(ElementControle, int, String) onPrendrePhotoElement;
  final Function(ElementControle, int, String) onChoisirPhotoElement;
  final Function(ElementControle, int, int, String) onSupprimerPhotoElement;
  final Function(int, String, String) onObservationChanged;
  final Function(int, String, ElementControle, String) onUseSuggestion;

  const _EtapeCelluleTransformateur({
    super.key,
    required this.celluleFonctionController,
    required this.celluleTypeController,
    required this.celluleMarqueController,
    required this.celluleTensionController,
    required this.cellulePouvoirController,
    required this.celluleNumerotationController,
    required this.celluleParafoudresController,
    required this.celluleElements,
    required this.transfoTypeController,
    required this.transfoMarqueController,
    required this.transfoPuissanceController,
    required this.transfoTensionController,
    required this.transfoBuchholzController,
    required this.transfoRefroidissementController,
    required this.transfoRegimeController,
    required this.transfoElements,
    required this.hasObservation,
    required this.elementSuggestions,
    required this.conformeSelected,
    required this.onElementChanged,
    required this.onConformeChanged,
    required this.onObservationToggleChanged,
    required this.onPrendrePhotoElement,
    required this.onChoisirPhotoElement,
    required this.onSupprimerPhotoElement,
    required this.onObservationChanged,
    required this.onUseSuggestion,
  });

  @override
  State<_EtapeCelluleTransformateur> createState() => _EtapeCelluleTransformateurState();
}

class _EtapeCelluleTransformateurState extends State<_EtapeCelluleTransformateur> {
  final PageController _slideController = PageController();
  
  // 0 = Cellule données, 1 = Cellule éléments, 2 = Transfo données, 3 = Transfo éléments
  int _currentSection = 0;
  int _currentSlide = 0;
  
  late List<List<ElementControle>> _celluleElementsSlides;
  late List<List<ElementControle>> _transfoElementsSlides;
  
  // Options pour les dropdowns
  static const List<String> _presentAbsentOptions = ['Présent', 'Absent'];

  @override
  void initState() {
    super.initState();
    _buildSlides();
  }

  void _buildSlides() {
    _celluleElementsSlides = [];
    for (int i = 0; i < widget.celluleElements.length; i += 3) {
      _celluleElementsSlides.add(widget.celluleElements.sublist(
        i, 
        (i + 3).clamp(0, widget.celluleElements.length)
      ));
    }
    
    _transfoElementsSlides = [];
    for (int i = 0; i < widget.transfoElements.length; i += 3) {
      _transfoElementsSlides.add(widget.transfoElements.sublist(
        i, 
        (i + 3).clamp(0, widget.transfoElements.length)
      ));
    }
  }

  List<Map<String, dynamic>> get _sections {
    final sections = <Map<String, dynamic>>[];
    
    sections.add({
      'title': 'CELLULE',
      'type': 'cellule',
      'color': const Color(0xFFE67E22),
    });
    
    sections.add({
      'title': 'TRANSFORMATEUR',
      'type': 'transfo',
      'color': const Color(0xFF2980B9),
    });
    
    return sections;
  }

  Map<String, dynamic> get _currentSectionData => _sections[_currentSection];
  String get _currentSectionType => _currentSectionData['type'];
  Color get _currentColor => _currentSectionData['color'];
  bool get _isLastSection => _currentSection == _sections.length - 1;

  int _getTotalSlidesForCurrentSection() {
    if (_currentSection == 0) {
      return 1 + _celluleElementsSlides.length;
    } else {
      return 1 + _transfoElementsSlides.length;
    }
  }

  int get _totalSlides => _getTotalSlidesForCurrentSection();
  bool get _isLastSlide => _currentSlide == _totalSlides - 1;
  bool get _isFirstSlide => _currentSlide == 0;

  bool _isCurrentSlideValid() {
    if (_currentSection == 0) {
      if (_currentSlide == 0) {
        return _validateCelluleDonnees();
      } else {
        final elementSlideIndex = _currentSlide - 1;
        if (elementSlideIndex < _celluleElementsSlides.length) {
          return _validateElementsSlide(_celluleElementsSlides[elementSlideIndex], 1000);
        }
      }
    } else {
      if (_currentSlide == 0) {
        return _validateTransfoDonnees();
      } else {
        final elementSlideIndex = _currentSlide - 1;
        if (elementSlideIndex < _transfoElementsSlides.length) {
          return _validateElementsSlide(_transfoElementsSlides[elementSlideIndex], 2000);
        }
      }
    }
    return true;
  }

  bool _validateCelluleDonnees() {
    return widget.celluleFonctionController.text.trim().isNotEmpty &&
           widget.celluleTypeController.text.trim().isNotEmpty &&
           widget.celluleMarqueController.text.trim().isNotEmpty &&
           widget.celluleTensionController.text.trim().isNotEmpty &&
           widget.cellulePouvoirController.text.trim().isNotEmpty &&
           widget.celluleNumerotationController.text.isNotEmpty &&
           widget.celluleParafoudresController.text.isNotEmpty;
  }

  bool _validateTransfoDonnees() {
    return widget.transfoTypeController.text.trim().isNotEmpty &&
           widget.transfoMarqueController.text.trim().isNotEmpty &&
           widget.transfoPuissanceController.text.trim().isNotEmpty &&
           widget.transfoTensionController.text.trim().isNotEmpty &&
           widget.transfoBuchholzController.text.trim().isNotEmpty &&
           widget.transfoRefroidissementController.text.trim().isNotEmpty &&
           widget.transfoRegimeController.text.trim().isNotEmpty;
  }

  bool _validateElementsSlide(List<ElementControle> elements, int baseIndex) {
    for (var element in elements) {
      if (!(widget.conformeSelected[element] ?? false)) return false;
      if (element.priorite == null) return false;
      
      final elementIndex = _currentSection == 0
          ? baseIndex + widget.celluleElements.indexOf(element)
          : baseIndex + widget.transfoElements.indexOf(element);
      
      // Si conformité = Non, l'observation est OBLIGATOIRE
      if (element.conforme == false) {
        if (widget.hasObservation[elementIndex] != true) return false;
        if (element.observation == null || element.observation!.trim().isEmpty) return false;
      } else {
        if (widget.hasObservation[elementIndex] == true) {
          if (element.observation == null || element.observation!.trim().isEmpty) return false;
        }
      }
    }
    return true;
  }

  void nextSlide() {
    if (!_isCurrentSlideValid()) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }
    
    if (_isLastSlide) {
      if (!_isLastSection) {
        setState(() {
          _currentSection++;
          _currentSlide = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(0);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void previousSlide() {
    if (_isFirstSlide) {
      if (_currentSection > 0) {
        setState(() {
          _currentSection--;
          _currentSlide = _getTotalSlidesForPreviousSection() - 1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_slideController.hasClients) {
            _slideController.jumpToPage(_currentSlide);
          }
        });
      }
    } else {
      if (_slideController.hasClients) {
        _slideController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  int _getTotalSlidesForPreviousSection() {
    if (_currentSection == 1) {
      return 1 + _celluleElementsSlides.length;
    }
    return 1;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
    );
  }

  bool canGoNext() {
    if (!_isCurrentSlideValid()) return false;
    return _isLastSection && _isLastSlide;
  }

  bool canGoPrevious() {
    return _isFirstSlide && _currentSection == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête
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
                width: context.iconSizeXL * 1.2,
                height: context.iconSizeXL * 1.2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE67E22), Color(0xFF2980B9)]),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Icon(Icons.electric_bolt, color: Colors.white, size: context.iconSizeM),
              ),
              SizedBox(width: context.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cellule & Transformateur',
                      style: TextStyle(fontSize: context.fontSizeXXL, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                    ),
                    Text(
                      'Données techniques et vérifications',
                      style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Titre de section avec compteur
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingS),
          child: Row(
            children: [
              Container(
                width: 4,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  _currentSection == 0 
                      ? (_currentSlide == 0 ? 'CELLULE - Données techniques' : 'CELLULE - Éléments vérifiés')
                      : (_currentSlide == 0 ? 'TRANSFORMATEUR - Données techniques' : 'TRANSFORMATEUR - Éléments vérifiés'),
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.bold, color: _currentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_currentSlide + 1}/$_totalSlides',
                style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        
        // Barre de progression
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacingL),
          child: LinearProgressIndicator(
            value: (_currentSlide + 1) / _totalSlides,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_currentColor),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Contenu
        Expanded(
          child: PageView.builder(
            controller: _slideController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentSlide = index),
            itemCount: _totalSlides,
            itemBuilder: (context, slideIndex) => _buildSectionContent(context, slideIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContent(BuildContext context, int slideIndex) {
    if (_currentSection == 0) {
      if (slideIndex == 0) {
        return _buildCelluleDonnees(context);
      } else {
        final elementSlideIndex = slideIndex - 1;
        if (elementSlideIndex < _celluleElementsSlides.length) {
          return _buildElementsSlide(
            context,
            elements: _celluleElementsSlides[elementSlideIndex],
            sectionType: 'cellule',
            color: _currentColor,
            baseIndex: 1000,
          );
        }
      }
    } else {
      if (slideIndex == 0) {
        return _buildTransfoDonnees(context);
      } else {
        final elementSlideIndex = slideIndex - 1;
        if (elementSlideIndex < _transfoElementsSlides.length) {
          return _buildElementsSlide(
            context,
            elements: _transfoElementsSlides[elementSlideIndex],
            sectionType: 'transformateur',
            color: _currentColor,
            baseIndex: 2000,
          );
        }
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildCelluleDonnees(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        Container(
          padding: EdgeInsets.all(context.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_currentColor, _currentColor.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(context.spacingL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: context.iconSizeM),
                  SizedBox(width: context.spacingS),
                  Flexible(
                    child: Text(
                      'Caractéristiques de la cellule',
                      style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              Text(
                'Renseignez toutes les informations techniques',
                style: TextStyle(fontSize: context.fontSizeS, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacingL),
        
        _buildModernInputField(
          context,
          controller: widget.celluleFonctionController,
          label: 'Fonction de la cellule *',
          icon: Icons.power,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.celluleTypeController,
          label: 'Type de cellule *',
          icon: Icons.category,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.celluleMarqueController,
          label: 'Marque / modèle / année *',
          icon: Icons.branding_watermark,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.celluleTensionController,
          label: 'Tension assignée *',
          icon: Icons.electrical_services,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.cellulePouvoirController,
          label: 'Pouvoir de coupure assigné (kA) *',
          icon: Icons.offline_bolt,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        
        // Dropdown pour Numérotation / repérage
        _buildModernDropdown(
          context,
          label: 'Numérotation / repérage *',
          value: widget.celluleNumerotationController.text,
          items: _presentAbsentOptions,
          icon: Icons.numbers,
          color: _currentColor,
          onChanged: (value) {
            setState(() {
              widget.celluleNumerotationController.text = value;
            });
          },
        ),
        
        // Dropdown pour Parafoudres installés sur l'arrivée
        _buildModernDropdown(
          context,
          label: 'Parafoudres installés sur l\'arrivée *',
          value: widget.celluleParafoudresController.text,
          items: _presentAbsentOptions,
          icon: Icons.shield,
          color: _currentColor,
          onChanged: (value) {
            setState(() {
              widget.celluleParafoudresController.text = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTransfoDonnees(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: [
        Container(
          padding: EdgeInsets.all(context.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_currentColor, _currentColor.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(context.spacingL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: context.iconSizeM),
                  SizedBox(width: context.spacingS),
                  Flexible(
                    child: Text(
                      'Caractéristiques du transformateur',
                      style: TextStyle(fontSize: context.fontSizeL, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              Text(
                'Renseignez toutes les informations techniques',
                style: TextStyle(fontSize: context.fontSizeS, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacingL),
        
        _buildModernInputField(
          context,
          controller: widget.transfoTypeController,
          label: 'Type de transformateur *',
          icon: Icons.transform,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoMarqueController,
          label: 'Marque/ Année de fabrication *',
          icon: Icons.branding_watermark,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoPuissanceController,
          label: 'Puissance assignée (kVA) *',
          icon: Icons.speed,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoTensionController,
          label: 'Tension primaire / secondaire *',
          icon: Icons.electrical_services,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoBuchholzController,
          label: 'Présence du relais Buchholz *',
          icon: Icons.sensors,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoRefroidissementController,
          label: 'Type de refroidissement *',
          icon: Icons.ac_unit,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
        _buildModernInputField(
          context,
          controller: widget.transfoRegimeController,
          label: 'Régime du neutre *',
          icon: Icons.settings_input_antenna,
          color: _currentColor,
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildModernInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onChanged,
  }) {
    final isValid = controller.text.trim().isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: isValid ? Colors.transparent : Colors.red.shade300, width: isValid ? 0 : 1.5),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: context.fontSizeS),
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeS),
          prefixIcon: Icon(icon, color: color, size: context.iconSizeS),
          suffixIcon: isValid 
              ? Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeS)
              : Icon(Icons.error_outline, color: Colors.red, size: context.iconSizeS),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.spacingM), borderSide: BorderSide(color: color, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
      ),
    );
  }

  Widget _buildModernDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Color color,
    required Function(String) onChanged,
  }) {
    final isValid = value.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: context.spacingS, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: isValid ? Colors.transparent : Colors.red.shade300, width: isValid ? 0 : 1.5),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value.isNotEmpty ? value : null,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down_circle, color: color, size: context.iconSizeM),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingM),
        hint: Text(
          'Sélectionnez...',
          style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: context.fontSizeS),
          prefixIcon: Icon(icon, color: color, size: context.iconSizeS),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingL, vertical: context.spacingM),
        ),
        style: TextStyle(fontSize: context.fontSizeS, color: AppTheme.darkBlue),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item == 'Présent' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: context.spacingS),
                Text(
                  item,
                  style: TextStyle(
                    color: item == 'Présent' ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((item) {
            return Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: item == 'Présent' ? Colors.green : Colors.red,
                  size: context.iconSizeS,
                ),
                SizedBox(width: context.spacingS),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      color: item == 'Présent' ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildElementsSlide(
    BuildContext context, {
    required List<ElementControle> elements,
    required String sectionType,
    required Color color,
    required int baseIndex,
  }) {
    return ListView(
      padding: EdgeInsets.all(context.spacingL),
      children: elements.map((element) {
        final originalIndex = sectionType == 'cellule'
            ? widget.celluleElements.indexOf(element)
            : widget.transfoElements.indexOf(element);
        final globalIndex = baseIndex + originalIndex;
        
        return _buildElementCardSimple(
          context,
          element: element,
          index: originalIndex,
          globalIndex: globalIndex,
          sectionType: sectionType,
          color: color,
        );
      }).toList(),
    );
  }

  Widget _buildElementCardSimple(
    BuildContext context, {
    required ElementControle element,
    required int index,
    required int globalIndex,
    required String sectionType,
    required Color color,
  }) {
    final hasObservation = widget.hasObservation[globalIndex] ?? false;
    final suggestions = widget.elementSuggestions[index] ?? [];
    final isConformiteNon = element.conforme == false;
    
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
          // En-tête avec numéro et titre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.iconSizeL,
                height: context.iconSizeL,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.spacingS),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              SizedBox(width: context.spacingS),
              Expanded(
                child: Text(
                  element.elementControle,
                  style: TextStyle(fontSize: context.fontSizeM, fontWeight: FontWeight.w600, color: AppTheme.darkBlue),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          
          SizedBox(height: context.spacingL),
          
          // Ligne 1 : Conformité (seule, sur toute la largeur)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Conformité *',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: element.conforme != null ? Colors.grey.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildConformiteButtonSimple(
                      context,
                      label: 'Oui',
                      isSelected: element.conforme == true,
                      color: Colors.green,
                      onTap: () {
                        setState(() {
                          element.conforme = true;
                          widget.onConformeChanged(element);
                          // Forcer l'observation à Non
                          widget.onObservationToggleChanged(globalIndex, false, sectionType);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: context.spacingS),
                  Expanded(
                    child: _buildConformiteButtonSimple(
                      context,
                      label: 'Non',
                      isSelected: element.conforme == false,
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          element.conforme = false;
                          widget.onConformeChanged(element);
                          // Forcer l'observation à Oui
                          widget.onObservationToggleChanged(globalIndex, true, sectionType);
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (element.conforme == null)
                Padding(
                  padding: EdgeInsets.only(top: context.spacingXS),
                  child: Text(
                    'Veuillez sélectionner Oui ou Non',
                    style: TextStyle(fontSize: context.fontSizeXS, color: Colors.red),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Ligne 2 : Priorité (seule, sur toute la largeur)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Priorité',
                    style: TextStyle(
                      fontSize: context.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacingS),
              _buildPrioriteSelectorSimple(context, element, color),
            ],
          ),
          
          SizedBox(height: context.spacingM),
          
          // Toggle Observation
          _buildObservationToggleSimple(
            context, globalIndex, hasObservation, color, sectionType, isConformiteNon,
          ),
          
          if (hasObservation) ...[
            SizedBox(height: context.spacingS),
            _buildObservationFieldSimple(
              context: context,
              element: element,
              index: index,
              sectionType: sectionType,
              suggestions: suggestions,
              color: color,
            ),
          ],
          
          SizedBox(height: context.spacingM),
          
          // Photos
          _buildElementPhotosSimple(
            context: context,
            element: element,
            index: index,
            sectionType: sectionType,
            color: color,
          ),
        ],
      ),
    );
  }

  // Toggle de conformité pour cellule/transformateur
  Widget _buildConformiteToggleSimple(
    BuildContext context,
    ElementControle element,
    Color color,
    int index,
    int globalIndex,
    String sectionType,
  ) {
    final isValid = widget.conformeSelected[element] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Conformité *',
              style: TextStyle(
                fontSize: context.fontSizeS,
                fontWeight: FontWeight.w600,
                color: isValid ? Colors.grey.shade700 : Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildConformiteButtonSimple(
                context,
                label: 'Oui',
                isSelected: element.conforme == true,
                color: Colors.green,
                onTap: () {
                  setState(() {
                    element.conforme = true;
                    widget.onConformeChanged(element);
                  });
                },
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildConformiteButtonSimple(
                context,
                label: 'Non',
                isSelected: element.conforme == false,
                color: Colors.red,
                onTap: () {
                  setState(() {
                    element.conforme = false;
                    widget.onConformeChanged(element);
                    // Forcer l'observation à Oui
                    widget.onObservationToggleChanged(globalIndex, true, sectionType);
                  });
                },
              ),
            ),
          ],
        ),
        if (element.conforme == null)
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

  Widget _buildConformiteButtonSimple(
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

  Widget _buildConformiteSelectorSimple(
    BuildContext context, 
    ElementControle element, 
    Color color, 
    bool isConformeSelected,
    int globalIndex,
    String sectionType,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(context.spacingS),
        border: Border.all(
          color: !isConformeSelected ? Colors.red.shade300 : Colors.transparent,
          width: !isConformeSelected ? 1.5 : 0,
        ),
      ),
      child: DropdownButtonFormField<bool?>(
        initialValue: isConformeSelected ? element.conforme : null,
        hint: Text('Sélectionnez *', style: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade500)),
        onChanged: (bool? newValue) {
          if (newValue != null) {
            setState(() {
              element.conforme = newValue;
              widget.onConformeChanged(element);
              
              if (newValue == false) {
                widget.onObservationToggleChanged(globalIndex, true, sectionType);
              } else {
                widget.onObservationToggleChanged(globalIndex, false, sectionType);
              }
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Conformité *',
          labelStyle: TextStyle(fontSize: context.fontSizeS, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
        ),
        items: [
          DropdownMenuItem(
            value: true,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Oui', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: context.iconSizeXS),
                SizedBox(width: context.spacingS),
                Flexible(child: Text('Non', style: TextStyle(fontSize: context.fontSizeS))),
              ],
            ),
          ),
        ],
        isExpanded: true,
      ),
    );
  }

  Widget _buildPrioriteSelectorSimple(BuildContext context, ElementControle element, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.spacingS),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPrioriteButtonSimple(
              context,
              label: 'N1',
              tooltip: 'Basse priorité',
              isSelected: element.priorite == 1,
              color: Colors.blue,
              onTap: () => setState(() => element.priorite = 1),
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButtonSimple(
              context,
              label: 'N2',
              tooltip: 'Moyenne priorité',
              isSelected: element.priorite == 2,
              color: Colors.orange,
              onTap: () => setState(() => element.priorite = 2),
            ),
          ),
          SizedBox(width: context.spacingXS),
          Expanded(
            child: _buildPrioriteButtonSimple(
              context,
              label: 'N3',
              tooltip: 'Haute priorité',
              isSelected: element.priorite == 3,
              color: Colors.red,
              onTap: () => setState(() => element.priorite = 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioriteButtonSimple(
    BuildContext context, {
    required String label,
    required String tooltip,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.flag : Icons.flag_outlined,
                size: context.iconSizeS,
                color: isSelected ? color : Colors.grey.shade500,
              ),
              SizedBox(height: context.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObservationToggleSimple(
    BuildContext context,
    int globalIndex,
    bool hasObservation,
    Color color,
    String sectionType,
    bool isConformiteNon, // ← NOUVEAU
  ) {
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
          onTap: () => widget.onObservationToggleChanged(globalIndex, true, sectionType),
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
          onTap: isConformiteNon 
              ? null 
              : () => widget.onObservationToggleChanged(globalIndex, false, sectionType),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingXS),
            decoration: BoxDecoration(
              color: !hasObservation && !isConformiteNon ? Colors.red.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(context.spacingL),
              border: Border.all(
                color: !hasObservation && !isConformiteNon ? Colors.red : Colors.grey.shade300,
                width: !hasObservation && !isConformiteNon ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Non',
                  style: TextStyle(
                    fontSize: context.fontSizeXS,
                    fontWeight: FontWeight.w600,
                    color: isConformiteNon
                        ? Colors.grey.shade400
                        : (!hasObservation ? Colors.red : Colors.grey.shade600),
                  ),
                ),
                if (isConformiteNon)
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.lock_outline,
                      size: context.fontSizeXS,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObservationFieldSimple({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required String sectionType,
    required List<String> suggestions,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(
              color: element.observation == null || element.observation!.trim().isEmpty ? Colors.red.shade300 : Colors.transparent,
              width: element.observation == null || element.observation!.trim().isEmpty ? 1.5 : 0,
            ),
          ),
          child: TextFormField(
            initialValue: element.observation,
            style: TextStyle(fontSize: context.fontSizeS),
            onChanged: (value) {
              element.observation = value;
              widget.onObservationChanged(index, value, sectionType);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Saisissez votre observation... *',
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
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(context.spacingS),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions',
                  style: TextStyle(fontSize: context.fontSizeXS, fontWeight: FontWeight.bold, color: color),
                ),
                SizedBox(height: context.spacingXS),
                Wrap(
                  spacing: context.spacingS,
                  runSpacing: context.spacingXS,
                  children: suggestions.map((s) => GestureDetector(
                    onTap: () => widget.onUseSuggestion(index, s, element, sectionType),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.spacingS, vertical: context.spacingXS),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.spacingL),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(fontSize: context.fontSizeXS, color: color.withOpacity(0.7)),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildElementPhotosSimple({
    required BuildContext context,
    required ElementControle element,
    required int index,
    required String sectionType,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, size: context.iconSizeXS, color: color),
            SizedBox(width: context.spacingS),
            Flexible(
              child: Text(
                'Photos (${element.photos.length})',
                style: TextStyle(fontSize: context.fontSizeS, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacingS),
        
        if (element.photos.isNotEmpty)
          Container(
            height: context.screenHeight * 0.1,
            margin: EdgeInsets.only(bottom: context.spacingS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: element.photos.length,
              itemBuilder: (context, photoIndex) {
                return Stack(
                  children: [
                    Container(
                      width: context.screenWidth * 0.2,
                      margin: EdgeInsets.only(right: context.spacingS),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.spacingS)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.spacingS),
                        child: Image.file(File(element.photos[photoIndex]), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: context.spacingXS,
                      right: context.spacingS + context.spacingXS,
                      child: GestureDetector(
                        onTap: () => widget.onSupprimerPhotoElement(element, index, photoIndex, sectionType),
                        child: Container(
                          padding: EdgeInsets.all(context.spacingXS),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: context.iconSizeXS - 2, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: _buildSmallIconButtonSimple(
                context,
                icon: Icons.camera_alt,
                label: 'Prendre',
                onTap: () => widget.onPrendrePhotoElement(element, index, sectionType),
                color: color,
              ),
            ),
            SizedBox(width: context.spacingS),
            Expanded(
              child: _buildSmallIconButtonSimple(
                context,
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => widget.onChoisirPhotoElement(element, index, sectionType),
                color: color,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconButtonSimple(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
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
            color: isSecondary ? Colors.grey.shade100 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(context.spacingS),
            border: Border.all(color: isSecondary ? Colors.grey.shade300 : color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.iconSizeXS, color: isSecondary ? Colors.grey.shade700 : color),
              SizedBox(width: context.spacingXS),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: context.fontSizeXS - 1, fontWeight: FontWeight.w600, color: isSecondary ? Colors.grey.shade700 : color),
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
// WIDGET PRINCIPAL : AjouterLocalScreen
// ================================================================

class AjouterLocalScreen extends StatefulWidget {
  final Mission mission;
  final bool isMoyenneTension;
  final dynamic local;
  final int? localIndex;
  final int? zoneIndex;
  final bool isInZone;
  final String? draftId;
  
  const AjouterLocalScreen({
    super.key,
    required this.mission,
    required this.isMoyenneTension,
    this.local,
    this.localIndex,
    this.zoneIndex,
    this.isInZone = false,
    this.draftId,
  });

  bool get isEdition => local != null;

  @override
  State<AjouterLocalScreen> createState() => _AjouterLocalScreenState();
}

class _AjouterLocalScreenState extends State<AjouterLocalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  String? _selectedType;
  List<ElementControle> _dispositionsConstructives = [];
  List<ElementControle> _conditionsExploitation = [];
  
  final ImagePicker _picker = ImagePicker();
  
  List<String> _localPhotos = [];
  bool _isLoadingPhotos = false;
  
  final _observationController = TextEditingController();
  final List<String> _observationPhotos = [];
  final List<ObservationLibre> _observationsExistantes = [];

  final _celluleFonctionController = TextEditingController();
  final _celluleTypeController = TextEditingController();
  final _celluleMarqueController = TextEditingController();
  final _celluleTensionController = TextEditingController();
  final _cellulePouvoirController = TextEditingController();
  final _celluleNumerotationController = TextEditingController();
  final _celluleParafoudresController = TextEditingController();
  List<ElementControle> _celluleElements = [];

  final _transfoTypeController = TextEditingController();
  final _transfoMarqueController = TextEditingController();
  final _transfoPuissanceController = TextEditingController();
  final _transfoTensionController = TextEditingController();
  final _transfoBuchholzController = TextEditingController();
  final _transfoRefroidissementController = TextEditingController();
  final _transfoRegimeController = TextEditingController();
  List<ElementControle> _transfoElements = [];

  static const String _baseUrl = "http://192.168.0.217:8000";
  Map<int, List<String>> _elementSuggestions = {};
  Map<int, bool> _elementLoading = {};
  Map<int, Timer?> _elementDebounceTimers = {};
  
  Map<String, TextEditingController> _observationControllers = {};

  bool _nomValid = false;
  bool _typeValid = false;
  bool _localPhotosValid = true;
  bool _observationsValid = true;
  bool _dispositionsValid = false;
  bool _conditionsValid = false;
  bool _celluleDonneesValid = true;
  bool _transfoDonneesValid = true;
  bool _celluleElementsValid = true;
  bool _transfoElementsValid = true;
  
  bool _addObservation = false;
  final Map<int, bool> _hasObservation = {};
  
  final Map<ElementControle, bool> _conformeSelected = {};

  final PageController _mainPageController = PageController();
  int _currentStep = 0;
  
  GlobalKey<_EtapeElementsControleState>? _etapeElementsKey;
  GlobalKey<_EtapeCelluleTransformateurState>? _etapeCelluleTransfoKey;

  bool _isLoading = false;

  String? _draftLocalId;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _etapeElementsKey = GlobalKey<_EtapeElementsControleState>();
    _etapeCelluleTransfoKey = GlobalKey<_EtapeCelluleTransformateurState>();

    // Générer un ID pour le brouillon
    _draftLocalId = widget.draftId ?? 
      (widget.isEdition && widget.local != null 
          ? 'EDIT_${widget.local.hashCode}' 
          : 'TEMP_${DateTime.now().millisecondsSinceEpoch}');
    
    if (widget.isEdition) {
      _chargerDonneesExistantes();
      _nomValid = true;
      _typeValid = true;
      _localPhotosValid = true;
      _dispositionsValid = _validateElements(_dispositionsConstructives);
      _conditionsValid = _validateElements(_conditionsExploitation);
      if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
        _celluleDonneesValid = _validateCelluleDonnees();
        _transfoDonneesValid = _validateTransfoDonnees();
        _celluleElementsValid = _validateElements(_celluleElements);
        _transfoElementsValid = _validateElements(_transfoElements);
      }
    } else {
      _initializeElementsControle();

      if (widget.draftId != null) {
        _loadDraft();
      }
    }
  }

  Future<void> _loadDraft() async {
    final draftData = HiveService.getLocalDraftData(_draftLocalId!);
    if (draftData == null) return;
    
    final local = draftData['local'];
    final savedStep = draftData['currentStep'] as int? ?? 0;
    
    setState(() {
      // Informations de base
      _nomController.text = local.nom ?? '';
      _selectedType = local.type;
      
      // Si le type est le type par défaut (utilisé quand pas encore sélectionné)
      // on ne le considère pas comme valide
      if (_selectedType == 'LOCAL_ELECTRIQUE' && local.nom == 'Sans nom') {
        _typeValid = false;
      } else {
        _typeValid = true;
      }
      
      _nomValid = (local.nom != null && local.nom!.isNotEmpty && local.nom != 'Sans nom');
      
      // Dispositions et conditions
      _dispositionsConstructives = List.from(local.dispositionsConstructives ?? []);
      _conditionsExploitation = List.from(local.conditionsExploitation ?? []);
      
      // Observations
      _observationsExistantes.clear();
      if (local.observationsLibres != null) {
        _observationsExistantes.addAll(local.observationsLibres);
      }
      
      // Photos
      _localPhotos.clear();
      if (local.photos != null && local.photos.isNotEmpty) {
        _localPhotos = List.from(local.photos);
      }
      _localPhotosValid = true;
      
      // Cellule et Transformateur (si local MT et type TRANSFORMATEUR)
      if (local is MoyenneTensionLocal && local.type == 'LOCAL_TRANSFORMATEUR') {
        if (local.cellule != null) {
          _celluleFonctionController.text = local.cellule!.fonction ?? '';
          _celluleTypeController.text = local.cellule!.type ?? '';
          _celluleMarqueController.text = local.cellule!.marqueModeleAnnee ?? '';
          _celluleTensionController.text = local.cellule!.tensionAssignee ?? '';
          _cellulePouvoirController.text = local.cellule!.pouvoirCoupure ?? '';
          _celluleNumerotationController.text = local.cellule!.numerotation ?? '';
          _celluleParafoudresController.text = local.cellule!.parafoudres ?? '';
          _celluleElements = List.from(local.cellule!.elementsVerifies ?? []);
        }
        if (local.transformateur != null) {
          _transfoTypeController.text = local.transformateur!.typeTransformateur ?? '';
          _transfoMarqueController.text = local.transformateur!.marqueAnnee ?? '';
          _transfoPuissanceController.text = local.transformateur!.puissanceAssignee ?? '';
          _transfoTensionController.text = local.transformateur!.tensionPrimaireSecondaire ?? '';
          _transfoBuchholzController.text = local.transformateur!.relaisBuchholz ?? '';
          _transfoRefroidissementController.text = local.transformateur!.typeRefroidissement ?? '';
          _transfoRegimeController.text = local.transformateur!.regimeNeutre ?? '';
          _transfoElements = List.from(local.transformateur!.elementsVerifies ?? []);
        }
      } else {
        // Réinitialiser les contrôleurs cellule/transfo
        _celluleFonctionController.clear();
        _celluleTypeController.clear();
        _celluleMarqueController.clear();
        _celluleTensionController.clear();
        _cellulePouvoirController.clear();
        _celluleNumerotationController.clear();
        _celluleParafoudresController.clear();
        _celluleElements.clear();
        
        _transfoTypeController.clear();
        _transfoMarqueController.clear();
        _transfoPuissanceController.clear();
        _transfoTensionController.clear();
        _transfoBuchholzController.clear();
        _transfoRefroidissementController.clear();
        _transfoRegimeController.clear();
        _transfoElements.clear();
      }
      
      // Étape courante
      _currentStep = savedStep;
      
      // Reconstruire conformeSelected
      _conformeSelected.clear();
      for (var element in _dispositionsConstructives) {
        _conformeSelected[element] = element.conforme != null;
      }
      for (var element in _conditionsExploitation) {
        _conformeSelected[element] = element.conforme != null;
      }
      for (var element in _celluleElements) {
        _conformeSelected[element] = element.conforme != null;
      }
      for (var element in _transfoElements) {
        _conformeSelected[element] = element.conforme != null;
      }
      
      // Reconstruire hasObservation
      _hasObservation.clear();
      for (int i = 0; i < _dispositionsConstructives.length; i++) {
        final obs = _dispositionsConstructives[i].observation;
        _hasObservation[i] = obs != null && obs.isNotEmpty;
        // Si conformité = false, forcer hasObservation = true
        if (_dispositionsConstructives[i].conforme == false) {
          _hasObservation[i] = true;
        }
      }
      for (int i = 0; i < _conditionsExploitation.length; i++) {
        final globalIndex = _dispositionsConstructives.length + i;
        final obs = _conditionsExploitation[i].observation;
        _hasObservation[globalIndex] = obs != null && obs.isNotEmpty;
        if (_conditionsExploitation[i].conforme == false) {
          _hasObservation[globalIndex] = true;
        }
      }
      
      // Validation des éléments
      _dispositionsValid = _validateElements(_dispositionsConstructives);
      _conditionsValid = _validateElements(_conditionsExploitation);
      if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
        _celluleDonneesValid = _validateCelluleDonnees();
        _transfoDonneesValid = _validateTransfoDonnees();
        _celluleElementsValid = _validateElements(_celluleElements);
        _transfoElementsValid = _validateElements(_transfoElements);
      }
      
      // Initialiser les suggestions
      _elementSuggestions.clear();
      _elementLoading.clear();
      
      // Positionner le PageController
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mainPageController.hasClients) {
          _mainPageController.jumpToPage(_currentStep);
        }
        // Si on est à l'étape 1, reconstruire les slides
        if (_currentStep == 1) {
          _etapeElementsKey?.currentState?.rebuildSlides();
        }
      });
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    
    final nom = _nomController.text.trim();
    if (nom.isEmpty && _selectedType == null) {
      return; //
    }
    final typeToSave = _selectedType ?? 'LOCAL_ELECTRIQUE'; // Type par défaut
    
    dynamic local;
    if (widget.isMoyenneTension) {
      local = _creerMoyenneTensionLocalAvecType(typeToSave);
    } else {
      local = _creerBasseTensionLocalAvecType(typeToSave);
    }
    
    await HiveService.saveLocalDraft(
      missionId: widget.mission.id,
      isMoyenneTension: widget.isMoyenneTension,
      zoneIndex: widget.zoneIndex,
      isInZone: widget.isInZone,
      local: local,
      currentStep: _currentStep,
      localId: _draftLocalId,
    );
    
    _hasUnsavedChanges = false;
  }

  // Créer un local MT avec un type spécifié
  MoyenneTensionLocal _creerMoyenneTensionLocalAvecType(String type) {
    return MoyenneTensionLocal(
      nom: _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim(),
      type: type,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      cellule: type == 'LOCAL_TRANSFORMATEUR' ? Cellule(
        fonction: _celluleFonctionController.text.trim(),
        type: _celluleTypeController.text.trim(),
        marqueModeleAnnee: _celluleMarqueController.text.trim(),
        tensionAssignee: _celluleTensionController.text.trim(),
        pouvoirCoupure: _cellulePouvoirController.text.trim(),
        numerotation: _celluleNumerotationController.text,
        parafoudres: _celluleParafoudresController.text,
        elementsVerifies: _celluleElements,
      ) : null,
      transformateur: type == 'LOCAL_TRANSFORMATEUR' ? TransformateurMTBT(
        typeTransformateur: _transfoTypeController.text.trim(),
        marqueAnnee: _transfoMarqueController.text.trim(),
        puissanceAssignee: _transfoPuissanceController.text.trim(),
        tensionPrimaireSecondaire: _transfoTensionController.text.trim(),
        relaisBuchholz: _transfoBuchholzController.text.trim(),
        typeRefroidissement: _transfoRefroidissementController.text.trim(),
        regimeNeutre: _transfoRegimeController.text.trim(),
        elementsVerifies: _transfoElements,
      ) : null,
      observationsLibres: _observationsExistantes,
      photos: _localPhotos,
    );
  }

  // Créer un local BT avec un type spécifié
  BasseTensionLocal _creerBasseTensionLocalAvecType(String type) {
    return BasseTensionLocal(
      nom: _nomController.text.trim().isEmpty ? 'Sans nom' : _nomController.text.trim(),
      type: type,
      dispositionsConstructives: _dispositionsConstructives,
      conditionsExploitation: _conditionsExploitation,
      observationsLibres: _observationsExistantes,
      photos: _localPhotos,
    );
  }

  void _chargerDonneesExistantes() {
    final local = widget.local!;
    _nomController.text = local.nom;
    _selectedType = local.type;
    _dispositionsConstructives = List.from(local.dispositionsConstructives);
    _conditionsExploitation = List.from(local.conditionsExploitation);
    _observationsExistantes.addAll(local.observationsLibres);
    if (local.photos.isNotEmpty) _localPhotos = List.from(local.photos);
    if (local is MoyenneTensionLocal && local.type == 'LOCAL_TRANSFORMATEUR') {
      if (local.cellule != null) {
        _celluleFonctionController.text = local.cellule!.fonction;
        _celluleTypeController.text = local.cellule!.type;
        _celluleMarqueController.text = local.cellule!.marqueModeleAnnee;
        _celluleTensionController.text = local.cellule!.tensionAssignee;
        _cellulePouvoirController.text = local.cellule!.pouvoirCoupure;
        _celluleNumerotationController.text = local.cellule!.numerotation;
        _celluleParafoudresController.text = local.cellule!.parafoudres;
        _celluleElements = List.from(local.cellule!.elementsVerifies);
      }
      if (local.transformateur != null) {
        _transfoTypeController.text = local.transformateur!.typeTransformateur;
        _transfoMarqueController.text = local.transformateur!.marqueAnnee;
        _transfoPuissanceController.text = local.transformateur!.puissanceAssignee;
        _transfoTensionController.text = local.transformateur!.tensionPrimaireSecondaire;
        _transfoBuchholzController.text = local.transformateur!.relaisBuchholz;
        _transfoRefroidissementController.text = local.transformateur!.typeRefroidissement;
        _transfoRegimeController.text = local.transformateur!.regimeNeutre;
        _transfoElements = List.from(local.transformateur!.elementsVerifies);
      }
    }
    
    for (var element in _dispositionsConstructives) {
      _conformeSelected[element] = true;
    }
    for (var element in _conditionsExploitation) {
      _conformeSelected[element] = true;
    }
    for (var element in _celluleElements) {
      _conformeSelected[element] = true;
    }
    for (var element in _transfoElements) {
      _conformeSelected[element] = true;
    }
    
    for (int i = 0; i < _dispositionsConstructives.length; i++) {
      _hasObservation[i] = _dispositionsConstructives[i].observation?.isNotEmpty == true;
    }
    for (int i = 0; i < _conditionsExploitation.length; i++) {
      _hasObservation[_dispositionsConstructives.length + i] = _conditionsExploitation[i].observation?.isNotEmpty == true;
    }
  }

  void _initializeElementsControle() {
    _dispositionsConstructives = [];
    _conditionsExploitation = [];
    _celluleElements = [];
    _transfoElements = [];
    _hasObservation.clear();
    _conformeSelected.clear();
  }

  void _validateNom(String value) {
    setState(() => _nomValid = value.trim().isNotEmpty);
    _scheduleAutoSave();
  }
  void _onTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      _validateType(newType);
      if (!widget.isEdition) _initializeElementsForType(newType);
    });
    _scheduleAutoSave();
  }

  void _onConformeChanged(ElementControle element) {
    setState(() {
      _conformeSelected[element] = true;
      element.priorite ??= 3;
      
      int? elementIndex;
      for (int i = 0; i < _dispositionsConstructives.length; i++) {
        if (_dispositionsConstructives[i] == element) {
          elementIndex = i;
          break;
        }
      }
      if (elementIndex == null) {
        for (int i = 0; i < _conditionsExploitation.length; i++) {
          if (_conditionsExploitation[i] == element) {
            elementIndex = _dispositionsConstructives.length + i;
            break;
          }
        }
      }
      if (element.conforme == false && elementIndex != null) {
        _hasObservation[elementIndex] = true;
      }
    });
    _scheduleAutoSave();
  }

  void _validateType(String? value) => setState(() => _typeValid = value != null && value.isNotEmpty);
  void _validateLocalPhotos() => setState(() => _localPhotosValid = true);

  void _validateObservations() {
    bool isValid = true;
    if (!widget.isEdition && _addObservation) {
      if (_observationController.text.trim().isEmpty && _observationsExistantes.isEmpty) isValid = false;
    }
    setState(() => _observationsValid = isValid);
  }

  bool _validateElements(List<ElementControle> elements) {
    if (elements.isEmpty) return false;
    for (var element in elements) {
      if (!(_conformeSelected[element] ?? false)) return false;
      if (element.priorite == null) return false;
    }
    return true;
  }

  bool _validateCelluleDonnees() {
    return _celluleFonctionController.text.trim().isNotEmpty &&
           _celluleTypeController.text.trim().isNotEmpty &&
           _celluleMarqueController.text.trim().isNotEmpty &&
           _celluleTensionController.text.trim().isNotEmpty &&
           _cellulePouvoirController.text.trim().isNotEmpty &&
           _celluleNumerotationController.text.isNotEmpty &&
           _celluleParafoudresController.text.isNotEmpty;
  }

  bool _validateTransfoDonnees() {
    return _transfoTypeController.text.trim().isNotEmpty &&
           _transfoMarqueController.text.trim().isNotEmpty &&
           _transfoPuissanceController.text.trim().isNotEmpty &&
           _transfoTensionController.text.trim().isNotEmpty &&
           _transfoBuchholzController.text.trim().isNotEmpty &&
           _transfoRefroidissementController.text.trim().isNotEmpty &&
           _transfoRegimeController.text.trim().isNotEmpty;
  }

  bool _canProceedToNextStep() {
    if (_currentStep == 0) return _nomValid && _typeValid && (!_addObservation || _observationsValid);
    return true;
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_canProceedToNextStep()) {
        _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showError('Veuillez remplir tous les champs obligatoires');
      }
    } else if (_currentStep == 1) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null) {
        if (elementsState.canGoNext()) {
          if (_selectedType == 'LOCAL_TRANSFORMATEUR') {
            _mainPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          } else {
            _sauvegarder();
          }
        } else {
          elementsState.nextSlide();
        }
      }
    } else if (_currentStep == 2) {
      final celluleTransfoState = _etapeCelluleTransfoKey?.currentState;
      if (celluleTransfoState != null) {
        if (celluleTransfoState.canGoNext()) {
          _sauvegarder();
        } else {
          celluleTransfoState.nextSlide();
        }
      }
    }
  }

  void _handlePrevious() {
    if (_currentStep == 1) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null) {
        if (elementsState.canGoPrevious()) {
          _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          elementsState.previousSlide();
        }
      }
    } else if (_currentStep == 2) {
      final celluleTransfoState = _etapeCelluleTransfoKey?.currentState;
      if (celluleTransfoState != null) {
        if (celluleTransfoState.canGoPrevious()) {
          _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        } else {
          celluleTransfoState.previousSlide();
        }
      }
    } else if (_currentStep > 0) {
      _mainPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _getNextButtonText() {
    if (_currentStep == 0) return 'Suivant';
    if (_currentStep == 1) {
      final elementsState = _etapeElementsKey?.currentState;
      if (elementsState != null && elementsState.canGoNext()) {
        return _selectedType == 'LOCAL_TRANSFORMATEUR' ? 'Suivant' : 'Terminer';
      }
      return 'Suivant';
    }
    if (_currentStep == 2) {
      final celluleTransfoState = _etapeCelluleTransfoKey?.currentState;
      if (celluleTransfoState != null && celluleTransfoState.canGoNext()) return 'Terminer';
      return 'Suivant';
    }
    return 'Suivant';
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _elementDebounceTimers.forEach((key, timer) => timer?.cancel());
    _observationControllers.forEach((key, controller) => controller.dispose());
    _nomController.dispose();
    _observationController.dispose();
    _celluleFonctionController.dispose();
    _celluleTypeController.dispose();
    _celluleMarqueController.dispose();
    _celluleTensionController.dispose();
    _cellulePouvoirController.dispose();
    _celluleNumerotationController.dispose();
    _celluleParafoudresController.dispose();
    _transfoTypeController.dispose();
    _transfoMarqueController.dispose();
    _transfoPuissanceController.dispose();
    _transfoTensionController.dispose();
    _transfoBuchholzController.dispose();
    _transfoRefroidissementController.dispose();
    _transfoRegimeController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  void _onElementObservationChanged(int elementIndex, String text, String sectionType) {
    _elementDebounceTimers[elementIndex]?.cancel();
    if (text.length >= 3) {
      _elementDebounceTimers[elementIndex] = Timer(const Duration(milliseconds: 500), () async {
        await _getElementSuggestions(elementIndex, text, sectionType);
      });
    } else {
      setState(() => _elementSuggestions[elementIndex]?.clear());
    }
  }

  Future<void> _getElementSuggestions(int elementIndex, String query, String sectionType) async {
    if (query.length < 3) return;
    final body = <String, dynamic>{'query': query, 'max_results': 5};
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/autocomplete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _elementSuggestions[elementIndex] = List<String>.from(data['suggestions'] ?? []));
      }
    } catch (e) {
      print('Erreur suggestions pour élément $elementIndex: $e');
    }
  }

  void _useElementSuggestion(int elementIndex, String suggestion, ElementControle element, String sectionType) {
    final observationKey = '$sectionType-$elementIndex';
    element.observation = suggestion;
    if (_observationControllers.containsKey(observationKey)) {
      _observationControllers[observationKey]!.text = suggestion;
    }
    setState(() => _elementSuggestions[elementIndex]?.clear());
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _prendrePhotoLocal() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _choisirPhotoLocalDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        setState(() => _isLoadingPhotos = true);
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'locaux');
        setState(() {
          _localPhotos.add(savedPath);
          _validateLocalPhotos();
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    } finally {
      setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _prendrePhotoObservation() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoObservationDepuisGalerie() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'observations');
        setState(() => _observationPhotos.add(savedPath));
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
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

  void _previsualiserPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(photos[index]), fit: BoxFit.contain)),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _supprimerPhoto(photos, index);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerPhoto(List<String> photos, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                photos.removeAt(index);
                _validateLocalPhotos();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _ajouterObservation() {
    final texte = _observationController.text.trim();
    if (texte.isEmpty) {
      _showError('Veuillez saisir une observation');
      return;
    }
    setState(() {
      _observationsExistantes.add(ObservationLibre(texte: texte, photos: List.from(_observationPhotos)));
      _observationController.clear();
      _observationPhotos.clear();
      _addObservation = false;
      _validateObservations();
    });
  }

  void _supprimerObservationExistante(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'observation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette observation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _observationsExistantes.removeAt(index);
                _validateObservations();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _initializeElementsForType(String? type) {
    if (type == null) return;
    final dispositions = HiveService.getDispositionsConstructivesForLocal(type);
    _dispositionsConstructives = dispositions.map((element) {
      final ec = ElementControle(elementControle: element, conforme: null, priorite: 3);
      _conformeSelected[ec] = false;
      return ec;
    }).toList();
    final conditions = HiveService.getConditionsExploitationForLocal(type);
    _conditionsExploitation = conditions.map((element) {
      final ec = ElementControle(elementControle: element, conforme: null, priorite: 3);
      _conformeSelected[ec] = false;
      return ec;
    }).toList();
    for (int i = 0; i < _dispositionsConstructives.length; i++) {
      _hasObservation[i] = false;
    }
    for (int i = 0; i < _conditionsExploitation.length; i++) {
      _hasObservation[_dispositionsConstructives.length + i] = false;
    }
    if (type == 'LOCAL_TRANSFORMATEUR') {
      final celluleElements = ['Schéma unifilaire affiché dans le local', 'Cellule correctement posée et fixée', 'Jonctions inter-cellules', 'Canalisations et câbles d\'arrivée / départ', 'Respect des distances de sécurité', 'Commande manuelle / motorisée', 'Voyants de position (O / F / T)', 'Verrouillage mécanique', 'Terre de protection (PE) reliée à chaque cellule'];
      _celluleElements = celluleElements.map((element) {
        final ec = ElementControle(elementControle: element, conforme: false, priorite: 3);
        _conformeSelected[ec] = false;
        return ec;
      }).toList();
      final transfoElements = ['Adapté au local et à la ventilation', 'Plaque signalétique (puissance, tension, couplage)', 'Mise à la terre du neutre et de la carcasse', 'Raccordement des câbles MT et BT', 'Protection contre les contacts directs', 'Bac de rétention (pour transfo à huile)', 'Protection contre les surintensités', 'Essais diélectriques', 'Distance entre transformateur', 'Protection MT', 'Protection BT (disjoncteur général, fusibles, relais thermique)', 'Écran de câble MT relié à la terre'];
      _transfoElements = transfoElements.map((element) {
        final ec = ElementControle(elementControle: element, conforme: false, priorite: 3);
        _conformeSelected[ec] = false;
        return ec;
      }).toList();
    }
  }

  void _onAjouterAutre(String sectionType) async {
    final result = await showDialog<ElementControle>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Ajouter un élément "Autre"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saisissez la description de l\'élément à ajouter :',
                style: TextStyle(fontSize: context.fontSizeM),
              ),
              SizedBox(height: context.spacingM),
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ex: Présence de rongeurs...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final texte = controller.text.trim();
                if (texte.isNotEmpty) {
                  final nouvelElement = ElementControle(
                    elementControle: texte,
                    conforme: false,
                    priorite: 3,
                  );
                  Navigator.pop(context, nouvelElement);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _conformeSelected[result] = false;
        
        if (sectionType == 'dispositions') {
          _dispositionsConstructives.add(result);
          _hasObservation[_dispositionsConstructives.length - 1] = false;
        } else {
          _conditionsExploitation.add(result);
          _hasObservation[_dispositionsConstructives.length + _conditionsExploitation.length - 1] = false;
        }
      });
      
      // Reconstruire les slides dans l'étape éléments
      _etapeElementsKey?.currentState?.rebuildSlides();
      // Aller au dernier slide pour voir le nouvel élément
      _etapeElementsKey?.currentState?.goToLastSlide();
    }
  }

  Future<void> _prendrePhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() => element.photos.add(savedPath));
        await HiveService.addPhotoToElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, cheminPhoto: savedPath, sectionType: sectionType);
      }
    } catch (e) {
      _showError('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _choisirPhotoPourElement(ElementControle element, int elementIndex, String sectionType) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      if (photo != null) {
        final savedPath = await _savePhotoToAppDirectory(File(photo.path), 'element_photos');
        setState(() => element.photos.add(savedPath));
        await HiveService.addPhotoToElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, cheminPhoto: savedPath, sectionType: sectionType);
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _supprimerPhotoElement(ElementControle element, int elementIndex, int photoIndex, String sectionType) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => element.photos.removeAt(photoIndex));
              await HiveService.removePhotoFromElementControle(missionId: widget.mission.id, localisation: _nomController.text.trim(), elementIndex: elementIndex, photoIndex: photoIndex, sectionType: sectionType);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _sauvegarder() async {
    if (!_nomValid || !_typeValid) {
      _showError('Veuillez remplir tous les champs obligatoires');
      _mainPageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      dynamic nouveauLocal;

      if (widget.isMoyenneTension) {
        if (widget.isInZone && widget.zoneIndex != null) {
          if (widget.isEdition && widget.localIndex != null) {
            await HiveService.updateLocalInMoyenneTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, 
              localIndex: widget.localIndex!, local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          } else {
            await HiveService.addLocalToMoyenneTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, 
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          }
        } else {
          if (widget.isEdition && widget.localIndex != null) {
            await HiveService.updateMoyenneTensionLocal(
              missionId: widget.mission.id, localIndex: widget.localIndex!, 
              local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          } else {
            await HiveService.addMoyenneTensionLocal(
              missionId: widget.mission.id, local: _creerMoyenneTensionLocal(),
            );
            nouveauLocal = _creerMoyenneTensionLocal();
          }
        }
      } else {
        if (widget.zoneIndex != null) {
          if (widget.isEdition && widget.localIndex != null) {
            await HiveService.updateBasseTensionLocal(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, 
              localIndex: widget.localIndex!, local: _creerBasseTensionLocal(),
            );
            nouveauLocal = _creerBasseTensionLocal();
          } else {
            await HiveService.addLocalToBasseTensionZone(
              missionId: widget.mission.id, zoneIndex: widget.zoneIndex!, 
              local: _creerBasseTensionLocal(),
            );
            nouveauLocal = _creerBasseTensionLocal();
          }
        } else {
          _showError('Erreur: pour basse tension, un local doit être dans une zone');
          setState(() => _isLoading = false);
          return;
        }
      }
      
      // SUPPRIMER LE BROUILLON APRÈS SAUVEGARDE RÉUSSIE
      await HiveService.deleteLocalDraft(_draftLocalId!);
      
      setState(() => _isLoading = false);
      
      if (widget.isEdition) {
        Navigator.pop(context, true);
      } else {
        await _allerAuClassement(nouveauLocal);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erreur sauvegarde: $e');
      _showError('Erreur lors de la sauvegarde: $e');
    }
  }


  Future<void> _allerAuClassement(dynamic local) async {
    if (local == null) {
      _showError('Erreur: impossible de créer le classement pour ce local');
      Navigator.pop(context, true);
      return;
    }
    
    final bool estDansUneZone = widget.isInZone && widget.zoneIndex != null;
    
    if (estDansUneZone) {
      final choix = await _showChoixClassementDialog(local);
      
      if (choix == null) {
        return;
      }
      
      if (choix == 'heriter') {
        // Récupérer le ClassementZone complet
        final zoneClassement = await _getZoneParenteClassement();
        
        if (zoneClassement != null) {
          // Vérifier que la zone a bien un classement complet
          if (!zoneClassement.estComplet) {
            _showSnackBar(
              'La zone parente n\'a pas encore de classement complet. '
              'Veuillez d\'abord classer la zone, ou choisir un classement spécifique.',
              Colors.orange,
            );
            // Proposer de définir un classement spécifique à la place
            final choix2 = await _showChoixClassementDialog(local, zoneNonClassee: true);
            if (choix2 == 'specifique') {
              // Continuer vers classement spécifique
            } else {
              return;
            }
          } else {
            // Créer un classement qui hérite en COPIANT les valeurs
            final classement = ClassementEmplacement.createLocalHeritant(
              missionId: widget.mission.id,
              nomLocal: local.nom,
              zoneParente: zoneClassement.nomZone,
              zoneClassement: zoneClassement, // ← Passer l'objet complet
            );
            
            // Ajouter à la box
            final classementBox = Hive.box<ClassementEmplacement>('classement_locaux');
            await classementBox.add(classement);
            
            _showSnackBar('Classement hérité avec succès', Colors.green);
            Navigator.pop(context, true);
            return;
          }
        } else {
          _showSnackBar(
            'La zone parente n\'a pas encore de classement. '
            'Veuillez définir un classement spécifique.',
            Colors.orange,
          );
          // Continuer vers classement spécifique
        }
      }
      
      // Si on arrive ici, c'est qu'on va en classement spécifique
      final classement = await HiveService.getOrCreateClassementForLocal(
        missionId: widget.mission.id,
        localisation: local.nom,
        zone: 'Zone ${widget.zoneIndex! + 1}',
        typeLocal: local.type,
      );
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassementEmplacementScreen(
            mission: widget.mission,
            emplacement: classement,
          ),
        ),
      );
      
      if (result == true) {
        Navigator.pop(context, true);
      }
    } else {
      // Local hors zone : classement spécifique obligatoire
      final classement = await HiveService.getOrCreateClassementForLocal(
        missionId: widget.mission.id,
        localisation: local.nom,
        zone: null,
        typeLocal: local.type,
      );
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassementEmplacementScreen(
            mission: widget.mission,
            emplacement: classement,
          ),
        ),
      );
      
      if (result == true) {
        Navigator.pop(context, true);
      }
    }
  }
  
  
  // NOUVEAU : Dialogue de choix héritage/spécifique
  Future<String?> _showChoixClassementDialog(dynamic local, {bool zoneNonClassee = false}) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_outlined,
                  size: 30,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Classement du local',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                zoneNonClassee 
                  ? 'La zone parente n\'a pas encore de classement complet. Vous devez définir un classement spécifique pour ce local.'
                  : 'Ce local appartient à une zone. Comment souhaitez-vous définir son classement ?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
              // Option 1 : Hériter (seulement si la zone est classée)
              if (!zoneNonClassee)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, 'heriter'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.link, color: Colors.blue, size: 22),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hériter du classement de la zone',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Le local suivra automatiquement le classement de sa zone parente',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              if (!zoneNonClassee) SizedBox(height: 12),
              
              // Option 2 : Spécifique
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: InkWell(
                  onTap: () => Navigator.pop(context, 'specifique'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: Colors.orange, size: 22),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Définir un classement spécifique',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Vous pourrez définir des influences externes différentes de la zone',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ClassementZone?> _getZoneParenteClassement() async {
    if (!widget.isInZone || widget.zoneIndex == null) return null;
    
    final audit = await HiveService.getOrCreateAuditInstallations(widget.mission.id);
    String? nomZone;
    
    if (widget.isMoyenneTension) {
      if (widget.zoneIndex! < audit.moyenneTensionZones.length) {
        nomZone = audit.moyenneTensionZones[widget.zoneIndex!].nom;
      }
    } else {
      if (widget.zoneIndex! < audit.basseTensionZones.length) {
        nomZone = audit.basseTensionZones[widget.zoneIndex!].nom;
      }
    }
    
    if (nomZone == null) return null;
    
    // Synchroniser d'abord pour s'assurer que le classement existe
    await HiveService.syncClassementsZonesFromAudit(widget.mission.id);
    
    // Chercher le classement de la zone
    return HiveService.getClassementZoneByNom(widget.mission.id, nomZone);
  }

  MoyenneTensionLocal _creerMoyenneTensionLocal() {
    return _creerMoyenneTensionLocalAvecType(_selectedType!);
  }

  BasseTensionLocal _creerBasseTensionLocal() {
    return _creerBasseTensionLocalAvecType(_selectedType!);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
  }

  int _getTotalSteps() => _selectedType == 'LOCAL_TRANSFORMATEUR' ? 3 : 2;

  @override
  Widget build(BuildContext context) {
    final totalSteps = _getTotalSteps();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.isEdition ? 'Modifier le Local' : 'Ajouter un Local', style: TextStyle(fontSize: context.fontSizeL)),
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
                  _EtapeInformationsGenerales(
                    nomController: _nomController,
                    selectedType: _selectedType,
                    onTypeChanged: _onTypeChanged,
                    localPhotos: _localPhotos,
                    onPrendrePhoto: _prendrePhotoLocal,
                    onChoisirPhoto: _choisirPhotoLocalDepuisGalerie,
                    onSupprimerPhoto: () {},
                    isLoadingPhotos: _isLoadingPhotos,
                    addObservation: _addObservation,
                    onAddObservationChanged: (value) {
                      setState(() {
                        _addObservation = value;
                        _validateObservations();
                      });
                    },
                    observationController: _observationController,
                    observationsExistantes: _observationsExistantes,
                    observationPhotos: _observationPhotos,
                    onPrendrePhotoObservation: _prendrePhotoObservation,
                    onChoisirPhotoObservation: _choisirPhotoObservationDepuisGalerie,
                    onAjouterObservation: _ajouterObservation,
                    onSupprimerObservationExistante: _supprimerObservationExistante,
                    nomValid: _nomValid,
                    typeValid: _typeValid,
                    onValidate: () => _validateNom(_nomController.text),
                  ),
                  if (_selectedType != null)
                    _EtapeElementsControle(
                    key: _etapeElementsKey,
                    dispositionsConstructives: _dispositionsConstructives,
                    conditionsExploitation: _conditionsExploitation,
                    hasObservation: _hasObservation,
                    elementSuggestions: _elementSuggestions,
                    conformeSelected: _conformeSelected,
                    onElementChanged: (element, index, action) => setState(() {}),
                    onConformeChanged: _onConformeChanged,
                    onObservationToggleChanged: (index, value, section) => setState(() => _hasObservation[index] = value),
                    onPrendrePhotoElement: _prendrePhotoPourElement,
                    onChoisirPhotoElement: _choisirPhotoPourElement,
                    onSupprimerPhotoElement: _supprimerPhotoElement,
                    onObservationChanged: _onElementObservationChanged,
                    onUseSuggestion: _useElementSuggestion,
                    onAjouterAutre: _onAjouterAutre,
                    onRebuildSlides: () {
                      // Reconstruire les slides après ajout
                      _etapeElementsKey?.currentState?.rebuildSlides();
                    },
                  ),
                  if (_selectedType == 'LOCAL_TRANSFORMATEUR')
                    _EtapeCelluleTransformateur(
                      key: _etapeCelluleTransfoKey,
                      celluleFonctionController: _celluleFonctionController,
                      celluleTypeController: _celluleTypeController,
                      celluleMarqueController: _celluleMarqueController,
                      celluleTensionController: _celluleTensionController,
                      cellulePouvoirController: _cellulePouvoirController,
                      celluleNumerotationController: _celluleNumerotationController,
                      celluleParafoudresController: _celluleParafoudresController,
                      celluleElements: _celluleElements,
                      transfoTypeController: _transfoTypeController,
                      transfoMarqueController: _transfoMarqueController,
                      transfoPuissanceController: _transfoPuissanceController,
                      transfoTensionController: _transfoTensionController,
                      transfoBuchholzController: _transfoBuchholzController,
                      transfoRefroidissementController: _transfoRefroidissementController,
                      transfoRegimeController: _transfoRegimeController,
                      transfoElements: _transfoElements,
                      hasObservation: _hasObservation,
                      elementSuggestions: _elementSuggestions,
                      conformeSelected: _conformeSelected,
                      onElementChanged: (element, index, action) => setState(() {}),
                      onConformeChanged: _onConformeChanged,
                      onObservationToggleChanged: (index, value, section) => setState(() => _hasObservation[index] = value),
                      onPrendrePhotoElement: _prendrePhotoPourElement,
                      onChoisirPhotoElement: _choisirPhotoPourElement,
                      onSupprimerPhotoElement: _supprimerPhotoElement,
                      onObservationChanged: _onElementObservationChanged,
                      onUseSuggestion: _useElementSuggestion,
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