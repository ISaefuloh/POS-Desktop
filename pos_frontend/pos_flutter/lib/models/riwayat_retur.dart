class RiwayatRetur {
  final int id;
  final String tanggal;
  final String namaProduk;
  final int jumlah;
  final String keterangan;

  RiwayatRetur({
    required this.id,
    required this.tanggal,
    required this.namaProduk,
    required this.jumlah,
    required this.keterangan,
  });

  factory RiwayatRetur.fromJson(Map<String, dynamic> json) {
    return RiwayatRetur(
      id: json['id'],
      tanggal: json['tanggal'],
      namaProduk: json['nama_produk'] ?? 'Produk',
      jumlah: json['jumlah'],
      keterangan: json['keterangan'] ?? '',
    );
  }
}
