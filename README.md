# Fir File Manager

🇹🇷 [Türkçe için aşağıya kaydırın](#türkçe)

Fir File Manager is a modern, cross-platform dual-pane file manager built with Flutter. It aims to provide an aesthetic, seamless, and productive file management experience with robust functionality.

## Features

- **Adaptive Dual-Pane Shell**: Two-pane interface for highly efficient file navigation and operations.
- **Advanced Sync & Equalization**: Includes a recursive directory sync analyzer with a **Tree-View Sync Preview Dialog** and a **Quick Panel Equalization (=)** shortcut in the context menu to easily align directories between panels.
- **Interactive Open With & Recents**: Offers an OS-native or customized application picker to open any file, alongside intelligent caching for **Recent Folders, Files, and Applications** for rapid workflow navigation.
- **Rich Media Feedback**: Features stunning glass-morphism progress bars, **animated flying file icons** across the screen, and custom **sound effects toggleable via settings** (e.g. paper crumple on delete, swoosh on copy/move).
- **Extensive File Operations**: Seamlessly Copy, Cut, Paste, Rename, Move, and Delete files and directories.
- **Drag & Drop Support**: Move files effortlessly between panels with drag and drop capabilities.
- **Keyboard Shortcuts & Clean UI**: Fully keyboard navigable for power users (F5 for Copy, F6 for Move, Cmd+C/Cmd+V, etc.) with custom hover-animated buttons built from state-of-the-art design systems.
- **Multi-Protocol Support (WIP)**: Built-in abstractions for Local, FTP, and SMB file systems.

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
- **Gelişmiş Senkronizasyon ve Eşitleme (=)**: İki klasörü eşitlemek için detaylı tarama ve **Ağaç (Tree) görünümlü önizleme penceresi** sunar. Ayrıca sağ tık menüsündeki hızlı **Eşitleme (=)** komutuyla hedef paneli aktif panelin yoluna saniyeler içinde getirebilirsiniz.
- **Akıllı Geçmiş ve Şununla Aç**: Dosyaları açmak için yerel işletim sistemi uygulamalarını veya özelleştirilmiş uygulama seçiciyi kullanır. Gezinme alışkanlıklarınızı takip ederek **Son Kullanılan Dosyalar, Klasörler ve Uygulamalar** için hızlı kısayollar sunar.
- **Görsel ve İşitsel Geri Bildirim**: Dosya transferleri sırasında alt kısımda beliren "Glassmorphism" tasarımlı işlem merkezine ek olarak, ekranda paneller arası **uçan şık dosya ikonları** görünür. Ayarlardan kapatılabilen tatmin edici ses efektleri eşlik eder.
- **Kapsamlı Dosya İşlemleri**: Kopyalama, kesme, yapıştırma, yeniden adlandırma, taşıma ve silme gibi tüm klasik dosya işlemlerini destekler.
- **Sürükle & Bırak (Drag & Drop)**: Paneller arasında dosyaları farenizle rahatça sürükleyip bırakabilirsiniz.
- **Klavye Kısayolları ve Modern Arayüz**: Gelişmiş kullanıcılar için tamamen klavye ile yönetilebilir yapı (F5 Kopyalama, F6 Taşıma, Cmd+C/Cmd+V vb.) ve Uiverse tabanlı modern animasyonlu butonlar.
- **Çoklu Protokol (WIP)**: Yerel (Local), FTP ve SMB dosya sistemleri için esnek altyapı destekleri içerir.

## Başlangıç

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) kurulumunu yapın.
2. Projeyi bilgisayarınıza indirin (clone).
3. `lib/env.dart.example` dosyasının bir kopyasını oluşturup adını `lib/env.dart` yapın. Gerekirse Google Drive API anahtarlarınızı bu dosyaya yazabilirsiniz.
4. Bağımlılıkları yüklemek için `flutter pub get` komutunu çalıştırın.
5. `flutter run -d macos` komutu ile uygulamayı başlatın (En iyi masaüstü deneyimi için macOS önerilir).
