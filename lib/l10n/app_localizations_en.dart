// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'uppidi';

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
  String get noProviders => 'No providers configured. Add one in Settings.';

  @override
  String disclaimer(Object provider) {
    return 'You are about to upload to $provider. We are not affiliated with that service.';
  }

  @override
  String get success => 'Success';

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
  String timeMinutesAgo(Object minutes) => '$minutes' 'm ago';

  @override
  String timeHoursAgo(Object hours) => '$hours' 'h ago';
}
