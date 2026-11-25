# Field Data Collector (Flutter, Android)

## Cara menjalankan di VS Code
1. Pastikan Flutter SDK (>= 3.27) dan Android SDK terpasang (`flutter doctor`).
2. Buat kerangka proyek Android dengan package yang sesuai:
   flutter create --org id.go.surabaya.bapenda --platforms=android field_data_collector
3. Salin isi folder ini ke dalam proyek hasil langkah 2 (timpa file yang sama):
   - pubspec.yaml
   - lib/                      (hapus lib/main.dart bawaan, pakai milik kami)
   - android/app/src/main/AndroidManifest.xml
   - android/app/src/main/kotlin/id/go/surabaya/bapenda/field_data_collector/MainActivity.kt
   - android/app/src/main/res/values/styles.xml  dan  values-night/styles.xml
4. Di android/app/build.gradle(.kts) ubah `minSdk` menjadi 26 (`minSdk = 26`).
5. Jalankan:
   flutter pub get
   flutter run
   (HP fisik, USB debugging aktif. Kamera/GPS tidak berfungsi baik di emulator.)

## Izin yang perlu disetujui saat testing
Kamera, Lokasi (saat aplikasi digunakan), Sidik jari/biometrik (bila kunci PIN + biometrik diaktifkan).
Penyimpanan tidak perlu izin khusus (file disimpan di folder aplikasi dan dibagikan via menu Bagikan).
Internet dipakai hanya untuk nama jalan (reverse geocoding) dan gambar peta di halaman detail.

## Yang perlu Anda sesuaikan
- utils/constants.dart: kontak bantuan (AppInfo.kontak*).
- services/export_service.dart: `kolomExcel` agar urutan/nama kolom sama persis dengan template sistem resmi Bapenda.
- Logo PDF saat ini berupa lingkaran "SBY"; ganti dengan logo resmi (pw.MemoryImage) bila ada.
- Sinkronisasi cloud belum ada; kolom `tersinkron` dan `server_id` di SQLite sudah disiapkan.
