// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Flutter Starter';

  @override
  String get loginAppBarTitle => 'تسجيل الدخول';

  @override
  String get loginHeadline => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لتنظيم مساحتك الرقمية.';

  @override
  String get loginUsernameLabel => 'البريد الإلكتروني';

  @override
  String get loginUsernameHint => 'hello@example.com';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginPasswordHint => '••••••••';

  @override
  String get loginShowPassword => 'إظهار كلمة المرور';

  @override
  String get loginHidePassword => 'إخفاء كلمة المرور';

  @override
  String get loginForgotPassword => 'نسيت؟';

  @override
  String get loginSubmit => 'دخول';

  @override
  String get loginDividerLabel => 'أو تابع باستخدام';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginRegisterPrompt => 'جديد في Flutter Starter؟ ';

  @override
  String get loginNavigateToRegister => 'إنشاء حساب';

  @override
  String get loginPasswordRecoveryUnavailable =>
      'استعادة كلمة المرور غير مهيأة بعد.';

  @override
  String get loginSocialUnavailable => 'تسجيل الدخول الاجتماعي غير مهيأ بعد.';

  @override
  String get registerAppBarTitle => 'إنشاء حساب';

  @override
  String get registerHeadline => 'انضم إلى Flutter Starter';

  @override
  String get registerSubtitle =>
      'أنشئ حسابًا وابدأ بتنظيم حياتك الرقمية بوضوح وسهولة.';

  @override
  String get registerEmailLabel => 'البريد الإلكتروني';

  @override
  String get registerEmailHint => 'jane@example.com';

  @override
  String get registerInvalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get registerUsernameLabel => 'اسم المستخدم';

  @override
  String get registerPasswordLabel => 'كلمة المرور';

  @override
  String get registerPasswordHint => '••••••••';

  @override
  String get registerPasswordHelp => 'يجب ألا تقل عن 8 أحرف.';

  @override
  String get registerPasswordMinLengthError =>
      'يجب ألا تقل كلمة المرور عن 8 أحرف.';

  @override
  String get registerShowPassword => 'إظهار كلمة المرور';

  @override
  String get registerHidePassword => 'إخفاء كلمة المرور';

  @override
  String get registerConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get registerSubmit => 'إنشاء الحساب';

  @override
  String get registerLoginPrompt => 'لديك حساب بالفعل؟ ';

  @override
  String get registerNavigateToLogin => 'تسجيل الدخول';

  @override
  String get errorPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get errorInvalidCredentials => 'يرجى إدخال اسم المستخدم وكلمة المرور.';

  @override
  String get errorInvalidInput => 'البيانات غير صالحة.';

  @override
  String get errorUnknown => 'حدث خطأ ما.';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonCreate => 'إنشاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonImageLoadFailed => 'تعذر تحميل الصورة';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonSignOut => 'تسجيل الخروج';

  @override
  String get quickActionsTitle => 'إجراءات سريعة';

  @override
  String get homeAppBarTitle => 'الرئيسية';

  @override
  String get homeWelcomeSubtitle => 'معرفتك المحفوظة، منظمة في مكان واحد';

  @override
  String get homeLoadError =>
      'تعذر تحميل لوحة المعلومات. يرجى المحاولة مجددًا.';

  @override
  String get homeViewAllBookmarks => 'عرض الكل';

  @override
  String get homeNoDescription => 'لا يوجد وصف';

  @override
  String get homeRecentBookmarks => 'الإشارات المرجعية الأخيرة';

  @override
  String get homeNoBookmarks => 'لا توجد إشارات مرجعية بعد. اضغط + للإضافة.';

  @override
  String get homeSearchTitle => 'بحث';

  @override
  String get homeSearchSubtitle =>
      'اعثر فورًا على مقالاتك وأدواتك ومصادر إلهامك المحفوظة.';

  @override
  String get homeSearchHint => 'ابحث في الإشارات المرجعية...';

  @override
  String get homeQuickAdd => 'إضافة رابط';

  @override
  String get homeQuickLibrary => 'المكتبة';

  @override
  String get homeQuickTags => 'الوسوم';

  @override
  String get homeFilterAll => 'الكل';

  @override
  String get homeFilterDesign => 'تصميم';

  @override
  String get homeFilterArticles => 'مقالات';

  @override
  String get homeFilterInspiration => 'إلهام';

  @override
  String get homeFilterTools => 'أدوات';

  @override
  String get homeSuggestedTitle => 'مقترح لك';

  @override
  String get homeFeaturedCollections => 'مجموعات مميزة';

  @override
  String get homeWeeklyDigestTitle => 'الملخص الأسبوعي';

  @override
  String get homeWeeklyDigestEyebrow => 'الأكثر قراءة';

  @override
  String get homeWeeklyDigestHeadline => 'راجع معارفك المحفوظة';

  @override
  String homeWeeklyDigestBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'حفظت $count إشارة مرجعية مؤخرًا. راجع أبرز محتوياتها وواصل القراءة.',
      many:
          'حفظت $count إشارة مرجعية مؤخرًا. راجع أبرز محتوياتها وواصل القراءة.',
      few:
          'حفظت $count إشارات مرجعية مؤخرًا. راجع أبرز محتوياتها وواصل القراءة.',
      two: 'حفظت إشارتين مرجعيتين مؤخرًا. راجع أبرز محتوياتهما وواصل القراءة.',
      one: 'حفظت إشارة مرجعية واحدة مؤخرًا. راجع أبرز محتوياتها وواصل القراءة.',
      zero:
          'لا توجد لديك إشارات مرجعية حديثة. أضف إشارة لتراجع أبرز محتوياتها.',
    );
    return '$_temp0';
  }

  @override
  String get homeReadDigest => 'قراءة الملخص';

  @override
  String get homeNoMatches => 'لا توجد إشارات مرجعية تطابق هذا العرض.';

  @override
  String get homeBookmarkVisualFallback => 'حديث';

  @override
  String get profileAppBarTitle => 'الملف الشخصي';

  @override
  String get profileSettingsSubtitle => 'إعدادات الحساب والتطبيق';

  @override
  String get profileAccountBadge => 'مساحتك الشخصية';

  @override
  String get profileCopyIdTooltip => 'نسخ معرّف الحساب';

  @override
  String get profileSectionAppearance => 'المظهر';

  @override
  String get profileAppearanceSectionSubtitle => 'السمة واللون واللغة';

  @override
  String get profileSectionAccount => 'الحساب';

  @override
  String get profileAccountSectionSubtitle => 'خيارات الأمان والخصوصية';

  @override
  String get profileChangePassword => 'تغيير كلمة المرور';

  @override
  String get profileChangePasswordSubtitle =>
      'تحديث بيانات الأمان الخاصة بحسابك';

  @override
  String get profileDeleteAccount => 'حذف الحساب';

  @override
  String get profileDeleteAccountSubtitle => 'إزالة حسابك وبياناتك نهائيًا';

  @override
  String get profileDeleteAccountDialogTitle => 'حذف الحساب؟';

  @override
  String get profileDeleteAccountDialogMessage =>
      'سيؤدي هذا إلى حذف حسابك وجميع بياناته نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String profileDeleteAccountConfirmLabel(String username) {
    return 'اكتب \"$username\" للتأكيد';
  }

  @override
  String get profileDeleteAccountSuccess => 'تم حذف حسابك.';

  @override
  String get profileDeleteAccountError =>
      'تعذر حذف حسابك. يرجى المحاولة مجددًا.';

  @override
  String get changePasswordAppBarTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordCurrentLabel => 'كلمة المرور الحالية';

  @override
  String get changePasswordNewLabel => 'كلمة المرور الجديدة';

  @override
  String get changePasswordConfirmLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get changePasswordSubmit => 'تحديث كلمة المرور';

  @override
  String get changePasswordSuccessMessage => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String get changePasswordMismatchError =>
      'كلمتا المرور الجديدتان غير متطابقتين.';

  @override
  String get profileSectionAbout => 'حول التطبيق';

  @override
  String get profileAboutSectionSubtitle => 'الإصدار وتفاصيل التطبيق';

  @override
  String get profileUserIdCopied => 'تم نسخ معرّف المستخدم';

  @override
  String get profileAppearanceThemeLabel => 'السمة';

  @override
  String get profileAppearanceColorLabel => 'اللون المميز';

  @override
  String get profileThemeSystemDefault => 'إعداد النظام';

  @override
  String get profileThemeLight => 'فاتح';

  @override
  String get profileThemeDark => 'داكن';

  @override
  String profileAppVersionBuild(String version, String buildNumber) {
    return 'الإصدار $version (البنية $buildNumber)';
  }

  @override
  String get profileAppStatus => 'محدّث';

  @override
  String get profileSignOutConfirmMessage => 'هل تريد بالتأكيد تسجيل الخروج؟';

  @override
  String get bookmarksAppBarTitle => 'الإشارات المرجعية';

  @override
  String get bookmarksSearchHint => 'ابحث بالعنوان أو الرابط أو الوسم';

  @override
  String get bookmarksNoMatchesTitle => 'لا توجد نتائج';

  @override
  String get bookmarksNoMatchesMessage => 'لا توجد إشارات مرجعية تطابق بحثك.';

  @override
  String get bookmarksEmptyTitle => 'لا توجد إشارات مرجعية بعد';

  @override
  String get bookmarksEmptyMessage => 'اضغط + لإضافة أول إشارة مرجعية.';

  @override
  String get bookmarksNotYetSynced => 'لم تتم المزامنة بعد';

  @override
  String get bookmarksSyncFailedRetryTooltip =>
      'فشلت المزامنة - اضغط لإعادة المحاولة';

  @override
  String get bookmarksAddTooltip => 'إضافة إشارة مرجعية';

  @override
  String get bookmarksSearchClear => 'مسح البحث';

  @override
  String get bookmarksSortTooltip => 'ترتيب الإشارات المرجعية';

  @override
  String get bookmarksSortMenuLabel => 'قائمة الترتيب';

  @override
  String get bookmarksSortNewest => 'الأحدث أولًا';

  @override
  String get bookmarksSortOldest => 'الأقدم أولًا';

  @override
  String get bookmarksSortTitleAz => 'العنوان (أ–ي)';

  @override
  String get bookmarksTabAll => 'الكل';

  @override
  String get bookmarksTabRecent => 'الأخيرة';

  @override
  String get bookmarksTabCollections => 'المجموعات';

  @override
  String get bookmarksRecentEmptyTitle => 'لا يوجد شيء حديث';

  @override
  String get bookmarksRecentEmptyMessage =>
      'ستظهر هنا الإشارات المرجعية التي تضيفها هذا الأسبوع.';

  @override
  String get bookmarksCollectionsComingSoonTitle => 'المجموعات قريبًا';

  @override
  String get bookmarksCollectionsComingSoonMessage =>
      'ستتمكن في تحديث قادم من تجميع الإشارات المرجعية المرتبطة.';

  @override
  String get bookmarkMoreActions => 'المزيد من الإجراءات';

  @override
  String get bookmarkAppBarTitle => 'تفاصيل الإشارة المرجعية';

  @override
  String get bookmarkSourceLabel => 'المصدر';

  @override
  String get bookmarkVisitWebsite => 'زيارة الموقع';

  @override
  String get bookmarkDetailsLabel => 'التفاصيل';

  @override
  String get bookmarkDateCreatedLabel => 'تاريخ الإنشاء';

  @override
  String get bookmarkLastModifiedLabel => 'آخر تعديل';

  @override
  String get bookmarkMediaLabel => 'الوسائط';

  @override
  String get bookmarkOpenInBrowser => 'فتح في المتصفح';

  @override
  String get bookmarkNotFound => 'لم يتم العثور على الإشارة المرجعية.';

  @override
  String get bookmarkDeleteDialogTitle => 'حذف الإشارة المرجعية؟';

  @override
  String get bookmarkDeleteDialogBody =>
      'لا يمكن التراجع عن هذا الإجراء.\nستُحذف الإشارة المرجعية نهائيًا من مجموعتك.';

  @override
  String bookmarkDeleteDialogMessage(String title) {
    return 'ستُحذف \"$title\".';
  }

  @override
  String get bookmarkOpenUrl => 'فتح الرابط';

  @override
  String get bookmarkAttachedVideo => 'فيديو مرفق';

  @override
  String get bookmarkInvalidUrl => 'الرابط غير صالح';

  @override
  String get bookmarkCouldNotOpenUrl => 'تعذر فتح الرابط';

  @override
  String get bookmarkFormEditTitle => 'تعديل الإشارة المرجعية';

  @override
  String get bookmarkFormNewTitle => 'إشارة مرجعية جديدة';

  @override
  String get bookmarkFormLoadFailed => 'تعذر تحميل الإشارة المرجعية.';

  @override
  String get bookmarkTitleLabel => 'العنوان';

  @override
  String get bookmarkUrlLabel => 'الرابط';

  @override
  String get bookmarkDescriptionLabel => 'الوصف (اختياري)';

  @override
  String get bookmarkTagsLabel => 'الوسوم';

  @override
  String get bookmarkTagsHint => 'قيم، مفصولة، بفواصل';

  @override
  String get bookmarkPreviewLabel => 'إشارة مرجعية';

  @override
  String get bookmarkTitleRequired => 'العنوان مطلوب';

  @override
  String get bookmarkUrlRequired => 'الرابط مطلوب';

  @override
  String get bookmarkUrlInvalid => 'أدخل رابطًا صالحًا (https://…)';

  @override
  String get errorPermissionDenied => 'تم رفض الإذن.';

  @override
  String get errorGalleryPermissionRequired =>
      'يلزم السماح بالوصول إلى معرض الصور لإرفاق الصور.';

  @override
  String get errorCameraPermissionRequired =>
      'يلزم السماح بالوصول إلى الكاميرا لالتقاط الصور.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navBookmarks => 'المحفوظات';

  @override
  String get navProfile => 'حسابي';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get settingsAppBarTitle => 'الإعدادات';

  @override
  String get bookmarksDetailPlaceholder => 'اختر إشارة مرجعية لعرض تفاصيلها';

  @override
  String bookmarkImageLabel(String title) {
    return 'صورة $title';
  }

  @override
  String get bookmarkAttachedImageLabel => 'صورة مرفقة';

  @override
  String get bookmarkRemoveImageLabel => 'إزالة الصورة';

  @override
  String get navNotifications => 'التنبيهات';

  @override
  String get notificationsAppBarTitle => 'الإشعارات';

  @override
  String get notificationsActivitySection => 'نشاطك';

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get notificationsSectionNew => 'جديدة';

  @override
  String get notificationsSectionEarlier => 'سابقة';

  @override
  String get notificationsEmptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get notificationsEmptyMessage =>
      'ستظهر إشعاراتك ونشاطاتك الأخيرة هنا.';

  @override
  String get notificationsNoNotifications => 'لا توجد إشعارات بعد.';

  @override
  String get notificationsLoadError =>
      'تعذر تحميل إشعاراتك. اسحب للتحديث أو حاول مجددًا.';

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار غير مقروء',
      many: '$count إشعارًا غير مقروء',
      few: '$count إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا توجد إشعارات غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة واحدة',
    );
    return 'قبل $_temp0';
  }

  @override
  String timeHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      many: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتين',
      one: 'ساعة واحدة',
    );
    return 'قبل $_temp0';
  }

  @override
  String timeDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'قبل $_temp0';
  }

  @override
  String get collectionsTitle => 'المجموعات';

  @override
  String get collectionsEmptyTitle => 'لا توجد مجموعات بعد';

  @override
  String get collectionsEmptyMessage =>
      'اجمع الإشارات المرجعية المرتبطة في مجموعات.';

  @override
  String get collectionsLoadError =>
      'تعذر تحميل مجموعاتك. اسحب للتحديث أو حاول مجددًا.';

  @override
  String get collectionsCreate => 'مجموعة جديدة';

  @override
  String get collectionsCreateTitle => 'مجموعة جديدة';

  @override
  String get collectionsEditTitle => 'تعديل المجموعة';

  @override
  String get collectionNameLabel => 'الاسم';

  @override
  String get collectionNameHint => 'مثال: إلهام للتصميم';

  @override
  String get collectionNameRequired => 'الاسم مطلوب';

  @override
  String get collectionAppearanceLabel => 'الأيقونة واللون';

  @override
  String get collectionSave => 'حفظ';

  @override
  String get collectionDeleteAction => 'حذف المجموعة';

  @override
  String get collectionDeleteDialogTitle => 'حذف المجموعة؟';

  @override
  String collectionDeleteDialogMessage(String name) {
    return 'ستُحذف \"$name\"، وستبقى إشاراتك المرجعية.';
  }

  @override
  String get collectionNotFound => 'لم يتم العثور على المجموعة.';

  @override
  String collectionItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشارة مرجعية',
      many: '$count إشارة مرجعية',
      few: '$count إشارات مرجعية',
      two: 'إشارتان مرجعيتان',
      one: 'إشارة مرجعية واحدة',
      zero: 'لا توجد إشارات مرجعية',
    );
    return '$_temp0';
  }

  @override
  String get collectionAddBookmarks => 'إضافة إشارات مرجعية';

  @override
  String get collectionRemoveBookmark => 'إزالة من المجموعة';

  @override
  String get collectionEmptyBookmarks =>
      'لا توجد إشارات مرجعية في هذه المجموعة بعد.';

  @override
  String get collectionPickerEmpty =>
      'جميع إشاراتك المرجعية موجودة بالفعل في هذه المجموعة.';

  @override
  String collectionPickerAddCount(int count) {
    return 'إضافة $count';
  }

  @override
  String get addToCollectionTitle => 'إضافة إلى مجموعة';

  @override
  String get addToCollectionEmpty => 'لم تنشئ أي مجموعات بعد.';

  @override
  String get homeCreateCollection => 'إنشاء مجموعة';

  @override
  String get bookmarkAttachGallery => 'المعرض';

  @override
  String get bookmarkAttachCamera => 'الكاميرا';

  @override
  String get bookmarkAttachVideo => 'فيديو';

  @override
  String get bookmarkAttachRecord => 'تسجيل';

  @override
  String get bookmarkRemoveVideoLabel => 'إزالة الفيديو';

  @override
  String get videoPlayerPlay => 'تشغيل';

  @override
  String get videoPlayerPause => 'إيقاف مؤقت';

  @override
  String get videoPlayerMute => 'كتم الصوت';

  @override
  String get videoPlayerUnmute => 'إلغاء كتم الصوت';

  @override
  String get videoPlayerFullScreen => 'ملء الشاشة';

  @override
  String get videoPlayerExitFullScreen => 'إنهاء ملء الشاشة';

  @override
  String get videoPlayerPlaybackSpeed => 'سرعة التشغيل';

  @override
  String get videoPlayerLoadFailed => 'تعذر تحميل الفيديو';

  @override
  String get profileAppearanceLanguageLabel => 'اللغة';

  @override
  String get systemSettingsTitle => 'إعدادات النظام';

  @override
  String get systemSettingsSubtitle => 'خصّص تجربة التطبيق';

  @override
  String get systemSettingsOpen => 'فتح إعدادات النظام';

  @override
  String get systemSettingsAppearance => 'المظهر والألوان';

  @override
  String get systemSettingsAppearanceHint => 'اختر المظهر واللون المناسبين لك';

  @override
  String get systemSettingsTypography => 'الخط والقراءة';

  @override
  String get systemSettingsTypographyHint =>
      'غيّر الخط وحجم النص في كامل التطبيق';

  @override
  String get systemSettingsFont => 'نوع الخط';

  @override
  String get systemSettingsFontSystem => 'خط النظام';

  @override
  String get systemSettingsFontSystemHint => 'استخدام الخط الافتراضي للجهاز';

  @override
  String get systemSettingsFontPreview => 'نص عربي و English 123';

  @override
  String get systemSettingsBrowseFonts => 'اضغط لاختيار نوع الخط';

  @override
  String get systemSettingsSuggestedFonts => 'مقترحة';

  @override
  String get systemSettingsFontLibrary => 'اختيار نوع الخط';

  @override
  String get systemSettingsFontLibraryHint =>
      'تُحمّل الأسماء تدريجياً، ولن يُحمّل الخط إلا بعد اختياره';

  @override
  String get systemSettingsFontSearchHint => 'ابحث باسم الخط';

  @override
  String get systemSettingsFontNoResults => 'لم يتم العثور على خط مطابق';

  @override
  String get systemSettingsFontLoadError => 'تعذر تحميل قائمة الخطوط';

  @override
  String get systemSettingsRetry => 'إعادة المحاولة';

  @override
  String get systemSettingsTextSize => 'حجم النص';

  @override
  String get systemSettingsTextCompact => 'صغير';

  @override
  String get systemSettingsTextStandard => 'عادي';

  @override
  String get systemSettingsTextLarge => 'كبير';

  @override
  String get systemSettingsLanguageHint => 'تتغير لغة الواجهة واتجاهها مباشرة';

  @override
  String get systemSettingsLanguageSystemHint => 'اتباع لغة الجهاز تلقائياً';

  @override
  String get systemSettingsPreviewTitle => 'معاينة مباشرة';

  @override
  String get systemSettingsReset => 'إعادة الإعدادات الافتراضية';

  @override
  String get documentCenterTitle => 'مركز المستندات';

  @override
  String get documentCenterSubtitle =>
      'استيراد وتصدير وإنشاء التقارير والطباعة';

  @override
  String get documentCenterTabImport => 'استيراد البيانات';

  @override
  String get documentCenterTabExport => 'تصدير البيانات';

  @override
  String get documentCenterTabReports => 'التقارير والطباعة';

  @override
  String get documentImportSelectFile => 'اختيار ملف';

  @override
  String get documentImportSelectFileHint =>
      'اختر ملف CSV أو XLSX أو JSON للاستيراد';

  @override
  String documentImportFileSelected(String fileName) {
    return 'الملف المختار: $fileName';
  }

  @override
  String documentImportDetectedFormat(String format) {
    return 'الصيغة المكتشفة: $format';
  }

  @override
  String get documentImportSourceColumns => 'أعمدة المصدر';

  @override
  String get documentImportTargetSchema => 'المخطط المستهدف';

  @override
  String get documentImportValidateButton => 'التحقق من البيانات';

  @override
  String get documentImportCommitButton => 'تأكيد الاستيراد';

  @override
  String get documentImportPreviewTitle => 'معاينة التحقق';

  @override
  String documentImportValidRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'الصفوف الصالحة: $countString';
  }

  @override
  String documentImportInvalidRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'الصفوف غير الصالحة: $countString';
  }

  @override
  String documentImportSuccessMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم استيراد $countString سجل بنجاح';
  }

  @override
  String documentImportErrorMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'فشل التحقق من الاستيراد بـ $countString أخطاء';
  }

  @override
  String get documentExportDatasetLabel => 'اختيار مجموعة البيانات';

  @override
  String get documentExportFormatLabel => 'صيغة التصدير';

  @override
  String get documentExportColumnsLabel => 'تحديد الأعمدة';

  @override
  String get documentExportNeutralizeFormulas =>
      'الحماية من حقن معادلات جداول البيانات';

  @override
  String get documentExportButton => 'تصدير المستند';

  @override
  String documentExportSuccess(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return 'اكتمل التصدير ($bytesString بايت)';
  }

  @override
  String get documentReportsSelectTemplate => 'قالب التقرير';

  @override
  String get documentReportsSales => 'تقرير ملخص المبيعات';

  @override
  String get documentReportsInventory => 'تقرير حركة المخزون';

  @override
  String get documentReportsStatement => 'كشف حساب المورد';

  @override
  String get documentReportsInvoice => 'فاتورة ضريبية تجارية';

  @override
  String get documentReportsGeneral => 'سجل الأنشطة العام';

  @override
  String get documentReportsGeneratePdf => 'إنشاء PDF';

  @override
  String get documentReportsPrintSystem => 'طباعة النظام';

  @override
  String get documentReportsPrintThermal => 'طباعة حرارية (ESC/POS)';

  @override
  String get documentReportsThermalSuccess =>
      'تم إرسال المستند إلى الطابعة الحرارية';

  @override
  String get documentReportsPreviewTitle => 'معاينة التقرير';

  @override
  String get collectionsImportAction => 'استيراد المجموعات';

  @override
  String get bookmarksImportAction => 'استيراد الإشارات المرجعية';

  @override
  String get documentImportDatasetLabel => 'مجموعة البيانات المستهدفة';

  @override
  String get documentImportDuplicatePolicyLabel => 'سياسة التعامل مع التكرار';

  @override
  String get documentImportPolicySkip => 'تخطي المكرر';

  @override
  String get documentImportPolicyUpdate => 'تحديث الموجود';

  @override
  String get documentImportPolicyCreate => 'إنشاء نسخ جديدة';

  @override
  String documentImportCreatedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم الإنشاء: $countString';
  }

  @override
  String documentImportUpdatedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم التحديث: $countString';
  }

  @override
  String documentImportSkippedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تم التخطي: $countString';
  }

  @override
  String documentImportFailedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'فشل: $countString';
  }

  @override
  String get documentImportSummaryTitle => 'ملخص نتيجة الاستيراد';

  @override
  String get documentImportCloseButton => 'إغلاق';

  @override
  String get routeNotFoundTitle => 'الصفحة غير موجودة';

  @override
  String routeNotFoundMessage(String location) {
    return 'لا توجد صفحة تطابق $location.';
  }

  @override
  String get routeNotFoundHomeAction => 'الانتقال إلى الرئيسية';

  @override
  String get exitAppTitle => 'هل تريد الخروج؟';

  @override
  String get exitAppMessage => 'اضغط خروج لإغلاق التطبيق.';

  @override
  String get exitAppConfirm => 'خروج';

  @override
  String get documentImportDemoSales => 'المبيعات (تجريبي)';

  @override
  String get documentProgressReading => 'جارٍ قراءة المستند…';

  @override
  String get documentProgressParsing => 'جارٍ تحليل المستند…';

  @override
  String documentProgressValidating(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'جارٍ التحقق من $currentString من $totalString…';
  }

  @override
  String get documentProgressCommitting => 'جارٍ حفظ السجلات المستوردة…';

  @override
  String get documentReportPdfFailure => 'تعذر إنشاء ملف PDF.';

  @override
  String documentThermalSuccessBytes(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return 'أُرسل المستند إلى الطابعة الحرارية ($bytesString بايت)';
  }

  @override
  String get documentThermalFailure =>
      'تعذر إرسال المستند إلى الطابعة الحرارية.';

  @override
  String get documentFileReadFailure => 'تعذرت قراءة الملف المحدد.';

  @override
  String get documentImportValidationFailure =>
      'الملف تالف أو غير مدعوم أو لا يطابق مجموعة البيانات المحددة.';

  @override
  String get documentImportCommitFailure =>
      'تعذر حفظ الصفوف المتحقق منها، ولم يُحتفظ باستيراد جزئي.';

  @override
  String get documentExportFailure => 'تعذر تصدير المستند.';

  @override
  String get documentSaveFailure => 'تعذر حفظ الملف المُصدّر.';
}
