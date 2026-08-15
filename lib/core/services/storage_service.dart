import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class StorageService {
  Future<Directory> temporaryJobs() async {
    final root = await getTemporaryDirectory();
    final directory = Directory(p.join(root.path, 'abzarfile', 'jobs'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> reserveOutput(String inputPath, String targetFormat, {String? preferredDirectory}) async {
    final directory = preferredDirectory == null ? await temporaryJobs() : await Directory(preferredDirectory).create(recursive: true);
    final stem = p.basenameWithoutExtension(inputPath);
    var candidate = File(p.join(directory.path, '$stem.$targetFormat'));
    var index = 2;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '$stem-$index.$targetFormat'));
      index++;
    }
    return candidate;
  }

  Future<void> cleanOldTemporaryFiles() async {
    final directory = await temporaryJobs();
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    await for (final entity in directory.list()) {
      final stat = await entity.stat();
      if (stat.modified.isBefore(threshold)) await entity.delete(recursive: true);
    }
  }
}
