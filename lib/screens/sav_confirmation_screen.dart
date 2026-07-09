import 'package:flutter/material.dart';

import '../data/app_config.dart';
import '../models/sav_intervention.dart';
import '../theme/app_colors.dart';
import '../widgets/rpi_app_bar_title.dart';

class SavConfirmationScreen extends StatelessWidget {
  const SavConfirmationScreen({super.key, required this.intervention});

  final SavIntervention intervention;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const RpiAppBarTitle('Intervention planifiée')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajoutée au Google Calendar de Joël',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${intervention.numeroSav} — ${intervention.nomClient}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${intervention.dateIntervention}, ${intervention.heureIntervention} '
                      '— ${intervention.dureeIntervention}',
                    ),
                    if (intervention.clientFinal.isNotEmpty)
                      Text(intervention.clientFinal),
                    if (intervention.vehicule.isNotEmpty ||
                        intervention.renfort.isNotEmpty)
                      Text(
                        [
                          if (intervention.vehicule.isNotEmpty)
                            intervention.vehicule,
                          intervention.renfort.isNotEmpty
                              ? intervention.renfort
                              : 'Sans renfort',
                        ].join(', '),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  'Etat SAV mis à jour : ${SavColumns.etatPretPourIntervention}',
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                labelStyle: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retour à la liste'),
            ),
          ],
        ),
      ),
    );
  }
}
