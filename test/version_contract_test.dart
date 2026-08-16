import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updater and workflows share exact asset names', () {
    final updater =
        File('lib/features/updater/update_service.dart').readAsStringSync();
    final android =
        File('.github/workflows/android-release.yml').readAsStringSync();
    final windows =
        File('.github/workflows/windows-release.yml').readAsStringSync();
    expect(updater, contains('android-universal.apk'));
    expect(android, contains('android-universal.apk'));
    expect(updater, contains('windows-x64-setup.exe'));
    expect(windows, contains('windows-x64-setup.exe'));
  });
}
