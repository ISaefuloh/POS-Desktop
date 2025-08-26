// -----------------------------
// kasir_controller.dart
// -----------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:dropdown_search/dropdown_search.dart';

// Import model & services dari projectmu (sesuaikan path jika perlu)
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/models/penjualan.dart';
import 'package:pos_flutter/services/product_service.dart';
import 'package:pos_flutter/services/penjualan_service.dart';
import 'package:pos_flutter/services/nota_service.dart';
//import '../nota_printer.dart';
//import 'package:pos_flutter/screens/penjualan/nota_printer.dart';

class KasirController extends ChangeNotifier {
  final NumberFormat rupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<Product> produkList = [];
  Product? selectedProduk;

  final List<DetailPenjualan> keranjang = [];

  int jumlah = 1;

  double get totalHarga =>
      keranjang.fold(0, (sum, item) => sum + item.subtotal);

  // load produk
  Future<void> loadProduk() async {
    try {
      produkList = await ProductService.getAllProducts();
      notifyListeners();
    } catch (e) {
      // ignore for now, caller can show error
    }
  }

  void pilihProduk(Product? p) {
    selectedProduk = p;
    jumlah = 1;
    notifyListeners();
  }

  String formatRupiah(num value) => rupiah.format(value);

  void setJumlah(int v) {
    if (v <= 0) return;
    jumlah = v;
    notifyListeners();
  }

  String? validateStok() {
    if (selectedProduk == null) return 'Pilih produk dulu';
    if (selectedProduk!.stokTersedia <= 0) {
      return 'Stok produk habis';
    }
    if (jumlah > selectedProduk!.stokTersedia) {
      return 'Stok tidak cukup (tersedia: ${selectedProduk!.stokTersedia})';
    }
    return null;
  }

  bool sudahAdaSelectedProdukDiKeranjang() {
    if (selectedProduk == null) return false;
    return keranjang.any((k) => k.produkId == selectedProduk!.id);
  }

  void tambahKeKeranjang() {
    final err = validateStok();
    if (err != null) throw Exception(err);
    if (selectedProduk == null) throw Exception('Produk belum dipilih');

    final existIndex =
        keranjang.indexWhere((k) => k.produkId == selectedProduk!.id);
    if (existIndex != -1) {
      throw Exception('Produk sudah ada di keranjang');
    }

    final d = DetailPenjualan(
      produkId: selectedProduk!.id ?? 0,
      produkKode: selectedProduk!.kode,
      produkNama: selectedProduk!.nama,
      jumlah: jumlah,
      hargaJual: selectedProduk!.hargaJual,
      subtotal: selectedProduk!.hargaJual * jumlah,
    );

    keranjang.add(d);
    // reset pilihan
    selectedProduk = null;
    jumlah = 1;
    notifyListeners();
  }

  void updateQty(int index, int newQty) {
    if (newQty <= 0) return;

    final item = keranjang[index];

    // Cari produk berdasarkan ID
    final produk = produkList.firstWhere(
      (p) => p.id == item.produkId,
      orElse: () => Product(
        id: 0,
        kode: '',
        nama: '',
        satuan: '',
        hargaJual: 0,
        stokTersedia: 0,
      ),
    );

    // Kalau produk tidak ditemukan atau stok 0 → hentikan
    if (produk.id == 0 || produk.stokTersedia <= 0) {
      throw Exception('Stok produk habis atau produk tidak ditemukan');
    }

    // Validasi stok
    if (newQty > produk.stokTersedia) {
      throw Exception('Stok tidak cukup (tersedia: ${produk.stokTersedia})');
    }

    // Update keranjang
    keranjang[index] = DetailPenjualan(
      produkId: item.produkId,
      produkKode: item.produkKode,
      produkNama: item.produkNama,
      jumlah: newQty,
      hargaJual: item.hargaJual,
      subtotal: newQty * item.hargaJual,
    );

    notifyListeners();
  }

  void hapusItem(int index) {
    keranjang.removeAt(index);
    notifyListeners();
  }

  void clearKeranjang() {
    keranjang.clear();
    notifyListeners();
  }

  Future<Penjualan> simpanPenjualan({required double pembayaran}) async {
    if (keranjang.isEmpty) throw Exception('Keranjang kosong');
    if (pembayaran < totalHarga) throw Exception('Pembayaran kurang');

    final nomorNota = await NotaService().getNomorNotaBaru();

    final data = {
      'nomor_nota': nomorNota,
      'tanggal': DateTime.now().toIso8601String(),
      'total_harga': totalHarga,
      'pembayaran': pembayaran,
      'kembalian': pembayaran - totalHarga,
      'detail_penjualan': keranjang.map((e) => e.toJson()).toList(),
    };

    final penjualan = await PenjualanService().createPenjualan(data);
    return penjualan;
  }
}
