// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Uppidi Upload';

  @override
  String get genericError =>
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get errorSessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen Ayarlar\'dan kimlik bilgilerinizi kontrol edin.';

  @override
  String get errorFileTooLarge => 'Bu dosya bu sağlayıcı için çok büyük.';

  @override
  String get errorInvalidUploader =>
      'Geçersiz yükleyici yapılandırması. Lütfen ayarları kontrol edin veya daha sonra tekrar deneyin.';

  @override
  String get invalidMimeType => 'Geçersiz veya desteklenmeyen dosya türü.';

  @override
  String get fileSystemError => 'Seçilen dosya okunamadı.';

  @override
  String get errorConnectionFailed =>
      'Sağlayıcıya bağlanılamadı. Erişilemiyor olabilir veya tarayıcınız tarafından engellenmiş olabilir.';

  @override
  String get uploadCancelled => 'Yükleme iptal edildi.';

  @override
  String get providerWebNotSupported =>
      'Bu sağlayıcı web tarayıcısında doğrudan kullanılamaz. Ayarlardan deneysel proxy\'yi etkinleştirin.';

  @override
  String get selfSignedCertWarning =>
      'Güvensiz bağlantı modu sertifika doğrulamasını atlar. Bu seçeneği yalnızca güvenilen kendi barındırılan sunucular için etkinleştirin.';

  @override
  String get upload => 'Yükle';

  @override
  String get uploading => 'Yükleniyor...';

  @override
  String get uploadComplete => 'Yükleme tamamlandı!';

  @override
  String get uploadFailed => 'Yükleme başarısız';

  @override
  String get cancelUpload => 'Yüklemeyi İptal Et';

  @override
  String get pickAndUpload => 'Seç ve Yükle';

  @override
  String get urlCopiedToClipboard => 'URL panoya kopyalandı';

  @override
  String get shareUrl => 'URL Paylaş';

  @override
  String get selectProvider => 'Sağlayıcı Seç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get history => 'Geçmiş';

  @override
  String get historyEmpty => 'Henüz yükleme geçmişi yok';

  @override
  String get enableInsecure => 'Güvensiz bağlantılara izin ver';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get navProviders => 'Sağlayıcılar';

  @override
  String get providersSection => 'Sağlayıcılar';

  @override
  String get historyClearAll => 'Tümünü temizle';

  @override
  String get historyClearConfirm => 'Tüm geçmiş silinsin mi?';

  @override
  String historyRecords(Object count) {
    return '$count kayıt';
  }

  @override
  String get clearHistory => 'Geçmişi Temizle';

  @override
  String get openInBrowser => 'Tarayıcıda aç';

  @override
  String get noProviders =>
      'Hiç sağlayıcı yapılandırılmamış. Ayarlardan bir tane ekleyin.';

  @override
  String disclaimer(Object provider) {
    return '$provider hizmetine yükleme yapmak üzeresiniz. Bu hizmetle ilişkili değiliz.';
  }

  @override
  String get success => 'Başarılı';

  @override
  String get themeCustomLogo => 'Özel Logo';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSeedColor => 'Vurgu Rengi';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get failed => 'Başarısız';

  @override
  String get error => 'Hata';

  @override
  String get unknownError => 'Bilinmeyen hata';

  @override
  String get language => 'Dil';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'İptal';

  @override
  String get apply => 'Uygula';

  @override
  String get timeJustNow => 'az önce';

  @override
  String timeMinutesAgo(Object minutes) {
    return '${minutes}dk önce';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '${hours}s önce';
  }

  @override
  String get navTest => 'Test';

  @override
  String get testAll => 'Hepsini Test Et';

  @override
  String get testProvider => 'Test';

  @override
  String get noProvidersAvailable => 'Sağlayıcı yok';

  @override
  String get connectionFailed => 'Bağlantı başarısız';

  @override
  String get viewChangelog => 'Değişiklikleri Gör';

  @override
  String get changelogTitle => 'Değişiklikler';

  @override
  String get changeLogo => 'Logoyu Değiştir';

  @override
  String get chooseLogo => 'Logo Seç';

  @override
  String providersCount(Object count) {
    return '$count sağlayıcı';
  }

  @override
  String get defaultForSharing => 'Paylaşım için varsayılan';

  @override
  String get lastUsed => 'Son kullanılan';

  @override
  String get proxyHint => 'socks5://sunucu:port';

  @override
  String get dropFileToUpload => 'Yüklemek için dosyayı bırak';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get chooseFile => 'Dosya Seç';

  @override
  String get deleteThisRecord => 'Bu kaydı sil?';

  @override
  String get shareLink => 'Bağlantıyı Paylaş';

  @override
  String get includeMessage => 'Mesaj ekle';

  @override
  String get templateVars => 'Şablon Değişkenleri';

  @override
  String get templateExamples => 'Örnekler:';

  @override
  String get customizeMessage => 'Özelleştir:';

  @override
  String get debugLogging => 'Hata ayıklama günlüğünü etkinleştir';

  @override
  String get debugLoggingDescription =>
      'Sorun giderme için tüm HTTP istek/yanıt detaylarını konsola kaydeder. Yalnızca gerektiğinde etkinleştirin.';

  @override
  String get qualityOriginal => 'Orijinal';

  @override
  String get qualityMedium => 'Yarım boyut';

  @override
  String get qualityLow => 'Çeyrek boyut';

  @override
  String get uiVariant => 'UI Varyantı';

  @override
  String get uiVariantDescription =>
      'Ana ekran sağlayıcı düzenini seçin: Liste veya Çip.';

  @override
  String get uiVariantDefault => 'Sağlayıcı Listesi';

  @override
  String get uiVariantCompact => 'Sağlayıcı Çipleri';

  @override
  String get iconLegendWarning => 'Uyarı';

  @override
  String get iconLegendExpiry => 'Süre';

  @override
  String get iconLegendFileSize => 'Dosya boyutu';

  @override
  String get iconLegendAcceptedFiles => 'Kabul edilen dosyalar';

  @override
  String get iconLegendDirectLinks => 'Doğrudan linkler';

  @override
  String get iconLegendAccount => 'Hesap gerekli';

  @override
  String get enabled => 'Etkin';

  @override
  String get disabled => 'Devre Dışı';

  @override
  String get appDescription =>
      'Birden fazla ücretsiz barındırma servisine dosya yükleyin. Hızlı, basit ve birçok sağlayıcıyı destekler.';

  @override
  String get providerInfoTitle => 'Sağlayıcı Bilgisi';

  @override
  String maxFileSize(Object size) {
    return 'Maksimum dosya boyutu: $size';
  }

  @override
  String acceptedFiles(Object types) {
    return 'Kabul edilen dosyalar: $types';
  }

  @override
  String expiryInfo(Object info) {
    return 'Süre: $info';
  }

  @override
  String get supportsDirectLinks => 'Doğrudan linkleri destekler';

  @override
  String get requiresAccount => 'Hesap gerektirir';

  @override
  String get iconLegendTitle => 'Sağlayıcı Simgeleri';

  @override
  String get iconLegendTest => 'Test';

  @override
  String get iconLegendFiles => 'Dosyalar';

  @override
  String get iconLegendLinks => 'Linkler';

  @override
  String get iconLegendImages => 'Görseller';

  @override
  String get iconLegendOther => 'Diğer';

  @override
  String get insecureWarningTitle => 'Güvensiz Bağlantı';

  @override
  String insecureWarningHttp(Object providerName, Object url) {
    return '$providerName sağlayıcısı $url adresinde güvensiz bir HTTP bağlantısı kullanıyor. Dosyalarınız ve kimlik doğrulama verileriniz düz metin olarak gönderilecek.';
  }

  @override
  String insecureWarningHttps(Object providerName, Object url) {
    return '$providerName sağlayıcısı $url adresinde geçersiz veya kendi imzalı bir sertifikaya sahip. Bağlantı güvenli olmayabilir.';
  }

  @override
  String get viewCertificate => 'Sertifikayı Görüntüle';

  @override
  String get certificateDialogTitle => 'Sunucu Sertifikası';

  @override
  String get certSubject => 'Konu';

  @override
  String get certIssuer => 'Yayıncı';

  @override
  String get certValidFrom => 'Geçerlilik başlangıcı';

  @override
  String get certValidUntil => 'Geçerlilik sonu';

  @override
  String get certFingerprint => 'Parmak izi';

  @override
  String get proceedAnyway => 'Yine de devam et';

  @override
  String get dontShowAgain => 'Bu sağlayıcı için tekrar gösterme';

  @override
  String get viewDebugLog => 'Hata ayıklama günlüğünü görüntüle';

  @override
  String get navigationLeft => 'Sol';

  @override
  String get navigationBottom => 'Alt';

  @override
  String get navigationRight => 'Sağ';

  @override
  String get navLayout => 'Navigasyon Düzeni';

  @override
  String get navLayoutDescription =>
      'Navigasyon konumunu seçin: Sol, Alt veya Sağ.';

  @override
  String selectedExpiry(Object expiry) {
    return 'Kalan süre: $expiry';
  }

  @override
  String get deleteUrl => 'Silme URL\'si';

  @override
  String get openDeleteUrl => 'Silme URL\'sini aç';

  @override
  String get deleteUrlCopied => 'Silme URL\'si panoya kopyalandı';

  @override
  String get copyDeleteUrl => 'Silme URL\'sini kopyala';

  @override
  String get failedToReadFile => 'Seçilen dosya okunamadı';

  @override
  String get noProvidersConfigured =>
      'Hiçbir yükleme sağlayıcısı yapılandırılmamış';

  @override
  String get connectionTimedOut => 'Bağlantı zaman aşımına uğradı';

  @override
  String connectionFailedMsg(Object error) {
    return 'Bağlantı başarısız: $error';
  }

  @override
  String serverErrorMsg(Object code) {
    return 'Sunucu hatası: $code';
  }

  @override
  String uploadFailedMsg(Object reason) {
    return 'Yükleme başarısız: $reason';
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
  String get clearSelection => 'Seçimi temizle';

  @override
  String get expiry1Hour => '1 saat';

  @override
  String get expiry24Hours => '24 saat';

  @override
  String get expiry3Days => '3 gün';

  @override
  String get resetCrop => 'Kırpmayı sıfırla';

  @override
  String get debugInfo => 'Hata Ayıklama Bilgisi';

  @override
  String get debugInfoTooltip => 'Hata ayıklama bilgisi';

  @override
  String get copyAll => 'Tümünü Kopyala';

  @override
  String get share => 'Paylaş';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String fileExceedsLimit(Object size) {
    return 'Dosya $size sınırını aşıyor';
  }

  @override
  String providerOnlyAccepts(Object types) {
    return 'Sağlayıcı yalnızca şunları kabul eder: $types';
  }

  @override
  String get systemInfo => 'Sistem Bilgisi';

  @override
  String get info => 'Bilgi';

  @override
  String get license => 'Lisans';

  @override
  String get gplNotice =>
      'Bu proje GNU Genel Kamu Lisansı v3.0 kapsamında lisanslanmıştır.';

  @override
  String get gplUrl => 'https://www.gnu.org/licenses/gpl-3.0.txt';

  @override
  String get noLogEntries => 'Henüz günlük kaydı yok.';

  @override
  String get copy => 'Kopyala';

  @override
  String versionLabel(Object version) {
    return 'Uppidi Upload v$version';
  }

  @override
  String get shellLayoutTitle => 'Arayüz Düzeni';

  @override
  String get shellLayoutDescription =>
      'Ekranların nasıl düzenleneceğini seçin: \"Sekmeler\" gezinti için bir sekme çubuğu kullanır. \"Modal\" yükleme ekranını her zaman gösterir ve diğer ekranları iletişim kutusu olarak açar.';

  @override
  String get tabs => 'Sekmeler';

  @override
  String get modals => 'Modal';

  @override
  String get downloadAndroid => 'Android APK İndir';

  @override
  String get downloadLinux => 'Linux İndir';

  @override
  String get browseAllBuilds => 'Tüm yapıları göz at';

  @override
  String get viewReleases => 'GitHub\'da sürümleri görüntüle';

  @override
  String downloadingFile(Object label) {
    return '$label indiriliyor';
  }

  @override
  String downloadedTo(Object path) {
    return 'İndirildi: $path';
  }

  @override
  String downloadFailed(Object error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get changelogNotAvailable => 'Değişiklik günlüğü mevcut değil';

  @override
  String debugLogCopied(Object label) {
    return '$label — panoya kopyalandı';
  }

  @override
  String get devBuild => 'GELİŞTİRME YAPISI';

  @override
  String versionPrefix(Object version) {
    return 'v$version';
  }

  @override
  String get providerConfigDescription =>
      'Bu sağlayıcının gerektirdiği kimlik bilgilerini girin.';

  @override
  String get providerConfigSecretHint =>
      'Bu değer yerel olarak saklanır ve asla paylaşılmaz.';

  @override
  String get providerConfigRequired => 'Bu alan zorunludur';

  @override
  String providerConfigSaved(Object provider) {
    return '$provider yapılandırması kaydedildi!';
  }

  @override
  String get providerConfigSectionConfigured => 'Yapılandırıldı';

  @override
  String providerConfigNotConfigured(Object provider) {
    return '$provider — yapılandırılmamış';
  }

  @override
  String get providerConfigure => 'Yapılandır';

  @override
  String get save => 'Kaydet';

  @override
  String get telegramErrorChatNotFound =>
      'Chat bulunamadı. Chat ID\'nizi kontrol edin.';

  @override
  String get telegramErrorBotBlocked =>
      'Bot kullanıcı tarafından engellendi. Önce botun engelini kaldırın.';

  @override
  String get telegramErrorNoRights =>
      'Botun bu sohbette mesaj gönderme izni yok.';

  @override
  String get telegramErrorInvalidToken =>
      'Geçersiz bot tokeni. BotFather\'dan Bot Token\'inizi kontrol edin.';

  @override
  String get telegramSentToChat => 'Telegram sohbetine gönderildi';

  @override
  String get expiryPersistent => 'Kalıcı (bot tokeni iptal edilene kadar)';

  @override
  String get expiryIndefinite30d =>
      'Süresiz (30 gün hareketsiz kalırsa silinebilir)';

  @override
  String get expiryOneDayExtendable =>
      '~1 gün (yeniden yüklemeyle uzatılabilir)';

  @override
  String get expiryOptions1h12h24h72h => '1s / 12s / 24s / 72s';

  @override
  String get expiry3Hours => '3 saat';

  @override
  String get expiry7Days => '7 gün';

  @override
  String get mimeTypesImagesOnly => 'Yalnızca görseller';

  @override
  String get configLabelBotToken => 'Bot Tokeni';

  @override
  String get configLabelChatId => 'Sohbet ID\'si';

  @override
  String get configLabelSendAsPhoto => 'Görselleri fotoğraf olarak gönder';

  @override
  String get myProviders => 'Sağlayıcılarım';

  @override
  String get addProvider => 'Sağlayıcı ekle';

  @override
  String get noInstancesConfigured => 'Hiçbir örnek yapılandırılmamış';

  @override
  String get deleteInstanceTitle => 'Örnek silinsin mi?';

  @override
  String deleteInstanceConfirm(Object name) {
    return '\"$name\" ve tüm kimlik bilgileri silinsin mi?';
  }

  @override
  String get delete => 'Sil';

  @override
  String get fillRequiredFields => 'Önce gerekli alanları doldurun';

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
  String get reloadZulipResources => 'Manage channels & users';

  @override
  String get undo => 'Geri al';

  @override
  String get redo => 'Yinele';

  @override
  String get remove => 'Kaldır';

  @override
  String get rotate => 'Döndür';

  @override
  String get flip => 'Çevir';

  @override
  String get ratio => 'Oran';

  @override
  String get reset => 'Sıfırla';

  @override
  String get search => 'Ara';

  @override
  String get none => 'Hiçbiri';

  @override
  String get color => 'Renk';

  @override
  String get opacity => 'Saydamlık';

  @override
  String get fill => 'Doldur';

  @override
  String get eraser => 'Silgi';

  @override
  String get lineWidth => 'Çizgi kalınlığı';

  @override
  String get strokeWidth => 'Çizgi kalınlığı';

  @override
  String get edit => 'Düzenle';

  @override
  String get brightness => 'Parlaklık';

  @override
  String get contrast => 'Kontrast';

  @override
  String get saturation => 'Doygunluk';

  @override
  String get exposure => 'Pozlama';

  @override
  String get hue => 'Renk tonu';

  @override
  String get temperature => 'Sıcaklık';

  @override
  String get sharpness => 'Keskinlik';

  @override
  String get fade => 'Soldurma';

  @override
  String get textAlign => 'Hizalama';

  @override
  String get fontScale => 'Yazı boyutu';

  @override
  String get backgroundMode => 'Arka plan';

  @override
  String get inputHintText => 'Metin girin...';

  @override
  String get closeEditorWarningTitle => 'Değişiklikler atılsın mı?';

  @override
  String get closeEditorWarningMessage =>
      'Kaydedilmemiş değişiklikler var. Bunları atmak istediğinize emin misiniz?';

  @override
  String get closeEditorWarningConfirmBtn => 'At';

  @override
  String get arrow => 'Ok';

  @override
  String get line => 'Çizgi';

  @override
  String get rectangle => 'Dikdörtgen';

  @override
  String get circle => 'Daire';

  @override
  String get moveAndZoom => 'Taşı ve Yakınlaştır';

  @override
  String get freestyle => 'Serbest çizim';

  @override
  String get toggleFill => 'Doldurmayı aç/kapat';

  @override
  String get changeOpacity => 'Saydamlığı değiştir';

  @override
  String get back => 'Geri';

  @override
  String get blurTool => 'Bulanıklaştır';

  @override
  String get emojiTool => 'Emoji';

  @override
  String get filterTool => 'Filtre';

  @override
  String get paintTool => 'Boyama';

  @override
  String get stickerTool => 'Çıkartmalar';

  @override
  String get textTool => 'Yazı';

  @override
  String get tuneTool => 'Ayarla';

  @override
  String get revertEdits => 'Düzenlemeleri geri al';

  @override
  String get editImage => 'Görseli düzenle';
}
