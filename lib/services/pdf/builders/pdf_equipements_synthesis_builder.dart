import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

class PdfEquipementItem {
  final String zoneName;
  final String localName;
  final String repere;
  final String nom;
  final String type;
  final bool isMT;
  final bool accessible;
  final String? presenceParafoudre;
  final String? verificationThermo;
  final String hasObservation;

  const PdfEquipementItem({
    this.zoneName = '',
    this.localName = '',
    required this.repere,
    required this.nom,
    required this.type,
    required this.isMT,
    this.accessible = true,
    this.presenceParafoudre,
    this.verificationThermo,
    this.hasObservation = 'Non',
  });
}

class PdfUnknownSourceItem {
  final String zoneName;
  final String localName;
  final String repere;
  final String nom;
  final String type;
  final String alimentationConcernee;
  final String source;

  const PdfUnknownSourceItem({
    this.zoneName = '',
    this.localName = '',
    required this.repere,
    required this.nom,
    required this.type,
    required this.alimentationConcernee,
    required this.source,
  });
}

class PdfEquipementRepereGroup {
  final String localName;
  final List<PdfEquipementItem> items;

  PdfEquipementRepereGroup({
    required this.localName,
    required this.items,
  });
}

class PdfEquipementZoneGroup {
  final String zoneName;
  final List<PdfEquipementRepereGroup> repereGroups;

  PdfEquipementZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

class PdfUnknownSourceRepereGroup {
  final String localName;
  final List<PdfUnknownSourceItem> items;

  PdfUnknownSourceRepereGroup({
    required this.localName,
    required this.items,
  });
}

class PdfUnknownSourceZoneGroup {
  final String zoneName;
  final List<PdfUnknownSourceRepereGroup> repereGroups;

  PdfUnknownSourceZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

/// Builder responsable de la Synthèse des Équipements (tableaux MT, BT, et sources inconnues)
class PdfEquipementsSynthesisBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsSmall = PdfReportStyles.fsSmall;
  static const double fsBody = PdfReportStyles.fsBody;

  static pw.Widget buildEquipementsTableForTesting(
    List<PdfEquipementItem> items, {
    bool isMT = false,
  }) {
    return pw.Column(children: buildEquipementsTable(items, isMT: isMT));
  }

// Internal aliases
  static String? _normalizeEquipementType(String rawType, String rawNom) => normalizeEquipementType(rawType, rawNom);
  static bool _isMTEquipementCoffret(CoffretArmoire coffret) => isMTEquipementCoffret(coffret);
  static String? _extractPresenceParafoudre(Object refObj) => extractPresenceParafoudre(refObj);
  static String? _extractVerificationThermo(Object refObj) => extractVerificationThermo(refObj);
  static bool _isRealUserObservation(String? text) => isRealUserObservation(text);
  static bool _matchEquip(CoffretArmoire c, String query) => matchEquip(c, query);
  static bool _matchName(String name, String query) => matchName(name, query);
  static bool _extractHasObservation(Object refObj) => extractHasObservation(refObj);
  static List<PdfEquipementItem> _collectEquipementsMT(AuditInstallationsElectriques? audit) => collectEquipementsMT(audit);
  static List<PdfEquipementItem> _collectEquipementsBT(AuditInstallationsElectriques? audit, DescriptionInstallations? desc) => collectEquipementsBT(audit, desc);
  static List<PdfUnknownSourceItem> _collectEquipementsUnknownSource(AuditInstallationsElectriques? audit) => collectEquipementsUnknownSource(audit);
  static List<pw.Widget> _buildUnknownSourcesTable(List<PdfUnknownSourceItem> items) => buildUnknownSourcesTable(items);
  static List<pw.Widget> _buildEquipementsTable(List<PdfEquipementItem> items, {bool isMT = false}) => buildEquipementsTable(items, isMT: isMT);

  static String? normalizeEquipementType(String rawType, String rawNom) {
    final combined = '${rawType.toLowerCase()} ${rawNom.toLowerCase()}';

    if (combined.contains('cellule')) return 'Cellule';
    if (combined.contains('transformateur') || combined.contains('transfo')) return 'Transformateur';
    if (combined.contains('tgbt')) return 'TGBT';
    if (combined.contains('inverseur')) return 'Inverseur';
    if (combined.contains('armoire')) return 'Armoire';
    if (combined.contains('coffret') || combined.contains('tur')) return 'Coffret';

    final typeLower = rawType.trim().toLowerCase();
    if (typeLower == 'cellule') return 'Cellule';
    if (typeLower == 'transformateur' || typeLower == 'transfo') return 'Transformateur';
    if (typeLower == 'tgbt') return 'TGBT';
    if (typeLower == 'inverseur') return 'Inverseur';
    if (typeLower == 'armoire') return 'Armoire';
    if (typeLower == 'coffret') return 'Coffret';

    return null;
  }

