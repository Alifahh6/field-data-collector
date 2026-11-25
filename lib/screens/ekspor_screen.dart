import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';
import '../widgets/stat_card.dart';

class EksporScreen extends StatefulWidget {
  const EksporScreen({super.key});

  @override
  State<EksporScreen> createState() => _EksporScreenState();
}

class _EksporScreenState extends State<EksporScreen> {
  int _preset = 2; // 0 hari ini, 1 tujuh hari, 2 bulan ini, 3 kustom
  late DateTimeRange _range = _hitung(2);
  String? _kategori; // null = semua jenis pajak
  bool _sertakanFoto = true;
  bool _formatPdf = false;
  bool _excelLoading = false;
  bool _pdfLoading = false;
  File? _hasil;
  bool _hasilPdf = false;

  DateTimeRange _hitung(int preset) {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case 0:
        return DateTimeRange(start: hariIni, end: hariIni);
      case 1:
        return DateTimeRange(start: hariIni.subtract(const Duration(days: 6)), end: hariIni);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: hariIni);
    }
  }

  Future<void> _pilihPreset(int i) async {
    if (i == 3) {
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        initialDateRange: _range,
        locale: const Locale('id', 'ID'),
        helpText: 'Pilih rentang tanggal',
        saveText: 'Pilih',
      );
      if (r == null) return;
      setState(() {
        _preset = 3;
        _range = DateTimeRange(start: DateFormatter.awalHari(r.start), end: DateFormatter.awalHari(r.end));
        _hasil = null;
      });
    } else {
      setState(() {
        _preset = i;
        _range = _hitung(i);
        _hasil = null;
      });
    }
  }

  List<Kunjungan> _data(KunjunganProvider prov) => prov
      .antara(_range.start, DateFormatter.hariBerikutnya(_range.end))
      .where((k) => _kategori == null || k.kategori == _kategori)
      .toList();

  Future<void> _ekspor({required bool pdf, bool langsungBagikan = false}) async {
    final prov = context.read<KunjunganProvider>();
    final petugas = context.read<SettingsProvider>().namaPetugas;
    final data = _data(prov);
    if (data.isEmpty) {
      AppSnack.tampil(context, 'Tidak ada data pada rentang tanggal / jenis pajak ini', tipe: SnackType.peringatan);
      return;
    }
    final kat = _kategori == null ? null : KategoriPajak.dari(_kategori);
    setState(() => pdf ? _pdfLoading = true : _excelLoading = true);
    try {
      final file = pdf
          ? await ExportService.buatPdf(data, _range, petugas: petugas, sertakanFoto: _sertakanFoto, kategori: kat)
          : await ExportService.buatExcel(data, _range, sertakanFoto: _sertakanFoto, kategori: kat);
      if (!mounted) return;
      setState(() {
        _hasil = file;
        _hasilPdf = pdf;
      });
      AppSnack.tampil(context, 'File ${pdf ? 'PDF' : 'Excel'} berhasil dibuat', tipe: SnackType.sukses);
      if (langsungBagikan) await ExportService.bagikan(file);
    } catch (e) {
      if (mounted) AppSnack.tampil(context, 'Gagal membuat file. Silakan coba lagi.', tipe: SnackType.galat);
    } finally {
      if (mounted) setState(() => pdf ? _pdfLoading = false : _excelLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KunjunganProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final data = _data(prov);
    final jumlah = data.length;
    final denganFoto = data.where((k) => k.fotoPath != null).length;

    final jenisAktif = data.map((k) => k.kategori).toSet().length;
    final sibuk = _excelLoading || _pdfLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Ekspor Laporan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Rentang Tanggal', style: tt.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in const [
                    (0, 'Hari ini'),
                    (1, '7 hari'),
                    (2, 'Bulan ini'),
                    (3, 'Kustom'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PilPilih(label: e.$2, terpilih: _preset == e.$1, onTap: () => _pilihPreset(e.$1)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormatter.tanggalPendek(_range.start)} - ${DateFormatter.tanggalPendek(_range.end)}',
              style: tt.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('Jenis Pajak', style: tt.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PilPilih(
                      label: 'Semua',
                      terpilih: _kategori == null,
                      onTap: () => setState(() {
                        _kategori = null;
                        _hasil = null;
                      }),
                    ),
                  ),
                  for (final k in KategoriPajak.semua)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PilPilih(
                        label: k.singkat,
                        warna: k.color,
                        terpilih: _kategori == k.id,
                        onTap: () => setState(() {
                          _kategori = k.id;
                          _hasil = null;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Format', style: tt.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.table_chart_rounded), label: Text('Excel (.xlsx)')),
                  ButtonSegment(value: true, icon: Icon(Icons.picture_as_pdf_rounded), label: Text('PDF')),
                ],
                selected: {_formatPdf},
                onSelectionChanged: (v) => setState(() {
                  _formatPdf = v.first;
                  _hasil = null;
                }),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.image_rounded, color: cs.primary),
                title: const Text('Sertakan foto bukti'),
                subtitle: const Text('Foto ditanam di dalam file'),
                value: _sertakanFoto,
                onChanged: (v) => setState(() {
                  _sertakanFoto = v;
                  _hasil = null;
                }),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pratinjau Laporan', style: tt.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AngkaPratinjau(nilai: jumlah, label: 'Kunjungan'),
                      _AngkaPratinjau(nilai: _sertakanFoto ? denganFoto : 0, label: 'Foto'),
                      _AngkaPratinjau(nilai: jenisAktif, label: 'Jenis pajak'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CustomButton(
              label: 'Buat & Bagikan',
              icon: Icons.ios_share_rounded,
              loading: sibuk,
              onPressed: sibuk ? null : () => _ekspor(pdf: _formatPdf, langsungBagikan: true),
            ),
            if (_sertakanFoto && jumlah > 60)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Data banyak dengan foto: proses bisa memakan waktu beberapa saat. Mohon tunggu.',
                    style: tt.bodySmall),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _hasil == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: AppCard(
                        color: cs.primaryContainer.withValues(alpha: 0.45),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                                const SizedBox(width: 10),
                                Text('File siap dibagikan', style: tt.titleMedium),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(_hasilPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded, size: 22),
                                const SizedBox(width: 8),
                                Expanded(child: Text(p.basename(_hasil!.path), style: tt.bodyMedium)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              label: 'Bagikan Lagi (WhatsApp / Email)',
                              icon: Icons.share_rounded,
                              onPressed: () => ExportService.bagikan(_hasil!),
                            ),
                            if (_hasilPdf) ...[
                              const SizedBox(height: 10),
                              CustomButton(
                                label: 'Pratinjau / Cetak',
                                icon: Icons.print_rounded,
                                kind: ButtonKind.outlined,
                                onPressed: () => ExportService.cetakPdf(_hasil!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PilPilih extends StatelessWidget {
  final String label;
  final Color? warna;
  final bool terpilih;
  final VoidCallback onTap;
  const _PilPilih({required this.label, required this.terpilih, required this.onTap, this.warna});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: terpilih ? cs.primary : cs.surface,
      shape: StadiumBorder(side: BorderSide(color: terpilih ? cs.primary : cs.outlineVariant.withValues(alpha: 0.8))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warna != null) ...[
                Container(width: 9, height: 9, decoration: BoxDecoration(color: warna, shape: BoxShape.circle)),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: terpilih ? cs.onPrimary : cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AngkaPratinjau extends StatelessWidget {
  final int nilai;
  final String label;
  const _AngkaPratinjau({required this.nilai, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$nilai', style: tt.headlineSmall?.copyWith(fontSize: 26)),
        Text(label, style: tt.bodySmall?.copyWith(fontSize: 12.5)),
      ],
    );
  }
}
