class ReturPembelian {
  final int id;
  final String tanggal;
  final String nomorBTB;
  final List<DetailReturPembelian> detailRetur;

  ReturPembelian({
    required this.id,
    required this.tanggal,
    required this.nomorBTB,
    required this.detailRetur,
  });

  factory ReturPembelian.fromJson(Map<String, dynamic> json) {
    return ReturPembelian(
      id: json['id'],
      tanggal: json['tanggal'],
      nomorBTB: json['nomor_btb'],
      detailRetur: (json['detail'] as List)
          .map((e) => DetailReturPembelian.fromJson(e))
          .toList(),
    );
  }
}

class DetailReturPembelian {
  final int id;
  final String namaProduk;
  final int jumlah;
  final double hargaBeli;
  final String? keterangan;

  DetailReturPembelian({
    required this.id,
    required this.namaProduk,
    required this.jumlah,
    required this.hargaBeli,
    this.keterangan,
  });

  factory DetailReturPembelian.fromJson(Map<String, dynamic> json) {
    return DetailReturPembelian(
      id: json['id'],
      namaProduk: json['produk_nama'],
      jumlah: json['jumlah'],
      hargaBeli: double.tryParse(json['harga_beli'].toString()) ?? 0,
      keterangan: json['keterangan'],
    );
  }
}
