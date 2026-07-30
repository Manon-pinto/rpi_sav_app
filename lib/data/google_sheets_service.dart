import 'package:googleapis/sheets/v4.dart' as sheets;

import '../models/sav_intervention.dart';
import 'app_config.dart';
import 'google_http_client.dart';

/// Lecture/écriture directe du Google Sheet "SAV diffus", tel que décrit
/// dans le doc de lancement : lecture filtrée sur Statut SAV = Accepté,
/// écriture des colonnes AC à AG et mise à jour automatique de la colonne W.
class GoogleSheetsService {
  static const _headerRange = "'$kSavSheetName'!A1:ZZ1";
  static const _dataRange = "'$kSavSheetName'!A2:ZZ";

  /// SAV acceptés, confiés à Joël, pas encore planifiés (pas de date/heure).
  Future<List<SavIntervention>> fetchAcceptedInterventions(
    String accessToken,
  ) {
    return _fetchInterventions(accessToken, wantPlanned: false);
  }

  /// SAV acceptés, confiés à Joël, déjà planifiés (date/heure renseignées) —
  /// permet de retrouver un RDV existant pour le déplacer en cas d'imprévu.
  Future<List<SavIntervention>> fetchPlannedInterventions(
    String accessToken,
  ) {
    return _fetchInterventions(accessToken, wantPlanned: true);
  }

  Future<List<SavIntervention>> _fetchInterventions(
    String accessToken, {
    required bool wantPlanned,
  }) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = sheets.SheetsApi(client);
      final headerResponse = await api.spreadsheets.values.get(
        kSavSpreadsheetId,
        _headerRange,
      );
      final headerRow = headerResponse.values?.first ?? const [];
      final idGoogleColumnIndex = _findIdGoogleColumnIndex(headerRow);

      final dataResponse = await api.spreadsheets.values.get(
        kSavSpreadsheetId,
        _dataRange,
      );
      final rows = dataResponse.values ?? const [];

      // La colonne L ("Choix livraison") est un texte libre non fiable pour
      // détecter "assigné à Joël" : le vrai signal est la couleur de fond
      // rose appliquée à toute la ligne dans le Sheet.
      final rowColors = rows.isEmpty
          ? const <sheets.Color?>[]
          : await _fetchRowBackgroundColors(api, rows.length);

      final interventions = <SavIntervention>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;
        final rowIndex = i + 2; // +2 : ligne 1 = en-tête, données dès ligne 2.
        final statut = _cell(row, SavColumns.indexOf(SavColumns.statutSav));
        if (!_matches(statut, SavColumns.statutAccepte)) continue;
        final rowColor = i < rowColors.length ? rowColors[i] : null;
        final affecteALabel = _cell(
          row,
          SavColumns.indexOf(SavColumns.affecteA),
        );
        final isAssigneJoel =
            _isPinkish(rowColor) || _contains(affecteALabel, 'Joel');
        if (!isAssigneJoel) continue;
        final etatSav = _cell(row, SavColumns.indexOf(SavColumns.etatSav));
        if (_contains(etatSav, SavColumns.etatCloture)) continue;
        final dateIntervention = _cell(
          row,
          SavColumns.indexOf(SavColumns.dateIntervention),
        );
        final heureIntervention = _cell(
          row,
          SavColumns.indexOf(SavColumns.heureIntervention),
        );
        final isPlanned =
            dateIntervention.isNotEmpty && heureIntervention.isNotEmpty;
        if (isPlanned != wantPlanned) continue;
        final affecteA = affecteALabel;

        final clientFinal = [
          _cell(row, SavColumns.indexOf(SavColumns.clientFinal)),
          _cell(row, SavColumns.indexOf(SavColumns.adresseIntervention)),
          _cell(row, SavColumns.indexOf(SavColumns.telephone)),
        ].where((part) => part.isNotEmpty).join(' - ');

