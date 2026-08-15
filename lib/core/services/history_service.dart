import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/job_report.dart';
import '../models/job_spec.dart';

final class _HistoryExecutorUser implements QueryExecutorUser {
  const _HistoryExecutorUser();
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) => executor.runCustom('CREATE TABLE IF NOT EXISTS job_history (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at INTEGER NOT NULL, spec_json TEXT NOT NULL, report_json TEXT NOT NULL)');
}

final class HistoryEntry {
  const HistoryEntry({required this.id, required this.createdAt, required this.spec, required this.report});
  final int id;
  final DateTime createdAt;
  final JobSpec spec;
  final JobReport report;
}

final class HistoryService {
  QueryExecutor? _executor;

  Future<QueryExecutor> _database() async {
    final current = _executor;
    if (current != null) return current;
    final support = await getApplicationSupportDirectory();
    final file = File(p.join(support.path, 'abzarfile.sqlite'));
    final database = NativeDatabase.createInBackground(file, enableMigrations: false);
    await database.ensureOpen(const _HistoryExecutorUser());
    _executor = database;
    return database;
  }

  Future<void> add(JobSpec spec, JobReport report) async {
    final db = await _database();
    await db.runInsert(
      'INSERT INTO job_history(created_at, spec_json, report_json) VALUES (?, ?, ?)',
      <Object?>[DateTime.now().millisecondsSinceEpoch, spec.encode(), jsonEncode(<String, Object>{'errorCode': report.errorCode, 'inputBytes': report.inputBytes, 'outputBytes': report.outputBytes, 'durationMs': report.durationMs, 'pageCount': report.pageCount, 'warningCount': report.warningCount, 'error': report.error})],
    );
  }

  Future<List<HistoryEntry>> list({int limit = 100}) async {
    final db = await _database();
    final rows = await db.runSelect('SELECT id, created_at, spec_json, report_json FROM job_history ORDER BY id DESC LIMIT ?', <Object?>[limit]);
    return rows.map((row) {
      final specJson = jsonDecode(row['spec_json']! as String)! as Map<String, Object?>;
      final spec = JobSpec(inputPath: specJson['inputPath']! as String, outputPath: specJson['outputPath']! as String, sourceFormat: specJson['sourceFormat']! as String, targetFormat: specJson['targetFormat']! as String, dpi: specJson['dpi']! as int, quality: specJson['quality']! as int, stitchPages: specJson['stitchPages']! as bool, embedImages: specJson['embedImages']! as bool);
      return HistoryEntry(id: row['id']! as int, createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int), spec: spec, report: JobReport.fromJson(jsonDecode(row['report_json']! as String)! as Map<String, Object?>));
    }).toList(growable: false);
  }

  Future<void> clear() async => (await _database()).runDelete('DELETE FROM job_history', const <Object?>[]);
  Future<void> close() async { await _executor?.close(); _executor = null; }
}
