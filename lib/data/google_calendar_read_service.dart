import 'package:googleapis/calendar/v3.dart' as calendar;

import 'app_config.dart';
import 'google_http_client.dart';

/// Résumé d'un évènement existant dans le calendrier de Joël, pour affichage
/// dans l'écran de planification (visu des disponibilités avant de valider
/// une date/heure).
class CalendarEventSummary {
  const CalendarEventSummary({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final DateTime start;
  final DateTime end;
}

/// Lecture seule du calendrier de Joël, pour prévisualiser ses
/// disponibilités avant de planifier une intervention — complète la
/// synchronisation en écriture faite côté Apps Script.
class GoogleCalendarReadService {
  Future<List<CalendarEventSummary>> fetchEventsForDay(
    String accessToken,
    DateTime day,
  ) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = calendar.CalendarApi(client);
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await api.events.list(
        kJoelCalendarId,
        timeMin: startOfDay.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final items = response.items ?? const [];
      return items
          .where((event) => event.status != 'cancelled')
          .map((event) {
            final start = event.start?.dateTime ?? event.start?.date;
            final end = event.end?.dateTime ?? event.end?.date;
            if (start == null || end == null) return null;
            return CalendarEventSummary(
              title: event.summary ?? 'Sans titre',
              start: start.toLocal(),
              end: end.toLocal(),
            );
          })
          .whereType<CalendarEventSummary>()
          .toList();
    } finally {
      client.close();
    }
  }
}
