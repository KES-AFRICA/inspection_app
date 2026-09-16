// lib/services/regulatory_classification_service.dart

/// Entité immuable représentant une option de Type pour un classement réglementaire.
class RegulatoryTypeOption {
  final String code;
  final String description;

  const RegulatoryTypeOption({
    required this.code,
    required this.description,
  });

  /// Titre formaté pour l'affichage (ex: "Type J", "GHA", "Usines, Ateliers...")
  String get displayTitle => code;
}

/// Entité immuable représentant une option de Catégorie pour un classement réglementaire.
class RegulatoryCategoryOption {
  final String title;
  final String description;

  const RegulatoryCategoryOption({
    required this.title,
    required this.description,
  });

  String get code => title;
  String get displayTitle => title;
}

/// Source unique de vérité et moteur fonctionnel pour les classements réglementaires,
/// types et catégories d'établissements.
class RegulatoryClassificationService {
  // Constantes des 4 classements officiels autorisés
  static const String installationsClassees = 'Installations classées';
  static const String igh = 'IGH';
  static const String erpGeneraux = 'ERP Établissements Généraux';
  static const String erpSpecialises = 'ERP Établissements Spécialisés';

  /// Liste immuable des classements réglementaires officiels
  static const List<String> classifications = [
    installationsClassees,
    igh,
    erpGeneraux,
    erpSpecialises,
  ];

  // Types pour « Installations classées »
  static const List<RegulatoryTypeOption> _installationsClasseesTypes = [
    RegulatoryTypeOption(
      code: 'Usines, Ateliers, Dépôts, Chantiers',
      description: 'Usines, Ateliers, Dépôts, Chantiers',
    ),
  ];

  // Types pour « IGH »
  static const List<RegulatoryTypeOption> _ighTypes = [
    RegulatoryTypeOption(
      code: 'GHA',
      description: 'pour les immeubles à usage d’habitation',
    ),
    RegulatoryTypeOption(
      code: 'GHO',
      description: 'pour les immeubles à usage d’hôtel',
    ),
    RegulatoryTypeOption(
      code: 'GHR',
      description: 'pour les immeubles à usage d’enseignement',
    ),
    RegulatoryTypeOption(
      code: 'GHS',
      description: 'pour les immeubles à usage de dépôt d’archives',
    ),
    RegulatoryTypeOption(
      code: 'GHU',
      description: 'pour les immeubles à usage sanitaire',
    ),
    RegulatoryTypeOption(
      code: 'GHW1',
      description:
          'pour les immeubles à usage de bureaux de hauteur caractéristique supérieure à 25 m et au plus égale à 50 m',
    ),
    RegulatoryTypeOption(
      code: 'GHW2',
      description:
          'pour les immeubles à usage de bureaux de hauteur caractéristique supérieure à 50 m',
    ),
    RegulatoryTypeOption(
      code: 'GHZ',
      description: 'pour les immeubles à usage mixte',
    ),
  ];

  // Types pour « ERP Établissements Généraux »
  static const List<RegulatoryTypeOption> _erpGenerauxTypes = [
    RegulatoryTypeOption(
      code: 'Type J',
      description:
          'Structures d’accueil pour personnes âgées et personnes handicapées.',
    ),
    RegulatoryTypeOption(
      code: 'Type L',
      description:
          'Salles d’audition, de conférences, de réunions, de spectacles ou à usage multiple.',
    ),
    RegulatoryTypeOption(
      code: 'Type M',
      description: 'Magasins de vente, centres commerciaux.',
    ),
    RegulatoryTypeOption(
      code: 'Type N',
      description: 'Restaurants et débits de boisson.',
    ),
    RegulatoryTypeOption(
      code: 'Type O',
      description: 'Hôtels et pensions de famille.',
    ),
    RegulatoryTypeOption(
      code: 'Type P',
      description: 'Salles de danse et salles de jeux.',
    ),
    RegulatoryTypeOption(
      code: 'Type R',
      description:
          'Etablissements d’éveil, d’enseignement, de formation, centres de vacances, centres de loisir sans hébergement.',
    ),
    RegulatoryTypeOption(
      code: 'Type S',
      description:
          'Bibliothèques, centres de documentation et de consultation d’archives.',
    ),
    RegulatoryTypeOption(
      code: 'Type T',
      description: 'Salles d’exposition.',
    ),
    RegulatoryTypeOption(
      code: 'Type U',
      description: 'Etablissements de soins.',
    ),
    RegulatoryTypeOption(
      code: 'Type V',
      description: 'Etablissements du culte.',
    ),
    RegulatoryTypeOption(
      code: 'Type W',
      description: 'Administrations, banques, bureaux.',
    ),
    RegulatoryTypeOption(
      code: 'Type X',
      description: 'Etablissements sportifs couverts.',
    ),
    RegulatoryTypeOption(
      code: 'Type Y',
      description: 'Musée',
    ),
  ];

