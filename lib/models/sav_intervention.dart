import '../data/app_config.dart';

/// Une ligne du Google Sheet "SAV diffus", filtrée sur Statut SAV = Accepté.
class SavIntervention {
  const SavIntervention({
    required this.idGoogle,
    required this.rowIndex,
    required this.numeroSav,
    required this.quiOuvre,
    required this.nomClient,
    required this.refChantier,
    required this.probleme,
    required this.affecteA,
    required this.statutSav,
    required this.fournitures,
    required this.etatSav,
    required this.interventionARealiser,
    required this.clientFinal,
    this.dureeIntervention = '',
    this.vehicule = '',
    this.renfort = '',
    this.dateIntervention = '',
    this.heureIntervention = '',
  });

  /// Valeur de la colonne technique ID_GOOGLE, utilisée pour retrouver la
  /// ligne de façon fiable même si le Sheet est trié ou filtré.
  final String idGoogle;

  /// Index de ligne (1-based, tel que dans le Sheet) au moment de la
  /// lecture. Sert de repli si l'écriture via ID_GOOGLE échoue.
  final int rowIndex;

  final String numeroSav;
  final String quiOuvre;
  final String nomClient;
  final String refChantier;
  final String probleme;
  final String affecteA;
  final String statutSav;
  final String fournitures;
  final String etatSav;
  final String interventionARealiser;

  /// Colonne AH : "Client final / Adresse / Téléphone" telle quelle.
  final String clientFinal;

  final String dureeIntervention;
  final String vehicule;
  final String renfort;
  final String dateIntervention;
  final String heureIntervention;

  bool get isAccepte => statutSav.trim() == SavColumns.statutAccepte;

  bool get isPlanned =>
      dateIntervention.trim().isNotEmpty && heureIntervention.trim().isNotEmpty;

  String get displayTitle => numeroSav.isNotEmpty ? numeroSav : 'SAV';

  /// Date d'intervention parsée depuis le format "dd/MM/yyyy", ou null si
  /// absente/non reconnue.
  DateTime? get plannedDate {
    final parts = dateIntervention.trim().split(RegExp('[/-]'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year < 100 ? 2000 + year : year, month, day);
  }

  SavIntervention copyWithPlanning({
    required String dureeIntervention,
    required String vehicule,
    required String renfort,
    required String dateIntervention,
    required String heureIntervention,
  }) {
    return SavIntervention(
      idGoogle: idGoogle,
      rowIndex: rowIndex,
      numeroSav: numeroSav,
      quiOuvre: quiOuvre,
      nomClient: nomClient,
      refChantier: refChantier,
      probleme: probleme,
      affecteA: affecteA,
      statutSav: statutSav,
      fournitures: fournitures,
      etatSav: etatSav,
      interventionARealiser: interventionARealiser,
      clientFinal: clientFinal,
      dureeIntervention: dureeIntervention,
      vehicule: vehicule,
      renfort: renfort,
      dateIntervention: dateIntervention,
      heureIntervention: heureIntervention,
    );
  }
}
