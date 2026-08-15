import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../models/job_report.dart';
import '../models/job_spec.dart';
import 'abzar_bindings.g.dart';
import 'native_error.dart';
import 'native_library.dart';

typedef _ProgressCallbackNative = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Double,
  ffi.Pointer<ffi.Char>,
);

abstract final class FfiBridge {
  static JobReport convert(JobSpec spec) => convertJson(spec.encode());

  static JobReport convertJson(String specification) {
    final bindings = NativeLibrary.load().bindings;
    final json = specification.toNativeUtf8();
    final job = bindings.abz_job_create(json.cast<ffi.Char>());
    calloc.free(json);
    if (job == ffi.nullptr) {
      throw const NativeException(NativeErrorCode.invalidArgument, 'Invalid native job specification.');
    }
    try {
      final callback = ffi.nullptr.cast<ffi.NativeFunction<_ProgressCallbackNative>>();
      final result = bindings.abz_job_run(job, callback, ffi.nullptr);
      final reportPointer = bindings.abz_job_report_json(job);
      final reportJson = reportPointer.cast<Utf8>().toDartString();
      final report = JobReport.fromJson(jsonDecode(reportJson)! as Map<String, Object?>);
      if (result != 0) {
        throw NativeException(NativeErrorCode.fromValue(result), report.error);
      }
      return report;
    } finally {
      bindings.abz_job_destroy(job);
    }
  }
}
