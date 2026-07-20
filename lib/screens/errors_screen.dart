import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/allowed_accounts_service.dart';
import '../data/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/rpi_app_bar_title.dart';

/// Écran réservé à admin, à 3 onglets : erreurs remontées automatiquement,
/// activité récente (SAV planifiés / contrôles qualité) et dernière
/// connexion par compte. Collections Firestore partagées entre rpi_sav_app
/// et rpi_qualite_app (même projet Firebase) : `error_logs`,
/// `activity_events`, `user_activity`.
class ErrorsScreen extends StatelessWidget {
  const ErrorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const RpiAppBarTitle('Monitoring'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Erreurs'),
              Tab(text: 'Activité'),
              Tab(text: 'Comptes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ErrorsTab(), _ActivityTab(), _AccountsTab()],
        ),
      ),
    );
  }
}

class _ErrorsTab extends StatelessWidget {
  const _ErrorsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('error_logs')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(child: Text('Aucune erreur remontée.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final app = data['app'] as String? ?? '?';
            final message = data['message'] as String? ?? '';
            final userEmail = data['userEmail'] as String? ?? '';
            final errContext = data['context'] as String? ?? '';
            final createdAt = data['createdAt'] as Timestamp?;
            final dateLabel = createdAt != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(createdAt.toDate())
                : '';
            return ExpansionTile(
              title: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  app,
                  dateLabel,
                  if (userEmail.isNotEmpty) userEmail,
                ].join(' · '),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errContext.isNotEmpty) ...[
                        Text(
                          'Contexte : $errContext',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SelectableText(
                        (data['stack'] as String?)?.isNotEmpty == true
                            ? data['stack'] as String
                            : 'Pas de stack trace.',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('activity_events')
          .orderBy('createdAt', descending: true)
          .limit(300)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        final recent = docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(since);
        }).toList();

        final counts = <String, int>{};
        for (final doc in recent) {
          final type = doc.data()['type'] as String? ?? '?';
          counts[type] = (counts[type] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in counts.entries)
                    Chip(label: Text('${entry.key} : ${entry.value} (7j)')),
                  if (counts.isEmpty)
                    const Text(
                      'Aucune activité sur les 7 derniers jours.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('Aucun évènement.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final app = data['app'] as String? ?? '?';
                        final type = data['type'] as String? ?? '?';
                        final userEmail = data['userEmail'] as String? ?? '';
                        final createdAt = data['createdAt'] as Timestamp?;
                        final dateLabel = createdAt != null
                            ? DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(createdAt.toDate())
                            : '';
                        return ListTile(
                          dense: true,
                          title: Text(type),
                          subtitle: Text(
                            [
                              app,
                              dateLabel,
                              if (userEmail.isNotEmpty) userEmail,
                            ].join(' · '),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AllowedAccountsManager(),
        SizedBox(height: 24),
        Text(
          'Activité récente',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        _RecentActivityList(),
      ],
    );
  }
}

/// Gestion des comptes autorisés en plus des 3 comptes de base (fixés dans
/// le code, non modifiables ici pour éviter un verrouillage accidentel de
/// tout le monde) — ajout/suppression immédiats, sans redéploiement.
class _AllowedAccountsManager extends StatefulWidget {
  const _AllowedAccountsManager();

  @override
  State<_AllowedAccountsManager> createState() =>
      _AllowedAccountsManagerState();
}

class _AllowedAccountsManagerState extends State<_AllowedAccountsManager> {
  final _emailController = TextEditingController();
  String? _error;
  bool _adding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (!email.contains('@')) {
      setState(() => _error = 'Adresse email invalide.');
      return;
    }
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await AllowedAccountsService.addEmail(email);
      _emailController.clear();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmRemove(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce compte ?'),
        content: Text(
          '$email ne pourra plus se connecter à l\'application après '
          'cette action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AllowedAccountsService.removeEmail(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comptes autorisés',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comptes de base (non modifiables ici) :',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final email in kAllowedEmails) Chip(label: Text(email)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Comptes ajoutés depuis cet écran :',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            StreamBuilder<List<String>>(
              stream: AllowedAccountsService.watchExtraEmails(),
              builder: (context, snapshot) {
                final emails = snapshot.data ?? const [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                if (emails.isEmpty) {
                  return const Text(
                    'Aucun compte supplémentaire pour le moment.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  );
                }
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final email in emails)
                      Chip(
                        label: Text(email),
                        onDeleted: () => _confirmRemove(email),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau compte (email @rpimenuiserie.com)',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addEmail(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _adding ? null : _addEmail,
                  child: _adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajouter'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_activity')
          .orderBy('lastSeenAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Text('Aucun compte vu pour le moment.');
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final email = data['email'] as String? ?? '?';
            final app = data['app'] as String? ?? '?';
            final version = data['appVersion'] as String? ?? '?';
            final lastSeenAt = data['lastSeenAt'] as Timestamp?;
            final dateLabel = lastSeenAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(lastSeenAt.toDate())
                : 'Jamais';
            return ListTile(
              title: Text(email),
              subtitle: Text('$app · v$version'),
              trailing: Text(
                dateLabel,
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          },
        );
      },
    );
  }
}