  static bool isMTEquipementCoffret(CoffretArmoire coffret) {
    final normType = _normalizeEquipementType(coffret.type, coffret.nom);
    if (normType == 'Cellule' || normType == 'Transformateur') {
      return true;
    }
    if (normType == 'TGBT' || normType == 'Inverseur' || normType == 'Armoire' || normType == 'Coffret') {
      return false;
    }
    final combined = '${coffret.type.toLowerCase()} ${coffret.nom.toLowerCase()}';
    if (combined.contains('cellule') || combined.contains('transformateur') || combined.contains('transfo')) {
      return true;
    }
    return false;
  }

  static String? extractPresenceParafoudre(Object refObj) {
    if (refObj is CoffretArmoire) {
      return refObj.presenceParafoudre ? 'Oui' : 'Non';
    }
    try {
      final dynamic val = (refObj as dynamic).presenceParafoudre;
      if (val is bool) {
        return val ? 'Oui' : 'Non';
      } else if (val is String && val.trim().isNotEmpty) {
        final norm = val.trim().toLowerCase();
        if (norm == 'oui' || norm == 'true' || norm == '1') return 'Oui';
        if (norm == 'non' || norm == 'false' || norm == '0') return 'Non';
      }
    } catch (_) {}

    try {
      final dynamic val = (refObj as dynamic).parafoudres;
      if (val is bool) {
        return val ? 'Oui' : 'Non';
      } else if (val is String && val.trim().isNotEmpty) {
        final norm = val.trim().toLowerCase();
        if (norm == 'oui' || norm == 'true' || norm == '1' || norm.contains('présent') || norm.contains('present')) return 'Oui';
        if (norm == 'non' || norm == 'false' || norm == '0' || norm.contains('absent')) return 'Non';
      }
    } catch (_) {}

    return null;
  }

  static String? extractVerificationThermo(Object refObj) {
    if (refObj is List) {
      for (final item in refObj) {
        if (item is Object) {
          final res = _extractVerificationThermo(item);
          if (res != null) return res;
        }
      }
    }
    if (refObj is CoffretArmoire) {
      return refObj.verificationThermographie ? 'Oui' : 'Non';
    }
    if (refObj is InstallationItem) {
      for (final entry in refObj.data.entries) {
        final keyLower = entry.key.toLowerCase();
        if (keyLower.contains('thermo')) {
          final norm = entry.value.trim().toLowerCase();
          if (norm == 'oui' || norm == 'true' || norm == '1') return 'Oui';
          if (norm == 'non' || norm == 'false' || norm == '0') return 'Non';
        }
      }
    }
    try {
      final dynamic val = (refObj as dynamic).verificationThermographie;
      if (val is bool) {
        return val ? 'Oui' : 'Non';
      } else if (val is String && val.trim().isNotEmpty) {
        final norm = val.trim().toLowerCase();
        if (norm == 'oui' || norm == 'true' || norm == '1') return 'Oui';
        if (norm == 'non' || norm == 'false' || norm == '0') return 'Non';
      }
    } catch (_) {}

    return null;
  }

  static bool isRealUserObservation(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();

    // Filtre des placeholders générés et textes système
    if (lower.startsWith('observation équipement') ||
        lower.startsWith('observation equipement') ||
        lower.startsWith('observation n°') ||
        lower.startsWith('observation no')) {
      return false;
    }

    // Filtre des mots neutres et réponses de conformité simples
    if (lower == 'ras' ||
        lower == 'r.a.s' ||
        lower == 'r.a.s.' ||
        lower == 'aucun' ||
        lower == 'aucune' ||
        lower == 'sans' ||
        lower == 'sans objet' ||
        lower == 's/o' ||
        lower == 'n/a' ||
        lower == 'none' ||
        lower == 'oui' ||
        lower == 'non' ||
        lower == 'conforme' ||
        lower == 'non conforme') {
      return false;
    }

    return true;
  }



  static bool matchEquip(CoffretArmoire c, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (c.nom.trim().toLowerCase() == q) return true;
    if (c.repere != null && c.repere!.trim().toLowerCase() == q) return true;
    if (c.numeroEquipement != null && c.numeroEquipement!.trim().toLowerCase() == q) return true;
    return false;
  }

  static bool matchName(String name, String query) {
    final n = name.trim().toLowerCase();
    final q = query.trim().toLowerCase();
    if (n.isEmpty || q.isEmpty) return false;
    if (n == q) return true;
    if (n.replaceFirst('local ', '') == q.replaceFirst('local ', '')) return true;
    return false;
  }

