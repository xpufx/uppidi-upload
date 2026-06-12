import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_eo.dart';
import 'app_localizations_it.dart';
import 'app_localizations_tlh.dart';
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
    Locale('eo'),
    Locale('it'),
    Locale('tlh'),
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
  /// **'Providers'**
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

  /// No description provided for @userAgent.
  ///
  /// In en, this message translates to:
  /// **'User-Agent'**
  String get userAgent;

  /// No description provided for @userAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Custom User-Agent header for upload requests'**
  String get userAgentHint;

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
  /// **'Half size'**
  String get qualityMedium;

  /// No description provided for @qualityLow.
  ///
  /// In en, this message translates to:
  /// **'Quarter size'**
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

  /// No description provided for @insecureWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Insecure Connection'**
  String get insecureWarningTitle;

  /// No description provided for @insecureWarningHttp.
  ///
  /// In en, this message translates to:
  /// **'The provider {providerName} at {url} uses an insecure HTTP connection. Your files and authentication data will be sent in plain text.'**
  String insecureWarningHttp(Object providerName, Object url);

  /// No description provided for @insecureWarningHttps.
  ///
  /// In en, this message translates to:
  /// **'The provider {providerName} at {url} has a self-signed or invalid certificate. The connection may not be secure.'**
  String insecureWarningHttps(Object providerName, Object url);

  /// No description provided for @viewCertificate.
  ///
  /// In en, this message translates to:
  /// **'View Certificate'**
  String get viewCertificate;

  /// No description provided for @certificateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Certificate'**
  String get certificateDialogTitle;

  /// No description provided for @certSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get certSubject;

  /// No description provided for @certIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get certIssuer;

  /// No description provided for @certValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get certValidFrom;

  /// No description provided for @certValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get certValidUntil;

  /// No description provided for @certFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get certFingerprint;

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceedAnyway;

  /// No description provided for @dontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again for this provider'**
  String get dontShowAgain;

  /// No description provided for @viewDebugLog.
  ///
  /// In en, this message translates to:
  /// **'View debug log'**
  String get viewDebugLog;

  /// No description provided for @navigationLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get navigationLeft;

  /// No description provided for @navigationBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get navigationBottom;

  /// No description provided for @navigationRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get navigationRight;

  /// No description provided for @navLayout.
  ///
  /// In en, this message translates to:
  /// **'Nav Layout'**
  String get navLayout;

  /// No description provided for @navLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose navigation position: Left, Bottom, or Right.'**
  String get navLayoutDescription;

  /// No description provided for @selectedExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires in: {expiry}'**
  String selectedExpiry(Object expiry);

  /// No description provided for @deleteUrl.
  ///
  /// In en, this message translates to:
  /// **'Delete URL'**
  String get deleteUrl;

  /// No description provided for @openDeleteUrl.
  ///
  /// In en, this message translates to:
  /// **'Open delete URL'**
  String get openDeleteUrl;

  /// No description provided for @deleteUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Delete URL copied to clipboard'**
  String get deleteUrlCopied;

  /// No description provided for @copyDeleteUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy delete URL'**
  String get copyDeleteUrl;

  /// No description provided for @failedToReadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to read selected file'**
  String get failedToReadFile;

  /// No description provided for @noProvidersConfigured.
  ///
  /// In en, this message translates to:
  /// **'No upload providers configured'**
  String get noProvidersConfigured;

  /// No description provided for @connectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out'**
  String get connectionTimedOut;

  /// No description provided for @connectionFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailedMsg(Object error);

  /// No description provided for @serverErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Server error: {code}'**
  String serverErrorMsg(Object code);

  /// No description provided for @uploadFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {reason}'**
  String uploadFailedMsg(Object reason);

  /// No description provided for @speedBS.
  ///
  /// In en, this message translates to:
  /// **'{speed} B/s'**
  String speedBS(Object speed);

  /// No description provided for @speedKBS.
  ///
  /// In en, this message translates to:
  /// **'{speed} KB/s'**
  String speedKBS(Object speed);

  /// No description provided for @speedMBS.
  ///
  /// In en, this message translates to:
  /// **'{speed} MB/s'**
  String speedMBS(Object speed);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @expiry1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get expiry1Hour;

  /// No description provided for @expiry24Hours.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get expiry24Hours;

  /// No description provided for @expiry3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get expiry3Days;

  /// No description provided for @resetCrop.
  ///
  /// In en, this message translates to:
  /// **'Reset crop'**
  String get resetCrop;

  /// No description provided for @debugInfo.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfo;

  /// No description provided for @debugInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Debug info'**
  String get debugInfoTooltip;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get copyAll;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @fileExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'File exceeds {size} limit'**
  String fileExceedsLimit(Object size);

  /// No description provided for @providerOnlyAccepts.
  ///
  /// In en, this message translates to:
  /// **'Provider only accepts: {types}'**
  String providerOnlyAccepts(Object types);

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemInfo;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @gplNotice.
  ///
  /// In en, this message translates to:
  /// **'This project is licensed under the GNU General Public License v3.0.'**
  String get gplNotice;

  /// No description provided for @gplUrl.
  ///
  /// In en, this message translates to:
  /// **'https://www.gnu.org/licenses/gpl-3.0.txt'**
  String get gplUrl;

  /// No description provided for @noLogEntries.
  ///
  /// In en, this message translates to:
  /// **'No log entries yet.'**
  String get noLogEntries;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Uppidi Upload v{version}'**
  String versionLabel(Object version);

  /// No description provided for @shellLayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Shell Layout'**
  String get shellLayoutTitle;

  /// No description provided for @shellLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how screens are organized: \"Tabs\" uses a tab bar for navigation. \"Modals\" shows the upload screen always and opens other screens as dialogs.'**
  String get shellLayoutDescription;

  /// No description provided for @tabs.
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get tabs;

  /// No description provided for @modals.
  ///
  /// In en, this message translates to:
  /// **'Modals'**
  String get modals;

  /// No description provided for @downloadAndroid.
  ///
  /// In en, this message translates to:
  /// **'Download Android APK'**
  String get downloadAndroid;

  /// No description provided for @downloadLinux.
  ///
  /// In en, this message translates to:
  /// **'Download Linux'**
  String get downloadLinux;

  /// No description provided for @browseAllBuilds.
  ///
  /// In en, this message translates to:
  /// **'Browse all builds'**
  String get browseAllBuilds;

  /// No description provided for @viewReleases.
  ///
  /// In en, this message translates to:
  /// **'View releases on GitHub'**
  String get viewReleases;

  /// No description provided for @downloadingFile.
  ///
  /// In en, this message translates to:
  /// **'Downloading {label}'**
  String downloadingFile(Object label);

  /// No description provided for @downloadedTo.
  ///
  /// In en, this message translates to:
  /// **'Downloaded to: {path}'**
  String downloadedTo(Object path);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(Object error);

  /// No description provided for @changelogNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Changelog not available'**
  String get changelogNotAvailable;

  /// No description provided for @debugLogCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} — copied to clipboard'**
  String debugLogCopied(Object label);

  /// No description provided for @devBuild.
  ///
  /// In en, this message translates to:
  /// **'DEV BUILD'**
  String get devBuild;

  /// No description provided for @versionPrefix.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String versionPrefix(Object version);

  /// No description provided for @providerConfigDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the credentials required by this provider.'**
  String get providerConfigDescription;

  /// No description provided for @providerConfigSecretHint.
  ///
  /// In en, this message translates to:
  /// **'This value is stored locally and never shared.'**
  String get providerConfigSecretHint;

  /// No description provided for @providerConfigRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get providerConfigRequired;

  /// No description provided for @providerConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'{provider} configuration saved!'**
  String providerConfigSaved(Object provider);

  /// No description provided for @providerConfigSectionConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get providerConfigSectionConfigured;

  /// No description provided for @providerConfigNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'{provider} — not configured'**
  String providerConfigNotConfigured(Object provider);

  /// No description provided for @providerConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get providerConfigure;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @telegramErrorChatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found. Please check your Chat ID.'**
  String get telegramErrorChatNotFound;

  /// No description provided for @telegramErrorBotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Bot was blocked by the user. Unblock the bot first.'**
  String get telegramErrorBotBlocked;

  /// No description provided for @telegramErrorNoRights.
  ///
  /// In en, this message translates to:
  /// **'Bot lacks rights to send messages in this chat.'**
  String get telegramErrorNoRights;

  /// No description provided for @telegramErrorInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid bot token. Check your Bot Token from BotFather.'**
  String get telegramErrorInvalidToken;

  /// No description provided for @telegramSentToChat.
  ///
  /// In en, this message translates to:
  /// **'Sent to Telegram chat'**
  String get telegramSentToChat;

  /// No description provided for @expiryPersistent.
  ///
  /// In en, this message translates to:
  /// **'Persistent (until bot token is revoked)'**
  String get expiryPersistent;

  /// No description provided for @expiryIndefinite30d.
  ///
  /// In en, this message translates to:
  /// **'Indefinite (inactive >30d may delete)'**
  String get expiryIndefinite30d;

  /// No description provided for @expiryOneDayExtendable.
  ///
  /// In en, this message translates to:
  /// **'~1 day (extendable on re-upload)'**
  String get expiryOneDayExtendable;

  /// No description provided for @expiryOptions1h12h24h72h.
  ///
  /// In en, this message translates to:
  /// **'1h / 12h / 24h / 72h'**
  String get expiryOptions1h12h24h72h;

  /// No description provided for @expiry3Hours.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get expiry3Hours;

  /// No description provided for @expiry7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expiry7Days;

  /// No description provided for @mimeTypesImagesOnly.
  ///
  /// In en, this message translates to:
  /// **'Images only'**
  String get mimeTypesImagesOnly;

  /// No description provided for @configLabelBotToken.
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get configLabelBotToken;

  /// No description provided for @configLabelChatId.
  ///
  /// In en, this message translates to:
  /// **'Chat ID'**
  String get configLabelChatId;

  /// No description provided for @configLabelSendAsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send images as photos'**
  String get configLabelSendAsPhoto;

  /// No description provided for @myProviders.
  ///
  /// In en, this message translates to:
  /// **'My Providers'**
  String get myProviders;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get addProvider;

  /// No description provided for @noInstancesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No instances configured'**
  String get noInstancesConfigured;

  /// No description provided for @deleteInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete instance?'**
  String get deleteInstanceTitle;

  /// No description provided for @deleteInstanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its credentials?'**
  String deleteInstanceConfirm(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in required fields first'**
  String get fillRequiredFields;

  /// No description provided for @debugResponse.
  ///
  /// In en, this message translates to:
  /// **'Debug response'**
  String get debugResponse;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @configLabelServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get configLabelServerUrl;

  /// No description provided for @configLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get configLabelEmail;

  /// No description provided for @configLabelApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get configLabelApiKey;

  /// No description provided for @configLabelInstanceName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get configLabelInstanceName;

  /// No description provided for @configInstanceNameHelper.
  ///
  /// In en, this message translates to:
  /// **'A label to identify this instance'**
  String get configInstanceNameHelper;

  /// No description provided for @currentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get currentlyUnavailable;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropImage;

  /// No description provided for @builtInProviders.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInProviders;

  /// No description provided for @testStepReachable.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get testStepReachable;

  /// No description provided for @testStepNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get testStepNotProvided;

  /// No description provided for @testStepNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get testStepNotFound;

  /// No description provided for @testStepInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get testStepInvalid;

  /// No description provided for @connectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as @{username}'**
  String connectedAs(Object username);

  /// No description provided for @chatAccessible.
  ///
  /// In en, this message translates to:
  /// **'Chat \"{title}\" accessible'**
  String chatAccessible(Object title);

  /// No description provided for @configLabelChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get configLabelChannel;

  /// No description provided for @configLabelTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get configLabelTopic;

  /// No description provided for @configLabelDirectMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get configLabelDirectMessage;

  /// No description provided for @configLabelApiToken.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get configLabelApiToken;

  /// No description provided for @configLabelGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get configLabelGateway;

  /// No description provided for @configLabelUploadVia.
  ///
  /// In en, this message translates to:
  /// **'Upload via'**
  String get configLabelUploadVia;

  /// No description provided for @configLabelRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get configLabelRecipient;

  /// No description provided for @providerDescTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram Bot API — send files to any chat'**
  String get providerDescTelegram;

  /// No description provided for @providerDescZulip.
  ///
  /// In en, this message translates to:
  /// **'Zulip — upload files to your Zulip server'**
  String get providerDescZulip;

  /// No description provided for @providerDescMatterbridge.
  ///
  /// In en, this message translates to:
  /// **'Matterbridge — relay files to bridged gateways'**
  String get providerDescMatterbridge;

  /// No description provided for @providerDescCustomUguu.
  ///
  /// In en, this message translates to:
  /// **'Uguu-compatible — upload to your own server'**
  String get providerDescCustomUguu;

  /// No description provided for @matterbridgeSend.
  ///
  /// In en, this message translates to:
  /// **'Send via Matterbridge'**
  String get matterbridgeSend;

  /// No description provided for @matterbridgeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Matterbridge not fully configured'**
  String get matterbridgeNotConfigured;

  /// No description provided for @matterbridgeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {gateway}'**
  String matterbridgeSent(Object gateway);

  /// No description provided for @matterbridgeError.
  ///
  /// In en, this message translates to:
  /// **'Matterbridge error: {code}'**
  String matterbridgeError(Object code);

  /// No description provided for @matterbridgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String matterbridgeFailed(Object error);

  /// No description provided for @messageVariables.
  ///
  /// In en, this message translates to:
  /// **'Variables: {vars}'**
  String messageVariables(Object vars);

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No image found in clipboard'**
  String get clipboardEmpty;

  /// No description provided for @exportImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get exportImportTitle;

  /// No description provided for @exportImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Export your provider credentials and app settings to a JSON file for backup or transfer. Import merges all data — existing settings and provider config will be replaced.'**
  String get exportImportDescription;

  /// No description provided for @exportConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Export config'**
  String get exportConfigTitle;

  /// No description provided for @exportConfigWarning.
  ///
  /// In en, this message translates to:
  /// **'This file will contain API keys, tokens, passwords, and app settings. Keep it safe — anyone with this file can access your accounts.'**
  String get exportConfigWarning;

  /// No description provided for @importConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Import config'**
  String get importConfigTitle;

  /// No description provided for @importConfigWarning.
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE all current provider credentials and settings with the data from the imported file. This cannot be undone.'**
  String get importConfigWarning;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to: {path}'**
  String exportedTo(Object path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @apkDownloaded.
  ///
  /// In en, this message translates to:
  /// **'APK downloaded'**
  String get apkDownloaded;

  /// No description provided for @installNow.
  ///
  /// In en, this message translates to:
  /// **'Install Now'**
  String get installNow;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String secondsAgo(Object seconds);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @reloadZulipResources.
  ///
  /// In en, this message translates to:
  /// **'Load channels & users'**
  String get reloadZulipResources;

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

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @ratio.
  ///
  /// In en, this message translates to:
  /// **'Aspect ratio'**
  String get ratio;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacity;

  /// No description provided for @fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fill;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @lineWidth.
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get lineWidth;

  /// No description provided for @strokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke width'**
  String get strokeWidth;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

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

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @exposure.
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get exposure;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @sharpness.
  ///
  /// In en, this message translates to:
  /// **'Sharpness'**
  String get sharpness;

  /// No description provided for @fade.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get fade;

  /// No description provided for @textAlign.
  ///
  /// In en, this message translates to:
  /// **'Text align'**
  String get textAlign;

  /// No description provided for @fontScale.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontScale;

  /// No description provided for @backgroundMode.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundMode;

  /// No description provided for @inputHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get inputHintText;

  /// No description provided for @closeEditorWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get closeEditorWarningTitle;

  /// No description provided for @closeEditorWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get closeEditorWarningMessage;

  /// No description provided for @closeEditorWarningConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get closeEditorWarningConfirmBtn;

  /// No description provided for @arrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get arrow;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @circle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circle;

  /// No description provided for @moveAndZoom.
  ///
  /// In en, this message translates to:
  /// **'Move & Zoom'**
  String get moveAndZoom;

  /// No description provided for @freestyle.
  ///
  /// In en, this message translates to:
  /// **'Freestyle'**
  String get freestyle;

  /// No description provided for @toggleFill.
  ///
  /// In en, this message translates to:
  /// **'Toggle fill'**
  String get toggleFill;

  /// No description provided for @changeOpacity.
  ///
  /// In en, this message translates to:
  /// **'Change opacity'**
  String get changeOpacity;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @blurTool.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get blurTool;

  /// No description provided for @emojiTool.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojiTool;

  /// No description provided for @filterTool.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTool;

  /// No description provided for @paintTool.
  ///
  /// In en, this message translates to:
  /// **'Paint'**
  String get paintTool;

  /// No description provided for @stickerTool.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get stickerTool;

  /// No description provided for @textTool.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textTool;

  /// No description provided for @tuneTool.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get tuneTool;

  /// No description provided for @revertEdits.
  ///
  /// In en, this message translates to:
  /// **'Revert edits'**
  String get revertEdits;

  /// No description provided for @editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit image'**
  String get editImage;

  /// No description provided for @navImageEditor.
  ///
  /// In en, this message translates to:
  /// **'Image Editor'**
  String get navImageEditor;

  /// No description provided for @saveToFile.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get saveToFile;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get imageSaved;

  /// No description provided for @selectImageToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select an image to edit'**
  String get selectImageToEdit;

  /// No description provided for @saveEditedImage.
  ///
  /// In en, this message translates to:
  /// **'Save edited image'**
  String get saveEditedImage;

  /// No description provided for @editAgain.
  ///
  /// In en, this message translates to:
  /// **'Edit again'**
  String get editAgain;

  /// No description provided for @openNewImage.
  ///
  /// In en, this message translates to:
  /// **'Open new image'**
  String get openNewImage;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved edits. What would you like to do?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Share message'**
  String get shareMessage;

  /// No description provided for @shareMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'Default message template for all providers. Overridden per-upload on the upload screen.'**
  String get shareMessageDescription;

  /// No description provided for @messageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Message template'**
  String get messageTemplate;

  /// No description provided for @messageTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Message template saved'**
  String get messageTemplateSaved;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @noChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChangesToSave;

  /// No description provided for @failedToLoadChannelsUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load channels/users'**
  String get failedToLoadChannelsUsers;

  /// No description provided for @failedToLoadGateways.
  ///
  /// In en, this message translates to:
  /// **'Failed to load gateways'**
  String get failedToLoadGateways;

  /// No description provided for @matterbridgeNotFullyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Matterbridge not fully configured'**
  String get matterbridgeNotFullyConfigured;

  /// No description provided for @sentToProvider.
  ///
  /// In en, this message translates to:
  /// **'Sent to {provider}'**
  String sentToProvider(Object provider);

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String operationFailed(Object error);
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
      <String>['en', 'eo', 'it', 'tlh', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'eo':
      return AppLocalizationsEo();
    case 'it':
      return AppLocalizationsIt();
    case 'tlh':
      return AppLocalizationsTlh();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
