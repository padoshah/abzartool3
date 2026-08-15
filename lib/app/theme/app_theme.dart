import 'dart:io';

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, const Color(0xff195de6));
  static ThemeData dark() => _build(Brightness.dark, const Color(0xff8fb2ff));

  static ThemeData _build(Brightness brightness, Color seed) {
    final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'NotoSans',
      fontFamilyFallback: const <String>['NotoSansArabic'],
      visualDensity: Platform.isWindows ? VisualDensity.compact : VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      navigationRailTheme: const NavigationRailThemeData(groupAlignment: -0.8),
    );
  }
}
