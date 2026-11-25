import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/kunjungan.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'foto_service.dart';
import 'xlsx_writer.dart';

class ExportService {
  /// Kolom Excel. Sesuaikan urutan/nama kolom dengan template sistem resmi Bapenda bila berbeda.
  static const kolomExcel = [
    'No',
    'Jenis Pajak',
    'NOP',
    'Nama Wajib Pajak',
    'Alamat',
    'Status Penerimaan Surat',
    'Nama Penerima',
    'No. Telepon Penerima',
    'Tanggal Kunjungan',
    'Jam',
    'Latitude',
    'Longitude',
    'Petugas',
    'Catatan',
    'Foto Bukti',
  ];
  static const _lebarExcel = [6.0, 18.0, 24.0, 26.0, 40.0, 24.0, 22.0, 18.0, 16.0, 8.0, 14.0, 14.0, 20.0, 28.0, 36.0];

  static Future<Directory> _dirEkspor() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'ekspor'));
    await dir.create(recursive: true);
    return dir;
  }

  static String _namaFile(DateTimeRange r, String ext, KategoriPajak? kat) {
    final k = kat == null ? 'Semua' : kat.singkat.replaceAll(' ', '');
    return 'Kunjungan_${k}_${DateFormatter.kodeFile(r.start)}-${DateFormatter.kodeFile(r.end)}.$ext';
  }

  /// Dikelompokkan per jenis pajak (urutan tetap), lalu urut waktu.
  static List<Kunjungan> _urut(List<Kunjungan> data) {
    int idx(Kunjungan k) => KategoriPajak.semua.indexOf(KategoriPajak.dari(k.kategori));
    return [...data]..sort((a, b) {
        final c = idx(a).compareTo(idx(b));
        return c != 0 ? c : a.waktu.compareTo(b.waktu);
      });
  }

  // ---------------------------------------------------------------- EXCEL
  static Future<File> buatExcel(
    List<Kunjungan> data,
    DateTimeRange range, {
    bool sertakanFoto = true,
    KategoriPajak? kategori,
  }) async {
    final urut = _urut(data);
    final baris = <List<XCell>>[
      [for (final h in kolomExcel) XCell(h, 1)],
    ];
    final tinggi = <double>[30];
    final fotos = <XFoto>[];

    for (var i = 0; i < urut.length; i++) {
      final k = urut[i];
      final kat = KategoriPajak.dari(k.kategori);
      final katIdx = KategoriPajak.semua.indexOf(kat);
      final thumb = sertakanFoto ? await FotoService.buatThumb(k.fotoPath, maxW: 230, maxH: 140) : null;
      baris.add([
        XCell(i + 1, 2),
        XCell(kat.label, 3 + katIdx),
        XCell(k.nop, 2),
        XCell(k.namaWp, 2),
        XCell(k.alamat, 2),
        XCell(k.status, 2),
        XCell(k.namaPenerima ?? '', 2),
        XCell(k.telepon ?? '', 2),
        XCell(DateFormatter.tanggalAngka(k.waktu), 2),
        XCell(DateFormatter.jam(k.waktu), 2),
        XCell(k.latitude?.toStringAsFixed(6) ?? '', 2),
        XCell(k.longitude?.toStringAsFixed(6) ?? '', 2),
        XCell(k.petugas, 2),
        XCell(k.catatan ?? '', 2),
        XCell(thumb == null && k.fotoPath != null ? p.basename(k.fotoPath!) : '', 2),
      ]);
      tinggi.add(thumb != null ? 115 : 45);
      if (thumb != null) fotos.add(XFoto(i + 1, thumb.bytes, thumb.w, thumb.h));
    }

    final bytes = XlsxWriter.bangun(
      namaSheet: 'Kunjungan',
      lebarKolom: _lebarExcel,
      baris: baris,
      tinggiBaris: tinggi,
      kolomFoto: kolomExcel.length - 1,
      foto: fotos,
    );
    final dir = await _dirEkspor();
    final file = File(p.join(dir.path, _namaFile(range, 'xlsx', kategori)));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ------------------------------------------------------------------ PDF
  static PdfColor _pdfWarna(KategoriPajak k) => PdfColor.fromInt(k.hex);

  static Future<File> buatPdf(
    List<Kunjungan> data,
    DateTimeRange range, {
    String petugas = '',
    bool sertakanFoto = true,
    KategoriPajak? kategori,
  }) async {
    final biru = PdfColor.fromHex('#1F3864');
    final urut = _urut(data);

    final doc = pw.Document(title: 'Laporan Kunjungan', author: AppInfo.namaAplikasi);

    pw.Widget logo() => pw.Container(
          width: 46,
          height: 46,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(color: biru, shape: pw.BoxShape.circle),
          child: pw.Text('SBY',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        );

    pw.Widget kotak(String label, String nilai, PdfColor warna) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const pw.EdgeInsets.only(right: 6, bottom: 6),
          decoration: pw.BoxDecoration(color: warna, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(nilai, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
          ]),
        );

    final berhasil = urut.where((k) => StatusSurat.berhasil(k.status)).length;
    final rincian = <pw.Widget>[
      kotak('Total Kunjungan', '${urut.length}', biru),
      kotak('Berhasil', '$berhasil', PdfColor.fromHex('#2E8B57')),
      kotak('Gagal / Tertunda', '${urut.length - berhasil}', PdfColor.fromHex('#D98A2B')),
      for (final kat in KategoriPajak.semua)
        if (urut.any((k) => k.kategori == kat.id))
          kotak(kat.label, '${urut.where((k) => k.kategori == kat.id).length}', _pdfWarna(kat)),
    ];

    // Siapkan foto & tanda tangan (diperkecil).
    final fotoBaris = <pw.MemoryImage?>[];
    final ttdBaris = <pw.MemoryImage?>[];
    for (final k in urut) {
      final t = sertakanFoto ? await FotoService.buatThumb(k.fotoPath, maxW: 300, maxH: 225) : null;
      fotoBaris.add(t == null ? null : pw.MemoryImage(t.bytes));
      pw.MemoryImage? ttd;
      if (sertakanFoto && k.ttdPath != null) {
        final f = File(k.ttdPath!);
        if (await f.exists()) ttd = pw.MemoryImage(await f.readAsBytes());
      }
      ttdBaris.add(ttd);
    }

    pw.Widget sel(pw.Widget child, {PdfColor? bg, pw.Alignment align = pw.Alignment.topLeft}) => pw.Container(
          alignment: align,
          color: bg,
          padding: const pw.EdgeInsets.all(4),
          child: child,
        );
    pw.Widget teks(String s, {double size = 8, bool tebal = false, PdfColor? warna}) => pw.Text(
          s,
          style: pw.TextStyle(fontSize: size, fontWeight: tebal ? pw.FontWeight.bold : pw.FontWeight.normal, color: warna),
        );

    pw.TableRow header() => pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: biru),
          children: [
            for (final h in ['No', 'Jenis Pajak', 'Foto Bukti', 'NOP / Nama / Alamat', 'Status', 'Penerima / Catatan', 'Lokasi & Waktu'])
              sel(teks(h, size: 8.5, tebal: true, warna: PdfColors.white), align: pw.Alignment.center),
          ],
        );

    final barisTabel = <pw.TableRow>[header()];
    for (var i = 0; i < urut.length; i++) {
      final k = urut[i];
      final kat = KategoriPajak.dari(k.kategori);
      final foto = fotoBaris[i];
      final ttd = ttdBaris[i];
      barisTabel.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            sel(teks('${i + 1}'), align: pw.Alignment.center),
            sel(teks(kat.label, size: 8, tebal: true, warna: PdfColors.white), bg: _pdfWarna(kat), align: pw.Alignment.center),
            sel(
              foto == null
                  ? teks(k.fotoPath == null ? '-' : 'Foto tidak tersedia')
                  : pw.Container(
                      width: 96,
                      height: 72,
                      child: pw.Image(foto, fit: pw.BoxFit.contain),
                    ),
              align: pw.Alignment.center,
            ),
            sel(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              teks(k.nop, tebal: true),
              teks(k.namaWp, size: 8.5),
              pw.SizedBox(height: 2),
              teks(k.alamat),
            ])),
            sel(teks(k.status, tebal: true)),
            sel(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if ((k.namaPenerima ?? '').isNotEmpty) teks(k.namaPenerima!, tebal: true),
              if ((k.telepon ?? '').isNotEmpty) teks(k.telepon!),
              if ((k.catatan ?? '').isNotEmpty) teks('Catatan: ${k.catatan}'),
              if (ttd != null) pw.Container(width: 70, height: 28, child: pw.Image(ttd, fit: pw.BoxFit.contain)),
            ])),
            sel(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              teks(DateFormatter.tanggalJamPendek(k.waktu), tebal: true),
              teks(k.punyaKoordinat
                  ? '${k.latitude!.toStringAsFixed(5)}, ${k.longitude!.toStringAsFixed(5)}'
                  : 'Koordinat -'),
            ])),
          ],
        ),
      );
    }

    final judulKat = kategori == null ? 'SEMUA JENIS PAJAK' : kategori.label.toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 30),
        header: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            logo(),
            pw.SizedBox(width: 12),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('PEMERINTAH KOTA SURABAYA', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('BADAN PENDAPATAN DAERAH (BAPENDA)',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: biru)),
              pw.Text(AppInfo.unit, style: const pw.TextStyle(fontSize: 9)),
            ]),
          ]),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 1.5, color: biru),
          pw.SizedBox(height: 4),
        ]),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Dicetak ${DateFormatter.tanggalJam(DateTime.now())} - ${AppInfo.namaAplikasi}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ]),
        ),
        build: (ctx) => [
          pw.Text('LAPORAN BUKTI KUNJUNGAN PAJAK DAERAH - $judulKat',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(
            'Periode: ${DateFormatter.tanggalPendek(range.start)} s.d. ${DateFormatter.tanggalPendek(range.end)}'
            '${petugas.isEmpty ? '' : '   |   Petugas: $petugas'}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(children: rincian),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(62),
              2: const pw.FixedColumnWidth(108),
              3: const pw.FlexColumnWidth(4),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(2.6),
              6: const pw.FlexColumnWidth(2.4),
            },
            children: barisTabel,
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(children: [
              pw.Text('Surabaya, ${DateFormatter.tanggalPendek(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Petugas Lapangan', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 40),
              pw.Text(petugas.isEmpty ? '(................................)' : petugas,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );

    final dir = await _dirEkspor();
    final file = File(p.join(dir.path, _namaFile(range, 'pdf', kategori)));
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  // ------------------------------------------------------------- SHARE/PRINT
  static Future<void> bagikan(File file, {String? teks}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: teks ?? 'Laporan kunjungan - ${AppInfo.namaAplikasi}',
      subject: 'Laporan Kunjungan ${AppInfo.unit}',
    );
  }

  static Future<void> bagikanFoto(String path, {String? teks}) async {
    await Share.shareXFiles([XFile(path)], text: teks);
  }

  static Future<void> cetakPdf(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: p.basename(file.path));
  }
}
