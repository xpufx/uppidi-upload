// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Klingon tlhIngan Hol (`tlh`).
class AppLocalizationsTlh extends AppLocalizations {
  AppLocalizationsTlh([String locale = 'tlh']) : super(locale);

  @override
  String get appTitle => 'Uppidi Upload';

  @override
  String get genericError => 'Qagh. DochDaq Qagh.';

  @override
  String get errorSessionExpired => 'tIqwIj vIl. pat Dacha\'.';

  @override
  String get errorFileTooLarge => 'Doch\'a\' law\'qu\'.';

  @override
  String get errorInvalidUploader => 'pat Qagh. Dacha\'.';

  @override
  String get invalidMimeType => 'Doch qab Qagh.';

  @override
  String get fileSystemError => 'Doch laDlaHbe\'.';

  @override
  String get errorConnectionFailed => 'Qapbe\' qara\'DI\'.';

  @override
  String get uploadCancelled => 'Ha\'ra\' QIt.';

  @override
  String get providerWebNotSupported => 'ngeDna\' yIlo\' patDaq.';

  @override
  String get selfSignedCertWarning => 'ra\'QoS Qagh. motlh yIlo\'.';

  @override
  String get upload => 'Ha\'ra\'';

  @override
  String get uploading => 'Ha\'ra\'taH...';

  @override
  String get uploadComplete => 'Ha\'ra\' Qapla\'!';

  @override
  String get uploadFailed => 'Ha\'ra\' Qagh';

  @override
  String get cancelUpload => 'Ha\'ra\' QIt';

  @override
  String get pickAndUpload => 'wIvbogh Ha\'ra\'';

  @override
  String get urlCopiedToClipboard => 'ra\'wI\' rur ghe\'tor';

  @override
  String get shareUrl => 'ra\'wI\' yIbej';

  @override
  String get selectProvider => 'ngeDna\' yIghoS';

  @override
  String get settings => 'pat';

  @override
  String get history => 'QonwI\'';

  @override
  String get historyEmpty => 'QonwI\' ghobe\'';

  @override
  String get enableInsecure => 'ra\'QoS chaw\'';

  @override
  String get proxyUrl => 'ra\'wI\' ray\'';

  @override
  String get navProviders => 'ngeDna\'';

  @override
  String get providersSection => 'QaHwI\'meywIj';

  @override
  String get historyClearAll => 'Hoch QIt';

  @override
  String get historyClearConfirm => 'Hoch QonwI\' QIt?';

  @override
  String historyRecords(Object count) {
    return '$count QonwI\'';
  }

  @override
  String get clearHistory => 'QonwI\' QIt';

  @override
  String get openInBrowser => 'nIvbogh yIpoQ';

  @override
  String get noProviders => 'ngeDna\' ghobe\'. patDaq yI\'aq.';

  @override
  String disclaimer(Object provider) {
    return 'Doch Daha\' $provider Dung. maH ghobe\'.';
  }

  @override
  String get success => 'Qapla\'';

  @override
  String get themeCustomLogo => 'loDnal';

  @override
  String get themeDark => 'qIj';

  @override
  String get themeLight => 'wov';

  @override
  String get themeMode => 'qab';

  @override
  String get themeSeedColor => 'qab lang';

  @override
  String get themeSystem => 'QaQ';

  @override
  String get failed => 'Qagh';

  @override
  String get error => 'Qagh';

  @override
  String get unknownError => 'Qagh Sovbe\'';

  @override
  String get language => 'Hol';

  @override
  String get ok => 'HISlaH';

  @override
  String get cancel => 'QIt';

  @override
  String get apply => 'choH';

