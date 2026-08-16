import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/storage_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class EsignScreen extends StatefulWidget {
  const EsignScreen({super.key});
  @override
  State<EsignScreen> createState() => _EsignScreenState();
}

class _EsignScreenState extends State<EsignScreen> {
  final strokes = <List<Offset>>[];
  final typed = TextEditingController();
  final boundary = GlobalKey();
  int mode = 0;
  Uint8List? imported;
  FileEntry? pdf;
  String? signedOutput;
  bool running = false;

  Future<void> importPng() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['png'],
        withData: true);
    if (result != null)
      setState(() => imported = result.files.single.bytes ??
          File(result.files.single.path!).readAsBytesSync());
  }

  Future<Uint8List?> capture() async {
    final render =
        boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (render == null) return null;
    final image = await render.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> save() async {
    final bytes = await capture();
    if (bytes == null) return;
    final output = await FilePicker.platform.saveFile(
        fileName: 'signature.png',
        type: FileType.custom,
        allowedExtensions: const <String>['png']);
    if (output != null) await File(output).writeAsBytes(bytes, flush: true);
  }

  Future<void> selectPdf() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty) setState(() => pdf = files.first);
  }

  Future<void> flatten() async {
    if (pdf == null) return;
    setState(() => running = true);
    try {
      final bytes = await capture();
      if (bytes == null) return;
      final root = await StorageService().temporaryJobs();
      final signature = File(p.join(
          root.path, 'signature-${DateTime.now().microsecondsSinceEpoch}.png'));
      await signature.writeAsBytes(bytes, flush: true);
      final output = p.join(
          root.path, '${p.basenameWithoutExtension(pdf!.path)}-signed.pdf');
      await NativeOperations.addPdfImage(
          inputPath: pdf!.path,
          outputPath: output,
          pageIndex: 0,
          imagePath: signature.path,
          imageFormat: 'png',
          x: 360,
          y: 72,
          width: 180,
          height: 72);
      await signature.delete();
      if (mounted) setState(() => signedOutput = output);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  @override
  void dispose() {
    typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeatureScaffold(
      title: l10n.esign,
      actions: <Widget>[
        IconButton(
            tooltip: l10n.undo,
            icon: const Icon(Icons.undo),
            onPressed: strokes.isEmpty
                ? null
                : () => setState(() => strokes.removeLast())),
        IconButton(
            tooltip: l10n.save, icon: const Icon(Icons.save), onPressed: save),
      ],
      child: Column(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                  segments: <ButtonSegment<int>>[
                    ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.gesture),
                        label: Text(l10n.draw)),
                    ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.text_fields),
                        label: Text(l10n.type)),
                    ButtonSegment(
                        value: 2,
                        icon: const Icon(Icons.image),
                        label: Text(l10n.importPng))
                  ],
                  selected: <int>{
                    mode
                  },
                  onSelectionChanged: (values) {
                    setState(() => mode = values.first);
                    if (values.first == 2) importPng();
                  })),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: switch (mode) {
                      0 => GestureDetector(
                          onPanStart: (details) => setState(() =>
                              strokes.add(<Offset>[details.localPosition])),
                          onPanUpdate: (details) => setState(
                              () => strokes.last.add(details.localPosition)),
                          child: CustomPaint(
                              painter: _SignaturePainter(strokes),
                              size: Size.infinite)),
                      1 => Center(
                          child: TextField(
                              controller: typed,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 48, fontStyle: FontStyle.italic),
                              decoration: InputDecoration(
                                  hintText: l10n.signature,
                                  border: InputBorder.none))),
                      _ => imported == null
                          ? Center(child: Text(l10n.importPng))
                          : Center(child: Image.memory(imported!)),
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: <Widget>[
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: running ? null : selectPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(pdf?.name ?? l10n.selectPdf))),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton.icon(
                        onPressed: running || pdf == null ? null : flatten,
                        icon: const Icon(Icons.layers),
                        label: Text(l10n.flattenSignature)))
              ])),
          if (running) const LinearProgressIndicator(),
          if (signedOutput != null)
            ListTile(
                title: Text(l10n.completed),
                trailing: IconButton(
                    tooltip: l10n.open,
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => FileService().open(signedOutput!))),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
