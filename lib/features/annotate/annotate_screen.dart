import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/l10n/app_localizations.dart';
import '../../shared/widgets/feature_scaffold.dart';

class AnnotateScreen extends StatefulWidget {
  const AnnotateScreen({super.key});
  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  final strokes = <List<Offset>>[];
  final boundary = GlobalKey();
  Color color = Colors.red;
  double width = 3;

  Future<void> save() async {
    final render = boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (render == null) return;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = await FilePicker.platform.saveFile(fileName: 'annotation.png', type: FileType.custom, allowedExtensions: const <String>['png']);
    if (bytes != null && output != null) await File(output).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeatureScaffold(
      title: l10n.annotate,
      actions: <Widget>[
        IconButton(tooltip: l10n.undo, icon: const Icon(Icons.undo), onPressed: strokes.isEmpty ? null : () => setState(() => strokes.removeLast())),
        IconButton(tooltip: l10n.save, icon: const Icon(Icons.save), onPressed: strokes.isEmpty ? null : save),
      ],
      child: Column(children: <Widget>[
        Wrap(children: <Widget>[
          IconButton(tooltip: l10n.annotate, icon: const Icon(Icons.edit), onPressed: () => setState(() { color = Colors.red; width = 3; })),
          IconButton(tooltip: l10n.textColor, icon: const Icon(Icons.highlight), onPressed: () => setState(() { color = Colors.yellow.withValues(alpha: .6); width = 18; })),
          IconButton(tooltip: l10n.underline, icon: const Icon(Icons.format_underline), onPressed: () => setState(() { color = Colors.blue; width = 2; })),
          IconButton(tooltip: l10n.insert, icon: const Icon(Icons.arrow_right_alt), onPressed: () => setState(() { color = Colors.green; width = 5; })),
        ]),
        Expanded(child: RepaintBoundary(key: boundary, child: ColoredBox(color: Theme.of(context).colorScheme.surface, child: GestureDetector(onPanStart: (details) => setState(() => strokes.add(<Offset>[details.localPosition])), onPanUpdate: (details) => setState(() => strokes.last.add(details.localPosition)), child: CustomPaint(painter: _Ink(strokes, color, width), size: Size.infinite))))),
      ]),
    );
  }
}

class _Ink extends CustomPainter {
  _Ink(this.strokes, this.color, this.width);
  final List<List<Offset>> strokes;
  final Color color;
  final double width;
  @override
  void paint(Canvas canvas, Size size) { final paint = Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round; for (final stroke in strokes) { for (var index = 1; index < stroke.length; index++) canvas.drawLine(stroke[index - 1], stroke[index], paint); } }
  @override
  bool shouldRepaint(covariant _Ink oldDelegate) => true;
}
