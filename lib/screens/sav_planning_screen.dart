import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/activity_logger.dart';
import '../data/app_config.dart';
import '../data/error_logger.dart';
import '../data/firebase_auth_service.dart';
import '../data/google_calendar_read_service.dart';
import '../data/google_sheets_service.dart';
import '../models/sav_intervention.dart';
import '../theme/app_colors.dart';
import '../widgets/rpi_app_bar_title.dart';
import 'sav_confirmation_screen.dart';

class SavPlanningScreen extends StatefulWidget {
  const SavPlanningScreen({
    super.key,
    required this.authService,
    required this.sheetsService,
    required this.intervention,
  });

  final FirebaseAuthService authService;
  final GoogleSheetsService sheetsService;
  final SavIntervention intervention;

  @override
  State<SavPlanningScreen> createState() => _SavPlanningScreenState();
}

class _SavPlanningScreenState extends State<SavPlanningScreen> {
  final _dureeController = TextEditingController();
  final _vehiculeController = TextEditingController();
  final _renfortController = TextEditingController();
  final _calendarReadService = GoogleCalendarReadService();

  DateTime? _date;
  TimeOfDay? _heure;
  bool _saving = false;
  String? _error;
  Map<String, List<String>> _dropdownOptions = {};

  // Agenda de Joël sous forme de mini calendrier mensuel, chargé dès
  // l'ouverture de l'écran — pour que Clara/Joël voie ses disponibilités
  // en permanence, indépendamment de la date choisie pour l'intervention.
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEventSummary>? _monthEvents;
  bool _loadingMonth = false;

  @override
  void initState() {
    super.initState();
    _dureeController.text = widget.intervention.dureeIntervention;
    _vehiculeController.text = widget.intervention.vehicule;
    _renfortController.text = widget.intervention.renfort;
    _loadDropdownOptions();
    _loadMonthEvents(_focusedMonth);
  }

  /// Visu des disponibilités de Joël sur le mois affiché, en complément de
  /// l'alerte mail envoyée après coup par le script si un conflit passe
  /// quand même.
  Future<void> _loadMonthEvents(DateTime month) async {
    setState(() => _loadingMonth = true);
    try {
      final token = await widget.authService.requestDataAccessToken();
      // Marge d'une semaine avant/après pour couvrir les jours du mois
      // précédent/suivant affichés en début/fin de grille.
      final start = DateTime(
        month.year,
        month.month,
      ).subtract(const Duration(days: 7));
      final end = DateTime(
        month.year,
        month.month + 1,
      ).add(const Duration(days: 7));
      final events = await _calendarReadService.fetchEventsForRange(
        token,
        start,
        end,
      );
      events.sort((a, b) => a.start.compareTo(b.start));
      if (mounted) setState(() => _monthEvents = events);
    } catch (_) {
      // Non bloquant : la visu est un confort, pas une condition pour
      // planifier.
      if (mounted) setState(() => _monthEvents = null);
    } finally {
      if (mounted) setState(() => _loadingMonth = false);
    }
  }

  List<CalendarEventSummary> _eventsForDay(DateTime day) {
    return (_monthEvents ?? const [])
        .where((event) => isSameDay(event.start, day))
        .toList();
  }

  Future<void> _loadDropdownOptions() async {
    try {
      final token = await widget.authService.requestDataAccessToken();
      final options = await widget.sheetsService.fetchPlanningDropdownOptions(
        token,
      );
      if (mounted) setState(() => _dropdownOptions = options);
    } catch (_) {
      // Pas de liste déroulante disponible : les champs restent en texte libre.
    }
  }

