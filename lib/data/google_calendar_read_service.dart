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
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    return fetchEventsForRange(
      accessToken,
      startOfDay,
      startOfDay.add(const Duration(days: 1)),
    );
  }

  /// Évènements sur une plage de dates (bornes locales) — utilisé pour
  /// afficher les disponibilités de Joël sur les prochains jours *avant*
  /// même que Clara/Joël choisisse une date précise.
  Future<List<CalendarEventSummary>> fetchEventsForRange(
    String accessToken,
    DateTime start,
    DateTime end,
  ) async {
    final client = GoogleAuthorizedClient(accessToken);
    try {
      final api = calendar.CalendarApi(client);

      final response = await api.events.list(
        kJoelCalendarId,
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final items = response.items ?? const [];
      return items
          .where((event) => event.status != 'cancelled')
          .map((event) {
            final eventStart = event.start?.dateTime ?? event.start?.date;
            final eventEnd = event.end?.dateTime ?? event.end?.date;
            if (eventStart == null || eventEnd == null) return null;
            return CalendarEventSummary(
              title: event.summary ?? 'Sans titre',
              start: eventStart.toLocal(),
              end: eventEnd.toLocal(),
            );
          })
          .whereType<CalendarEventSummary>()
          .toList();
    } finally {
      client.close();
    }
  }
}
