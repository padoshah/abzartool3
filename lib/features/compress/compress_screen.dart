import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/bytes.dart';
import '../../shared/widgets/feature_scaffold.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});
  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  double level = 5;
  FileEntry? input;
  String? outputPath;
  int? outputSize;
  Object? error;
  bool running = false;

  Future<void> pick() async {
    final selected = await FileService().pickFiles(multiple: false);
    if (selected.isNotEmpty)
      setState(() {
        input = selected.first;
        outputPath = null;
        outputSize = null;
        error = null;
      });
  }

  Future<void> compress() async {
    final source = input;
    if (source == null) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      final directory = await StorageService().temporaryJobs();
      final directFormat = const <String>{
        'png',
        'jpg',
        'jpeg',
        'webp',
        'docx',
        'xlsx',
        'pptx',
        'pdf'
      }.contains(source.extension);
      final extension = directFormat ? source.extension : 'abz';
      final output = p.join(directory.path,
          '${p.basenameWithoutExtension(source.path)}-compressed.$extension');
      await NativeOperations.compress(
          inputPath: source.path,
          outputPath: output,
          format: source.extension,
          level: level.round());
      final size = await File(output).length();
      if (mounted)
        setState(() {
          outputPath = output;
          outputSize = size;
        });
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduction = (level * 7).round();
    return FeatureScaffold(
      title: l10n.compress,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          FilledButton.icon(
              onPressed: running ? null : pick,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.selectFiles)),
          if (input != null)
            ListTile(
                title: Text(input!.name),
                subtitle: Text(formatBytes(input!.size))),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(l10n.compressionLevel,
                      style: Theme.of(context).textTheme.titleLarge),
                  Slider(
                      value: level,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: level.round().toString(),
                      onChanged: running
                          ? null
                          : (value) => setState(() => level = value)),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(l10n.estimatedSize),
                        Text('${100 - reduction}%')
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(l10n.qualityImpact),
                        Text('$reduction%')
                      ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: input == null || running ? null : compress,
              icon: running
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.compress),
              label: Text(l10n.compress)),
          if (outputPath != null && outputSize != null)
            Card(
                child: ListTile(
                    title: Text(l10n.completed),
                    subtitle: Text(
                        '${formatBytes(input!.size)} → ${formatBytes(outputSize!)}'),
                    trailing: IconButton(
                        tooltip: l10n.open,
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => FileService().open(outputPath!)))),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          Text(l10n.sourceUnchanged, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
