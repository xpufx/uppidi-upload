// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Esperanto (`eo`).
class AppLocalizationsEo extends AppLocalizations {
  AppLocalizationsEo([String locale = 'eo']) : super(locale);

  @override
  String get appTitle => 'Uppidi Alŝutilo';

  @override
  String get genericError => 'Neatendita eraro okazis. Bonvolu reprovi.';

  @override
  String get errorSessionExpired =>
      'Via seanco eksvalidiĝis. Bonvolu kontroli viajn akreditaĵojn en Agordoj.';

  @override
  String get errorFileTooLarge =>
      'La dosiero estas tro granda por ĉi tiu provizanto.';

  @override
  String get errorInvalidUploader =>
      'Nevalida alŝutila agordo. Bonvolu kontroli viajn agordojn aŭ reprovi poste.';

  @override
  String get invalidMimeType => 'Nevalida aŭ nesubtenata dosiertipo.';

  @override
  String get fileSystemError => 'Ne eblis legi la elektitan dosieron.';

  @override
  String get errorConnectionFailed =>
      'Ne eblis konekti al la provizanto. Ĝi eble ne estas atingebla.';

  @override
  String get uploadCancelled => 'Alŝuto nuligita.';

  @override
  String get providerWebNotSupported =>
      'Ĉi tiu provizanto ne povas esti uzata rekte en retumilo. Ŝaltu la eksperimentan prokurilon en Agordoj.';

  @override
  String get selfSignedCertWarning =>
      'Malcerta konekto preterpasas atestilan validigon. Ŝaltu ĉi tion nur por fidindaj memgastigitaj serviloj.';

  @override
  String get upload => 'Alŝuti';

  @override
  String get uploading => 'Alŝutante...';

  @override
  String get uploadComplete => 'Alŝuto kompleta!';

  @override
  String get uploadFailed => 'Alŝuto malsukcesis';

  @override
  String get cancelUpload => 'Nuligi Alŝuton';

  @override
  String get pickAndUpload => 'Elekti kaj Alŝuti';

  @override
  String get urlCopiedToClipboard => 'URL kopiis al tondujo';

  @override
  String get shareUrl => 'Kunhavigi URL';

  @override
  String get selectProvider => 'Elekti Provizanton';

  @override
  String get settings => 'Agordoj';

  @override
  String get history => 'Historio';

  @override
  String get historyEmpty => 'Neniu alŝuta historio ankoraŭ';

  @override
  String get enableInsecure => 'Permesi malcertajn konektojn';

  @override
  String get proxyUrl => 'Prokura URL';

  @override
  String get navProviders => 'Provizantoj';

  @override
  String get providersSection => 'Provizantoj';

  @override
  String get historyClearAll => 'Forigi ĉion';

  @override
  String get historyClearConfirm => 'Ĉu forigi tutan historion?';

  @override
  String historyRecords(Object count) {
    return '$count registro(j)';
  }

  @override
  String get clearHistory => 'Forigi Historion';

  @override
  String get openInBrowser => 'Malfermi en retumilo';

  @override
  String get noProviders => 'Neniu provizanto agordita. Aldonu unu en Agordoj.';

  @override
  String disclaimer(Object provider) {
    return 'Vi estas alŝontonta al $provider. Ni ne estas filiataj kun tiu servo.';
  }

  @override
  String get success => 'Sukceso';

  @override
  String get themeCustomLogo => 'Propra Emblemo';

  @override
  String get themeDark => 'Malhela';

  @override
  String get themeLight => 'Hela';

  @override
  String get themeMode => 'Etoso';

  @override
  String get themeSeedColor => 'Akcenta Koloro';

  @override
  String get themeSystem => 'Sistemo';

  @override
  String get failed => 'Malsukcesis';

  @override
  String get error => 'Eraro';

  @override
  String get unknownError => 'Nekonata eraro';

  @override
  String get language => 'Lingvo';

  @override
  String get ok => 'Bone';

  @override
  String get cancel => 'Nuligi';

  @override
  String get apply => 'Apliki';

  @override
  String get timeJustNow => 'ĵus nun';

  @override
  String timeMinutesAgo(Object minutes) {
    return 'antaŭ $minutes min';
  }

  @override
  String timeHoursAgo(Object hours) {
    return 'antaŭ $hours h';
  }

  @override
  String get navTest => 'Testi';

  @override
  String get testAll => 'Testi Ĉiujn';

  @override
  String get testProvider => 'Testi';

  @override
  String get noProvidersAvailable => 'Neniu provizanto havebla';

  @override
  String get connectionFailed => 'Konekto malsukcesis';

