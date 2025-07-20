class Penjualan {
  final int? id;
  final String? nomorNota;
  final String? tanggal;
  final double? totalHarga;
  final double? pembayaran;
  final double? kembalian;
  final List<DetailPenjualan>? detailPenjualan;

  Penjualan({
    this.id,
    required this.nomorNota,
    required this.tanggal,
    required this.totalHarga,
    required this.pembayaran,
    required this.kembalian,
    required this.detailPenjualan,
  });

  factory Penjualan.fromJson(Map<String, dynamic> json) {
    List<DetailPenjualan> detailList = [];
    if (json['detail_penjualan'] != null) {
      var list = json['detail_penjualan'] as List;
      detailList = list.map((i) => DetailPenjualan.fromJson(i)).toList();
    }

    return Penjualan(
      id: json['id'],
      nomorNota: json['nomor_nota'] as String?,
      totalHarga: double.tryParse(json['total_harga']?.toString() ?? '0.0'),
      pembayaran: double.tryParse(json['pembayaran']?.toString() ?? '0.0'),
      kembalian: double.tryParse(json['kembalian']?.toString() ?? '0.0'),
      detailPenjualan: detailList,
      tanggal: json['tanggal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomor_nota': nomorNota,
      'total_harga': totalHarga,
      'pembayaran': pembayaran,
      'kembalian': kembalian,
      'detail_penjualan': detailPenjualan?.map((e) => e.toJson()).toList(),
      'tanggal': tanggal,
    };
  }
}

class DetailPenjualan {
  final int produkId;
  final String? produkKode; // Make nullable
  final String? produkNama; // Make nullable
  final int jumlah;
  final double hargaJual;
  final double subtotal;

  DetailPenjualan({
    required this.produkId,
    this.produkKode, // Not required anymore as it's nullable
    this.produkNama, // Not required anymore as it's nullable
    required this.jumlah,
    required this.hargaJual,
    required this.subtotal,
  });

  factory DetailPenjualan.fromJson(Map<String, dynamic> json) {
    final jumlah = int.tryParse(json['jumlah'].toString()) ?? 0;
    final harga = double.tryParse(json['harga_jual'].toString()) ?? 0.0;

    return DetailPenjualan(
      produkId: json['produk'] as int,
      produkKode: json['produk_kode'] as String?,
      produkNama: json['produk_nama'] as String?,
      jumlah: jumlah,
      hargaJual: harga,
      subtotal: json['subtotal'] != null
          ? double.tryParse(json['subtotal'].toString()) ?? 0.0
          : jumlah * harga,
    );
  }

  //factory DetailPenjualan.fromJson(Map<String, dynamic> json) {
  //  return DetailPenjualan(
  //    produkId: json['produk'] as int,
  //    produkKode: json['produk_kode'] as String?,
  //    produkNama: json['produk_nama'] as String?,
  //    jumlah: json['jumlah'] as int,
  //    hargaJual:
  //        double.tryParse(json['harga_jual']?.toString() ?? '0.0') ?? 0.0,
  //    subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
  //  );
  //}

  Map<String, dynamic> toJson() {
    return {
      'produk': produkId,
      'produk_kode': produkKode,
      'produk_nama': produkNama,
      'jumlah': jumlah,
      'harga_jual': hargaJual,
      'subtotal': subtotal,
    };
  }
}
