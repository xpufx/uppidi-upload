import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_tr.dart';

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
    Locale('it'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Uppidi Upload'**
  String get appTitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please check your credentials in Settings.'**
  String get errorSessionExpired;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large for this provider.'**
  String get errorFileTooLarge;

  /// No description provided for @errorInvalidUploader.
  ///
  /// In en, this message translates to:
  /// **'Invalid uploader configuration. Please check your settings or try again later.'**
  String get errorInvalidUploader;

  /// No description provided for @invalidMimeType.
  ///
  /// In en, this message translates to:
  /// **'Invalid or unsupported file type.'**
  String get invalidMimeType;

  /// No description provided for @fileSystemError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get fileSystemError;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the provider. It may be unreachable or blocked by your browser.'**
  String get errorConnectionFailed;

  /// No description provided for @uploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled.'**
  String get uploadCancelled;

  /// No description provided for @providerWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This provider cannot be used directly in a web browser. Enable the experimental proxy in settings.'**
  String get providerWebNotSupported;

  /// No description provided for @selfSignedCertWarning.
  ///
  /// In en, this message translates to:
  /// **'Insecure connection mode bypasses certificate validation. Only enable this for trusted self-hosted servers.'**
  String get selfSignedCertWarning;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete!'**
  String get uploadComplete;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @cancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Upload'**
  String get cancelUpload;

  /// No description provided for @pickAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Pick & Upload'**
  String get pickAndUpload;

  /// No description provided for @urlCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'URL copied to clipboard'**
  String get urlCopiedToClipboard;

  /// No description provided for @shareUrl.
  ///
  /// In en, this message translates to:
  /// **'Share URL'**
  String get shareUrl;

  /// No description provided for @selectProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Provider'**
  String get selectProvider;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upload history yet'**
  String get historyEmpty;

  /// No description provided for @enableInsecure.
  ///
  /// In en, this message translates to:
  /// **'Allow insecure connections'**
  String get enableInsecure;

  /// No description provided for @proxyUrl.
  ///
  /// In en, this message translates to:
  /// **'Proxy URL'**
  String get proxyUrl;

  /// No description provided for @navProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get navProviders;

  /// No description provided for @providersSection.
  ///
  /// In en, this message translates to:
  /// **'Provider Configuration'**
  String get providersSection;

  /// No description provided for @historyClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get historyClearAll;

  /// No description provided for @historyClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all history?'**
  String get historyClearConfirm;

  /// No description provided for @historyRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String historyRecords(Object count);

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @noProviders.
  ///
  /// In en, this message translates to:
  /// **'No providers configured. Add one in Settings.'**
  String get noProviders;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'You are about to upload to {provider}. We are not affiliated with that service.'**
  String disclaimer(Object provider);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @themeCustomLogo.
  ///
  /// In en, this message translates to:
  /// **'Custom Logo'**
  String get themeCustomLogo;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get themeSeedColor;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(Object minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(Object hours);

  /// No description provided for @navTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get navTest;

  /// No description provided for @testAll.
  ///
  /// In en, this message translates to:
  /// **'Test All'**
  String get testAll;

  /// No description provided for @testProvider.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testProvider;

  /// No description provided for @noProvidersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get noProvidersAvailable;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @viewChangelog.
  ///
  /// In en, this message translates to:
  /// **'View Changelog'**
  String get viewChangelog;

  /// No description provided for @changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelogTitle;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @chooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose Logo'**
  String get chooseLogo;

  /// No description provided for @providersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} providers'**
  String providersCount(Object count);

  /// No description provided for @defaultForSharing.
  ///
  /// In en, this message translates to:
  /// **'Default for sharing'**
  String get defaultForSharing;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @proxyHint.
  ///
  /// In en, this message translates to:
  /// **'socks5://host:port'**
  String get proxyHint;

  /// No description provided for @dropFileToUpload.
  ///
  /// In en, this message translates to:
  /// **'Drop file to upload'**
  String get dropFileToUpload;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @deleteThisRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get deleteThisRecord;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @includeMessage.
  ///
  /// In en, this message translates to:
  /// **'Include message'**
  String get includeMessage;

  /// No description provided for @templateVars.
  ///
  /// In en, this message translates to:
  /// **'Template Variables'**
  String get templateVars;

  /// No description provided for @templateExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples:'**
  String get templateExamples;

  /// No description provided for @customizeMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize:'**
  String get customizeMessage;

  /// No description provided for @debugLogging.
  ///
  /// In en, this message translates to:
  /// **'Enable debug logging'**
  String get debugLogging;

  /// No description provided for @debugLoggingDescription.
  ///
  /// In en, this message translates to:
  /// **'Logs full HTTP request/response details to the console for troubleshooting. Only enable when needed.'**
  String get debugLoggingDescription;

  /// No description provided for @qualityOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get qualityOriginal;

  /// No description provided for @qualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (1920px)'**
  String get qualityMedium;

  /// No description provided for @qualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low (800px)'**
  String get qualityLow;

  /// No description provided for @uiVariant.
  ///
  /// In en, this message translates to:
  /// **'UI Variant'**
  String get uiVariant;

  /// No description provided for @uiVariantDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the main screen provider layout: List or Chips.'**
  String get uiVariantDescription;

  /// No description provided for @uiVariantDefault.
  ///
  /// In en, this message translates to:
  /// **'Provider List'**
  String get uiVariantDefault;

  /// No description provided for @uiVariantCompact.
  ///
  /// In en, this message translates to:
  /// **'Provider Chips'**
  String get uiVariantCompact;

  /// No description provided for @iconLegendWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get iconLegendWarning;

  /// No description provided for @iconLegendExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry days'**
  String get iconLegendExpiry;

  /// No description provided for @iconLegendFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get iconLegendFileSize;

  /// No description provided for @iconLegendAcceptedFiles.
  ///
  /// In en, this message translates to:
  /// **'Accepted files'**
  String get iconLegendAcceptedFiles;

  /// No description provided for @iconLegendDirectLinks.
  ///
  /// In en, this message translates to:
  /// **'Direct links'**
  String get iconLegendDirectLinks;

  /// No description provided for @iconLegendAccount.
  ///
  /// In en, this message translates to:
  /// **'Account required'**
  String get iconLegendAccount;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload files to multiple free hosting services. Fast, simple, and supports many providers.'**
  String get appDescription;

  /// No description provided for @providerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Info'**
  String get providerInfoTitle;

  /// No description provided for @maxFileSize.
  ///
  /// In en, this message translates to:
  /// **'Max file size: {size}'**
  String maxFileSize(Object size);

  /// No description provided for @acceptedFiles.
  ///
  /// In en, this message translates to:
  /// **'Accepted files: {types}'**
  String acceptedFiles(Object types);

  /// No description provided for @expiryInfo.
  ///
  /// In en, this message translates to:
  /// **'Files expire: {info}'**
  String expiryInfo(Object info);

  /// No description provided for @supportsDirectLinks.
  ///
  /// In en, this message translates to:
  /// **'Supports direct links'**
  String get supportsDirectLinks;

  /// No description provided for @requiresAccount.
  ///
  /// In en, this message translates to:
  /// **'Requires account'**
  String get requiresAccount;

  /// No description provided for @iconLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Icons'**
  String get iconLegendTitle;

  /// No description provided for @iconLegendTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get iconLegendTest;

  /// No description provided for @iconLegendFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get iconLegendFiles;

  /// No description provided for @iconLegendLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get iconLegendLinks;

  /// No description provided for @iconLegendImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get iconLegendImages;

  /// No description provided for @iconLegendOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get iconLegendOther;
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
      <String>['en', 'it', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
