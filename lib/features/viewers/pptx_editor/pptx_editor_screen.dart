import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../app/l10n/app_localizations.dart';
import '../../../core/models/job_spec.dart';
import '../../../core/native/native_operations.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/storage_service.dart';
import '../editor_controls.dart';

class PptxEditorScreen extends StatefulWidget {
  const PptxEditorScreen({super.key});
  @override
  State<PptxEditorScreen> createState() => _PptxEditorScreenState();
}

class _PptxEditorScreenState extends State<PptxEditorScreen> {
  final slides = <TextEditingController>[TextEditingController()];
  int selected = 0;
  bool running = false;
  String? path;

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() => running = true);
    try {
      final text = await NativeOperations.extractText(files.first.path, files.first.extension);
      for (final slide in slides) slide.dispose();
      slides.clear();
      for (final line in text.split('\n').where((line) => line.trim().isNotEmpty)) slides.add(TextEditingController(text: line));
      if (slides.isEmpty) slides.add(TextEditingController());
      selected = 0; path = files.first.path;
    } finally { if (mounted) setState(() => running = false); }
  }

  Future<void> save() async {
    final output = path ?? await FilePicker.platform.saveFile(fileName: 'presentation.pptx', type: FileType.custom, allowedExtensions: const <String>['pptx']);
    if (output == null) return;
    setState(() => running = true);
    try {
      final root = await StorageService().temporaryJobs();
      final parts = <String>[];
      for (final (index, slide) in slides.indexed) {
        final text = File(p.join(root.path, 'slide-${DateTime.now().microsecondsSinceEpoch}-$index.txt'));
        final part = p.setExtension(text.path, '.pptx');
        await text.writeAsString(slide.text, flush: true);
        await NativeOperations.convert(JobSpec(inputPath: text.path, outputPath: part, sourceFormat: 'txt', targetFormat: 'pptx'));
        await text.delete(); parts.add(part);
      }
      if (parts.length == 1) { await File(parts.single).copy(output); await File(parts.single).delete(); } else { await NativeOperations.merge(inputPaths: parts, outputPath: output, sourceFormat: 'pptx', targetFormat: 'pptx'); }
      for (final part in parts) { final file = File(part); if (await file.exists()) await file.delete(); }
      path = output;
    } finally { if (mounted) setState(() => running = false); }
  }

  Future<void> addImage() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) slides[selected].text += '\n${files.first.name}';
  }

  void preview() => showDialog<void>(context: context, builder: (context) => Dialog.fullscreen(child: Scaffold(appBar: AppBar(title: Text(AppLocalizations.of(context).presentationPreview)), body: Center(child: Text(slides[selected].text, style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center)))));

  @override
  void dispose() { for (final slide in slides) slide.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pptxEditor), actions: <Widget>[IconButton(tooltip: l10n.presentationPreview, icon: const Icon(Icons.play_arrow), onPressed: preview), EditorControls(onSave: running ? null : save), IconButton(tooltip: l10n.openFile, icon: const Icon(Icons.folder_open), onPressed: running ? null : open)]),
      body: Row(children: <Widget>[
        SizedBox(width: 180, child: ReorderableListView(onReorder: (oldIndex, newIndex) { setState(() { if (newIndex > oldIndex) newIndex--; slides.insert(newIndex, slides.removeAt(oldIndex)); selected = newIndex; }); }, children: slides.indexed.map((item) => Card(key: ValueKey(item.$2), child: ListTile(selected: selected == item.$1, onTap: () => setState(() => selected = item.$1), title: Text('${l10n.pages} ${item.$1 + 1}')))).toList())),
        const VerticalDivider(width: 1),
        Expanded(child: Column(children: <Widget>[
          if (running) const LinearProgressIndicator(),
          Wrap(children: <Widget>[
            IconButton(tooltip: l10n.insert, icon: const Icon(Icons.add), onPressed: () => setState(() => slides.add(TextEditingController()))),
            IconButton(tooltip: l10n.imageViewer, icon: const Icon(Icons.image), onPressed: addImage),
            IconButton(tooltip: l10n.annotate, icon: const Icon(Icons.category), onPressed: () => slides[selected].text += '\n• '),
            IconButton(tooltip: l10n.delete, icon: const Icon(Icons.delete), onPressed: slides.length == 1 ? null : () => setState(() { slides.removeAt(selected).dispose(); selected = 0; })),
          ]),
          Expanded(child: Center(child: AspectRatio(aspectRatio: 16 / 9, child: Card(child: Padding(padding: const EdgeInsets.all(36), child: TextField(controller: slides[selected], maxLines: null, expands: true, textAlignVertical: TextAlignVertical.center, textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none))))))),
        ])),
      ]),
    );
  }
}
