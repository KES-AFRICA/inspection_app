import 'package:flutter/material.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class ParatonnerreScreen extends StatefulWidget {
  final Mission mission;

  const ParatonnerreScreen({super.key, required this.mission});

  @override
  State<ParatonnerreScreen> createState() => _ParatonnerreScreenState();
}

class _ParatonnerreScreenState extends State<ParatonnerreScreen> {
  String? _presenceParatonnerre;
  String? _analyseRisqueFoudre;
  String? _etudeTechniqueFoudre;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    setState(() => _isLoading = true);
    
    try {
      final desc = await HiveService.getOrCreateDescriptionInstallations(widget.mission.id);
      
      setState(() {
        _presenceParatonnerre = desc.presenceParatonnerre;
        _analyseRisqueFoudre = desc.analyseRisqueFoudre;
        _etudeTechniqueFoudre = desc.etudeTechniqueFoudre;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement paratonnerre: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelections() async {
    setState(() => _isSaving = true);

    try {
      final success1 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'presence_paratonnerre',
        value: _presenceParatonnerre ?? '',
      );

      final success2 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'analyse_risque_foudre',
        value: _analyseRisqueFoudre ?? '',
      );

      final success3 = await HiveService.updateSelection(
        missionId: widget.mission.id,
        field: 'etude_technique_foudre',
        value: _etudeTechniqueFoudre ?? '',
      );

      if (success1 && success2 && success3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélections sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildRadioGroup(String title, String? selectedValue, Function(String?) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRadioButton(
                    label: 'OUI',
                    value: 'OUI',
                    groupValue: selectedValue,
                    onChanged: onChanged,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRadioButton(
                    label: 'NON',
                    value: 'NON',
                    groupValue: selectedValue,
                    onChanged: onChanged,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioButton({
    required String label,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
    required Color color,
  }) {
    final isSelected = groupValue == value;
    
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Protection des installations contre la foudre',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRadioGroup(
              'Présence de paratonnerre',
              _presenceParatonnerre,
              (value) => setState(() => _presenceParatonnerre = value),
            ),
            _buildRadioGroup(
              'Analyse risque foudre',
              _analyseRisqueFoudre,
              (value) => setState(() => _analyseRisqueFoudre = value),
            ),
            _buildRadioGroup(
              'Étude technique foudre',
              _etudeTechniqueFoudre,
              (value) => setState(() => _etudeTechniqueFoudre = value),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Enregistrer (visible en bas également)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSelections,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ENREGISTRER',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}