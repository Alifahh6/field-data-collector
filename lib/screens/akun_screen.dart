import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/kunjungan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tugas_provider.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/app_feedback.dart';
import '../widgets/stat_card.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final _auth = AuthService();
  bool _biometrikTersedia = false;

  @override
  void initState() {
    super.initState();
    _auth.biometrikTersedia().then((v) {
      if (mounted) setState(() => _biometrikTersedia = v);
    });
  }

  Future<void> _menuFoto() async {
    final settings = context.read<SettingsProvider>();
    final ada = settings.fotoProfilPath != null;
    final pilih = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(ada ? 'Ganti foto dari galeri' : 'Pilih foto dari galeri'),
              onTap: () => Navigator.pop(ctx, 'ganti'),
            ),
            if (ada)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Theme.of(ctx).colorScheme.error),
                title: Text('Hapus foto profil', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () => Navigator.pop(ctx, 'hapus'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (pilih == 'ganti') {
      await _gantiFoto();
    } else if (pilih == 'hapus') {
      final lama = settings.fotoProfilPath;
      await settings.setFotoProfil(null);
      if (lama != null) File(lama).delete().ignore();
      if (mounted) AppSnack.tampil(context, 'Foto profil dihapus', tipe: SnackType.sukses);
    }
  }

  Future<void> _gantiFoto() async {
    final settings = context.read<SettingsProvider>();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final tujuan = p.join(dir.path, 'profil_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(tujuan);
    final lama = settings.fotoProfilPath;
    await settings.setFotoProfil(tujuan);
    if (lama != null) File(lama).delete().ignore();
  }

  Future<void> _editProfil() async {
    final s = context.read<SettingsProvider>();
    final nama = TextEditingController(text: s.namaPetugas);
    final nip = TextEditingController(text: s.nip);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Ubah Info Petugas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama Petugas', prefixIcon: Icon(Icons.person_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nip,
              decoration: const InputDecoration(labelText: 'NIP / NIM', prefixIcon: Icon(Icons.badge_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await s.setProfil(nama: nama.text, nomorInduk: nip.text);
      if (mounted) AppSnack.tampil(context, 'Info petugas diperbarui', tipe: SnackType.sukses);
    }
    nama.dispose();
    nip.dispose();
  }

  Future<void> _toggleKunci(bool aktif) async {
    final s = context.read<SettingsProvider>();
    if (aktif) {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PinDialog(mode: PinMode.buat),
      );
      if (pin == null || !mounted) return;
      await _auth.simpanPin(pin);
      await s.setKunciAktif(true);
      if (mounted) AppSnack.tampil(context, 'Kunci aplikasi diaktifkan', tipe: SnackType.sukses);
    } else {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PinDialog(mode: PinMode.verifikasi),
      );
      if (pin == null || !mounted) return;
      await _auth.hapusPin();
      await s.setKunciAktif(false);
      if (mounted) AppSnack.tampil(context, 'Kunci aplikasi dimatikan', tipe: SnackType.info);
    }
  }

  Future<void> _toggleBiometrik(bool aktif) async {
    final s = context.read<SettingsProvider>();
    if (aktif) {
      final ok = await _auth.autentikasiBiometrik();
      if (!ok) {
        if (mounted) AppSnack.tampil(context, 'Verifikasi sidik jari / wajah dibatalkan', tipe: SnackType.peringatan);
        return;
      }
    }
    await s.setBiometrikAktif(aktif);
  }

  bool _sibuk = false;

  Future<void> _cadangkan() async {
    setState(() => _sibuk = true);
    try {
      final file = await BackupService.buat();
      if (!mounted) return;
      setState(() => _sibuk = false);
      await ExportService.bagikan(file, teks: 'Cadangan data Field Data Collector');
    } catch (_) {
      if (mounted) {
        setState(() => _sibuk = false);
        AppSnack.tampil(context, 'Cadangan gagal dibuat', tipe: SnackType.galat);
      }
    }
  }

  Future<void> _pulihkan() async {
    final ya = await AppDialog.konfirmasi(
      context,
      judul: 'Pulihkan dari cadangan?',
      pesan: 'Pilih file cadangan (.zip). Data yang sudah ada tidak ditimpa; hanya data yang belum ada yang ditambahkan.',
      labelYa: 'Pilih File',
      ikon: Icons.settings_backup_restore_rounded,
    );
    if (!ya || !mounted) return;
    final pilih = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
    final path = pilih?.files.single.path;
    if (path == null || !mounted) return;
    final kunjungan = context.read<KunjunganProvider>();
    final tugas = context.read<TugasProvider>();
    setState(() => _sibuk = true);
    try {
      final tambah = await BackupService.pulihkan(path);
      await kunjungan.muat();
      await tugas.muat();
      if (!mounted) return;
      setState(() => _sibuk = false);
      AppSnack.tampil(context, '$tambah data kunjungan dipulihkan', tipe: SnackType.sukses);
    } catch (_) {
      if (mounted) {
        setState(() => _sibuk = false);
        AppSnack.tampil(context, 'File cadangan tidak valid', tipe: SnackType.galat);
      }
    }
  }

  void _tentang() {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.namaAplikasi,
      applicationVersion: 'Versi ${AppInfo.versi}',
      applicationIcon: const Icon(Icons.assignment_turned_in_rounded, size: 44, color: AppColors.navy),
      children: const [
        SizedBox(height: 12),
        Text('Aplikasi dokumentasi bukti pengantaran surat pajak daerah (SPPT PBB dan SKPD) '
            'untuk petugas lapangan ${AppInfo.unit}, ${AppInfo.instansi}.'),
        SizedBox(height: 8),
        Text('Data tersimpan di HP (offline) dan dapat diekspor ke Excel atau PDF.'),
      ],
    );
  }

  void _bantuan() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.support_agent_rounded, size: 40),
        title: const Text('Kontak Bantuan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppInfo.kontakNama, style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Row(children: [Icon(Icons.phone_rounded, size: 20), SizedBox(width: 8), Expanded(child: Text(AppInfo.kontakTelepon))]),
            SizedBox(height: 6),
            Row(children: [Icon(Icons.email_rounded, size: 20), SizedBox(width: 8), Expanded(child: Text(AppInfo.kontakEmail))]),
            SizedBox(height: 14),
            Text('Tips: bila GPS lemah, pindah ke area terbuka. Foto bisa diambil ulang sebelum disimpan.'),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            AppCard(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: s.fotoProfilPath == null ? null : FileImage(File(s.fotoProfilPath!)),
                        child: s.fotoProfilPath == null ? Icon(Icons.person_rounded, size: 52, color: cs.primary) : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: cs.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _menuFoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(s.fotoProfilPath == null ? Icons.photo_camera_rounded : Icons.edit_rounded, size: 20, color: cs.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(s.namaPetugas, style: tt.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(s.nip.isEmpty ? 'NIP / NIM belum diisi' : 'NIP / NIM: ${s.nip}', style: tt.bodyMedium),
                  const SizedBox(height: 2),
                  Text(AppInfo.unit, style: tt.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _editProfil,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Ubah Info Petugas'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Tampilan', style: tt.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Keamanan', style: tt.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: const Icon(Icons.lock_rounded),
                    title: const Text('Kunci Aplikasi dengan PIN'),
                    subtitle: const Text('Melindungi data wajib pajak'),
                    value: s.kunciAktif,
                    onChanged: _toggleKunci,
                  ),
                  if (s.kunciAktif && _biometrikTersedia) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: const Text('Buka dengan Sidik Jari / Wajah'),
                      value: s.biometrikAktif,
                      onChanged: _toggleBiometrik,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Foto Bukti', style: tt.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.image_rounded),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('Format file foto', style: TextStyle(fontSize: 16))),
                        SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'jpg', label: Text('JPG')),
                            ButtonSegment(value: 'png', label: Text('PNG')),
                          ],
                          selected: {s.formatFoto},
                          onSelectionChanged: (v) => s.setFormatFoto(v.first),
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: const Icon(Icons.photo_library_rounded),
                    title: const Text('Simpan otomatis ke Galeri'),
                    subtitle: const Text('Album "Field Data Collector"'),
                    value: s.simpanGaleri,
                    onChanged: s.setSimpanGaleri,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Data', style: tt.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    minVerticalPadding: 14,
                    leading: _sibuk
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6))
                        : const Icon(Icons.cloud_upload_rounded),
                    title: const Text('Cadangkan Data'),
                    subtitle: const Text('Data + foto jadi satu file ZIP'),
                    onTap: _sibuk ? null : _cadangkan,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minVerticalPadding: 14,
                    leading: const Icon(Icons.settings_backup_restore_rounded),
                    title: const Text('Pulihkan dari Cadangan'),
                    subtitle: const Text('Untuk HP baru atau setelah instal ulang'),
                    onTap: _sibuk ? null : _pulihkan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Lainnya', style: tt.titleMedium),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    minVerticalPadding: 14,
                    leading: const Icon(Icons.support_agent_rounded),
                    title: const Text('Kontak Bantuan'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _bantuan,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    minVerticalPadding: 14,
                    leading: const Icon(Icons.info_rounded),
                    title: const Text('Tentang Aplikasi'),
                    subtitle: const Text('Versi ${AppInfo.versi}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _tentang,
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

enum PinMode { buat, verifikasi }

class _PinDialog extends StatefulWidget {
  final PinMode mode;
  const _PinDialog({required this.mode});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _c = TextEditingController();
  final _auth = AuthService();
  String? _pertama;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    _fokus.dispose();
    super.dispose();
  }

  String get _judul {
    if (widget.mode == PinMode.verifikasi) return 'Masukkan PIN Saat Ini';
    return _pertama == null ? 'Buat PIN 4 Angka' : 'Ulangi PIN';
  }

  Future<void> _lanjut() async {
    final v = _c.text;
    if (v.length != 4) {
      setState(() => _error = 'PIN harus 4 angka');
      return;
    }
    if (widget.mode == PinMode.verifikasi) {
      if (await _auth.cekPin(v)) {
        if (mounted) Navigator.pop(context, v);
      } else {
        setState(() {
          _error = 'PIN salah';
          _c.clear();
        });
      }
      return;
    }
    if (_pertama == null) {
      setState(() {
        _pertama = v;
        _error = null;
        _c.clear();
      });
    } else if (_pertama == v) {
      Navigator.pop(context, v);
    } else {
      setState(() {
        _pertama = null;
        _error = 'PIN tidak sama, ulangi dari awal';
        _c.clear();
      });
    }
  }

  final _fokus = FocusNode();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final adaError = _error != null;
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.lock_rounded, size: 30, color: cs.primary),
          ),
          const SizedBox(height: 14),
          Text(_judul, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            widget.mode == PinMode.verifikasi ? 'Demi keamanan, masukkan PIN Anda' : 'PIN dipakai untuk membuka aplikasi',
            textAlign: TextAlign.center,
            style: tt.bodySmall,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _fokus.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 52,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < _c.text.length ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: adaError
                                ? cs.error
                                : (i == _c.text.length ? cs.primary : cs.outlineVariant),
                            width: i == _c.text.length ? 2 : 1,
                          ),
                        ),
                        child: i < _c.text.length
                            ? Container(width: 14, height: 14, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle))
                            : null,
                      ),
                  ],
                ),
                // Kolom input tersembunyi: hanya untuk menerima ketikan angka.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _c,
                      focusNode: _fokus,
                      autofocus: true,
                      maxLength: 4,
                      showCursor: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _lanjut(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: adaError
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error, fontSize: 13.5, fontWeight: FontWeight.w500)),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(110, 48)),
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 48)),
          onPressed: _lanjut,
          child: Text(widget.mode == PinMode.buat && _pertama == null ? 'Lanjut' : 'Simpan'),
        ),
      ],
    );
  }
}
