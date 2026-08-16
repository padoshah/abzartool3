import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/platform_open_service.dart';
import '../core/services/settings_service.dart';
import '../features/convert/convert_controller.dart';
import '../features/updater/update_dialog.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class AbzarFileApp extends ConsumerWidget {
  const AbzarFileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => UpdateBootstrap(
            child:
                OpenIntentBootstrap(child: child ?? const SizedBox.shrink()),),
        theme: light == null
            ? AppTheme.light()
            : AppTheme.light().copyWith(colorScheme: light),
        darkTheme: dark == null
            ? AppTheme.dark()
            : AppTheme.dark().copyWith(colorScheme: dark),
        themeMode: settings.themeMode,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
      ),
    );
  }
}

class OpenIntentBootstrap extends ConsumerStatefulWidget {
  const OpenIntentBootstrap({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<OpenIntentBootstrap> createState() =>
      _OpenIntentBootstrapState();
}

class _OpenIntentBootstrapState extends ConsumerState<OpenIntentBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PlatformOpenService.initialize((path) async {
        await ref
            .read(convertControllerProvider.notifier)
            .addDroppedFiles(<String>[path]);
        if (mounted) context.go('/convert');
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
