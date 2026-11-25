import 'package:flutter/foundation.dart';

import '../models/tugas.dart';
import '../services/database_service.dart';

class TugasProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Tugas> _items = [];

  List<Tugas> get items => List.unmodifiable(_items);

  Future<void> muat() async {
    _items = await _db.getTugas();
    notifyListeners();
  }

  /// Menambahkan tugas baru; NOP yang sudah ada dilewati. Mengembalikan jumlah yang ditambahkan.
  Future<int> tambahBanyak(List<Tugas> baru) async {
    final ada = _items.map((e) => e.kunci).toSet();
    final unik = <Tugas>[];
    for (final t in baru) {
      if (t.kunci.isEmpty || ada.contains(t.kunci)) continue;
      ada.add(t.kunci);
      unik.add(t);
    }
    if (unik.isNotEmpty) {
      await _db.insertTugasBanyak(unik);
      await muat();
    }
    return unik.length;
  }

  Future<void> hapus(Tugas t) async {
    if (t.id == null) return;
    await _db.deleteTugas(t.id!);
    _items.removeWhere((e) => e.id == t.id);
    notifyListeners();
  }

  Future<void> kosongkan() async {
    await _db.kosongkanTugas();
    _items = [];
    notifyListeners();
  }
}
