import 'package:googleapis/calendar/v3.dart' as calendar;

import '../models/sav_intervention.dart';
import 'app_config.dart';
import 'google_http_client.dart';

/// Création de l'événement d'intervention sur le Google Calendar de Joël
/// (section 7 du doc de lancement).
class GoogleCalendarService {
  Future<calendar.Event> createInterventionEvent(
    String accessToken,
    SavIntervention intervention,
  ) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = calendar.CalendarApi(client);
      final start = _parseStart(
        intervention.dateIntervention,
        intervention.heureIntervention,
      );
      final duration = _parseDuration(intervention.dureeIntervention);
      final end = start.add(duration);

      final event = calendar.Event(
        summary: '${intervention.numeroSav} — ${intervention.nomClient}',
        location: intervention.clientFinal,
        description: [
          if (intervention.interventionARealiser.isNotEmpty)
            'Intervention à réaliser : ${intervention.interventionARealiser}',
          if (intervention.fournitures.isNotEmpty)
            'Fournitures à livrer : ${intervention.fournitures}',
          if (intervention.clientFinal.isNotEmpty)
            'Client final : ${intervention.clientFinal}',
        ].join('\n'),
        start: calendar.EventDateTime(
          dateTime: start,
          timeZone: 'Europe/Paris',
        ),
        end: calendar.EventDateTime(dateTime: end, timeZone: 'Europe/Paris'),
      );

      return api.events.insert(event, 'primary');
    } finally {
      client.close();
    }
  }

  DateTime _parseStart(String dateLabel, String heureLabel) {
    final dateParts = dateLabel.split(RegExp('[/-]'));
    var year = DateTime.now().year;
    var month = DateTime.now().month;
    var day = DateTime.now().day;
    if (dateParts.length == 3) {
      day = int.tryParse(dateParts[0]) ?? day;
      month = int.tryParse(dateParts[1]) ?? month;
      final parsedYear = int.tryParse(dateParts[2]) ?? year;
      year = parsedYear < 100 ? 2000 + parsedYear : parsedYear;
    }

    final timeParts = heureLabel.split(':');
    var hour = 8;
    var minute = 0;
    if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? hour;
    if (timeParts.length > 1) {
      minute = int.tryParse(timeParts[1]) ?? minute;
    }

    return DateTime(year, month, day, hour, minute);
  }

  /// Ex. "1h30", "1h", "90" (minutes), "2:00" → Duration ; sinon valeur par
  /// défaut définie dans [kDefaultInterventionDurationMinutes].
  Duration _parseDuration(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const Duration(minutes: kDefaultInterventionDurationMinutes);
    }

    final hourMinuteMatch = RegExp(r'^(\d+)h(\d{0,2})$').firstMatch(normalized);
    if (hourMinuteMatch != null) {
      final hours = int.tryParse(hourMinuteMatch.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(hourMinuteMatch.group(2) ?? '') ?? 0;
      final total = Duration(hours: hours, minutes: minutes);
      return total.inMinutes > 0
          ? total
          : const Duration(minutes: kDefaultInterventionDurationMinutes);
    }

    final colonMatch = RegExp(r'^(\d+):(\d{2})$').firstMatch(normalized);
    if (colonMatch != null) {
      final hours = int.tryParse(colonMatch.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(colonMatch.group(2) ?? '') ?? 0;
      final total = Duration(hours: hours, minutes: minutes);
      return total.inMinutes > 0
          ? total
          : const Duration(minutes: kDefaultInterventionDurationMinutes);
    }

    final numericMinutes = int.tryParse(normalized);
    if (numericMinutes != null && numericMinutes > 0) {
      return Duration(minutes: numericMinutes);
    }

    return const Duration(minutes: kDefaultInterventionDurationMinutes);
  }
}
