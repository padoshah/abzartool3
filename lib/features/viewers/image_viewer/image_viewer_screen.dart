import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../app/l10n/app_localizations.dart';
import '../../../core/services/file_service.dart';
import '../editor_controls.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key});
  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  img.Image? image;
  Uint8List? preview;

  void update(img.Image next) { image = next; preview = Uint8List.fromList(img.encodePng(next)); setState(() {}); }

  Future<void> open() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isEmpty) return;
    final decoded = img.decodeImage(await File(files.first.path).readAsBytes());
    if (decoded != null) update(decoded);
  }

  void rotate() { final current = image; if (current != null) update(img.copyRotate(current, angle: 90)); }
  void crop() { final current = image; if (current != null) { final width = (current.width * .8).round(); final height = (current.height * .8).round(); update(img.copyCrop(current, x: (current.width - width) ~/ 2, y: (current.height - height) ~/ 2, width: width, height: height)); } }
  void grayscale() { final current = image; if (current != null) update(img.grayscale(current.clone())); }

  Future<void> save() async {
    final current = image;
    if (current == null) return;
    final output = await FilePicker.platform.saveFile(fileName: 'edited.png', type: FileType.custom, allowedExtensions: const <String>['png', 'jpg']);
    if (output == null) return;
    final bytes = output.toLowerCase().endsWith('.jpg') ? img.encodeJpg(current, quality: 92) : img.encodePng(current);
    await File(output).writeAsBytes(bytes, flush: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.imageViewer), actions: <Widget>[EditorControls(onSave: image == null ? null : save)]),
      body: Column(children: <Widget>[
        Wrap(children: <Widget>[
          TextButton.icon(onPressed: open, icon: const Icon(Icons.folder_open), label: Text(l10n.openFile)),
          TextButton.icon(onPressed: image == null ? null : rotate, icon: const Icon(Icons.rotate_right), label: Text(l10n.rotate)),
          TextButton.icon(onPressed: image == null ? null : crop, icon: const Icon(Icons.crop), label: Text(l10n.crop)),
          TextButton.icon(onPressed: image == null ? null : grayscale, icon: const Icon(Icons.tune), label: Text(l10n.annotate)),
        ]),
        Expanded(child: preview == null ? Center(child: Text(l10n.chooseFileFirst)) : InteractiveViewer(minScale: .2, maxScale: 8, child: Center(child: Image.memory(preview!)))),
      ]),
    );
  }
}
