import 'package:flutter/foundation.dart';

import '../services/sync_service.dart';
import 'kunjungan_provider.dart';
import 'settings_provider.dart';

/// Mengatur pengiriman antrean data yang belum terkirim ke server.
class SyncProvider extends ChangeNotifier {
  bool sedang = false;
  int selesai = 0;
  int total = 0;
  String? galat;

  /// Mengirim semua kunjungan yang belum terkirim (terlama dulu). Mengembalikan pesan ringkasan.
  Future<String> kirimSemua(KunjunganProvider kp, SettingsProvider st) async {
    if (sedang) return 'Pengiriman sedang berjalan...';
    if (!st.serverSiap) return 'Alamat server belum diatur.';
    final antrean = kp.items.where((k) => !k.tersinkron).toList().reversed.toList();
    if (antrean.isEmpty) return 'Semua data sudah terkirim.';

    sedang = true;
    selesai = 0;
    total = antrean.length;
    galat = null;
    notifyListeners();
    try {
      for (final k in antrean) {
        final id = await SyncService.kirim(k, st.serverUrl, st.apiKey);
        await kp.tandaiSinkron(k, id);
        selesai++;
        notifyListeners();
      }
    } on SyncException catch (e) {
      galat = e.pesan;
    } catch (_) {
      galat = 'Pengiriman gagal.';
    }
    sedang = false;
    notifyListeners();
    return galat == null ? '$selesai data berhasil dikirim ke server.' : '$selesai dari $total terkirim. $galat';
  }
}
