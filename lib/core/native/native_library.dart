import 'dart:ffi';
import 'dart:io';

import 'abzar_bindings.g.dart';

final class NativeLibrary {
  NativeLibrary._(this.bindings);

  final AbzarBindings bindings;

  static NativeLibrary? _instance;

  static NativeLibrary load() {
    final existing = _instance;
    if (existing != null) return existing;
    final DynamicLibrary library;
    if (Platform.isAndroid) {
      library = DynamicLibrary.open('libabzar_core.so');
    } else if (Platform.isWindows) {
      library = DynamicLibrary.open('abzar_core.dll');
    } else if (Platform.isLinux) {
      library = DynamicLibrary.open('libabzar_core.so');
    } else {
      throw UnsupportedError('AbzarFile native core supports Android, Windows, and Linux development tests.');
    }
    final result = NativeLibrary._(AbzarBindings(library));
    if (result.bindings.abz_abi_version() != 1) {
      throw StateError('Incompatible AbzarFile native ABI.');
    }
    _instance = result;
    return result;
  }
}
