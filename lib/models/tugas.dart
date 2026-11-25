/// Satu objek pajak yang harus dikunjungi (hasil impor daftar dari SIMPADA / CSV / XLSX).
class Tugas {
  final int? id;
  final String kategori;
  final String nop;
  final String nama;
  final String alamat;

  const Tugas({this.id, required this.kategori, required this.nop, required this.nama, required this.alamat});

  /// NOP dinormalkan (tanpa titik/strip/spasi) agar pencocokan tidak terganggu format.
  static String normal(String nop) => nop.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toLowerCase();

  String get kunci => normal(nop);

  Map<String, dynamic> toMap() => {
        'id': id,
        'kategori': kategori,
        'nop': nop,
        'nama': nama,
        'alamat': alamat,
      };

  factory Tugas.fromMap(Map<String, dynamic> m) => Tugas(
        id: m['id'] as int?,
        kategori: (m['kategori'] as String?) ?? 'lainnya',
        nop: m['nop'] as String,
        nama: (m['nama'] as String?) ?? '',
        alamat: (m['alamat'] as String?) ?? '',
      );
}
