import 'package:flutter_test/flutter_test.dart';

import 'package:rpi_sav_app/data/app_config.dart';
import 'package:rpi_sav_app/models/sav_intervention.dart';

SavIntervention _buildIntervention({
  String statutSav = 'Accepté',
  String dateIntervention = '',
  String heureIntervention = '',
}) {
  return SavIntervention(
    idGoogle: 'QK7-M2X9',
    rowIndex: 12,
    numeroSav: '36107-01P',
    quiOuvre: 'Cyril',
    nomClient: 'DUCOLOMB',
    refChantier: 'SALN/SEJ',
    probleme: 'Fenêtre bloquée',
    affecteA: 'Joel',
    statutSav: statutSav,
    fournitures: '',
    etatSav: '',
    interventionARealiser: 'Changer les ouvrants',
    clientFinal: 'Client final - Adresse - Tel',
    dateIntervention: dateIntervention,
    heureIntervention: heureIntervention,
  );
}

void main() {
  group('SavHeaderIndex', () {
    test('retrouve une colonne par un fragment de son en-tête', () {
      final headerIndex = SavHeaderIndex([
        'N°SAV',
        "Durée d'intervention prévue",
        'Véhicule pour livraison',
        '# de personnes supplémentaires nécessaires',
      ]);
      expect(headerIndex.indexOf(SavColumns.numeroSav), 0);
      expect(headerIndex.indexOf(SavColumns.dureeIntervention), 1);
      expect(headerIndex.indexOf(SavColumns.vehicule), 2);
      expect(headerIndex.indexOf(SavColumns.renfort), 3);
      expect(headerIndex.letterOf(SavColumns.vehicule), 'C');
    });

    test('reste valide si une colonne est insérée avant les autres', () {
      final headerIndex = SavHeaderIndex([
        'N°SAV',
        'Nouvelle colonne',
        "Durée d'intervention prévue",
        'Véhicule pour livraison',
      ]);
      expect(headerIndex.letterOf(SavColumns.dureeIntervention), 'C');
      expect(headerIndex.letterOf(SavColumns.vehicule), 'D');
    });

    test('indexOf renvoie -1 pour une colonne introuvable', () {
      final headerIndex = SavHeaderIndex(['N°SAV']);
      expect(headerIndex.indexOf(SavColumns.vehicule), -1);
      expect(() => headerIndex.letterOf(SavColumns.vehicule), throwsStateError);
    });
  });

  group('SavIntervention.isAccepte', () {
    test('vrai quand le statut correspond exactement à "Accepté"', () {
      expect(_buildIntervention(statutSav: 'Accepté').isAccepte, isTrue);
    });

    test('faux pour un autre statut', () {
      expect(_buildIntervention(statutSav: 'Refusé').isAccepte, isFalse);
    });

    test('tolère les espaces autour de la valeur', () {
      expect(_buildIntervention(statutSav: '  Accepté  ').isAccepte, isTrue);
    });
  });

  group('SavIntervention.isPlanned', () {
    test('faux si date et heure sont vides', () {
      expect(_buildIntervention().isPlanned, isFalse);
    });

    test('faux si seule la date est renseignée', () {
      expect(
        _buildIntervention(dateIntervention: '11/07/2026').isPlanned,
        isFalse,
      );
    });

    test('faux si seule l\'heure est renseignée', () {
      expect(
        _buildIntervention(heureIntervention: '09h30').isPlanned,
        isFalse,
      );
    });

    test('vrai si date et heure sont toutes les deux renseignées', () {
      expect(
        _buildIntervention(
          dateIntervention: '11/07/2026',
          heureIntervention: '09h30',
        ).isPlanned,
        isTrue,
      );
    });
  });

  group('SavIntervention.plannedDate', () {
    test('parse une date au format dd/MM/yyyy', () {
      final date = _buildIntervention(
        dateIntervention: '11/07/2026',
      ).plannedDate;
      expect(date, DateTime(2026, 7, 11));
    });

    test('retourne null si la date est vide', () {
      expect(_buildIntervention().plannedDate, isNull);
    });

    test('retourne null pour un format non reconnu', () {
      expect(
        _buildIntervention(dateIntervention: 'pas une date').plannedDate,
        isNull,
      );
    });
  });

  group('SavIntervention.copyWithPlanning', () {
    test('met à jour uniquement les champs de planification', () {
      final original = _buildIntervention();
      final planned = original.copyWithPlanning(
        dureeIntervention: '2h',
        vehicule: 'Fourgon Joël',
        renfort: '1',
        dateIntervention: '11/07/2026',
        heureIntervention: '09h30',
      );

      expect(planned.dureeIntervention, '2h');
      expect(planned.vehicule, 'Fourgon Joël');
      expect(planned.renfort, '1');
      expect(planned.dateIntervention, '11/07/2026');
      expect(planned.heureIntervention, '09h30');
      // Les autres champs restent identiques à l'intervention d'origine.
      expect(planned.numeroSav, original.numeroSav);
      expect(planned.idGoogle, original.idGoogle);
      expect(planned.rowIndex, original.rowIndex);
    });
  });
}
