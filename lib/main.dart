import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/error_logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAuthPersistence();
  _configureErrorLogging();
  RpiSavApp.bootstrap();
}

void _configureErrorLogging() {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    previousOnError?.call(details);
    ErrorLogger.log(
      details.exceptionAsString(),
      stack: details.stack,
      context: details.library,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.log(error.toString(), stack: stack);
    return true;
  };
}

Future<void> _configureAuthPersistence() async {
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {
    // Native Apple/Android builds persist Firebase Auth localement par défaut.
  }
}