  // Types pour « ERP Établissements Spécialisés »
  static const List<RegulatoryTypeOption> _erpSpecialisesTypes = [
    RegulatoryTypeOption(
      code: 'Type PA',
      description: 'Etablissements de plein air',
    ),
    RegulatoryTypeOption(
      code: 'Type CTS',
      description: 'Chapiteaux, tentes et structures',
    ),
    RegulatoryTypeOption(
      code: 'Type SG',
      description: 'Structures gonflables',
    ),
    RegulatoryTypeOption(
      code: 'Type PS',
      description: 'Parcs de stationnement couverts',
    ),
    RegulatoryTypeOption(
      code: 'Type GA',
      description: 'Gares',
    ),
    RegulatoryTypeOption(
      code: 'Type OA',
      description: 'Hôtels et restaurants d’altitude',
    ),
    RegulatoryTypeOption(
      code: 'EF',
      description: 'Etablissements flottants',
    ),
    RegulatoryTypeOption(
      code: 'REF',
      description: 'Refuges de montagne',
    ),
  ];

  // Catégories ERP (communes pour ERP Généraux et ERP Spécialisés)
  static const List<RegulatoryCategoryOption> _erpCategories = [
    RegulatoryCategoryOption(
      title: 'Première catégorie',
      description: 'au-dessus de 1500 personnes ;',
    ),
    RegulatoryCategoryOption(
      title: 'Deuxième catégorie',
      description: 'de 701 à 1500 personnes ;',
    ),
    RegulatoryCategoryOption(
      title: 'Troisième catégorie',
      description: 'de 301 à 700 personnes ;',
    ),
    RegulatoryCategoryOption(
      title: 'Quatrième catégorie',
      description: '300 personnes au maximum et hors cinquième catégorie ;',
    ),
    RegulatoryCategoryOption(
      title: 'Cinquième catégorie',
      description:
          'lorsque l’effectif du public est inférieur aux valeurs que nous indiquerons par la suite.',
    ),
  ];

  /// Retourne les options de Type pour le classement donné
  static List<RegulatoryTypeOption> getTypesForClassification(
      String? classification) {
    if (classification == null) return const [];
    switch (classification.trim()) {
      case installationsClassees:
        return _installationsClasseesTypes;
      case igh:
        return _ighTypes;
      case erpGeneraux:
        return _erpGenerauxTypes;
      case erpSpecialises:
        return _erpSpecialisesTypes;
      default:
        return const [];
    }
  }

  /// Retourne les options de Catégorie pour le classement donné
  static List<RegulatoryCategoryOption> getCategoriesForClassification(
      String? classification) {
    if (classification == null) return const [];
    switch (classification.trim()) {
      case erpGeneraux:
      case erpSpecialises:
        return _erpCategories;
      case installationsClassees:
      case igh:
      default:
        return const [];
    }
  }

  /// Indique si la catégorie est applicable pour le classement donné
  static bool isCategoryApplicable(String? classification) {
    if (classification == null) return false;
    final clean = classification.trim();
    return clean == erpGeneraux || clean == erpSpecialises;
  }

  /// Alias pour vérifier si un classement supporte les catégories
  static bool hasCategories(String? classification) => isCategoryApplicable(classification);

  /// Récupère l'option RegulatoryTypeOption pour un code/titre de type donné
  static RegulatoryTypeOption? getType(String? classification, String? typeCode) {
    if (typeCode == null || typeCode.trim().isEmpty) return null;
    final types = getTypesForClassification(classification);
    final normalized = normalizeTypeCode(typeCode).toLowerCase();
    for (final t in types) {
      if (normalizeTypeCode(t.code).toLowerCase() == normalized ||
          t.code.toLowerCase() == typeCode.trim().toLowerCase()) {
        return t;
      }
    }
    return null;
  }

  /// Récupère l'option RegulatoryCategoryOption pour un titre de catégorie donné
  static RegulatoryCategoryOption? getCategory(String? categoryTitle) {
    if (categoryTitle == null || categoryTitle.trim().isEmpty) return null;
    final normalized = normalizeCategoryTitle(categoryTitle).toLowerCase();
    for (final c in _erpCategories) {
      if (normalizeCategoryTitle(c.title).toLowerCase() == normalized ||
          c.title.toLowerCase() == categoryTitle.trim().toLowerCase()) {
        return c;
      }
    }
    return null;
  }

  /// Vérifie si un type correspond à une sélection utilisateur
  static bool isTypeMatching(String? classification, String code, String? selectedType) {
    if (selectedType == null) return false;
    return normalizeTypeCode(code).toLowerCase() == normalizeTypeCode(selectedType).toLowerCase();
  }

  /// Vérifie si une catégorie correspond à une sélection utilisateur
  static bool isCategoryMatching(String title, String? selectedCategory) {
    if (selectedCategory == null) return false;
    return normalizeCategoryTitle(title).toLowerCase() == normalizeCategoryTitle(selectedCategory).toLowerCase();
  }

