import 'package:abzarfile/core/native/native_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native error numbers remain ABI stable', () {
    expect(NativeErrorCode.fromValue(7), NativeErrorCode.ocrUnavailable);
    expect(NativeErrorCode.fromValue(999), NativeErrorCode.internal);
  });
}
