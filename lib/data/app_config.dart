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

/// Reflète `version:` dans pubspec.yaml — à garder synchronisé manuellement,
/// affiché dans le monitoring admin pour vérifier que tout le monde a bien
/// rechargé la dernière version.
const String kAppVersion = '1.0.0+1';

/// Durée par défaut (en minutes) appliquée à l'événement Calendar quand la
/// "durée prévue" saisie par Joël n'est pas dans un format reconnu.
const int kDefaultInterventionDurationMinutes = 60;

/// Calendrier dont on lit les disponibilités pour la visu dans l'écran de
/// planification — même calendrier que celui utilisé côté Apps Script
/// (CONFIG.IDS.CALENDAR) pour la création effective des RDV.
const String kJoelCalendarId = 'joel.pouvereau@rpimenuiserie.com';

/// Regroupe les codes postaux de l'agglomération bordelaise (et sa
/// périphérie proche) dans une même "zone", pour la suggestion "Joël est
/// déjà dans le secteur" : deux communes limitrophes (ex. Pessac 33600 et
/// Mérignac 33700) ont des codes postaux différents mais sont à quelques
/// minutes l'une de l'autre. Alternative gratuite à une vraie distance GPS
/// (qui nécessiterait l'API Geocoding, payante au-delà du quota gratuit et
/// donc écartée). Un code postal absent de cette table n'est comparé qu'à
/// lui-même (comportement d'origine, pas de zone élargie).
///
/// À compléter à la main si RPI intervient régulièrement dans un autre
/// secteur (liste non exhaustive, centrée sur Bordeaux Métropole).
const Map<String, String> kPostalCodeZones = {
  // Bordeaux intra-muros
  '33000': 'bordeaux-metropole',
  '33100': 'bordeaux-metropole',
  '33200': 'bordeaux-metropole',
  '33300': 'bordeaux-metropole',
  '33800': 'bordeaux-metropole',
  // Rive gauche / périphérie proche
  '33600': 'bordeaux-metropole', // Pessac
  '33700': 'bordeaux-metropole', // Mérignac
  '33400': 'bordeaux-metropole', // Talence
  '33170': 'bordeaux-metropole', // Gradignan
  '33130': 'bordeaux-metropole', // Bègles
  '33140': 'bordeaux-metropole', // Villenave-d'Ornon
  '33610': 'bordeaux-metropole', // Cestas / Canéjan
  '33185': 'bordeaux-metropole', // Le Haillan
  '33127': 'bordeaux-metropole', // Saint-Jean-d'Illac
  // Rive droite / périphérie proche
  '33150': 'bordeaux-metropole', // Cenon
  '33310': 'bordeaux-metropole', // Lormont
  '33270': 'bordeaux-metropole', // Floirac
  '33370': 'bordeaux-metropole', // Artigues / Tresses / Yvrac
  // Nord Bordeaux
  '33520': 'bordeaux-metropole', // Bruges
  '33110': 'bordeaux-metropole', // Le Bouscat
  '33320': 'bordeaux-metropole', // Eysines
  '33290': 'bordeaux-metropole', // Blanquefort
  '33160': 'bordeaux-metropole', // Saint-Médard-en-Jalles / Le Taillan-Médoc
};

/// Résout la zone d'un code postal (voir [kPostalCodeZones]) — retourne le
/// code lui-même s'il n'est répertorié dans aucune zone.
String postalCodeZone(String postalCode) =>
    kPostalCodeZones[postalCode] ?? postalCode;

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
