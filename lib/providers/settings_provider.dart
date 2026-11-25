import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _p;

  bool onboardingSelesai = false;
  ThemeMode themeMode = ThemeMode.system;
  String namaPetugas = 'Petugas Lapangan';
  String nip = '';
  List<String> daftarPetugas = [];
  String? fotoProfilPath;
  bool kunciAktif = false;
  bool biometrikAktif = false;
  String formatFoto = 'jpg'; // 'jpg' | 'png'
  bool simpanGaleri = true;
  String serverUrl = '';
  String apiKey = '';
  bool autoKirim = true;

  bool get serverSiap => serverUrl.isNotEmpty && apiKey.isNotEmpty;

  Future<void> muat() async {
    final p = _p = await SharedPreferences.getInstance();
    onboardingSelesai = p.getBool('onboarding_selesai') ?? false;
    themeMode = ThemeMode.values[(p.getInt('theme_mode') ?? 0).clamp(0, 2)];
    namaPetugas = p.getString('nama_petugas') ?? 'Petugas Lapangan';
    nip = p.getString('nip') ?? '';
    daftarPetugas = p.getStringList('daftar_petugas') ?? [];
    fotoProfilPath = p.getString('foto_profil');
    if (fotoProfilPath != null && !File(fotoProfilPath!).existsSync()) fotoProfilPath = null;
    kunciAktif = p.getBool('kunci_aktif') ?? false;
    biometrikAktif = p.getBool('biometrik_aktif') ?? false;
    formatFoto = p.getString('format_foto') ?? 'jpg';
    simpanGaleri = p.getBool('simpan_galeri') ?? true;
    serverUrl = p.getString('server_url') ?? '';
    apiKey = p.getString('api_key') ?? '';
    autoKirim = p.getBool('auto_kirim') ?? true;
  }

  Future<void> setOnboardingSelesai() async {
    onboardingSelesai = true;
    await _p?.setBool('onboarding_selesai', true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await _p?.setInt('theme_mode', m.index);
    notifyListeners();
  }

  Future<void> setProfil({required String nama, required String nomorInduk}) async {
    namaPetugas = nama.trim().isEmpty ? 'Petugas Lapangan' : nama.trim();
    nip = nomorInduk.trim();
    await _p?.setString('nama_petugas', namaPetugas);
    await _p?.setString('nip', nip);
    notifyListeners();
  }

  Future<void> setFotoProfil(String? path) async {
    fotoProfilPath = path;
    if (path == null) {
      await _p?.remove('foto_profil');
    } else {
      await _p?.setString('foto_profil', path);
    }
    notifyListeners();
  }

  Future<void> setKunciAktif(bool v) async {
    kunciAktif = v;
    if (!v) biometrikAktif = false;
    await _p?.setBool('kunci_aktif', v);
    await _p?.setBool('biometrik_aktif', biometrikAktif);
    notifyListeners();
  }

  Future<void> setBiometrikAktif(bool v) async {
    biometrikAktif = v;
    await _p?.setBool('biometrik_aktif', v);
    notifyListeners();
  }

  Future<void> setFormatFoto(String v) async {
    formatFoto = v;
    await _p?.setString('format_foto', v);
    notifyListeners();
  }

  Future<void> setSimpanGaleri(bool v) async {
    simpanGaleri = v;
    await _p?.setBool('simpan_galeri', v);
    notifyListeners();
  }

  /// Petugas yang pernah dipakai di HP ini (untuk pilihan cepat di form).
  List<String> get pilihanPetugas {
    final hasil = <String>[];
    for (final n in [namaPetugas, ...daftarPetugas]) {
      final t = n.trim();
      if (t.isNotEmpty && !hasil.any((e) => e.toLowerCase() == t.toLowerCase())) hasil.add(t);
    }
    return hasil;
  }

  Future<void> catatPetugas(String nama) async {
    final t = nama.trim();
    if (t.isEmpty || pilihanPetugas.any((e) => e.toLowerCase() == t.toLowerCase())) return;
    daftarPetugas = [...daftarPetugas, t];
    await _p?.setStringList('daftar_petugas', daftarPetugas);
    notifyListeners();
  }

  Future<void> hapusPetugas(String nama) async {
    daftarPetugas = daftarPetugas.where((e) => e != nama).toList();
    await _p?.setStringList('daftar_petugas', daftarPetugas);
    notifyListeners();
  }

  Future<void> setServer(String url, String key) async {
    serverUrl = url.trim();
    apiKey = key.trim();
    await _p?.setString('server_url', serverUrl);
    await _p?.setString('api_key', apiKey);
    notifyListeners();
  }

  Future<void> setAutoKirim(bool v) async {
    autoKirim = v;
    await _p?.setBool('auto_kirim', v);
    notifyListeners();
  }
}
