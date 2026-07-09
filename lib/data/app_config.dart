/// Identifiant du classeur Google Sheet "SAV diffus".
///
/// Placeholder en attendant l'ID réel fourni par l'utilisateur. Peut être
/// surchargé au build via `--dart-define=SAV_SPREADSHEET_ID=...`.
const String kSavSpreadsheetId = String.fromEnvironment(
  'SAV_SPREADSHEET_ID',
  defaultValue: '1HRn7SEUkqnHbJgsdmNZp2yOsoK6P5SikJZ5PGgr6fUI',
);

/// Nom de l'onglet contenant les lignes de SAV.
const String kSavSheetName = 'SAV diffus';

/// Seuls ces comptes peuvent se connecter à l'application (accès nominatif,
/// pas tout le domaine @rpimenuiserie.com).
const Set<String> kAllowedEmails = {
  'cyril.chaumeil@rpimenuiserie.com',
  'joel.pouvereau@rpimenuiserie.com',
  'admin@rpimenuiserie.com',
};

/// Durée par défaut (en minutes) appliquée à l'événement Calendar quand la
/// "durée prévue" saisie par Joël n'est pas dans un format reconnu.
const int kDefaultInterventionDurationMinutes = 60;

/// Mapping des colonnes du Google Sheet "SAV diffus" (voir section 3 du doc
/// de lancement). Les lettres de colonnes sont converties en index 0-based
/// par [SavColumns.indexOf].
class SavColumns {
  static const String numeroSav = 'A';
  static const String quiOuvre = 'D';
  static const String nomClient = 'E';
  static const String refChantier = 'F';
  static const String probleme = 'I';

  /// Colonne "Choix livraison" : commentaire libre saisi par les
  /// commerciaux. Affiché à titre informatif ; ce n'est PAS le signal fiable
  /// pour savoir si le SAV est confié à Joël (voir le surlignage rose de la
  /// ligne, détecté via la couleur de fond dans GoogleSheetsService).
  static const String affecteA = 'L';
  static const String statutSav = 'O';
  static const String fournitures = 'Q';
  static const String etatSav = 'U';
  static const String interventionARealiser = 'Z';
  static const String clientFinal = 'AF';
  static const String adresseIntervention = 'AG';
  static const String telephone = 'AH';
  static const String dureeIntervention = 'AA';
  static const String vehicule = 'AB';
  static const String renfort = 'AC';
  static const String dateIntervention = 'AD';
  static const String heureIntervention = 'AE';

  /// Colonne technique invisible pour Joël, utilisée comme clé de
  /// correspondance fiable pour retrouver une ligne (au lieu de son index).
  static const String idGoogle = 'ID_GOOGLE';

  static const String statutAccepte = 'Accepté';
  static const String etatPretPourIntervention = 'Prêt pour intervention';

  /// Valeur de [etatSav] indiquant un SAV clôturé, à exclure de la liste.
  static const String etatCloture = 'Cloturé';

  /// Convertit une référence de colonne façon Sheet ("A", "Z", "AA", "AB"…)
  /// en index 0-based.
  static int indexOf(String columnLetters) {
    var index = 0;
    for (final rune in columnLetters.toUpperCase().runes) {
      index = index * 26 + (rune - 'A'.codeUnitAt(0) + 1);
    }
    return index - 1;
  }
}
