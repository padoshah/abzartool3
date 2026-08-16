import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../models/file_entry.dart';

final class FileService {
  Future<List<FileEntry>> pickFiles({bool multiple = true}) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: multiple);
    if (result == null) return const [];
    final entries = <FileEntry>[];
    for (final item in result.files) {
      final path = item.path;
      if (path == null) continue;
      entries.add(FileEntry(
          path: path,
          name: item.name,
          extension: p.extension(path).replaceFirst('.', '').toLowerCase(),
          size: item.size));
    }
    return entries;
  }

  Future<void> open(String path) async => OpenFilex.open(path);
  Future<void> share(String path) async =>
      Share.shareXFiles(<XFile>[XFile(path)]);
  Future<bool> exists(String path) => File(path).exists();
}
