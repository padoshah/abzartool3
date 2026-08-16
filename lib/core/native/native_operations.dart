import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../models/job_report.dart';
import '../models/job_spec.dart';
import 'abzar_bindings.g.dart';
import 'native_error.dart';
import 'native_library.dart';

abstract final class NativeOperations {
  static Future<JobReport> convert(JobSpec spec) =>
      Isolate.run(() => _convert(spec.encode()));

  static Future<void> compress({
    required String inputPath,
    required String outputPath,
    required String format,
    required int level,
  }) =>
      Isolate.run(() => _compress(inputPath, outputPath, format, level));

  static Future<void> merge({
    required List<String> inputPaths,
    required String outputPath,
    required String sourceFormat,
    required String targetFormat,
  }) =>
      Isolate.run(
          () => _merge(inputPaths, outputPath, sourceFormat, targetFormat));

  static Future<List<String>> split({
    required String inputPath,
    required String outputDirectory,
    required String format,
    required List<String> ranges,
  }) =>
      Isolate.run(() => _split(inputPath, outputDirectory, format, ranges));

  static Future<String> extractText(String inputPath, String sourceFormat) =>
      Isolate.run(() => _extractText(inputPath, sourceFormat));

  static Future<void> encrypt(
          String inputPath, String outputPath, String password) =>
      Isolate.run(() => _crypt(inputPath, outputPath, password, true));

  static Future<void> decrypt(
          String inputPath, String outputPath, String password) =>
      Isolate.run(() => _crypt(inputPath, outputPath, password, false));

  static Future<void> replacePdfText({
    required String inputPath,
    required String outputPath,
    required String search,
    required String replacement,
    int pageIndex = -1,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final find = search.toNativeUtf8();
        final replace = replacement.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_replace_text(input.cast(),
              output.cast(), find.cast(), replace.cast(), pageIndex, error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(find);
          calloc.free(replace);
          calloc.free(error);
        }
      });

  static Future<void> deletePdfImage({
    required String inputPath,
    required String outputPath,
    required int pageIndex,
    required String objectName,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final name = objectName.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_delete_image(
              input.cast(), output.cast(), pageIndex, name.cast(), error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(name);
          calloc.free(error);
        }
      });

  static Future<void> addPdfImage({
    required String inputPath,
    required String outputPath,
    required int pageIndex,
    required String imagePath,
    required String imageFormat,
    required double x,
    required double y,
    required double width,
    required double height,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final image = imagePath.toNativeUtf8();
        final format = imageFormat.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_add_image(
              input.cast(),
              output.cast(),
              pageIndex,
              image.cast(),
              format.cast(),
              x,
              y,
              width,
              height,
              error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(image);
          calloc.free(format);
          calloc.free(error);
        }
      });

  static Future<void> replacePdfImage({
    required String inputPath,
    required String outputPath,
    required int pageIndex,
    String objectName = '',
    required String replacementPath,
    required String replacementFormat,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final name = objectName.toNativeUtf8();
        final replacement = replacementPath.toNativeUtf8();
        final format = replacementFormat.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_replace_image(
              input.cast(),
              output.cast(),
              pageIndex,
              name.cast(),
              replacement.cast(),
              format.cast(),
              error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(name);
          calloc.free(replacement);
          calloc.free(format);
          calloc.free(error);
        }
      });

