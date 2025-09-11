import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Silent if no .env yet.
  }
}

void bootstrap(Widget Function() builder) {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _loadEnv();
      runApp(builder());
    },
    (error, stack) {
      // TODO: integrate logging / crash reporting
      debugPrint('Bootstrap error: $error');
    },
  );
}
