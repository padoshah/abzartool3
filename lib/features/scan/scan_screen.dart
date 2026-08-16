import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/models/job_spec.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final picker = ImagePicker();
  final pages = <XFile>[];
  bool running = false;
  String? output;
  Object? error;
  int filter = 0;
  double brightness = 0;
  double contrast = 1;
  bool perspective = false;

  Future<void> camera() async {
    final image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    if (image != null) setState(() => pages.add(image));
  }

  Future<void> images() async {
    final selected = await picker.pickMultiImage(imageQuality: 100);
    setState(() => pages.addAll(selected));
  }

  Future<void> exportPdf() async {
    setState(() {
      running = true;
      error = null;
    });
    try {
      final root = await StorageService().temporaryJobs();
      final processed = <String>[];
      for (final (index, page) in pages.indexed) {
        final extension =
            p.extension(page.path).replaceFirst('.', '').toLowerCase();
        final corrected = p.join(root.path,
            'scan-page-${DateTime.now().microsecondsSinceEpoch}-$index.png');
        await NativeOperations.processScan(
            inputPath: page.path,
            outputPath: corrected,
            format: extension,
            perspective: perspective,
            filter: filter,
            brightness: brightness,
            contrast: contrast);
        processed.add(corrected);
      }
      final result = p.join(
          root.path, 'scan-${DateTime.now().millisecondsSinceEpoch}.pdf');
      if (processed.length == 1) {
        await NativeOperations.convert(JobSpec(
            inputPath: processed.single,
            outputPath: result,
            sourceFormat: 'png',
            targetFormat: 'pdf',
            dpi: 300));
      } else {
        await NativeOperations.merge(
            inputPaths: processed,
            outputPath: result,
            sourceFormat: 'png',
            targetFormat: 'pdf');
      }
      for (final path in processed) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      if (mounted) setState(() => output = result);
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeatureScaffold(
      title: l10n.scan,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                FilledButton.icon(
                    onPressed: running ? null : camera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.camera)),
                OutlinedButton.icon(
                    onPressed: running ? null : images,
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.importImages)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: <ButtonSegment<int>>[
                ButtonSegment(value: 0, label: Text(l10n.originalFilter)),
                ButtonSegment(value: 1, label: Text(l10n.bwFilter)),
                ButtonSegment(value: 2, label: Text(l10n.enhancedFilter)),
              ],
              selected: <int>{filter},
              onSelectionChanged: running
                  ? null
                  : (selected) => setState(() => filter = selected.first),
            ),
          ),
          SwitchListTile(
              title: Text(l10n.perspectiveCorrection),
              value: perspective,
              onChanged: running
                  ? null
                  : (value) => setState(() => perspective = value)),
          Row(
            children: <Widget>[
              Expanded(
                child: Slider(
                  value: brightness,
                  min: -1,
                  max: 1,
                  label: l10n.brightness,
                  onChanged: running
                      ? null
                      : (value) => setState(() => brightness = value),
                ),
              ),
              Expanded(
                child: Slider(
                  value: contrast,
                  min: 0.5,
                  max: 2,
                  label: l10n.contrast,
                  onChanged: running
                      ? null
                      : (value) => setState(() => contrast = value),
                ),
              ),
            ],
          ),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  pages.insert(newIndex, pages.removeAt(oldIndex));
                });
              },
              children: pages
                  .map(
                    (page) => Card(
                      key: ValueKey(page.path),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(File(page.path)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => pages.remove(page)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (running) const LinearProgressIndicator(),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (output != null)
            ListTile(
                title: Text(l10n.completed),
                trailing: IconButton(
                    tooltip: l10n.open,
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => FileService().open(output!))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                  onPressed: pages.isEmpty || running ? null : exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.exportPdf))),
        ],
      ),
    );
  }
}
