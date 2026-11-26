# Field Data Collector

Aplikasi Android untuk **mendokumentasikan bukti pengantaran surat pajak daerah** di lapangan.
Dibuat sebagai proyek magang di **Bapenda Kota Surabaya – UPTB Pelayanan Pajak Daerah Surabaya 5**.

Petugas cukup membuka aplikasi, memotret lokasi, dan data tersimpan lengkap dengan koordinat GPS, alamat,
waktu, nama petugas, dan tanda tangan penerima. Semua bisa dipakai **tanpa internet** dan diekspor ke Excel/PDF.

---

## 1. Latar Belakang & Tujuan

Bukti pengantaran SPPT PBB, SKPD, dan surat pajak lainnya selama ini sulit direkap: foto tersebar di galeri,
catatan manual, dan sulit diverifikasi lokasinya. Aplikasi ini:

- mengumpulkan bukti dalam **satu tempat yang rapi**,
- membuktikan lokasi & waktu lewat **foto bergeotag**,
- mencatat **siapa petugas** yang mengantar,
- memudahkan **rekap & pelaporan** (Excel/PDF) kepada atasan.

## 2. Fitur Utama

| Fitur | Keterangan |
|---|---|
| 9 jenis pajak berwarna | PBB, Restoran, Hotel, Hiburan, Parkir, Reklame, Air Tanah, PPJ, Lainnya |
| Foto geotag | Peta mini, alamat, koordinat, tanggal & jam, NOP, nama, dan petugas dalam kotak sesuai warna jenis pajak |
| Status penerimaan | Diterima Langsung, Kotak Pos, Tidak Ada Orang, Alamat Tidak Ditemukan, Ditolak |
| Tanda tangan digital | Tanda tangan penerima langsung di layar |
| Daftar Tugas | Impor objek pajak dari SIMPADA (.xlsx/.csv), progres, kunjungan ulang, tombol Rute ke Google Maps |
| Peringatan NOP ganda | Mencegah pencatatan ganda untuk NOP yang sama |
| Riwayat & pencarian | Cari + filter jenis pajak, status, petugas, dan tanggal |
| Statistik | Grafik mingguan/bulanan, tingkat keberhasilan, kinerja per petugas |
| Ekspor | Excel (foto tertanam) dan PDF (foto + tanda tangan) |
| Cadangan data | Backup & pulihkan dalam satu file ZIP |
| Keamanan | Kunci PIN dan sidik jari (opsional) |
| Tema | Mengikuti sistem HP (terang/gelap), bisa diubah manual |
| Offline | Data tersimpan lokal (SQLite), tidak butuh internet untuk mencatat |

## 3. Cara Menggunakan Aplikasi

### 3.1 Pertama kali membuka
1. Layar pembuka (splash) lalu **3 slide perkenalan** — geser atau tekan *Lewati*.
2. Izinkan **Kamera** dan **Lokasi** saat diminta.
3. (Opsional) Buka tab **Akun** untuk mengisi nama petugas dan mengaktifkan PIN.

### 3.2 Menyiapkan profil petugas (tab Akun)
- **Ubah Info Petugas**: isi nama petugas. Nama ini muncul di foto dan laporan. Tidak wajib diisi.
- **Foto profil**: bisa ditambah, diganti, atau dihapus.
- **Tampilan**: Sistem / Terang / Gelap.
- **Kunci PIN**: aktifkan, lalu (opsional) tambahkan sidik jari.
- **Foto Bukti**: pilih format JPG atau PNG dan apakah otomatis disimpan ke galeri.

### 3.3 Mencatat kunjungan baru
1. Di **Beranda**, ketuk tombol **Kunjungan Baru** (+).
2. Pilih **jenis pajak**.
3. Isi data (semuanya opsional, tetap bisa disimpan): NOP, nama wajib pajak, alamat, petugas.
   Ketuk **Ambil Alamat dari Lokasi Saat Ini** agar alamat terisi otomatis.
4. Pilih **status penerimaan surat**.
5. Ketuk **Foto Bukti**:
   - tunggu indikator GPS siap (akurasi tampil di bagian atas),
   - atur flash bila perlu, lalu ambil foto,
   - tinjau hasilnya, pilih **Gunakan** atau ulangi.
6. Isi nama penerima, telepon, dan catatan bila perlu.
7. Minta penerima **tanda tangan** di layar (opsional).
8. Ketuk **Simpan**. Bila NOP sudah pernah dicatat, aplikasi memberi peringatan.

