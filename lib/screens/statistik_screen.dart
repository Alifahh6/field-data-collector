import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kunjungan_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/charts.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  int _mode = 0; // 0 = mingguan, 1 = bulanan
  int _offset = 0; // 0 = periode berjalan, 1 = periode sebelumnya, dst.

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KunjunganProvider>();
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();

    late final List<int> nilai;
    late final List<String> label;
    late final DateTime mulai;
    late final DateTime akhirEks;
    late final String judulPeriode;

    if (_mode == 0) {
      final akhir = DateTime(now.year, now.month, now.day - _offset * 7);
      mulai = DateTime(akhir.year, akhir.month, akhir.day - 6);
      akhirEks = DateTime(akhir.year, akhir.month, akhir.day + 1);
      nilai = prov.jumlahPerHari(akhir, 7);
      label = [
        for (var i = 6; i >= 0; i--) DateFormatter.hariSingkat(DateTime(akhir.year, akhir.month, akhir.day - i)),
      ];
      judulPeriode = '${DateFormatter.tanggalPendek(mulai)} - ${DateFormatter.tanggalPendek(akhir)}';
    } else {
      final bulan = DateTime(now.year, now.month - _offset, 1);
      final jumlahHari = DateTime(bulan.year, bulan.month + 1, 0).day;
      mulai = bulan;
      akhirEks = DateTime(bulan.year, bulan.month + 1, 1);
      nilai = [for (var d = 1; d <= jumlahHari; d++) prov.pada(DateTime(bulan.year, bulan.month, d)).length];
      label = [for (var d = 1; d <= jumlahHari; d++) '$d'];
      judulPeriode = DateFormatter.bulanTahun(bulan);
    }

    final puncakNilai = nilai.fold<int>(0, (a, b) => b > a ? b : a);
    final puncakIdx = puncakNilai == 0 ? 0 : nilai.indexOf(puncakNilai);
    final data = prov.antara(mulai, akhirEks);
    final berhasil = data.where((e) => StatusSurat.berhasil(e.status)).length;
    final gagal = data.length - berhasil;
    final persen = data.isEmpty ? 0 : (berhasil * 100 / data.length).round();
    final status = KunjunganProvider.hitungStatus(data);
    final perKategori = KunjunganProvider.hitungKategori(data);
    final perPetugas = <String, List<int>>{}; // nama -> [total, berhasil]
    for (final k in data) {
      final n = k.petugas.isEmpty ? '(tanpa nama)' : k.petugas;
      final v = perPetugas.putIfAbsent(n, () => [0, 0]);
      v[0]++;
      if (StatusSurat.berhasil(k.status)) v[1]++;
    }
    final urutPetugas = perPetugas.entries.toList()..sort((a, b) => b.value[0].compareTo(a.value[0]));

    return Scaffold(
      appBar: AppBar(title: const Text('Rekapitulasi & Statistik')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.view_week_rounded), label: Text('Mingguan')),
                  ButtonSegment(value: 1, icon: Icon(Icons.calendar_month_rounded), label: Text('Bulanan')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _mode = s.first;
                  _offset = 0;
                }),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Periode sebelumnya',
                  onPressed: () => setState(() => _offset++),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(judulPeriode, textAlign: TextAlign.center, style: tt.titleMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Periode berikutnya',
                  onPressed: _offset == 0 ? null : () => setState(() => _offset--),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: StatCard(label: 'Total', value: data.length, icon: Icons.assignment_rounded, color: AppColors.navy)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(label: 'Berhasil', value: berhasil, icon: Icons.check_circle_rounded, color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(label: 'Gagal / Tertunda', value: gagal, icon: Icons.pending_actions_rounded, color: AppColors.warning)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Tingkat keberhasilan pengantaran', style: tt.bodyLarge)),
                  Text('$persen%', style: tt.titleLarge?.copyWith(color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_mode == 0 ? 'Kunjungan per Hari' : 'Kunjungan per Tanggal', style: tt.titleMedium),
                      ),
                      if (puncakNilai > 0)
                        Text('Puncak: ${label[puncakIdx]} ($puncakNilai)', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_mode == 0)
                    BarTrenChart(values: nilai, labels: label, height: 200)
                  else
                    LineTrenChart(values: nilai, labels: label, height: 220),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Breakdown Status Kunjungan', style: tt.titleMedium)),
                    Text('${data.length} Surat', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  if (data.isEmpty)
                    const SizedBox(
                      child: EmptyState(
                        compact: true,
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'Belum ada data',
                        message: 'Belum ada kunjungan pada periode ini.',
                      ),
                    )
                  else
                    StatusPieChart(counts: status),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('Breakdown per Jenis Pajak', style: tt.titleMedium)),
                    Text('${perKategori.length} Aktif', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  if (data.isEmpty)
                    const SizedBox(
                      child: EmptyState(
                        compact: true,
                        icon: Icons.donut_large_rounded,
                        title: 'Belum ada data',
                        message: 'Belum ada kunjungan pada periode ini.',
                      ),
                    )
                  else
                    KategoriPieChart(counts: perKategori),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kinerja per Petugas', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text('Jumlah surat yang diantar pada periode ini', style: tt.bodySmall),
                  const SizedBox(height: 12),
                  if (urutPetugas.isEmpty)
                    Text('Belum ada kunjungan pada periode ini.', style: tt.bodyMedium)
                  else
                    for (var i = 0; i < urutPetugas.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(urutPetugas[i].key,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyLarge),
                            ),
                            Text('${urutPetugas[i].value[0]} surat', style: tt.titleSmall),
                            const SizedBox(width: 8),
                            Text('${urutPetugas[i].value[1]} berhasil',
                                style: tt.bodySmall?.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
