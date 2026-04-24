// lib/services/normative_reference_service.dart
import 'package:flutter/material.dart';

class NormativeReferenceService {
  // Map des références normatives par libellé de point de vérification
  static const Map<String, String> _normativeReferences = {
    'Emplacement / Dégagement autour': 'Norme NF C 15-100 art 421-422',
    'Protection IP/IK adaptée au local d\'installation': 'Norme NF C 15-100 art 512-522',
    'Etat du coffret / Armoire': 'Norme NF C 15-100 art 435',
    'Identification complète des circuits': 'Norme NF C 15-100 art 514.1',
    'Protection contre les contacts directs (capots, caches, bornes protégées)': 'Norme NF C 15-100 art. 411',
    'Présence et fonctionnement des dispositifs de coupure / arrêt d\'urgence': 'Norme NF C 15-100 art 463-536',
    'Présence et fonctionnement des dispositifs de protection': 'Norme NF C 15-100 art 430-533',
    'Câblage': 'Norme NF C 15-100 art 462-536',
    'Dispositif de connexion': 'Norme NF C 15-100 art 526-555',
    'Répartiteur de circuit': 'Norme NF C 15-100 art 435',
    'Répartition des circuits': 'Norme NF C 15-100 art 462-536',
    'Adéquation des dispositifs de protection': 'Norme NF C 15-100 art 430-533',
    'Section des câbles d\'alimentation adaptée au courant nominal des disjoncteurs associés': 'Norme NF C 15-100 art 523',
    'Section des câbles de départs adaptée au courant nominal des disjoncteurs associés': 'Norme NF C 15-100 art 523',
    'Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)': 'Norme NF C 15-100 art 531',
    'Coordination entre disjoncteurs et contacteurs': 'Norme NF C 15-100 art 435',
    'Coordination entre disjoncteurs': 'Norme NF C 15-100 art 435',
    'Protection contre les contacts indirects': 'Norme NF C 15-100 art 531',
    'Sélectivité et coordination des protections (montée sélective des calibres)': 'Norme NF C 15-100 art 435',
    'Continuité du conducteur de protection (PE)': 'Norme NF C 15-100 art 526-555',
    'Respect code couleur des câbles': 'Norme NF C 15-100 art 514.3',
    'Présence de double alimentation électrique': 'Norme NF C 15-100 art 612',
  };

  /// Récupère la référence normative pour un point de vérification donné
  static String? getReferenceForPoint(String pointVerification) {
    return _normativeReferences[pointVerification];
  }

  /// Vérifie si un point a une référence normative
  static bool hasReference(String pointVerification) {
    return _normativeReferences.containsKey(pointVerification);
  }
}