import 'dart:io';
import 'package:flutter/services.dart';

abstract final class AndroidInstaller {
  static const _channel = MethodChannel('com.padoshah.abzarfile/installer');
  static Future<void> install(File apk) => _channel
      .invokeMethod<void>('installApk', <String, String>{'path': apk.path});
  static Future<void> openPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallSettings');
}