### 3.4 Memakai Daftar Tugas
1. Buka **Daftar Tugas** dari Beranda.
2. Ketuk **Impor**, pilih berkas dari SIMPADA (.xlsx atau .csv).
3. Tugas terbagi tiga tab: **Belum**, **Ulang** (perlu kunjungan ulang), **Selesai**.
4. Ketuk **Rute** untuk membuka Google Maps menuju lokasi.
5. Ketuk **Mulai** (atau **Ulangi**) — form kunjungan terbuka dengan data sudah terisi dan terhubung ke tugas.
6. Setelah disimpan, tugas otomatis berpindah ke tab yang sesuai.

### 3.5 Melihat & mengelola riwayat
- Tab **Riwayat**: cari berdasarkan NOP/nama/alamat, saring dengan chip jenis pajak, status, petugas, atau tanggal.
- Geser item untuk aksi cepat; ketuk untuk membuka **Detail**.
- Di Detail: salin NOP/alamat, lihat peta, simpan foto ke galeri, bagikan foto, ubah, atau hapus.

### 3.6 Melihat statistik
Tab **Statistik** menampilkan rekap Mingguan/Bulanan: total, hari puncak, tingkat keberhasilan,
rincian per status dan jenis pajak, serta **Kinerja per Petugas**.

### 3.7 Mengekspor laporan
1. Buka menu **Ekspor**.
2. Pilih **rentang tanggal** dan **jenis pajak**.
3. Pilih format **Excel** atau **PDF**, centang **sertakan foto** bila diinginkan.
4. Lihat **pratinjau**, lalu ketuk **Buat & Bagikan** (kirim via WhatsApp, email, Drive, dll).

### 3.8 Cadangkan & pulihkan data
- Tab **Akun → Cadangkan Data**: menghasilkan satu berkas ZIP (data + foto). Simpan di tempat aman.
- **Pulihkan Data**: pilih berkas ZIP cadangan, misalnya saat ganti HP.

## 4. Izin yang Dibutuhkan

| Izin | Kegunaan |
|---|---|
| Kamera | Mengambil foto bukti |
| Lokasi (saat aplikasi dipakai) | Koordinat & alamat pada foto |
| Biometrik | Membuka kunci dengan sidik jari (jika diaktifkan) |
| Internet | Nama jalan, peta mini pada foto, dan peta di halaman detail |

Tanpa internet, foto tetap bisa diambil dan disimpan; hanya peta mini dan alamat otomatis yang tidak muncul
(alamat yang diketik di form tetap dipakai).

## 5. Teknologi

- **Flutter / Dart** (Material 3), target Android (minSdk 26)
- State management: **Provider**
- Database lokal: **SQLite** (`sqflite`)
- Lokasi & peta: `geolocator`, `geocoding`, `flutter_map`
- Kamera & berkas: `camera`, `file_picker`, `share_plus`, `gal`
- Laporan: `pdf`/`printing` dan penulis Excel (.xlsx) buatan sendiri
- Grafik: `fl_chart`; keamanan: `local_auth`, `crypto`

## 6. Struktur Proyek

```
lib/
  screens/    Layar: beranda, riwayat, input, kamera, detail, statistik, ekspor, tugas, akun, lock, dll
  services/   Database, foto geotag, lokasi, ekspor, impor, backup, auth
  providers/  State aplikasi (pengaturan, kunjungan, tugas)
  models/     Model data
  utils/      Konstanta, tema, format tanggal, helper
  widgets/    Komponen UI yang dipakai ulang
assets/       Logo aplikasi
android/      Konfigurasi Android
server/       Contoh server Flask (opsional, tidak dipakai di antarmuka aplikasi)
```

## 7. Menjalankan untuk Pengembang

```bash
flutter clean
flutter pub get
flutter run                   # HP Android tersambung / emulator
flutter build apk --release   # menghasilkan APK
```

Prasyarat: Flutter SDK, Android SDK, dan HP dengan mode pengembang + USB debugging aktif.

## 8. Kustomisasi

- `lib/utils/constants.dart` — kontak bantuan (`AppInfo.kontak*`), nama & warna jenis pajak.
- `lib/services/export_service.dart` — `kolomExcel` agar sesuai template resmi Bapenda.
- Logo PDF saat ini placeholder "SBY"; ganti dengan logo resmi.
- Logo aplikasi: `assets/images/logo.png`.

## 9. Keterbatasan Saat Ini

- Data tersimpan di perangkat; belum ada sinkronisasi cloud otomatis (gunakan Ekspor/Cadangan).
- Impor tugas bergantung pada format kolom berkas SIMPADA.

## 10. Pengembangan Selanjutnya

- Sinkronisasi ke Google Drive/Sheets
- Verifikasi bukti (hash + QR)
- OCR NOP dari foto surat
- Urutan rute terdekat & target harian per petugas

---

© Bapenda Kota Surabaya – UPTB Pelayanan Pajak Daerah Surabaya 5 · Proyek magang