  /// Vérifie si un code de Type est valide pour un classement donné
  static bool isTypeValid(String? classification, String? typeCode) {
    if (classification == null || typeCode == null || typeCode.trim().isEmpty) {
      return false;
    }
    final types = getTypesForClassification(classification);
    final normalized = normalizeTypeCode(typeCode);
    return types.any((t) =>
        normalizeTypeCode(t.code).toLowerCase() == normalized.toLowerCase());
  }

  /// Vérifie si une Catégorie est valide pour un classement donné
  static bool isCategoryValid(String? classification, String? categoryTitle) {
    if (classification == null ||
        categoryTitle == null ||
        categoryTitle.trim().isEmpty) {
      return false;
    }
    final categories = getCategoriesForClassification(classification);
    final normalized = normalizeCategoryTitle(categoryTitle);
    return categories.any((c) =>
        normalizeCategoryTitle(c.title).toLowerCase() ==
        normalized.toLowerCase());
  }

  /// Normalise le code d'un type (ex: "J" -> "Type J", "Type  J" -> "Type J")
  static String normalizeTypeCode(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    if (RegExp(r'^[A-Z]$').hasMatch(clean)) {
      return 'Type $clean';
    }
    return clean.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Normalise le titre d'une catégorie (ex: "1ère catégorie" -> "Première catégorie")
  static String normalizeCategoryTitle(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    final lower = clean.toLowerCase();
    if (lower.startsWith('1') || lower.contains('1ère') || lower.contains('premiere')) {
      return 'Première catégorie';
    }
    if (lower.startsWith('2') || lower.contains('2ème') || lower.contains('deuxieme')) {
      return 'Deuxième catégorie';
    }
    if (lower.startsWith('3') || lower.contains('3ème') || lower.contains('troisieme')) {
      return 'Troisième catégorie';
    }
    if (lower.startsWith('4') || lower.contains('4ème') || lower.contains('quatrieme')) {
      return 'Quatrième catégorie';
    }
    if (lower.startsWith('5') || lower.contains('5ème') || lower.contains('cinquieme')) {
      return 'Cinquième catégorie';
    }
    return clean;
  }

  /// Récupère la description associée à un Type pour un classement donné
  static String? getTypeDescription(String? classification, String? typeCode) {
    if (typeCode == null || typeCode.trim().isEmpty) return null;
    final types = classification != null
        ? getTypesForClassification(classification)
        : [
            ..._installationsClasseesTypes,
            ..._ighTypes,
            ..._erpGenerauxTypes,
            ..._erpSpecialisesTypes,
          ];
    final normalized = normalizeTypeCode(typeCode).toLowerCase();
    for (final t in types) {
      if (normalizeTypeCode(t.code).toLowerCase() == normalized) {
        return t.description;
      }
    }
    return null;
  }

  /// Récupère la description associée à une Catégorie pour un classement donné
  static String? getCategoryDescription(
      String? classification, String? categoryTitle) {
    if (categoryTitle == null || categoryTitle.trim().isEmpty) return null;
    if (classification != null && !isCategoryApplicable(classification)) {
      return null;
    }
    final normalized = normalizeCategoryTitle(categoryTitle).toLowerCase();
    for (final c in _erpCategories) {
      if (normalizeCategoryTitle(c.title).toLowerCase() == normalized) {
        return c.description;
      }
    }
    return null;
  }

  /// Inférence intelligente et déterministe du classement pour les missions historiques
  /// créées avant l'introduction du champ parent Classement réglementaire.
  static String? inferClassificationFromLegacy({
    String? currentClassification,
    String? type,
    String? category,
  }) {
    if (currentClassification != null &&
        classifications.contains(currentClassification.trim())) {
      return currentClassification.trim();
    }

    if (type != null && type.trim().isNotEmpty) {
      final cleanType = type.trim().toUpperCase();
      // IGH
      if (cleanType.startsWith('GH') ||
          _ighTypes.any((t) => t.code.toUpperCase() == cleanType)) {
        return igh;
      }
      // ERP Spécialisés
      if (cleanType.contains('PA') ||
          cleanType.contains('CTS') ||
          cleanType.contains('SG') ||
          cleanType.contains('PS') ||
          cleanType.contains('GA') ||
          cleanType.contains('OA') ||
          cleanType == 'EF' ||
          cleanType == 'REF') {
        return erpSpecialises;
      }
      // Installations classées
      if (cleanType.contains('USINE') ||
          cleanType.contains('ATELIER') ||
          cleanType.contains('DEPOT') ||
          cleanType.contains('CHANTIER')) {
        return installationsClassees;
      }
      // ERP Généraux par défaut pour les lettres J, L, M, N...
      return erpGeneraux;
    }

    if (category != null && category.trim().isNotEmpty) {
      return erpGeneraux;
    }

    return null;
  }
}
