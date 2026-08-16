import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/annotate/annotate_screen.dart';
import '../features/compress/compress_screen.dart';
import '../features/convert/convert_screen.dart';
import '../features/esign/esign_screen.dart';
import '../features/extract_text/extract_text_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/merge/merge_screen.dart';
import '../features/pdf_tools/pdf_object_editor_screen.dart';
import '../features/pdf_tools/pdf_repair_screen.dart';
import '../features/pdf_tools/pdf_structure_screen.dart';
import '../features/pdf_tools/pdf_tools_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/security/security_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/split/split_screen.dart';
import '../features/toolbox/toolbox_screen.dart';
import '../features/updater/update_dialog.dart';
import '../features/viewers/docx_editor/docx_editor_screen.dart';
import '../features/viewers/html_editor/html_editor_screen.dart';
import '../features/viewers/image_viewer/image_viewer_screen.dart';
import '../features/viewers/json_editor/json_editor_screen.dart';
import '../features/viewers/pdf_viewer/pdf_viewer_screen.dart';
import '../features/viewers/pptx_editor/pptx_editor_screen.dart';
import '../features/viewers/txt_editor/txt_editor_screen.dart';
import '../features/viewers/xlsx_editor/xlsx_editor_screen.dart';
import '../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/convert', builder: (_, __) => const ConvertScreen()),
        GoRoute(path: '/toolbox', builder: (_, __) => const ToolboxScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/compress', builder: (_, __) => const CompressScreen()),
    GoRoute(path: '/annotate', builder: (_, __) => const AnnotateScreen()),
    GoRoute(path: '/merge', builder: (_, __) => const MergeScreen()),
    GoRoute(path: '/split', builder: (_, __) => const SplitScreen()),
    GoRoute(path: '/extract', builder: (_, __) => const ExtractTextScreen()),
    GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
    GoRoute(path: '/esign', builder: (_, __) => const EsignScreen()),
    GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
    GoRoute(path: '/pdf-tools', builder: (_, __) => const PdfToolsScreen()),
    GoRoute(path: '/pdf-repair', builder: (_, __) => const PdfRepairScreen()),
    GoRoute(
        path: '/pdf-objects',
        builder: (_, __) => const PdfObjectEditorScreen()),
    GoRoute(
        path: '/pdf-structure', builder: (_, __) => const PdfStructureScreen()),
    GoRoute(path: '/updates', builder: (_, __) => const UpdateScreen()),
    GoRoute(path: '/viewer/pdf', builder: (_, __) => const PdfViewerScreen()),
    GoRoute(path: '/viewer/docx', builder: (_, __) => const DocxEditorScreen()),
    GoRoute(path: '/viewer/xlsx', builder: (_, __) => const XlsxEditorScreen()),
    GoRoute(path: '/viewer/pptx', builder: (_, __) => const PptxEditorScreen()),
    GoRoute(path: '/viewer/txt', builder: (_, __) => const TxtEditorScreen()),
    GoRoute(path: '/viewer/json', builder: (_, __) => const JsonEditorScreen()),
    GoRoute(path: '/viewer/html', builder: (_, __) => const HtmlEditorScreen()),
    GoRoute(
        path: '/viewer/image', builder: (_, __) => const ImageViewerScreen()),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text(state.error.toString()))),
);
