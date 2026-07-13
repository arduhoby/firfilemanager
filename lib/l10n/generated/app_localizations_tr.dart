// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Fir Dosya Yöneticisi';

  @override
  String get navLocal => 'Yerel';

  @override
  String get navConnections => 'Bağlantılar';

  @override
  String get navServer => 'Sunucu';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get categoryImages => 'Görüntüler';

  @override
  String get categoryDocuments => 'Belgeler';

  @override
  String get categoryAudio => 'Ses';

  @override
  String get categoryVideo => 'Video';

  @override
  String get categoryDownloads => 'İndirilenler';

  @override
  String get categoryMainStorage => 'Ana Bellek';

  @override
  String get actionCopy => 'Kopyala';

  @override
  String get actionMove => 'Taşı';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionRename => 'Yeniden Adlandır';

  @override
  String get actionNewFolder => 'Yeni Klasör';

  @override
  String get actionPaste => 'Yapıştır';

  @override
  String get actionSelectAll => 'Tümünü Seç';

  @override
  String get actionRefresh => 'Yenile';

  @override
  String get actionOpen => 'Aç';

  @override
  String get actionProperties => 'Özellikler';

  @override
  String get actionOpenWith => 'Aç';

  @override
  String get actionRevealInFinder => 'Finder\'da Göster';

  @override
  String get actionCompress => 'Sıkıştır';

  @override
  String get actionCompressZip => 'ZIP olarak sıkıştır';

  @override
  String get actionCompressTar => 'TAR olarak sıkıştır';

  @override
  String get actionCompressTarGz => 'TAR.GZ olarak sıkıştır';

  @override
  String get actionExtract => 'Buraya Çıkar';

  @override
  String get actionExtractTo => 'Çıkar…';

  @override
  String get actionClose => 'Kapat';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionRetry => 'Tekrar Dene';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionConnect => 'Bağlan';

  @override
  String get actionDisconnect => 'Bağlantıyı Kes';

  @override
  String get actionAdd => 'Ekle';

  @override
  String get actionEdit => 'Düzenle';

  @override
  String get actionRemove => 'Kaldır';

  @override
  String get sortByName => 'İsim';

  @override
  String get sortByDate => 'Değiştirilme Tarihi';

  @override
  String get sortBySize => 'Boyut';

  @override
  String get sortByType => 'Tür';

  @override
  String get sortAscending => 'Artan';

  @override
  String get sortDescending => 'Azalan';

  @override
  String get panelLeft => 'Sol Panel';

  @override
  String get panelRight => 'Sağ Panel';

  @override
  String get panelActive => 'Aktif Panel';

  @override
  String operationCopying(int count) {
    return '$count öğe kopyalanıyor…';
  }

  @override
  String operationMoving(int count) {
    return '$count öğe taşınıyor…';
  }

  @override
  String operationDeleting(int count) {
    return '$count öğe siliniyor…';
  }

  @override
  String get operationComplete => 'İşlem tamamlandı';

  @override
  String operationFailed(String error) {
    return 'İşlem başarısız: $error';
  }

  @override
  String operationProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get connectionTypeSftp => 'SFTP';

  @override
  String get connectionTypeFtp => 'FTP';

  @override
  String get connectionTypeWebdav => 'WebDAV';

  @override
  String get connectionTypeSmb => 'SMB';

  @override
  String get connectionTypeGdrive => 'Google Drive';

  @override
  String get connectionTypeDropbox => 'Dropbox';

  @override
  String get connectionHost => 'Sunucu';

  @override
  String get connectionPort => 'Port';

  @override
  String get connectionUsername => 'Kullanıcı Adı';

  @override
  String get connectionPassword => 'Şifre';

  @override
  String get connectionName => 'Bağlantı Adı';

  @override
  String get connectionAuthMethod => 'Kimlik Doğrulama Yöntemi';

  @override
  String get connectionAuthPassword => 'Şifre';

  @override
  String get connectionAuthKey => 'Özel Anahtar';

  @override
  String get connectionAddNew => 'Yeni Bağlantı Ekle';

  @override
  String get connectionEdit => 'Bağlantıyı Düzenle';

  @override
  String get connectionTest => 'Bağlantıyı Test Et';

  @override
  String get connectionTestSuccess => 'Bağlantı başarılı';

  @override
  String connectionTestFailed(String error) {
    return 'Bağlantı başarısız: $error';
  }

  @override
  String get connectionDisconnected => 'Bağlantı kesildi';

  @override
  String get connectionReconnecting => 'Yeniden bağlanılıyor…';

  @override
  String get serverStart => 'Sunucuyu Başlat';

  @override
  String get serverStop => 'Sunucuyu Durdur';

  @override
  String get serverRunning => 'Sunucu çalışıyor';

  @override
  String get serverStopped => 'Sunucu durduruldu';

  @override
  String get serverSharedFolder => 'Paylaşılan Klasör';

  @override
  String get serverPort => 'Port';

  @override
  String get serverUsername => 'Kullanıcı Adı';

  @override
  String get serverPassword => 'Şifre';

  @override
  String get serverActiveConnections => 'Aktif Bağlantılar';

  @override
  String get serverNoConnections => 'Aktif bağlantı yok';

  @override
  String get serverFtp => 'FTP Sunucusu';

  @override
  String get serverWebdav => 'WebDAV Sunucusu';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get errorAccessDenied => 'Erişim reddedildi';

  @override
  String errorNotFound(String path) {
    return 'Bulunamadı: $path';
  }

  @override
  String errorAlreadyExists(String path) {
    return 'Zaten mevcut: $path';
  }

  @override
  String errorNetwork(String error) {
    return 'Ağ hatası: $error';
  }

  @override
  String get errorTimeout => 'İşlem zaman aşımına uğradı';

  @override
  String get errorUnknown => 'Bilinmeyen bir hata oluştu';

  @override
  String get confirmDeleteTitle => 'Sil';

  @override
  String confirmDeleteMessage(int count) {
    return '$count öğeyi silmek istediğinize emin misiniz?';
  }

  @override
  String get confirmOverwriteTitle => 'Üzerine Yaz';

  @override
  String confirmOverwriteMessage(String name) {
    return '$name zaten mevcut. Üzerine yazılsın mı?';
  }

  @override
  String get propertiesName => 'İsim';

  @override
  String get propertiesPath => 'Yol';

  @override
  String get propertiesSize => 'Boyut';

  @override
  String get propertiesType => 'Tür';

  @override
  String get propertiesModified => 'Değiştirilme Tarihi';

  @override
  String get propertiesPermissions => 'İzinler';

  @override
  String get propertiesFolder => 'Klasör';

  @override
  String get propertiesFile => 'Dosya';

  @override
  String itemsSelected(int count) {
    return '$count seçili';
  }

  @override
  String itemsCount(int count) {
    return '$count öğe';
  }

  @override
  String get emptyFolder => 'Bu klasör boş';
}
