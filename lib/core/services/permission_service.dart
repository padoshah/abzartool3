import 'dart:io';

final class PermissionService {
  Future<bool> canUseCamera() async => Platform.isAndroid || Platform.isWindows;
  Future<bool> canInstallPackages() async => Platform.isAndroid;
}
