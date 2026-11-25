import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../providers/kunjungan_provider.dart';
import '../services/export_service.dart';
import '../services/foto_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/maps_helper.dart';
import '../utils/page_route.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';
import '../widgets/kategori_badge.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import 'input_kunjungan_screen.dart';

class DetailKunjunganScreen extends StatelessWidget {
  final Kunjungan kunjungan;
  const DetailKunjunganScreen({super.key, required this.kunjungan});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KunjunganProvider>();
    final k = prov.items.firstWhere((e) => e.id == kunjungan.id, orElse: () => kunjungan);
    final kat = KategoriPajak.dari(k.kategori);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kunjungan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KategoriBadge(kategori: kat, kecil: false),
                StatusBadge(status: k.status, besar: true),
              ],
            ),
            const SizedBox(height: 14),
            if (k.fotoPath != null) ...[
              GestureDetector(
                onTap: () => Navigator.push(context, AppRoute(page: _FotoViewer(path: k.fotoPath!))),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: kat.color, borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(k.fotoPath!),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, e, s) => Container(
                        height: 200,
                        color: cs.primaryContainer,
                        child: const Center(child: Icon(Icons.broken_image_rounded, size: 52)),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Ketuk foto untuk memperbesar', textAlign: TextAlign.center, style: tt.bodySmall),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Simpan ke Galeri',
                      icon: Icons.download_rounded,
                      kind: ButtonKind.tonal,
                      onPressed: () async {
                        final ok = await FotoService.simpanKeGaleri(k.fotoPath!);
                        if (context.mounted) {
                          AppSnack.tampil(
                            context,
                            ok ? 'Foto tersimpan di Galeri (album Field Data Collector)' : 'Foto gagal disimpan ke Galeri',
                            tipe: ok ? SnackType.sukses : SnackType.galat,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      label: 'Bagikan Foto',
                      icon: Icons.share_rounded,
                      kind: ButtonKind.tonal,
                      onPressed: () => ExportService.bagikanFoto(
                        k.fotoPath!,
                        teks: '${kat.label} - ${k.namaWp} (NOP ${k.nop})',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _Baris(Icons.person_rounded, 'Nama Wajib Pajak', k.namaTampil),
                  _Baris(Icons.tag_rounded, 'NOP', k.nopTampil, salin: k.nop),
                  _Baris(Icons.home_rounded, 'Alamat', k.alamat, salin: k.alamat),
                  _Baris(Icons.event_rounded, 'Waktu Kunjungan',
                      '${DateFormatter.tanggalPanjang(k.waktu)}, ${DateFormatter.jam(k.waktu)}'),
                  if ((k.namaPenerima ?? '').isNotEmpty) _Baris(Icons.badge_rounded, 'Nama Penerima', k.namaPenerima!),
                  if ((k.telepon ?? '').isNotEmpty) _Baris(Icons.phone_rounded, 'Nomor Telepon', k.telepon!),
                  if ((k.catatan ?? '').isNotEmpty) _Baris(Icons.notes_rounded, 'Catatan', k.catatan!),
                  if (k.petugas.isNotEmpty) _Baris(Icons.support_agent_rounded, 'Petugas', k.petugas),
                  _Baris(
                    k.tersinkron ? Icons.cloud_done_rounded : Icons.save_rounded,
                    'Status Data',
                    k.tersinkron ? 'Tersinkron' : 'Tersimpan Lokal',
                    terakhir: true,
                  ),
                ],
              ),
            ),
            if (k.ttdPath != null && File(k.ttdPath!).existsSync()) ...[
              const SizedBox(height: 18),
              Text('Tanda Tangan Penerima', style: tt.titleMedium),
              const SizedBox(height: 10),
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Image.file(File(k.ttdPath!), fit: BoxFit.contain),
              ),
            ],
            const SizedBox(height: 18),
            Text('Lokasi Kunjungan', style: tt.titleMedium),
            const SizedBox(height: 10),
            if (k.punyaKoordinat) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 210,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(k.latitude!, k.longitude!),
                      initialZoom: 16.5,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'id.go.surabaya.bapenda.field_data_collector',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(k.latitude!, k.longitude!),
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: Icon(Icons.location_on_rounded, color: kat.color, size: 48),
                        ),
                      ]),
                      const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.my_location_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${k.latitude!.toStringAsFixed(6)}, ${k.longitude!.toStringAsFixed(6)}', style: tt.bodyMedium),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Peta memerlukan internet untuk menampilkan gambar.', style: tt.bodySmall),
              ),
            ] else
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.location_off_rounded, color: cs.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Koordinat lokasi tidak tersimpan pada data ini.')),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Buka Rute di Google Maps',
              icon: Icons.directions_rounded,
              kind: ButtonKind.outlined,
              onPressed: () async {
                final ok = await MapsHelper.buka(lat: k.latitude, lng: k.longitude, alamat: k.alamat);
                if (!ok && context.mounted) {
                  AppSnack.tampil(context, 'Aplikasi peta tidak dapat dibuka', tipe: SnackType.peringatan);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Ubah',
                    icon: Icons.edit_rounded,
                    kind: ButtonKind.outlined,
                    onPressed: () => Navigator.push(context, AppRoute(page: InputKunjunganScreen(edit: k))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Hapus',
                    icon: Icons.delete_rounded,
                    color: AppColors.error,
                    onPressed: () async {
                      final ya = await AppDialog.konfirmasi(
                        context,
                        judul: 'Hapus data ini?',
                        pesan: 'Data kunjungan ${k.namaWp} beserta fotonya akan dihapus permanen.',
                        labelYa: 'Hapus',
                        destruktif: true,
                      );
                      if (!ya || !context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      await context.read<KunjunganProvider>().hapus(k);
                      nav.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('Data kunjungan dihapus')));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool terakhir;
  final String? salin; // bila diisi, tampil tombol salin
  const _Baris(this.icon, this.label, this.value, {this.terakhir = false, this.salin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: terakhir ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.65))),
                const SizedBox(height: 2),
                Text(value.trim().isEmpty ? '-' : value, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (salin != null && salin!.trim().isNotEmpty)
            IconButton(
              tooltip: 'Salin',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_rounded, size: 20, color: cs.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: salin!));
                AppSnack.tampil(context, '$label disalin', tipe: SnackType.sukses);
              },
            ),
        ],
      ),
    );
  }
}

class _FotoViewer extends StatelessWidget {
  final String path;
  const _FotoViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Bukti', style: TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
      ),
    );
  }
}
