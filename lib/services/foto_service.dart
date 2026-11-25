import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart' show DateFormat;

import '../utils/constants.dart';

/// Data yang ditulis ke foto sebagai overlay.
class FotoOverlayData {
  final KategoriPajak kategori;
  final String? nop;
  final String? nama;
  final String? petugas;
  final double? lat;
  final double? lng;
  final String judul;
  final String alamat;
  final DateTime waktu;

  const FotoOverlayData({
    required this.kategori,
    this.nop,
    this.nama,
    this.petugas,
    this.lat,
    this.lng,
    required this.judul,
    required this.alamat,
    required this.waktu,
  });

  static String gmt(DateTime d) {
    final o = d.timeZoneOffset;
    final tanda = o.isNegative ? '-' : '+';
    final h = o.inHours.abs().toString().padLeft(2, '0');
    final m = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return 'GMT $tanda$h:$m';
  }

  String get waktuTeks => '${DateFormat('EEEE, dd/MM/yyyy HH:mm', 'id_ID').format(waktu)} ${gmt(waktu)}';
}

// ---- Fungsi top-level untuk isolate (compute) ----
Uint8List _normalisasi(Uint8List bytes) {
  var im = img.decodeImage(bytes);
  if (im == null) throw Exception('Foto tidak dapat dibaca');
  im = img.bakeOrientation(im);
  if (im.width > 1280) im = img.copyResize(im, width: 1280);
  return Uint8List.fromList(img.encodeJpg(im, quality: 92));
}

