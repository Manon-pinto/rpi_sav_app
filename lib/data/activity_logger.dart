import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_config.dart';

/// Suivi d'activité pour le monitoring admin (partagé avec rpi_qualite_app,
/// même projet Firebase) : dernière connexion par compte (`user_activity`)
/// et évènements métier notables (`activity_events`), ex. SAV planifié.
class ActivityLogger {
  static const String appName = 'sav';

  /// À appeler une fois l'utilisateur connecté (ex. à l'affichage du
  /// tableau de bord) pour mettre à jour sa dernière activité connue.
  static Future<void> heartbeat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('user_activity')
          .doc(user.uid)
          .set({
            'email': user.email,
            'app': appName,
            'appVersion': kAppVersion,
            'lastSeenAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Le monitoring ne doit jamais faire planter l'app.
    }
  }

  static Future<void> logEvent(
    String type, {
    Map<String, dynamic>? details,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activity_events').add({
        'app': appName,
        'type': type,
        'userEmail': FirebaseAuth.instance.currentUser?.email ?? '',
        'details': details ?? const {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Le monitoring ne doit jamais faire planter l'app.
    }
  }
}
