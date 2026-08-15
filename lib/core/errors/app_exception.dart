sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}
final class FileOperationException extends AppException { const FileOperationException(super.message); }
final class ConversionException extends AppException { const ConversionException(super.message); }
final class UpdateException extends AppException { const UpdateException(super.message); }
