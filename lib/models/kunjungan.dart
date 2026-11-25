class Kunjungan {
  final int? id;
  final String kategori; // id KategoriPajak
  final String nop;
  final String namaWp;
  final String alamat;
  final String status;
  final String? namaPenerima;
  final String? telepon;
  final String? fotoPath;
  final String? ttdPath; // tanda tangan penerima (PNG)
  final String? catatan;
  final double? latitude;
  final double? longitude;
  final DateTime waktu;
  final bool tersinkron;
  final String petugas;
  final String? serverId; // disiapkan untuk sinkronisasi cloud di masa depan

  const Kunjungan({
    this.id,
    this.kategori = 'pbb',
    required this.nop,
    required this.namaWp,
    required this.alamat,
    required this.status,
    this.namaPenerima,
    this.telepon,
    this.fotoPath,
    this.ttdPath,
    this.catatan,
    this.latitude,
    this.longitude,
    required this.waktu,
    this.tersinkron = false,
    this.petugas = '',
    this.serverId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'kategori': kategori,
        'nop': nop,
        'nama_wp': namaWp,
        'alamat': alamat,
        'status': status,
        'nama_penerima': namaPenerima,
        'telepon': telepon,
        'foto_path': fotoPath,
        'ttd_path': ttdPath,
        'catatan': catatan,
        'latitude': latitude,
        'longitude': longitude,
        'waktu': waktu.toIso8601String(),
        'tersinkron': tersinkron ? 1 : 0,
        'petugas': petugas,
        'server_id': serverId,
      };

  factory Kunjungan.fromMap(Map<String, dynamic> m) => Kunjungan(
        id: m['id'] as int?,
        kategori: (m['kategori'] as String?) ?? 'pbb',
        nop: m['nop'] as String,
        namaWp: m['nama_wp'] as String,
        alamat: m['alamat'] as String,
        status: m['status'] as String,
        namaPenerima: m['nama_penerima'] as String?,
        telepon: m['telepon'] as String?,
        fotoPath: m['foto_path'] as String?,
        ttdPath: m['ttd_path'] as String?,
        catatan: m['catatan'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        waktu: DateTime.parse(m['waktu'] as String),
        tersinkron: (m['tersinkron'] as int? ?? 0) == 1,
        petugas: (m['petugas'] as String?) ?? '',
        serverId: m['server_id'] as String?,
      );

  Kunjungan copyWith({int? id, bool? tersinkron, String? serverId}) => Kunjungan(
        id: id ?? this.id,
        kategori: kategori,
        nop: nop,
        namaWp: namaWp,
        alamat: alamat,
        status: status,
        namaPenerima: namaPenerima,
        telepon: telepon,
        fotoPath: fotoPath,
        ttdPath: ttdPath,
        catatan: catatan,
        latitude: latitude,
        longitude: longitude,
        waktu: waktu,
        tersinkron: tersinkron ?? this.tersinkron,
        petugas: petugas,
        serverId: serverId ?? this.serverId,
      );

  String get namaTampil => namaWp.trim().isEmpty ? '(Tanpa nama)' : namaWp;
  String get nopTampil => nop.trim().isEmpty ? 'NOP tidak diisi' : nop;

  bool get punyaKoordinat => latitude != null && longitude != null;
}
