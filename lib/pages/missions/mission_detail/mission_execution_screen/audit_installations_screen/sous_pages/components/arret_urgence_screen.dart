// lib/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/arret_urgence_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ArretUrgenceScreen extends StatefulWidget {
  final Mission mission;

  const ArretUrgenceScreen({super.key, required this.mission});

  @override
  State<ArretUrgenceScreen> createState() => _ArretUrgenceScreenState();
}

class _ArretUrgenceScreenState extends State<ArretUrgenceScreen> {
  bool _estPresent = false; // Par défaut absent
  String? _selectedResult;
  bool _isLoading = true;
  bool _isSaving = false;

  // 3 options pour le résultat du test
  final List<String> _resultOptions = ['Satisfaisant', 'Non satisfaisant', 'Sans objet'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final mesures = await HiveService.getOrCreateMesuresEssais(widget.mission.id);
      final tau = mesures.testArretUrgence;

      if (mounted) {
        setState(() {
          // Règle de rétrocompatibilité stricte : si observation non vide => Présent
          _estPresent = tau.estPresent;
          _selectedResult = tau.observation;

          // Si présent mais sans résultat déjà sélectionné, 'Sans objet' par défaut
          if (_estPresent && (_selectedResult == null || _selectedResult!.trim().isEmpty)) {
            _selectedResult = 'Sans objet';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePresence(bool present) async {
    setState(() {
      _estPresent = present;
      if (present && (_selectedResult == null || _selectedResult!.trim().isEmpty)) {
        _selectedResult = 'Sans objet';
      }
      _isSaving = true;
    });

    try {
      final success = await HiveService.updateTestArretUrgence(
        missionId: widget.mission.id,
        presence: present,
        observation: present ? _selectedResult : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(present ? 'Arrêt d\'urgence : Présent' : 'Arrêt d\'urgence : Absent'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveResult(String value) async {
    setState(() {
      _selectedResult = value;
      _isSaving = true;
    });

    try {
      final success = await HiveService.updateTestArretUrgence(
        missionId: widget.mission.id,
        presence: true,
        observation: value,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Résultat : $value'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test arrêt urgence'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message informatif
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: isSmallScreen ? 20 : 22),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                      child: Text(
                        'Indiquez la présence ou l\'absence de l\'arrêt d\'urgence général, puis le résultat du test le cas échéant.',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 1. SECTION ARRÊT D'URGENCE GÉNÉRAL (Présent / Absent) ──
              Text(
                'Arrêt d\'Urgence Général',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),

              // Option Présent
              _buildPresenceCard(
                title: 'Présent',
                subtitle: 'Un dispositif d\'arrêt d\'urgence général est installé',
                value: true,
                isSelected: _estPresent,
                isSmallScreen: isSmallScreen,
              ),

              SizedBox(height: isSmallScreen ? 8 : 10),

              // Option Absent (par défaut)
              _buildPresenceCard(
                title: 'Absent',
                subtitle: 'Aucun arrêt d\'urgence général présent sur le site',
                value: false,
                isSelected: !_estPresent,
                isSmallScreen: isSmallScreen,
              ),

              // ── 2. SECTION RÉSULTAT DU TEST (affichée uniquement si Présent) ──
              if (_estPresent) ...[
                SizedBox(height: isSmallScreen ? 24 : 28),
                const Divider(height: 1),
                SizedBox(height: isSmallScreen ? 20 : 24),

                Text(
                  'Résultat du test',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                ..._resultOptions.map((option) {
                  final isSelected = _selectedResult == option;
                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryBlue : Colors.black87,
                        ),
                      ),
                      value: option,
                      groupValue: _selectedResult,
                      onChanged: _isSaving ? null : (value) {
                        if (value != null) {
                          _saveResult(value);
                        }
                      },
                      activeColor: AppTheme.primaryBlue,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }),
              ] else ...[
                
              ],

              if (_isSaving)
                Padding(
                  padding: EdgeInsets.only(top: isSmallScreen ? 20 : 24),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceCard({
    required String title,
    required String subtitle,
    required bool value,
    required bool isSelected,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<bool>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryBlue : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        groupValue: _estPresent,
        onChanged: _isSaving ? null : (v) {
          if (v != null) {
            _savePresence(v);
          }
        },
        activeColor: AppTheme.primaryBlue,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}