  @override
  String get viewChangelog => 'Rigardi Ŝanĝoprotokolon';

  @override
  String get changelogTitle => 'Ŝanĝoprotokolo';

  @override
  String get changeLogo => 'Ŝanĝi Emblemon';

  @override
  String get chooseLogo => 'Elekti Emblemon';

  @override
  String providersCount(Object count) {
    return '$count provizanto(j)';
  }

  @override
  String get defaultForSharing => 'Defaŭlta por kunhavigo';

  @override
  String get lastUsed => 'Lasta uzo';

  @override
  String get proxyHint => 'socks5://gastigo:haveno';

  @override
  String get dropFileToUpload => 'Demetu dosieron por alŝuti';

  @override
  String get retry => 'Reprovi';

  @override
  String get chooseFile => 'Elekti Dosieron';

  @override
  String get deleteThisRecord => 'Ĉu forigi ĉi tiun registron?';

  @override
  String get shareLink => 'Kunhavigi Ligilon';

  @override
  String get includeMessage => 'Inkluzivi mesaĝon';

  @override
  String get templateVars => 'Ŝablonaj Variabloj';

  @override
  String get templateExamples => 'Ekzemploj:';

  @override
  String get customizeMessage => 'Personecigi:';

  @override
  String get debugLogging => 'Ŝalti sencimigan protokoladon';

  @override
  String get debugLoggingDescription =>
      'Registras plenajn HTTP pet/respond detalojn al la konzolo por sencimigo. Ŝaltu nur kiam bezonate.';

  @override
  String get qualityOriginal => 'Originala';

  @override
  String get qualityMedium => 'Duona';

  @override
  String get qualityLow => 'Kvarona';

  @override
  String get uiVariant => 'UI Varianto';

  @override
  String get uiVariantDescription =>
      'Elektu la ĉefekranan provizantan aranĝon: Listo aŭ Ĉipoj.';

  @override
  String get uiVariantDefault => 'Provizanta Listo';

  @override
  String get uiVariantCompact => 'Provizantaj Ĉipoj';

  @override
  String get iconLegendWarning => 'Averto';

  @override
  String get iconLegendExpiry => 'Eksvalidiĝo';

  @override
  String get iconLegendFileSize => 'Dosiergrandeco';

  @override
  String get iconLegendAcceptedFiles => 'Akceptitaj dosieroj';

  @override
  String get iconLegendDirectLinks => 'Rektaj ligiloj';

  @override
  String get iconLegendAccount => 'Konto bezonata';

  @override
  String get enabled => 'Ŝaltita';

  @override
  String get disabled => 'Malŝaltita';

  @override
  String get appDescription =>
      'Alŝutu dosierojn al pluraj senpagaj gastigaj servoj. Rapida, simpla, kaj subtenas multajn provizantojn.';

  @override
  String get providerInfoTitle => 'Provizanta Informo';

  @override
  String maxFileSize(Object size) {
    return 'Maksimuma dosiergrandeco: $size';
  }

  @override
  String acceptedFiles(Object types) {
    return 'Akceptitaj dosieroj: $types';
  }

  @override
  String expiryInfo(Object info) {
    return 'Dosieroj eksvalidiĝas: $info';
  }

  @override
  String get supportsDirectLinks => 'Subtenas rektajn ligilojn';

  @override
  String get requiresAccount => 'Bezonas konton';

  @override
  String get iconLegendTitle => 'Provizantaj Ikonoj';

  @override
  String get iconLegendTest => 'Testi';

  @override
  String get iconLegendFiles => 'Dosieroj';

  @override
  String get iconLegendLinks => 'Ligiloj';

  @override
  String get iconLegendImages => 'Bildoj';

  @override
  String get iconLegendOther => 'Alia';

  @override
  String get insecureWarningTitle => 'Malcerta Konekto';

  @override
  String insecureWarningHttp(Object providerName, Object url) {
    return 'La provizanto $providerName ĉe $url uzas malcertan HTTP-konekton. Viaj dosieroj estos senditaj klartekste.';
  }

  @override
  String insecureWarningHttps(Object providerName, Object url) {
    return 'La provizanto $providerName ĉe $url havas memsubskribitan aŭ nevalidan atestilon.';
  }

  @override
  String get viewCertificate => 'Rigardi Atestilon';

  @override
  String get certificateDialogTitle => 'Servila Atestilo';

  @override
  String get certSubject => 'Temo';

  @override
  String get certIssuer => 'Eldoninto';

  @override
  String get certValidFrom => 'Valida de';

  @override
  String get certValidUntil => 'Valida ĝis';

