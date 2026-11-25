import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/foto_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';

class KameraHasil {
  final String path;
  final double? latitude;
  final double? longitude;
  final String? alamat;
  final bool tersimpanGaleri;
  const KameraHasil({required this.path, this.latitude, this.longitude, this.alamat, this.tersimpanGaleri = false});
}

class KameraScreen extends StatefulWidget {
  final KategoriPajak kategori;
  final String? nop;
  final String? nama;
  final String? alamatForm; // dipakai bila nama jalan tidak bisa didapat (offline)
  final String? petugas;
  const KameraScreen({super.key, required this.kategori, this.nop, this.nama, this.alamatForm, this.petugas});

  @override
  State<KameraScreen> createState() => _KameraScreenState();
}

class _KameraScreenState extends State<KameraScreen> with WidgetsBindingObserver {
  CameraController? _c;
  bool _menginisialisasi = false;
  String? _errKamera;

  LokasiHasil? _lokasi;
  bool _memuatLokasi = false;

  bool _proses = false;
  String? _hasilPath;
  LokasiHasil? _lokasiFoto;
  bool _dipakai = false;

  DateTime _sekarang = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initKamera();
    _muatLokasi();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasilPath == null) setState(() => _sekarang = DateTime.now());
    });
  }

  Future<void> _initKamera() async {
    if (_menginisialisasi) return;
    _menginisialisasi = true;
    try {
      final daftar = await availableCameras();
      if (daftar.isEmpty) {
        if (mounted) setState(() => _errKamera = 'Kamera tidak ditemukan di perangkat ini.');
        return;
      }
      final kamera = daftar.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => daftar.first,
      );
      final ctrl = CameraController(
        kamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      try {
        await ctrl.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _c = ctrl;
        _errKamera = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errKamera = (e.code.contains('Denied') || e.code.contains('Restricted'))
            ? 'Izin kamera ditolak. Aktifkan lewat Pengaturan > Aplikasi > Izin > Kamera.'
            : 'Kamera gagal dibuka (${e.code}). Coba tutup dan buka lagi.';
      });
    } catch (_) {
      if (mounted) setState(() => _errKamera = 'Kamera gagal dibuka. Coba lagi.');
    } finally {
      _menginisialisasi = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _c;
    if (state == AppLifecycleState.inactive) {
      if (c != null && c.value.isInitialized) {
        c.dispose();
        if (mounted) setState(() => _c = null);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_c == null && _hasilPath == null) _initKamera();
    }
  }

  Future<void> _muatLokasi() async {
    setState(() => _memuatLokasi = true);
    final r = await LocationService.ambilLokasiSaatIni();
    if (!mounted) return;
    setState(() {
      _lokasi = r;
      _memuatLokasi = false;
    });
  }

  Future<void> _ambilFoto() async {
    final c = _c;
    if (c == null || !c.value.isInitialized || _proses) return;
    setState(() => _proses = true);
    try {
      final lokasi = _lokasi;
      final waktu = DateTime.now();
      final format = context.read<SettingsProvider>().formatFoto;
      final mentah = await c.takePicture();
      final base = await getApplicationDocumentsDirectory();
      final dirFoto = Directory(p.join(base.path, 'foto'));
      await dirFoto.create(recursive: true);
      final tujuan = p.join(dirFoto.path, 'bukti_${waktu.millisecondsSinceEpoch}.$format');
      final pos = lokasi?.posisi;
      await FotoService.buatBukti(
        srcPath: mentah.path,
        dstPath: tujuan,
        format: format,
        data: FotoOverlayData(
          kategori: widget.kategori,
          nop: widget.nop,
          nama: widget.nama,
          petugas: widget.petugas,
          lat: pos?.latitude,
          lng: pos?.longitude,
          judul: lokasi?.judul ?? '',
          alamat: lokasi?.alamatLengkap ??
              ((widget.alamatForm ?? '').trim().isNotEmpty
                  ? widget.alamatForm!.trim()
                  : (pos == null ? 'Lokasi tidak tersedia' : 'Nama jalan tidak tersedia (offline)')),
          waktu: waktu,
        ),
      );
      if (!mounted) return;
      setState(() {
        _hasilPath = tujuan;
        _lokasiFoto = lokasi;
        _proses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _proses = false);
      AppSnack.tampil(context, 'Foto gagal diproses, silakan coba lagi.', tipe: SnackType.galat);
    }
  }

  Future<void> _ambilUlang() async {
    final path = _hasilPath;
    setState(() => _hasilPath = null);
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (_c == null) _initKamera();
  }

  Future<void> _pakai() async {
    _dipakai = true;
    final pos = _lokasiFoto?.posisi;
    var galeri = false;
    if (context.read<SettingsProvider>().simpanGaleri) {
      galeri = await FotoService.simpanKeGaleri(_hasilPath!);
    }
    if (!mounted) return;
    Navigator.pop(
      context,
      KameraHasil(
        path: _hasilPath!,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        alamat: _lokasiFoto?.alamat,
        tersimpanGaleri: galeri,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _c?.dispose();
    if (!_dipakai && _hasilPath != null) {
      File(_hasilPath!).delete().ignore();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------- UI
  bool _flash = false;

  Future<void> _alihFlash() async {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(_flash ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _flash = !_flash);
    } catch (_) {
      // perangkat tanpa lampu kilat: abaikan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _hasilPath != null ? _buildPreview() : _buildKamera()),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: const [
              Icon(Icons.fact_check_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Periksa foto sebelum disimpan',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            child: Center(child: Image.file(File(_hasilPath!), fit: BoxFit.contain)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Ambil Ulang',
                  icon: Icons.replay_rounded,
                  kind: ButtonKind.outlined,
                  color: Colors.white,
                  onPressed: _ambilUlang,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Pakai Foto',
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  onPressed: _pakai,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKamera() {
    final c = _c;
    final pos = _lokasi?.posisi;
    final status = _lokasi?.status;
    final gpsBermasalah = !_memuatLokasi && status != null && status != GpsStatus.ok;

    return Stack(
      children: [
        // Preview kamera
        Positioned.fill(
          child: _errKamera != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 64),
                        const SizedBox(height: 16),
                        Text(_errKamera!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 20),
                        CustomButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          expand: false,
                          onPressed: () {
                            setState(() => _errKamera = null);
                            _initKamera();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : (c == null || !c.value.isInitialized)
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Center(
                      child: AspectRatio(
                        aspectRatio: 1 / c.value.aspectRatio,
                        child: CameraPreview(c),
                      ),
                    ),
        ),

        // Bilah atas: tombol kembali + status GPS
        Positioned(
          top: 8,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Row(
                children: [
                  _bulat(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: (gpsBermasalah ? AppColors.warning : const Color(0xFF1C7C54)).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_memuatLokasi)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            else
                              Icon(gpsBermasalah || pos == null ? Icons.gps_off_rounded : Icons.location_on_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _memuatLokasi
                                  ? 'Mencari sinyal GPS...'
                                  : (gpsBermasalah || pos == null)
                                      ? 'GPS belum siap'
                                      : 'GPS siap, ${pos.accuracy.round()} m',
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _bulat(_flash ? Icons.flash_on_rounded : Icons.flash_off_rounded, _alihFlash),
                ],
              ),
              if (gpsBermasalah) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gps_off_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              LocationService.pesan(status),
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (status == GpsStatus.layananMati || status == GpsStatus.izinDitolakPermanen)
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              onPressed: () => LocationService.bukaPengaturan(status),
                              child: const Text('Buka Pengaturan'),
                            ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            onPressed: _muatLokasi,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Kotak stempel (pratinjau hasil) + kontrol bawah
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: widget.kategori.color.withValues(alpha: 0.92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.kategori.singkat,
                              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                        ),
                        Text(DateFormatter.tanggalJam(_sekarang),
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lokasi?.alamatLengkap ?? (pos == null ? '-' : 'Nama jalan belum tersedia (butuh internet)'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _memuatLokasi
                                ? 'Mencari sinyal GPS...'
                                : pos == null
                                    ? 'Koordinat belum tersedia'
                                    : 'Lat ${pos.latitude.toStringAsFixed(6)}  Long ${pos.longitude.toStringAsFixed(6)}  (akurasi ${pos.accuracy.round()} m)',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (widget.nop ?? '').isEmpty ? 'NOP: -' : 'NOP: ${widget.nop}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                        if ((widget.petugas ?? '').isNotEmpty)
                          Text('Petugas: ${widget.petugas}', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFF0A1440),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _kotak(Icons.my_location_rounded, _muatLokasi),
                    GestureDetector(
                      onTap: _ambilFoto,
                      child: Container(
                        width: 78,
                        height: 78,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: _proses
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.navy),
                                )
                              : null,
                        ),
                      ),
                    ),
                    _kotak(Icons.close_rounded, () => Navigator.pop(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulat(IconData ikon, VoidCallback onTap) => Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(11), child: Icon(ikon, color: Colors.white, size: 24)),
        ),
      );

  Widget _kotak(IconData ikon, VoidCallback onTap) => Material(
        color: const Color(0xFF1B2A63),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(width: 52, height: 52, child: Icon(ikon, color: Colors.white, size: 26)),
        ),
      );
}
