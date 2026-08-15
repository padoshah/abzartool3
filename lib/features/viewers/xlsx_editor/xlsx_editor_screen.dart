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

class XlsxEditorScreen extends StatefulWidget {
  const XlsxEditorScreen({super.key});
  @override
  State<XlsxEditorScreen> createState() => _XlsxEditorScreenState();
}

class _XlsxEditorScreenState extends State<XlsxEditorScreen> {
  final cells = List.generate(40, (_) => List.generate(12, (_) => TextEditingController()));
  int row = 0, col = 0;
  bool running = false;
  String? path;

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() => running = true);
    try {
      final text = await NativeOperations.extractText(files.first.path, files.first.extension);
      for (final (rowIndex, line) in text.split('\n').take(cells.length).indexed) {
        for (final (columnIndex, value) in line.split('\t').take(cells[rowIndex].length).indexed) cells[rowIndex][columnIndex].text = value;
      }
      path = files.first.path;
    } finally { if (mounted) setState(() => running = false); }
  }

  String _csv() => cells.map((columns) => columns.map((cell) => '"${cell.text.replaceAll('"', '""')}"').join(',')).join('\n');

  Future<void> save() async {
    final output = path ?? await FilePicker.platform.saveFile(fileName: 'workbook.xlsx', type: FileType.custom, allowedExtensions: const <String>['xlsx']);
    if (output == null) return;
    setState(() => running = true);
    try {
      final root = await StorageService().temporaryJobs();
      final source = File(p.join(root.path, 'sheet-edit-${DateTime.now().microsecondsSinceEpoch}.csv'));
      await source.writeAsString(_csv(), flush: true);
      await NativeOperations.convert(JobSpec(inputPath: source.path, outputPath: output, sourceFormat: 'csv', targetFormat: 'xlsx'));
      await source.delete(); path = output;
    } finally { if (mounted) setState(() => running = false); }
  }

  @override
  void dispose() { for (final row in cells) { for (final cell in row) cell.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.xlsxEditor), actions: <Widget>[EditorControls(onSave: running ? null : save), IconButton(tooltip: l10n.openFile, icon: const Icon(Icons.folder_open), onPressed: running ? null : open)]),
      body: Column(children: <Widget>[
        if (running) const LinearProgressIndicator(),
        TextField(controller: cells[row][col], decoration: InputDecoration(prefixText: '${String.fromCharCode(65 + col)}${row + 1}  ', labelText: l10n.formula), onChanged: (_) => setState(() {})),
        Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: cells.first.length * 120, child: ListView.builder(itemCount: cells.length, itemBuilder: (context, rowIndex) => SizedBox(height: 44, child: Row(children: List.generate(cells[rowIndex].length, (columnIndex) => SizedBox(width: 120, child: TextField(controller: cells[rowIndex][columnIndex], onTap: () => setState(() { row = rowIndex; col = columnIndex; }), decoration: InputDecoration(border: const OutlineInputBorder(), filled: rowIndex == row && columnIndex == col, isDense: true))))))))),
        NavigationBar(selectedIndex: 0, destinations: <NavigationDestination>[NavigationDestination(icon: const Icon(Icons.grid_on), label: '${l10n.pages} 1'), NavigationDestination(icon: const Icon(Icons.add), label: l10n.insert)]),
      ]),
    );
  }
}
