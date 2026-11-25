import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/kunjungan.dart';
import '../models/tugas.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class KunjunganProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Kunjungan> _items = [];
  bool loading = true;

  List<Kunjungan> get items => List.unmodifiable(_items);

  Future<void> muat() async {
    loading = true;
    notifyListeners();
    _items = await _db.getAll();
    loading = false;
    notifyListeners();
  }

  Future<void> tambah(Kunjungan k) async {
    final id = await _db.insert(k);
    _items.add(k.copyWith(id: id));
    _urutkan();
    notifyListeners();
  }

  Future<void> ubah(Kunjungan baru) async {
    await _db.update(baru);
    final i = _items.indexWhere((e) => e.id == baru.id);
    if (i >= 0) {
      final lama = _items[i];
      if (lama.fotoPath != null && lama.fotoPath != baru.fotoPath) {
        await _hapusFile(lama.fotoPath);
      }
      _items[i] = baru;
    }
    _urutkan();
    notifyListeners();
  }

  Future<void> hapus(Kunjungan k) async {
    if (k.id == null) return;
    await _db.delete(k.id!);
    _items.removeWhere((e) => e.id == k.id);
    await _hapusFile(k.fotoPath);
    notifyListeners();
  }

  Future<void> _hapusFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  void _urutkan() => _items.sort((a, b) => b.waktu.compareTo(a.waktu));

  /// Menandai kunjungan sudah terkirim ke server. Dilewati bila data diubah selagi dikirim
  /// (objek berbeda) agar perubahan itu ikut terkirim pada pengiriman berikutnya.
  Future<void> tandaiSinkron(Kunjungan k, String serverId) async {
    final i = _items.indexWhere((e) => e.id == k.id);
    if (i < 0 || !identical(_items[i], k)) return;
    final baru = k.copyWith(tersinkron: true, serverId: serverId);
    await _db.update(baru);
    _items[i] = baru;
    notifyListeners();
  }

  // ---------------------------------------------------------- Query/statistik
  bool get adaBelumSinkron => _items.any((e) => !e.tersinkron);

  List<Kunjungan> get terbaru => _items.take(3).toList();

  List<Kunjungan> pada(DateTime hari) =>
      _items.where((e) => DateFormatter.sameDay(e.waktu, hari)).toList();

  /// [mulai] termasuk, [akhirEksklusif] tidak termasuk.
  List<Kunjungan> antara(DateTime mulai, DateTime akhirEksklusif) => _items
      .where((e) => !e.waktu.isBefore(mulai) && e.waktu.isBefore(akhirEksklusif))
      .toList();

  /// Jumlah kunjungan per hari, urut dari terlama ke terbaru, berakhir di [akhir].
  List<int> jumlahPerHari(DateTime akhir, int hari) {
    final hasil = <int>[];
    for (var i = hari - 1; i >= 0; i--) {
      final d = DateTime(akhir.year, akhir.month, akhir.day - i);
      hasil.add(pada(d).length);
    }
    return hasil;
  }

  static Map<String, int> hitungStatus(List<Kunjungan> data) {
    final m = {for (final s in StatusSurat.semua) s: 0};
    for (final k in data) {
      m[k.status] = (m[k.status] ?? 0) + 1;
    }
    return m;
  }


  // ------------------------------------------------- Fitur tambahan
  /// Kunjungan terakhir untuk sebuah NOP (null jika belum pernah dikunjungi).
  Kunjungan? terakhirUntukNop(String nop, {int? kecualiId}) {
    final kunci = Tugas.normal(nop);
    if (kunci.isEmpty) return null;
    for (final k in _items) {
      if (k.id == kecualiId) continue;
      if (Tugas.normal(k.nop) == kunci) return k; // _items sudah urut terbaru
    }
    return null;
  }

  /// Objek pajak yang kunjungan terakhirnya belum berhasil (perlu didatangi lagi).
  List<Kunjungan> get perluUlang {
    final sudah = <String>{};
    final hasil = <Kunjungan>[];
    for (final k in _items) {
      final kunci = Tugas.normal(k.nop);
      if (!sudah.add(kunci)) continue;
      if (!StatusSurat.berhasil(k.status)) hasil.add(k);
    }
    return hasil;
  }

  static Map<String, int> hitungKategori(List<Kunjungan> data) {
    final m = <String, int>{};
    for (final k in data) {
      m[k.kategori] = (m[k.kategori] ?? 0) + 1;
    }
    return m;
  }

  static int maks(List<int> v) => v.fold(0, math.max);
}
