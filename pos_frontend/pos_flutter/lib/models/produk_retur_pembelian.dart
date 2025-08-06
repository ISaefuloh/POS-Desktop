class ProdukReturPembelian {
  final int detailPembelianId;
  final String namaProduk;
  final int jumlahTransaksi;
  int jumlahRetur;
  final int jumlahTersisa;
  final int harga;
  String? keterangan;

  ProdukReturPembelian({
    required this.detailPembelianId,
    required this.namaProduk,
    required this.jumlahTransaksi,
    required this.jumlahRetur,
    required this.jumlahTersisa,
    required this.harga,
    this.keterangan,
  });

  factory ProdukReturPembelian.fromJson(Map<String, dynamic> json) {
    return ProdukReturPembelian(
      detailPembelianId: json['detail_pembelian_id'], // sesuai backend
      namaProduk: json['nama_produk'],
      jumlahTransaksi: json['jumlah_dibeli'],
      jumlahRetur: json['jumlah_sudah_diretur'],
      jumlahTersisa: json['jumlah_bisa_diretur'],
      harga: (json['harga_beli'] as num).toInt(),
      keterangan: null,
    );
  }
}
