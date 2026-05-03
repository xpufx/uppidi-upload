// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'uppidi';

  @override
  String get genericError =>
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get errorSessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen Ayarlar\'dan kimlik bilgilerinizi kontrol edin.';

  @override
  String get errorFileTooLarge => 'Bu dosya bu sağlayıcı için çok büyük.';

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
  String get selectProvider => 'Sağlayıcı Seç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get history => 'Geçmiş';

  @override
  String get historyEmpty => 'Henüz yükleme geçmişi yok';

  @override
  String get enableInsecure =>
      'Güvensiz bağlantılara izin ver (kendi imzalı sertifikalar)';

  @override
  String get proxyUrl => 'Proxy URL';

  @override
  String get providersSection => 'Sağlayıcı Yapılandırması';

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
  String get failed => 'Başarısız';

  @override
  String get error => 'Hata';

  @override
  String get unknownError => 'Bilinmeyen hata';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'İptal';

  @override
  String get timeJustNow => 'az önce';

  @override
  String timeMinutesAgo(Object minutes) => '$minutes' 'dk önce';

  @override
  String timeHoursAgo(Object hours) => '$hours' 's önce';
}
