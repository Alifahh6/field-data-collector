import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kunjungan.dart';
import '../models/tugas.dart';
import '../providers/kunjungan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/tugas_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/page_route.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';
import '../widgets/kategori_badge.dart';
import '../widgets/stat_card.dart';
import 'kamera_screen.dart';
import 'tanda_tangan_screen.dart';

class InputKunjunganScreen extends StatefulWidget {
  /// Jika diisi, layar berfungsi sebagai form edit.
  final Kunjungan? edit;

  /// Data awal dari Daftar Tugas / kunjungan ulang.
  final Tugas? awal;
  const InputKunjunganScreen({super.key, this.edit, this.awal});

  @override
  State<InputKunjunganScreen> createState() => _InputKunjunganScreenState();
}

class _InputKunjunganScreenState extends State<InputKunjunganScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nop = TextEditingController();
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _penerima = TextEditingController();
  final _telepon = TextEditingController();
  final _catatan = TextEditingController();
  final _petugas = TextEditingController();

  String? _kategori;
  String? _status;
  String? _fotoPath;
  String? _ttdPath;
  double? _lat;
  double? _lng;
  bool _menyimpan = false;
  bool _ambilLokasi = false;
  bool _fotoError = false;
  bool _tersimpan = false;
  Kunjungan? _duplikat;

  bool get _modeEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    final a = widget.awal;
    if (e != null) {
      _kategori = e.kategori;
      _nop.text = e.nop;
      _nama.text = e.namaWp;
      _alamat.text = e.alamat;
      _penerima.text = e.namaPenerima ?? '';
      _telepon.text = e.telepon ?? '';
      _catatan.text = e.catatan ?? '';
      _petugas.text = e.petugas;
      _status = e.status;
      _fotoPath = e.fotoPath;
      _ttdPath = e.ttdPath;
      _lat = e.latitude;
      _lng = e.longitude;
    } else if (a != null) {
      _terapkanTugas(a);
    }
    if (_petugas.text.trim().isEmpty) _petugas.text = context.read<SettingsProvider>().namaPetugas;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekDuplikat());
  }

  void _terapkanTugas(Tugas t) {
    _kategori = t.kategori;
    _nop.text = t.nop;
    _nama.text = t.nama;
    _alamat.text = t.alamat;
  }

  @override
  void dispose() {
    for (final c in [_nop, _nama, _alamat, _penerima, _telepon, _catatan, _petugas]) {
      c.dispose();
    }
    // Bersihkan foto/tanda tangan baru yang tidak jadi disimpan.
    if (!_tersimpan) {
      if (_fotoPath != null && _fotoPath != widget.edit?.fotoPath) File(_fotoPath!).delete().ignore();
      if (_ttdPath != null && _ttdPath != widget.edit?.ttdPath) File(_ttdPath!).delete().ignore();
    }
    super.dispose();
  }

  void _cekDuplikat() {
    if (!mounted) return;
    final k = context.read<KunjunganProvider>().terakhirUntukNop(_nop.text, kecualiId: widget.edit?.id);
    if (k?.id != _duplikat?.id) setState(() => _duplikat = k);
  }

  KategoriPajak? get _kat => _kategori == null ? null : KategoriPajak.dari(_kategori);

  Future<void> _pilihDariTugas() async {
    final tugas = context.read<TugasProvider>().items;
    final kunjungan = context.read<KunjunganProvider>();
    final hasil = await showModalBottomSheet<Tugas>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _PilihTugasSheet(
        tugas: tugas,
        sudahDikunjungi: (t) => kunjungan.terakhirUntukNop(t.nop) != null,
      ),
    );
    if (hasil == null || !mounted) return;
    setState(() => _terapkanTugas(hasil));
    _cekDuplikat();
  }

  Future<void> _isiAlamatDariLokasi() async {
    setState(() => _ambilLokasi = true);
    final r = await LocationService.ambilLokasiSaatIni();
    if (!mounted) return;
    setState(() => _ambilLokasi = false);
    if (r.posisi == null) {
      AppSnack.tampil(context, LocationService.pesan(r.status), tipe: SnackType.peringatan);
      if (r.status == GpsStatus.layananMati || r.status == GpsStatus.izinDitolakPermanen) {
        LocationService.bukaPengaturan(r.status);
      }
      return;
    }
    setState(() {
      _lat = r.posisi!.latitude;
      _lng = r.posisi!.longitude;
      _alamat.text = r.alamat ?? 'Koordinat ${r.koordinatTeks}';
    });
    if (r.status == GpsStatus.lemah) {
      AppSnack.tampil(context, LocationService.pesan(GpsStatus.lemah), tipe: SnackType.peringatan);
    } else {
      AppSnack.tampil(context, 'Lokasi berhasil diambil', tipe: SnackType.sukses);
    }
  }

  Future<void> _ambilFoto() async {
    if (_kat == null) {
      AppSnack.tampil(context, 'Pilih jenis pajak dulu sebelum mengambil foto', tipe: SnackType.peringatan);
      return;
    }
    final hasil = await Navigator.push<KameraHasil>(
      context,
      AppRoute(
        page: KameraScreen(
          kategori: _kat!,
          nop: _nop.text.trim(),
          nama: _nama.text.trim(),
          alamatForm: _alamat.text,
          petugas: _petugas.text.trim(),
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    if (_fotoPath != null && _fotoPath != widget.edit?.fotoPath) {
      File(_fotoPath!).delete().ignore();
    }
    setState(() {
      _fotoPath = hasil.path;
      _fotoError = false;
      if (hasil.latitude != null) {
        _lat = hasil.latitude;
        _lng = hasil.longitude;
      }
      if (_alamat.text.trim().isEmpty && hasil.alamat != null) _alamat.text = hasil.alamat!;
    });
    if (hasil.tersimpanGaleri) {
      AppSnack.tampil(context, 'Foto juga tersimpan di Galeri', tipe: SnackType.sukses);
    }
  }

  Future<void> _tandaTangan() async {
    final path = await Navigator.push<String>(
      context,
      AppRoute(page: TandaTanganScreen(namaPenerima: _penerima.text.trim())),
    );
    if (path == null || !mounted) return;
    if (_ttdPath != null && _ttdPath != widget.edit?.ttdPath) File(_ttdPath!).delete().ignore();
    setState(() => _ttdPath = path);
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    if (_fotoPath == null) setState(() => _fotoError = true);
    if (!valid || _fotoPath == null) {
      AppSnack.tampil(context, 'Mohon lengkapi data yang bertanda merah', tipe: SnackType.galat);
      return;
    }
    setState(() => _menyimpan = true);
    final prov = context.read<KunjunganProvider>();
    final settings = context.read<SettingsProvider>();
    final sync = context.read<SyncProvider>();
    final petugas = _petugas.text.trim();
    await settings.catatPetugas(petugas);
    final langsung = _status == StatusSurat.diterimaLangsung;
    final data = Kunjungan(
      id: widget.edit?.id,
      kategori: _kategori!,
      nop: _nop.text.trim(),
      namaWp: _nama.text.trim(),
      alamat: _alamat.text.trim(),
      status: _status!,
      namaPenerima: langsung ? _penerima.text.trim() : null,
      telepon: langsung ? _telepon.text.trim() : null,
      fotoPath: _fotoPath,
      ttdPath: langsung ? _ttdPath : null,
      catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
      latitude: _lat,
      longitude: _lng,
      waktu: widget.edit?.waktu ?? DateTime.now(),
      tersinkron: false,
      petugas: petugas,
    );
    try {
      if (_modeEdit) {
        await prov.ubah(data);
      } else {
        await prov.tambah(data);
      }
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      AppSnack.tampil(context, 'Data gagal disimpan. Silakan coba lagi.', tipe: SnackType.galat);
      return;
    }
    _tersimpan = true;
    if (settings.serverSiap && settings.autoKirim) {
      sync.kirimSemua(prov, settings); // di latar belakang; bila gagal tetap antre
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Data berhasil disimpan',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  String? _wajib(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final adaTugas = context.watch<TugasProvider>().items.isNotEmpty;
    final warnaKat = _kat?.color;

    return Scaffold(
      appBar: AppBar(title: Text(_modeEdit ? 'Ubah Kunjungan' : 'Kunjungan Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              if (widget.awal != null && !_modeEdit) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          const TextSpan(text: 'Tugas Terhubung  '),
                          TextSpan(
                              text: 'Data NOP, nama, alamat, dan jenis pajak sudah terisi otomatis dari daftar tugas.',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75))),
                        ]), style: tt.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (adaTugas && !_modeEdit) ...[
                CustomButton(
                  label: 'Pilih dari Daftar Tugas',
                  icon: Icons.checklist_rounded,
                  kind: ButtonKind.tonal,
                  onPressed: _pilihDariTugas,
                ),
                const SizedBox(height: 20),
              ],
              Text('Jenis Pajak *', style: tt.titleMedium),
              const SizedBox(height: 12),
              FormField<String>(
                key: ValueKey('kat_$_kategori'),
                initialValue: _kategori,
                validator: (v) => v == null ? 'Pilih jenis pajak' : null,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KategoriSelector(
                      terpilih: _kategori,
                      onPilih: (k) {
                        setState(() => _kategori = k.id);
                        state.didChange(k.id);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 6),
                        child: Text(state.errorText!,
                            style: TextStyle(color: cs.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Data Wajib Pajak', style: tt.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nop,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                onChanged: (_) => _cekDuplikat(),
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Nomor Objek Pajak (NOP)',
                  hintText: 'Contoh: 35.78.xxx.xxx.xxx-xxxx.x',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isNotEmpty && t.length < 6) return 'NOP terlalu pendek, periksa kembali';
                  return null;
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.topCenter,
                child: _duplikat == null
                    ? const SizedBox(width: double.infinity)
                    : Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.history_rounded, color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'NOP ini sudah pernah dikunjungi pada ${DateFormatter.tanggalPendek(_duplikat!.waktu)} '
                                'dengan status "${_duplikat!.status}". Lanjutkan hanya jika ini kunjungan ulang.',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                final pilihan = context.watch<SettingsProvider>().pilihanPetugas;
                return TextFormField(
                  controller: _petugas,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Petugas Pengantar Surat',
                    prefixIcon: const Icon(Icons.support_agent_rounded),
                    suffixIcon: pilihan.length < 2
                        ? null
                        : PopupMenuButton<String>(
                            tooltip: 'Pilih petugas',
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                            onSelected: (v) => setState(() => _petugas.text = v),
                            itemBuilder: (_) => [
                              for (final n in pilihan) PopupMenuItem(value: n, child: Text(n)),
                            ],
                          ),
                  ),
                );
              }),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Nama Wajib Pajak / Objek Pajak',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alamat,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.home_rounded),
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                label: 'Ambil Alamat dari Lokasi Saat Ini',
                icon: Icons.my_location_rounded,
                kind: ButtonKind.tonal,
                loading: _ambilLokasi,
                onPressed: _isiAlamatDariLokasi,
              ),
              const SizedBox(height: 24),

              Text('Status Penerimaan Surat *', style: tt.titleMedium),
              const SizedBox(height: 12),
              FormField<String>(
                initialValue: _status,
                validator: (v) => v == null ? 'Pilih salah satu status penerimaan surat' : null,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in StatusSurat.semua)
                      _StatusOption(
                        status: s,
                        selected: _status == s,
                        onTap: () {
                          setState(() => _status = s);
                          state.didChange(s);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Text(state.errorText!,
                            style: TextStyle(color: cs.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _status == StatusSurat.diterimaLangsung
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _penerima,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: 'Nama Penerima *',
                                prefixIcon: Icon(Icons.badge_rounded),
                              ),
                              validator: (v) => _wajib(v, 'Nama penerima'),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telepon,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: 'Nomor Telepon *',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              validator: (v) {
                                final w = _wajib(v, 'Nomor telepon');
                                if (w != null) return w;
                                if (v!.replaceAll(RegExp(r'\D'), '').length < 8) return 'Nomor telepon terlalu pendek';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tanda Tangan Penerima (disarankan)', style: tt.titleSmall),
                                  const SizedBox(height: 10),
                                  if (_ttdPath != null)
                                    Container(
                                      height: 110,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: cs.outlineVariant),
                                      ),
                                      child: Image.file(File(_ttdPath!), fit: BoxFit.contain),
                                    ),
                                  if (_ttdPath != null) const SizedBox(height: 10),
                                  CustomButton(
                                    label: _ttdPath == null ? 'Minta Tanda Tangan' : 'Ulangi Tanda Tangan',
                                    icon: Icons.draw_rounded,
                                    kind: ButtonKind.outlined,
                                    onPressed: _tandaTangan,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 24),

              Text('Foto Bukti *', style: tt.titleMedium),
              const SizedBox(height: 4),
              Text('Di foto otomatis tertera alamat, koordinat, dan waktu dalam kotak berwarna jenis pajak.',
                  style: tt.bodySmall),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(12),
                color: _fotoError ? cs.error.withValues(alpha: 0.06) : null,
                child: Column(
                  children: [
                    if (_fotoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_fotoPath!),
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(
                            height: 230,
                            color: cs.primaryContainer,
                            child: const Center(child: Icon(Icons.broken_image_rounded, size: 48)),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: (warnaKat ?? cs.primary).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _fotoError ? cs.error : (warnaKat ?? cs.primary).withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 44, color: warnaKat ?? cs.primary),
                            const SizedBox(height: 8),
                            Text('Belum ada foto', style: tt.bodyMedium),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: _fotoPath == null ? 'Ambil Foto Bukti' : 'Ambil Ulang Foto',
                      icon: _fotoPath == null ? Icons.photo_camera_rounded : Icons.replay_rounded,
                      kind: _fotoPath == null ? ButtonKind.filled : ButtonKind.outlined,
                      color: _fotoPath == null ? warnaKat : null,
                      onPressed: _ambilFoto,
                    ),
                    if (_fotoError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Foto bukti wajib diambil',
                            style: TextStyle(color: cs.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    if (_lat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Titik lokasi: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                                  style: tt.bodySmall),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _catatan,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Catatan lapangan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: _modeEdit ? 'Simpan Perubahan' : 'Simpan Kunjungan',
                icon: Icons.save_rounded,
                color: AppColors.success,
                loading: _menyimpan,
                onPressed: _simpan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusOption({required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = StatusSurat.color(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? c.withValues(alpha: 0.12) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? c : cs.outlineVariant, width: selected ? 2 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(StatusSurat.icon(status), color: c),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1 : 0,
                    child: Icon(Icons.check_circle_rounded, color: c),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet untuk memilih objek pajak dari Daftar Tugas.
class _PilihTugasSheet extends StatefulWidget {
  final List<Tugas> tugas;
  final bool Function(Tugas) sudahDikunjungi;
  const _PilihTugasSheet({required this.tugas, required this.sudahDikunjungi});

  @override
  State<_PilihTugasSheet> createState() => _PilihTugasSheetState();
}

class _PilihTugasSheetState extends State<_PilihTugasSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final daftar = widget.tugas
        .where((t) => q.isEmpty || t.nama.toLowerCase().contains(q) || t.nop.toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau NOP',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: daftar.isEmpty
                    ? const Center(child: Text('Tidak ada tugas yang cocok'))
                    : ListView.builder(
                        itemCount: daftar.length,
                        itemBuilder: (context, i) {
                          final t = daftar[i];
                          final kat = KategoriPajak.dari(t.kategori);
                          final sudah = widget.sudahDikunjungi(t);
                          return ListTile(
                            minVerticalPadding: 10,
                            leading: CircleAvatar(backgroundColor: kat.color, child: Icon(kat.icon, color: Colors.white, size: 20)),
                            title: Text(t.nama.isEmpty ? t.nop : t.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${t.nop}\n${t.alamat}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            isThreeLine: true,
                            trailing: sudah ? const Icon(Icons.check_circle_rounded, color: AppColors.success) : null,
                            onTap: () => Navigator.pop(context, t),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
