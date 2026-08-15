import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/models/file_entry.dart';
import '../../core/models/job_report.dart';
import '../../core/models/job_spec.dart';
import '../../core/native/job_isolate.dart';
import '../../core/native/native_error.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/storage_service.dart';

enum QueueStatus { waiting, running, completed, failed, cancelled }
final class QueueItem {
  const QueueItem({required this.file, this.status = QueueStatus.waiting, this.progress = 0, this.outputPath, this.report, this.error});
  final FileEntry file;
  final QueueStatus status;
  final double progress;
  final String? outputPath;
  final JobReport? report;
  final Object? error;
  QueueItem copyWith({QueueStatus? status, double? progress, String? outputPath, JobReport? report, Object? error}) => QueueItem(file: file, status: status ?? this.status, progress: progress ?? this.progress, outputPath: outputPath ?? this.outputPath, report: report ?? this.report, error: error ?? this.error);
}
final class ConvertState {
  const ConvertState({this.items = const <QueueItem>[], this.targetFormat = 'pdf', this.dpi = 150, this.quality = 90});
  final List<QueueItem> items;
  final String targetFormat;
  final int dpi;
  final int quality;
  ConvertState copyWith({List<QueueItem>? items, String? targetFormat, int? dpi, int? quality}) => ConvertState(items: items ?? this.items, targetFormat: targetFormat ?? this.targetFormat, dpi: dpi ?? this.dpi, quality: quality ?? this.quality);
}

final convertControllerProvider = StateNotifierProvider<ConvertController, ConvertState>((ref) => ConvertController(ref));

final class ConvertController extends StateNotifier<ConvertState> {
  ConvertController(this.ref) : super(const ConvertState());
  final Ref ref;
  final _files = FileService();
  final _storage = StorageService();
  final _history = HistoryService();
  final _executions = <int, JobExecution>{};

  Future<void> pick() async {
    final selected = await _files.pickFiles();
    if (selected.isNotEmpty) state = state.copyWith(items: selected.map((file) => QueueItem(file: file)).toList(growable: false));
  }
  Future<void> addDroppedFiles(List<String> paths) async {
    final selected = <FileEntry>[];
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      selected.add(FileEntry(path: path, name: p.basename(path), extension: p.extension(path).replaceFirst('.', '').toLowerCase(), size: await file.length()));
    }
    if (selected.isNotEmpty) state = state.copyWith(items: selected.map((file) => QueueItem(file: file)).toList(growable: false));
  }
  void setTarget(String target) => state = state.copyWith(targetFormat: target);
  void setDpi(int dpi) => state = state.copyWith(dpi: dpi);
  void setQuality(int quality) => state = state.copyWith(quality: quality);

  Future<void> run() async {
    for (var index = 0; index < state.items.length; index++) {
      if (state.items[index].status == QueueStatus.cancelled) continue;
      final file = state.items[index].file;
      final settings = ref.read(settingsProvider).valueOrNull;
      final output = await _storage.reserveOutput(file.path, state.targetFormat, preferredDirectory: settings?.outputDirectory);
      _replace(index, state.items[index].copyWith(status: QueueStatus.running, progress: 0.02, outputPath: output.path));
      final spec = JobSpec(inputPath: file.path, outputPath: output.path, sourceFormat: file.extension, targetFormat: state.targetFormat, dpi: state.dpi, quality: state.quality);
      try {
        final execution = await JobIsolate.start(spec);
        _executions[index] = execution;
        await for (final event in execution.events) {
          if (event is JobProgress) _replace(index, state.items[index].copyWith(progress: event.value));
          if (event is JobFinished) {
            _replace(index, state.items[index].copyWith(status: QueueStatus.completed, progress: 1, report: event.report));
            await _history.add(spec, event.report);
          }
        }
      } catch (error) {
        final cancelled = error is NativeException && error.code == NativeErrorCode.cancelled;
        _replace(index, state.items[index].copyWith(status: cancelled ? QueueStatus.cancelled : QueueStatus.failed, error: error));
      } finally {
        _executions.remove(index);
      }
    }
  }
  void cancel(int index) { _executions[index]?.cancel(); _replace(index, state.items[index].copyWith(status: QueueStatus.cancelled)); }
  void retry(int index) => _replace(index, state.items[index].copyWith(status: QueueStatus.waiting, progress: 0));
  void _replace(int index, QueueItem item) { final items = [...state.items]; items[index] = item; state = state.copyWith(items: items); }
  @override
  void dispose() { for (final execution in _executions.values) execution.cancel(); _history.close(); super.dispose(); }
}
