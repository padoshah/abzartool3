import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/services/file_service.dart';
import '../editor_controls.dart';

class TxtEditorScreen extends StatefulWidget {
  const TxtEditorScreen({super.key});
  @override
  State<TxtEditorScreen> createState() => _TxtEditorScreenState();
}

class _TxtEditorScreenState extends State<TxtEditorScreen> {
  final text = TextEditingController();
  String? path;
  bool wrap = true, lines = false;
  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) {
      path = files.first.path;
      text.text = await File(path!).readAsString();
      setState(() {});
    }
  }

  Future<void> save() async {
    if (path != null) await File(path!).writeAsString(text.text, flush: true);
  }

  Future<void> findText() async {
    final query = TextEditingController();
    await showDialog<void>(
        context: context,
        builder: (context) {
          final l = AppLocalizations.of(context);
          return AlertDialog(
              title: Text(l.search),
              content: TextField(controller: query, autofocus: true),
              actions: <Widget>[
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.search))
              ]);
        });
    query.dispose();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text(l.txtEditor), actions: <Widget>[
          EditorControls(onSave: save),
          IconButton(
              tooltip: l.openFile,
              icon: const Icon(Icons.folder_open),
              onPressed: open)
        ]),
        body: Column(children: <Widget>[
          Material(
              child: Wrap(children: <Widget>[
            FilterChip(
                label: Text(l.lineNumbers),
                selected: lines,
                onSelected: (v) => setState(() => lines = v)),
            const SizedBox(width: 8),
            FilterChip(
                label: Text(l.wordWrap),
                selected: wrap,
                onSelected: (v) => setState(() => wrap = v)),
            IconButton(
                tooltip: l.search,
                icon: const Icon(Icons.search),
                onPressed: findText)
          ])),
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                if (lines)
                  Container(
                      width: 48,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Text(
                          List.generate('\n'.allMatches(text.text).length + 1,
                              (i) => '${i + 1}').join('\n'),
                          textAlign: TextAlign.end)),
                Expanded(
                    child: TextField(
                        controller: text,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16))))
              ]))
        ]));
  }
}
