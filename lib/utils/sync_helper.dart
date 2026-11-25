import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kunjungan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/app_feedback.dart';

/// Kirim semua data yang belum terkirim, lalu tampilkan hasilnya.
Future<void> kirimSekarang(BuildContext context) async {
  final st = context.read<SettingsProvider>();
  final sync = context.read<SyncProvider>();
  final kp = context.read<KunjunganProvider>();
  if (!st.serverSiap) {
    AppSnack.tampil(context, 'Atur alamat server dulu di Akun > Sambungan Server', tipe: SnackType.peringatan);
    return;
  }
  if (!kp.adaBelumSinkron) {
    AppSnack.tampil(context, 'Semua data sudah terkirim', tipe: SnackType.sukses);
    return;
  }
  AppSnack.tampil(context, 'Mengirim data ke server...', tipe: SnackType.info);
  final pesan = await sync.kirimSemua(kp, st);
  if (context.mounted) {
    AppSnack.tampil(context, pesan, tipe: sync.galat == null ? SnackType.sukses : SnackType.galat);
  }
}