  static bool extractHasObservation(Object refObj) {
    if (refObj is List) {
      for (final item in refObj) {
        if (item is Object && _extractHasObservation(item)) return true;
      }
      return false;
    }
    if (refObj is CoffretArmoire) {
      // 1. Slide 1 (Information Générale)
      if (_isRealUserObservation(refObj.description)) return true;

      // 2. Slide 2 (Alimentation & Protection Tête)
      if (refObj.protectionTete != null) {
        try {
          final dynamic obs = (refObj.protectionTete as dynamic).observation;
          if (obs is String && _isRealUserObservation(obs)) return true;
        } catch (_) {}
      }
      for (final alim in refObj.alimentations) {
        try {
          final dynamic obs = (alim as dynamic).observation;
          if (obs is String && _isRealUserObservation(obs)) return true;
        } catch (_) {}
      }

      // 3. Slide 5 (Points de vérification et observations libres)
      for (final pv in refObj.pointsVerification) {
        if (_isRealUserObservation(pv.observation)) return true;
        if (pv.observations != null) {
          for (final ec in pv.observations!) {
            if (_isRealUserObservation(ec.observation)) return true;
          }
        }
      }

      for (final obs in refObj.observationsLibres) {
        if (_isRealUserObservation(obs.texte)) return true;
      }

      for (final obs in refObj.observationsParafoudre) {
        if (_isRealUserObservation(obs.texte)) return true;
      }

      if (refObj.observationsParafoudreEnrichies != null) {
        for (final ec in refObj.observationsParafoudreEnrichies!) {
          if (_isRealUserObservation(ec.observation)) return true;
        }
      }
    } else if (refObj is InstallationItem) {
      for (final entry in refObj.data.entries) {
        final kLower = entry.key.toLowerCase();
        if (kLower.contains('obs') && _isRealUserObservation(entry.value)) {
          return true;
        }
      }
    } else {
      try {
        final dynamic obs = (refObj as dynamic).observation;
        if (obs is String && _isRealUserObservation(obs)) return true;
      } catch (_) {}
      try {
        final dynamic obsList = (refObj as dynamic).observationsLibres;
        if (obsList is List) {
          for (final o in obsList) {
            if (o is ObservationLibre && _isRealUserObservation(o.texte)) return true;
            if (o is String && _isRealUserObservation(o)) return true;
          }
        }
      } catch (_) {}
    }

    return false;
  }




