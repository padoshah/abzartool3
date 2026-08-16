import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/services/file_service.dart';
import '../editor_controls.dart';

class JsonEditorScreen extends StatefulWidget {
  const JsonEditorScreen({super.key});
  @override
  State<JsonEditorScreen> createState() => _JsonEditorScreenState();
}

class _JsonEditorScreenState extends State<JsonEditorScreen> {
  final text = TextEditingController(text: '{}');
  String? error;
  String? path;

  void prettify() {
    try {
      text.text =
          const JsonEncoder.withIndent('  ').convert(jsonDecode(text.text));
      setState(() => error = null);
    } catch (value) {
      setState(() => error = value.toString());
    }
  }

  void minify() {
    try {
      text.text = jsonEncode(jsonDecode(text.text));
      setState(() => error = null);
    } catch (value) {
      setState(() => error = value.toString());
    }
  }

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) {
      text.text = await File(files.first.path).readAsString();
      path = files.first.path;
      prettify();
    }
  }

  Future<void> save() async {
    try {
      jsonDecode(text.text);
    } catch (value) {
      setState(() => error = value.toString());
      return;
    }
    final output = path ??
        await FilePicker.platform.saveFile(
            fileName: 'document.json',
            type: FileType.custom,
            allowedExtensions: const <String>['json']);
    if (output != null) {
      await File(output).writeAsString(text.text, flush: true);
      path = output;
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.jsonEditor), actions: <Widget>[
        EditorControls(onSave: save),
        IconButton(
            tooltip: l10n.openFile,
            icon: const Icon(Icons.folder_open),
            onPressed: open)
      ]),
      body: Column(
        children: <Widget>[
          Wrap(spacing: 8, children: <Widget>[
            TextButton.icon(
                onPressed: prettify,
                icon: const Icon(Icons.format_align_left),
                label: Text(l10n.prettify)),
            TextButton.icon(
                onPressed: minify,
                icon: const Icon(Icons.compress),
                label: Text(l10n.minify)),
            TextButton.icon(
                onPressed: prettify,
                icon: const Icon(Icons.check),
                label: Text(l10n.validate))
          ]),
          if (error != null)
            MaterialBanner(content: Text(error!), actions: <Widget>[
              TextButton(
                  onPressed: () => setState(() => error = null),
                  child: Text(l10n.cancel))
            ]),
          Expanded(
              child: TextField(
                  controller: text,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16)))),
        ],
      ),
    );
  }
}
