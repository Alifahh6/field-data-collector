import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/kunjungan.dart';
import '../models/tugas.dart';

class SyncException implements Exception {
  final String pesan;
  SyncException(this.pesan);
  @override
  String toString() => pesan;
}

/// Mengirim data kunjungan + foto + tanda tangan ke server (web/aplikasi kantor) lewat REST API.
///
/// Kontrak API (lihat folder server/ untuk contoh implementasinya):
///   GET  {url}/api/ping                 header X-API-Key
///   POST {url}/api/kunjungan            header X-API-Key, multipart:
///        field `data`  = JSON (client_id, kategori, nop, nama_wp, alamat, status, nama_penerima, telepon,
///                        catatan, latitude, longitude, waktu, petugas)
///        file  `foto`  = foto bukti (jpg/png)      [opsional]
///        file  `ttd`   = tanda tangan penerima png [opsional]
///        balasan JSON: {"ok": true, "id": "id di server"}
///   Kirim ulang dengan client_id yang sama = memperbarui data (tidak dobel).
class SyncService {
  static String normalUrl(String u) {
    var s = u.trim();
    if (s.isEmpty) return '';
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// ID unik & stabil per kunjungan (sama setiap kali dikirim) agar server tidak membuat data ganda.
  static String clientId(Kunjungan k) {
    final mentah = '${k.petugas}|${k.waktu.toIso8601String()}|${Tugas.normal(k.nop)}';
    return sha256.convert(utf8.encode(mentah)).toString().substring(0, 24);
  }

  static SyncException _galat(Object e) {
    if (e is SyncException) return e;
    if (e is TimeoutException) {
      return SyncException('Server tidak menjawab. Pastikan HP dan komputer satu Wi-Fi.');
    }
    if (e is SocketException || e is http.ClientException) {
      return SyncException('Tidak bisa terhubung ke server. Periksa alamat dan Wi-Fi.');
    }
    if (e is FormatException) {
      return SyncException('Alamat tidak valid atau bukan server Field Data Collector.');
    }
    return SyncException('Koneksi gagal.');
  }

  /// Tes koneksi. Mengembalikan nama server bila berhasil.
  static Future<String> tes(String url, String key) async {
    try {
      final res = await http
          .get(Uri.parse('${normalUrl(url)}/api/ping'), headers: {'X-API-Key': key.trim()})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 401) throw SyncException('API key salah.');
      if (res.statusCode != 200) throw SyncException('Server menjawab kode ${res.statusCode}.');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['nama'] as String?) ?? 'Server';
    } catch (e) {
      throw _galat(e);
    }
  }

  /// Mengirim satu kunjungan. Mengembalikan ID di server.
  static Future<String> kirim(Kunjungan k, String url, String key) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('${normalUrl(url)}/api/kunjungan'));
      req.headers['X-API-Key'] = key.trim();
      req.fields['data'] = jsonEncode({
        'client_id': clientId(k),
        'kategori': k.kategori,
        'nop': k.nop,
        'nama_wp': k.namaWp,
        'alamat': k.alamat,
        'status': k.status,
        'nama_penerima': k.namaPenerima,
        'telepon': k.telepon,
        'catatan': k.catatan,
        'latitude': k.latitude,
        'longitude': k.longitude,
        'waktu': k.waktu.toIso8601String(),
        'petugas': k.petugas,
      });
      if (k.fotoPath != null && File(k.fotoPath!).existsSync()) {
        req.files.add(await http.MultipartFile.fromPath('foto', k.fotoPath!));
      }
      if (k.ttdPath != null && File(k.ttdPath!).existsSync()) {
        req.files.add(await http.MultipartFile.fromPath('ttd', k.ttdPath!));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 401) throw SyncException('API key salah.');
      if (res.statusCode == 413) throw SyncException('Foto terlalu besar untuk server.');
      if (res.statusCode != 200) throw SyncException('Server menolak data (kode ${res.statusCode}).');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['ok'] != true) throw SyncException((j['pesan'] as String?) ?? 'Server menolak data.');
      return (j['id'] ?? '').toString();
    } catch (e) {
      throw _galat(e);
    }
  }
}
