import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAuthPersistence();
  RpiSavApp.bootstrap();
}

Future<void> _configureAuthPersistence() async {
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {
    // Native Apple/Android builds persist Firebase Auth localement par défaut.
  }
}
