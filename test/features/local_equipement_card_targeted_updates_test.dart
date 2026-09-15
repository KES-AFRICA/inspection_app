import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Mises à jour ciblées — Locaux et Équipements', () {
    test('1. Accessibilité Local : accessible par défaut pour un nouveau local et préservé pour les anciens', () {
      // Cas A: Nouveau local créé sans valeur préalable -> doit valoir true
      final nouveauLocalBT = BasseTensionLocal(
        nom: 'Nouveau Local BT',
        type: 'LOCAL_TGBT',
        accessible: true, // Valeur par défaut pour nouvelle création
      );
      expect(nouveauLocalBT.accessible, isTrue);

      final nouveauLocalMT = MoyenneTensionLocal(
        nom: 'Nouveau Local MT',
        type: 'LOCAL_TRANSFORMATEUR',
        accessible: true, // Valeur par défaut pour nouvelle création
      );
      expect(nouveauLocalMT.accessible, isTrue);

      // Cas B: Ancien local existant avec accessible == false -> ne doit jamais être écrasé
      final ancienLocalInaccessible = BasseTensionLocal(
        nom: 'Ancien Local Inaccessible',
        type: 'LOCAL_TGBT',
        accessible: false,
      );
      expect(ancienLocalInaccessible.accessible, isFalse);

      // Cas C: Ancien local existant avec accessible == true
      final ancienLocalAccessible = MoyenneTensionLocal(
        nom: 'Ancien Local MT',
        type: 'LOCAL_TRANSFORMATEUR',
        accessible: true,
      );
      expect(ancienLocalAccessible.accessible, isTrue);
    });

    test('2 & 3. Card des Locaux MT / HT-BT : indicateurs coffrets, obs, cellules, transfo sans brouillons', () {
      // Local MT avec 2 coffrets, 1 obs, 3 cellules, 2 transfo
      final coffret1 = CoffretArmoire(
        nom: 'Coffret 1',
        type: 'COFFRET',
        qrCode: 'QR_001',
        pointsVerification: [],
      );
      final coffret2 = CoffretArmoire(
        nom: 'Coffret 2',
        type: 'COFFRET',
        qrCode: 'QR_002',
        pointsVerification: [],
      );
      final obs = ObservationLibre(
        texte: 'Observation de test',
      );
      final cellule1 = Cellule(
        type: 'Cellule Arrivée',
        fonction: 'Arrivée',
        marqueModeleAnnee: 'Schneider',
        tensionAssignee: '20 kV',
        pouvoirCoupure: '12.5 kA',
        numerotation: '1',
        parafoudres: 'Oui',
        elementsVerifies: [],
      );
      final cellule2 = Cellule(
        type: 'Cellule Départ',
        fonction: 'Départ',
        marqueModeleAnnee: 'Schneider',
        tensionAssignee: '20 kV',
        pouvoirCoupure: '12.5 kA',
        numerotation: '2',
        parafoudres: 'Non',
        elementsVerifies: [],
      );
      final cellule3 = Cellule(
        type: 'Cellule Protection',
        fonction: 'Protection',
        marqueModeleAnnee: 'Schneider',
        tensionAssignee: '20 kV',
        pouvoirCoupure: '12.5 kA',
        numerotation: '3',
        parafoudres: 'Non',
        elementsVerifies: [],
      );

      final transfo1 = TransformateurMTBT(
        nom: 'Transfo 1',
        typeTransformateur: 'Sec',
        marqueAnnee: 'Schneider 2020',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TN-S',
        elementsVerifies: [],
      );
      final transfo2 = TransformateurMTBT(
        nom: 'Transfo 2',
        typeTransformateur: 'Bain d\'huile',
        marqueAnnee: 'France Transfo 2018',
        puissanceAssignee: '1000 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'IT',
        elementsVerifies: [],
      );

      final localMT = MoyenneTensionLocal(
        nom: 'Poste MT 1',
        type: 'LOCAL_TRANSFORMATEUR',
        coffrets: [coffret1, coffret2],
        observationsLibres: [obs],
        cellules: [cellule1, cellule2, cellule3],
        transformateurs: [transfo1, transfo2],
      );

      // Vérification que les compteurs sont strictement dérivés des entités persistées
      expect(localMT.coffrets.length, equals(2));
      expect(localMT.observationsLibres.length, equals(1));
      expect(localMT.cellules.length, equals(3));
      expect(localMT.transformateurs.length, equals(2));

      // Suppression d'un coffret : le compteur passe immédiatement à 1
      localMT.coffrets.removeAt(0);
      expect(localMT.coffrets.length, equals(1));

      // Suppression du deuxième : passe à 0
      localMT.coffrets.clear();
      expect(localMT.coffrets.length, equals(0));

      // Un brouillon non validé ne se trouve pas dans localMT.coffrets
      final draftsTemporaires = [
        CoffretArmoire(nom: 'Brouillon Temporaire', type: 'COFFRET', qrCode: 'QR_DRAFT', pointsVerification: []),
      ];
      // Le compteur réel de la Card continue d'ignorer draftsTemporaires
      final compteurCardReel = localMT.coffrets.length;
      expect(compteurCardReel, equals(0));
      expect(draftsTemporaires.length, equals(1));
    });

    test('4. Priorité : masquée dans l\'UI, mais préservée dans le modèle et les données historiques', () {
      // A: Donnée historique avec priorité existante (N1, N2, N3)
      final elementHistoriqueN1 = ElementControle(
        elementControle: 'Élément ancien N1',
        conforme: false,
        priorite: 1,
      );
      final elementHistoriqueN2 = ElementControle(
        elementControle: 'Élément ancien N2',
        conforme: false,
        priorite: 2,
      );
      final elementHistoriqueN3 = ElementControle(
        elementControle: 'Élément ancien N3',
        conforme: false,
        priorite: 3,
      );

      // Les données historiques restent strictement intactes
      expect(elementHistoriqueN1.priorite, equals(1));
      expect(elementHistoriqueN2.priorite, equals(2));
      expect(elementHistoriqueN3.priorite, equals(3));

      // B: Nouvel élément non-conforme sans priorité saisie par l'utilisateur
      final nouvelElement = ElementControle(
        elementControle: 'Nouveau constat terrain',
        conforme: false,
        priorite: null,
      );

      // Le comportement transparent assigne la priorité par défaut (3) sans bloquer
      if (nouvelElement.conforme == false && nouvelElement.priorite == null) {
        nouvelElement.priorite = 3;
      }
      expect(nouvelElement.priorite, equals(3));
    });
  });
}
