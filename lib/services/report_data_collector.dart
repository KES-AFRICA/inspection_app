// lib/services/report_data_collector.dart
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';

/// Modèle d'entrée photo partagé et dédupliqué entre PDF et Word
class ReportPhotoItem {
  final String filePath;
  final String description;
  final String? repere;

  ReportPhotoItem({
    required this.filePath,
    required this.description,
    this.repere,
  });
}

/// Collecteur de données et source unique de vérité pour les rapports (PDF & Word)
class ReportDataCollector {
  /// Collecte et déduplique l'ensemble des photographies de l'inspection
  static List<ReportPhotoItem> collectAllPhotos({
    required Mission mission,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
  }) {
    final allPhotos = <ReportPhotoItem>[];
    final seenPaths = <String>{};

    void addUniquePhotos(List<String>? paths, String desc, {String? repere}) {
      if (paths == null || paths.isEmpty) return;
      for (var p in paths) {
        final trimmed = p.trim();
        if (trimmed.isEmpty) continue;
        if (!seenPaths.contains(trimmed)) {
          seenPaths.add(trimmed);
          allPhotos.add(ReportPhotoItem(
            filePath: trimmed,
            description: desc,
            repere: repere,
          ));
        }
      }
    }

    void processCoffret(CoffretArmoire c, String prefix) {
      final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
      addUniquePhotos(c.photosExternes, '$prefix - Coffret : ${c.nom} (Extérieur)', repere: repVal);
      addUniquePhotos(c.photosInternes, '$prefix - Coffret : ${c.nom} (Intérieur)', repere: repVal);
      addUniquePhotos(c.photos, '$prefix - Coffret : ${c.nom}', repere: repVal);
      for (var pv in c.pointsVerification) {
        addUniquePhotos(pv.photos, '$prefix - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
      }
      for (var obs in c.observationsLibres) {
        addUniquePhotos(obs.photos, '$prefix - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
      }
      final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
      for (var obs in pfEnrichies) {
        addUniquePhotos(obs.photos, '$prefix - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
      }
    }

    // 1. Photos Description des installations
    if (description != null) {
      void addItems(List<InstallationItem>? items, String categoryLabel) {
        if (items == null) return;
        for (var item in items) {
          final nomItem = item.data['nom'] ?? item.data['Nom'] ?? (item.data.isNotEmpty ? item.data.values.first : '');
          addUniquePhotos(item.photoPaths, 'Description - $categoryLabel${nomItem.isNotEmpty ? ' : $nomItem' : ''}');
        }
      }
      addItems(description.alimentationMoyenneTension, 'Alimentation MT');
      addItems(description.alimentationBasseTension, 'Alimentation BT');
      addItems(description.groupeElectrogene, 'Groupe Électrogène');
      addItems(description.alimentationCarburant, 'Alimentation Carburant');
      addItems(description.inverseur, 'Inverseur');
      addItems(description.stabilisateur, 'Stabilisateur');
      addItems(description.onduleurs, 'Onduleurs');
    }

    // 2. Photos Audit des installations électriques
    if (audit != null) {
      // Général Audit
      addUniquePhotos(audit.photos, "Général Audit");

      // Moyenne Tension Locaux
      for (var local in audit.moyenneTensionLocaux) {
        addUniquePhotos(local.photos, local.nom);
        for (var dc in local.dispositionsConstructives) {
          addUniquePhotos(dc.photos, '${local.nom} - DC : ${dc.elementControle}');
        }
        for (var ce in local.conditionsExploitation) {
          addUniquePhotos(ce.photos, '${local.nom} - CE : ${ce.elementControle}');
        }
        for (var obs in local.observationsLibres) {
          addUniquePhotos(obs.photos, '${local.nom} - Obs libre : ${obs.texte}');
        }
        for (var i = 0; i < local.cellules.length; i++) {
          final cellule = local.cellules[i];
          addUniquePhotos(cellule.photos, '${local.nom} - Cellule ${i + 1} (${cellule.fonction})');
          for (var ev in cellule.elementsVerifies) {
            addUniquePhotos(ev.photos, '${local.nom} - Cellule ${i + 1} - Vérif : ${ev.elementControle}');
          }
        }
        for (var i = 0; i < local.transformateurs.length; i++) {
          final transfo = local.transformateurs[i];
          addUniquePhotos(transfo.photos, '${local.nom} - Transformateur ${i + 1}');
          for (var ev in transfo.elementsVerifies) {
            addUniquePhotos(ev.photos, '${local.nom} - Transformateur ${i + 1} - Vérif : ${ev.elementControle}');
          }
        }
        for (var c in local.coffrets) {
          processCoffret(c, local.nom);
        }
      }

      // Moyenne Tension Zones
      for (var zone in audit.moyenneTensionZones) {
        addUniquePhotos(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addUniquePhotos(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}');
        }
        for (var c in zone.coffrets) {
          processCoffret(c, zone.nom);
        }
        for (var local in zone.locaux) {
          addUniquePhotos(local.photos, '${zone.nom} - Local ${local.nom}');
          for (var dc in local.dispositionsConstructives) {
            addUniquePhotos(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}');
          }
          for (var ce in local.conditionsExploitation) {
            addUniquePhotos(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}');
          }
          for (var obs in local.observationsLibres) {
            addUniquePhotos(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}');
          }
          for (var c in local.coffrets) {
            processCoffret(c, '${zone.nom} - Local ${local.nom}');
          }
        }
      }

      // Basse Tension Zones
      for (var zone in audit.basseTensionZones) {
        addUniquePhotos(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addUniquePhotos(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}');
        }
        for (var c in zone.coffretsDirects) {
          processCoffret(c, zone.nom);
        }
        for (var local in zone.locaux) {
          addUniquePhotos(local.photos, '${zone.nom} - Local ${local.nom}');
          if (local.dispositionsConstructives != null) {
            for (var dc in local.dispositionsConstructives!) {
              addUniquePhotos(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}');
            }
          }
          if (local.conditionsExploitation != null) {
            for (var ce in local.conditionsExploitation!) {
              addUniquePhotos(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}');
            }
          }
          for (var obs in local.observationsLibres) {
            addUniquePhotos(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}');
          }
          for (var c in local.coffrets) {
            processCoffret(c, '${zone.nom} - Local ${local.nom}');
          }
        }
      }
    }

    return allPhotos;
  }

  /// Indique si la section Schéma des installations électriques doit être affichée
  static bool hasSchemaSection(Mission mission) {
    return mission.schemaOption?.trim().toLowerCase() == 'oui';
  }
}
