import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/errors/error_localizer.dart';
import '../../core/native/native_error.dart';
import '../../core/services/file_service.dart';
import '../../core/services/format_registry.dart';
import '../../core/utils/bytes.dart';
import 'convert_controller.dart';

class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(convertControllerProvider);
    final controller = ref.read(convertControllerProvider.notifier);
    final registry = ref.watch(formatRegistryProvider);
    final source =
        state.items.isEmpty ? 'txt' : state.items.first.file.extension;
    final targets = registry.valueOrNull?.targetsFor(source) ?? const [];
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(title: Text(l10n.convert)),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: <Widget>[
              FilledButton.icon(
                  onPressed: controller.pick,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.selectFiles)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue:
                    targets.any((item) => item.id == state.targetFormat)
                        ? state.targetFormat
                        : null,
                decoration: InputDecoration(labelText: l10n.targetFormat),
                items: targets
                    .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.label} (.${item.id})')))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) controller.setTarget(value);
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(segments: const <ButtonSegment<int>>[
                ButtonSegment(value: 72, label: Text('72 DPI')),
                ButtonSegment(value: 150, label: Text('150 DPI')),
                ButtonSegment(value: 300, label: Text('300 DPI')),
                ButtonSegment(value: 600, label: Text('600 DPI'))
              ], selected: <int>{
                state.dpi
              }, onSelectionChanged: (value) => controller.setDpi(value.first)),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: state.items.isEmpty ? null : controller.run,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startConversion)),
              const SizedBox(height: 24),
              Text(l10n.conversionQueue,
                  style: Theme.of(context).textTheme.titleLarge),
              if (state.items.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(l10n.noJobs))),
              ...state.items.indexed
                  .map((pair) => _QueueCard(index: pair.$1, item: pair.$2)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.index, required this.item});
  final int index;
  final QueueItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = switch (item.status) {
      QueueStatus.waiting => l10n.noJobs,
      QueueStatus.running => l10n.working,
      QueueStatus.completed => l10n.completed,
      QueueStatus.failed => l10n.failed,
      QueueStatus.cancelled => l10n.cancelled
    };
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(item.file.name),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${formatBytes(item.file.size)} · $status'),
              if (item.status == QueueStatus.running)
                LinearProgressIndicator(value: item.progress),
              if (item.report != null)
                Text(
                    '${formatBytes(item.report!.inputBytes)} → ${formatBytes(item.report!.outputBytes)}'),
              if (item.error is NativeException)
                Text(
                    localizeNativeError(
                        l10n, (item.error! as NativeException).code),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))
            ]),
        trailing: item.status == QueueStatus.completed
            ? IconButton(
                tooltip: l10n.open,
                icon: const Icon(Icons.open_in_new),
                onPressed: () => FileService().open(item.outputPath!))
            : item.status == QueueStatus.failed
                ? IconButton(
                    tooltip: l10n.retry,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref
                        .read(convertControllerProvider.notifier)
                        .retry(index))
                : IconButton(
                    tooltip: l10n.cancel,
                    icon: const Icon(Icons.close),
                    onPressed: () => ref
                        .read(convertControllerProvider.notifier)
                        .cancel(index)),
      ),
    );
  }
}
