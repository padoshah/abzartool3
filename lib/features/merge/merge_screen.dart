import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});
  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  List<FileEntry> files = <FileEntry>[];
  String? output;
  Object? error;
  bool running = false;

  Future<void> pick() async {
    final selected = await FileService().pickFiles();
    if (selected.map((entry) => entry.extension).toSet().length > 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).sameTypeOnly)));
      return;
    }
    setState(() { files = selected; output = null; error = null; });
  }

  Future<void> merge() async {
    if (files.length < 2) return;
    setState(() { running = true; error = null; });
    try {
      final directory = await StorageService().temporaryJobs();
      final format = files.first.extension;
      final path = p.join(directory.path, '${p.basenameWithoutExtension(files.first.path)}-merged.$format');
      await NativeOperations.merge(inputPaths: files.map((entry) => entry.path).toList(growable: false), outputPath: path, sourceFormat: format, targetFormat: format);
      if (mounted) setState(() => output = path);
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
      title: l10n.merge,
      child: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: <Widget>[
            Text(l10n.sameTypeOnly),
            Text(l10n.reorderHint),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: running ? null : pick, icon: const Icon(Icons.add), label: Text(l10n.selectFiles)),
          ]),
        ),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() { if (newIndex > oldIndex) newIndex--; files.insert(newIndex, files.removeAt(oldIndex)); });
            },
            children: files.map((file) => ListTile(key: ValueKey(file.path), leading: const Icon(Icons.drag_handle), title: Text(file.name), trailing: IconButton(icon: const Icon(Icons.close), tooltip: l10n.delete, onPressed: running ? null : () => setState(() => files.remove(file)))) .toList(growable: false),
          ),
        ),
        if (error != null) Text(error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (output != null) ListTile(title: Text(l10n.completed), trailing: IconButton(tooltip: l10n.open, icon: const Icon(Icons.open_in_new), onPressed: () => FileService().open(output!))),
        Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: files.length < 2 || running ? null : merge, icon: const Icon(Icons.call_merge), label: Text(l10n.merge))),
      ]),
    );
  }
}
