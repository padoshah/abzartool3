import '../../app/l10n/app_localizations.dart';
import '../native/native_error.dart';

String localizeNativeError(AppLocalizations l10n, NativeErrorCode code) =>
    switch (code) {
      NativeErrorCode.unsupportedFormat => l10n.unsupportedFormat,
      NativeErrorCode.corruptInput => l10n.corruptInput,
      NativeErrorCode.ocrUnavailable => l10n.ocrUnavailable,
      NativeErrorCode.cancelled => l10n.cancelled,
      _ => l10n.unknownError,
    };