  static List<PdfEquipementItem> collectEquipementsMT(
    AuditInstallationsElectriques? audit,
  ) {
    final list = <PdfEquipementItem>[];
    if (audit == null) return list;

    final seenHashes = <int>{};

    void addEquipement({
      required Object refObj,
      String zoneName = '',
      String localName = '',
      required String repere,
      required String nom,
      required String type,
      bool accessible = true,
    }) {
      final hash = identityHashCode(refObj);
      if (!seenHashes.contains(hash)) {
        seenHashes.add(hash);
        final equipNom = nom.trim().isNotEmpty
            ? nom.trim()
            : (repere.trim().isNotEmpty ? repere.trim() : type);
        list.add(
          PdfEquipementItem(
            zoneName: zoneName.trim(),
            localName: localName.trim(),
            repere: repere.trim(),
            nom: equipNom,
            type: type,
            isMT: true,
            accessible: accessible,
            presenceParafoudre: _extractPresenceParafoudre(refObj),
            verificationThermo: _extractVerificationThermo(refObj),
            hasObservation: _extractHasObservation(refObj) ? 'Oui' : 'Non',
          ),
        );
      }
    }

    void processCellulesAndTransfos(
      List<Cellule> cellules,
      List<TransformateurMTBT> transfos, {
      String zoneName = '',
      String localName = '',
    }) {
      for (final c in cellules) {
        final rep = c.getEffectiveRepere(localName);

        String equipNom = '';
        final rawNom = c.nom?.trim() ?? '';
        final isGenericNom = rawNom.isEmpty ||
            rawNom.toLowerCase() == 'présent' ||
            rawNom.toLowerCase() == 'present' ||
            rawNom.toLowerCase() == 'oui' ||
            rawNom.toLowerCase() == 'non' ||
            rawNom.toLowerCase() == 'cellule';

        if (!isGenericNom) {
          equipNom = rawNom;
        } else if (c.repere?.trim().isNotEmpty == true &&
            c.repere!.trim() != localName) {
          equipNom = c.repere!.trim();
        } else if (c.numerotation.trim().isNotEmpty) {
          equipNom = c.numerotation.trim().toLowerCase().contains('cellule')
              ? c.numerotation.trim()
              : 'Cellule ${c.numerotation.trim()}';
        } else if (c.fonction.trim().isNotEmpty) {
          equipNom = c.fonction.trim().toLowerCase().contains('cellule')
              ? c.fonction.trim()
              : 'Cellule ${c.fonction.trim()}';
        } else if (c.type.trim().isNotEmpty) {
          equipNom = c.type.trim().toLowerCase().contains('cellule')
              ? c.type.trim()
              : 'Cellule ${c.type.trim()}';
        } else if (rep.isNotEmpty) {
          equipNom = rep;
        } else {
          equipNom = 'Cellule';
        }

        addEquipement(
          refObj: c,
          zoneName: zoneName,
          localName: localName,
          repere: rep,
          nom: equipNom,
          type: 'Cellule',
          accessible: true,
        );
      }

      for (final t in transfos) {
        final rep = t.getEffectiveRepere(localName);

        String equipNom = '';
        final rawNom = t.nom?.trim() ?? '';
        final isGenericNom = rawNom.isEmpty ||
            rawNom == localName ||
            rawNom.toLowerCase() == 'présent' ||
            rawNom.toLowerCase() == 'present' ||
            rawNom.toLowerCase() == 'oui' ||
            rawNom.toLowerCase() == 'non' ||
            rawNom.toLowerCase() == 'transformateur';

        if (!isGenericNom) {
          equipNom = rawNom;
        } else if (t.repere?.trim().isNotEmpty == true &&
            t.repere!.trim() != localName) {
          equipNom = t.repere!.trim();
        } else if (t.puissanceAssignee.trim().isNotEmpty) {
          equipNom = 'Transformateur ${t.puissanceAssignee.trim()}';
        } else if (t.marqueAnnee.trim().isNotEmpty) {
          equipNom = 'Transformateur ${t.marqueAnnee.trim()}';
        } else if (t.typeTransformateur.trim().isNotEmpty) {
          equipNom = 'Transformateur ${t.typeTransformateur.trim()}';
        } else if (rep.isNotEmpty) {
          equipNom = rep;
        } else {
          equipNom = 'Transformateur';
        }

        addEquipement(
          refObj: t,
          zoneName: zoneName,
          localName: localName,
          repere: rep,
          nom: equipNom,
          type: 'Transformateur',
          accessible: true,
        );
      }
    }

    void processCoffretsMT(
      List<CoffretArmoire> coffrets, {
      String zoneName = '',
      String localName = '',
    }) {
      for (final coffret in coffrets) {
        final normType = _normalizeEquipementType(coffret.type, coffret.nom);
        // Explicitement : Seuls les coffrets de type Cellule ou Transformateur entrent en MT
        if (normType != null && (normType == 'Cellule' || normType == 'Transformateur')) {
          final rep = (coffret.repere != null && coffret.repere!.trim().isNotEmpty)
              ? coffret.repere!.trim()
              : '';
          final nom = coffret.nom.trim().isNotEmpty
              ? coffret.nom.trim()
              : (rep.isNotEmpty ? rep : normType);

          addEquipement(
            refObj: coffret,
            zoneName: zoneName,
            localName: localName,
            repere: rep,
            nom: nom,
            type: normType,
            accessible: coffret.accessible,
          );
        }
      }
    }

    // 1. Moyenne tension locaux directs (hors zone)
    for (final local in audit.moyenneTensionLocaux) {
      final locName = local.nom.trim();
      processCellulesAndTransfos(local.cellules, local.transformateurs, zoneName: '', localName: locName);
      processCoffretsMT(local.coffrets, zoneName: '', localName: locName);
    }

    // 2. Moyenne tension zones
    for (final zone in audit.moyenneTensionZones) {
      final zName = zone.nom.trim();
      processCoffretsMT(zone.coffrets, zoneName: zName, localName: '');

      for (final local in zone.locaux) {
        final locName = local.nom.trim();
        processCellulesAndTransfos(local.cellules, local.transformateurs, zoneName: zName, localName: locName);
        processCoffretsMT(local.coffrets, zoneName: zName, localName: locName);
      }
    }

    return list;
  }

