class DetailPembelian {
  final int? id;
  final int produkId;
  final String produkKode;
  final String produkNama;
  final int jumlah;
  final double hargaBeli;

  DetailPembelian({
    this.id,
    required this.produkId,
    required this.produkKode,
    required this.produkNama,
    required this.jumlah,
    required this.hargaBeli,
  });

  factory DetailPembelian.fromJson(Map<String, dynamic> json) {
    return DetailPembelian(
      id: json['id'],
      produkId: json['produk_id'] ?? json['produk'],
      produkKode:
          json['produk_kode']?.toString() ?? json['kode']?.toString() ?? '',
      produkNama: json['produk_nama'] ?? json['nama'] ?? '',
      jumlah: json['jumlah'],
      hargaBeli: double.tryParse(json['harga_beli'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produk': produkId,
      'jumlah': jumlah,
      'harga_beli': hargaBeli,
    };
  }
}

class Pembelian {
  final int? id;
  final String? nomorBtb; // sekarang nullable
  final String tanggal;
  final String? supplier;
  final List<DetailPembelian> detailPembelian;

  Pembelian({
    this.id,
    this.nomorBtb,
    required this.tanggal,
    this.supplier,
    required this.detailPembelian,
  });

  factory Pembelian.fromJson(Map<String, dynamic> json) {
    return Pembelian(
      id: json['id'],
      nomorBtb: json['nomor_btb'],
      tanggal: json['tanggal'],
      supplier: json['supplier'],
      detailPembelian: (json['detail_pembelian'] as List)
          .map((item) => DetailPembelian.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'nomor_btb': nomorBtb, // Dihapus karena backend akan generate otomatis
      'tanggal': tanggal,
      'supplier': supplier,
      'detail_pembelian': detailPembelian.map((e) => e.toJson()).toList(),
    };
  }

  double get totalHarga {
    return detailPembelian.fold(
      0.0,
      (sum, item) => sum + (item.hargaBeli * item.jumlah),
    );
  }
}
