import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un compte géré depuis l'écran admin.
enum AccountStatus { active, suspended }

/// Entrée Firestore décrivant l'état d'un compte (base ou ajouté).
class AllowedAccountEntry {
  const AllowedAccountEntry({
    required this.email,
    required this.status,
    required this.isBase,
  });

  final String email;
  final AccountStatus status;

  /// Vrai pour les 3 comptes de base ([kAllowedEmails], fixés dans le
  /// code) — ils ne peuvent pas être supprimés (le code les autoriserait
  /// à nouveau au prochain déploiement), seulement suspendus.
  final bool isBase;
}

/// Gestion des comptes autorisés à se connecter, base et ajoutés confondus.
///
/// Une entrée Firestore (`allowed_accounts/sav/entries/{email}`) par compte
/// dont le statut a été modifié depuis l'écran admin — écriture réservée à
/// admin par les règles Firestore (voir `firestore.rules` dans
/// rpi_qualite_app, projet Firebase partagé). Un compte de base sans
/// entrée est considéré actif par défaut (comportement d'origine, pour ne
/// pas nécessiter de migration au déploiement de cette fonctionnalité).
class AllowedAccountsService {
  static final _entries = FirebaseFirestore.instance
      .collection('allowed_accounts')
      .doc('sav')
      .collection('entries');

  /// Vrai si ce compte peut se connecter : actif par défaut s'il fait
  /// partie des comptes de base et n'a pas d'entrée Firestore explicite ;
  /// sinon dépend du statut de son entrée (absente = jamais autorisé pour
  /// un compte ajouté).
  static Future<bool> isAllowed(String email, {required bool isBase}) async {
    final doc = await _entries.doc(email).get();
    if (!doc.exists) return isBase;
    return doc.data()?['status'] == 'active';
  }

  /// Vue combinée des comptes de base et de leurs éventuelles entrées
  /// Firestore (statut suspendu) + des comptes ajoutés, pour l'écran admin.
  static Stream<List<AllowedAccountEntry>> watchAll(
    Set<String> baseEmails,
  ) {
    return _entries.snapshots().map((snapshot) {
      final overrides = <String, AccountStatus>{
        for (final doc in snapshot.docs)
          doc.id: doc.data()['status'] == 'active'
              ? AccountStatus.active
              : AccountStatus.suspended,
      };

      final result = <AllowedAccountEntry>[
        for (final email in baseEmails)
          AllowedAccountEntry(
            email: email,
            status: overrides[email] ?? AccountStatus.active,
            isBase: true,
          ),
      ];
      for (final entry in overrides.entries) {
        if (baseEmails.contains(entry.key)) continue;
        result.add(
          AllowedAccountEntry(
            email: entry.key,
            status: entry.value,
            isBase: false,
          ),
        );
      }
      result.sort((a, b) => a.email.compareTo(b.email));
      return result;
    });
  }

  static Future<void> addEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    await _entries.doc(normalized).set({'status': 'active'});
  }

  static Future<void> setStatus(String email, AccountStatus status) async {
    await _entries.doc(email).set({
      'status': status == AccountStatus.active ? 'active' : 'suspended',
    }, SetOptions(merge: true));
  }

  /// Retire complètement l'entrée — pour un compte de base, ça revient à
  /// "actif" (valeur par défaut sans entrée), pas à une suppression
  /// effective ; utiliser [setStatus] avec [AccountStatus.suspended] pour
  /// bloquer un compte de base.
  static Future<void> deleteEntry(String email) async {
    await _entries.doc(email).delete();
  }
}