  static List<PdfEquipementItem> collectEquipementsBT(
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? desc,
  ) {
    final list = <PdfEquipementItem>[];
    final seenHashes = <int>{};

    void addEquipement({
      required Object refObj,
      String zoneName = '',
      String localName = '',
      required String repere,
      required String nom,
      required String type,
      bool accessible = true,
      bool isMT = false,
    }) {
      final hash = identityHashCode(refObj);
      if (!seenHashes.contains(hash)) {
        seenHashes.add(hash);
        final equipNom = nom.trim().isNotEmpty
            ? nom.trim()
            : (repere.trim().isNotEmpty ? repere.trim() : type);
        list.add(
          PdfEquipementItem(
            zoneName: zoneName.trim(),
            localName: localName.trim(),
            repere: repere.trim(),
            nom: equipNom,
            type: type,
            isMT: isMT,
            accessible: accessible,
            presenceParafoudre: _extractPresenceParafoudre(refObj),
            verificationThermo: _extractVerificationThermo(refObj),
            hasObservation: _extractHasObservation(refObj) ? 'Oui' : 'Non',
          ),
        );
      }
    }

    void processCoffretsBT(
      List<CoffretArmoire> coffrets, {
      String zoneName = '',
      String localName = '',
    }) {
      for (final coffret in coffrets) {
        final normType = _normalizeEquipementType(coffret.type, coffret.nom);
        // Tout coffret de type BT (TGBT, Inverseur, Armoire, Coffret) est collecté dans la BT
        if (normType != null && normType != 'Cellule' && normType != 'Transformateur') {
          final rep = (coffret.repere != null && coffret.repere!.trim().isNotEmpty)
              ? coffret.repere!.trim()
              : '';
          final nom = coffret.nom.trim().isNotEmpty
              ? coffret.nom.trim()
              : (rep.isNotEmpty ? rep : normType);

          addEquipement(
            refObj: coffret,
            zoneName: zoneName,
            localName: localName,
            repere: rep,
            nom: nom,
            type: normType,
            accessible: coffret.accessible,
            isMT: false,
          );
        }
      }
    }

    if (audit != null) {
      // 1. Basse tension zones
      for (final zone in audit.basseTensionZones) {
        final zName = zone.nom.trim();
        processCoffretsBT(zone.coffretsDirects, zoneName: zName, localName: '');

        for (final local in zone.locaux) {
          final locName = local.nom.trim();
          processCoffretsBT(local.coffrets, zoneName: zName, localName: locName);
        }
      }

      // 2. Moyenne tension locaux & zones (Règle Métier : Équipements BT installés dans des locaux MT)
      for (final local in audit.moyenneTensionLocaux) {
        final locName = local.nom.trim();
        processCoffretsBT(local.coffrets, zoneName: '', localName: locName);
      }

      for (final zone in audit.moyenneTensionZones) {
        final zName = zone.nom.trim();
        processCoffretsBT(zone.coffrets, zoneName: zName, localName: '');

        for (final local in zone.locaux) {
          final locName = local.nom.trim();
          processCoffretsBT(local.coffrets, zoneName: zName, localName: locName);
        }
      }
    }

    return list;
  }

  static List<PdfUnknownSourceItem> collectEquipementsUnknownSource(
    AuditInstallationsElectriques? audit,
  ) {
    final list = <PdfUnknownSourceItem>[];
    if (audit == null) return list;

    final seenHashes = <int>{};

    void processCoffret(CoffretArmoire coffret, {String zoneName = '', String localName = ''}) {
      final hash = identityHashCode(coffret);
      if (seenHashes.contains(hash)) return;
      seenHashes.add(hash);

      final normType = _normalizeEquipementType(coffret.type, coffret.nom) ?? coffret.type;
      final rep = (coffret.repere != null && coffret.repere!.trim().isNotEmpty)
          ? coffret.repere!.trim()
          : '';
      final nom = coffret.nom.trim().isNotEmpty ? coffret.nom.trim() : (rep.isNotEmpty ? rep : '-');

      if (coffret.type == 'INVERSEUR') {
        if (coffret.alimentations.isNotEmpty &&
            coffret.alimentations[0].effectiveSourceKnown == 'Inconnue') {
          final s = coffret.alimentations[0].source.trim();
          list.add(
            PdfUnknownSourceItem(
              zoneName: zoneName.trim(),
              localName: localName.trim(),
              repere: rep,
              nom: nom,
              type: 'Inverseur',
              alimentationConcernee: (s.isNotEmpty && s.toLowerCase() != 'inconnu') ? s : 'Source non identifie',
              source: (s.isNotEmpty && s.toLowerCase() != 'inconnu') ? s : 'non identifie',
            ),
          );
        }
        if (coffret.alimentations.length > 1 &&
            coffret.alimentations[1].effectiveSourceKnown == 'Inconnue') {
          final s = coffret.alimentations[1].source.trim();
          list.add(
            PdfUnknownSourceItem(
              zoneName: zoneName.trim(),
              localName: localName.trim(),
              repere: rep,
              nom: nom,
              type: 'Inverseur',
              alimentationConcernee: (s.isNotEmpty && s.toLowerCase() != 'inconnu') ? s : 'Source non identifie',
              source: (s.isNotEmpty && s.toLowerCase() != 'inconnu') ? s : 'non identifie',
            ),
          );
        }
      } else {
        bool isUnknown = false;
        for (final a in coffret.alimentations) {
          if (a.effectiveSourceKnown == 'Inconnue') {
            isUnknown = true;
            break;
          }
        }
        if (isUnknown) {
          list.add(
            PdfUnknownSourceItem(
              zoneName: zoneName.trim(),
              localName: localName.trim(),
              repere: rep,
              nom: nom,
              type: normType,
              alimentationConcernee: 'Source d\'alimentation',
              source: 'non identifie',
            ),
          );
        }
      }
    }

    for (final local in audit.moyenneTensionLocaux) {
      final locName = local.nom != null ? local.nom.toString().trim() : '';
      for (final coffret in local.coffrets) {
        processCoffret(coffret, zoneName: '', localName: locName);
      }
    }

    for (final zone in audit.moyenneTensionZones) {
      final zName = zone.nom.trim();
      for (final coffret in zone.coffrets) {
        processCoffret(coffret, zoneName: zName, localName: '');
      }
      for (final local in zone.locaux) {
        final locName = local.nom != null ? local.nom.toString().trim() : '';
        for (final coffret in local.coffrets) {
          processCoffret(coffret, zoneName: zName, localName: locName);
        }
      }
    }

    for (final zone in audit.basseTensionZones) {
      final zName = zone.nom.trim();
      for (final coffret in zone.coffretsDirects) {
        processCoffret(coffret, zoneName: zName, localName: '');
      }
      for (final local in zone.locaux) {
        final locName = local.nom.trim();
        for (final coffret in local.coffrets) {
          processCoffret(coffret, zoneName: zName, localName: locName);
        }
      }
    }

    return list;
  }

