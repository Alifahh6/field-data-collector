import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../utils/constants.dart';

class XCell {
  final Object value; // String atau int
  final int style; // 0 default, 1 header, 2 isi, 3+i = jenis pajak ke-i
  const XCell(this.value, this.style);
}

class XFoto {
  final int barisIndex; // 0 = baris header
  final Uint8List bytes; // JPEG
  final int w;
  final int h;
  const XFoto(this.barisIndex, this.bytes, this.w, this.h);
}

/// Penulis file .xlsx minimal (tanpa package luar) yang mendukung warna sel dan gambar tertanam.
class XlsxWriter {
  static const _main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _r = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _pkgRel = 'http://schemas.openxmlformats.org/package/2006/relationships';
  static const _xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _kolom(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  static String _styles() {
    final kat = KategoriPajak.semua;
    final fills = StringBuffer();
    final xfs = StringBuffer();
    for (var i = 0; i < kat.length; i++) {
      final hex = kat[i].hex.toRadixString(16).padLeft(6, '0').toUpperCase();
      fills.write('<fill><patternFill patternType="solid"><fgColor rgb="FF$hex"/><bgColor indexed="64"/></patternFill></fill>');
      xfs.write('<xf numFmtId="0" fontId="1" fillId="${3 + i}" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>');
    }
    final total = 3 + kat.length;
    return '$_xml<styleSheet xmlns="$_main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>'
        '<fills count="$total"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF1F3864"/><bgColor indexed="64"/></patternFill></fill>$fills</fills>'
        '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border><left style="thin"><color rgb="FFBFBFBF"/></left><right style="thin"><color rgb="FFBFBFBF"/></right><top style="thin"><color rgb="FFBFBFBF"/></top><bottom style="thin"><color rgb="FFBFBFBF"/></bottom><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="$total">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
        '$xfs</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';
  }

  static List<int> bangun({
    required String namaSheet,
    required List<double> lebarKolom,
    required List<List<XCell>> baris,
    required List<double> tinggiBaris,
    required int kolomFoto,
    required List<XFoto> foto,
  }) {
    final arsip = Archive();
    void tambah(String nama, List<int> data) => arsip.addFile(ArchiveFile(nama, data.length, data));
    void tambahTeks(String nama, String teks) => tambah(nama, utf8.encode(teks));

    final adaFoto = foto.isNotEmpty;

    tambahTeks(
      '[Content_Types].xml',
      '$_xml<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Default Extension="jpg" ContentType="image/jpeg"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '${adaFoto ? '<Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>' : ''}'
      '</Types>',
    );
    tambahTeks(
      '_rels/.rels',
      '$_xml<Relationships xmlns="$_pkgRel"><Relationship Id="rId1" Type="$_r/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    );
    tambahTeks(
      'xl/workbook.xml',
      '$_xml<workbook xmlns="$_main" xmlns:r="$_r"><sheets><sheet name="${_esc(namaSheet)}" sheetId="1" r:id="rId1"/></sheets></workbook>',
    );
    tambahTeks(
      'xl/_rels/workbook.xml.rels',
      '$_xml<Relationships xmlns="$_pkgRel">'
      '<Relationship Id="rId1" Type="$_r/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="$_r/styles" Target="styles.xml"/></Relationships>',
    );
    tambahTeks('xl/styles.xml', _styles());

    final kolom = StringBuffer();
    for (var i = 0; i < lebarKolom.length; i++) {
      kolom.write('<col min="${i + 1}" max="${i + 1}" width="${lebarKolom[i]}" customWidth="1"/>');
    }
    final data = StringBuffer();
    for (var r = 0; r < baris.length; r++) {
      final sel = StringBuffer();
      for (var c = 0; c < baris[r].length; c++) {
        final cell = baris[r][c];
        final ref = '${_kolom(c)}${r + 1}';
        if (cell.value is int) {
          sel.write('<c r="$ref" s="${cell.style}"><v>${cell.value}</v></c>');
        } else {
          sel.write('<c r="$ref" s="${cell.style}" t="inlineStr"><is><t xml:space="preserve">${_esc(cell.value.toString())}</t></is></c>');
        }
      }
      data.write('<row r="${r + 1}" ht="${tinggiBaris[r]}" customHeight="1">$sel</row>');
    }
    tambahTeks(
      'xl/worksheets/sheet1.xml',
      '$_xml<worksheet xmlns="$_main" xmlns:r="$_r">'
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
      '<sheetFormatPr defaultRowHeight="15"/>'
      '<cols>$kolom</cols><sheetData>$data</sheetData>'
      '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>'
      '${adaFoto ? '<drawing r:id="rId1"/>' : ''}</worksheet>',
    );

    if (adaFoto) {
      tambahTeks(
        'xl/worksheets/_rels/sheet1.xml.rels',
        '$_xml<Relationships xmlns="$_pkgRel"><Relationship Id="rId1" Type="$_r/drawing" Target="../drawings/drawing1.xml"/></Relationships>',
      );
      final jangkar = StringBuffer();
      final rels = StringBuffer();
      for (var i = 0; i < foto.length; i++) {
        final n = i + 1;
        final f = foto[i];
        tambah('xl/media/image$n.jpg', f.bytes);
        rels.write('<Relationship Id="rId$n" Type="$_r/image" Target="../media/image$n.jpg"/>');
        final cx = f.w * 9525, cy = f.h * 9525;
        jangkar.write(
          '<xdr:oneCellAnchor><xdr:from><xdr:col>$kolomFoto</xdr:col><xdr:colOff>38100</xdr:colOff><xdr:row>${f.barisIndex}</xdr:row><xdr:rowOff>38100</xdr:rowOff></xdr:from>'
          '<xdr:ext cx="$cx" cy="$cy"/><xdr:pic><xdr:nvPicPr><xdr:cNvPr id="${n + 1}" name="Foto $n"/><xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr></xdr:nvPicPr>'
          '<xdr:blipFill><a:blip r:embed="rId$n"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill>'
          '<xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/></xdr:oneCellAnchor>',
        );
      }
      tambahTeks(
        'xl/drawings/drawing1.xml',
        '$_xml<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="$_r">$jangkar</xdr:wsDr>',
      );
      tambahTeks(
        'xl/drawings/_rels/drawing1.xml.rels',
        '$_xml<Relationships xmlns="$_pkgRel">$rels</Relationships>',
      );
    }

    final List<int>? hasil = ZipEncoder().encode(arsip);
    if (hasil == null) throw Exception('Gagal membuat file xlsx');
    return hasil;
  }
}
