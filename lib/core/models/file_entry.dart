final class FileEntry {
  const FileEntry(
      {required this.path,
      required this.name,
      required this.extension,
      required this.size,});
  final String path;
  final String name;
  final String extension;
  final int size;
}
