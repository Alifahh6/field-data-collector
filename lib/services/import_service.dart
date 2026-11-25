import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../models/tugas.dart';
import '../utils/constants.dart';

class HasilImpor {
  final List<Tugas> data;
  final int terdeteksi; // jumlah baris yang jenis pajaknya terdeteksi otomatis
  final String? pesan; // dipakai bila gagal
  const HasilImpor(this.data, this.terdeteksi, {this.pesan});
}

/// Membaca daftar objek pajak dari CSV atau XLSX (mis. hasil ekspor SIMPADA).
class ImportService {
  static Future<HasilImpor> baca(String path, KategoriPajak kategoriDefault) async {
    final ext = path.toLowerCase().split('.').last;
    List<List<String>> tabel;
    try {
      if (ext == 'csv' || ext == 'txt') {
        tabel = _parseCsv(utf8.decode(await File(path).readAsBytes(), allowMalformed: true));
      } else if (ext == 'xlsx') {
        tabel = _parseXlsx(await File(path).readAsBytes());
      } else {
        return const HasilImpor([], 0, pesan: 'Format belum didukung. Gunakan .xlsx atau .csv (simpan ulang dari Excel bila file .xls).');
      }
    } catch (_) {
      return const HasilImpor([], 0, pesan: 'File tidak dapat dibaca. Pastikan formatnya .xlsx atau .csv yang benar.');
    }
    return _petakan(tabel, kategoriDefault);
  }

  // ---------------------------------------------------------------- pemetaan
  static HasilImpor _petakan(List<List<String>> tabel, KategoriPajak kategoriDefault) {
    // Cari baris header: baris pertama yang memuat kata "nop".
    var h = -1;
    for (var i = 0; i < tabel.length && i < 15; i++) {
      if (tabel[i].any((c) => c.toLowerCase().trim() == 'nop' || c.toLowerCase().contains('nop'))) {
        h = i;
        break;
      }
    }
    if (h < 0) {
      return const HasilImpor([], 0, pesan: 'Kolom "NOP" tidak ditemukan. Pastikan baris judul memuat kata NOP.');
    }
    final head = tabel[h].map((e) => e.toLowerCase().trim()).toList();
    int cari(bool Function(String) f, [int mulai = 0]) {
      for (var i = mulai; i < head.length; i++) {
        if (f(head[i])) return i;
      }
      return -1;
    }

    final cNop = cari((s) => s.contains('nop'));
    final cNama = cari((s) => s.contains('nama'), cNop + 1) >= 0 ? cari((s) => s.contains('nama'), cNop + 1) : cari((s) => s.contains('nama'));
    final cAlamat = cari((s) => s.contains('alamat'));
    final cJenis = <int>[
      for (var i = 0; i < head.length; i++)
        if (head[i].contains('jenis') || head[i].contains('kategori') || head[i] == 'pajak' || head[i].contains('nama pajak')) i,
    ];

    String ambil(List<String> r, int c) => (c >= 0 && c < r.length) ? r[c].trim() : '';

    final hasil = <Tugas>[];
    var terdeteksi = 0;
    for (var i = h + 1; i < tabel.length; i++) {
      final r = tabel[i];
      final nop = ambil(r, cNop);
      if (nop.isEmpty) continue;
      var kat = KategoriPajak.cocok([for (final c in cJenis) ambil(r, c)].join(' '));
      kat ??= KategoriPajak.cocok(r.join(' '));
      if (kat != null) terdeteksi++;
      hasil.add(Tugas(
        kategori: (kat ?? kategoriDefault).id,
        nop: nop,
        nama: ambil(r, cNama),
        alamat: ambil(r, cAlamat),
      ));
    }
    if (hasil.isEmpty) {
      return const HasilImpor([], 0, pesan: 'Tidak ada baris data yang bisa dibaca di bawah judul kolom.');
    }
    return HasilImpor(hasil, terdeteksi);
  }

