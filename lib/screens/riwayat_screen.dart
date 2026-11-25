import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../providers/kunjungan_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/page_route.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/dashboard_widgets.dart';
import 'detail_kunjungan_screen.dart';
import 'input_kunjungan_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _cari = TextEditingController();
  String _query = '';
  String? _status;
  String? _kategori;
  String? _petugas;
  DateTimeRange? _range;

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  bool get _adaFilter => _query.isNotEmpty || _status != null || _kategori != null || _petugas != null || _range != null;

  void _reset() {
    _cari.clear();
    setState(() {
      _query = '';
      _status = null;
      _kategori = null;
      _petugas = null;
      _range = null;
    });
  }

  List<Kunjungan> _saring(List<Kunjungan> data) {
    final q = _query.toLowerCase();
    return data.where((k) {
      if (q.isNotEmpty && !k.namaWp.toLowerCase().contains(q) && !k.nop.toLowerCase().contains(q)) {
        return false;
      }
      if (_status != null && k.status != _status) return false;
      if (_kategori != null && k.kategori != _kategori) return false;
      if (_petugas != null && k.petugas != _petugas) return false;
      if (_range != null) {
        final mulai = DateFormatter.awalHari(_range!.start);
        final akhir = DateFormatter.hariBerikutnya(_range!.end);
        if (k.waktu.isBefore(mulai) || !k.waktu.isBefore(akhir)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pilihStatus() async {
    final hasil = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text('Semua Status'),
              trailing: _status == null ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final s in StatusSurat.semua)
              ListTile(
                leading: Icon(StatusSurat.icon(s), color: StatusSurat.color(s)),
                title: Text(s),
                trailing: _status == s ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (hasil == null) return;
    setState(() => _status = hasil.isEmpty ? null : hasil);
  }

  Future<void> _pilihPetugas() async {
    final semua = context.read<KunjunganProvider>().items.map((k) => k.petugas).where((n) => n.isNotEmpty).toSet().toList()
      ..sort();
    final hasil = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: const Text('Semua Petugas'),
                trailing: _petugas == null ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final n in semua)
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(n),
                  trailing: _petugas == n ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(ctx, n),
                ),
            ],
          ),
        ),
      ),
    );
    if (hasil == null) return;
    setState(() => _petugas = hasil.isEmpty ? null : hasil);
  }

  Future<void> _pilihTanggal() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih rentang tanggal',
      saveText: 'Pilih',
    );
    if (r != null) setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KunjunganProvider>();
    final hasil = _saring(prov.items);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Kelompokkan per tanggal (data sudah urut terbaru -> terlama).
    final grup = <DateTime, List<Kunjungan>>{};
    for (final k in hasil) {
      grup.putIfAbsent(DateFormatter.awalHari(k.waktu), () => []).add(k);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _cari,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari nama wajib pajak atau NOP',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _cari.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ChipJenis(label: 'Semua', warna: null, terpilih: _kategori == null, onTap: () => setState(() => _kategori = null)),
                for (final j in KategoriPajak.semua)
                  _ChipJenis(
                    label: j.singkat,
                    warna: j.color,
                    terpilih: _kategori == j.id,
                    onTap: () => setState(() => _kategori = _kategori == j.id ? null : j.id),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.filter_list_rounded, size: 20),
                  label: Text(_status == null ? 'Status: Semua' : _status!),
                  backgroundColor: _status == null ? null : cs.primaryContainer,
                  onPressed: _pilihStatus,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.support_agent_rounded, size: 20),
                  label: Text(_petugas ?? 'Petugas: Semua'),
                  backgroundColor: _petugas == null ? null : cs.primaryContainer,
                  onPressed: _pilihPetugas,
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 20),
                  label: Text(_range == null
                      ? 'Tanggal: Semua'
                      : '${DateFormatter.tanggalPendek(_range!.start)} - ${DateFormatter.tanggalPendek(_range!.end)}'),
                  backgroundColor: _range == null ? null : cs.primaryContainer,
                  onPressed: _pilihTanggal,
                ),
                if (_adaFilter) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.restart_alt_rounded, size: 20),
                    label: const Text('Reset'),
                    onPressed: _reset,
                  ),
                ],
              ],
            ),
          ),
          if (prov.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
              child: Row(
                children: [
                  Icon(Icons.swipe_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Geser kanan untuk ubah, geser kiri untuk hapus',
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: prov.items.isEmpty
                ? EmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'Belum ada riwayat kunjungan',
                    message: 'Kunjungan yang Anda catat akan muncul di sini, dikelompokkan per tanggal.',
                    actionLabel: 'Catat Kunjungan',
                    onAction: () => Navigator.push(context, AppRoute(page: const InputKunjunganScreen())),
                  )
                : hasil.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Data tidak ditemukan',
                        message: 'Coba ubah kata kunci atau filter yang dipakai.',
                        actionLabel: 'Reset Filter',
                        actionIcon: Icons.restart_alt_rounded,
                        onAction: _reset,
                      )
                    : CustomScrollView(
                        slivers: [
                          for (final e in grup.entries)
                            SliverMainAxisGroup(
                              slivers: [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _HeaderTanggal(
                                    label: DateFormatter.labelHari(e.key),
                                    jumlah: e.value.length,
                                    bg: Theme.of(context).scaffoldBackgroundColor,
                                    fg: cs.primary,
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => _ItemKunjungan(item: e.value[i]),
                                      childCount: e.value.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTanggal extends SliverPersistentHeaderDelegate {
  final String label;
  final int jumlah;
  final Color bg;
  final Color fg;
  _HeaderTanggal({required this.label, required this.jumlah, required this.bg, required this.fg});

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text('$jumlah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderTanggal old) =>
      old.label != label || old.jumlah != jumlah || old.bg != bg || old.fg != fg;
}

class _ItemKunjungan extends StatelessWidget {
  final Kunjungan item;
  const _ItemKunjungan({required this.item});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final kat = KategoriPajak.dari(item.kategori);

    Widget latar(Color warna, IconData ikon, String label, Alignment al) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: al,
          decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, color: Colors.white, size: 28),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Dismissible(
      key: ValueKey('kunjungan_${item.id}'),
      background: latar(AppColors.info, Icons.edit_rounded, 'Ubah', Alignment.centerLeft),
      secondaryBackground: latar(AppColors.error, Icons.delete_rounded, 'Hapus', Alignment.centerRight),
      confirmDismiss: (arah) async {
        if (arah == DismissDirection.startToEnd) {
          final ya = await AppDialog.konfirmasi(
            context,
            judul: 'Ubah data ini?',
            pesan: 'Anda akan membuka form untuk mengubah data kunjungan ${item.namaWp}.',
            labelYa: 'Ubah',
            ikon: Icons.edit_rounded,
          );
          if (ya && context.mounted) {
            Navigator.push(context, AppRoute(page: InputKunjunganScreen(edit: item)));
          }
          return false;
        }
        return AppDialog.konfirmasi(
          context,
          judul: 'Hapus data ini?',
          pesan: 'Data kunjungan ${item.namaWp} beserta fotonya akan dihapus permanen.',
          labelYa: 'Hapus',
          destruktif: true,
        );
      },
      onDismissed: (_) {
        context.read<KunjunganProvider>().hapus(item);
        AppSnack.tampil(context, 'Data kunjungan dihapus', tipe: SnackType.info);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(12),
          onTap: () => Navigator.push(context, AppRoute(page: DetailKunjunganScreen(kunjungan: item))),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: kat.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
                child: Icon(kat.icon, color: kat.color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.namaTampil, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(item.nopTampil,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.robotoMono(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.65))),
                    if (item.petugas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(item.petugas,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [PilKategori(kategori: kat), PilStatus(status: item.status)]),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormatter.jam(item.waktu), style: tt.bodySmall),
                  const SizedBox(height: 14),
                  Icon(item.tersinkron ? Icons.cloud_done_rounded : Icons.chevron_right_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.6)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipJenis extends StatelessWidget {
  final String label;
  final Color? warna;
  final bool terpilih;
  final VoidCallback onTap;
  const _ChipJenis({required this.label, required this.warna, required this.terpilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6, top: 2),
      child: Material(
        color: terpilih ? cs.primary : cs.surface,
        shape: StadiumBorder(side: BorderSide(color: terpilih ? cs.primary : cs.outlineVariant.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warna != null) ...[
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: warna, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: terpilih ? cs.onPrimary : cs.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
