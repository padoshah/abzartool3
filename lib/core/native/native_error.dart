enum NativeErrorCode {
  ok(0),
  invalidArgument(1),
  io(2),
  unsupportedFormat(3),
  corruptInput(4),
  passwordRequired(5),
  wrongPassword(6),
  ocrUnavailable(7),
  cancelled(8),
  outOfMemory(9),
  internal(10),
  validation(11);

  const NativeErrorCode(this.value);
  final int value;

  static NativeErrorCode fromValue(int value) => values.firstWhere(
        (item) => item.value == value,
        orElse: () => internal,
      );
}

final class NativeException implements Exception {
  const NativeException(this.code, this.message);
  final NativeErrorCode code;
  final String message;
  @override
  String toString() => 'NativeException(${code.name}): $message';
}
