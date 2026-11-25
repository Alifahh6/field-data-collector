import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum GpsStatus { ok, layananMati, izinDitolak, izinDitolakPermanen, lemah, gagal }

class LokasiHasil {
  final Position? posisi;
  final String? alamat; // ringkas, untuk kolom alamat di form
  final String? alamatLengkap; // lengkap, untuk overlay foto
  final String? judul; // mis. "Kecamatan Gubeng, Jawa Timur, Indonesia"
  final GpsStatus status;
  const LokasiHasil({this.posisi, this.alamat, this.alamatLengkap, this.judul, required this.status});

  String get koordinatTeks => posisi == null
      ? '-'
      : '${posisi!.latitude.toStringAsFixed(6)}, ${posisi!.longitude.toStringAsFixed(6)}';
}

class _Geo {
  final String alamat;
  final String lengkap;
  final String judul;
  const _Geo(this.alamat, this.lengkap, this.judul);
}

class LocationService {
  static const _userAgent = 'FieldDataCollector/1.0 (Bapenda Surabaya)';

  /// Cek GPS aktif & izin lokasi (meminta izin bila belum ada).
  static Future<GpsStatus> periksaIzin() async {
    if (!await Geolocator.isLocationServiceEnabled()) return GpsStatus.layananMati;
    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied) return GpsStatus.izinDitolak;
    if (izin == LocationPermission.deniedForever) return GpsStatus.izinDitolakPermanen;
    return GpsStatus.ok;
  }

  static Future<LokasiHasil> ambilLokasiSaatIni() async {
    final izin = await periksaIzin();
    if (izin != GpsStatus.ok) return LokasiHasil(status: izin);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return _lengkapi(pos, pos.accuracy > 50 ? GpsStatus.lemah : GpsStatus.ok);
    } on TimeoutException {
      final terakhir = await Geolocator.getLastKnownPosition();
      if (terakhir != null) return _lengkapi(terakhir, GpsStatus.lemah);
      return const LokasiHasil(status: GpsStatus.gagal);
    } catch (_) {
      return const LokasiHasil(status: GpsStatus.gagal);
    }
  }

  static Future<LokasiHasil> _lengkapi(Position pos, GpsStatus status) async {
    final geo = await _alamatDariKoordinat(pos.latitude, pos.longitude);
    return LokasiHasil(
      posisi: pos,
      alamat: geo?.alamat,
      alamatLengkap: geo?.lengkap,
      judul: geo?.judul,
      status: status,
    );
  }

  /// Reverse geocoding: coba Geocoder Android dulu, lalu OpenStreetMap (Nominatim). Butuh internet.
  static Future<_Geo?> _alamatDariKoordinat(double lat, double lng) async {
    final a = await _geocoderAndroid(lat, lng);
    if (a != null) return a;
    return _nominatim(lat, lng);
  }

  static List<String> _unik(Iterable<String?> data) {
    final hasil = <String>[];
    for (final s in data) {
      final v = (s ?? '').trim();
      if (v.isNotEmpty && !hasil.contains(v)) hasil.add(v);
    }
    return hasil;
  }

  static Future<_Geo?> _geocoderAndroid(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 8));
      if (list.isEmpty) return null;
      final pm = list.first;
      final ringkas = _unik([pm.street, pm.subLocality, pm.locality, pm.subAdministrativeArea]);
      final lengkap = _unik([
        pm.street,
        pm.subLocality,
        pm.locality,
        pm.subAdministrativeArea,
        pm.administrativeArea,
        pm.postalCode,
        pm.country,
      ]);
      final judul = _unik([
        pm.locality?.isNotEmpty == true ? pm.locality : pm.subAdministrativeArea,
        pm.administrativeArea,
        pm.country,
      ]);
      if (lengkap.isEmpty) return null;
      return _Geo(ringkas.join(', '), lengkap.join(', '), judul.join(', '));
    } catch (_) {
      return null;
    }
  }

  static Future<_Geo?> _nominatim(double lat, double lng) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&zoom=18&accept-language=id&lat=$lat&lon=$lng');
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', _userAgent);
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      client.close();
      final j = jsonDecode(body) as Map<String, dynamic>;
      final display = (j['display_name'] as String?) ?? '';
      if (display.isEmpty) return null;
      final a = (j['address'] as Map?)?.cast<String, dynamic>() ?? {};
      final jalan = _unik([a['road'] as String?, a['house_number'] as String?]).join(' ');
      final ringkas = _unik([
        jalan,
        (a['suburb'] ?? a['village']) as String?,
        (a['city_district'] ?? a['county']) as String?,
        (a['city'] ?? a['town']) as String?,
      ]);
      final judul = _unik([
        (a['city_district'] ?? a['suburb'] ?? a['city']) as String?,
        a['state'] as String?,
        a['country'] as String?,
      ]);
      return _Geo(ringkas.isEmpty ? display : ringkas.join(', '), display, judul.join(', '));
    } catch (_) {
      return null;
    }
  }

  static String pesan(GpsStatus s) {
    switch (s) {
      case GpsStatus.layananMati:
        return 'GPS di HP Anda belum aktif. Yuk nyalakan GPS (Lokasi) agar titik kunjungan tercatat.';
      case GpsStatus.izinDitolak:
        return 'Aplikasi butuh izin lokasi untuk mencatat titik kunjungan. Silakan izinkan saat diminta.';
      case GpsStatus.izinDitolakPermanen:
        return 'Izin lokasi sedang ditolak. Buka Pengaturan > Izin untuk mengaktifkannya.';
      case GpsStatus.lemah:
        return 'Sinyal GPS masih lemah. Coba pindah ke area terbuka dan tunggu beberapa detik.';
      case GpsStatus.gagal:
        return 'Lokasi belum berhasil didapat. Pastikan GPS aktif lalu coba lagi.';
      case GpsStatus.ok:
        return 'GPS siap digunakan.';
    }
  }

  static Future<void> bukaPengaturan(GpsStatus s) async {
    if (s == GpsStatus.layananMati) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
