class ProdukRetur {
  final int detailPenjualanId;
  final String namaProduk;
  final int jumlahTransaksi;
  int jumlahRetur;
  final int jumlahTersisa;
  final int harga;
  String? keterangan;

  ProdukRetur({
    required this.detailPenjualanId,
    required this.namaProduk,
    required this.jumlahTransaksi,
    required this.jumlahRetur,
    required this.jumlahTersisa,
    required this.harga,
    this.keterangan,
  });

  factory ProdukRetur.fromJson(Map<String, dynamic> json) {
    return ProdukRetur(
      detailPenjualanId: json['detail_penjualan_id'], // ✅ pakai id ini
      namaProduk: json['nama_produk'],
      jumlahTransaksi: json['jumlah_terjual'],
      jumlahRetur: json['jumlah_sudah_diretur'],
      jumlahTersisa: json['jumlah_bisa_diretur'],
      harga: (json['harga_jual'] as num).toInt(),
      keterangan: null,
    );
  }
}
