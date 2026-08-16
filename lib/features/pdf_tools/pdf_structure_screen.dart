import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class PdfStructureScreen extends StatefulWidget {
  const PdfStructureScreen({super.key});
  @override
  State<PdfStructureScreen> createState() => _PdfStructureScreenState();
}

class _PdfStructureScreenState extends State<PdfStructureScreen> {
  final page = TextEditingController(text: '1'),
      bookmark = TextEditingController(),
      annotation = TextEditingController(),
      x = TextEditingController(text: '36'),
      y = TextEditingController(text: '760');
  FileEntry? pdf;
  String? output;
  Object? error;
  bool running = false;
  Future<void> pick() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) setState(() => pdf = files.first);
  }

  Future<String> path(String action) async {
    final root = await StorageService().temporaryJobs();
    return p.join(
        root.path, '${p.basenameWithoutExtension(pdf!.path)}-$action.pdf');
  }

  Future<void> execute(
      Future<void> Function(String) operation, String action) async {
    if (pdf == null) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      final result = await path(action);
      await operation(result);
      if (mounted) setState(() => output = result);
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  void dispose() {
    for (final value in [page, bookmark, annotation, x, y]) {
      value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pageIndex = (int.tryParse(page.text) ?? 1) - 1;
    return FeatureScaffold(
        title: l.pdfStructureEditor,
        child: ListView(padding: const EdgeInsets.all(20), children: <Widget>[
          FilledButton.icon(
              onPressed: running ? null : pick,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(l.selectFiles)),
          if (pdf != null) ListTile(title: Text(pdf!.name)),
          TextField(
              controller: page,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.pageIndex)),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: running
                  ? null
                  : () => execute(
                      (result) =>
                          NativeOperations.flattenPdf(pdf!.path, result),
                      'flattened'),
              icon: const Icon(Icons.layers_clear),
              label: Text(l.flattenForms)),
          const Divider(height: 32),
          TextField(
              controller: bookmark,
              decoration: InputDecoration(labelText: l.bookmarkTitle)),
          FilledButton.icon(
              onPressed: running
                  ? null
                  : () => execute(
                      (result) => NativeOperations.addPdfBookmark(
                          inputPath: pdf!.path,
                          outputPath: result,
                          pageIndex: pageIndex,
                          title: bookmark.text),
                      'bookmarked'),
              icon: const Icon(Icons.bookmark_add),
              label: Text(l.addBookmark)),
          const Divider(height: 32),
          TextField(
              controller: annotation,
              decoration: InputDecoration(labelText: l.annotationText)),
          Row(children: <Widget>[
            Expanded(
                child: TextField(
                    controller: x,
                    decoration: InputDecoration(labelText: l.imageX))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: y,
                    decoration: InputDecoration(labelText: l.imageY)))
          ]),
          FilledButton.icon(
              onPressed: running
                  ? null
                  : () => execute(
                      (result) => NativeOperations.addPdfAnnotation(
                          inputPath: pdf!.path,
                          outputPath: result,
                          pageIndex: pageIndex,
                          text: annotation.text,
                          x: double.tryParse(x.text) ?? 36,
                          y: double.tryParse(y.text) ?? 760),
                      'annotated'),
              icon: const Icon(Icons.comment),
              label: Text(l.addTextAnnotation)),
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
