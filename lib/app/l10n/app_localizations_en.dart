// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AbzarFile';

  @override
  String get home => 'Home';

  @override
  String get convert => 'Convert';

  @override
  String get toolbox => 'Toolbox';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get offlinePitch => 'Your offline document workshop';

  @override
  String get selectFiles => 'Select files';

  @override
  String get selectOutput => 'Choose output folder';

  @override
  String get targetFormat => 'Target format';

  @override
  String get startConversion => 'Start conversion';

  @override
  String get conversionQueue => 'Conversion queue';

  @override
  String get noJobs => 'No jobs yet';

  @override
  String get completed => 'Completed';

  @override
  String get failed => 'Failed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get working => 'Working…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get documents => 'Documents';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get compress => 'Compress';

  @override
  String get merge => 'Merge';

  @override
  String get split => 'Split';

  @override
  String get extractText => 'Extract text';

  @override
  String get scan => 'Scan document';

  @override
  String get esign => 'Sign PDF';

  @override
  String get security => 'Passwords & security';

  @override
  String get pdfTools => 'PDF tools';

  @override
  String get annotate => 'Annotate';

  @override
  String get recentFiles => 'Recent files';

  @override
  String get compressionLevel => 'Compression level';

  @override
  String get estimatedSize => 'Estimated output size';

  @override
  String get qualityImpact => 'Estimated quality impact';

  @override
  String get sameTypeOnly => 'Merge accepts files of the same format only.';

  @override
  String get reorderHint => 'Drag files to change their order.';

  @override
  String get splitMode => 'Split mode';

  @override
  String get pageRange => 'Page range';

  @override
  String get everyNPages => 'Every N pages';

  @override
  String get byHeading => 'By heading';

  @override
  String get bySheet => 'By sheet';

  @override
  String get bySlide => 'By slide';

  @override
  String get copyAll => 'Copy all';

  @override
  String wordCount(int count) {
    return '$count words';
  }

  @override
  String characterCount(int count) {
    return '$count characters';
  }

  @override
  String get camera => 'Camera';

  @override
  String get importImages => 'Import images';

  @override
  String get capture => 'Capture';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get signature => 'Signature';

  @override
  String get draw => 'Draw';

  @override
  String get type => 'Type';

  @override
  String get importPng => 'Import PNG';

  @override
  String get addPassword => 'Add password';

  @override
  String get removePassword => 'Remove password';

  @override
  String get password => 'Password';

  @override
  String get ownerPassword => 'Owner password';

  @override
  String get permissions => 'Permissions';

  @override
  String get neverStored =>
      'Passwords are used in memory and are never stored.';

  @override
  String get pdfViewer => 'PDF viewer';

  @override
  String get docxEditor => 'Word editor';

  @override
  String get xlsxEditor => 'Spreadsheet editor';

  @override
  String get pptxEditor => 'Presentation editor';

  @override
  String get txtEditor => 'Text editor';

  @override
  String get jsonEditor => 'JSON editor';

  @override
  String get htmlEditor => 'HTML editor';

  @override
  String get imageViewer => 'Image viewer';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save as';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get search => 'Search';

  @override
  String get replace => 'Replace';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get underline => 'Underline';

  @override
  String get fontFamily => 'Font family';

  @override
  String get fontSize => 'Font size';

  @override
  String get textColor => 'Text color';

  @override
  String get backgroundColor => 'Background color';

  @override
  String get readMode => 'Read mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get sepia => 'Sepia';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get persian => 'Persian';

  @override
  String get theme => 'Theme';

  @override
  String get defaultDpi => 'Default DPI';

  @override
  String get updateChecks => 'Check for updates';

  @override
  String get checkNow => 'Check now';

  @override
  String get updateAvailable => 'A new version is available.';

  @override
  String get updateNow => 'Update now';

  @override
  String get later => 'Later';

  @override
  String get skipVersion => 'Skip this version';

  @override
  String get upToDate => 'AbzarFile is up to date.';

  @override
  String get offline => 'An update check could not be completed.';

  @override
  String get openFile => 'Open file';

  @override
  String get unsupportedFormat => 'This format is not available in this build.';

  @override
  String get corruptInput => 'The input file is damaged or unsupported.';

  @override
  String get ocrUnavailable => 'OCR is not installed in this build.';

  @override
  String get unknownError => 'The operation could not be completed.';

  @override
  String get sourceUnchanged => 'The original file is never modified.';

  @override
  String get pages => 'Pages';

  @override
  String get rotate => 'Rotate';

  @override
  String get crop => 'Crop';

  @override
  String get delete => 'Delete';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get insert => 'Insert';

  @override
  String get watermark => 'Watermark';

  @override
  String get metadata => 'Metadata';

  @override
  String get presentationPreview => 'Presentation preview';

  @override
  String get formula => 'Formula';

  @override
  String get prettify => 'Prettify';

  @override
  String get minify => 'Minify';

  @override
  String get validate => 'Validate';

  @override
  String get source => 'Source';

  @override
  String get preview => 'Preview';

  @override
  String get lineNumbers => 'Line numbers';

  @override
  String get wordWrap => 'Word wrap';

  @override
  String get chooseFileFirst => 'Choose a file to begin.';

  @override
  String get nativeUnavailable =>
      'The native engine could not be loaded. Build libabzar_core for this platform.';

  @override
  String get featureWorkspace =>
      'Choose inputs and options; processing remains on this device.';

  @override
  String get outputDirectory => 'Output directory';

  @override
  String get defaultQuality => 'Default quality';

  @override
  String get originalFilter => 'Original';

  @override
  String get bwFilter => 'Black & white';

  @override
  String get enhancedFilter => 'Enhanced';

  @override
  String get grayscaleFilter => 'Grayscale';

  @override
  String get blackWhiteFilter => 'Black and white';

  @override
  String get magicColorFilter => 'Magic color';

  @override
  String get perspectiveCorrection => 'Perspective correction';

  @override
  String get brightness => 'Brightness';

  @override
  String get contrast => 'Contrast';

  @override
  String get repairPdf => 'Repair PDF';

  @override
  String get pdfObjectEditor => 'PDF object editor';

  @override
  String get searchText => 'Existing text';

  @override
  String get replacementText => 'Replacement text';

  @override
  String get objectName => 'Image object name (optional)';

  @override
  String get pageIndex => 'Page number';

  @override
  String get replaceTextObject => 'Replace text object';

  @override
  String get replaceImageObject => 'Replace image object';

  @override
  String get selectReplacementImage => 'Select replacement image';

  @override
  String get addImageObject => 'Add image object';

  @override
  String get imageX => 'Image X';

  @override
  String get imageY => 'Image Y';

  @override
  String get imageWidth => 'Image width';

  @override
  String get imageHeight => 'Image height';

  @override
  String get deleteImageObject => 'Delete image object';

  @override
  String get pdfStructureEditor => 'PDF forms and outlines';

  @override
  String get flattenForms => 'Flatten forms and annotations';

  @override
  String get bookmarkTitle => 'Bookmark title';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get annotationText => 'Annotation text';

  @override
  String get addTextAnnotation => 'Add text annotation';

  @override
  String get selectPdf => 'Select PDF';

  @override
  String get flattenSignature => 'Flatten signature into PDF';
}
