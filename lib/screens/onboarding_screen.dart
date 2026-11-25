import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/app_flow.dart';
import '../widgets/custom_button.dart';

class _Slide {
  final IconData icon;
  final String judul;
  final String isi;
  final String tag;
  const _Slide(this.icon, this.judul, this.isi, this.tag);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(Icons.edit_note_rounded, 'Catat Kunjungan dengan Mudah',
        'Isi NOP, nama wajib pajak, dan status penerimaan surat langsung dari HP. Tanpa kertas, tanpa buku catatan.', 'SPPT PBB'),
    _Slide(Icons.photo_camera_rounded, 'Foto Bukti + Lokasi Otomatis',
        'Ambil foto langsung dari aplikasi. Koordinat GPS, nama jalan, dan waktu otomatis tertera di foto sebagai bukti.', 'GEOTAG'),
    _Slide(Icons.ios_share_rounded, 'Rekap & Ekspor Laporan',
        'Lihat riwayat dan statistik, lalu ekspor ke Excel atau PDF dan bagikan lewat WhatsApp atau Email.', 'EKSPOR'),
  ];

  Future<void> _selesai() async {
    await context.read<SettingsProvider>().setOnboardingSelesai();
    if (!mounted) return;
    AppFlow.masuk(context);
  }

  void _lanjut() {
    if (_index == _slides.length - 1) {
      _selesai();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final terakhir = _index == _slides.length - 1;
    final gelap = cs.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: gelap ? const Color(0xFF050F35) : null,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: terakhir ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                  child: Material(
                    color: cs.surface,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: terakhir ? null : _selesai,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Lewati >', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: ValueKey(i),
                          tween: Tween(begin: 0.85, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          builder: (context, v, child) => Transform.scale(scale: v, child: child),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border(top: BorderSide(color: cs.primary.withValues(alpha: 0.7), width: 2)),
                              boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 14))],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _PilKecil(icon: Icons.verified_rounded, teks: 'UPTB SURABAYA 5', cs: cs),
                                    _PilKecil(icon: Icons.circle, teks: s.tag, cs: cs, ikonKecil: true),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
                                  child: Icon(s.icon, size: 62, color: cs.primary),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.shield_outlined, size: 16, color: cs.primary),
                                      const SizedBox(width: 6),
                                      Text('Siap tanpa internet', style: tt.bodySmall?.copyWith(fontSize: 12.5)),
                                    ]),
                                    Text('Bapenda SBY', style: tt.bodySmall?.copyWith(fontSize: 12.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(s.judul, textAlign: TextAlign.center, style: tt.headlineSmall?.copyWith(fontSize: 22)),
                        const SizedBox(height: 12),
                        Text(
                          s.isi,
                          textAlign: TextAlign.center,
                          style: tt.bodyLarge?.copyWith(height: 1.5, color: cs.onSurface.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _index ? cs.primary : cs.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: CustomButton(
                label: terakhir ? 'Mulai Sekarang' : 'Lanjut',
                icon: terakhir ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                onPressed: _lanjut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PilKecil extends StatelessWidget {
  final IconData icon;
  final String teks;
  final ColorScheme cs;
  final bool ikonKecil;
  const _PilKecil({required this.icon, required this.teks, required this.cs, this.ikonKecil = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ikonKecil ? 9 : 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(teks, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ],
        ),
      );
}
