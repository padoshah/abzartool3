// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'ابزارفایل';

  @override
  String get home => 'خانه';

  @override
  String get convert => 'تبدیل';

  @override
  String get toolbox => 'جعبه‌ابزار';

  @override
  String get history => 'تاریخچه';

  @override
  String get settings => 'تنظیمات';

  @override
  String get offlinePitch => 'کارگاه آفلاین اسناد شما';

  @override
  String get selectFiles => 'انتخاب فایل‌ها';

  @override
  String get selectOutput => 'انتخاب پوشه خروجی';

  @override
  String get targetFormat => 'قالب مقصد';

  @override
  String get startConversion => 'شروع تبدیل';

  @override
  String get conversionQueue => 'صف تبدیل';

  @override
  String get noJobs => 'هنوز کاری وجود ندارد';

  @override
  String get completed => 'تکمیل شد';

  @override
  String get failed => 'ناموفق';

  @override
  String get cancelled => 'لغو شد';

  @override
  String get working => 'در حال انجام…';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get cancel => 'لغو';

  @override
  String get ok => 'تأیید';

  @override
  String get documents => 'اسناد';

  @override
  String get open => 'باز کردن';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get compress => 'فشرده‌سازی';

  @override
  String get merge => 'ادغام';

  @override
  String get split => 'تقسیم';

  @override
  String get extractText => 'استخراج متن';

  @override
  String get scan => 'اسکن سند';

  @override
  String get esign => 'امضای PDF';

  @override
  String get security => 'گذرواژه و امنیت';

  @override
  String get pdfTools => 'ابزارهای PDF';

  @override
  String get annotate => 'یادداشت‌گذاری';

  @override
  String get recentFiles => 'فایل‌های اخیر';

  @override
  String get compressionLevel => 'سطح فشرده‌سازی';

  @override
  String get estimatedSize => 'حجم تخمینی خروجی';

  @override
  String get qualityImpact => 'اثر تخمینی بر کیفیت';

  @override
  String get sameTypeOnly => 'برای ادغام، قالب همه فایل‌ها باید یکسان باشد.';

  @override
  String get reorderHint => 'برای تغییر ترتیب، فایل‌ها را بکشید.';

  @override
  String get splitMode => 'روش تقسیم';

  @override
  String get pageRange => 'محدوده صفحات';

  @override
  String get everyNPages => 'هر N صفحه';

  @override
  String get byHeading => 'بر اساس عنوان';

  @override
  String get bySheet => 'بر اساس برگه';

  @override
  String get bySlide => 'بر اساس اسلاید';

  @override
  String get copyAll => 'کپی همه';

  @override
  String wordCount(int count) {
    return '$count واژه';
  }

  @override
  String characterCount(int count) {
    return '$count نویسه';
  }

  @override
  String get camera => 'دوربین';

  @override
  String get importImages => 'وارد کردن تصاویر';

  @override
  String get capture => 'ثبت';

  @override
  String get exportPdf => 'خروجی PDF';

  @override
  String get signature => 'امضا';

  @override
  String get draw => 'رسم';

  @override
  String get type => 'تایپ';

  @override
  String get importPng => 'وارد کردن PNG';

  @override
  String get addPassword => 'افزودن گذرواژه';

  @override
  String get removePassword => 'حذف گذرواژه';

  @override
  String get password => 'گذرواژه';

  @override
  String get ownerPassword => 'گذرواژه مالک';

  @override
  String get permissions => 'مجوزها';

  @override
  String get neverStored =>
      'گذرواژه‌ها فقط در حافظه استفاده شده و ذخیره نمی‌شوند.';

  @override
  String get pdfViewer => 'نمایشگر PDF';

  @override
  String get docxEditor => 'ویرایشگر ورد';

  @override
  String get xlsxEditor => 'ویرایشگر صفحه‌گسترده';

  @override
  String get pptxEditor => 'ویرایشگر ارائه';

  @override
  String get txtEditor => 'ویرایشگر متن';

  @override
  String get jsonEditor => 'ویرایشگر JSON';

  @override
  String get htmlEditor => 'ویرایشگر HTML';

  @override
  String get imageViewer => 'نمایشگر تصویر';

  @override
  String get save => 'ذخیره';

  @override
  String get saveAs => 'ذخیره با نام';

  @override
  String get undo => 'واگرد';

  @override
  String get redo => 'بازانجام';

  @override
  String get search => 'جستجو';

  @override
  String get replace => 'جایگزینی';

  @override
  String get bold => 'ضخیم';

  @override
  String get italic => 'مورب';

  @override
  String get underline => 'زیرخط';

  @override
  String get fontFamily => 'قلم';

  @override
  String get fontSize => 'اندازه متن';

  @override
  String get textColor => 'رنگ متن';

  @override
  String get backgroundColor => 'رنگ پس‌زمینه';

  @override
  String get readMode => 'حالت مطالعه';

  @override
  String get light => 'روشن';

  @override
  String get dark => 'تیره';

  @override
  String get system => 'سیستم';

  @override
  String get sepia => 'سپیا';

  @override
  String get language => 'زبان';

  @override
  String get english => 'انگلیسی';

  @override
  String get persian => 'فارسی';

  @override
  String get theme => 'پوسته';

  @override
  String get defaultDpi => 'DPI پیش‌فرض';

  @override
  String get updateChecks => 'بررسی بروزرسانی';

  @override
  String get checkNow => 'اکنون بررسی کن';

  @override
  String get updateAvailable => 'نسخه جدیدی موجود است.';

  @override
  String get updateNow => 'اکنون بروزرسانی';

  @override
  String get later => 'بعداً';

  @override
  String get skipVersion => 'رد کردن این نسخه';

  @override
  String get upToDate => 'ابزارفایل بروز است.';

  @override
  String get offline => 'بررسی بروزرسانی انجام نشد.';

  @override
  String get openFile => 'باز کردن فایل';

  @override
  String get unsupportedFormat => 'این قالب در این ساخت موجود نیست.';

  @override
  String get corruptInput => 'فایل ورودی خراب یا پشتیبانی‌نشده است.';

  @override
  String get ocrUnavailable => 'OCR در این ساخت نصب نشده است.';

  @override
  String get unknownError => 'عملیات انجام نشد.';

  @override
  String get sourceUnchanged => 'فایل اصلی هرگز تغییر نمی‌کند.';

  @override
  String get pages => 'صفحات';

  @override
  String get rotate => 'چرخش';

  @override
  String get crop => 'برش';

  @override
  String get delete => 'حذف';

  @override
  String get duplicate => 'تکثیر';

  @override
  String get insert => 'درج';

  @override
  String get watermark => 'واترمارک';

  @override
  String get metadata => 'فراداده';

  @override
  String get presentationPreview => 'پیش‌نمایش ارائه';

  @override
  String get formula => 'فرمول';

  @override
  String get prettify => 'مرتب‌سازی';

  @override
  String get minify => 'فشرده‌سازی متن';

  @override
  String get validate => 'اعتبارسنجی';

  @override
  String get source => 'منبع';

  @override
  String get preview => 'پیش‌نمایش';

  @override
  String get lineNumbers => 'شماره خطوط';

  @override
  String get wordWrap => 'شکستن خطوط';

  @override
  String get chooseFileFirst => 'برای شروع یک فایل انتخاب کنید.';

  @override
  String get nativeUnavailable =>
      'موتور بومی بارگذاری نشد. libabzar_core را برای این سکو بسازید.';

  @override
  String get featureWorkspace =>
      'ورودی و گزینه‌ها را انتخاب کنید؛ پردازش روی همین دستگاه انجام می‌شود.';

  @override
  String get outputDirectory => 'پوشه خروجی';

  @override
  String get defaultQuality => 'کیفیت پیش‌فرض';

  @override
  String get originalFilter => 'اصلی';

  @override
  String get bwFilter => 'Black & white';

  @override
  String get enhancedFilter => 'Enhanced';

  @override
  String get grayscaleFilter => 'خاکستری';

  @override
  String get blackWhiteFilter => 'سیاه و سفید';

  @override
  String get magicColorFilter => 'رنگ جادویی';

  @override
  String get perspectiveCorrection => 'اصلاح پرسپکتیو';

  @override
  String get brightness => 'روشنایی';

  @override
  String get contrast => 'کنتراست';

  @override
  String get repairPdf => 'ترمیم PDF';

  @override
  String get pdfObjectEditor => 'ویرایشگر اشیای PDF';

  @override
  String get searchText => 'متن موجود';

  @override
  String get replacementText => 'متن جایگزین';

  @override
  String get objectName => 'نام شیء تصویر (اختیاری)';

  @override
  String get pageIndex => 'شماره صفحه';

  @override
  String get replaceTextObject => 'جایگزینی شیء متن';

  @override
  String get replaceImageObject => 'جایگزینی شیء تصویر';

  @override
  String get selectReplacementImage => 'انتخاب تصویر جایگزین';

  @override
  String get addImageObject => 'افزودن شیء تصویر';

  @override
  String get imageX => 'موقعیت X';

  @override
  String get imageY => 'موقعیت Y';

  @override
  String get imageWidth => 'عرض تصویر';

  @override
  String get imageHeight => 'ارتفاع تصویر';

  @override
  String get deleteImageObject => 'حذف شیء تصویر';

  @override
  String get pdfStructureEditor => 'فرم‌ها و ساختار PDF';

  @override
  String get flattenForms => 'تخت‌کردن فرم‌ها و یادداشت‌ها';

  @override
  String get bookmarkTitle => 'عنوان نشانک';

  @override
  String get addBookmark => 'افزودن نشانک';

  @override
  String get annotationText => 'متن یادداشت';

  @override
  String get addTextAnnotation => 'افزودن یادداشت متنی';

  @override
  String get selectPdf => 'انتخاب PDF';

  @override
  String get flattenSignature => 'تخت‌کردن امضا در PDF';
}
