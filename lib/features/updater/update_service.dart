import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/hash.dart';
import 'update_models.dart';

final class UpdateService {
  static const endpoint = 'https://api.github.com/repos/padoshah/abzartool3/releases/latest';

  Future<AppRelease?> check() async {
    final response = await http.get(Uri.parse(endpoint), headers: const <String, String>{'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'}).timeout(const Duration(seconds: 12));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw HttpException('GitHub Releases returned ${response.statusCode}.');
    final release = AppRelease.fromJson(response.body.isEmpty ? <String, Object?>{} : jsonDecode(response.body)! as Map<String, Object?>);
    final installed = (await PackageInfo.fromPlatform()).version;
    final skipped = (await SharedPreferences.getInstance()).getString('skippedUpdateVersion');
    return _newer(release.version, installed) && skipped != release.version ? release : null;
  }

  bool _newer(String candidate, String current) {
    final left = candidate.split('.').map(int.parse).toList();
    final right = current.split('.').map(int.parse).toList();
    for (var index = 0; index < 3; index++) { final a = index < left.length ? left[index] : 0; final b = index < right.length ? right[index] : 0; if (a != b) return a > b; }
    return false;
  }

  Future<File> downloadAndVerify(AppRelease release, void Function(double) progress) async {
    final suffix = Platform.isAndroid ? 'android-universal.apk' : 'windows-x64-setup.exe';
    final expectedName = 'AbzarFile-v${release.version}-$suffix';
    final asset = release.assets.where((item) => item.name == expectedName).first;
    final checksumName = Platform.isAndroid ? 'checksums-android.txt' : 'checksums-windows.txt';
    final checksumAsset = release.assets.where((item) => item.name == checksumName).first;
    final checksumResponse = await http.get(Uri.parse(checksumAsset.url)).timeout(const Duration(seconds: 20));
    if (checksumResponse.statusCode != 200) throw const HttpException('Unable to download release checksums.');
    final expected = RegExp('([a-fA-F0-9]{64})\\s+\\*?${RegExp.escape(expectedName)}').firstMatch(checksumResponse.body)?.group(1)?.toLowerCase();
    if (expected == null) throw const FormatException('The release checksum file has no matching entry.');

    final directory = await getTemporaryDirectory();
    final output = File(p.join(directory.path, expectedName));
    final partial = File('${output.path}.part');
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _downloadResumable(asset, partial, progress);
        if (await sha256File(partial) != expected) { await partial.delete(); throw const FormatException('The downloaded update checksum does not match.'); }
        if (await output.exists()) await output.delete();
        return partial.rename(output.path);
      } catch (error) {
        lastError = error;
        if (attempt < 2) await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw lastError ?? const HttpException('Update download failed.');
  }

  Future<void> _downloadResumable(ReleaseAsset asset, File partial, void Function(double) progress) async {
    var received = await partial.exists() ? await partial.length() : 0;
    if (received > asset.size) { await partial.delete(); received = 0; }
    final request = http.Request('GET', Uri.parse(asset.url));
    if (received > 0) request.headers['Range'] = 'bytes=$received-';
    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 && response.statusCode != 206) throw HttpException('Download returned ${response.statusCode}.');
    if (response.statusCode == 200 && received > 0) { received = 0; await partial.writeAsBytes(const <int>[]); }
    final sink = partial.openWrite(mode: received > 0 ? FileMode.append : FileMode.write);
    try {
      await for (final bytes in response.stream) { sink.add(bytes); received += bytes.length; progress(asset.size == 0 ? 0 : received / asset.size); }
    } finally { await sink.close(); }
    if (asset.size > 0 && received != asset.size) throw const HttpException('The update download is incomplete.');
  }
}
