import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AbzarFile'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @toolbox.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get toolbox;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @offlinePitch.
  ///
  /// In en, this message translates to:
  /// **'Your offline document workshop'**
  String get offlinePitch;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select files'**
  String get selectFiles;

  /// No description provided for @selectOutput.
  ///
  /// In en, this message translates to:
  /// **'Choose output folder'**
  String get selectOutput;

  /// No description provided for @targetFormat.
  ///
  /// In en, this message translates to:
  /// **'Target format'**
  String get targetFormat;

  /// No description provided for @startConversion.
  ///
  /// In en, this message translates to:
  /// **'Start conversion'**
  String get startConversion;

  /// No description provided for @conversionQueue.
  ///
  /// In en, this message translates to:
  /// **'Conversion queue'**
  String get conversionQueue;

  /// No description provided for @noJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get noJobs;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get working;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @compress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compress;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @extractText.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get extractText;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scan;

  /// No description provided for @esign.
  ///
  /// In en, this message translates to:
  /// **'Sign PDF'**
  String get esign;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Passwords & security'**
  String get security;

  /// No description provided for @pdfTools.
  ///
  /// In en, this message translates to:
  /// **'PDF tools'**
  String get pdfTools;

  /// No description provided for @annotate.
  ///
  /// In en, this message translates to:
  /// **'Annotate'**
  String get annotate;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get recentFiles;

  /// No description provided for @compressionLevel.
  ///
  /// In en, this message translates to:
  /// **'Compression level'**
  String get compressionLevel;

  /// No description provided for @estimatedSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated output size'**
  String get estimatedSize;

  /// No description provided for @qualityImpact.
  ///
  /// In en, this message translates to:
  /// **'Estimated quality impact'**
  String get qualityImpact;

  /// No description provided for @sameTypeOnly.
  ///
  /// In en, this message translates to:
  /// **'Merge accepts files of the same format only.'**
  String get sameTypeOnly;

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag files to change their order.'**
  String get reorderHint;

  /// No description provided for @splitMode.
  ///
  /// In en, this message translates to:
  /// **'Split mode'**
  String get splitMode;

  /// No description provided for @pageRange.
  ///
  /// In en, this message translates to:
  /// **'Page range'**
  String get pageRange;

  /// No description provided for @everyNPages.
  ///
  /// In en, this message translates to:
  /// **'Every N pages'**
  String get everyNPages;

  /// No description provided for @byHeading.
  ///
  /// In en, this message translates to:
  /// **'By heading'**
  String get byHeading;

  /// No description provided for @bySheet.
  ///
  /// In en, this message translates to:
  /// **'By sheet'**
  String get bySheet;

  /// No description provided for @bySlide.
  ///
  /// In en, this message translates to:
  /// **'By slide'**
  String get bySlide;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordCount(int count);

  /// No description provided for @characterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String characterCount(int count);

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @importImages.
  ///
  /// In en, this message translates to:
  /// **'Import images'**
  String get importImages;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @importPng.
  ///
  /// In en, this message translates to:
  /// **'Import PNG'**
  String get importPng;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'Add password'**
  String get addPassword;

  /// No description provided for @removePassword.
  ///
  /// In en, this message translates to:
  /// **'Remove password'**
  String get removePassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @ownerPassword.
  ///
  /// In en, this message translates to:
  /// **'Owner password'**
  String get ownerPassword;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @neverStored.
  ///
  /// In en, this message translates to:
  /// **'Passwords are used in memory and are never stored.'**
  String get neverStored;

  /// No description provided for @pdfViewer.
  ///
  /// In en, this message translates to:
  /// **'PDF viewer'**
  String get pdfViewer;

  /// No description provided for @docxEditor.
  ///
  /// In en, this message translates to:
  /// **'Word editor'**
  String get docxEditor;

  /// No description provided for @xlsxEditor.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet editor'**
  String get xlsxEditor;

  /// No description provided for @pptxEditor.
  ///
  /// In en, this message translates to:
  /// **'Presentation editor'**
  String get pptxEditor;

  /// No description provided for @txtEditor.
  ///
  /// In en, this message translates to:
  /// **'Text editor'**
  String get txtEditor;

  /// No description provided for @jsonEditor.
  ///
  /// In en, this message translates to:
  /// **'JSON editor'**
  String get jsonEditor;

  /// No description provided for @htmlEditor.
  ///
  /// In en, this message translates to:
  /// **'HTML editor'**
  String get htmlEditor;

  /// No description provided for @imageViewer.
  ///
  /// In en, this message translates to:
  /// **'Image viewer'**
  String get imageViewer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get saveAs;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// No description provided for @readMode.
  ///
  /// In en, this message translates to:
  /// **'Read mode'**
  String get readMode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @sepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get sepia;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @defaultDpi.
  ///
  /// In en, this message translates to:
  /// **'Default DPI'**
  String get defaultDpi;

  /// No description provided for @updateChecks.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateChecks;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available.'**
  String get updateAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @skipVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get skipVersion;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'AbzarFile is up to date.'**
  String get upToDate;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'An update check could not be completed.'**
  String get offline;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This format is not available in this build.'**
  String get unsupportedFormat;

  /// No description provided for @corruptInput.
  ///
  /// In en, this message translates to:
  /// **'The input file is damaged or unsupported.'**
  String get corruptInput;

  /// No description provided for @ocrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'OCR is not installed in this build.'**
  String get ocrUnavailable;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed.'**
  String get unknownError;

  /// No description provided for @sourceUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The original file is never modified.'**
  String get sourceUnchanged;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// No description provided for @watermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get watermark;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @presentationPreview.
  ///
  /// In en, this message translates to:
  /// **'Presentation preview'**
  String get presentationPreview;

  /// No description provided for @formula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get formula;

  /// No description provided for @prettify.
  ///
  /// In en, this message translates to:
  /// **'Prettify'**
  String get prettify;

  /// No description provided for @minify.
  ///
  /// In en, this message translates to:
  /// **'Minify'**
  String get minify;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @lineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get lineNumbers;

  /// No description provided for @wordWrap.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get wordWrap;

  /// No description provided for @chooseFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a file to begin.'**
  String get chooseFileFirst;

  /// No description provided for @nativeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The native engine could not be loaded. Build libabzar_core for this platform.'**
  String get nativeUnavailable;

  /// No description provided for @featureWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose inputs and options; processing remains on this device.'**
  String get featureWorkspace;

  /// No description provided for @outputDirectory.
  ///
  /// In en, this message translates to:
  /// **'Output directory'**
  String get outputDirectory;

  /// No description provided for @defaultQuality.
  ///
  /// In en, this message translates to:
  /// **'Default quality'**
  String get defaultQuality;

  /// No description provided for @originalFilter.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalFilter;

  /// No description provided for @bwFilter.
  ///
  /// In en, this message translates to:
  /// **'Black & white'**
  String get bwFilter;

  /// No description provided for @enhancedFilter.
  ///
  /// In en, this message translates to:
  /// **'Enhanced'**
  String get enhancedFilter;

  /// No description provided for @grayscaleFilter.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get grayscaleFilter;

  /// No description provided for @blackWhiteFilter.
  ///
  /// In en, this message translates to:
  /// **'Black and white'**
  String get blackWhiteFilter;

  /// No description provided for @magicColorFilter.
  ///
  /// In en, this message translates to:
  /// **'Magic color'**
  String get magicColorFilter;

  /// No description provided for @perspectiveCorrection.
  ///
  /// In en, this message translates to:
  /// **'Perspective correction'**
  String get perspectiveCorrection;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @repairPdf.
  ///
  /// In en, this message translates to:
  /// **'Repair PDF'**
  String get repairPdf;

  /// No description provided for @pdfObjectEditor.
  ///
  /// In en, this message translates to:
  /// **'PDF object editor'**
  String get pdfObjectEditor;

  /// No description provided for @searchText.
  ///
  /// In en, this message translates to:
  /// **'Existing text'**
  String get searchText;

  /// No description provided for @replacementText.
  ///
  /// In en, this message translates to:
  /// **'Replacement text'**
  String get replacementText;

  /// No description provided for @objectName.
  ///
  /// In en, this message translates to:
  /// **'Image object name (optional)'**
  String get objectName;

  /// No description provided for @pageIndex.
  ///
  /// In en, this message translates to:
  /// **'Page number'**
  String get pageIndex;

  /// No description provided for @replaceTextObject.
  ///
  /// In en, this message translates to:
  /// **'Replace text object'**
  String get replaceTextObject;

  /// No description provided for @replaceImageObject.
  ///
  /// In en, this message translates to:
  /// **'Replace image object'**
  String get replaceImageObject;

  /// No description provided for @selectReplacementImage.
  ///
  /// In en, this message translates to:
  /// **'Select replacement image'**
  String get selectReplacementImage;

  /// No description provided for @addImageObject.
  ///
  /// In en, this message translates to:
  /// **'Add image object'**
  String get addImageObject;

  /// No description provided for @imageX.
  ///
  /// In en, this message translates to:
  /// **'Image X'**
  String get imageX;

  /// No description provided for @imageY.
  ///
  /// In en, this message translates to:
  /// **'Image Y'**
  String get imageY;

  /// No description provided for @imageWidth.
  ///
  /// In en, this message translates to:
  /// **'Image width'**
  String get imageWidth;

  /// No description provided for @imageHeight.
  ///
  /// In en, this message translates to:
  /// **'Image height'**
  String get imageHeight;

  /// No description provided for @deleteImageObject.
  ///
  /// In en, this message translates to:
  /// **'Delete image object'**
  String get deleteImageObject;

  /// No description provided for @pdfStructureEditor.
  ///
  /// In en, this message translates to:
  /// **'PDF forms and outlines'**
  String get pdfStructureEditor;

  /// No description provided for @flattenForms.
  ///
  /// In en, this message translates to:
  /// **'Flatten forms and annotations'**
  String get flattenForms;

  /// No description provided for @bookmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark title'**
  String get bookmarkTitle;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @annotationText.
  ///
  /// In en, this message translates to:
  /// **'Annotation text'**
  String get annotationText;

  /// No description provided for @addTextAnnotation.
  ///
  /// In en, this message translates to:
  /// **'Add text annotation'**
  String get addTextAnnotation;

  /// No description provided for @selectPdf.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdf;

  /// No description provided for @flattenSignature.
  ///
  /// In en, this message translates to:
  /// **'Flatten signature into PDF'**
  String get flattenSignature;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
