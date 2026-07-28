import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Journalise les erreurs non gérées dans Firestore (`error_logs`), pour
/// consultation par admin depuis un écran dédié dans l'app — partagée avec
/// rpi_qualite_app, les deux utilisant le même projet Firebase.
class ErrorLogger {
  static const String appName = 'sav';

  static Future<void> log(
    String message, {
    StackTrace? stack,
    String? context,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('error_logs').add({
        'app': appName,
        'message': message,
        'stack': stack?.toString() ?? '',
        'context': context ?? '',
        'userEmail': FirebaseAuth.instance.currentUser?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Le logging d'erreur ne doit jamais faire planter l'app à son tour.
    }
  }
}
