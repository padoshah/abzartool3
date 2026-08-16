import 'dart:convert';

final class JobSpec {
  const JobSpec(
      {required this.inputPath,
      required this.outputPath,
      required this.sourceFormat,
      required this.targetFormat,
      this.dpi = 150,
      this.quality = 90,
      this.stitchPages = false,
      this.embedImages = true,
      this.applyDefaultStyle = false,
      this.fontFamily = 'Noto Sans',
      this.fontSize = 11,
      this.bold = false,
      this.italic = false,
      this.underline = false});
  final String inputPath;
  final String outputPath;
  final String sourceFormat;
  final String targetFormat;
  final int dpi;
  final int quality;
  final bool stitchPages;
  final bool embedImages;
  final bool applyDefaultStyle;
  final String fontFamily;
  final int fontSize;
  final bool bold;
  final bool italic;
  final bool underline;

  Map<String, Object> toJson() => <String, Object>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'sourceFormat': sourceFormat,
        'targetFormat': targetFormat,
        'dpi': dpi,
        'quality': quality,
        'stitchPages': stitchPages,
        'embedImages': embedImages,
        'applyDefaultStyle': applyDefaultStyle,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'bold': bold,
        'italic': italic,
        'underline': underline,
      };
  String encode() => jsonEncode(toJson());
}
