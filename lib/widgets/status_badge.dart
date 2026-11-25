import 'package:flutter/material.dart';

import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool besar;
  const StatusBadge({super.key, required this.status, this.besar = false});

  @override
  Widget build(BuildContext context) {
    final c = StatusSurat.color(status);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final teks = dark ? Color.lerp(c, Colors.white, 0.45)! : c;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: besar ? 14 : 10, vertical: besar ? 8 : 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusSurat.icon(status), size: besar ? 20 : 16, color: teks),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: besar ? 15 : 13,
                fontWeight: FontWeight.w600,
                color: teks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indikator kecil "Tersimpan Lokal" / "Tersinkron". Ketuk untuk mengirim data ke server.
class SyncIndicator extends StatelessWidget {
  final bool tersinkron;
  final bool solid; // true = latar putih (dipakai di atas gradient)
  final bool mengirim;
  final VoidCallback? onTap;
  const SyncIndicator({super.key, required this.tersinkron, this.solid = false, this.mengirim = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = tersinkron ? AppColors.success : AppColors.info;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warna = (dark && !solid) ? Color.lerp(c, Colors.white, 0.4)! : c;
    final label = mengirim ? 'Mengirim...' : (tersinkron ? 'Terkirim' : 'Belum terkirim');
    return Material(
      color: solid ? Colors.white : c.withValues(alpha: dark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: mengirim ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mengirim
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: warna))
                  : Icon(tersinkron ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded, size: 16, color: warna),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: warna)),
            ],
          ),
        ),
      ),
    );
  }
}