Future<void> _simpanBerkas(Map<String, dynamic> a) async {
  final rgba = a['rgba'] as Uint8List;
  final im = img.Image.fromBytes(
    width: a['w'] as int,
    height: a['h'] as int,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  final out = (a['fmt'] == 'png') ? img.encodePng(im) : img.encodeJpg(im, quality: 90);
  await File(a['dst'] as String).writeAsBytes(out, flush: true);
}

Map<String, Object> _kecilkan(Map<String, dynamic> a) {
  var im = img.decodeImage(a['bytes'] as Uint8List);
  if (im == null) throw Exception('gagal');
  im = img.bakeOrientation(im);
  final maxW = a['w'] as int, maxH = a['h'] as int;
  final skala = math.min(maxW / im.width, maxH / im.height);
  final kecil = skala >= 1 ? im : img.copyResize(im, width: (im.width * skala).round(), height: (im.height * skala).round());
  return {'bytes': Uint8List.fromList(img.encodeJpg(kecil, quality: 78)), 'w': kecil.width, 'h': kecil.height};
}

class ThumbFoto {
  final Uint8List bytes;
  final int w;
  final int h;
  const ThumbFoto(this.bytes, this.w, this.h);
}

class FotoService {
  /// Membuat foto bukti: koreksi rotasi, tempel overlay (peta mini + alamat + koordinat + waktu
  /// pada kotak berwarna sesuai jenis pajak), lalu simpan sebagai JPG/PNG di [dstPath].
  static Future<void> buatBukti({
    required String srcPath,
    required String dstPath,
    required String format, // 'jpg' | 'png'
    required FotoOverlayData data,
  }) async {
    final mentah = await File(srcPath).readAsBytes();
    final jpg = await compute(_normalisasi, mentah);
    final codec = await ui.instantiateImageCodec(jpg);
    final foto = (await codec.getNextFrame()).image;

    final w = foto.width.toDouble();
    final h = foto.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w, h));
    canvas.drawImage(foto, ui.Offset.zero, ui.Paint());

    final tile = (data.lat != null && data.lng != null) ? await _ambilTilePeta(data.lat!, data.lng!, 17) : null;
    _gambarOverlay(canvas, w, h, data, tile);

    final gambar = await recorder.endRecording().toImage(foto.width, foto.height);
    final byteData = await gambar.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Gagal merender foto');
    await compute(_simpanBerkas, {
      'rgba': byteData.buffer.asUint8List(),
      'w': foto.width,
      'h': foto.height,
      'fmt': format,
      'dst': dstPath,
    });
    foto.dispose();
    gambar.dispose();
    try {
      await File(srcPath).delete();
    } catch (_) {}
  }

  static void _gambarOverlay(ui.Canvas canvas, double w, double h, FotoOverlayData d, _Tile? tile) {
    final warna = d.kategori.color;
    final margin = w * 0.025;
    final pad = w * 0.02;
    final dasar = w * 0.0265;
    final thumb = w * 0.25;
    final lebarTeks = w - margin * 2 - pad * 3 - thumb;

    TextStyle gaya(double skala, {bool tebal = false, double spasi = 0}) => TextStyle(
          color: const ui.Color(0xFFFFFFFF),
          fontSize: dasar * skala,
          fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
          letterSpacing: spasi,
          height: 1.25,
        );

    final koordinat = (d.lat == null || d.lng == null)
        ? 'Koordinat: GPS tidak tersedia'
        : 'Lat ${d.lat!.toStringAsFixed(6)}°  Long ${d.lng!.toStringAsFixed(6)}°';
    final infoObjek = [
      if ((d.nop ?? '').isNotEmpty) 'NOP ${d.nop}',
      if ((d.nama ?? '').isNotEmpty) d.nama!,
    ].join('  |  ');

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 10,
      ellipsis: '...',
      text: TextSpan(children: [
        TextSpan(text: '${d.kategori.label.toUpperCase()}\n', style: gaya(0.85, tebal: true, spasi: 1.2)),
        if (infoObjek.isNotEmpty) TextSpan(text: '$infoObjek\n', style: gaya(0.85)),
        if (d.judul.isNotEmpty) TextSpan(text: '${d.judul}\n', style: gaya(1.15, tebal: true)),
        TextSpan(text: '${d.alamat}\n', style: gaya(0.95)),
        TextSpan(text: '$koordinat\n', style: gaya(0.95)),
        TextSpan(text: d.waktuTeks, style: gaya(0.95)),
        if ((d.petugas ?? '').isNotEmpty) TextSpan(text: '\nPetugas: ${d.petugas}', style: gaya(0.95, tebal: true)),
      ]),
    )..layout(maxWidth: lebarTeks);

    final tinggiKotak = math.max(tp.height, thumb) + pad * 2;
    final kotak = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(margin, h - margin - tinggiKotak, w - margin * 2, tinggiKotak),
      ui.Radius.circular(w * 0.02),
    );
    canvas.drawRRect(kotak, ui.Paint()..color = warna.withValues(alpha: 0.9));
    canvas.drawRRect(
      kotak,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = w * 0.004
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.85),
    );

    // Peta mini
    final thumbRect = ui.Rect.fromLTWH(kotak.left + pad, kotak.top + pad, thumb, thumb);
    final thumbRRect = ui.RRect.fromRectAndRadius(thumbRect, ui.Radius.circular(w * 0.012));
    canvas.save();
    canvas.clipRRect(thumbRRect);
    double pinX = thumbRect.center.dx, pinY = thumbRect.center.dy;
    if (tile != null) {
      canvas.drawImageRect(
        tile.image,
        ui.Rect.fromLTWH(0, 0, tile.image.width.toDouble(), tile.image.height.toDouble()),
        thumbRect,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      pinX = thumbRect.left + tile.fx * thumb;
      pinY = thumbRect.top + tile.fy * thumb;
    } else {
      canvas.drawRect(thumbRect, ui.Paint()..color = const ui.Color(0xFFCFD8DC));
      final garis = ui.Paint()
        ..color = const ui.Color(0xFFB0BEC5)
        ..strokeWidth = 2;
      for (var i = 1; i < 5; i++) {
        canvas.drawLine(ui.Offset(thumbRect.left + thumb * i / 5, thumbRect.top),
            ui.Offset(thumbRect.left + thumb * i / 5, thumbRect.bottom), garis);
        canvas.drawLine(ui.Offset(thumbRect.left, thumbRect.top + thumb * i / 5),
            ui.Offset(thumbRect.right, thumbRect.top + thumb * i / 5), garis);
      }
    }
    canvas.restore();
    // Pin lokasi
    final r = thumb * 0.07;
    canvas.drawCircle(ui.Offset(pinX, pinY), r * 1.5, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    canvas.drawCircle(ui.Offset(pinX, pinY), r, ui.Paint()..color = const ui.Color(0xFFD32F2F));
    canvas.drawRRect(
      thumbRRect,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = w * 0.004
        ..color = const ui.Color(0xFFFFFFFF),
    );

    tp.paint(canvas, ui.Offset(thumbRect.right + pad, kotak.top + pad));
  }

  /// Mengambil satu tile peta OpenStreetMap (butuh internet). Null bila gagal/offline.
  static Future<_Tile?> _ambilTilePeta(double lat, double lng, int z) async {
    try {
      final n = math.pow(2, z).toDouble();
      final xf = (lng + 180) / 360 * n;
      final latRad = lat * math.pi / 180;
      final yf = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
      final x = xf.floor(), y = yf.floor();
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('https://tile.openstreetmap.org/$z/$x/$y.png'));
      req.headers.set('User-Agent', 'FieldDataCollector/1.0 (Bapenda Surabaya)');
      final res = await req.close().timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final bytes = await consolidateHttpClientResponseBytes(res);
      client.close();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return _Tile(frame.image, xf - x, yf - y);
    } catch (_) {
      return null;
    }
  }

  /// Simpan ke Galeri HP (album "Field Data Collector"). Mengembalikan true jika berhasil.
  static Future<bool> simpanKeGaleri(String path) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(path, album: 'Field Data Collector');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Versi kecil foto untuk dimasukkan ke Excel/PDF (agar file tidak membengkak).
  static Future<ThumbFoto?> buatThumb(String? path, {int maxW = 240, int maxH = 180}) async {
    if (path == null) return null;
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      final r = await compute(_kecilkan, {'bytes': await f.readAsBytes(), 'w': maxW, 'h': maxH});
      return ThumbFoto(r['bytes'] as Uint8List, r['w'] as int, r['h'] as int);
    } catch (_) {
      return null;
    }
  }
}

class _Tile {
  final ui.Image image;
  final double fx;
  final double fy;
  const _Tile(this.image, this.fx, this.fy);
}
