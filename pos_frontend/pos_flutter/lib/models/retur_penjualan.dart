class ReturPenjualan {
  final int id;
  final String tanggal;
  final String nomorNota;
  final List<DetailReturPenjualan> detailRetur;

  ReturPenjualan({
    required this.id,
    required this.tanggal,
    required this.nomorNota,
    required this.detailRetur,
  });

  factory ReturPenjualan.fromJson(Map<String, dynamic> json) {
    return ReturPenjualan(
      id: json['id'],
      tanggal: json['tanggal'],
      nomorNota: json['nomor_nota'],
      detailRetur: (json['detail'] as List)
          .map((e) => DetailReturPenjualan.fromJson(e))
          .toList(),
    );
  }
}

class DetailReturPenjualan {
  final int id;
  final String namaProduk;
  final int jumlah;
  final double hargaJual;
  final String? keterangan; // tambahkan ini

  DetailReturPenjualan({
    required this.id,
    required this.namaProduk,
    required this.jumlah,
    required this.hargaJual,
    this.keterangan,
  });

  factory DetailReturPenjualan.fromJson(Map<String, dynamic> json) {
    return DetailReturPenjualan(
      id: json['id'],
      namaProduk: json['produk_nama'],
      jumlah: json['jumlah'],
      hargaJual: double.tryParse(json['harga_jual'].toString()) ?? 0,
      keterangan: json['keterangan'], // ambil dari JSON jika tersedia
    );
  }
}
