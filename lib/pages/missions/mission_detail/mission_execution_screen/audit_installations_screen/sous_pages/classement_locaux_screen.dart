// // classement_locaux_screen.dart
// import 'package:flutter/material.dart';
// import 'package:inspec_app/models/classement_locaux.dart';
// import 'package:inspec_app/models/mission.dart';
// import 'package:inspec_app/constants/app_theme.dart';
// import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/classement_emplacement_screen.dart';
// import 'package:inspec_app/services/hive_service.dart';

// class ClassementLocauxScreen extends StatefulWidget {
//   final Mission mission;

//   const ClassementLocauxScreen({super.key, required this.mission});

//   @override
//   State<ClassementLocauxScreen> createState() => _ClassementLocauxScreenState();
// }

// class _ClassementLocauxScreenState extends State<ClassementLocauxScreen> with SingleTickerProviderStateMixin {
//   List<ClassementEmplacement> _zones = [];
//   List<ClassementEmplacement> _locaux = [];
//   bool _isLoading = true;
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _checkAuditAndLoadEmplacements();
//   }

//   void _checkAuditAndLoadEmplacements() async {
//     try {
//       final audit = HiveService.getAuditInstallationsByMissionId(widget.mission.id);
      
//       if (audit != null) {
//         // Synchroniser TOUT (zones + locaux)
//         final allEmplacements = await HiveService.syncAllEmplacementsFromAudit(widget.mission.id);
        
