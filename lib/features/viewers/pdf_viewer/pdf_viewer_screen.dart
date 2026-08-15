import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../app/l10n/app_localizations.dart';
import '../../../core/models/job_spec.dart';
import '../../../core/native/native_operations.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/storage_service.dart';
import '../editor_controls.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final text = TextEditingController();
  double zoom = 1;
  int turns = 0;
  bool running = false;

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() => running = true);
    try { text.text = await NativeOperations.extractText(files.first.path, files.first.extension); }
    finally { if (mounted) setState(() => running = false); }
  }

  Future<void> save() async {
    final output = await FilePicker.platform.saveFile(fileName: 'edited.pdf', type: FileType.custom, allowedExtensions: const <String>['pdf']);
    if (output == null) return;
    final root = await StorageService().temporaryJobs();
    final source = File(p.join(root.path, 'pdf-edit-${DateTime.now().microsecondsSinceEpoch}.txt'));
    await source.writeAsString(text.text, flush: true);
    await NativeOperations.convert(JobSpec(inputPath: source.path, outputPath: output, sourceFormat: 'txt', targetFormat: 'pdf'));
    await source.delete();
  }

  Future<void> searchText() async {
    final query = TextEditingController();
    await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(AppLocalizations.of(context).search), content: TextField(controller: query, autofocus: true), actions: <Widget>[FilledButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).search))]));
    query.dispose();
  }

  @override
  void dispose() { text.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pdfViewer), actions: <Widget>[IconButton(tooltip: l10n.openFile, icon: const Icon(Icons.folder_open), onPressed: running ? null : open), IconButton(tooltip: l10n.search, icon: const Icon(Icons.search), onPressed: searchText), EditorControls(onSave: text.text.isEmpty ? null : save)]),
      body: Row(children: <Widget>[
        SizedBox(width: 150, child: ListView.builder(itemCount: text.text.isEmpty ? 0 : 1, itemBuilder: (context, index) => Card(child: AspectRatio(aspectRatio: .7, child: Center(child: Text('${l10n.pages} ${index + 1}'))))),
        const VerticalDivider(width: 1),
        Expanded(child: Column(children: <Widget>[
          if (running) const LinearProgressIndicator(),
          Wrap(children: <Widget>[
            IconButton(tooltip: l10n.annotate, icon: const Icon(Icons.highlight), onPressed: () => setState(() => text.text += '\n• ')),
            IconButton(tooltip: l10n.esign, icon: const Icon(Icons.draw), onPressed: () => context.push('/esign')),
            IconButton(tooltip: l10n.rotate, icon: const Icon(Icons.rotate_right), onPressed: () => setState(() => turns = (turns + 1) % 4)),
            IconButton(tooltip: l10n.pages, icon: const Icon(Icons.view_agenda), onPressed: () => context.push('/pdf-tools')),
            SizedBox(width: 220, child: Slider(value: zoom, min: .5, max: 3, onChanged: (value) => setState(() => zoom = value))),
          ]),
          Expanded(child: InteractiveViewer(minScale: .5, maxScale: 5, child: Center(child: Transform.scale(scale: zoom, child: RotatedBox(quarterTurns: turns, child: Card(child: SizedBox(width: 595, height: 842, child: Padding(padding: const EdgeInsets.all(48), child: TextField(controller: text, maxLines: null, expands: true, decoration: const InputDecoration(border: InputBorder.none))))))))),
        ])),
      ]),
    );
  }
}
