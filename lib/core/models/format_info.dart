final class FormatInfo {
  const FormatInfo(
      {required this.id,
      required this.label,
      required this.mime,
      required this.writable,});
  factory FormatInfo.fromJson(Map<String, Object?> json) => FormatInfo(
        id: json['id']! as String,
        label: json['label']! as String,
        mime: json['mime']! as String,
        writable: json['writable']! as bool,
      );
  final String id;
  final String label;
  final String mime;
  final bool writable;
}

enum Fidelity { lossless, high, textOnly, raster }

final class ConversionOption {
  const ConversionOption(this.id, this.type, this.values, this.defaultValue);
  factory ConversionOption.fromJson(Map<String, Object?> json) =>
      ConversionOption(
        json['id']! as String,
        json['type']! as String,
        (json['values'] as List<Object?>?) ?? const [],
        json['default'],
      );
  final String id;
  final String type;
  final List<Object?> values;
  final Object? defaultValue;
}

final class ConversionCapability {
  const ConversionCapability(
      {required this.source,
      required this.target,
      required this.fidelity,
      required this.enabled,
      required this.requiresOcr,
      required this.options,});
  factory ConversionCapability.fromJson(Map<String, Object?> json) =>
      ConversionCapability(
        source: json['source']! as String,
        target: json['target']! as String,
        fidelity: Fidelity.values.byName((json['fidelity']! as String)
            .toLowerCase()
            .replaceAll('_only', 'Only'),),
        enabled: json['enabled']! as bool,
        requiresOcr: json['requiresOcr']! as bool,
        options: (json['options']! as List<Object?>)
            .map((item) =>
                ConversionOption.fromJson(item! as Map<String, Object?>),)
            .toList(growable: false),
      );
  final String source;
  final String target;
  final Fidelity fidelity;
  final bool enabled;
  final bool requiresOcr;
  final List<ConversionOption> options;
}
