import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
    SettingsController.new);

final class AppSettings {
  const AppSettings(
      {this.themeMode = ThemeMode.system,
      this.locale,
      this.defaultDpi = 150,
      this.defaultQuality = 90,
      this.outputDirectory,
      this.checkUpdates = true});
  final ThemeMode themeMode;
  final Locale? locale;
  final int defaultDpi;
  final int defaultQuality;
  final String? outputDirectory;
  final bool checkUpdates;
  AppSettings copyWith(
      {ThemeMode? themeMode,
      Locale? locale,
      bool clearLocale = false,
      int? defaultDpi,
      int? defaultQuality,
      String? outputDirectory,
      bool clearOutputDirectory = false,
      bool? checkUpdates}) {
    return AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: clearLocale ? null : locale ?? this.locale,
        defaultDpi: defaultDpi ?? this.defaultDpi,
        defaultQuality: defaultQuality ?? this.defaultQuality,
        outputDirectory: clearOutputDirectory
            ? null
            : outputDirectory ?? this.outputDirectory,
        checkUpdates: checkUpdates ?? this.checkUpdates);
  }
}

final class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeMode.values.firstWhere(
        (item) => item.name == prefs.getString('theme'),
        orElse: () => ThemeMode.system);
    final localeName = prefs.getString('locale');
    return AppSettings(
        themeMode: theme,
        locale: localeName == null ? null : Locale(localeName),
        defaultDpi: prefs.getInt('dpi') ?? 150,
        defaultQuality: prefs.getInt('quality') ?? 90,
        outputDirectory: prefs.getString('outputDirectory'),
        checkUpdates: prefs.getBool('updates') ?? true);
  }

  @override
  Future<AppSettings> update(FutureOr<AppSettings> Function(AppSettings) cb,
      {FutureOr<AppSettings> Function(Object, StackTrace)? onError}) async {
    final next = await cb(state.valueOrNull ?? const AppSettings());
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', next.themeMode.name);
    if (next.locale == null) {
      await prefs.remove('locale');
    } else {
      await prefs.setString('locale', next.locale!.languageCode);
    }
    if (next.outputDirectory == null) {
      await prefs.remove('outputDirectory');
    } else {
      await prefs.setString('outputDirectory', next.outputDirectory!);
    }
    await prefs.setInt('dpi', next.defaultDpi);
    await prefs.setInt('quality', next.defaultQuality);
    await prefs.setBool('updates', next.checkUpdates);
    return next;
  }
}
