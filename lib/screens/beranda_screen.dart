import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tugas_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/page_route.dart';
import '../widgets/charts.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import 'detail_kunjungan_screen.dart';
import 'input_kunjungan_screen.dart';
import 'statistik_screen.dart';
import 'tugas_screen.dart';

class BerandaScreen extends StatelessWidget {
  final VoidCallback onLihatRiwayat;
  const BerandaScreen({super.key, required this.onLihatRiwayat});

  void _kunjunganBaru(BuildContext context) =>
      Navigator.push(context, AppRoute(page: const InputKunjunganScreen()));

  @override
  Widget build(BuildContext context) {
    final k = context.watch<KunjunganProvider>();
    final s = context.watch<SettingsProvider>();
    final tugasItems = context.watch<TugasProvider>().items;
    final tt = Theme.of(context).textTheme;
    final sekarang = DateTime.now();

    final hariIni = k.pada(sekarang);
    final berhasil = hariIni.where((e) => StatusSurat.berhasil(e.status)).length;
    final tren = k.jumlahPerHari(sekarang, 7);
    final labelTren = [
      for (var i = 6; i >= 0; i--)
        DateFormatter.hariSingkat(DateTime(sekarang.year, sekarang.month, sekarang.day - i)),
    ];

    final ditolak = hariIni.where((e) => e.status == StatusSurat.ditolak).length;
    final tertunda = hariIni.length - berhasil - ditolak;
    final persen = hariIni.isEmpty ? 0.0 : berhasil / hariIni.length;
    final cs = Theme.of(context).colorScheme;
    final perJenis = KunjunganProvider.hitungKategori(k.antara(
        DateTime(sekarang.year, sekarang.month, sekarang.day - 6), DateTime(sekarang.year, sekarang.month, sekarang.day + 1)));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _kunjunganBaru(context),
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text('Kunjungan Baru'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Header (gaya bilah atas desain)
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 20),
            decoration: BoxDecoration(
              color: cs.brightness == Brightness.dark ? const Color(0xFF16296A) : AppColors.navy,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppInfo.instansi.toUpperCase().replaceFirst('KOTA ', ''),
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Beranda', style: tt.titleLarge?.copyWith(color: Colors.white, fontSize: 22)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary,
                  backgroundImage: s.fotoProfilPath == null ? null : FileImage(File(s.fotoProfilPath!)),
                  child: s.fotoProfilPath == null ? Icon(Icons.person_rounded, color: cs.onPrimary) : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${DateFormatter.sapaan()},', style: tt.bodyMedium),
                Text(s.namaPetugas, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.headlineSmall),
                const SizedBox(height: 2),
                Text('${AppInfo.unit}  •  ${DateFormatter.tanggalPanjang(sekarang)}', style: tt.bodySmall),
                const SizedBox(height: 16),

                // ---- Ringkasan hari ini
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Ringkasan Hari Ini', style: tt.titleMedium)),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Real-time', style: tt.bodySmall?.copyWith(fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          RingProgress(nilai: persen, label: 'berhasil'),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                Row(children: [
                                  Expanded(child: MiniStat(nilai: hariIni.length, label: 'Total', warna: cs.onSurface)),
                                  const SizedBox(width: 8),
                                  Expanded(child: MiniStat(nilai: berhasil, label: 'Diterima', warna: AppColors.success)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: MiniStat(nilai: tertunda, label: 'Tertunda', warna: AppColors.warning)),
                                  const SizedBox(width: 8),
                                  Expanded(child: MiniStat(nilai: ditolak, label: 'Ditolak', warna: cs.error)),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ---- Pintasan
                Row(
                  children: [
                    Expanded(
                      child: _Pintasan(
                        ikon: Icons.checklist_rounded,
                        judul: 'Daftar Tugas',
                        sub: tugasItems.isEmpty
                            ? 'Impor SIMPADA'
                            : '${tugasItems.where((t) {
                                final last = k.terakhirUntukNop(t.nop);
                                return last != null && StatusSurat.berhasil(last.status);
                              }).length}/${tugasItems.length} selesai',
                        onTap: () => Navigator.push(context, AppRoute(page: const TugasScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Pintasan(
                        ikon: Icons.bar_chart_rounded,
                        judul: 'Rekapitulasi',
                        sub: 'Statistik',
                        onTap: () => Navigator.push(context, AppRoute(page: const StatistikScreen())),
                      ),
                    ),
                  ],
                ),
                if (k.perluUlang.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.replay_circle_filled_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${k.perluUlang.length} objek pajak perlu dikunjungi ulang',
                            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // ---- Per jenis pajak
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Kunjungan per Jenis Pajak', style: tt.titleMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                            child: Text('7 hari', style: TextStyle(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      KategoriBarChart(counts: perJenis),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ---- Tren 7 hari
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tren 7 Hari Terakhir', style: tt.titleMedium),
                      const SizedBox(height: 14),
                      BarTrenChart(values: tren, labels: labelTren, height: 150),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ---- Kunjungan terakhir
                Row(
                  children: [
                    Expanded(child: Text('Kunjungan Terakhir', style: tt.titleMedium)),
                    if (k.terbaru.isNotEmpty)
                      TextButton(onPressed: onLihatRiwayat, child: const Text('Lihat semua >')),
                  ],
                ),
                const SizedBox(height: 6),
                if (k.terbaru.isEmpty)
                  EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada kunjungan',
                    message: 'Yuk mulai catat kunjungan pertama Anda!',
                    actionLabel: 'Mulai Catat',
                    onAction: () => _kunjunganBaru(context),
                    compact: true,
                  )
                else
                  for (final item in k.terbaru) _AktivitasTile(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pintasan extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String sub;
  final VoidCallback onTap;
  const _Pintasan({required this.ikon, required this.judul, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(ikon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall?.copyWith(fontSize: 14)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AktivitasTile extends StatelessWidget {
  final Kunjungan item;
  const _AktivitasTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final kat = KategoriPajak.dari(item.kategori);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => Navigator.push(context, AppRoute(page: DetailKunjunganScreen(kunjungan: item))),
        child: Row(
          children: [
            FotoKecil(path: item.fotoPath, kategori: kat),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.namaTampil, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall)),
                      Text(
                        DateFormatter.sameDay(item.waktu, DateTime.now()) ? DateFormatter.jam(item.waktu) : DateFormatter.tanggalPendek(item.waktu),
                        style: tt.bodySmall?.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.nopTampil,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoMono(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65))),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [PilKategori(kategori: kat), PilStatus(status: item.status)]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
