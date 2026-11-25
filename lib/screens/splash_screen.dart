import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/app_flow.dart';
import '../utils/constants.dart';
import '../utils/page_route.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2300), _lanjut);
  }

  void _lanjut() {
    if (!mounted) return;
    final s = context.read<SettingsProvider>();
    if (!s.onboardingSelesai) {
      Navigator.of(context).pushReplacement(AppRoute(page: const OnboardingScreen()));
    } else {
      AppFlow.masuk(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _anim, curve: const Interval(0, 0.6, curve: Curves.easeIn));
    const cyan = Color(0xFF4DD9E8);
    return Scaffold(
      backgroundColor: const Color(0xFF050F35),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.0,
            colors: [Color(0xFF123A7A), Color(0xFF071445), Color(0xFF050F35)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 22),
              FadeTransition(
                opacity: fade,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF55E39A), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('SISTEM INFORMASI PENDATAAN LAPANGAN',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: [BoxShadow(color: cyan.withValues(alpha: 0.30), blurRadius: 60, spreadRadius: 2)],
                    ),
                    child: Image.asset('assets/images/logo.png', width: 170, height: 170),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: fade,
                child: Column(
                  children: [
                    Text(AppInfo.namaAplikasi,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Bukti lapangan, rapi dan terverifikasi.',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 22),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_rounded, color: cyan, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(AppInfo.unit,
                                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                                Text('Badan Pendapatan Daerah ${AppInfo.instansi.replaceFirst('Bapenda ', '')}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) => LinearProgressIndicator(
                      minHeight: 5,
                      value: null,
                      color: cyan,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Menyiapkan aplikasi...', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 10),
              Text('v${AppInfo.versi}  •  Edisi Resmi Petugas Lapangan',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
