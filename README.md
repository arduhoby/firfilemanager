# Fir File Manager

🇹🇷 [Türkçe için aşağıya kaydırın](#türkçe)

Fir File Manager is a modern, cross-platform dual-pane file manager built with Flutter. It aims to provide an aesthetic, seamless, and productive file management experience with robust functionality.

## Features

- **Adaptive Dual-Pane Shell**: Two-pane interface for highly efficient file navigation and operations.
- **Fir SmartSync**: Compares both panels by name, size, and modification time; provides color-coded table/card previews with per-file overrides; and saves named manual, one-time, daily, or weekly jobs with run history. Scheduled execution uses systemd user timers on Linux, Task Scheduler on Windows, and Android alarms with foreground notifications.
- **Interactive Open With & Recents**: Offers an OS-native or customized application picker to open any file, alongside intelligent caching for **Recent Folders, Files, and Applications** for rapid workflow navigation.
- **Rich Media Feedback**: Features stunning glass-morphism progress bars, **animated flying file icons** across the screen, and custom **sound effects toggleable via settings** (e.g. paper crumple on delete, swoosh on copy/move).
- **Extensive File Operations**: Seamlessly Copy, Cut, Paste, Rename, Move, and Delete files and directories.
- **Drag & Drop Support**: Move files effortlessly between panels with drag and drop capabilities.
- **Keyboard Shortcuts & Clean UI**: Fully keyboard navigable for power users (F5 for Copy, F6 for Move, Cmd+C/Cmd+V, etc.) with custom hover-animated buttons built from state-of-the-art design systems.
- **Multi-Protocol Support**: Built-in abstractions for Local, FTP, SFTP, WebDAV (Nextcloud), SMB, and Cloud Storage (Google Drive, OneDrive, Dropbox) filesystems.
- **Fast Transfers**: Paged cloud listings, single-request directory scans, small-file parallel copy (Local/WebDAV), and batched post-transfer verification keep large trees responsive (v1.1.1).
- **Built-in Server Mode**: Share your files over FTP and WebDAV from the app; the shared password is remembered across restarts via the platform keystore, and credentials are never written to logs (v1.1.2).

## Getting Started

1. Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
2. Clone this repository.
3. Copy `lib/env.dart.example` to `lib/env.dart`. You can add your API keys inside this file if needed.
4. Run `flutter pub get` to install dependencies.
5. Run `flutter run -d macos` (macOS recommended for optimal desktop experience).

---

# Türkçe

Fir File Manager, Flutter ile geliştirilmiş modern, çok platformlu ve çift panelli (dual-pane) bir dosya yöneticisidir. Amacı; estetik, akıcı ve verimli bir dosya yönetim deneyimi sunmaktır.

## Özellikler

- **Çift Panelli Arayüz (Dual-Pane Shell)**: Dosyalar arasında gezinmeyi ve dosya taşıma/kopyalama işlemlerini inanılmaz derecede hızlandıran çift panel düzeni.
- **Fir SmartSync**: Panelleri ad, boyut ve değiştirilme tarihine göre karşılaştırır; renkli tablo/kart önizlemesi ve dosya bazlı seçim sunar. Adlandırılmış görevler elle, bir kez, günlük veya haftalık çalıştırılabilir; sonuç geçmişi tutulur. Zamanlama Linux'ta systemd kullanıcı zamanlayıcısı, Windows'ta Görev Zamanlayıcı ve Android'de bildirimli alarm altyapısını kullanır.
- **Akıllı Geçmiş ve Şununla Aç**: Dosyaları açmak için yerel işletim sistemi uygulamalarını veya özelleştirilmiş uygulama seçiciyi kullanır. Gezinme alışkanlıklarınızı takip ederek **Son Kullanılan Dosyalar, Klasörler ve Uygulamalar** için hızlı kısayollar sunar.
- **Görsel ve İşitsel Geri Bildirim**: Dosya transferleri sırasında alt kısımda beliren "Glassmorphism" tasarımlı işlem merkezine ek olarak, ekranda paneller arası **uçan şık dosya ikonları** görünür. Ayarlardan kapatılabilen tatmin edici ses efektleri eşlik eder.
- **Kapsamlı Dosya İşlemleri**: Kopyalama, kesme, yapıştırma, yeniden adlandırma, taşıma ve silme gibi tüm klasik dosya işlemlerini destekler.
- **Sürükle & Bırak (Drag & Drop)**: Paneller arasında dosyaları farenizle rahatça sürükleyip bırakabilirsiniz.
- **Klavye Kısayolları ve Modern Arayüz**: Gelişmiş kullanıcılar için tamamen klavye ile yönetilebilir yapı (F5 Kopyalama, F6 Taşıma, Cmd+C/Cmd+V vb.) ve Uiverse tabanlı modern animasyonlu butonlar.
- **Çoklu Protokol**: Yerel (Local), FTP, SFTP, WebDAV (Nextcloud), SMB ve Bulut Depolama (Google Drive, OneDrive, Dropbox) dosya sistemleri için esnek altyapı destekleri içerir.
- **Hızlı Transferler**: Sayfalı bulut listelemeleri, dizin başına tek istekli tarama, küçük dosyalarda paralel kopyalama (Local/WebDAV) ve toplu aktarım-sonrası doğrulama ile büyük ağaçlarda akıcı deneyim (v1.1.1).
- **Yerleşik Sunucu Modu**: Dosyalarınızı uygulama içinden FTP ve WebDAV ile paylaşın; paylaşım şifresi platform anahtar deposunda saklanarak yeniden başlatmalarda hatırlanır ve bilgiler asla loglara yazılmaz (v1.1.2).

## Başlangıç

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) kurulumunu yapın.
2. Projeyi bilgisayarınıza indirin (clone).
3. `lib/env.dart.example` dosyasının bir kopyasını oluşturup adını `lib/env.dart` yapın. Gerekirse Google Drive API anahtarlarınızı bu dosyaya yazabilirsiniz.
4. Bağımlılıkları yüklemek için `flutter pub get` komutunu çalıştırın.
5. `flutter run -d macos` komutu ile uygulamayı başlatın (En iyi masaüstü deneyimi için macOS önerilir).

