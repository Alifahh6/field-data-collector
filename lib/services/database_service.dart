import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/kunjungan.dart';
import '../models/tugas.dart';

/// Penyimpanan lokal SQLite (offline-first).
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'field_data_collector.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE kunjungan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kategori TEXT NOT NULL DEFAULT 'pbb',
            nop TEXT NOT NULL,
            nama_wp TEXT NOT NULL,
            alamat TEXT NOT NULL,
            status TEXT NOT NULL,
            nama_penerima TEXT,
            telepon TEXT,
            foto_path TEXT,
            ttd_path TEXT,
            catatan TEXT,
            latitude REAL,
            longitude REAL,
            waktu TEXT NOT NULL,
            tersinkron INTEGER NOT NULL DEFAULT 0,
            petugas TEXT NOT NULL DEFAULT '',
            server_id TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_kunjungan_waktu ON kunjungan(waktu)');
        await _buatTabelTugas(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE kunjungan ADD COLUMN kategori TEXT NOT NULL DEFAULT 'pbb'");
          await db.execute('ALTER TABLE kunjungan ADD COLUMN ttd_path TEXT');
          await db.execute('ALTER TABLE kunjungan ADD COLUMN catatan TEXT');
          await _buatTabelTugas(db);
        }
      },
    );
  }

  Future<void> _buatTabelTugas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tugas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kategori TEXT NOT NULL,
        nop TEXT NOT NULL,
        nama TEXT,
        alamat TEXT
      )
    ''');
  }

  // ------------------------------------------------------------- Kunjungan
  Future<int> insert(Kunjungan k) async {
    final db = await database;
    final map = k.toMap()..remove('id');
    return db.insert('kunjungan', map);
  }

  Future<void> update(Kunjungan k) async {
    final db = await database;
    final map = k.toMap()..remove('id');
    await db.update('kunjungan', map, where: 'id = ?', whereArgs: [k.id]);
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('kunjungan', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Kunjungan>> getAll() async {
    final db = await database;
    final rows = await db.query('kunjungan', orderBy: 'waktu DESC');
    return rows.map(Kunjungan.fromMap).toList();
  }

  // ----------------------------------------------------------------- Tugas
  Future<List<Tugas>> getTugas() async {
    final db = await database;
    final rows = await db.query('tugas', orderBy: 'id ASC');
    return rows.map(Tugas.fromMap).toList();
  }

  Future<void> insertTugasBanyak(List<Tugas> data) async {
    final db = await database;
    final batch = db.batch();
    for (final t in data) {
      final m = t.toMap()..remove('id');
      batch.insert('tugas', m);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteTugas(int id) async {
    final db = await database;
    await db.delete('tugas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> kosongkanTugas() async {
    final db = await database;
    await db.delete('tugas');
  }
}
