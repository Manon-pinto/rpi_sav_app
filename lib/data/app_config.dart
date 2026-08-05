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
/// de lancement). Chaque constante est un fragment (unique) du texte d'en-tête
/// recherché dans la ligne 1 du Sheet — voir [SavHeaderIndex] — plutôt qu'une
/// lettre de colonne fixe, pour ne pas se désynchroniser si des colonnes sont
/// insérées/réordonnées dans le Sheet.
class SavColumns {
  static const String numeroSav = 'N°SAV';
  static const String quiOuvre = 'Qui ouvre le SAV';
  static const String nomClient = 'Nom Client';
  static const String refChantier = 'Ref. Chantier';
  static const String probleme = 'Description du problème rencontré';

  /// Colonne "Choix livraison" : commentaire libre saisi par les
  /// commerciaux. Affiché à titre informatif ; ce n'est PAS le signal fiable
  /// pour savoir si le SAV est confié à Joël (voir le surlignage rose de la
  /// ligne, détecté via la couleur de fond dans GoogleSheetsService).
  static const String affecteA = 'Choix livraison';
  static const String statutSav = 'Statut SAV';
  static const String fournitures = 'Fournitures à livrer';
  static const String etatSav = 'Etat SAV';
  static const String interventionARealiser = 'Intervention à réaliser';

  /// Colonne unique regroupant "Client final / Adresse d'intervention /
  /// Téléphone" (cellule multi-lignes dans le Sheet).
  static const String clientFinal = 'Client final';
  static const String dureeIntervention = "Durée d'intervention prévue";
  static const String vehicule = 'Véhicule pour livraison';
  static const String renfort = 'personnes supplémentaires nécessaires';
  static const String dateIntervention = "Date d'intervention programmée";
  static const String heureIntervention = "Heure d'intervention programmée";

  /// Colonne technique invisible pour Joël, utilisée comme clé de
  /// correspondance fiable pour retrouver une ligne (au lieu de son index).
  static const String idGoogle = 'ID_GOOGLE';

  static const String statutAccepte = 'Accepté';
  static const String etatPretPourIntervention = 'Prêt pour intervention';

  /// Valeur de [etatSav] indiquant un SAV clôturé, à exclure de la liste.
  static const String etatCloture = 'Cloturé';
}

/// Traduit les noms de colonnes [SavColumns] en index / lettre réels du
/// Google Sheet, en les recherchant dans la ligne d'en-tête lue à chaque
/// appel — ainsi, ajouter ou déplacer une colonne dans le Sheet ne désynchronise
/// plus l'app tant que l'intitulé de chaque colonne suivie reste reconnaissable.
class SavHeaderIndex {
  SavHeaderIndex(List<Object?> headerRow)
      : _headers = [for (final h in headerRow) _normalize('${h ?? ''}')];

  final List<String> _headers;

  /// Index 0-based de la colonne dont l'en-tête contient [columnName], ou -1
  /// si aucune colonne ne correspond.
  int indexOf(String columnName) {
    final needle = _normalize(columnName);
    return _headers.indexWhere((header) => header.contains(needle));
  }

  /// Lettre de colonne Sheet (A, B, …, AA, AB…) correspondant à [columnName].
  /// Lève une erreur explicite si la colonne est introuvable (plutôt que
  /// d'écrire silencieusement au mauvais endroit).
  String letterOf(String columnName) {
    final index = indexOf(columnName);
    if (index == -1) {
      throw StateError(
        'Colonne "$columnName" introuvable dans l\'en-tête du Sheet SAV '
        '(a-t-elle été renommée ?).',
      );
    }
    return columnLetterFromIndex(index);
  }

  static String columnLetterFromIndex(int index) {
    var value = index + 1;
    var letters = '';
    while (value > 0) {
      final remainder = (value - 1) % 26;
      letters = String.fromCharCode(65 + remainder) + letters;
      value = (value - 1) ~/ 26;
    }
    return letters;
  }

  static String _normalize(String value) {
    const accented = 'àâäáãåèéêëìíîïòóôöõùúûüçñÀÂÄÁÃÅÈÉÊËÌÍÎÏÒÓÔÖÕÙÚÛÜÇÑ';
    const plain = 'aaaaaaeeeeiiiiooooouuuucnAAAAAAEEEEIIIIOOOOOUUUUCN';
    final buffer = StringBuffer();
    for (final rune in value.replaceAll('\n', ' ').trim().runes) {
      final index = accented.indexOf(String.fromCharCode(rune));
      buffer.writeCharCode(index == -1 ? rune : plain.codeUnitAt(index));
    }
    return buffer
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
