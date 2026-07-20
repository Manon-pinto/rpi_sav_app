import 'package:cloud_firestore/cloud_firestore.dart';

/// Comptes autorisés en plus des 3 comptes de base ([kAllowedEmails], fixés
/// dans le code — jamais modifiables depuis l'app, pour éviter qu'une
/// mauvaise manipulation ne verrouille tout le monde dehors). Gérés depuis
/// l'écran de monitoring admin, sans avoir besoin de redéployer l'app.
///
/// Un seul document Firestore (`allowed_accounts/sav`) avec un champ
/// `emails` (liste) — écriture réservée à admin par les règles Firestore
/// (voir `firestore.rules` dans rpi_qualite_app, projet Firebase partagé).
class AllowedAccountsService {
  static final _doc = FirebaseFirestore.instance
      .collection('allowed_accounts')
      .doc('sav');

  static Stream<List<String>> watchExtraEmails() {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      final emails = data?['emails'] as List<dynamic>? ?? const [];
      return emails.cast<String>();
    });
  }

  static Future<List<String>> fetchExtraEmails() async {
    final snapshot = await _doc.get();
    final emails = snapshot.data()?['emails'] as List<dynamic>? ?? const [];
    return emails.cast<String>();
  }

  static Future<void> addEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    await _doc.set({
      'emails': FieldValue.arrayUnion([normalized]),
    }, SetOptions(merge: true));
  }

  static Future<void> removeEmail(String email) async {
    await _doc.set({
      'emails': FieldValue.arrayRemove([email]),
    }, SetOptions(merge: true));
  }
}
