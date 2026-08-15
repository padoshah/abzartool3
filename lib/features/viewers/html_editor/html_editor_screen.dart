import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/services/file_service.dart';
import '../editor_controls.dart';

class HtmlEditorScreen extends StatefulWidget {
  const HtmlEditorScreen({super.key});
  @override
  State<HtmlEditorScreen> createState() => _HtmlEditorScreenState();
}

class _HtmlEditorScreenState extends State<HtmlEditorScreen> {
  final source = TextEditingController(text: '<!doctype html>\n<html><body><h1>AbzarFile</h1></body></html>');
  String? path;

  String plain(String value) => value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) { source.text = await File(files.first.path).readAsString(); path = files.first.path; setState(() {}); }
  }

  Future<void> save() async {
    final output = path ?? await FilePicker.platform.saveFile(fileName: 'document.html', type: FileType.custom, allowedExtensions: const <String>['html', 'htm']);
    if (output != null) { await File(output).writeAsString(source.text, flush: true); path = output; }
  }

  @override
  void dispose() { source.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.htmlEditor), actions: <Widget>[EditorControls(onSave: save), IconButton(tooltip: l10n.openFile, icon: const Icon(Icons.folder_open), onPressed: open)]),
      body: LayoutBuilder(builder: (context, constraints) {
        final sourcePane = Column(children: <Widget>[ListTile(title: Text(l10n.source)), Expanded(child: TextField(controller: source, onChanged: (_) => setState(() {}), maxLines: null, expands: true, style: const TextStyle(fontFamily: 'monospace'), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16))))]);
        final previewPane = Column(children: <Widget>[ListTile(title: Text(l10n.preview)), Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: SelectableText(plain(source.text), style: Theme.of(context).textTheme.bodyLarge)))]);
        return constraints.maxWidth > 700 ? Row(children: <Widget>[Expanded(child: sourcePane), const VerticalDivider(width: 1), Expanded(child: previewPane)]) : Column(children: <Widget>[Expanded(child: sourcePane), const Divider(), Expanded(child: previewPane)]);
      }),
    );
  }
}
