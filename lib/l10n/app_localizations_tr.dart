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
  String get providersSection => 'Sağlayıcı Yapılandırması';

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
  String get deleteThisRecord => 'Bu kayıtı sil?';

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
  String get qualityMedium => 'Orta (1920px)';

  @override
  String get qualityLow => 'Düşük (800px)';

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
    return 'Dosyaların süresi: $info';
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
}
