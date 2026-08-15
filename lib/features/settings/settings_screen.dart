import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final controller = ref.read(settingsProvider.notifier);
    return CustomScrollView(slivers: <Widget>[
      SliverAppBar.large(title: Text(l10n.settings)),
      SliverList.list(children: <Widget>[
        ListTile(
          title: Text(l10n.theme),
          trailing: DropdownButton<ThemeMode>(
            value: settings.themeMode,
            items: <DropdownMenuItem<ThemeMode>>[
              DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
              DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
              DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
            ],
            onChanged: (value) => controller.update((_) async => settings.copyWith(themeMode: value)),
          ),
        ),
        ListTile(
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: settings.locale?.languageCode ?? 'system',
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'system', child: Text(l10n.system)),
              DropdownMenuItem(value: 'en', child: Text(l10n.english)),
              DropdownMenuItem(value: 'fa', child: Text(l10n.persian)),
            ],
            onChanged: (value) => controller.update((_) async => settings.copyWith(locale: value == 'system' ? null : Locale(value!), clearLocale: value == 'system')),
          ),
        ),
        ListTile(
          title: Text(l10n.defaultDpi),
          subtitle: Slider(
            value: settings.defaultDpi.toDouble(),
            min: 72,
            max: 600,
            divisions: 22,
            label: settings.defaultDpi.toString(),
            onChanged: (value) => controller.update((_) async => settings.copyWith(defaultDpi: value.toInt())),
          ),
        ),
        ListTile(
          title: Text(l10n.defaultQuality),
          subtitle: Slider(
            value: settings.defaultQuality.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            label: settings.defaultQuality.toString(),
            onChanged: (value) => controller.update((_) async => settings.copyWith(defaultQuality: value.toInt())),
          ),
        ),
        ListTile(
          title: Text(l10n.outputDirectory),
          subtitle: settings.outputDirectory == null ? null : Text(settings.outputDirectory!),
          trailing: const Icon(Icons.folder_open),
          onTap: () async {
            final result = await FilePicker.platform.getDirectoryPath();
            if (result != null) controller.update((_) async => settings.copyWith(outputDirectory: result));
          },
        ),
        SwitchListTile(
          title: Text(l10n.updateChecks),
          value: settings.checkUpdates,
          onChanged: (value) => controller.update((_) async => settings.copyWith(checkUpdates: value)),
        ),
        ListTile(title: Text(l10n.checkNow), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/updates')),
      ]),
    ]);
  }
}