  // ------------------------------------------------------------------- CSV
  static List<List<String>> _parseCsv(String teks) {
    final baris = teks.split('\n');
    final pertama = baris.isEmpty ? '' : baris.first;
    final pemisah = (';'.allMatches(pertama).length > ','.allMatches(pertama).length) ? ';' : ',';
    final hasil = <List<String>>[];
    var row = <String>[];
    final sb = StringBuffer();
    var kutip = false;
    for (var i = 0; i < teks.length; i++) {
      final c = teks[i];
      if (kutip) {
        if (c == '"') {
          if (i + 1 < teks.length && teks[i + 1] == '"') {
            sb.write('"');
            i++;
          } else {
            kutip = false;
          }
        } else {
          sb.write(c);
        }
      } else if (c == '"') {
        kutip = true;
      } else if (c == pemisah) {
        row.add(sb.toString());
        sb.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < teks.length && teks[i + 1] == '\n') i++;
        row.add(sb.toString());
        sb.clear();
        if (row.any((e) => e.trim().isNotEmpty)) hasil.add(row);
        row = <String>[];
      } else {
        sb.write(c);
      }
    }
    if (sb.isNotEmpty || row.isNotEmpty) {
      row.add(sb.toString());
      if (row.any((e) => e.trim().isNotEmpty)) hasil.add(row);
    }
    return hasil;
  }

  // ------------------------------------------------------------------ XLSX
  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
      .replaceAll('&amp;', '&');

  static int _kolomIndex(String huruf) {
    var n = 0;
    for (final c in huruf.codeUnits) {
      n = n * 26 + (c - 64);
    }
    return n - 1;
  }

  static List<List<String>> _parseXlsx(List<int> bytes) {
    final arsip = ZipDecoder().decodeBytes(bytes);
    String? baca(String nama) {
      for (final f in arsip) {
        if (f.isFile && f.name == nama) return utf8.decode(f.content as List<int>, allowMalformed: true);
      }
      return null;
    }

    // shared strings
    final shared = <String>[];
    final ss = baca('xl/sharedStrings.xml');
    if (ss != null) {
      for (final m in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(ss)) {
        final sb = StringBuffer();
        for (final t in RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).allMatches(m[1]!)) {
          sb.write(_unescape(t[1]!));
        }
        shared.add(sb.toString());
      }
    }

    // sheet pertama
    final namaSheet = arsip
        .where((f) => f.isFile && RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name))
        .map((f) => f.name)
        .toList()
      ..sort();
    if (namaSheet.isEmpty) throw Exception('sheet tidak ditemukan');
    final xml = baca(namaSheet.first)!;

    final peta = <int, Map<int, String>>{};
    for (final m in RegExp(r'<c\s+([^>]*?)(?:/>|>(.*?)</c>)', dotAll: true).allMatches(xml)) {
      final attr = m[1]!;
      final isi = m[2] ?? '';
      final ref = RegExp(r'r="([A-Z]+)(\d+)"').firstMatch(attr);
      if (ref == null) continue;
      final tipe = RegExp(r't="(\w+)"').firstMatch(attr)?[1];
      String nilai = '';
      if (tipe == 'inlineStr') {
        nilai = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).allMatches(isi).map((e) => _unescape(e[1]!)).join();
      } else {
        final v = RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(isi)?[1] ?? '';
        if (tipe == 's') {
          final idx = int.tryParse(v);
          nilai = (idx != null && idx < shared.length) ? shared[idx] : '';
        } else {
          nilai = _unescape(v);
        }
      }
      final r = int.parse(ref[2]!) - 1;
      peta.putIfAbsent(r, () => {})[_kolomIndex(ref[1]!)] = nilai;
    }
    final hasil = <List<String>>[];
    final urut = peta.keys.toList()..sort();
    for (final r in urut) {
      final kolom = peta[r]!;
      final maks = kolom.keys.reduce((a, b) => a > b ? a : b);
      hasil.add([for (var c = 0; c <= maks; c++) kolom[c] ?? '']);
    }
    return hasil;
  }
}