//         setState(() {
//           _zones = allEmplacements.where((e) => e.typeEmplacement == 'zone').toList();
//           _locaux = allEmplacements.where((e) => e.typeEmplacement == 'local').toList();
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _zones = HiveService.getZonesByMissionId(widget.mission.id);
//           _locaux = HiveService.getLocauxByMissionId(widget.mission.id);
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('❌ Erreur chargement classement: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   int _getZonesComplets() {
//     return _zones.where((e) => e.af != null && e.be != null && e.ae != null && e.ad != null && e.ag != null).length;
//   }

//   int _getLocauxComplets() {
//     return _locaux.where((e) => e.af != null && e.be != null && e.ae != null && e.ad != null && e.ag != null).length;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Classement des Emplacements'),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//         ),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Classement des Emplacements'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _checkAuditAndLoadEmplacements,
//             tooltip: 'Synchroniser avec l\'audit',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // En-tête avec statistiques globales
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade50,
//               border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildStatCard('Zones', _zones.length, Icons.map_outlined, AppTheme.primaryBlue),
//                 _buildStatCard('Zones complètes', _getZonesComplets(), Icons.check_circle, Colors.green),
//                 _buildStatCard('Locaux', _locaux.length, Icons.location_on, Colors.orange),
//                 _buildStatCard('Locaux complets', _getLocauxComplets(), Icons.check_circle, Colors.green),
//               ],
//             ),
//           ),
          
//           // TabBar
//           Container(
//             color: Colors.white,
//             child: TabBar(
//               controller: _tabController,
//               labelColor: AppTheme.primaryBlue,
//               unselectedLabelColor: Colors.grey,
//               indicatorColor: AppTheme.primaryBlue,
//               tabs: [
//                 Tab(text: 'ZONES (${_zones.length})'),
//                 Tab(text: 'LOCAUX (${_locaux.length})'),
//               ],
//             ),
//           ),
          
//           // Contenu des onglets
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildZonesList(),
//                 _buildLocauxList(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildZonesList() {
//     if (_zones.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
//             SizedBox(height: 16),
//             Text('Aucune zone trouvée', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
//             SizedBox(height: 8),
//             Text(
//               'Créez des zones dans l\'audit',
//               style: TextStyle(color: Colors.grey.shade500),
//             ),
//           ],
//         ),
//       );
//     }
    
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: _zones.length,
//       itemBuilder: (context, index) {
//         return _buildEmplacementCard(_zones[index], index, isZone: true);
//       },
//     );
//   }

//   Widget _buildLocauxList() {
//     if (_locaux.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.location_on_outlined, size: 64, color: Colors.grey.shade400),
//             SizedBox(height: 16),
//             Text('Aucun local trouvé', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
//             SizedBox(height: 8),
//             Text(
//               'Créez des locaux dans l\'audit',
//               style: TextStyle(color: Colors.grey.shade500),
//             ),
//           ],
//         ),
//       );
//     }
    
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: _locaux.length,
//       itemBuilder: (context, index) {
//         return _buildEmplacementCard(_locaux[index], index, isZone: false);
//       },
//     );
//   }

//   Widget _buildEmplacementCard(ClassementEmplacement emplacement, int index, {required bool isZone}) {
//     final estComplet = emplacement.af != null && 
//                        emplacement.be != null && 
//                        emplacement.ae != null && 
//                        emplacement.ad != null && 
//                        emplacement.ag != null;
    
//     return Card(
//       margin: EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: InkWell(
//         onTap: () => _ouvrirClassement(emplacement),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: estComplet ? Colors.green.shade50 : Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       isZone ? Icons.map_outlined : Icons.location_on_outlined,
//                       color: estComplet ? Colors.green : AppTheme.primaryBlue,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           emplacement.localisation,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         if (emplacement.zone != null) ...[
//                           SizedBox(height: 4),
//                           Text(
//                             'Zone: ${emplacement.zone}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                         // Afficher si le local hérite de sa zone
//                         if (!isZone && emplacement.heriteDeZone)
//                           Container(
//                             margin: EdgeInsets.only(top: 4),
//                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(Icons.link, size: 12, color: Colors.blue.shade700),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'Hérite de la zone',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.blue.shade700,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: estComplet ? Colors.green.shade100 : Colors.orange.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       estComplet ? 'Complet' : 'À compléter',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: estComplet ? Colors.green.shade800 : Colors.orange.shade800,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               SizedBox(height: 12),
              
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Text(
//                       'Origine: ',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     Text(
//                       emplacement.origineClassement,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: AppTheme.darkBlue,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               SizedBox(height: 12),
              
//               if (estComplet)
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green.shade100),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Influences externes:',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.green.shade800,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: [
//                           _buildInfluenceChip('AF', emplacement.af!),
//                           _buildInfluenceChip('BE', emplacement.be!),
//                           _buildInfluenceChip('AE', emplacement.ae!),
//                           _buildInfluenceChip('AD', emplacement.ad!),
//                           _buildInfluenceChip('AG', emplacement.ag!),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(color: Colors.green.shade200),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             Text(
//                               'IP: ${emplacement.ip ?? "N/A"}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green.shade800,
//                               ),
//                             ),
//                             Text(
//                               'IK: ${emplacement.ik ?? "N/A"}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green.shade800,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               else
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.orange.shade100),
//                   ),
//                   child: Center(
//                     child: Text(
//                       'Cliquez pour renseigner les influences externes',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.orange.shade800,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _ouvrirClassement(ClassementEmplacement emplacement) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ClassementEmplacementScreen(
//           mission: widget.mission,
//           emplacement: emplacement,
//         ),
//       ),
//     );
    
//     if (result == true) {
//       _checkAuditAndLoadEmplacements();
//     }
//   }


// Widget _buildInfluenceChip(String type, String code) {
//   final Map<String, Color> colorMap = {
//     'AF': Colors.blue,
//     'BE': Colors.purple,
//     'AE': Colors.orange,
//     'AD': Colors.teal,
//     'AG': Colors.red,
//   };
  
//   return Container(
//     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//     decoration: BoxDecoration(
//       color: colorMap[type]!.withOpacity(0.1),
//       borderRadius: BorderRadius.circular(6),
//       border: Border.all(color: colorMap[type]!.withOpacity(0.3)),
//     ),
//     child: Text(
//       '$type: $code',
//       style: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//         color: colorMap[type]!,
//       ),
//     ),
//   );
// }
// }