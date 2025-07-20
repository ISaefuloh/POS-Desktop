class Product {
  final int? id; // tambahkan ini
  final String kode;
  final String nama;
  final String satuan;
  final double hargaJual;
  final int stokTersedia;

  Product({
    this.id, // tambahkan ini
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.hargaJual,
    this.stokTersedia = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // tambahkan ini
      kode: json['kode'],
      nama: json['nama'],
      satuan: json['satuan'],
      hargaJual: json['harga_jual'] is String
          ? double.tryParse(json['harga_jual']) ?? 0.0
          : (json['harga_jual'] as num).toDouble(),
      stokTersedia: json['stok_tersedia'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // optional, berguna untuk PUT
      'kode': kode,
      'nama': nama,
      'satuan': satuan,
      'harga_jual': hargaJual,
    };
  }
}
