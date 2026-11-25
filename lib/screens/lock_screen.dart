import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  /// Dipanggil saat PIN / biometrik berhasil.
  final void Function(BuildContext context) onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  static const _panjangPin = 4;
  final _auth = AuthService();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  String _pin = '';
  String? _error;
  bool _biometrikSiap = false;

  @override
  void initState() {
    super.initState();
    _initBiometrik();
  }

  Future<void> _initBiometrik() async {
    final aktif = context.read<SettingsProvider>().biometrikAktif;
    if (!aktif) return;
    final tersedia = await _auth.biometrikTersedia();
    if (!mounted) return;
    setState(() => _biometrikSiap = tersedia);
    if (tersedia) _cobaBiometrik();
  }

  Future<void> _cobaBiometrik() async {
    final ok = await _auth.autentikasiBiometrik();
    if (ok && mounted) widget.onUnlocked(context);
  }

  void _ketuk(String d) {
    if (_pin.length >= _panjangPin) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == _panjangPin) _verifikasi();
  }

  void _hapus() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifikasi() async {
    final ok = await _auth.cekPin(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked(context);
    } else {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _pin = '';
        _error = 'PIN salah, silakan coba lagi';
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, size: 42, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text('Aplikasi Terkunci', style: tt.headlineSmall),
              const SizedBox(height: 6),
              Text('Masukkan PIN untuk melanjutkan', style: tt.bodyLarge),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) => Transform.translate(
                  offset: Offset(math.sin(_shake.value * math.pi * 6) * 12 * (1 - _shake.value), 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _panjangPin; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 9),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length ? cs.primary : Colors.transparent,
                          border: Border.all(color: _error != null ? cs.error : cs.primary, width: 2),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: Center(
                  child: Text(_error ?? '', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(),
              _keypad(cs),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypad(ColorScheme cs) {
    Widget tombol(String d) => _Tombol(onTap: () => _ketuk(d), child: Text(d, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)));
    Widget baris(List<Widget> c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: c),
        );
    return Column(
      children: [
        baris([tombol('1'), tombol('2'), tombol('3')]),
        baris([tombol('4'), tombol('5'), tombol('6')]),
        baris([tombol('7'), tombol('8'), tombol('9')]),
        baris([
          _biometrikSiap
              ? _Tombol(onTap: _cobaBiometrik, child: Icon(Icons.fingerprint_rounded, size: 34, color: cs.primary))
              : const SizedBox(width: 84, height: 72),
          tombol('0'),
          _Tombol(onTap: _hapus, child: const Icon(Icons.backspace_rounded, size: 28)),
        ]),
      ],
    );
  }
}

class _Tombol extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Tombol({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 74,
        height: 74,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: CircleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}
