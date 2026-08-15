import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/format_info.dart';

final formatRegistryProvider = FutureProvider<FormatRegistry>((ref) => FormatRegistry.load());

final class FormatRegistry {
  const FormatRegistry(this.formats, this.conversions);
  final List<FormatInfo> formats;
  final List<ConversionCapability> conversions;

  static Future<FormatRegistry> load() async {
    final source = await rootBundle.loadString('assets/config/conversion_matrix.json');
    final root = jsonDecode(source)! as Map<String, Object?>;
    return FormatRegistry(
      (root['formats']! as List<Object?>).map((item) => FormatInfo.fromJson(item! as Map<String, Object?>)).toList(growable: false),
      (root['conversions']! as List<Object?>).map((item) => ConversionCapability.fromJson(item! as Map<String, Object?>)).toList(growable: false),
    );
  }

  List<FormatInfo> targetsFor(String source) {
    final ids = conversions.where((item) => item.source == source && item.enabled).map((item) => item.target).toSet();
    return formats.where((item) => ids.contains(item.id)).toList(growable: false);
  }

  ConversionCapability? capability(String source, String target) {
    for (final item in conversions) {
      if (item.source == source && item.target == target) return item;
    }
    return null;
  }
}
