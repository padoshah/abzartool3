final class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.url, required this.size});
  factory ReleaseAsset.fromJson(Map<String, Object?> json) => ReleaseAsset(name: json['name']! as String, url: json['browser_download_url']! as String, size: json['size']! as int);
  final String name;
  final String url;
  final int size;
}
final class AppRelease {
  const AppRelease({required this.version, required this.notes, required this.assets});
  factory AppRelease.fromJson(Map<String, Object?> json) => AppRelease(version: (json['tag_name']! as String).replaceFirst('v', ''), notes: (json['body'] as String?) ?? '', assets: (json['assets']! as List<Object?>).map((item) => ReleaseAsset.fromJson(item! as Map<String, Object?>)).toList(growable: false));
  final String version;
  final String notes;
  final List<ReleaseAsset> assets;
}
