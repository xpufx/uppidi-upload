// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Uppidi Upload';

  @override
  String get genericError => 'An unexpected error occurred. Please try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please check your credentials in Settings.';

  @override
  String get errorFileTooLarge => 'The file is too large for this provider.';

  @override
  String get errorConnectionFailed =>
      'Could not connect to the provider. It may be unreachable or blocked by your browser.';

  @override
  String get uploadCancelled => 'Upload cancelled.';

  @override
  String get providerWebNotSupported =>
      'This provider cannot be used directly in a web browser. Enable the experimental proxy in settings.';

  @override
  String get selfSignedCertWarning =>
      'Insecure connection mode bypasses certificate validation. Only enable this for trusted self-hosted servers.';

  @override
  String get upload => 'Upload';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadComplete => 'Upload complete!';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get cancelUpload => 'Cancel Upload';

  @override
  String get pickAndUpload => 'Pick & Upload';

  @override
  String get urlCopiedToClipboard => 'URL copied to clipboard';

  @override
  String get shareUrl => 'Share URL';

  @override
  String get selectProvider => 'Select Provider';

  @override
  String get settings => 'Settings';

  @override
  String get history => 'History';

  @override
  String get historyEmpty => 'No upload history yet';

  @override
  String get enableInsecure =>
      'Allow insecure connections (self-signed certificates)';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get providersSection => 'Provider Configuration';

  @override
  String get historyClearAll => 'Clear all';

  @override
  String get historyClearConfirm => 'Delete all history?';

  @override
  String historyRecords(Object count) {
    return '$count records';
  }

  @override
  String get clearHistory => 'Clear History';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get noProviders => 'No providers configured. Add one in Settings.';

  @override
  String disclaimer(Object provider) {
    return 'You are about to upload to $provider. We are not affiliated with that service.';
  }

  @override
  String get success => 'Success';

  @override
  String get themeCustomLogo => 'Custom Logo';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSeedColor => 'Accent Color';

  @override
  String get themeSystem => 'System';

  @override
  String get failed => 'Failed';

  @override
  String get error => 'Error';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String get navTest => 'Test';

  @override
  String get testAll => 'Test All';

  @override
  String get testProvider => 'Test';

  @override
  String get noProvidersAvailable => 'No providers available';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get viewChangelog => 'View Changelog';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get changeLogo => 'Change Logo';

  @override
  String get chooseLogo => 'Choose Logo';

  @override
  String providersCount(Object count) {
    return '$count providers';
  }

  @override
  String get defaultForSharing => 'Default for sharing';

  @override
  String get lastUsed => 'Last used';

  @override
  String get proxyHint => 'socks5://host:port';

  @override
  String get dropFileToUpload => 'Drop file to upload';

  @override
  String get retry => 'Retry';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get deleteThisRecord => 'Delete this record?';
}
