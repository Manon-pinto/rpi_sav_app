import 'package:flutter/material.dart';

import '../data/firebase_auth_service.dart';
import '../data/google_sheets_service.dart';
import '../models/sav_intervention.dart';
import '../theme/app_colors.dart';
import '../widgets/rpi_app_bar_title.dart';
import 'sav_planning_screen.dart';

class SavListScreen extends StatefulWidget {
  const SavListScreen({
    super.key,
    required this.authService,
    required this.sheetsService,
  });

  final FirebaseAuthService authService;
  final GoogleSheetsService sheetsService;

  @override
  State<SavListScreen> createState() => _SavListScreenState();
}

class _SavListScreenState extends State<SavListScreen> {
  late Future<List<SavIntervention>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SavIntervention>> _load() async {
    final token = await widget.authService.requestDataAccessToken();
    return widget.sheetsService.fetchAcceptedInterventions(token);
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
        title: const RpiAppBarTitle('SAV à planifier'),
        actions: [
          IconButton(
            onPressed: () => widget.authService.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
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
                  Center(child: Text('Aucun SAV accepté à planifier.')),
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
                      label: Text(intervention.statutSav),
                      backgroundColor: AppColors.success.withValues(
                        alpha: 0.12,
                      ),
                      labelStyle: const TextStyle(color: AppColors.success),
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
}
