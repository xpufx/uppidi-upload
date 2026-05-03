// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'uppidi';

  @override
  String get genericError => 'Si è verificato un errore imprevisto. Riprova.';

  @override
  String get errorSessionExpired =>
      'La sessione è scaduta. Controlla le credenziali nelle Impostazioni.';

  @override
  String get errorFileTooLarge =>
      'Il file è troppo grande per questo servizio.';

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
  String get enableInsecure =>
      'Consenti connessioni insicure (certificati autofirmati)';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get providersSection => 'Configurazione Servizi';

  @override
  String get historyClearAll => 'Cancella tutto';

  @override
  String get historyClearConfirm => 'Eliminare tutta la cronologia?';

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
  String get ok => 'OK';

  @override
  String get cancel => 'Annulla';

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
}
