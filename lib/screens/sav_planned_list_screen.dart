import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firebase_auth_service.dart';
import '../data/google_sheets_service.dart';
import '../models/sav_intervention.dart';
import '../theme/app_colors.dart';
import '../widgets/rpi_app_bar_title.dart';
import 'sav_planning_screen.dart';

/// Liste des SAV déjà planifiés (date/heure fixées), pour permettre à
/// Joël/Clara de déplacer un rendez-vous en cas d'imprévu ou de besoin.
class SavPlannedListScreen extends StatefulWidget {
  const SavPlannedListScreen({
    super.key,
    required this.authService,
    required this.sheetsService,
  });

  final FirebaseAuthService authService;
  final GoogleSheetsService sheetsService;

  @override
  State<SavPlannedListScreen> createState() => _SavPlannedListScreenState();
}

class _SavPlannedListScreenState extends State<SavPlannedListScreen> {
  late Future<List<SavIntervention>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SavIntervention>> _load() async {
    final token = await widget.authService.requestDataAccessToken();
    final interventions = await widget.sheetsService.fetchPlannedInterventions(
      token,
    );
    // Seuls les RDV pas encore passés sont proposés à la replanification —
    // inutile de déplacer une intervention déjà réalisée.
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcoming = interventions.where((intervention) {
      final date = intervention.plannedDate;
      return date == null || !date.isBefore(startOfToday);
    }).toList();
    // Les prochains rendez-vous en premier, pour repérer rapidement ceux à
    // déplacer en priorité.
    upcoming.sort((a, b) {
      final dateA = a.plannedDate;
      final dateB = b.plannedDate;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });
    return upcoming;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const RpiAppBarTitle('Rendez-vous à venir'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<SavIntervention>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erreur de chargement : ${snapshot.error}',
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            final interventions = snapshot.data ?? const [];
            if (interventions.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Aucun rendez-vous à venir.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: interventions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final intervention = interventions[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      '${intervention.numeroSav} — ${intervention.nomClient}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(intervention.probleme),
                    trailing: Chip(
                      label: Text(_dateHeureLabel(intervention)),
                      backgroundColor: AppColors.accent.withValues(
                        alpha: 0.12,
                      ),
                      labelStyle: const TextStyle(color: AppColors.accent),
                    ),
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => SavPlanningScreen(
                            authService: widget.authService,
                            sheetsService: widget.sheetsService,
                            intervention: intervention,
                          ),
                        ),
                      );
                      if (updated == true) {
                        await _refresh();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _dateHeureLabel(SavIntervention intervention) {
    final date = intervention.plannedDate;
    final dateLabel = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : intervention.dateIntervention;
    return '$dateLabel · ${intervention.heureIntervention}';
  }
}