  @override
  String get timeJustNow => 'DaH';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes tup ret';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours rep ret';
  }

  @override
  String get navTest => 'nIv';

  @override
  String get testAll => 'Hoch nIv';

  @override
  String get testProvider => 'nIv';

  @override
  String get noProvidersAvailable => 'ngeDna\' ghobe\'';

  @override
  String get connectionFailed => 'Qapbe\' qara\'DI\'';

  @override
  String get viewChangelog => 'choH QonwI\' yIleS';

  @override
  String get changelogTitle => 'choH QonwI\'';

  @override
  String get changeLogo => 'loDnal choH';

  @override
  String get chooseLogo => 'loDnal yIghoS';

  @override
  String providersCount(Object count) {
    return '$count ngeDna\'';
  }

  @override
  String get defaultForSharing => 'bejmeH Doch';

  @override
  String get lastUsed => 'pIq lo\'lu\'';

  @override
  String get proxyHint => 'socks5://raS:QIr';

  @override
  String get dropFileToUpload => 'Doch yI\'ura\' Ha\'ra\'meH';

  @override
  String get retry => 'qa\'vI\'';

  @override
  String get chooseFile => 'Doch yIghoS';

  @override
  String get deleteThisRecord => 'QonwI\' QIt?';

  @override
  String get shareLink => 'ra\'wI\' yIbej';

  @override
  String get includeMessage => 'jatlh yI\'ang';

  @override
  String get templateVars => 'choHmey';

  @override
  String get templateExamples => 'ghojmey:';

  @override
  String get customizeMessage => 'choH:';

  @override
  String get debugLogging => 'Qagh log chaw\'';

  @override
  String get debugLoggingDescription =>
      'Hoch HTTP Qapla\' logDaq yIqIH. neH poQpa\' yIlo\'.';

  @override
  String get qualityOriginal => 'QonoS';

  @override
  String get qualityMedium => 'buQ';

  @override
  String get qualityLow => 'mach';

  @override
  String get uiVariant => 'qab choH';

  @override
  String get uiVariantDescription => 'ngeDna\' qab yIghoS: tet or chip.';

  @override
  String get uiVariantDefault => 'ngeDna\' tet';

  @override
  String get uiVariantCompact => 'ngeDna\' chip';

  @override
  String get iconLegendWarning => 'yIqIm';

  @override
  String get iconLegendExpiry => 'jaj pIH';

  @override
  String get iconLegendFileSize => 'Doch tIn';

  @override
  String get iconLegendAcceptedFiles => 'Doch chaw\'lu\'';

  @override
  String get iconLegendDirectLinks => 'ra\'wI\' QaQ';

  @override
  String get iconLegendAccount => 'pat neH';

  @override
  String get enabled => 'chaw\'lu\'';

  @override
  String get disabled => 'chaw\'be\'';

  @override
  String get appDescription =>
      'Dochmey Ha\'ra\' law\' ngeDna\' Dung. QIt, QaQ, law\' ngeDna\'.';

  @override
  String get providerInfoTitle => 'ngeDna\' QonoS';

  @override
  String maxFileSize(Object size) {
    return 'Doch\'a\' tIn law\': $size';
  }

  @override
  String acceptedFiles(Object types) {
    return 'Doch chaw\'lu\': $types';
  }

  @override
  String expiryInfo(Object info) {
    return 'Doch pIH: $info';
  }

  @override
  String get supportsDirectLinks => 'ra\'wI\' QaQ chaw\'';

  @override
  String get requiresAccount => 'pat neH';

  @override
  String get iconLegendTitle => 'ngeDna\' nagh';

  @override
  String get iconLegendTest => 'nIv';

  @override
  String get iconLegendFiles => 'Dochmey';

  @override
  String get iconLegendLinks => 'ra\'wI\'mey';

  @override
  String get iconLegendImages => 'qabmey';

  @override
  String get iconLegendOther => 'latlh';

  @override
  String get insecureWarningTitle => 'ra\'QoS Qapbe\'';

  @override
  String insecureWarningHttp(Object providerName, Object url) {
    return 'ngeDna\' $providerName ${url}Daq ra\'QoS HTTP lulo\'. Dochmey lulo\' QIt.';
  }

  @override
  String insecureWarningHttps(Object providerName, Object url) {
    return 'ngeDna\' $providerName ${url}Daq ra\'QoS Qagh. Qapbe\'.';
  }

  @override
  String get viewCertificate => 'ra\'QoS yIleS';

  @override
  String get certificateDialogTitle => 'raS ra\'QoS';

  @override
  String get certSubject => 'pong';

  @override
  String get certIssuer => 'nIv';

  @override
  String get certValidFrom => 'poH tagh';

  @override
  String get certValidUntil => 'poH QIt';

  @override
  String get certFingerprint => 'nagh';

  @override
  String get proceedAnyway => 'qa\'vI\'';

  @override
  String get dontShowAgain => 'ngeDna\'vaD qa\'vI\' yIchaw\'be\'';

  @override
  String get viewDebugLog => 'Qagh log yIleS';

  @override
  String get navigationLeft => 'poS';

  @override
  String get navigationBottom => 'bIng';

  @override
  String get navigationRight => 'nIH';

  @override
  String get navLayout => 'tet qab';

  @override
  String get navLayoutDescription => 'tet qab yIghoS: poS, bIng, pagh nIH.';

  @override
  String selectedExpiry(Object expiry) {
    return 'pIH: $expiry';
  }

  @override
  String get deleteUrl => 'QIt ra\'wI\'';

  @override
  String get openDeleteUrl => 'QIt ra\'wI\' yIpoQ';

  @override
  String get deleteUrlCopied => 'QIt ra\'wI\' rur ghe\'tor';

  @override
  String get copyDeleteUrl => 'QIt ra\'wI\' yIrur';

  @override
  String get failedToReadFile => 'Doch laDlaHbe\'';

  @override
  String get noProvidersConfigured => 'ngeDna\' pat ghobe\'';

  @override
  String get connectionTimedOut => 'qara\'DI\' poH QIt';

  @override
  String connectionFailedMsg(Object error) {
    return 'Qapbe\' qara\'DI\': $error';
  }

  @override
  String serverErrorMsg(Object code) {
    return 'raS Qagh: $code';
  }

  @override
  String uploadFailedMsg(Object reason) {
    return 'Ha\'ra\' Qagh: $reason';
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
  String get clearSelection => 'ghoS QIt';

  @override
  String get expiry1Hour => '1 rep';

  @override
  String get expiry24Hours => '24 rep';

  @override
  String get expiry3Days => '3 jaj';

  @override
  String get resetCrop => 'ghot QIt';

  @override
  String get debugInfo => 'Qagh QonoS';

  @override
  String get debugInfoTooltip => 'Qagh QonoS';

  @override
  String get copyAll => 'Hoch rur';

  @override
  String get share => 'bej';

  @override
  String get copiedToClipboard => 'rur ghe\'tor';

  @override
  String fileExceedsLimit(Object size) {
    return 'Doch $size law\'qu\'';
  }

  @override
  String providerOnlyAccepts(Object types) {
    return 'ngeDna\' chaw\': $types';
  }

  @override
  String get systemInfo => 'raS QonoS';

  @override
  String get info => 'QonoS';

  @override
  String get license => 'pat chaw\'';

  @override
  String get gplNotice =>
      'GNU General Public License v3.0 pat chaw\'Daq Dochvam.';

  @override
  String get gplUrl => 'https://www.gnu.org/licenses/gpl-3.0.txt';

  @override
  String get noLogEntries => 'log ghobe\'';

  @override
  String get copy => 'rur';

  @override
  String versionLabel(Object version) {
    return 'Uppidi Upload v$version';
  }

  @override
  String get shellLayoutTitle => 'qab tet';

  @override
  String get shellLayoutDescription =>
      'qab tet yIghoS: \"Tabs\" tet bar lulo\'. \"Modals\" Ha\'ra\' qab reH lulo\' latlh qabmey Dialog lulo\'.';

  @override
  String get tabs => 'tetmey';

  @override
  String get modals => 'modal';

  @override
  String get downloadAndroid => 'Android APK yItlhutlh';

  @override
  String get downloadLinux => 'Linux yItlhutlh';

  @override
  String get browseAllBuilds => 'Hoch build yIleS';

  @override
  String get viewReleases => 'GitHub Dan yIleS';

  @override
  String downloadingFile(Object label) {
    return '$label yItlhutlhtaH';
  }

  @override
  String downloadedTo(Object path) {
    return '${path}Daq yItlhutlh';
  }

  @override
  String downloadFailed(Object error) {
    return 'yItlhutlh Qagh: $error';
  }

  @override
  String get changelogNotAvailable => 'choH QonwI\' ghobe\'';

  @override
  String debugLogCopied(Object label) {
    return '$label — rur ghe\'tor';
  }

  @override
  String get devBuild => 'DEV BUILD';

  @override
  String versionPrefix(Object version) {
    return 'v$version';
  }

  @override
  String get providerConfigDescription => 'ngeDna\'vaD pat yIchenmoH.';

  @override
  String get providerConfigSecretHint =>
      'Dochvam \'ay\'Daq yIqel. latlhvaD yIbejQo\'.';

  @override
  String get providerConfigRequired => 'QochDaq Doch yIqel';

  @override
  String providerConfigSaved(Object provider) {
    return '$provider pat chenmoHlu\'!';
  }

  @override
  String get providerConfigSectionConfigured => 'chenmoHlu\'';

  @override
  String providerConfigNotConfigured(Object provider) {
    return '$provider — pat ghobe\'';
  }

  @override
  String get providerConfigure => 'chenmoH';

  @override
  String get save => 'yIqel';

  @override
  String get telegramErrorChatNotFound => 'chat ghobe\'. Chat ID yIghoS.';

  @override
  String get telegramErrorBotBlocked => 'bot loD qIp. bot yIqIt Ha\'.';

  @override
  String get telegramErrorNoRights => 'bot chatDaq mIw chaw\'be\'.';

  @override
  String get telegramErrorInvalidToken =>
      'bot token Qagh. BotFatherDaq Bot Token yIghoS.';

  @override
  String get telegramSentToChat => 'Telegram chatDaq nge\'';

  @override
  String get expiryPersistent => 'bot token QItpu\'ba\' rur';

  @override
  String get expiryIndefinite30d => 'poH QItbe\' (30h jaj QItlaH)';

  @override
  String get expiryOneDayExtendable => '~1 jaj (qa\'Ha\'ra\'laH)';

  @override
  String get expiryOptions1h12h24h72h => '1h / 12h / 24h / 72h';

  @override
  String get expiry3Hours => '3 rep';

  @override
  String get expiry7Days => '7 jaj';

  @override
  String get mimeTypesImagesOnly => 'qabmey neH';

  @override
  String get configLabelBotToken => 'bot token';

  @override
  String get configLabelChatId => 'chat ID';

  @override
  String get configLabelSendAsPhoto => 'qabmey FotoDaq';

  @override
  String get myProviders => 'QaHwI\'meywIj';

  @override
  String get addProvider => 'QaHwI\' lan';

  @override
  String get noInstancesConfigured => 'pagh rap ta\'';

  @override
  String get deleteInstanceTitle => 'rap Qaw\'?';

  @override
  String deleteInstanceConfirm(Object name) {
    return '\"$name\" rap je Qaw\'?';
  }

  @override
  String get delete => 'Qaw\'';

  @override
  String get fillRequiredFields => 'Dochmey rur qaSpay\'';

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
  String get reloadZulipResources => 'Manage channels & users';
}