        interventions.add(
          SavIntervention(
            idGoogle: idGoogleColumnIndex == null
                ? 'row-$rowIndex'
                : _cell(row, idGoogleColumnIndex),
            rowIndex: rowIndex,
            numeroSav: _cell(row, SavColumns.indexOf(SavColumns.numeroSav)),
            quiOuvre: _cell(row, SavColumns.indexOf(SavColumns.quiOuvre)),
            nomClient: _cell(row, SavColumns.indexOf(SavColumns.nomClient)),
            refChantier: _cell(
              row,
              SavColumns.indexOf(SavColumns.refChantier),
            ),
            probleme: _cell(row, SavColumns.indexOf(SavColumns.probleme)),
            affecteA: affecteA,
            statutSav: statut,
            fournitures: _cell(
              row,
              SavColumns.indexOf(SavColumns.fournitures),
            ),
            etatSav: _cell(row, SavColumns.indexOf(SavColumns.etatSav)),
            interventionARealiser: _cell(
              row,
              SavColumns.indexOf(SavColumns.interventionARealiser),
            ),
            clientFinal: clientFinal,
            dureeIntervention: _cell(
              row,
              SavColumns.indexOf(SavColumns.dureeIntervention),
            ),
            vehicule: _cell(row, SavColumns.indexOf(SavColumns.vehicule)),
            renfort: _cell(row, SavColumns.indexOf(SavColumns.renfort)),
            dateIntervention: dateIntervention,
            heureIntervention: heureIntervention,
          ),
        );
      }
      return interventions;
    } finally {
      client.close();
    }
  }

  /// Écrit les colonnes AC:AG (planification) et met à jour W ("Etat SAV")
  /// pour la ligne identifiée par [intervention.idGoogle], en la relocalisant
  /// au besoin si le Sheet a été trié/filtré entre-temps.
  Future<void> writePlanning(
    String accessToken,
    SavIntervention intervention,
  ) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = sheets.SheetsApi(client);
      final rowIndex = await _resolveRowIndex(api, intervention);

      final data = <sheets.ValueRange>[
        sheets.ValueRange(
          range: "'$kSavSheetName'!${SavColumns.dureeIntervention}$rowIndex",
          values: [
            [intervention.dureeIntervention],
          ],
        ),
        sheets.ValueRange(
          range: "'$kSavSheetName'!${SavColumns.vehicule}$rowIndex",
          values: [
            [intervention.vehicule],
          ],
        ),
        sheets.ValueRange(
          range: "'$kSavSheetName'!${SavColumns.renfort}$rowIndex",
          values: [
            [intervention.renfort],
          ],
        ),
        sheets.ValueRange(
          range: "'$kSavSheetName'!${SavColumns.dateIntervention}$rowIndex",
          values: [
            [intervention.dateIntervention],
          ],
        ),
        sheets.ValueRange(
          range: "'$kSavSheetName'!${SavColumns.heureIntervention}$rowIndex",
          values: [
            [intervention.heureIntervention],
          ],
        ),
        // La colonne "Etat SAV" (U) est protégée dans le Sheet et son
        // écriture est rejetée par l'API pour ce compte (l'ensemble du
        // batchUpdate échoue si une seule plage est refusée) : on ne la
        // touche plus depuis l'app, elle reste gérée manuellement/par une
        // automatisation côté Sheet.
      ];

      await api.spreadsheets.values.batchUpdate(
        sheets.BatchUpdateValuesRequest(
          valueInputOption: 'USER_ENTERED',
          data: data,
        ),
        kSavSpreadsheetId,
      );
    } finally {
      client.close();
    }
  }

  /// Récupère les options de liste déroulante (validation de données) des
  /// colonnes Durée prévue / Véhicule / Renfort, si elles existent, pour que
  /// le formulaire de planification propose les mêmes choix que le Sheet.
  /// Une colonne sans liste déroulante renvoie une liste vide (champ texte
  /// libre côté app).
  Future<Map<String, List<String>>> fetchPlanningDropdownOptions(
    String accessToken,
  ) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = sheets.SheetsApi(client);
      final columns = [
        SavColumns.dureeIntervention,
        SavColumns.vehicule,
        SavColumns.renfort,
      ];
      final response = await api.spreadsheets.get(
        kSavSpreadsheetId,
        ranges: [for (final col in columns) "'$kSavSheetName'!${col}2"],
        $fields: 'sheets.data.rowData.values.dataValidation',
      );
      final rowDataList = response.sheets?.first.data ?? const [];

      final result = <String, List<String>>{};
      for (var i = 0; i < columns.length; i++) {
        final rowData = i < rowDataList.length ? rowDataList[i].rowData : null;
        final cell = (rowData != null && rowData.isNotEmpty)
            ? rowData.first.values?.first
            : null;
        result[columns[i]] = await _resolveDropdownOptions(
          api,
          cell?.dataValidation,
        );
      }
      return result;
    } finally {
      client.close();
    }
  }

  Future<List<String>> _resolveDropdownOptions(
    sheets.SheetsApi api,
    sheets.DataValidationRule? rule,
  ) async {
    final condition = rule?.condition;
    if (condition == null) return const [];
    final values = condition.values ?? const [];

    if (condition.type == 'ONE_OF_LIST') {
      return values
          .map((v) => v.userEnteredValue ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
    }

    if (condition.type == 'ONE_OF_RANGE' && values.isNotEmpty) {
      final rangeFormula = (values.first.userEnteredValue ?? '')
          .replaceFirst(RegExp(r'^='), '')
          .replaceAll(r'$', '');
      if (rangeFormula.isEmpty) return const [];
      try {
        final rangeResponse = await api.spreadsheets.values.get(
          kSavSpreadsheetId,
          rangeFormula,
        );
        return (rangeResponse.values ?? const [])
            .expand((row) => row)
            .map((v) => '$v'.trim())
            .where((v) => v.isNotEmpty)
            .toList();
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }

  /// Retrouve le numéro de ligne actuel via la colonne ID_GOOGLE plutôt que
  /// de se fier au numéro lu au moment du chargement de la liste.
  Future<int> _resolveRowIndex(
    sheets.SheetsApi api,
    SavIntervention intervention,
  ) async {
    // Sans ID_GOOGLE exploitable, impossible de relocaliser la ligne de
    // façon fiable (une valeur vide matcherait la première ligne vide de la
    // colonne) : on se fie au numéro de ligne lu au chargement de la liste.
    if (intervention.idGoogle.isEmpty ||
        intervention.idGoogle.startsWith('row-')) {
      return intervention.rowIndex;
    }
    final headerResponse = await api.spreadsheets.values.get(
      kSavSpreadsheetId,
      _headerRange,
    );
    final headerRow = headerResponse.values?.first ?? const [];
    final idGoogleColumnIndex = _findIdGoogleColumnIndex(headerRow);
    if (idGoogleColumnIndex == null) return intervention.rowIndex;

    final columnLetter = _columnLetterFromIndex(idGoogleColumnIndex);
    final columnResponse = await api.spreadsheets.values.get(
      kSavSpreadsheetId,
      "'$kSavSheetName'!${columnLetter}2:$columnLetter",
    );
    final columnValues = columnResponse.values ?? const [];
    for (var i = 0; i < columnValues.length; i++) {
      final value = columnValues[i].isEmpty ? '' : '${columnValues[i].first}';
      if (value.isNotEmpty && value == intervention.idGoogle) {
        return i + 2;
      }
    }
    return intervention.rowIndex;
  }

  int? _findIdGoogleColumnIndex(List<Object?> headerRow) {
    for (var i = 0; i < headerRow.length; i++) {
      final header = '${headerRow[i]}'.trim().toUpperCase();
      if (header == SavColumns.idGoogle) return i;
    }
    return null;
  }

  String _columnLetterFromIndex(int index) {
    var value = index + 1;
    var letters = '';
    while (value > 0) {
      final remainder = (value - 1) % 26;
      letters = String.fromCharCode(65 + remainder) + letters;
      value = (value - 1) ~/ 26;
    }
    return letters;
  }

  String _cell(List<Object?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return '${row[index] ?? ''}'.trim();
  }

  /// Compare deux valeurs de cellule en ignorant la casse et les accents,
  /// pour tolérer les variantes de saisie ("Joël"/"joel", "Accepté"/"accepte").
  bool _matches(String cellValue, String expected) {
    return _normalize(cellValue) == _normalize(expected);
  }

  /// Comme [_matches] mais teste une sous-chaîne (ex. "Cloturé" au milieu
  /// d'un texte d'état plus long).
  bool _contains(String cellValue, String needle) {
    return _normalize(cellValue).contains(_normalize(needle));
  }

  /// Récupère la couleur de fond effective de la colonne A pour chaque ligne
  /// de données (A2:A{n+1}) — la ligne entière étant colorée en rose quand le
  /// SAV est confié à Joël, une seule colonne suffit à détecter le surlignage.
  Future<List<sheets.Color?>> _fetchRowBackgroundColors(
    sheets.SheetsApi api,
    int rowCount,
  ) async {
    final response = await api.spreadsheets.get(
      kSavSpreadsheetId,
      ranges: ["'$kSavSheetName'!A2:A${rowCount + 1}"],
      $fields:
          'sheets.data.rowData.values.effectiveFormat.backgroundColorStyle',
    );
    final rowData = response.sheets?.first.data?.first.rowData ?? const [];
    return List<sheets.Color?>.generate(rowCount, (i) {
      if (i >= rowData.length) return null;
      final values = rowData[i].values;
      if (values == null || values.isEmpty) return null;
      return values.first.effectiveFormat?.backgroundColorStyle?.rgbColor;
    });
  }

  /// Couleur de surlignage confirmée sur le Sheet pour "confié à Joël".
  static const _joelHighlightRed = 0xd5 / 0xff;
  static const _joelHighlightGreen = 0xa6 / 0xff;
  static const _joelHighlightBlue = 0xbd / 0xff;

  /// Tolérance par canal (0..1) pour absorber les petits écarts d'export.
  static const _colorTolerance = 0.03;

  /// Compare la couleur de fond de la ligne à #d5a6bd (le rose utilisé sur le
  /// Sheet pour signaler "confié à Joël"), avec une petite tolérance.
  bool _isPinkish(sheets.Color? color) {
    if (color == null) return false;
    final red = color.red ?? 1.0;
    final green = color.green ?? 1.0;
    final blue = color.blue ?? 1.0;
    return (red - _joelHighlightRed).abs() < _colorTolerance &&
        (green - _joelHighlightGreen).abs() < _colorTolerance &&
        (blue - _joelHighlightBlue).abs() < _colorTolerance;
  }

  String _normalize(String value) {
    const accented = 'àâäáãåèéêëìíîïòóôöõùúûüçñÀÂÄÁÃÅÈÉÊËÌÍÎÏÒÓÔÖÕÙÚÛÜÇÑ';
    const plain = 'aaaaaaeeeeiiiiooooouuuucnAAAAAAEEEEIIIIOOOOOUUUUCN';
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      final index = accented.indexOf(String.fromCharCode(rune));
      buffer.writeCharCode(index == -1 ? rune : plain.codeUnitAt(index));
    }
    return buffer.toString().toLowerCase();
  }
}
