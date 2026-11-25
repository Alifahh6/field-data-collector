import 'package:flutter/material.dart';

import '../utils/constants.dart';

enum SnackType { sukses, peringatan, galat, info }

/// Snackbar seragam: ikon + teks, warna sesuai jenis pesan.
class AppSnack {
  static void tampil(BuildContext context, String pesan, {SnackType tipe = SnackType.info}) {
    final (Color warna, IconData ikon) = switch (tipe) {
      SnackType.sukses => (AppColors.success, Icons.check_circle_rounded),
      SnackType.peringatan => (AppColors.warning, Icons.warning_amber_rounded),
      SnackType.galat => (AppColors.error, Icons.error_rounded),
      SnackType.info => (AppColors.info, Icons.info_rounded),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: warna,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Row(
            children: [
              Icon(ikon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pesan,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class AppDialog {
  /// Dialog konfirmasi; mengembalikan true jika pengguna menekan tombol aksi.
  static Future<bool> konfirmasi(
    BuildContext context, {
    required String judul,
    required String pesan,
    required String labelYa,
    String labelBatal = 'Batal',
    bool destruktif = false,
    IconData? ikon,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          ikon ?? (destruktif ? Icons.delete_forever_rounded : Icons.help_rounded),
          size: 40,
          color: destruktif ? cs.error : cs.primary,
        ),
        title: Text(judul, textAlign: TextAlign.center),
        content: Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(labelBatal)),
          FilledButton(
            style: destruktif ? FilledButton.styleFrom(backgroundColor: cs.error) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(labelYa),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }
}
