import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});
  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final range = TextEditingController();
  int mode = 0;
  FileEntry? input;
  List<String> outputs = const <String>[];
  Object? error;
  bool running = false;

  @override
  void dispose() {
    range.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final selected = await FileService().pickFiles(multiple: false);
    if (selected.isNotEmpty)
      setState(() {
        input = selected.first;
        outputs = const <String>[];
        error = null;
      });
  }

  Future<void> split() async {
    final file = input;
    if (file == null) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      final root = await StorageService().temporaryJobs();
      final directory = await root.createTemp('split-');
      final result = await NativeOperations.split(
          inputPath: file.path,
          outputDirectory: directory.path,
          format: file.extension,
          ranges: mode == 0 && range.text.trim().isNotEmpty
              ? <String>[range.text.trim()]
              : const <String>[]);
      if (mounted) setState(() => outputs = result);
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = <String>[
      l10n.pageRange,
      l10n.everyNPages,
      l10n.byHeading,
      l10n.bySheet,
      l10n.bySlide
    ];
    return FeatureScaffold(
      title: l10n.split,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          FilledButton.icon(
              onPressed: running ? null : pick,
              icon: const Icon(Icons.file_open),
              label: Text(l10n.selectFiles)),
          if (input != null) ListTile(title: Text(input!.name)),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
              initialValue: mode,
              decoration: InputDecoration(labelText: l10n.splitMode),
              items: modes.indexed
                  .map((item) =>
                      DropdownMenuItem(value: item.$1, child: Text(item.$2)))
                  .toList(),
              onChanged: running
                  ? null
                  : (value) => setState(() => mode = value ?? 0)),
          const SizedBox(height: 16),
          TextField(
              controller: range,
              enabled: mode <= 1 && !running,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: mode == 1 ? l10n.everyNPages : l10n.pageRange)),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: input == null || running ? null : split,
              child: Text(l10n.split)),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ...outputs.map((path) => ListTile(
              title: Text(path.split(RegExp(r'[/\\]')).last),
              trailing: IconButton(
                  tooltip: l10n.open,
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => FileService().open(path)))),
          const SizedBox(height: 8),
          Text(l10n.sourceUnchanged, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