## Son Oturum Analizi: Yavaş Kopya/Hareket İşlemleri (2026-10-31)

Bu oturumda, uzak/bulut sunucularında kopya ve hareket işlemlerinin yavaş olmasının nedenleri derinlemesine analiz edilmiştir. Aşağıda özetlenen bulgular, gelecekteki geliştirme ve optimizasyonlar için temel oluşturacaktır:

### Ana Bulgular
- `move()` metodu, sunucu tarafında yeniden adlandırma yerine kopya + doğrulama + silme işlemi gerçekleştirir.
- `local_provider.dart` dosyasında, her ilerleme bildirimi için 1ms yapay gecikme eklenmiştir.
- `panel_controller.dart` dosyasında, izleyici (watcher) için debounce mekanizması yoktur.
- `file_operations_service.dart` ve `file_tree_inventory_service.dart` dosyalarında, hazırlık aşamasında throttle mekanizması eksikdir.
- `webdav_provider.dart` ve `nextcloud_provider.dart` dosyalarında, sunucu tarafı COPY işlemi desteklenmemektedir.
- `ftp_provider.dart` dosyasında, `stat()` metodu, üst klasör listesini tetikler.
- `google_drive_provider.dart` dosyasında, yazma işlemi sırasında tüm dosya bellekte tutulur.
- `parallel_transfer_capable.dart` dosyasında, yalnızca Local ve WebDAV sunucuları paralel transfer destekler.
- `sftp_provider.dart` dosyasında, 269. satırda, offset eksikliği ve beklenmeyen yazıcı (writer) nedeniyle veri bozulma riski bulunmaktadır.

### Önerilen Çözümler
1. Sunucu tarafı yeniden adlandırma (rename) desteklenmiyorsa, `move()` metodu yerine `copy` ve `delete` metotları kullanılmalıdır.
2. `local_provider.dart` dosyasında, 1ms gecikme kaldırılmalıdır.
3. `panel_controller.dart` dosyasında, izleyici için debounce mekanizması eklenmelidir.
4. `file_operations_service.dart` ve `file_tree_inventory_service.dart` dosyalarında, hazırlık aşamasında throttle mekanizması eklenmelidir.
5. `webdav_provider.dart` ve `nextcloud_provider.dart` dosyalarında, sunucu tarafı COPY işlemi desteklenmelidir.
6. `ftp_provider.dart` dosyasında, `stat()` metodu optimize edilmelidir.
7. `google_drive_provider.dart` dosyasında, yazma işlemi bellek kullanımını azaltacak şekilde optimize edilmelidir.
8. `parallel_transfer_capable.dart` dosyasında, paralel transfer desteklenmeyen sunucular için destek eklenmelidir.
9. `sftp_provider.dart` dosyasında, 269. satırda bulunan offset eksikliği ve beklenmeyen yazıcı nedeniyle veri bozulma riski giderilmelidir.

Bu analiz sonucunda, geliştirme süreci daha verimli ve hedefe yönelik hale gelmiştir. Gelecek oturumlarda bu bulgulara dayanarak ilerlenecektir.