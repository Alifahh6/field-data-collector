import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF1B2F7E); // biru tua (indigo) - dasar gradasi
  static const teal = Color(0xFF1596A8); // warna utama (tombol, ikon aktif)
  static const tealMuda = Color(0xFF35B6C4); // sisi terang gradasi header
  static const lightBlue = Color(0xFFDDF3F6);
  static const success = Color(0xFF2E8B57);
  static const warning = Color(0xFFD98A2B);
  static const error = Color(0xFFC0392B);
  static const background = Color(0xFFF4F8FA);
  static const info = Color(0xFF2F7FD0);
  static const neutral = Color(0xFF5C6B80);
}

class AppInfo {
  static const namaAplikasi = 'Field Data Collector';
  static const versi = '1.0.0';
  static const instansi = 'Bapenda Kota Surabaya';
  static const unit = 'UPTB Pelayanan Pajak Daerah Surabaya 5';
  static const kontakNama = 'Admin UPTB Pelayanan Pajak Daerah Surabaya 5';
  static const kontakTelepon = '(031) 5941436';
  static const kontakEmail = 'bapenda.surabaya.go.id';
}

/// Daftar status penerimaan surat + warna & ikonnya.
class StatusSurat {
  static const diterimaLangsung = 'Diterima Langsung';
  static const kotakPos = 'Kotak Pos';
  static const tidakAdaOrang = 'Tidak Ada Orang';
  static const alamatTidakDitemukan = 'Alamat Tidak Ditemukan';
  static const ditolak = 'Ditolak';

  static const semua = [
    diterimaLangsung,
    kotakPos,
    tidakAdaOrang,
    alamatTidakDitemukan,
    ditolak,
  ];

  /// Surat dianggap "berhasil" jika sudah sampai ke wajib pajak / kotak pos.
  static bool berhasil(String s) => s == diterimaLangsung || s == kotakPos;

  static Color color(String s) {
    switch (s) {
      case diterimaLangsung:
        return AppColors.success;
      case kotakPos:
        return AppColors.info;
      case tidakAdaOrang:
        return AppColors.warning;
      case alamatTidakDitemukan:
        return AppColors.neutral;
      case ditolak:
        return AppColors.error;
      default:
        return AppColors.neutral;
    }
  }

  static IconData icon(String s) {
    switch (s) {
      case diterimaLangsung:
        return Icons.how_to_reg_rounded;
      case kotakPos:
        return Icons.markunread_mailbox_rounded;
      case tidakAdaOrang:
        return Icons.person_off_rounded;
      case alamatTidakDitemukan:
        return Icons.wrong_location_rounded;
      case ditolak:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

/// Jenis pajak daerah. Setiap jenis punya warna sendiri agar mudah dikelompokkan
/// (dipakai di badge, kartu riwayat, grafik, kotak alamat pada foto, dan ekspor).
class KategoriPajak {
  final String id;
  final String label;
  final String singkat;
  final int hex; // 0xRRGGBB
  final IconData icon;
  final List<String> kataKunci;

  const KategoriPajak(this.id, this.label, this.singkat, this.hex, this.icon, this.kataKunci);

  Color get color => Color(0xFF000000 | hex);

  static const pbb = KategoriPajak('pbb', 'Pajak PBB', 'PBB', 0x2563C9, Icons.home_work_rounded, ['PBB', 'BUMI DAN BANGUNAN', 'SPPT']);
  static const restoran = KategoriPajak('restoran', 'Pajak Restoran', 'Restoran', 0xEF6C00, Icons.restaurant_rounded, ['RESTORAN', 'RESTO', 'RUMAH MAKAN', 'CAFE', 'KAFE', 'KATERING']);
  static const hotel = KategoriPajak('hotel', 'Pajak Hotel', 'Hotel', 0x7B3FB5, Icons.hotel_rounded, ['HOTEL', 'PENGINAPAN', 'HOMESTAY', 'KOS', 'VILLA']);
  static const hiburan = KategoriPajak('hiburan', 'Pajak Hiburan', 'Hiburan', 0xD81B60, Icons.theater_comedy_rounded, ['HIBURAN', 'KARAOKE', 'DISKOTIK', 'BILLYARD', 'BILIARD', 'PERTUNJUKAN', 'BIOSKOP', 'KLUB MALAM']);
  static const parkir = KategoriPajak('parkir', 'Pajak Parkir', 'Parkir', 0x6D4C41, Icons.local_parking_rounded, ['PARKIR']);
  static const reklame = KategoriPajak('reklame', 'Pajak Reklame', 'Reklame', 0xB8860B, Icons.campaign_rounded, ['REKLAME', 'BILLBOARD', 'VIDEOTRON']);
  static const airTanah = KategoriPajak('air_tanah', 'Pajak Air Tanah', 'Air Tanah', 0x0097A7, Icons.water_drop_rounded, ['AIR TANAH']);
  static const ppj = KategoriPajak('ppj', 'Pajak Penerangan Jalan', 'PPJ', 0x546E7A, Icons.lightbulb_rounded, ['PENERANGAN', 'PPJ']);
  static const lainnya = KategoriPajak('lainnya', 'Pajak Lainnya', 'Lainnya', 0x757575, Icons.category_rounded, []);

  static const semua = [pbb, restoran, hotel, hiburan, parkir, reklame, airTanah, ppj, lainnya];

  static KategoriPajak dari(String? id) =>
      semua.firstWhere((k) => k.id == id, orElse: () => lainnya);

  /// Menebak jenis pajak dari teks bebas (mis. kolom "Jenis Pajak" hasil ekspor SIMPADA).
  static KategoriPajak? cocok(String teks) {
    final t = teks.toUpperCase();
    if (t.trim().isEmpty) return null;
    const urutan = [airTanah, parkir, reklame, hotel, restoran, hiburan, ppj, pbb];
    for (final k in urutan) {
      for (final kata in k.kataKunci) {
        if (t.contains(kata)) return k;
      }
    }
    return null;
  }
}
