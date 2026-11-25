import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../models/tugas.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/tugas_provider.dart';
import '../services/import_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/maps_helper.dart';
import '../utils/page_route.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state.dart';
import '../widgets/kategori_badge.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import 'input_kunjungan_screen.dart';

/// Daftar Tugas: objek pajak yang harus dikunjungi (impor dari SIMPADA / CSV / XLSX),
/// beserta progres dan daftar yang perlu dikunjungi ulang.
class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen> {
  bool _mengimpor = false;

  Future<void> _impor() async {
    final pilih = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
    );
    final path = pilih?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _mengimpor = true);
    final hasil = await ImportService.baca(path, KategoriPajak.lainnya);
    if (!mounted) return;
    setState(() => _mengimpor = false);
    if (hasil.pesan != null) {
      AppSnack.tampil(context, hasil.pesan!, tipe: SnackType.galat);
      return;
    }
    final tidakTerdeteksi = hasil.data.length - hasil.terdeteksi;
    var jenisDefault = KategoriPajak.pbb;
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          icon: const Icon(Icons.upload_file_rounded, size: 40),
          title: const Text('Impor Daftar Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${hasil.data.length} objek pajak ditemukan.\n'
                  '${hasil.terdeteksi} jenis pajak terdeteksi otomatis.'),
              if (tidakTerdeteksi > 0) ...[
                const SizedBox(height: 12),
                Text('$tidakTerdeteksi baris tidak terdeteksi. Beri jenis pajak:'),
                const SizedBox(height: 8),
                DropdownButton<KategoriPajak>(
                  value: jenisDefault,
                  isExpanded: true,
                  items: [
                    for (final k in KategoriPajak.semua)
                      DropdownMenuItem(value: k, child: Text(k.label)),
                  ],
                  onChanged: (v) => setD(() => jenisDefault = v ?? KategoriPajak.pbb),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Impor')),
          ],
        ),
      ),
    );
    if (lanjut != true || !mounted) return;
    final data = [
      for (final t in hasil.data)
        t.kategori == KategoriPajak.lainnya.id
            ? Tugas(kategori: jenisDefault.id, nop: t.nop, nama: t.nama, alamat: t.alamat)
            : t,
    ];
    final tambah = await context.read<TugasProvider>().tambahBanyak(data);
    if (!mounted) return;
    AppSnack.tampil(
      context,
      '$tambah tugas ditambahkan${data.length - tambah > 0 ? ' (${data.length - tambah} duplikat dilewati)' : ''}',
      tipe: SnackType.sukses,
    );
  }

  Future<void> _kosongkan() async {
    final ya = await AppDialog.konfirmasi(
      context,
      judul: 'Hapus semua tugas?',
      pesan: 'Daftar tugas akan dikosongkan. Data kunjungan yang sudah dicatat tidak ikut terhapus.',
      labelYa: 'Hapus Semua',
      destruktif: true,
    );
    if (ya && mounted) await context.read<TugasProvider>().kosongkan();
  }

  void _mulai(Tugas t) => Navigator.push(context, AppRoute(page: InputKunjunganScreen(awal: t)));

  @override
  Widget build(BuildContext context) {
    final tugasProv = context.watch<TugasProvider>();
    final kunj = context.watch<KunjunganProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final belum = <Tugas>[];
    final selesai = <Tugas>[];
    for (final t in tugasProv.items) {
      final k = kunj.terakhirUntukNop(t.nop);
      if (k == null) {
        belum.add(t);
      } else if (StatusSurat.berhasil(k.status)) {
        selesai.add(t);
      }
    }
    final ulang = kunj.perluUlang;
    final total = tugasProv.items.length;
    final progres = total == 0 ? 0.0 : selesai.length / total;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Tugas'),
          actions: [
            TextButton.icon(
              onPressed: _mengimpor ? null : _impor,
              icon: _mengimpor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Icon(Icons.upload_file_rounded),
              label: const Text('Impor'),
            ),
            if (total > 0)
              PopupMenuButton<String>(
                tooltip: 'Menu',
                onSelected: (_) => _kosongkan(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'hapus', child: Text('Hapus semua tugas')),
                ],
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Belum (${belum.length})'),
              Tab(text: 'Ulang (${ulang.length})'),
              Tab(text: 'Selesai (${selesai.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Progres tugas', style: tt.titleSmall)),
                          Text('${selesai.length} / $total selesai', style: tt.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progres,
                          minHeight: 10,
                          backgroundColor: cs.primaryContainer,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _daftarTugas(belum, tugasProv.items.isEmpty),
                  _daftarUlang(ulang),
                  _daftarTugas(selesai, false, selesai: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daftarTugas(List<Tugas> data, bool kosongTotal, {bool selesai = false}) {
    if (data.isEmpty) {
      if (kosongTotal) {
        return EmptyState(
          icon: Icons.checklist_rounded,
          title: 'Belum ada daftar tugas',
          message: 'Impor daftar objek pajak dari SIMPADA (.xlsx atau .csv) agar kunjungan terencana dan progresnya terpantau.',
          actionLabel: 'Impor Daftar',
          actionIcon: Icons.upload_file_rounded,
          onAction: _impor,
        );
      }
      return EmptyState(
        icon: selesai ? Icons.hourglass_empty_rounded : Icons.celebration_rounded,
        title: selesai ? 'Belum ada yang selesai' : 'Semua tugas sudah dikunjungi',
        message: selesai ? 'Tugas yang berhasil dikunjungi akan muncul di sini.' : 'Kerja bagus! Tidak ada tugas tersisa.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: data.length,
      itemBuilder: (context, i) => _TugasTile(
        tugas: data[i],
        aksiLabel: selesai ? null : 'Mulai',
        onAksi: selesai ? null : () => _mulai(data[i]),
      ),
    );
  }

  Widget _daftarUlang(List<Kunjungan> data) {
    if (data.isEmpty) {
      return const EmptyState(
        icon: Icons.thumb_up_alt_rounded,
        title: 'Tidak ada yang perlu diulang',
        message: 'Objek pajak dengan status Tidak Ada Orang, Alamat Tidak Ditemukan, atau Ditolak akan muncul di sini.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final k = data[i];
        return _TugasTile(
          tugas: Tugas(kategori: k.kategori, nop: k.nop, nama: k.namaWp, alamat: k.alamat),
          status: k.status,
          info: 'Terakhir: ${DateFormatter.tanggalPendek(k.waktu)}',
          lat: k.latitude,
          lng: k.longitude,
          aksiLabel: 'Ulangi',
          onAksi: () => _mulai(Tugas(kategori: k.kategori, nop: k.nop, nama: k.namaWp, alamat: k.alamat)),
        );
      },
    );
  }
}

class _TugasTile extends StatelessWidget {
  final Tugas tugas;
  final String? status;
  final String? info;
  final double? lat;
  final double? lng;
  final String? aksiLabel;
  final VoidCallback? onAksi;

  const _TugasTile({
    required this.tugas,
    this.status,
    this.info,
    this.lat,
    this.lng,
    this.aksiLabel,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final kat = KategoriPajak.dari(tugas.kategori);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: kat.color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tugas.nama.isEmpty ? tugas.nop : tugas.nama,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall),
                      const SizedBox(height: 2),
                      Text(tugas.nop, style: tt.bodySmall),
                      if (tugas.alamat.isNotEmpty)
                        Text(tugas.alamat, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          KategoriBadge(kategori: kat),
                          if (status != null) StatusBadge(status: status!),
                          if (info != null) Text(info!, style: tt.bodySmall),
                        ],
                      ),
                      if (aksiLabel != null || tugas.alamat.isNotEmpty || lat != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 46)),
                              onPressed: () async {
                                final ok = await MapsHelper.buka(lat: lat, lng: lng, alamat: tugas.alamat);
                                if (!ok && context.mounted) {
                                  AppSnack.tampil(context, 'Aplikasi peta tidak dapat dibuka', tipe: SnackType.peringatan);
                                }
                              },
                              icon: const Icon(Icons.directions_rounded, size: 20),
                              label: const Text('Rute'),
                            )),
                            const SizedBox(width: 8),
                            if (aksiLabel != null)
                              Expanded(child: FilledButton.icon(
                                style: FilledButton.styleFrom(minimumSize: const Size(64, 46)),
                                onPressed: onAksi,
                                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                label: Text(aksiLabel!),
                              )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
