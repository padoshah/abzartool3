import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await StorageService().cleanOldTemporaryFiles();
    runApp(const ProviderScope(child: AbzarFileApp()));
  }, (error, stack) {
    FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack));
  });
}
