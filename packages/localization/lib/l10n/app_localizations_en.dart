// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Starter';

  @override
  String get loginAppBarTitle => 'Sign in';

  @override
  String get loginHeadline => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to organize your digital space.';

  @override
  String get loginUsernameLabel => 'Email Address';

  @override
  String get loginUsernameHint => 'hello@example.com';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => '••••••••';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginForgotPassword => 'Forgot?';

  @override
  String get loginSubmit => 'Log In';

  @override
  String get loginDividerLabel => 'OR CONTINUE WITH';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginRegisterPrompt => 'New to Flutter Starter? ';

  @override
  String get loginNavigateToRegister => 'Create an account';

  @override
  String get loginPasswordRecoveryUnavailable =>
      'Password recovery isn\'t configured yet.';

  @override
  String get loginSocialUnavailable => 'Social sign-in isn\'t configured yet.';

  @override
  String get registerAppBarTitle => 'Register';

  @override
  String get registerHeadline => 'Join Flutter Starter';

  @override
  String get registerSubtitle =>
      'Create an account to start organizing your digital life with clarity and ease.';

  @override
  String get registerEmailLabel => 'Email Address';

  @override
  String get registerEmailHint => 'jane@example.com';

  @override
  String get registerInvalidEmail => 'Enter a valid email address.';

  @override
  String get registerUsernameLabel => 'Username';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordHint => '••••••••';

  @override
  String get registerPasswordHelp => 'Must be at least 8 characters.';

  @override
  String get registerPasswordMinLengthError =>
      'Password must be at least 8 characters.';

  @override
  String get registerShowPassword => 'Show password';

  @override
  String get registerHidePassword => 'Hide password';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerSubmit => 'Join Flutter Starter';

  @override
  String get registerLoginPrompt => 'Already have an account? ';

  @override
  String get registerNavigateToLogin => 'Log in';

  @override
  String get errorPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get errorInvalidCredentials => 'Please enter a username and password.';

  @override
  String get errorInvalidInput => 'Invalid input.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonImageLoadFailed => 'Failed to load image';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get homeAppBarTitle => 'Home';

  @override
  String get homeWelcomeSubtitle =>
      'Your saved knowledge, organized in one place';

  @override
  String get homeLoadError =>
      'We could not load your dashboard. Please try again.';

  @override
  String get homeViewAllBookmarks => 'View all';

  @override
  String get homeNoDescription => 'No description';

  @override
  String get homeRecentBookmarks => 'Recent Bookmarks';

  @override
  String get homeNoBookmarks => 'No bookmarks yet. Tap + to add one.';

  @override
  String get homeSearchTitle => 'Search';

  @override
  String get homeSearchSubtitle =>
      'Find your saved articles, tools, and inspirations instantly.';

  @override
  String get homeSearchHint => 'Search bookmarks...';

  @override
  String get homeQuickAdd => 'Add Link';

  @override
  String get homeQuickLibrary => 'Library';

  @override
  String get homeQuickTags => 'Tags';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterDesign => 'Design';

  @override
  String get homeFilterArticles => 'Articles';

  @override
  String get homeFilterInspiration => 'Inspiration';

  @override
  String get homeFilterTools => 'Tools';

  @override
  String get homeSuggestedTitle => 'Suggested for You';

  @override
  String get homeFeaturedCollections => 'Featured Collections';

  @override
  String get homeWeeklyDigestTitle => 'Weekly Digest';

  @override
  String get homeWeeklyDigestEyebrow => 'Most Read';

  @override
  String get homeWeeklyDigestHeadline => 'Your saved knowledge catch-up';

  @override
  String homeWeeklyDigestBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You saved $count bookmarks recently. Review the highlights and keep your reading flow moving.',
      one:
          'You saved 1 bookmark recently. Review the highlight and keep your reading flow moving.',
      zero:
          'You have no recent bookmarks. Review saved highlights when you add one.',
    );
    return '$_temp0';
  }

  @override
  String get homeReadDigest => 'Read Digest';

  @override
  String get homeNoMatches => 'No bookmarks match this view.';

  @override
  String get homeBookmarkVisualFallback => 'Recent';

  @override
  String get profileAppBarTitle => 'Profile';

  @override
  String get profileSettingsSubtitle => 'Account and application settings';

  @override
  String get profileAccountBadge => 'Personal workspace';

  @override
  String get profileCopyIdTooltip => 'Copy account ID';

  @override
  String get profileSectionAppearance => 'Appearance';

  @override
  String get profileAppearanceSectionSubtitle => 'Theme, color and language';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileAccountSectionSubtitle => 'Security and privacy controls';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileChangePasswordSubtitle =>
      'Update your account security credentials';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteAccountSubtitle =>
      'Permanently remove your account and data';

  @override
  String get profileDeleteAccountDialogTitle => 'Delete account?';

  @override
  String get profileDeleteAccountDialogMessage =>
      'This permanently removes your account and all of its data. This action cannot be undone.';

  @override
  String profileDeleteAccountConfirmLabel(String username) {
    return 'Type \"$username\" to confirm';
  }

  @override
  String get profileDeleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get profileDeleteAccountError =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get changePasswordAppBarTitle => 'Change Password';

  @override
  String get changePasswordCurrentLabel => 'Current Password';

  @override
  String get changePasswordNewLabel => 'New Password';

  @override
  String get changePasswordConfirmLabel => 'Confirm New Password';

  @override
  String get changePasswordSubmit => 'Update Password';

  @override
  String get changePasswordSuccessMessage => 'Password updated successfully.';

  @override
  String get changePasswordMismatchError => 'New passwords do not match.';

  @override
  String get profileSectionAbout => 'About';

  @override
  String get profileAboutSectionSubtitle => 'Version and application details';

  @override
  String get profileUserIdCopied => 'User ID copied';

  @override
  String get profileAppearanceThemeLabel => 'Theme';

  @override
  String get profileAppearanceColorLabel => 'Accent color';

  @override
  String get profileThemeSystemDefault => 'System default';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String profileAppVersionBuild(String version, String buildNumber) {
    return 'Version $version (build $buildNumber)';
  }

  @override
  String get profileAppStatus => 'Up to date';

  @override
  String get profileSignOutConfirmMessage =>
      'Are you sure you want to sign out?';

  @override
  String get bookmarksAppBarTitle => 'Bookmarks';

  @override
  String get bookmarksSearchHint => 'Search title, URL, or tag';

  @override
  String get bookmarksNoMatchesTitle => 'No matches';

  @override
  String get bookmarksNoMatchesMessage => 'No bookmarks match your search.';

  @override
  String get bookmarksEmptyTitle => 'No bookmarks yet';

  @override
  String get bookmarksEmptyMessage => 'Tap + to add your first bookmark.';

  @override
  String get bookmarksNotYetSynced => 'Not yet synced';

  @override
  String get bookmarksSyncFailedRetryTooltip => 'Sync failed - tap to retry';

  @override
  String get bookmarksAddTooltip => 'Add bookmark';

  @override
  String get bookmarksSearchClear => 'Clear search';

  @override
  String get bookmarksSortTooltip => 'Sort bookmarks';

  @override
  String get bookmarksSortMenuLabel => 'Sort Menu';

  @override
  String get bookmarksSortNewest => 'Newest first';

  @override
  String get bookmarksSortOldest => 'Oldest first';

  @override
  String get bookmarksSortTitleAz => 'Title (A–Z)';

  @override
  String get bookmarksTabAll => 'All';

  @override
  String get bookmarksTabRecent => 'Recent';

  @override
  String get bookmarksTabCollections => 'Collections';

  @override
  String get bookmarksRecentEmptyTitle => 'Nothing recent';

  @override
  String get bookmarksRecentEmptyMessage =>
      'Bookmarks you add this week show up here.';

  @override
  String get bookmarksCollectionsComingSoonTitle => 'Collections coming soon';

  @override
  String get bookmarksCollectionsComingSoonMessage =>
      'Group related bookmarks into collections in a future update.';

  @override
  String get bookmarkMoreActions => 'More actions';

  @override
  String get bookmarkAppBarTitle => 'Bookmark Details';

  @override
  String get bookmarkSourceLabel => 'Source';

  @override
  String get bookmarkVisitWebsite => 'Visit Website';

  @override
  String get bookmarkDetailsLabel => 'Details';

  @override
  String get bookmarkDateCreatedLabel => 'Date Created';

  @override
  String get bookmarkLastModifiedLabel => 'Last Modified';

  @override
  String get bookmarkMediaLabel => 'Media';

  @override
  String get bookmarkOpenInBrowser => 'Open in Browser';

  @override
  String get bookmarkNotFound => 'Bookmark not found.';

  @override
  String get bookmarkDeleteDialogTitle => 'Delete bookmark?';

  @override
  String get bookmarkDeleteDialogBody =>
      'This action cannot be undone.\nThe bookmark will be permanently removed from your collection.';

  @override
  String bookmarkDeleteDialogMessage(String title) {
    return '\"$title\" will be removed.';
  }

  @override
  String get bookmarkOpenUrl => 'Open URL';

  @override
  String get bookmarkAttachedVideo => 'Attached video';

  @override
  String get bookmarkInvalidUrl => 'Invalid URL';

  @override
  String get bookmarkCouldNotOpenUrl => 'Could not open URL';

  @override
  String get bookmarkFormEditTitle => 'Edit bookmark';

  @override
  String get bookmarkFormNewTitle => 'New bookmark';

  @override
  String get bookmarkFormLoadFailed => 'Failed to load bookmark.';

  @override
  String get bookmarkTitleLabel => 'Title';

  @override
  String get bookmarkUrlLabel => 'URL';

  @override
  String get bookmarkDescriptionLabel => 'Description (optional)';

  @override
  String get bookmarkTagsLabel => 'Tags';

  @override
  String get bookmarkTagsHint => 'comma, separated, values';

  @override
  String get bookmarkPreviewLabel => 'Bookmark';

  @override
  String get bookmarkTitleRequired => 'Title is required';

  @override
  String get bookmarkUrlRequired => 'URL is required';

  @override
  String get bookmarkUrlInvalid => 'Enter a valid URL (https://…)';

  @override
  String get errorPermissionDenied => 'Permission denied.';

  @override
  String get errorGalleryPermissionRequired =>
      'Photo gallery access is required to attach images.';

  @override
  String get errorCameraPermissionRequired =>
      'Camera access is required to take photos.';

  @override
  String get navHome => 'Home';

  @override
  String get navBookmarks => 'Saved';

  @override
  String get navProfile => 'Account';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsAppBarTitle => 'Settings';

  @override
  String get bookmarksDetailPlaceholder =>
      'Select a bookmark to view its details';

  @override
  String bookmarkImageLabel(String title) {
    return 'Image for $title';
  }

  @override
  String get bookmarkAttachedImageLabel => 'Attached image';

  @override
  String get bookmarkRemoveImageLabel => 'Remove image';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get notificationsAppBarTitle => 'Notifications';

  @override
  String get notificationsActivitySection => 'Your activity';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationsSectionNew => 'New';

  @override
  String get notificationsSectionEarlier => 'Earlier';

  @override
  String get notificationsEmptyTitle => 'Nothing here yet';

  @override
  String get notificationsEmptyMessage =>
      'Your notifications and recent activity will appear here.';

  @override
  String get notificationsNoNotifications => 'No notifications yet.';

  @override
  String get notificationsLoadError =>
      'Couldn\'t load your notifications. Pull to refresh or try again.';

  @override
  String notificationsUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyMessage =>
      'Group related bookmarks into collections.';

  @override
  String get collectionsLoadError =>
      'Couldn\'t load your collections. Pull to refresh or try again.';

  @override
  String get collectionsCreate => 'New collection';

  @override
  String get collectionsCreateTitle => 'New collection';

  @override
  String get collectionsEditTitle => 'Edit collection';

  @override
  String get collectionNameLabel => 'Name';

  @override
  String get collectionNameHint => 'e.g. Design inspiration';

  @override
  String get collectionNameRequired => 'Name is required';

  @override
  String get collectionAppearanceLabel => 'Icon & color';

  @override
  String get collectionSave => 'Save';

  @override
  String get collectionDeleteAction => 'Delete collection';

  @override
  String get collectionDeleteDialogTitle => 'Delete collection?';

  @override
  String collectionDeleteDialogMessage(String name) {
    return '\"$name\" will be removed. Your bookmarks stay.';
  }

  @override
  String get collectionNotFound => 'Collection not found.';

  @override
  String collectionItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookmarks',
      one: '1 bookmark',
      zero: 'No bookmarks',
    );
    return '$_temp0';
  }

  @override
  String get collectionAddBookmarks => 'Add bookmarks';

  @override
  String get collectionRemoveBookmark => 'Remove from collection';

  @override
  String get collectionEmptyBookmarks => 'No bookmarks in this collection yet.';

  @override
  String get collectionPickerEmpty =>
      'All your bookmarks are already in this collection.';

  @override
  String collectionPickerAddCount(int count) {
    return 'Add $count';
  }

  @override
  String get addToCollectionTitle => 'Add to collection';

  @override
  String get addToCollectionEmpty =>
      'You haven\'t created any collections yet.';

  @override
  String get homeCreateCollection => 'Create collection';

  @override
  String get bookmarkAttachGallery => 'Gallery';

  @override
  String get bookmarkAttachCamera => 'Camera';

  @override
  String get bookmarkAttachVideo => 'Video';

  @override
  String get bookmarkAttachRecord => 'Record';

  @override
  String get bookmarkRemoveVideoLabel => 'Remove video';

  @override
  String get videoPlayerPlay => 'Play';

  @override
  String get videoPlayerPause => 'Pause';

  @override
  String get videoPlayerMute => 'Mute';

  @override
  String get videoPlayerUnmute => 'Unmute';

  @override
  String get videoPlayerFullScreen => 'Full screen';

  @override
  String get videoPlayerExitFullScreen => 'Exit full screen';

  @override
  String get videoPlayerPlaybackSpeed => 'Playback speed';

  @override
  String get videoPlayerLoadFailed => 'Failed to load video';

  @override
  String get profileAppearanceLanguageLabel => 'Language';

  @override
  String get systemSettingsTitle => 'System settings';

  @override
  String get systemSettingsSubtitle => 'Personalize your app experience';

  @override
  String get systemSettingsOpen => 'Open system settings';

  @override
  String get systemSettingsAppearance => 'Appearance and color';

  @override
  String get systemSettingsAppearanceHint =>
      'Choose the appearance and accent that suit you';

  @override
  String get systemSettingsTypography => 'Type and reading';

  @override
  String get systemSettingsTypographyHint =>
      'Change the font and text size across the app';

  @override
  String get systemSettingsFont => 'Font family';

  @override
  String get systemSettingsFontSystem => 'System font';

  @override
  String get systemSettingsFontSystemHint => 'Use the device\'s default font';

  @override
  String get systemSettingsFontPreview => 'English and نص عربي 123';

  @override
  String get systemSettingsBrowseFonts => 'Tap to choose a font family';

  @override
  String get systemSettingsSuggestedFonts => 'Suggested';

  @override
  String get systemSettingsFontLibrary => 'Choose a font family';

  @override
  String get systemSettingsFontLibraryHint =>
      'Names load gradually; the font is loaded only after selection';

  @override
  String get systemSettingsFontSearchHint => 'Search by font name';

  @override
  String get systemSettingsFontNoResults => 'No matching font found';

  @override
  String get systemSettingsFontLoadError => 'The font list could not be loaded';

  @override
  String get systemSettingsRetry => 'Try again';

  @override
  String get systemSettingsTextSize => 'Text size';

  @override
  String get systemSettingsTextCompact => 'Small';

  @override
  String get systemSettingsTextStandard => 'Standard';

  @override
  String get systemSettingsTextLarge => 'Large';

  @override
  String get systemSettingsLanguageHint =>
      'The interface language and direction update immediately';

  @override
  String get systemSettingsLanguageSystemHint =>
      'Automatically follow the device language';

  @override
  String get systemSettingsPreviewTitle => 'Live preview';

  @override
  String get systemSettingsReset => 'Restore default settings';

  @override
  String get documentCenterTitle => 'Document Center';

  @override
  String get documentCenterSubtitle =>
      'Import, export, report composition and printing';

  @override
  String get documentCenterTabImport => 'Import Data';

  @override
  String get documentCenterTabExport => 'Export Data';

  @override
  String get documentCenterTabReports => 'Reports & Printing';

  @override
  String get documentImportSelectFile => 'Select File';

  @override
  String get documentImportSelectFileHint =>
      'Select a CSV, XLSX, or JSON file to import';

  @override
  String documentImportFileSelected(String fileName) {
    return 'Selected file: $fileName';
  }

  @override
  String documentImportDetectedFormat(String format) {
    return 'Detected format: $format';
  }

  @override
  String get documentImportSourceColumns => 'Source columns';

  @override
  String get documentImportTargetSchema => 'Target schema';

  @override
  String get documentImportValidateButton => 'Validate Dataset';

  @override
  String get documentImportCommitButton => 'Commit Import';

  @override
  String get documentImportPreviewTitle => 'Validation Preview';

  @override
  String documentImportValidRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Valid rows: $countString';
  }

  @override
  String documentImportInvalidRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Invalid rows: $countString';
  }

  @override
  String documentImportSuccessMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Successfully imported $countString records';
  }

  @override
  String documentImportErrorMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Import validation failed with $countString errors';
  }

  @override
  String get documentExportDatasetLabel => 'Select Dataset';

  @override
  String get documentExportFormatLabel => 'Export Format';

  @override
  String get documentExportColumnsLabel => 'Select Columns';

  @override
  String get documentExportNeutralizeFormulas =>
      'Protect against spreadsheet formula injection';

  @override
  String get documentExportButton => 'Export Document';

  @override
  String documentExportSuccess(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return 'Export completed ($bytesString bytes)';
  }

  @override
  String get documentReportsSelectTemplate => 'Report Template';

  @override
  String get documentReportsSales => 'Sales Summary Report';

  @override
  String get documentReportsInventory => 'Inventory Movement Report';

  @override
  String get documentReportsStatement => 'Supplier Account Statement';

  @override
  String get documentReportsInvoice => 'Commercial Tax Invoice';

  @override
  String get documentReportsGeneral => 'General Activity Log';

  @override
  String get documentReportsGeneratePdf => 'Generate PDF';

  @override
  String get documentReportsPrintSystem => 'System Print';

  @override
  String get documentReportsPrintThermal => 'Thermal Print (ESC/POS)';

  @override
  String get documentReportsThermalSuccess =>
      'Document sent to thermal printer';

  @override
  String get documentReportsPreviewTitle => 'Report Preview';

  @override
  String get collectionsImportAction => 'Import Collections';

  @override
  String get bookmarksImportAction => 'Import Bookmarks';

  @override
  String get documentImportDatasetLabel => 'Target Dataset';

  @override
  String get documentImportDuplicatePolicyLabel => 'Duplicate Handling Policy';

  @override
  String get documentImportPolicySkip => 'Skip Duplicates';

  @override
  String get documentImportPolicyUpdate => 'Update Existing';

  @override
  String get documentImportPolicyCreate => 'Create New Copies';

  @override
  String documentImportCreatedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Created: $countString';
  }

  @override
  String documentImportUpdatedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Updated: $countString';
  }

  @override
  String documentImportSkippedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Skipped: $countString';
  }

  @override
  String documentImportFailedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Failed: $countString';
  }

  @override
  String get documentImportSummaryTitle => 'Import Result Summary';

  @override
  String get documentImportCloseButton => 'Close';

  @override
  String get routeNotFoundTitle => 'Page Not Found';

  @override
  String routeNotFoundMessage(String location) {
    return 'No page matches $location.';
  }

  @override
  String get routeNotFoundHomeAction => 'Go to Home';

  @override
  String get exitAppTitle => 'Exit app?';

  @override
  String get exitAppMessage => 'Press Exit to close the app.';

  @override
  String get exitAppConfirm => 'Exit';

  @override
  String get documentImportDemoSales => 'Sales (Demo)';

  @override
  String get documentProgressReading => 'Reading document…';

  @override
  String get documentProgressParsing => 'Parsing document…';

  @override
  String documentProgressValidating(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Validating $currentString of $totalString…';
  }

  @override
  String get documentProgressCommitting => 'Saving imported records…';

  @override
  String get documentReportPdfFailure => 'The PDF could not be generated.';

  @override
  String documentThermalSuccessBytes(int bytes) {
    final intl.NumberFormat bytesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bytesString = bytesNumberFormat.format(bytes);

    return 'Document sent to the thermal printer ($bytesString bytes)';
  }

  @override
  String get documentThermalFailure =>
      'The document could not be sent to the thermal printer.';

  @override
  String get documentFileReadFailure => 'The selected file could not be read.';

  @override
  String get documentImportValidationFailure =>
      'The document is damaged, unsupported, or does not match the selected dataset.';

  @override
  String get documentImportCommitFailure =>
      'The validated rows could not be saved. No partial import was kept.';

  @override
  String get documentExportFailure => 'The document could not be exported.';

  @override
  String get documentSaveFailure => 'The exported file could not be saved.';
}
