import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextTheme accessible(TextTheme base) => base.copyWith(
        bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      );
}