  static List<pw.Widget> buildUnknownSourcesTable(
    List<PdfUnknownSourceItem> items, {
    int startNumber = 1,
    bool showTableHeader = true,
  }) {
    if (items.isEmpty) return [];

    final headers = [
      'Zone',
      'Repère',
      'N°',
      'Désignation',
      'Type',
      'Source',
    ];

    final columnWidths = const {
      0: pw.FlexColumnWidth(1.2), // Zone
      1: pw.FlexColumnWidth(1.6), // Repère
      2: pw.FixedColumnWidth(34), // N°
      3: pw.FlexColumnWidth(2.5), // Équipement
      4: pw.FlexColumnWidth(1.8), // Type
      5: pw.FlexColumnWidth(2.0), // Source
    };

    final zoneGroups = <PdfUnknownSourceZoneGroup>[];
    for (final item in items) {
      final normZone = item.zoneName.trim();
      final normLoc = item.localName.trim();

      var zGroup = zoneGroups.firstWhere(
        (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
        orElse: () {
          final zg = PdfUnknownSourceZoneGroup(zoneName: normZone, repereGroups: []);
          zoneGroups.add(zg);
          return zg;
        },
      );

      var rGroup = zGroup.repereGroups.firstWhere(
        (rg) => rg.localName.toLowerCase() == normLoc.toLowerCase(),
        orElse: () {
          final rg = PdfUnknownSourceRepereGroup(localName: normLoc, items: []);
          zGroup.repereGroups.add(rg);
          return rg;
        },
      );

      rGroup.items.add(item);
    }

    final allTableRows = <pw.TableRow>[];

    if (showTableHeader) {
      allTableRows.add(
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: headers
              .map(
                (h) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    int globalRowIndex = 0;
    int globalEquipementNumber = startNumber;

    for (final zoneGroup in zoneGroups) {
      final totalZoneItems =
          zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.items.length);
      final zoneMidIndex = (totalZoneItems - 1) ~/ 2;

      int zoneItemIndex = 0;

      for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
        final repereGroup = zoneGroup.repereGroups[rIdx];
        final repereCount = repereGroup.items.length;
        final repereMidIndex = (repereCount - 1) ~/ 2;
        final isLastRepereInZone = (rIdx == zoneGroup.repereGroups.length - 1);

        for (int i = 0; i < repereCount; i++) {
          final item = repereGroup.items[i];
          final currentZoneItemIdx = zoneItemIndex++;
          final currentRepereItemIdx = i;

          final currentNum = globalEquipementNumber++;
          final idx = globalRowIndex++;
          final isEven = idx % 2 == 0;
          final bgColor = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB);

          final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
          final isStartOfRepere = (currentRepereItemIdx == 0 && currentZoneItemIdx > 0);

          final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
          final isEndOfRepere = (currentRepereItemIdx == repereCount - 1);

          final zoneBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : pw.BorderSide.none,
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : pw.BorderSide.none,
          );

          final repereBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isStartOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isEndOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
          );

          final itemBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isStartOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isEndOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4)),
          );

