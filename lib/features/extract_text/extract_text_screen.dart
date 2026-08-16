import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class ExtractTextScreen extends StatefulWidget {
  const ExtractTextScreen({super.key});
  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  final controller = TextEditingController();
  final search = TextEditingController();
  bool running = false;
  Object? error;

  @override
  void dispose() {
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> extract() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      final value = await NativeOperations.extractText(
          files.first.path, files.first.extension);
      if (mounted) setState(() => controller.text = value);
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  Future<void> save() async {
    final path = await FilePicker.platform.saveFile(
        fileName: 'extracted.txt',
        allowedExtensions: const <String>['txt', 'md'],
        type: FileType.custom);
    if (path != null)
      await File(path).writeAsString(controller.text, flush: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final words = controller.text.trim().isEmpty
        ? 0
        : controller.text.trim().split(RegExp(r'\s+')).length;
    final query = search.text;
    final matches =
        query.isEmpty ? 0 : query.allMatches(controller.text).length;
    return FeatureScaffold(
      title: l10n.extractText,
      actions: <Widget>[
        IconButton(
            tooltip: l10n.copyAll,
            icon: const Icon(Icons.copy_all),
            onPressed: controller.text.isEmpty
                ? null
                : () =>
                    Clipboard.setData(ClipboardData(text: controller.text))),
        IconButton(
            tooltip: l10n.save,
            icon: const Icon(Icons.save_outlined),
            onPressed: controller.text.isEmpty ? null : save),
      ],
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: FilledButton.icon(
                        onPressed: running ? null : extract,
                        icon: const Icon(Icons.file_open),
                        label: Text(l10n.selectFiles))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: l10n.search, suffixText: '$matches'))),
              ],
            ),
          ),
          if (running) const LinearProgressIndicator(),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Expanded(
              child: TextField(
                  controller: controller,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20)))),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: <Widget>[
                Text(l10n.wordCount(words)),
                const Spacer(),
                Text(l10n.characterCount(controller.text.characters.length))
              ])),
        ],
      ),
    );
  }
}
