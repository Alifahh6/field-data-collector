import 'package:url_launcher/url_launcher.dart';

class MapsHelper {
  /// Membuka Google Maps (atau aplikasi peta lain) ke koordinat / alamat. Mengembalikan false bila gagal.
  static Future<bool> buka({double? lat, double? lng, String? alamat}) async {
    final String query;
    if (lat != null && lng != null) {
      query = '$lat,$lng';
    } else if ((alamat ?? '').trim().isNotEmpty) {
      query = alamat!.trim();
    } else {
      return false;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
