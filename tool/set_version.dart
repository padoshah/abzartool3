import 'dart:io';

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}

String replaceOne(
    String source, RegExp pattern, String replacement, String label) {
  if (!pattern.hasMatch(source)) _fail('Unable to update $label.');
  return source.replaceFirst(pattern, replacement);
}

void main(List<String> arguments) {
  if (arguments.length != 1)
    _fail('Usage: dart run tool/set_version.dart vX.Y.Z');
  final match = RegExp(r'^v(\d+)\.(\d+)\.(\d+)$').firstMatch(arguments.single);
  if (match == null) _fail('Version must be a stable vX.Y.Z tag.');
  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  final patch = int.parse(match.group(3)!);
  if (minor > 99 || patch > 99)
    _fail(
        'Minor and patch must be 0 through 99 for the Android versionCode formula.');
  final version = '$major.$minor.$patch';
  final code = major * 10000 + minor * 100 + patch;
  final pubspecFile = File('pubspec.yaml');
  pubspecFile.writeAsStringSync(replaceOne(
      pubspecFile.readAsStringSync(),
      RegExp(r'^version:\s*[^\r\n]+', multiLine: true),
      'version: $version+$code',
      'pubspec version'));
  final rcFile = File('windows/runner/Runner.rc');
  var rc = rcFile.readAsStringSync();
  rc = replaceOne(
      rc,
      RegExp(r'#define VERSION_AS_NUMBER \d+,\d+,\d+,\d+'),
      '#define VERSION_AS_NUMBER $major,$minor,$patch,0',
      'Runner numeric version');
  rc = replaceOne(rc, RegExp(r'#define VERSION_AS_STRING "[^"]+"'),
      '#define VERSION_AS_STRING "$version"', 'Runner string version');
  rcFile.writeAsStringSync(rc);
  final issFile = File('installer/abzarfile.iss');
  issFile.writeAsStringSync(replaceOne(
      issFile.readAsStringSync(),
      RegExp(r'#define MyAppVersion "[^"]+"'),
      '#define MyAppVersion "$version"',
      'installer version'));
  final check = pubspecFile.readAsStringSync();
  if (!check.contains('version: $version+$code'))
    _fail('Version consistency check failed.');
  stdout.writeln('Version $version, Android versionCode $code');
}