          final rawSource = item.source.trim();
          final sourceDisplay = (rawSource.isEmpty ||
                  rawSource.toLowerCase().contains('inconn') ||
                  rawSource.toLowerCase().contains('inconnu'))
              ? 'non identifie'
              : rawSource;

          final displayRepere = repereGroup.localName.isNotEmpty
              ? repereGroup.localName
              : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '');

          allTableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: bgColor),
              children: [
                // Cellule 0 : Zone
                PdfReportStyles.buildGroupedCellWidget(
                  currentIndex: currentZoneItemIdx,
                  totalRows: totalZoneItems,
                  text: zoneGroup.zoneName,
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                  border: zoneBorder,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),

                // Cellule 1 : Repère
                PdfReportStyles.buildGroupedCellWidget(
                  currentIndex: currentRepereItemIdx,
                  totalRows: repereCount,
                  text: displayRepere,
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                  border: repereBorder,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                ),

                // Cellule 2 : N° d'équipement
                pw.Container(
                  decoration: pw.BoxDecoration(border: itemBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '$currentNum',
                    style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Cellule 3 : Équipement (Nom)
                pw.Container(
                  decoration: pw.BoxDecoration(border: itemBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    item.nom,
                    style: pw.TextStyle(font: fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Cellule 4 : Type
                pw.Container(
                  decoration: pw.BoxDecoration(border: itemBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    item.type,
                    style: pw.TextStyle(font: fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Cellule 5 : Source
                pw.Container(
                  decoration: pw.BoxDecoration(border: itemBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    sourceDisplay,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: fsSmall,
                      color: PdfColor.fromInt(0xFFC62828),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    return [
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: const pw.TableBorder(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          horizontalInside: pw.BorderSide.none,
        ),
        columnWidths: columnWidths,
        children: allTableRows,
      ),
    ];
  }

  static List<pw.Widget> buildEquipementsTable(
    List<PdfEquipementItem> items, {
    int startNumber = 1,
    bool showTableHeader = true,
    bool isMT = false,
  }) {
    if (items.isEmpty) {
      return [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            'Aucun équipement recensé.',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ];
    }

    final headers = isMT
        ? [
            'Zone',
            'Repère',
            'N°',
            'Désignation',
            'Type',
            'Vérifié',
            'Observation',
          ]
        : [
            'Zone',
            'Repère',
            'N°',
            'Désignation',
            'Type',
            'Vérifié',
            'Présence du parafoudre',
            'Vérification thermo',
            'Observation',
          ];

    final columnWidths = isMT
        ? const {
            0: pw.FlexColumnWidth(1.3), // Zone
            1: pw.FlexColumnWidth(1.6), // Repère
            2: pw.FixedColumnWidth(34), // N°
            3: pw.FlexColumnWidth(2.5), // Équipement (Nom)
            4: pw.FlexColumnWidth(1.6), // Type
            5: pw.FlexColumnWidth(1.1), // Vérifié
            6: pw.FlexColumnWidth(1.3), // Observation
          }
        : const {
            0: pw.FlexColumnWidth(1.2), // Zone
            1: pw.FlexColumnWidth(1.5), // Repère
            2: pw.FixedColumnWidth(34), // N°
            3: pw.FlexColumnWidth(2.2), // Équipement (Nom)
            4: pw.FlexColumnWidth(1.5), // Type
            5: pw.FlexColumnWidth(1.0), // Vérifié
            6: pw.FlexColumnWidth(1.3), // Présence du parafoudre
            7: pw.FlexColumnWidth(1.3), // Vérification thermo
            8: pw.FlexColumnWidth(1.3), // Observation
          };

    final zoneGroups = <PdfEquipementZoneGroup>[];
    for (final eq in items) {
      final normZone = eq.zoneName.trim();
      final normLoc = eq.localName.trim();

      var zGroup = zoneGroups.firstWhere(
        (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
        orElse: () {
          final zg = PdfEquipementZoneGroup(zoneName: normZone, repereGroups: []);
          zoneGroups.add(zg);
          return zg;
        },
      );

      var rGroup = zGroup.repereGroups.firstWhere(
        (rg) => rg.localName.toLowerCase() == normLoc.toLowerCase(),
        orElse: () {
          final rg = PdfEquipementRepereGroup(localName: normLoc, items: []);
          zGroup.repereGroups.add(rg);
          return rg;
        },
      );

      rGroup.items.add(eq);
    }

    final allTableRows = <pw.TableRow>[];

    if (showTableHeader) {
      allTableRows.add(
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: headers
              .map(
                (h) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    int globalRowIndex = 0;
    int globalEquipementNumber = startNumber;

    for (final zoneGroup in zoneGroups) {
      final totalZoneItems =
          zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.items.length);
      final zoneMidIndex = (totalZoneItems - 1) ~/ 2;

      int zoneItemIndex = 0;

      for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
        final repereGroup = zoneGroup.repereGroups[rIdx];
        final repereCount = repereGroup.items.length;
        final repereMidIndex = (repereCount - 1) ~/ 2;
        final isLastRepereInZone = (rIdx == zoneGroup.repereGroups.length - 1);

        for (int i = 0; i < repereCount; i++) {
          final eq = repereGroup.items[i];
          final currentZoneItemIdx = zoneItemIndex++;
          final currentRepereItemIdx = i;

          final currentEqNum = globalEquipementNumber++;
          final idx = globalRowIndex++;
          final isEven = idx % 2 == 0;
          final bg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB);

          final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
          final isStartOfRepere = (currentRepereItemIdx == 0 && currentZoneItemIdx > 0);

          final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
          final isEndOfRepere = (currentRepereItemIdx == repereCount - 1);

          final zoneBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : pw.BorderSide.none,
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : pw.BorderSide.none,
          );

          final repereBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isStartOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isEndOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
          );

          final itemBorder = pw.Border(
            top: isStartOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isStartOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : pw.BorderSide.none),
            bottom: isEndOfZone
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                : (isEndOfRepere
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                    : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4)),
          );

          final rowCells = <pw.Widget>[
            // Cellule 0 : Zone
            PdfReportStyles.buildGroupedCellWidget(
              currentIndex: currentZoneItemIdx,
              totalRows: totalZoneItems,
              text: zoneGroup.zoneName,
              style: pw.TextStyle(font: fontBold, fontSize: 8.5),
              border: zoneBorder,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),

            // Cellule 1 : Repère
            PdfReportStyles.buildGroupedCellWidget(
              currentIndex: currentRepereItemIdx,
              totalRows: repereCount,
              text: repereGroup.localName.isNotEmpty
                  ? repereGroup.localName
                  : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : ''),
              style: pw.TextStyle(font: fontBold, fontSize: 8.5),
              border: repereBorder,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),

            // Cellule 2 : N° de l'équipement
            pw.Container(
              decoration: pw.BoxDecoration(border: itemBorder),
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '$currentEqNum',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Cellule 3 : Équipement (Nom)
            pw.Container(
              decoration: pw.BoxDecoration(border: itemBorder),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                eq.nom.isNotEmpty ? eq.nom : '-',
                style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Cellule 4 : Type
            pw.Container(
              decoration: pw.BoxDecoration(border: itemBorder),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                eq.type.isNotEmpty ? eq.type : 'Équipement',
                style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Cellule 5 : Vérifié
            pw.Container(
              decoration: pw.BoxDecoration(
                color: eq.accessible ? PdfReportStyles.conformeColor : PdfReportStyles.nonConformeColor,
                border: itemBorder,
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                eq.accessible ? 'Oui' : 'Non',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];

          if (!isMT) {
            // Cellule 6 : Présence du parafoudre (BT uniquement)
            rowCells.add(
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: eq.presenceParafoudre == 'Oui'
                      ? PdfReportStyles.conformeColor
                      : (eq.presenceParafoudre == 'Non' ? PdfReportStyles.nonConformeColor : bg),
                  border: itemBorder,
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  eq.presenceParafoudre ?? '-',
                  style: pw.TextStyle(
                    font: eq.presenceParafoudre != null ? fontBold : fontRegular,
                    fontSize: 8.5,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );

            // Cellule 7 : Vérification thermo (BT uniquement)
            rowCells.add(
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: eq.verificationThermo == 'Oui'
                      ? PdfReportStyles.conformeColor
                      : (eq.verificationThermo == 'Non' ? PdfReportStyles.nonConformeColor : bg),
                  border: itemBorder,
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  eq.verificationThermo ?? '-',
                  style: pw.TextStyle(
                    font: eq.verificationThermo != null ? fontBold : fontRegular,
                    fontSize: 8.5,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
          }

          // Cellule Observation (Dernière cellule pour MT et BT)
          rowCells.add(
            pw.Container(
              decoration: pw.BoxDecoration(
                color: eq.hasObservation == 'Oui'
                    ? PdfReportStyles.nonConformeColor
                    : (eq.hasObservation == 'Non' ? PdfReportStyles.conformeColor : bg),
                border: itemBorder,
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                eq.hasObservation,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );

          allTableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: rowCells,
            ),
          );
        }
      }
    }

    return [
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: const pw.TableBorder(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          horizontalInside: pw.BorderSide.none,
        ),
        columnWidths: columnWidths,
        children: allTableRows,
      ),
    ];
  }

  }
