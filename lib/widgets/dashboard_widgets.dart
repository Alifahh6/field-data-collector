import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';

/// Cincin persen (mis. "67% berhasil").
class RingProgress extends StatelessWidget {
  final double nilai; // 0..1
  final String label;
  final double ukuran;
  const RingProgress({super.key, required this.nilai, required this.label, this.ukuran = 118});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(ukuran),
            painter: _RingPainter(nilai.clamp(0, 1), cs.primary, cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(nilai * 100).round()}%', style: tt.titleLarge?.copyWith(fontSize: 22)),
              Text(label, style: tt.bodySmall?.copyWith(fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double nilai;
  final Color warna;
  final Color latar;
  _RingPainter(this.nilai, this.warna, this.latar);

  @override
  void paint(Canvas canvas, Size size) {
    const tebal = 11.0;
    final rect = Rect.fromLTWH(tebal / 2, tebal / 2, size.width - tebal, size.height - tebal);
    final dasar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..color = latar;
    final isi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round
      ..color = warna;
    canvas.drawArc(rect, 0, math.pi * 2, false, dasar);
    if (nilai > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * nilai, false, isi);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.nilai != nilai || o.warna != warna || o.latar != latar;
}

/// Kotak angka kecil (Total / Diterima / Tertunda / Ditolak).
class MiniStat extends StatelessWidget {
  final int nilai;
  final String label;
  final Color warna;
  const MiniStat({super.key, required this.nilai, required this.label, required this.warna});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gelap = cs.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: gelap ? Colors.black.withValues(alpha: 0.18) : cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$nilai', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: warna)),
          Text(label, style: tt.bodySmall?.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Grafik batang berwarna per jenis pajak (jumlah di atas batang).
class KategoriBarChart extends StatelessWidget {
  final Map<String, int> counts; // id kategori -> jumlah
  final double tinggi;
  const KategoriBarChart({super.key, required this.counts, this.tinggi = 170});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maks = counts.values.fold<int>(0, math.max);
    final daftar = KategoriPajak.semua.where((k) => (counts[k.id] ?? 0) > 0).toList();
    if (daftar.isEmpty) {
      return SizedBox(
        height: 90,
        child: Center(child: Text('Belum ada kunjungan pada periode ini.', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
    return SizedBox(
      height: tinggi,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final k in daftar)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${counts[k.id]}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: 34,
                    height: math.max(8, (tinggi - 44) * (counts[k.id]! / maks)),
                    decoration: BoxDecoration(
                      color: k.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(k.singkat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Foto kecil kunjungan (atau ikon jenis pajak bila foto tidak ada).
class FotoKecil extends StatelessWidget {
  final String? path;
  final KategoriPajak kategori;
  final double ukuran;
  const FotoKecil({super.key, required this.path, required this.kategori, this.ukuran = 58});

  @override
  Widget build(BuildContext context) {
    final ada = path != null && File(path!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: ukuran,
        height: ukuran,
        color: kategori.color.withValues(alpha: 0.18),
        child: ada
            ? Image.file(File(path!), fit: BoxFit.cover, cacheWidth: 200, errorBuilder: (_, __, ___) => Icon(kategori.icon, color: kategori.color))
            : Icon(kategori.icon, color: kategori.color),
      ),
    );
  }
}

/// Chip kecil berwarna (jenis pajak) dengan titik atau tanpa ikon.
class PilKategori extends StatelessWidget {
  final KategoriPajak kategori;
  const PilKategori({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: kategori.color, borderRadius: BorderRadius.circular(8)),
        child: Text(kategori.singkat,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

/// Pil status (outline berwarna) untuk daftar.
class PilStatus extends StatelessWidget {
  final String status;
  const PilStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = StatusSurat.color(status);
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final teks = gelap ? Color.lerp(c, Colors.white, 0.35)! : c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.7)),
      ),
      child: Text(status, style: TextStyle(color: teks, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}