  @override
  void dispose() {
    _dureeController.dispose();
    _vehiculeController.dispose();
    _renfortController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heure ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _heure = picked);
  }

  Future<void> _confirm() async {
    // La date/heure est optionnelle : Joël peut enregistrer la durée, le
    // véhicule et le renfort sans encore fixer de rendez-vous.
    final hasDate = _date != null && _heure != null;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // La date et l'heure sont écrites indépendamment l'une de l'autre :
      // Clara peut fixer la date avant l'heure (ou l'inverse) sans que la
      // première saisie soit effacée. Seul le duo complet déclenche le
      // statut "Prêt pour intervention" (le Sheet gère seul l'ajout au
      // calendrier à partir de ces colonnes).
      final dateLabel = _date != null
          ? DateFormat('dd/MM/yyyy').format(_date!)
          : '';
      final heureLabel = _heure != null
          ? '${_heure!.hour.toString().padLeft(2, '0')}h${_heure!.minute.toString().padLeft(2, '0')}'
          : '';

      final planned = widget.intervention.copyWithPlanning(
        dureeIntervention: _dureeController.text.trim(),
        vehicule: _vehiculeController.text.trim(),
        renfort: _renfortController.text.trim(),
        dateIntervention: dateLabel,
        heureIntervention: heureLabel,
      );

      final token = await widget.authService.requestDataAccessToken();
      try {
        await widget.sheetsService.writePlanning(token, planned);
      } catch (error, stack) {
        // Distinct des erreurs Flutter globales : une erreur Sheets ici est
        // rattrapée localement (l'utilisateur voit `_error`) et ne remonte
        // donc pas via FlutterError.onError — on la logue explicitement.
        ErrorLogger.log(
          error.toString(),
          stack: stack,
          context: 'writePlanning:sheets',
        );
        rethrow;
      }
      ActivityLogger.logEvent(
        'sav_planned',
        details: {
          'numeroSav': planned.numeroSav,
          'hasDate': hasDate,
        },
      );

      if (!hasDate) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enregistré sans rendez-vous'),
            content: const Text(
              'Durée, véhicule et renfort ont été enregistrés. Le SAV reste '
              'dans la liste "à planifier" jusqu\'à ce qu\'une date soit '
              'fixée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SavConfirmationScreen(intervention: planned),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result ?? true);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final intervention = widget.intervention;
    return Scaffold(
      appBar: AppBar(
        title: RpiAppBarTitle(
          '${intervention.numeroSav} — ${intervention.nomClient}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(intervention.statutSav),
                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                labelStyle: const TextStyle(color: AppColors.success),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _readOnlyLine(
                      'Intervention à réaliser',
                      intervention.interventionARealiser,
                    ),
                    _readOnlyLine('Fournitures à livrer', intervention.fournitures),
                    _readOnlyLine('Client final', intervention.clientFinal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Planifier l\'intervention',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _date == null
                          ? 'Date'
                          : DateFormat('dd/MM/yyyy').format(_date!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _heure == null
                          ? 'Heure'
                          : _heure!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fieldFor(
              columnKey: SavColumns.dureeIntervention,
              controller: _dureeController,
              label: 'Durée prévue (ex. 1h30)',
            ),
            const SizedBox(height: 12),
            _fieldFor(
              columnKey: SavColumns.vehicule,
              controller: _vehiculeController,
              label: 'Véhicule',
            ),
            const SizedBox(height: 12),
            _fieldFor(
              columnKey: SavColumns.renfort,
              controller: _renfortController,
              label: 'Renfort (nombre de personnes)',
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            FilledButton(
              onPressed: _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _date != null && _heure != null
                          ? 'Confirmer et ajouter au calendrier'
                          : 'Enregistrer sans rendez-vous',
                    ),
            ),
            const SizedBox(height: 20),
            // Toujours visible sous le bouton d'enregistrement, pour que
            // Clara/Joël garde un œil sur l'agenda même après avoir validé.
            _upcomingAvailabilityCard(),
          ],
        ),
      ),
    );
  }

  /// Agenda de Joël sur les prochains jours (regroupé par date), affiché
  /// en permanence sous le bouton d'enregistrement du rendez-vous : mini
  /// calendrier mensuel, jours occupés marqués d'un point orange, avec le
  /// détail du jour sélectionné en dessous.
  Widget _upcomingAvailabilityCard() {
    final selected = _selectedDay;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disponibilités de Joël',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                if (_loadingMonth) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            TableCalendar<CalendarEventSummary>(
              locale: 'fr',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedMonth,
              selectedDayPredicate: (day) => isSameDay(selected, day),
              eventLoader: _eventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.line,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: AppColors.ink),
                selectedDecoration: BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              onDaySelected: (day, focused) {
                setState(() {
                  _selectedDay = day;
                  _focusedMonth = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedMonth = focused;
                _loadMonthEvents(focused);
              },
            ),
            if (selected != null) ...[
              const Divider(height: 20),
              Text(
                DateFormat('EEEE dd/MM', 'fr').format(selected),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final events = _eventsForDay(selected);
                  if (events.isEmpty) {
                    return const Text(
                      'Aucun rendez-vous — journée libre.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: events
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${DateFormat('HH:mm').format(event.start)} - '
                              '${DateFormat('HH:mm').format(event.end)} · '
                              '${event.title}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Menu déroulant si la colonne du Sheet a une liste de validation,
  /// sinon champ texte libre.
  Widget _fieldFor({
    required String columnKey,
    required TextEditingController controller,
    required String label,
  }) {
    final options = _dropdownOptions[columnKey] ?? const <String>[];
    if (options.isEmpty) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      );
    }

    final currentValue = options.contains(controller.text)
        ? controller.text
        : null;
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (value) => setState(() => controller.text = value ?? ''),
    );
  }

  Widget _readOnlyLine(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
