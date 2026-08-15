import 'dart:io';

import 'package:flutter/services.dart';

final class PlatformOpenService {
  PlatformOpenService._();
  static const _channel = MethodChannel('com.padoshah.abzarfile/open_file');

  static Future<void> initialize(Future<void> Function(String path) onOpen) async {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async { if (call.method == 'openFile') { final path = call.arguments as String?; if (path != null) await onOpen(path); } });
      final initial = await _channel.invokeMethod<String>('initialFile');
      if (initial != null) await onOpen(initial);
    } else if (Platform.isWindows) {
      for (final argument in Platform.executableArguments) { if (await File(argument).exists()) { await onOpen(argument); break; } }
    }
  }
}