  @override
  String get certFingerprint => 'Spurprinto';

  @override
  String get proceedAnyway => 'Daŭrigi Ĉiuokaze';

  @override
  String get dontShowAgain => 'Ne montri denove por ĉi tiu provizanto';

  @override
  String get viewDebugLog => 'Rigardi sencimigan protokolon';

  @override
  String get navigationLeft => 'Maldekstre';

  @override
  String get navigationBottom => 'Sube';

  @override
  String get navigationRight => 'Dekstre';

  @override
  String get navLayout => 'Navigada Aranĝo';

  @override
  String get navLayoutDescription =>
      'Elektu navigadan pozicion: Maldekstre, Sube aŭ Dekstre.';

  @override
  String selectedExpiry(Object expiry) {
    return 'Eksvalidiĝas: $expiry';
  }

  @override
  String get deleteUrl => 'Foriga URL';

  @override
  String get openDeleteUrl => 'Malfermi forigan URL';

  @override
  String get deleteUrlCopied => 'Foriga URL kopiis al tondujo';

  @override
  String get copyDeleteUrl => 'Kopii forigan URL';

  @override
  String get failedToReadFile => 'Ne eblis legi la elektitan dosieron';

  @override
  String get noProvidersConfigured => 'Neniu alŝuta provizanto agordita';

  @override
  String get connectionTimedOut => 'Konekto tempis';

  @override
  String connectionFailedMsg(Object error) {
    return 'Konekto malsukcesis: $error';
  }

  @override
  String serverErrorMsg(Object code) {
    return 'Servila eraro: $code';
  }