  static Future<void> flattenPdf(String inputPath, String outputPath) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code =
              bindings.abz_pdf_flatten(input.cast(), output.cast(), error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(error);
        }
      });

  static Future<void> addPdfBookmark({
    required String inputPath,
    required String outputPath,
    required int pageIndex,
    required String title,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final bookmarkTitle = title.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_add_bookmark(input.cast(),
              output.cast(), pageIndex, bookmarkTitle.cast(), error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(bookmarkTitle);
          calloc.free(error);
        }
      });

  static Future<void> addPdfAnnotation({
    required String inputPath,
    required String outputPath,
    required int pageIndex,
    required String text,
    required double x,
    required double y,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final annotationText = text.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_add_annotation(input.cast(),
              output.cast(), pageIndex, annotationText.cast(), x, y, error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(annotationText);
          calloc.free(error);
        }
      });

  static Future<void> repairPdf(String inputPath, String outputPath) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code =
              bindings.abz_pdf_repair(input.cast(), output.cast(), error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(error);
        }
      });

  static Future<void> protectPdf({
    required String inputPath,
    required String outputPath,
    required String userPassword,
    required String ownerPassword,
    required bool allowPrint,
    required bool allowCopy,
    required bool allowModify,
    required bool allowAnnotate,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final user = userPassword.toNativeUtf8();
        final owner = ownerPassword.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_set_password(
            input.cast(),
            output.cast(),
            user.cast(),
            owner.cast(),
            allowPrint ? 1 : 0,
            allowCopy ? 1 : 0,
            allowModify ? 1 : 0,
            allowAnnotate ? 1 : 0,
            error,
          );
          _throwIfFailed(bindings, code, error.value);
        } finally {
          final userBytes = user.cast<ffi.Uint8>();
          final ownerBytes = owner.cast<ffi.Uint8>();
          for (var i = 0; i < utf8.encode(userPassword).length; i++) {
            userBytes[i] = 0;
          }
          for (var i = 0; i < utf8.encode(ownerPassword).length; i++) {
            ownerBytes[i] = 0;
          }
          calloc.free(input);
          calloc.free(output);
          calloc.free(user);
          calloc.free(owner);
          calloc.free(error);
        }
      });

  static Future<void> unprotectPdf(
          String inputPath, String outputPath, String password) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final secret = password.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_pdf_remove_password(
              input.cast(), output.cast(), secret.cast(), error);
          _throwIfFailed(bindings, code, error.value);
        } finally {
          final bytes = secret.cast<ffi.Uint8>();
          for (var i = 0; i < utf8.encode(password).length; i++) {
            bytes[i] = 0;
          }
          calloc.free(input);
          calloc.free(output);
          calloc.free(secret);
          calloc.free(error);
        }
      });

  static Future<void> processScan({
    required String inputPath,
    required String outputPath,
    required String format,
    required bool perspective,
    required int filter,
    required double brightness,
    required double contrast,
  }) =>
      Isolate.run(() {
        final bindings = NativeLibrary.load().bindings;
        final input = inputPath.toNativeUtf8();
        final output = outputPath.toNativeUtf8();
        final type = format.toNativeUtf8();
        final error = calloc<ffi.Pointer<ffi.Char>>();
        try {
          final code = bindings.abz_process_scan_image(
            input.cast(),
            output.cast(),
            type.cast(),
            perspective ? 1 : 0,
            filter,
            brightness,
            contrast,
            error,
          );
          _throwIfFailed(bindings, code, error.value);
        } finally {
          calloc.free(input);
          calloc.free(output);
          calloc.free(type);
          calloc.free(error);
        }
      });

  static JobReport _convert(String specification) {
    final bindings = NativeLibrary.load().bindings;
    final json = specification.toNativeUtf8();
    final job = bindings.abz_job_create(json.cast<ffi.Char>());
    calloc.free(json);
    if (job == ffi.nullptr) {
      throw const NativeException(
          NativeErrorCode.invalidArgument, 'Invalid native job specification.');
    }
    try {
      final callback =
          ffi.nullptr.cast<ffi.NativeFunction<_ProgressCallbackNative>>();
      final result = bindings.abz_job_run(job, callback, ffi.nullptr);
      final reportPointer = bindings.abz_job_report_json(job);
      final reportJson = reportPointer.cast<Utf8>().toDartString();
      final report =
          JobReport.fromJson(jsonDecode(reportJson)! as Map<String, Object?>);
      if (result != 0) {
        throw NativeException(NativeErrorCode.fromValue(result), report.error);
      }
      return report;
    } finally {
      bindings.abz_job_destroy(job);
    }
  }

  static void _compress(String input, String output, String format, int level) {
    final bindings = NativeLibrary.load().bindings;
    final inputPointer = input.toNativeUtf8();
    final outputPointer = output.toNativeUtf8();
    final formatPointer = format.toNativeUtf8();
    final error = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final code = bindings.abz_compress_file(
        inputPointer.cast(),
        outputPointer.cast(),
        formatPointer.cast(),
        level,
        error,
      );
      _throwIfFailed(bindings, code, error.value);
    } finally {
      calloc.free(inputPointer);
      calloc.free(outputPointer);
      calloc.free(formatPointer);
      calloc.free(error);
    }
  }

  static void _merge(
      List<String> inputs, String output, String source, String target) {
    final bindings = NativeLibrary.load().bindings;
    final pathsPointer = jsonEncode(inputs).toNativeUtf8();
    final outputPointer = output.toNativeUtf8();
    final sourcePointer = source.toNativeUtf8();
    final targetPointer = target.toNativeUtf8();
    final error = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final code = bindings.abz_merge_files(
        pathsPointer.cast(),
        outputPointer.cast(),
        sourcePointer.cast(),
        targetPointer.cast(),
        error,
      );
      _throwIfFailed(bindings, code, error.value);
    } finally {
      calloc.free(pathsPointer);
      calloc.free(outputPointer);
      calloc.free(sourcePointer);
      calloc.free(targetPointer);
      calloc.free(error);
    }
  }

  static List<String> _split(
      String input, String directory, String format, List<String> ranges) {
    final bindings = NativeLibrary.load().bindings;
    final inputPointer = input.toNativeUtf8();
    final directoryPointer = directory.toNativeUtf8();
    final formatPointer = format.toNativeUtf8();
    final rangesPointer = jsonEncode(ranges).toNativeUtf8();
    final outputs = calloc<ffi.Pointer<ffi.Char>>();
    final error = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final code = bindings.abz_split_file(
        inputPointer.cast(),
        directoryPointer.cast(),
        formatPointer.cast(),
        rangesPointer.cast(),
        outputs,
        error,
      );
      _throwIfFailed(bindings, code, error.value);
      final value = outputs.value.cast<Utf8>().toDartString();
      return (jsonDecode(value)! as List<Object?>).cast<String>();
    } finally {
      if (outputs.value != ffi.nullptr)
        bindings.abz_free(outputs.value.cast<ffi.Void>());
      calloc.free(inputPointer);
      calloc.free(directoryPointer);
      calloc.free(formatPointer);
      calloc.free(rangesPointer);
      calloc.free(outputs);
      calloc.free(error);
    }
  }

  static String _extractText(String input, String format) {
    final bindings = NativeLibrary.load().bindings;
    final inputPointer = input.toNativeUtf8();
    final formatPointer = format.toNativeUtf8();
    final text = calloc<ffi.Pointer<ffi.Char>>();
    final error = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final code = bindings.abz_extract_text(
          inputPointer.cast(), formatPointer.cast(), text, error);
      _throwIfFailed(bindings, code, error.value);
      return text.value.cast<Utf8>().toDartString();
    } finally {
      if (text.value != ffi.nullptr)
        bindings.abz_free(text.value.cast<ffi.Void>());
      calloc.free(inputPointer);
      calloc.free(formatPointer);
      calloc.free(text);
      calloc.free(error);
    }
  }

  static void _crypt(
      String input, String output, String password, bool encrypt) {
    final bindings = NativeLibrary.load().bindings;
    final inputPointer = input.toNativeUtf8();
    final outputPointer = output.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final error = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final code = encrypt
          ? bindings.abz_encrypt_container(inputPointer.cast(),
              outputPointer.cast(), passwordPointer.cast(), error)
          : bindings.abz_decrypt_container(inputPointer.cast(),
              outputPointer.cast(), passwordPointer.cast(), error);
      _throwIfFailed(bindings, code, error.value);
    } finally {
      final passwordBytes = passwordPointer.cast<ffi.Uint8>();
      for (var index = 0; index < utf8.encode(password).length; index++) {
        passwordBytes[index] = 0;
      }
      calloc.free(inputPointer);
      calloc.free(outputPointer);
      calloc.free(passwordPointer);
      calloc.free(error);
    }
  }

  static void _throwIfFailed(
      AbzarBindings bindings, int code, ffi.Pointer<ffi.Char> error) {
    if (code == 0) return;
    final message = error == ffi.nullptr
        ? 'Native operation failed.'
        : error.cast<Utf8>().toDartString();
    if (error != ffi.nullptr) bindings.abz_free(error.cast<ffi.Void>());
    throw NativeException(NativeErrorCode.fromValue(code), message);
  }
}

typedef _ProgressCallbackNative = ffi.Void Function(
    ffi.Pointer<ffi.Void>, ffi.Double, ffi.Pointer<ffi.Char>);
