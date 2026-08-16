import 'dart:convert';
import 'dart:io';

Never fail(String message) {
  stderr.writeln('FAIL: $message');
  exit(1);
}

bool contains(List<int> bytes, String text) {
  final needle = utf8.encode(text);
  for (var i = 0; i + needle.length <= bytes.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

void validate(File file) {
  if (!file.existsSync() || file.lengthSync() == 0)
    fail('${file.path} is missing or empty.');
  final bytes = file.readAsBytesSync();
  final extension = file.path.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      if (utf8.decode(bytes.take(5).toList()) != '%PDF-' ||
          !contains(bytes, 'xref') ||
          !contains(bytes, 'trailer') ||
          !contains(bytes, '%%EOF'))
        fail('Invalid PDF structure: ${file.path}');
    case 'docx':
      if (bytes[0] != 0x50 ||
          bytes[1] != 0x4b ||
          !contains(bytes, '[Content_Types].xml') ||
          !contains(bytes, 'word/document.xml'))
        fail('Invalid DOCX package: ${file.path}');
    case 'xlsx':
      if (bytes[0] != 0x50 ||
          bytes[1] != 0x4b ||
          !contains(bytes, '[Content_Types].xml') ||
          !contains(bytes, 'xl/workbook.xml') ||
          !contains(bytes, 'xl/worksheets/sheet1.xml'))
        fail('Invalid XLSX package: ${file.path}');
    case 'pptx':
      if (bytes[0] != 0x50 ||
          bytes[1] != 0x4b ||
          !contains(bytes, '[Content_Types].xml') ||
          !contains(bytes, 'ppt/presentation.xml') ||
          !contains(bytes, 'ppt/slides/slide1.xml'))
        fail('Invalid PPTX package: ${file.path}');
    case 'png':
      const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < 33 ||
          !List.generate(8, (i) => bytes[i] == signature[i]).every((v) => v) ||
          !contains(bytes, 'IHDR') ||
          !contains(bytes, 'IDAT')) fail('Invalid PNG: ${file.path}');
    case 'jpg':
      if (bytes.length < 4 ||
          bytes[0] != 0xff ||
          bytes[1] != 0xd8 ||
          bytes[bytes.length - 2] != 0xff ||
          bytes.last != 0xd9) fail('Invalid JPEG: ${file.path}');
    case 'webp':
      if (bytes.length < 16 ||
          !contains(bytes, 'RIFF') ||
          !contains(bytes, 'WEBP')) fail('Invalid WebP: ${file.path}');
    case 'html':
      if (!contains(bytes, '<!doctype html>') || !contains(bytes, '<html'))
        fail('Invalid HTML: ${file.path}');
    case 'txt':
      try {
        utf8.decode(bytes);
      } catch (_) {
        fail('TXT is not valid UTF-8: ${file.path}');
      }
    default:
      fail('No structural validator for .$extension');
  }
}

void verifyConfiguration() {
  final matrix = jsonDecode(
          File('assets/config/conversion_matrix.json').readAsStringSync())!
      as Map<String, Object?>;
  final outputs = <String>{
    'docx',
    'xlsx',
    'pptx',
    'pdf',
    'html',
    'txt',
    'png',
    'jpg',
    'webp'
  };
  for (final raw in matrix['conversions']! as List<Object?>) {
    final item = raw! as Map<String, Object?>;
    if (item['enabled'] == true && !outputs.contains(item['target']))
      fail('Enabled target has no validator: ${item['target']}');
  }
  final android =
      File('.github/workflows/android-release.yml').readAsStringSync();
  final windows =
      File('.github/workflows/windows-release.yml').readAsStringSync();
  final updater =
      File('lib/features/updater/update_service.dart').readAsStringSync();
  for (final name in <String>[
    'android-universal.apk',
    'android-armeabi-v7a.apk',
    'android-arm64-v8a.apk',
    'android-x86_64.apk'
  ]) {
    if (!android.contains(name)) fail('Android workflow asset mismatch: $name');
  }
  if (!windows.contains('windows-x64-setup.exe') ||
      !updater.contains('windows-x64-setup.exe') ||
      !updater.contains('android-universal.apk'))
    fail('Updater/workflow asset names disagree.');
}

void main(List<String> arguments) {
  verifyConfiguration();
  for (final path in arguments) {
    validate(File(path));
  }
  stdout.writeln(
      'Configuration and ${arguments.length} generated outputs are structurally valid.');
}
