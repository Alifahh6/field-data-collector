import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/kunjungan.dart';
import '../models/tugas.dart';
import '../utils/date_formatter.dart';
import 'database_service.dart';

/// Cadangan data (ZIP berisi data.json + foto + tanda tangan) agar data tidak hilang bila HP rusak/hilang.
class BackupService {
  static Future<File> buat() async {
    final db = DatabaseService.instance;
    final kunjungan = await db.getAll();
    final tugas = await db.getTugas();
    final arsip = Archive();

    final daftar = <Map<String, dynamic>>[];
    for (final k in kunjungan) {
      final m = k.toMap();
      for (final kolom in ['foto_path', 'ttd_path']) {
        final path = m[kolom] as String?;
        if (path != null && await File(path).exists()) {
          final folder = kolom == 'foto_path' ? 'foto' : 'ttd';
          final bytes = await File(path).readAsBytes();
          arsip.addFile(ArchiveFile('media/$folder/${p.basename(path)}', bytes.length, bytes));
          m[kolom] = p.basename(path);
        } else {
          m[kolom] = null;
        }
      }
      daftar.add(m);
    }
    final json = utf8.encode(jsonEncode({
      'versi': 2,
      'dibuat': DateTime.now().toIso8601String(),
      'kunjungan': daftar,
      'tugas': tugas.map((t) => t.toMap()).toList(),
    }));
    arsip.addFile(ArchiveFile('data.json', json.length, json));

    final List<int>? zip = ZipEncoder().encode(arsip);
    if (zip == null) throw Exception('Gagal membuat cadangan');
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'backup'));
    await dir.create(recursive: true);
    final nama = 'FDC_Backup_${DateFormatter.kodeFile(DateTime.now())}_${DateTime.now().millisecondsSinceEpoch % 100000}.zip';
    final file = File(p.join(dir.path, nama));
    await file.writeAsBytes(zip, flush: true);
    return file;
  }

  /// Memulihkan data dari ZIP cadangan. Data yang sudah ada (waktu + NOP sama) dilewati.
  /// Mengembalikan jumlah kunjungan yang ditambahkan.
  static Future<int> pulihkan(String zipPath) async {
    final arsip = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    ArchiveFile? dataFile;
    for (final f in arsip) {
      if (f.isFile && f.name == 'data.json') dataFile = f;
    }
    if (dataFile == null) throw Exception('Bukan file cadangan Field Data Collector');
    final json = jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map<String, dynamic>;

    final base = await getApplicationDocumentsDirectory();
    final dirFoto = Directory(p.join(base.path, 'foto'))..createSync(recursive: true);
    final dirTtd = Directory(p.join(base.path, 'ttd'))..createSync(recursive: true);
    for (final f in arsip) {
      if (!f.isFile) continue;
      Directory? tujuan;
      if (f.name.startsWith('media/foto/')) tujuan = dirFoto;
      if (f.name.startsWith('media/ttd/')) tujuan = dirTtd;
      if (tujuan != null) {
        await File(p.join(tujuan.path, p.basename(f.name))).writeAsBytes(f.content as List<int>);
      }
    }

    final db = DatabaseService.instance;
    final ada = (await db.getAll()).map((k) => '${k.waktu.toIso8601String()}|${Tugas.normal(k.nop)}').toSet();
    var tambah = 0;
    for (final m in (json['kunjungan'] as List).cast<Map<String, dynamic>>()) {
      final foto = m['foto_path'] as String?;
      final ttd = m['ttd_path'] as String?;
      m['foto_path'] = foto == null ? null : p.join(dirFoto.path, foto);
      m['ttd_path'] = ttd == null ? null : p.join(dirTtd.path, ttd);
      final k = Kunjungan.fromMap(m);
      final kunci = '${k.waktu.toIso8601String()}|${Tugas.normal(k.nop)}';
      if (ada.contains(kunci)) continue;
      await db.insert(k);
      ada.add(kunci);
      tambah++;
    }
    final tugasAda = (await db.getTugas()).map((t) => t.kunci).toSet();
    final tugasBaru = <Tugas>[];
    for (final m in ((json['tugas'] as List?) ?? []).cast<Map<String, dynamic>>()) {
      final t = Tugas.fromMap(m);
      if (t.kunci.isNotEmpty && tugasAda.add(t.kunci)) tugasBaru.add(Tugas(kategori: t.kategori, nop: t.nop, nama: t.nama, alamat: t.alamat));
    }
    if (tugasBaru.isNotEmpty) await db.insertTugasBanyak(tugasBaru);
    return tambah;
  }
}
