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
  String get errorInvalidUploader =>
      'Invalid uploader configuration. Please check your settings or try again later.';

  @override
  String get invalidMimeType => 'Invalid or unsupported file type.';

  @override
  String get fileSystemError => 'Could not read the selected file.';

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
  String get enableInsecure => 'Allow insecure connections';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get navProviders => 'Providers';

  @override
  String get providersSection => 'My Providers';

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
  String get language => 'Language';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

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

  @override
  String get shareLink => 'Share Link';

  @override
  String get includeMessage => 'Include message';

  @override
  String get templateVars => 'Template Variables';

  @override
  String get templateExamples => 'Examples:';

  @override
  String get customizeMessage => 'Customize:';

  @override
  String get debugLogging => 'Enable debug logging';

  @override
  String get debugLoggingDescription =>
      'Logs full HTTP request/response details to the console for troubleshooting. Only enable when needed.';

  @override
  String get qualityOriginal => 'Original';

  @override
  String get qualityMedium => 'Half size';

  @override
  String get qualityLow => 'Quarter size';

  @override
  String get uiVariant => 'UI Variant';

  @override
  String get uiVariantDescription =>
      'Choose the main screen provider layout: List or Chips.';

  @override
  String get uiVariantDefault => 'Provider List';

  @override
  String get uiVariantCompact => 'Provider Chips';

  @override
  String get iconLegendWarning => 'Warning';

  @override
  String get iconLegendExpiry => 'Expiry days';

  @override
  String get iconLegendFileSize => 'File size';

  @override
  String get iconLegendAcceptedFiles => 'Accepted files';

  @override
  String get iconLegendDirectLinks => 'Direct links';

  @override
  String get iconLegendAccount => 'Account required';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get appDescription =>
      'Upload files to multiple free hosting services. Fast, simple, and supports many providers.';

  @override
  String get providerInfoTitle => 'Provider Info';

  @override
  String maxFileSize(Object size) {
    return 'Max file size: $size';
  }

  @override
  String acceptedFiles(Object types) {
    return 'Accepted files: $types';
  }

  @override
  String expiryInfo(Object info) {
    return 'Files expire: $info';
  }

  @override
  String get supportsDirectLinks => 'Supports direct links';

  @override
  String get requiresAccount => 'Requires account';

  @override
  String get iconLegendTitle => 'Provider Icons';

  @override
  String get iconLegendTest => 'Test';

  @override
  String get iconLegendFiles => 'Files';

  @override
  String get iconLegendLinks => 'Links';

  @override
  String get iconLegendImages => 'Images';

  @override
  String get iconLegendOther => 'Other';

  @override
  String get insecureWarningTitle => 'Insecure Connection';

  @override
  String insecureWarningHttp(Object providerName, Object url) {
    return 'The provider $providerName at $url uses an insecure HTTP connection. Your files and authentication data will be sent in plain text.';
  }

  @override
  String insecureWarningHttps(Object providerName, Object url) {
    return 'The provider $providerName at $url has a self-signed or invalid certificate. The connection may not be secure.';
  }

  @override
  String get viewCertificate => 'View Certificate';

  @override
  String get certificateDialogTitle => 'Server Certificate';

  @override
  String get certSubject => 'Subject';

  @override
  String get certIssuer => 'Issuer';

  @override
  String get certValidFrom => 'Valid from';

  @override
  String get certValidUntil => 'Valid until';

  @override
  String get certFingerprint => 'Fingerprint';

  @override
  String get proceedAnyway => 'Proceed Anyway';

  @override
  String get dontShowAgain => 'Don\'t show again for this provider';

  @override
  String get viewDebugLog => 'View debug log';

  @override
  String get navigationLeft => 'Left';

  @override
  String get navigationBottom => 'Bottom';

  @override
  String get navigationRight => 'Right';

  @override
  String get navLayout => 'Nav Layout';

  @override
  String get navLayoutDescription =>
      'Choose navigation position: Left, Bottom, or Right.';

  @override
  String selectedExpiry(Object expiry) {
    return 'Expires in: $expiry';
  }

  @override
  String get deleteUrl => 'Delete URL';

  @override
  String get openDeleteUrl => 'Open delete URL';

  @override
  String get deleteUrlCopied => 'Delete URL copied to clipboard';

  @override
  String get copyDeleteUrl => 'Copy delete URL';

  @override
  String get failedToReadFile => 'Failed to read selected file';

  @override
  String get noProvidersConfigured => 'No upload providers configured';

  @override
  String get connectionTimedOut => 'Connection timed out';

  @override
  String connectionFailedMsg(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String serverErrorMsg(Object code) {
    return 'Server error: $code';
  }

  @override
  String uploadFailedMsg(Object reason) {
    return 'Upload failed: $reason';
  }

  @override
  String speedBS(Object speed) {
    return '$speed B/s';
  }

  @override
  String speedKBS(Object speed) {
    return '$speed KB/s';
  }

  @override
  String speedMBS(Object speed) {
    return '$speed MB/s';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get expiry1Hour => '1 hour';

  @override
  String get expiry24Hours => '24 hours';

  @override
  String get expiry3Days => '3 days';

  @override
  String get resetCrop => 'Reset crop';

  @override
  String get debugInfo => 'Debug Info';

  @override
  String get debugInfoTooltip => 'Debug info';

  @override
  String get copyAll => 'Copy All';

  @override
  String get share => 'Share';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String fileExceedsLimit(Object size) {
    return 'File exceeds $size limit';
  }

  @override
  String providerOnlyAccepts(Object types) {
    return 'Provider only accepts: $types';
  }

  @override
  String get systemInfo => 'System Info';

  @override
  String get info => 'Info';

  @override
  String get license => 'License';

  @override
  String get gplNotice =>
      'This project is licensed under the GNU General Public License v3.0.';

  @override
  String get gplUrl => 'https://www.gnu.org/licenses/gpl-3.0.txt';

  @override
  String get noLogEntries => 'No log entries yet.';

  @override
  String get copy => 'Copy';

  @override
  String versionLabel(Object version) {
    return 'Uppidi Upload v$version';
  }

  @override
  String get shellLayoutTitle => 'Shell Layout';

  @override
  String get shellLayoutDescription =>
      'Choose how screens are organized: \"Tabs\" uses a tab bar for navigation. \"Modals\" shows the upload screen always and opens other screens as dialogs.';

  @override
  String get tabs => 'Tabs';

  @override
  String get modals => 'Modals';

  @override
  String get downloadAndroid => 'Download Android APK';

  @override
  String get downloadLinux => 'Download Linux';

  @override
  String get browseAllBuilds => 'Browse all builds';

  @override
  String get viewReleases => 'View releases on GitHub';

  @override
  String downloadingFile(Object label) {
    return 'Downloading $label';
  }

  @override
  String downloadedTo(Object path) {
    return 'Downloaded to: $path';
  }

  @override
  String downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get changelogNotAvailable => 'Changelog not available';

  @override
  String debugLogCopied(Object label) {
    return '$label — copied to clipboard';
  }

  @override
  String get devBuild => 'DEV BUILD';

  @override
  String versionPrefix(Object version) {
    return 'v$version';
  }

  @override
  String get providerConfigDescription =>
      'Enter the credentials required by this provider.';

  @override
  String get providerConfigSecretHint =>
      'This value is stored locally and never shared.';

  @override
  String get providerConfigRequired => 'This field is required';

  @override
  String providerConfigSaved(Object provider) {
    return '$provider configuration saved!';
  }

  @override
  String get providerConfigSectionConfigured => 'Configured';

  @override
  String providerConfigNotConfigured(Object provider) {
    return '$provider — not configured';
  }

  @override
  String get providerConfigure => 'Configure';

  @override
  String get save => 'Save';

  @override
  String get telegramErrorChatNotFound =>
      'Chat not found. Please check your Chat ID.';

  @override
  String get telegramErrorBotBlocked =>
      'Bot was blocked by the user. Unblock the bot first.';

  @override
  String get telegramErrorNoRights =>
      'Bot lacks rights to send messages in this chat.';

  @override
  String get telegramErrorInvalidToken =>
      'Invalid bot token. Check your Bot Token from BotFather.';

  @override
  String get telegramSentToChat => 'Sent to Telegram chat';

  @override
  String get expiryPersistent => 'Persistent (until bot token is revoked)';

  @override
  String get expiryIndefinite30d => 'Indefinite (inactive >30d may delete)';

  @override
  String get expiryOneDayExtendable => '~1 day (extendable on re-upload)';

  @override
  String get expiryOptions1h12h24h72h => '1h / 12h / 24h / 72h';

  @override
  String get expiry3Hours => '3 hours';

  @override
  String get expiry7Days => '7 days';

  @override
  String get mimeTypesImagesOnly => 'Images only';

  @override
  String get configLabelBotToken => 'Bot Token';

  @override
  String get configLabelChatId => 'Chat ID';

  @override
  String get configLabelSendAsPhoto => 'Send images as photos';

  @override
  String get myProviders => 'My Providers';

  @override
  String get addProvider => 'Add provider';

  @override
  String get noInstancesConfigured => 'No instances configured';

  @override
  String get deleteInstanceTitle => 'Delete instance?';

  @override
  String deleteInstanceConfirm(Object name) {
    return 'Delete \"$name\" and all its credentials?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get fillRequiredFields => 'Fill in required fields first';

  @override
  String get debugResponse => 'Debug response';

  @override
  String get done => 'Done';

  @override
  String get configLabelServerUrl => 'Server URL';

  @override
  String get configLabelEmail => 'Email';

  @override
  String get configLabelApiKey => 'API Key';

  @override
  String get configLabelInstanceName => 'Name';

  @override
  String get configInstanceNameHelper => 'A label to identify this instance';

  @override
  String get currentlyUnavailable => 'Currently unavailable';

  @override
  String get cropImage => 'Crop';

  @override
  String get builtInProviders => 'Built-in';

  @override
  String get testStepReachable => 'Reachable';

  @override
  String get testStepNotProvided => 'Not provided';

  @override
  String get testStepNotFound => 'Not found';

  @override
  String get testStepInvalid => 'Invalid';

  @override
  String connectedAs(Object username) {
    return 'Connected as @$username';
  }

  @override
  String chatAccessible(Object title) {
    return 'Chat \"$title\" accessible';
  }

  @override
  String get configLabelChannel => 'Channel';

  @override
  String get configLabelTopic => 'Topic';

  @override
  String get configLabelDirectMessage => 'Direct message';

  @override
  String get matterbridgeSend => 'Send via Matterbridge';

  @override
  String get matterbridgeNotConfigured => 'Matterbridge not fully configured';

  @override
  String matterbridgeSent(Object gateway) {
    return 'Sent to $gateway';
  }

  @override
  String matterbridgeError(Object code) {
    return 'Matterbridge error: $code';
  }

  @override
  String matterbridgeFailed(Object error) {
    return 'Failed: $error';
  }

  @override
  String messageVariables(Object vars) {
    return 'Variables: $vars';
  }

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get clipboardEmpty => 'No image found in clipboard';

  @override
  String get exportImportTitle => 'Export / Import';

  @override
  String get exportImportDescription =>
      'Export your provider credentials and app settings to a JSON file for backup or transfer. Import merges all data — existing settings and provider config will be replaced.';

  @override
  String get exportConfigTitle => 'Export config';

  @override
  String get exportConfigWarning =>
      'This file will contain API keys, tokens, passwords, and app settings. Keep it safe — anyone with this file can access your accounts.';

  @override
  String get importConfigTitle => 'Import config';

  @override
  String get importConfigWarning =>
      'This will REPLACE all current provider credentials and settings with the data from the imported file. This cannot be undone.';

  @override
  String get exportAction => 'Export';

  @override
  String get importAction => 'Import';

  @override
  String exportedTo(Object path) {
    return 'Exported to: $path';
  }

  @override
  String get exportFailed => 'Export failed';

  @override
  String get importFailed => 'Import failed';

  @override
  String get apkDownloaded => 'APK downloaded';

  @override
  String get installNow => 'Install Now';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String secondsAgo(Object seconds) {
    return '${seconds}s ago';
  }

  @override
  String minutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String get reloadZulipResources => 'Load channels & users';
}
