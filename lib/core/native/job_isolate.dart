import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../models/job_report.dart';
import '../models/job_spec.dart';
import 'abzar_bindings.g.dart';
import 'native_error.dart';
import 'native_library.dart';

typedef _ProgressCallbackNative = ffi.Void Function(
    ffi.Pointer<ffi.Void>, ffi.Double, ffi.Pointer<ffi.Char>);

sealed class JobEvent {
  const JobEvent();
}

final class JobProgress extends JobEvent {
  const JobProgress(this.value);
  final double value;
}

final class JobFinished extends JobEvent {
  const JobFinished(this.report);
  final JobReport report;
}

final class JobExecution {
  JobExecution._(this._receivePort, this._isolate, this.events);
  final ReceivePort _receivePort;
  final Isolate _isolate;
  final Stream<JobEvent> events;
  int? _nativeAddress;
  bool _closed = false;

  void attachHandle(int address) => _nativeAddress = address;
  void cancel() {
    final address = _nativeAddress;
    if (address != null && !_closed)
      NativeLibrary.load()
          .bindings
          .abz_job_cancel(ffi.Pointer<AbzJob>.fromAddress(address));
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _receivePort.close();
  }

  void terminate() {
    _isolate.kill(priority: Isolate.immediate);
    close();
  }
}

abstract final class JobIsolate {
  static Future<JobExecution> start(JobSpec spec) async {
    final receive = ReceivePort();
    final controller = StreamController<JobEvent>();
    late JobExecution execution;
    final isolate = await Isolate.spawn<(String, SendPort)>(
        _entry, (spec.encode(), receive.sendPort),
        debugName: 'AbzarFile conversion');
    execution = JobExecution._(receive, isolate, controller.stream);
    receive.listen((message) {
      if (message is List<Object?> && message.isNotEmpty) {
        switch (message.first) {
          case 'handle':
            execution.attachHandle(message[1]! as int);
          case 'progress':
            controller.add(JobProgress(message[1]! as double));
          case 'finished':
            controller.add(JobFinished(JobReport.fromJson(
                jsonDecode(message[1]! as String)! as Map<String, Object?>)));
            controller.close();
            execution.close();
          case 'error':
            controller.addError(NativeException(
                NativeErrorCode.fromValue(message[1]! as int),
                message[2]! as String));
            controller.close();
            execution.close();
        }
      }
    });
    return execution;
  }

  static void _entry((String, SendPort) message) {
    final bindings = NativeLibrary.load().bindings;
    final json = message.$1.toNativeUtf8();
    final job = bindings.abz_job_create(json.cast<ffi.Char>());
    calloc.free(json);
    if (job == ffi.nullptr) {
      message.$2.send(<Object>[
        'error',
        NativeErrorCode.invalidArgument.value,
        'Invalid native job specification.'
      ]);
      return;
    }
    message.$2.send(<Object>['handle', job.address]);
    try {
      message.$2.send(<Object>['progress', .05]);
      final callback = ffi.NativeCallable<_ProgressCallbackNative>.isolateLocal(
          (ffi.Pointer<ffi.Void> userData, double progress,
              ffi.Pointer<ffi.Char> stage) {
        message.$2.send(
            <Object>['progress', progress, stage.cast<Utf8>().toDartString()]);
      });
      final result =
          bindings.abz_job_run(job, callback.nativeFunction, ffi.nullptr);
      callback.close();
      final report =
          bindings.abz_job_report_json(job).cast<Utf8>().toDartString();
      if (result == 0) {
        message.$2.send(<Object>['progress', 1.0]);
        message.$2.send(<Object>['finished', report]);
      } else {
        final parsed = jsonDecode(report)! as Map<String, Object?>;
        message.$2.send(<Object>[
          'error',
          result,
          (parsed['error'] as String?) ?? 'Native conversion failed.'
        ]);
      }
    } finally {
      bindings.abz_job_destroy(job);
    }
  }
}
