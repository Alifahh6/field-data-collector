import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PIN (disimpan sebagai hash) + biometrik (sidik jari / face unlock).
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const _kPin = 'pin_hash';
  static const _salt = 'bapenda-sby5-fdc';

  String _hash(String pin) => sha256.convert(utf8.encode('$_salt$pin')).toString();

  Future<void> simpanPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPin, _hash(pin));
  }

  Future<bool> cekPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPin) == _hash(pin);
  }

  Future<void> hapusPin() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPin);
  }

  Future<bool> biometrikTersedia() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autentikasiBiometrik() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka kunci aplikasi untuk melihat data wajib pajak',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
