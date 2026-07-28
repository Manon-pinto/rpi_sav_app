import 'package:flutter/material.dart';

import '../data/activity_logger.dart';
import '../data/firebase_auth_service.dart';
import '../data/google_sheets_service.dart';
import '../models/sav_intervention.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../widgets/rpi_app_bar_title.dart';
import 'errors_screen.dart';
import 'sav_list_screen.dart';
import 'sav_planning_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
    required this.sheetsService,
  });

  final FirebaseAuthService authService;
  final GoogleSheetsService sheetsService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<SavIntervention>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    ActivityLogger.heartbeat();
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
    final isPhone =
        AppLayout.classify(MediaQuery.sizeOf(context).width) ==
        AppScreenClass.phone;

    return Scaffold(
      appBar: AppBar(
        title: const RpiAppBarTitle('Tableau de bord'),
        actions: [
          if (widget.authService.currentUser?.email == 'admin@rpimenuiserie.com')
            IconButton(
              tooltip: 'Erreurs techniques',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ErrorsScreen()),
              ),
              icon: const Icon(Icons.bug_report_outlined),
            ),
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
                  const SizedBox(height: 100),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 40,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Autorisation Google requise pour accéder au Sheet et "
                            "au calendrier de Joël. Le navigateur bloque la demande "
                            "automatique — clique ci-dessous pour l'autoriser.",
                            style: TextStyle(color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refresh,
                            child: const Text("Autoriser l'accès Google"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // fetchAcceptedInterventions ne renvoie déjà que les SAV non
            // planifiés (voir GoogleSheetsService) : ils sont tous "à faire".
            final toPlan = snapshot.data ?? const <SavIntervention>[];
            final refsChantiers = toPlan
                .map((i) => i.refChantier)
                .where((ref) => ref.isNotEmpty)
                .toSet();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bonjour Joël',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Voici l\'état de tes interventions SAV.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: isPhone ? 2 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        label: 'À planifier',
                        value: '${toPlan.length}',
                        icon: Icons.pending_actions,
                        color: AppColors.accent,
                      ),
                      _StatCard(
                        label: 'Chantiers concernés',
                        value: '${refsChantiers.length}',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'À planifier',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SavListScreen(
                                authService: widget.authService,
                                sheetsService: widget.sheetsService,
                              ),
                            ),
                          );
                          await _refresh();
                        },
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (toPlan.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Tout est planifié, bravo !'),
                      ),
                    )
                  else
                    ...toPlan
                        .take(3)
                        .map(
                          (intervention) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accent
                                      .withValues(alpha: 0.14),
                                  foregroundColor: AppColors.accent,
                                  child: const Icon(Icons.build_outlined),
                                ),
                                title: Text(
                                  '${intervention.numeroSav} — ${intervention.nomClient}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(intervention.probleme),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SavPlanningScreen(
                                        authService: widget.authService,
                                        sheetsService: widget.sheetsService,
                                        intervention: intervention,
                                      ),
                                    ),
                                  );
                                  await _refresh();
                                },
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liseré coloré en haut de la carte, à la manière des tableaux de
          // bord RPI Commandes/Qualité — reprend la couleur de l'indicateur.
          Container(height: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 26),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
