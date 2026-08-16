import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../../core/utils/bytes.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final service = HistoryService();
  late Future<List<HistoryEntry>> entries = service.list();
  final running = <int>{};

  Future<void> rerun(HistoryEntry entry) async {
    setState(() => running.add(entry.id));
    try {
      final report = await NativeOperations.convert(entry.spec);
      await service.add(entry.spec, report);
      if (mounted) setState(() => entries = service.list());
    } finally {
      if (mounted) setState(() => running.remove(entry.id));
    }
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(title: Text(l10n.history)),
        FutureBuilder<List<HistoryEntry>>(
          future: entries,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <HistoryEntry>[];
            if (snapshot.connectionState != ConnectionState.done)
              return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()));
            if (data.isEmpty)
              return SliverFillRemaining(
                  child: Center(child: Text(l10n.noJobs)));
            return SliverList.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data[index];
                return ListTile(
                  leading: running.contains(entry.id)
                      ? const CircularProgressIndicator()
                      : Icon(entry.report.succeeded
                          ? Icons.check_circle_outline
                          : Icons.error_outline),
                  title: Text(
                      '${entry.spec.sourceFormat.toUpperCase()} → ${entry.spec.targetFormat.toUpperCase()}'),
                  subtitle: Text(
                      '${formatBytes(entry.report.inputBytes)} → ${formatBytes(entry.report.outputBytes)}'),
                  trailing: Wrap(
                    children: <Widget>[
                      IconButton(
                          tooltip: l10n.retry,
                          icon: const Icon(Icons.refresh),
                          onPressed: running.contains(entry.id)
                              ? null
                              : () => rerun(entry)),
                      IconButton(
                          tooltip: l10n.open,
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () =>
                              FileService().open(entry.spec.outputPath)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