  @override
  String uploadFailedMsg(Object reason) {
    return 'Alŝuto malsukcesis: $reason';
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
  String get clearSelection => 'Malplenigi elekton';

  @override
  String get expiry1Hour => '1 horo';

  @override
  String get expiry24Hours => '24 horoj';

  @override
  String get expiry3Days => '3 tagoj';

  @override
  String get resetCrop => 'Restarigi tondadon';

  @override
  String get debugInfo => 'Sencimiga Informo';

  @override
  String get debugInfoTooltip => 'Sencimiga informo';

  @override
  String get copyAll => 'Kopii Ĉion';

  @override
  String get share => 'Kunhavigi';

  @override
  String get copiedToClipboard => 'Kopiis al tondujo';

  @override
  String fileExceedsLimit(Object size) {
    return 'Dosiero superas la limon de $size';
  }

  @override
  String providerOnlyAccepts(Object types) {
    return 'Provizanto nur akceptas: $types';
  }

  @override
  String get systemInfo => 'Sistema Informo';

  @override
  String get info => 'Informo';

  @override
  String get license => 'Permesilo';

  @override
  String get gplNotice =>
      'Ĉi tiu projekto estas licencita sub la GNU General Public License v3.0.';

  @override
  String get gplUrl => 'https://www.gnu.org/licenses/gpl-3.0.txt';

  @override
  String get noLogEntries => 'Neniuj protokoleroj ankoraŭ.';

  @override
  String get copy => 'Kopii';

  @override
  String versionLabel(Object version) {
    return 'Uppidi Upload v$version';
  }

  @override
  String get shellLayoutTitle => 'Interfaca Aranĝo';

  @override
  String get shellLayoutDescription =>
      'Elektu kiel ekranoj estas organizitaj: \"Langetoj\" uzas langetan strion por navigado. \"Modala\" montras la alŝutan ekranon ĉiam kaj malfermas aliajn ekranojn kiel dialogojn.';

  @override
  String get tabs => 'Langetoj';

  @override
  String get modals => 'Modaloj';

  @override
  String get downloadAndroid => 'Elŝuti Android APK';

  @override
  String get downloadLinux => 'Elŝuti Linux';

  @override
  String get browseAllBuilds => 'Foliumi ĉiujn versiojn';

  @override
  String get viewReleases => 'Rigardi eldonojn en GitHub';

  @override
  String downloadingFile(Object label) {
    return 'Elŝutante $label';
  }

  @override
  String downloadedTo(Object path) {
    return 'Elŝutis al: $path';
  }

  @override
  String downloadFailed(Object error) {
    return 'Elŝuto malsukcesis: $error';
  }

  @override
  String get changelogNotAvailable => 'Ŝanĝoprotokolo ne havebla';

  @override
  String debugLogCopied(Object label) {
    return '$label — kopiis al tondujo';
  }

  @override
  String get devBuild => 'TESTA VERSIO';

  @override
  String versionPrefix(Object version) {
    return 'v$version';
  }

  @override
  String get providerConfigDescription =>
      'Enigu la necesajn akreditaĵojn por ĉi tiu provizanto.';

  @override
  String get providerConfigSecretHint =>
      'Ĉi tiu valoro estas stokita loke kaj neniam dividita.';

  @override
  String get providerConfigRequired => 'Ĉi tiu kampo estas deviga';

  @override
  String providerConfigSaved(Object provider) {
    return 'Agordo de $provider konservita!';
  }

  @override
  String get providerConfigSectionConfigured => 'Agordita';

  @override
  String providerConfigNotConfigured(Object provider) {
    return '$provider — ne agordita';
  }

  @override
  String get providerConfigure => 'Agordi';

  @override
  String get save => 'Konservi';

  @override
  String get telegramErrorChatNotFound =>
      'Babilejo ne trovita. Bonvolu kontroli vian Babilejan ID.';

  @override
  String get telegramErrorBotBlocked =>
      'La roboto estis blokita de la uzanto. Malbloku la roboton unue.';

  @override
  String get telegramErrorNoRights =>
      'Roboto ne rajtas sendi mesaĝojn en ĉi tiu babilejo.';

  @override
  String get telegramErrorInvalidToken =>
      'Nevalida robota ĵetono. Kontrolu vian Bot-Ĵetonon de BotFather.';

  @override
  String get telegramSentToChat => 'Sendita al Telegram-babilejo';

  @override
  String get expiryPersistent => 'Daŭra (ĝis la robotsimbolo estas revokita)';

  @override
  String get expiryIndefinite30d =>
      'Nedifinita (neaktiva >30d povas esti forigita)';

  @override
  String get expiryOneDayExtendable => '~1 tago (etendebla post re-alŝuto)';

  @override
  String get expiryOptions1h12h24h72h => '1h / 12h / 24h / 72h';

  @override
  String get expiry3Hours => '3 horoj';

  @override
  String get expiry7Days => '7 tagoj';

  @override
  String get mimeTypesImagesOnly => 'Nur bildoj';

  @override
  String get configLabelBotToken => 'Bot-Ĵetono';

  @override
  String get configLabelChatId => 'Babileja ID';

  @override
  String get configLabelSendAsPhoto => 'Sendi bildojn kiel fotoj';

  @override
  String get myProviders => 'Miaj Provizantoj';

  @override
  String get addProvider => 'Aldoni provizanton';

  @override
  String get noInstancesConfigured => 'Neniu ekzemplero agordita';

  @override
  String get deleteInstanceTitle => 'Ĉu forigi ekzempleron?';

  @override
  String deleteInstanceConfirm(Object name) {
    return 'Ĉu forigi \"$name\" kaj ĉiujn ĝiajn akreditaĵojn?';
  }

  @override
  String get delete => 'Forigi';

  @override
  String get fillRequiredFields => 'Plenigu la devigajn kampojn unue';

  @override
  String get debugResponse => 'Sensaliga respondo';

  @override
  String get done => 'Farita';

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
  String get currentlyUnavailable => 'Nuntempe ne havebla';

  @override
  String get cropImage => 'Tondi';

  @override
  String get builtInProviders => 'Enkonstruitaj';

  @override
  String get testStepReachable => 'Atingebla';

  @override
  String get testStepNotProvided => 'Ne provizita';

  @override
  String get testStepNotFound => 'Ne trovita';

  @override
  String get testStepInvalid => 'Nevalida';

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
  String get matterbridgeSend => 'Sendi per Matterbridge';

  @override
  String get matterbridgeNotConfigured => 'Matterbridge ne plene agordita';

  @override
  String matterbridgeSent(Object gateway) {
    return 'Sendita al $gateway';
  }

  @override
  String matterbridgeError(Object code) {
    return 'Matterbridge eraro: $code';
  }

  @override
  String matterbridgeFailed(Object error) {
    return 'Malsukcesis: $error';
  }

  @override
  String messageVariables(Object vars) {
    return 'Variabloj: $vars';
  }

  @override
  String get pasteFromClipboard => 'Alglui el tondujo';

  @override
  String get clipboardEmpty => 'Neniu bildo trovita en tondujo';

  @override
  String get exportImportTitle => 'Eksporti / Importi';

  @override
  String get exportImportDescription =>
      'Eksportu viajn provizantajn akreditaĵojn kaj aplikaĵajn agordojn al JSON-dosiero por sekurkopio aŭ transigo. Importo kunigas ĉiujn datumojn — ekzistantaj agordoj kaj provizanta agordo estos anstataŭigitaj.';

  @override
  String get exportConfigTitle => 'Eksporti agordon';

  @override
  String get exportConfigWarning =>
      'Ĉi tiu dosiero enhavos API-ŝlosilojn, ĵetonojn, pasvortojn kaj aplikaĵajn agordojn. Tenu ĝin sekura — iu ajn kun ĉi tiu dosiero povas aliri viajn kontojn.';

  @override
  String get importConfigTitle => 'Importi agordon';

  @override
  String get importConfigWarning =>
      'Ĉi tio ANSTATAŪIGOS ĉiujn nunajn provizantajn akreditaĵojn kaj agordojn per la datumoj de la importita dosiero. Ĉi tio ne povas esti malfarita.';

  @override
  String get exportAction => 'Eksporti';

  @override
  String get importAction => 'Importi';

  @override
  String exportedTo(Object path) {
    return 'Eksportita al: $path';
  }

  @override
  String get exportFailed => 'Eksporto malsukcesis';

  @override
  String get importFailed => 'Importo malsukcesis';

  @override
  String get apkDownloaded => 'APK elŝutita';

  @override
  String get installNow => 'Instali Nun';

  @override
  String get downloadComplete => 'Elŝuto kompleta';

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

  @override
  String get undo => 'Malfari';

  @override
  String get redo => 'Refari';

  @override
  String get remove => 'Forigi';

  @override
  String get rotate => 'Rotacii';

  @override
  String get flip => 'Respeguli';

  @override
  String get ratio => 'Proporcio';

  @override
  String get reset => 'Restarigi';

  @override
  String get search => 'Serĉi';

  @override
  String get none => 'Neniu';

  @override
  String get color => 'Koloro';

  @override
  String get opacity => 'Malmbrilo';

  @override
  String get fill => 'Plenigi';

  @override
  String get eraser => 'Viŝilo';

  @override
  String get lineWidth => 'Linilarĝo';

  @override
  String get strokeWidth => 'Streklarĝo';

  @override
  String get edit => 'Redakti';

  @override
  String get brightness => 'Heleco';

  @override
  String get contrast => 'Kontrasto';

  @override
  String get saturation => 'Satureco';

  @override
  String get exposure => 'Ekspono';

  @override
  String get hue => 'Nuanco';

  @override
  String get temperature => 'Temperaturo';

  @override
  String get sharpness => 'Akreco';

  @override
  String get fade => 'Forvelki';

  @override
  String get textAlign => 'Tekstordigo';

  @override
  String get fontScale => 'Tipara grando';

  @override
  String get backgroundMode => 'Fono';

  @override
  String get inputHintText => 'Enigu tekston...';

  @override
  String get closeEditorWarningTitle => 'Ĉu forigi ŝanĝojn?';

  @override
  String get closeEditorWarningMessage =>
      'Vi havas nekonservitajn ŝanĝojn. Ĉu vi certas, ke vi volas forigi ilin?';

  @override
  String get closeEditorWarningConfirmBtn => 'Forigi';

  @override
  String get arrow => 'Sago';

  @override
  String get line => 'Linio';

  @override
  String get rectangle => 'Ortangulo';

  @override
  String get circle => 'Rondo';

  @override
  String get moveAndZoom => 'Movi kaj Zomi';

  @override
  String get freestyle => 'Liberstila';

  @override
  String get toggleFill => 'Baskuligi plenigon';

  @override
  String get changeOpacity => 'Ŝanĝi malmbrilon';

  @override
  String get back => 'Reen';

  @override
  String get blurTool => 'Malklarigi';

  @override
  String get emojiTool => 'Emoĝio';

  @override
  String get filterTool => 'Filtrilo';

  @override
  String get paintTool => 'Pentri';

  @override
  String get stickerTool => 'Glumarkoj';

  @override
  String get textTool => 'Teksto';

  @override
  String get tuneTool => 'Agordi';

  @override
  String get revertEdits => 'Malfari redaktojn';

  @override
  String get editImage => 'Redakti bildon';

  @override
  String get navImageEditor => 'Bilda Redaktilo';

  @override
  String get saveToFile => 'Konservi al dosiero';

  @override
  String get imageSaved => 'Bildo konservita';

  @override
  String get selectImageToEdit => 'Elektu bildon por redakti';

  @override
  String get saveEditedImage => 'Konservi redaktitan bildon';

  @override
  String get editAgain => 'Redakti denove';

  @override
  String get openNewImage => 'Malfermi novan bildon';

  @override
  String get unsavedChangesTitle => 'Nekonservitaj ŝanĝoj';

  @override
  String get unsavedChangesMessage =>
      'Vi havas nekonservitajn redaktojn. Kion vi volas fari?';

  @override
  String get discard => 'Forĵeti';
}
