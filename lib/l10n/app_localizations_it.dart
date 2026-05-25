// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Uppidi Upload';

  @override
  String get genericError => 'Si è verificato un errore imprevisto. Riprova.';

  @override
  String get errorSessionExpired =>
      'La sessione è scaduta. Controlla le credenziali nelle Impostazioni.';

  @override
  String get errorFileTooLarge =>
      'Il file è troppo grande per questo servizio.';

  @override
  String get errorInvalidUploader =>
      'Configurazione uploader non valida. Controlla le impostazioni o riprova più tardi.';

  @override
  String get invalidMimeType => 'Tipo di file non valido o non supportato.';

  @override
  String get fileSystemError => 'Impossibile leggere il file selezionato.';

  @override
  String get errorConnectionFailed =>
      'Impossibile connettersi al servizio. Potrebbe essere irraggiungibile o bloccato dal browser.';

  @override
  String get uploadCancelled => 'Caricamento annullato.';

  @override
  String get providerWebNotSupported =>
      'Questo servizio non può essere usato direttamente dal browser. Attiva il proxy sperimentale nelle Impostazioni.';

  @override
  String get selfSignedCertWarning =>
      'La connessione insicura bypassa la validazione del certificato. Attivala solo per server fidati.';

  @override
  String get upload => 'Carica';

  @override
  String get uploading => 'Caricamento in corso...';

  @override
  String get uploadComplete => 'Caricamento completato!';

  @override
  String get uploadFailed => 'Caricamento fallito';

  @override
  String get cancelUpload => 'Annulla Caricamento';

  @override
  String get pickAndUpload => 'Scegli & Carica';

  @override
  String get urlCopiedToClipboard => 'URL copiato negli appunti';

  @override
  String get shareUrl => 'Condividi URL';

  @override
  String get selectProvider => 'Seleziona Servizio';

  @override
  String get settings => 'Impostazioni';

  @override
  String get history => 'Cronologia';

  @override
  String get historyEmpty => 'Nessun caricamento precedente';

  @override
  String get enableInsecure => 'Consenti connessioni insicure';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get navProviders => 'Provider';

  @override
  String get providersSection => 'I Miei Provider';

  @override
  String get historyClearAll => 'Cancella tutto';

  @override
  String get historyClearConfirm => 'Eliminare toda la cronologia?';

  @override
  String historyRecords(Object count) {
    return '$count record';
  }

  @override
  String get clearHistory => 'Cancella Cronologia';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get noProviders =>
      'Nessun servizio configurato. Aggiungine uno nelle Impostazioni.';

  @override
  String disclaimer(Object provider) {
    return 'Stai per caricare su $provider. Non siamo affiliati a questo servizio.';
  }

  @override
  String get success => 'Completato';

  @override
  String get themeCustomLogo => 'Logo Personalizzato';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSeedColor => 'Colore Accento';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get failed => 'Fallito';

  @override
  String get error => 'Errore';

  @override
  String get unknownError => 'Errore sconosciuto';

  @override
  String get language => 'Lingua';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annulla';

  @override
  String get apply => 'Applica';

  @override
  String get timeJustNow => 'proprio ora';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes min fa';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours h fa';
  }

  @override
  String get navTest => 'Test';

  @override
  String get testAll => 'Testa Tutti';

  @override
  String get testProvider => 'Testa';

  @override
  String get noProvidersAvailable => 'Nessun provider';

  @override
  String get connectionFailed => 'Connessione fallita';

  @override
  String get viewChangelog => 'Vedi Changelog';

  @override
  String get changelogTitle => 'Changelog';

  @override
  String get changeLogo => 'Cambia Logo';

  @override
  String get chooseLogo => 'Scegli Logo';

  @override
  String providersCount(Object count) {
    return '$count provider';
  }

  @override
  String get defaultForSharing => 'Predefinito per condivisione';

  @override
  String get lastUsed => 'Ultimo usato';

  @override
  String get proxyHint => 'socks5://host:porta';

  @override
  String get dropFileToUpload => 'Trascina file per caricare';

  @override
  String get retry => 'Riprova';

  @override
  String get chooseFile => 'Scegli File';

  @override
  String get deleteThisRecord => 'Eliminare questo record?';

  @override
  String get shareLink => 'Condividi Link';

  @override
  String get includeMessage => 'Includi messaggio';

  @override
  String get templateVars => 'Variabili Template';

  @override
  String get templateExamples => 'Esempi:';

  @override
  String get customizeMessage => 'Personalizza:';

  @override
  String get debugLogging => 'Abilita debug logging';

  @override
  String get debugLoggingDescription =>
      'Registra tutti i dettagli di richiesta/risposta HTTP nella console per il debug. Attivalo solo se necessario.';

  @override
  String get qualityOriginal => 'Originale';

  @override
  String get qualityMedium => 'Metà';

  @override
  String get qualityLow => 'Un quarto';

  @override
  String get uiVariant => 'Variante UI';

  @override
  String get uiVariantDescription =>
      'Scegli il layout dei provider nella schermata principale: Lista o Chip.';

  @override
  String get uiVariantDefault => 'Lista Provider';

  @override
  String get uiVariantCompact => 'Chip Provider';

  @override
  String get iconLegendWarning => 'Avvertenza';

  @override
  String get iconLegendExpiry => 'Giorni scadenza';

  @override
  String get iconLegendFileSize => 'Dimensione file';

  @override
  String get iconLegendAcceptedFiles => 'File accettati';

  @override
  String get iconLegendDirectLinks => 'Link diretti';

  @override
  String get iconLegendAccount => 'Account richiesto';

  @override
  String get enabled => 'Attivato';

  @override
  String get disabled => 'Disattivato';

  @override
  String get appDescription =>
      'Carica file su molti servizi di hosting gratuiti. Veloce, semplice e supporta molti provider.';

  @override
  String get providerInfoTitle => 'Info Provider';

  @override
  String maxFileSize(Object size) {
    return 'Dimensione massima file: $size';
  }

  @override
  String acceptedFiles(Object types) {
    return 'File accettati: $types';
  }

  @override
  String expiryInfo(Object info) {
    return 'I file scadono: $info';
  }

  @override
  String get supportsDirectLinks => 'Supporta link diretti';

  @override
  String get requiresAccount => 'Richiede account';

  @override
  String get iconLegendTitle => 'Icone Provider';

  @override
  String get iconLegendTest => 'Test';

  @override
  String get iconLegendFiles => 'File';

  @override
  String get iconLegendLinks => 'Link';

  @override
  String get iconLegendImages => 'Immagini';

  @override
  String get iconLegendOther => 'Altro';

  @override
  String get insecureWarningTitle => 'Connessione non sicura';

  @override
  String insecureWarningHttp(Object providerName, Object url) {
    return 'Il provider $providerName su $url usa una connessione HTTP non sicura. I tuoi file e dati di autenticazione verranno inviati in chiaro.';
  }

  @override
  String insecureWarningHttps(Object providerName, Object url) {
    return 'Il provider $providerName su $url ha un certificato non valido o autofirmato. La connessione potrebbe non essere sicura.';
  }

  @override
  String get viewCertificate => 'Vedi Certificato';

  @override
  String get certificateDialogTitle => 'Certificato del Server';

  @override
  String get certSubject => 'Soggetto';

  @override
  String get certIssuer => 'Emittente';

  @override
  String get certValidFrom => 'Valido dal';

  @override
  String get certValidUntil => 'Valido fino al';

  @override
  String get certFingerprint => 'Impronta digitale';

  @override
  String get proceedAnyway => 'Procedi comunque';

  @override
  String get dontShowAgain => 'Non mostrare più per questo provider';

  @override
  String get viewDebugLog => 'Visualizza log di debug';

  @override
  String get navigationLeft => 'Sinistra';

  @override
  String get navigationBottom => 'In basso';

  @override
  String get navigationRight => 'Destra';

  @override
  String get navLayout => 'Layout navigazione';

  @override
  String get navLayoutDescription =>
      'Scegli la posizione della navigazione: Sinistra, In basso o Destra.';

  @override
  String selectedExpiry(Object expiry) {
    return 'Scade tra: $expiry';
  }

  @override
  String get deleteUrl => 'URL di eliminazione';

  @override
  String get openDeleteUrl => 'Apri URL di eliminazione';

  @override
  String get deleteUrlCopied => 'URL di eliminazione copiato';

  @override
  String get copyDeleteUrl => 'Copia URL di eliminazione';

  @override
  String get failedToReadFile => 'Impossibile leggere il file selezionato';

  @override
  String get noProvidersConfigured => 'Nessun servizio di upload configurato';

  @override
  String get connectionTimedOut => 'Tempo di connessione scaduto';

  @override
  String connectionFailedMsg(Object error) {
    return 'Connessione fallita: $error';
  }

  @override
  String serverErrorMsg(Object code) {
    return 'Errore del server: $code';
  }

  @override
  String uploadFailedMsg(Object reason) {
    return 'Caricamento fallito: $reason';
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
  String get clearSelection => 'Annulla selezione';

  @override
  String get expiry1Hour => '1 ora';

  @override
  String get expiry24Hours => '24 ore';

  @override
  String get expiry3Days => '3 giorni';

  @override
  String get resetCrop => 'Ripristina ritaglio';

  @override
  String get debugInfo => 'Informazioni di Debug';

  @override
  String get debugInfoTooltip => 'Info debug';

  @override
  String get copyAll => 'Copia Tutto';

  @override
  String get share => 'Condividi';

  @override
  String get copiedToClipboard => 'Copiato negli appunti';

  @override
  String fileExceedsLimit(Object size) {
    return 'Il file supera il limite di $size';
  }

  @override
  String providerOnlyAccepts(Object types) {
    return 'Il provider accetta solo: $types';
  }

  @override
  String get systemInfo => 'Informazioni di Sistema';

  @override
  String get info => 'Informazioni';

  @override
  String get license => 'Licenza';

  @override
  String get gplNotice =>
      'Questo progetto è concesso in licenza GNU General Public License v3.0.';

  @override
  String get gplUrl => 'https://www.gnu.org/licenses/gpl-3.0.txt';

  @override
  String get noLogEntries => 'Nessuna voce di log.';

  @override
  String get copy => 'Copia';

  @override
  String versionLabel(Object version) {
    return 'Uppidi Upload v$version';
  }

  @override
  String get shellLayoutTitle => 'Layout Schermata';

  @override
  String get shellLayoutDescription =>
      'Scegli come organizzare le schermate: \"Tabs\" usa una barra delle schede per la navigazione. \"Modals\" mostra sempre la schermata di upload e apre le altre come dialoghi.';

  @override
  String get tabs => 'Schede';

  @override
  String get modals => 'Modali';

  @override
  String get downloadAndroid => 'Scarica APK Android';

  @override
  String get downloadLinux => 'Scarica Linux';

  @override
  String get browseAllBuilds => 'Sfoglia tutte le build';

  @override
  String get viewReleases => 'Vedi release su GitHub';

  @override
  String downloadingFile(Object label) {
    return 'Download di $label';
  }

  @override
  String downloadedTo(Object path) {
    return 'Scaricato in: $path';
  }

  @override
  String downloadFailed(Object error) {
    return 'Download fallito: $error';
  }

  @override
  String get changelogNotAvailable => 'Changelog non disponibile';

  @override
  String debugLogCopied(Object label) {
    return '$label — copiato negli appunti';
  }

  @override
  String get devBuild => 'BUILD DI SVILUPPO';

  @override
  String versionPrefix(Object version) {
    return 'v$version';
  }

  @override
  String get providerConfigDescription =>
      'Inserisci le credenziali richieste da questo provider.';

  @override
  String get providerConfigSecretHint =>
      'Questo valore è memorizzato localmente e mai condiviso.';

  @override
  String get providerConfigRequired => 'Questo campo è obbligatorio';

  @override
  String providerConfigSaved(Object provider) {
    return 'Configurazione di $provider salvata!';
  }

  @override
  String get providerConfigSectionConfigured => 'Configurato';

  @override
  String providerConfigNotConfigured(Object provider) {
    return '$provider — non configurato';
  }

  @override
  String get providerConfigure => 'Configura';

  @override
  String get save => 'Salva';

  @override
  String get telegramErrorChatNotFound =>
      'Chat non trovata. Controlla il tuo Chat ID.';

  @override
  String get telegramErrorBotBlocked =>
      'Il bot è stato bloccato dall\'utente. Sblocca prima il bot.';

  @override
  String get telegramErrorNoRights =>
      'Il bot non ha i permessi per inviare messaggi in questa chat.';

  @override
  String get telegramErrorInvalidToken =>
      'Token bot non valido. Controlla il tuo Bot Token da BotFather.';

  @override
  String get telegramSentToChat => 'Inviato alla chat Telegram';

  @override
  String get expiryPersistent =>
      'Persistente (fino alla revoca del token del bot)';

  @override
  String get expiryIndefinite30d =>
      'Indefinito (inattivo >30gg può essere eliminato)';

  @override
  String get expiryOneDayExtendable => '~1 giorno (estensibile al re-upload)';

  @override
  String get expiryOptions1h12h24h72h => '1h / 12h / 24h / 72h';

  @override
  String get expiry3Hours => '3 ore';

  @override
  String get expiry7Days => '7 giorni';

  @override
  String get mimeTypesImagesOnly => 'Solo immagini';

  @override
  String get configLabelBotToken => 'Token del Bot';

  @override
  String get configLabelChatId => 'ID Chat';

  @override
  String get configLabelSendAsPhoto => 'Invia immagini come foto';

  @override
  String get myProviders => 'I Miei Provider';

  @override
  String get addProvider => 'Aggiungi provider';

  @override
  String get noInstancesConfigured => 'Nessuna istanza configurata';

  @override
  String get deleteInstanceTitle => 'Eliminare istanza?';

  @override
  String deleteInstanceConfirm(Object name) {
    return 'Eliminare \"$name\" e tutte le sue credenziali?';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get fillRequiredFields => 'Compila prima i campi obbligatori';

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
