import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_config.dart';
import '../data/firebase_auth_service.dart';
import '../data/google_calendar_service.dart';
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
  final _calendarService = GoogleCalendarService();
  final _dureeController = TextEditingController();
  final _vehiculeController = TextEditingController();
  final _renfortController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _heure;
  bool _saving = false;
  String? _error;
  Map<String, List<String>> _dropdownOptions = {};

  @override
  void initState() {
    super.initState();
    _dureeController.text = widget.intervention.dureeIntervention;
    _vehiculeController.text = widget.intervention.vehicule;
    _renfortController.text = widget.intervention.renfort;
    _loadDropdownOptions();
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
    // véhicule et le renfort sans encore fixer de rendez-vous. Dans ce cas,
    // aucun événement n'est créé sur Calendar (voir message après l'écriture).
    final hasDate = _date != null && _heure != null;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final dateLabel = hasDate
          ? DateFormat('dd/MM/yyyy').format(_date!)
          : '';
      final heureLabel = hasDate
          ? '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}'
          : '';

      final planned = widget.intervention.copyWithPlanning(
        dureeIntervention: _dureeController.text.trim(),
        vehicule: _vehiculeController.text.trim(),
        renfort: _renfortController.text.trim(),
        dateIntervention: dateLabel,
        heureIntervention: heureLabel,
      );

      final token = await widget.authService.requestDataAccessToken();
      await widget.sheetsService.writePlanning(token, planned);

      if (!hasDate) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enregistré sans rendez-vous'),
            content: const Text(
              'Durée, véhicule et renfort ont été enregistrés. Aucun '
              'rendez-vous n\'a été ajouté au calendrier car aucune date '
              'n\'a été choisie. Le SAV reste dans la liste "à planifier" '
              'jusqu\'à ce qu\'une date soit fixée.',
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

      await _calendarService.createInterventionEvent(token, planned);

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
