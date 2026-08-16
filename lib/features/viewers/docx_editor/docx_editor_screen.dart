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

class DocxEditorScreen extends StatefulWidget {
  const DocxEditorScreen({super.key});
  @override
  State<DocxEditorScreen> createState() => _DocxEditorScreenState();
}

class _DocxEditorScreenState extends State<DocxEditorScreen> {
  final document = TextEditingController();
  bool bold = false, italic = false, underline = false, running = false;
  Color textColor = Colors.black;
  Color background = Colors.white;
  String? path;

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() => running = true);
    try {
      document.text = await NativeOperations.extractText(
          files.first.path, files.first.extension);
      path = files.first.path;
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  Future<void> save() async {
    final output = path ??
        await FilePicker.platform.saveFile(
            fileName: 'document.docx',
            type: FileType.custom,
            allowedExtensions: const <String>['docx']);
    if (output == null) return;
    setState(() => running = true);
    try {
      final root = await StorageService().temporaryJobs();
      final source = File(p.join(
          root.path, 'docx-edit-${DateTime.now().microsecondsSinceEpoch}.txt'));
      await source.writeAsString(document.text, flush: true);
      await NativeOperations.convert(
        JobSpec(
          inputPath: source.path,
          outputPath: output,
          sourceFormat: 'txt',
          targetFormat: 'docx',
          applyDefaultStyle: true,
          fontFamily: 'Noto Sans',
          fontSize: 16,
        ),
      );
      await source.delete();
      path = output;
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  Future<void> replaceText() async {
    final find = TextEditingController();
    final replacement = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.replace),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  controller: find,
                  decoration: InputDecoration(labelText: l10n.search)),
              TextField(
                  controller: replacement,
                  decoration: InputDecoration(labelText: l10n.replace)),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.ok)),
          ],
        );
      },
    );
    if (accepted == true && find.text.isNotEmpty) {
      document.text = document.text.replaceAll(find.text, replacement.text);
    }
    find.dispose();
    replacement.dispose();
  }

  @override
  void dispose() {
    document.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : null,
      fontStyle: italic ? FontStyle.italic : null,
      decoration: underline ? TextDecoration.underline : null,
      fontSize: 16,
      color: textColor,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.docxEditor),
        actions: <Widget>[
          EditorControls(onSave: running ? null : save),
          IconButton(
            tooltip: l10n.openFile,
            icon: const Icon(Icons.folder_open),
            onPressed: running ? null : open,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (running) const LinearProgressIndicator(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: l10n.bold,
                  isSelected: bold,
                  icon: const Icon(Icons.format_bold),
                  onPressed: () => setState(() => bold = !bold),
                ),
                IconButton(
                  tooltip: l10n.italic,
                  isSelected: italic,
                  icon: const Icon(Icons.format_italic),
                  onPressed: () => setState(() => italic = !italic),
                ),
                IconButton(
                  tooltip: l10n.underline,
                  isSelected: underline,
                  icon: const Icon(Icons.format_underline),
                  onPressed: () => setState(() => underline = !underline),
                ),
                IconButton(
                  tooltip: l10n.textColor,
                  icon: const Icon(Icons.format_color_text),
                  onPressed: () => setState(() => textColor =
                      textColor == Colors.black ? Colors.blue : Colors.black),
                ),
                IconButton(
                  tooltip: l10n.backgroundColor,
                  icon: const Icon(Icons.format_color_fill),
                  onPressed: () => setState(() => background =
                      background == Colors.white
                          ? const Color(0xfffff4d6)
                          : Colors.white),
                ),
                IconButton(
                  tooltip: l10n.search,
                  icon: const Icon(Icons.find_replace),
                  onPressed: replaceText,
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(maxWidth: 1200),
                  decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: document,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16)),
                    style: style,
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
