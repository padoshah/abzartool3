import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class PdfRepairScreen extends StatefulWidget {
  const PdfRepairScreen({super.key});
  @override
  State<PdfRepairScreen> createState() => _PdfRepairScreenState();
}

class _PdfRepairScreenState extends State<PdfRepairScreen> {
  bool running = false;
  String? output;
  Object? error;
  Future<void> repair() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      final root = await StorageService().temporaryJobs();
      final result = p.join(root.path,
          '${p.basenameWithoutExtension(files.first.path)}-repaired.pdf');
      await NativeOperations.repairPdf(files.first.path, result);
      if (mounted) setState(() => output = result);
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FeatureScaffold(
        title: l.repairPdf,
        child: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
          FilledButton.icon(
              onPressed: running ? null : repair,
              icon: const Icon(Icons.healing),
              label: Text(l.repairPdf)),
          if (running) const LinearProgressIndicator(),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (output != null)
            ListTile(
                title: Text(l.completed),
                trailing: IconButton(
                    tooltip: l.open,
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => FileService().open(output!))),
          Text(l.sourceUnchanged, textAlign: TextAlign.center)
        ]));
  }
}
