# Sürüm Geçmişi — Fir File Manager

> Kural: her oturum sürümün yama numarasını +1 büyütür. Görünür sürüm `pubspec.yaml`
> içindedir ve **Ayarlar → Sürüm** satırında gösterilir.

## v1.1.3 (2026-10-31) — Yavaş Kopya/Hareket Analizi

Bu sürümde, uzak/bulut sunucularında kopya ve hareket işlemlerinin yavaş olmasının nedenleri derinlemesine analiz edilmiştir. Aşağıda özetlenen bulgular, gelecekteki geliştirme ve optimizasyonlar için temel oluşturacaktır:

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