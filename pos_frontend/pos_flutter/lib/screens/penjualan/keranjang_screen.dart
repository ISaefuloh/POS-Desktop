import 'package:flutter/material.dart';
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/models/penjualan.dart';
//import 'package:pos_flutter/models/keranjang_item.dart';
import 'package:pos_flutter/services/penjualan_service.dart';
import 'package:pos_flutter/services/product_service.dart';
import 'package:pos_flutter/services/nota_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import './laporan_penjualan_screen.dart';
import './penjualan_list_screen.dart';
import 'nota_printer.dart';
//import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
//import 'package:collection/collection.dart';

//import './scan_printer_screen.dart';
//import './pengaturan_printer_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({Key? key}) : super(key: key);

  @override
  _KeranjangScreenState createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final TextEditingController _jumlahController =
      TextEditingController(text: '1');
  final TextEditingController _pembayaranController = TextEditingController();
  final TextEditingController _kembalianController = TextEditingController();
  final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final FocusNode _scannerFocus = FocusNode();
  final TextEditingController _scannerController = TextEditingController();

  List<Product> produkList = [];
  Product? selectedProduk;
  List<DetailPenjualan> keranjang = [];
  int jumlah = 1;
  double totalHarga = 0;

  @override
  void initState() {
    super.initState();
    _loadProduk();
    _jumlahController.addListener(_onJumlahChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_scannerFocus);
    });
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _pembayaranController.dispose();
    _kembalianController.dispose();
    super.dispose();
  }

  void _onJumlahChanged() {
    if (_jumlahController.text.isNotEmpty) {
      final int? parsedJumlah = int.tryParse(_jumlahController.text);
      if (parsedJumlah != null && parsedJumlah > 0) {
        setState(() {
          jumlah = parsedJumlah;
        });
      } else {
        setState(() {
          jumlah = 1;
          _jumlahController.text = '1';
        });
      }
    } else {
      setState(() {
        jumlah = 1;
        _jumlahController.text = '1';
      });
    }
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  Future<void> _loadProduk() async {
    try {
      final produk = await ProductService.getAllProducts();
      setState(() {
        produkList = produk;
      });
    } catch (e) {
      print('Gagal memuat produk: $e');
    }
  }

  void _updateTotal() {
    totalHarga = keranjang.fold(0, (sum, item) => sum + item.subtotal);
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  void _tambahKeKeranjang() {
    if (selectedProduk == null) return;

    final stokTersedia = selectedProduk!.stokTersedia;

    if (jumlah > stokTersedia) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.yellow.shade700, // Latar belakang kuning
          title: Text('Stok Tidak Cukup'),
          content: Text(
            'Stok produk \'${selectedProduk!.nama}\' tidak cukup (tersedia: $stokTersedia, diminta: $jumlah)',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog saat tombol OK ditekan
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Tombol hitam
              ),
              child: Text(
                'OK',
                style: TextStyle(
                    color: Colors.yellow.shade700), // Tulisan OK kuning
              ),
            ),
          ],
        ),
      );
      return;
    }

    final isProdukSudahAda =
        keranjang.any((item) => item.produkId == selectedProduk!.id);

    if (isProdukSudahAda) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.yellow.shade700, // Latar belakang kuning
          title: Text('Produk Sudah Ada'),
          content: Text('Produk sudah ada di keranjang.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog saat tombol OK ditekan
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Tombol hitam
              ),
              child: Text(
                'OK',
                style: TextStyle(
                    color: Colors.yellow.shade700), // Tulisan OK kuning
              ),
            ),
          ],
        ),
      );
      return;
    }

    final detail = DetailPenjualan(
      produkId: selectedProduk!.id ?? 0,
      produkKode: selectedProduk!.kode,
      produkNama: selectedProduk!.nama,
      jumlah: jumlah,
      hargaJual: selectedProduk!.hargaJual,
      subtotal: selectedProduk!.hargaJual * jumlah,
    );

    setState(() {
      keranjang.add(detail);
      jumlah = 1;
      _jumlahController.text = '1';
      selectedProduk = null;
      _updateTotal();
    });
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  void _kurangiJumlah() {
    setState(() {
      if (jumlah > 1) {
        jumlah--;
        _jumlahController.text = jumlah.toString();
      }
    });
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  void _tambahJumlah() {
    setState(() {
      jumlah++;
      _jumlahController.text = jumlah.toString();
    });
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  void _hitungKembalian(String value) {
    if (value.isNotEmpty) {
      final double? pembayaran = double.tryParse(value);
      if (pembayaran != null) {
        final double kembalian = pembayaran - totalHarga;
        setState(() {
          _kembalianController.text =
              kembalian >= 0 ? _rupiahFormat.format(kembalian) : 'Kurang Bayar';
        });
      } else {
        setState(() {
          _kembalianController.text = '';
        });
      }
    } else {
      setState(() {
        _kembalianController.text = '';
      });
    }
  }

  void _prosesPenjualanDenganPembayaran() async {
    if (keranjang.isEmpty) return;

    final String pembayaranText = _pembayaranController.text.trim();

    if (pembayaranText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Input pembayaran tidak boleh kosong.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    double? pembayaran =
        double.tryParse(pembayaranText.replaceAll(RegExp(r'[^\d]'), ''));
    if (pembayaran == null || pembayaran < totalHarga) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah pembayaran kurang.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final String nomorNota = await NotaService().getNomorNotaBaru();

      final data = {
        'nomor_nota': nomorNota,
        'tanggal': DateTime.now().toIso8601String(),
        'total_harga': totalHarga,
        'pembayaran': pembayaran,
        'kembalian': pembayaran - totalHarga,
        'detail_penjualan': keranjang.map((e) => e.toJson()).toList(),
      };

      //final penjualan = await PenjualanService().createPenjualan(data);

      final salinanKeranjang =
          List<DetailPenjualan>.from(keranjang); // <- ini penting

      final penjualan = await PenjualanService().createPenjualan(data);

      NotaPrinter.cetakNota(
        context,
        penjualan.nomorNota!,
        salinanKeranjang, // <- pakai ini
        totalHarga,
        pembayaran,
        pembayaran - totalHarga,
      );

      //NotaPrinter.cetakNota(context, penjualan.nomorNota!, keranjang,
      //    totalHarga, pembayaran, pembayaran - totalHarga);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text('Transaksi Sukses',
              style: TextStyle(color: Colors.white)),
          content: Text('Penjualan ${penjualan.nomorNota} berhasil!',
              style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('OK', style: TextStyle(color: Colors.yellow.shade700)),
            ),
          ],
        ),
      );

      setState(() {
        keranjang.clear();
        totalHarga = 0;
        _pembayaranController.clear();
        _kembalianController.clear();
      });
    } catch (e) {
      // ✅ Tampilkan error di alert
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.yellow.shade700,
          title: Text('Gagal Menyimpan'),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // latar tombol
                foregroundColor: Color(0xFFFFD700), // teks/ikon kuning (emas)
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(
      //    content: Text(e.toString().replaceFirst('Exception: ', '')),
      //    backgroundColor: Colors.red,
      //  ),
      //);
    }
    FocusScope.of(context).requestFocus(_scannerFocus);
  }

  void _handleBarcodeScan(String barcode) {
    final produk =
        produkList.where((p) => p.kode == barcode).toList().isNotEmpty
            ? produkList.firstWhere((p) => p.kode == barcode)
            : null;

    if (produk != null && produk.id != null) {
      setState(() {
        final index =
            keranjang.indexWhere((item) => item.produkKode == produk.kode);
        if (index != -1) {
          final existing = keranjang[index];
          keranjang[index] = DetailPenjualan(
            produkId: existing.produkId,
            produkKode: existing.produkKode,
            produkNama: existing.produkNama,
            jumlah: existing.jumlah + 1,
            hargaJual: existing.hargaJual,
            subtotal: (existing.jumlah + 1) * existing.hargaJual,
          );
        } else {
          keranjang.add(
            DetailPenjualan(
              produkId: produk.id!, // pastikan nullable
              produkKode: produk.kode,
              produkNama: produk.nama,
              jumlah: 1,
              hargaJual: produk.hargaJual,
              subtotal: produk.hargaJual,
            ),
          );
        }
        _updateTotal();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red, // warna latar belakang
          content: Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ), // warna teks
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Kidz Electrical',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.barcode_reader, color: Colors.black),
            onPressed: () {
              FocusScope.of(context).requestFocus(_scannerFocus);
            },
            tooltip: 'Scan',
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LaporanPenjualanScreen()),
              );
            },
            tooltip: 'Laporan Penjualan',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PenjualanListScreen()),
              );
            },
            tooltip: 'Nota Penjualan',
          ),
          /*
          IconButton(
            icon: const Icon(
              Icons.print,
              color: Colors.black,
            ),
            tooltip: 'Pilih Printer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsPage(),
                ),
              );
            },
          ), */
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Offstage(
                      offstage: true, // Tidak terlihat
                      child: TextField(
                        focusNode: _scannerFocus,
                        controller: _scannerController,
                        onSubmitted: (barcode) {
                          _handleBarcodeScan(barcode.trim());
                          _scannerController.clear(); // Reset input
                          FocusScope.of(context)
                              .requestFocus(_scannerFocus); // ⬅️ Kunci penting
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 20, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.shopping_bag,
                              color: Colors.yellow, size: 40),
                          SizedBox(width: 8),
                          Text(
                            'Kasir',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 4,
                      color: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Produk',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            DropdownSearch<Product>(
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Cari Produk...",
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  hintText: selectedProduk == null
                                      ? "Cari produk berdasarkan kode atau nama"
                                      : null,
                                  hintStyle:
                                      const TextStyle(color: Colors.white54),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade600),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade600),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.yellow.shade700),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade800,
                                ),
                                baseStyle: const TextStyle(color: Colors.white),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: 'Cari Produk...',
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    hintText: 'Ketik kode atau nama produk...',
                                    hintStyle:
                                        const TextStyle(color: Colors.white54),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.yellow.shade700),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade600),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                  ),
                                ),
                                itemBuilder: (context, item, isSelected) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.yellow.shade700
                                              .withOpacity(0.2)
                                          : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${item.kode} - ${item.nama}',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                },
                                menuProps: MenuProps(
                                  backgroundColor: Colors.grey.shade800,
                                ),
                              ),
                              items: produkList,
                              itemAsString: (Product u) =>
                                  '${u.kode} - ${u.nama}',
                              onChanged: (Product? data) {
                                setState(() {
                                  selectedProduk = data;
                                  jumlah = 1;
                                  _jumlahController.text = '1';
                                });
                              },
                              selectedItem: selectedProduk,
                              dropdownButtonProps: const DropdownButtonProps(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _jumlahController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade600),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade600),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.yellow.shade700),
                                      ),
                                      labelText: 'Jumlah',
                                      labelStyle: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline,
                                          color: Colors.yellow.shade700),
                                      onPressed: _tambahJumlah,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline,
                                          color: Colors.yellow.shade700),
                                      onPressed: _kurangiJumlah,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _tambahKeKeranjang,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.yellow,
                                  ),
                                  child: const Text('Tambah'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Keranjang',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    keranjang.isEmpty
                        ? const Text(
                            'Keranjang masih kosong',
                            style: TextStyle(color: Colors.white70),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: keranjang.length,
                            itemBuilder: (context, index) {
                              final item = keranjang[index];
                              final qtyController = TextEditingController(
                                  text: item.jumlah.toString());

                              return Card(
                                color: Colors.grey.shade800,
                                child: ListTile(
                                  title: Text(
                                    '${item.produkKode} - ${item.produkNama}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Qty: ',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          SizedBox(
                                            width: 50,
                                            child: TextField(
                                              controller: qtyController,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 4,
                                                        horizontal: 6),
                                                border: OutlineInputBorder(),
                                              ),
                                              onSubmitted: (value) {
                                                final newQty =
                                                    int.tryParse(value) ??
                                                        item.jumlah;
                                                if (newQty > 0) {
                                                  setState(() {
                                                    keranjang[index] =
                                                        DetailPenjualan(
                                                      produkId: item.produkId,
                                                      produkKode:
                                                          item.produkKode,
                                                      produkNama:
                                                          item.produkNama,
                                                      jumlah: newQty,
                                                      hargaJual: item.hargaJual,
                                                      subtotal: item.hargaJual *
                                                          newQty,
                                                    );
                                                    _updateTotal();
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'x ${_rupiahFormat.format(item.hargaJual)} = ${_rupiahFormat.format(item.subtotal)}',
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        keranjang.removeAt(index);
                                        _updateTotal();
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Harga:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _rupiahFormat.format(totalHarga),
                                style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller:
                                _pembayaranController, // Tambahkan controller ini
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.yellow.shade700),
                              ),
                              labelText: 'Pembayaran',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.grey.shade800,
                            ),
                            onChanged: (value) {
                              // Hapus semua karakter non-digit
                              String cleanedValue =
                                  value.replaceAll(RegExp(r'[^\d]'), '');

                              if (cleanedValue.isNotEmpty) {
                                // Parse ke double
                                final double? parsedValue =
                                    double.tryParse(cleanedValue);
                                if (parsedValue != null) {
                                  // Format ke Rupiah
                                  String formattedValue =
                                      _rupiahFormat.format(parsedValue);

                                  // Set nilai controller tanpa memicu perubahan lagi (untuk menghindari infinite loop)
                                  if (_pembayaranController.text !=
                                      formattedValue) {
                                    _pembayaranController.value =
                                        TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                          offset: formattedValue.length),
                                    );
                                  }
                                  // Hitung kembalian setelah pembayaran diubah
                                  _hitungKembalian(
                                      cleanedValue); // Gunakan nilai yang belum diformat untuk perhitungan
                                } else {
                                  // Jika parsing gagal, mungkin input tidak valid, clear controller
                                  _pembayaranController.clear();
                                  _kembalianController.clear();
                                }
                              } else {
                                // Jika input kosong, clear controller dan kembalian
                                _pembayaranController.clear();
                                _kembalianController.clear();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _kembalianController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Kembalian',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.yellow.shade700),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _prosesPenjualanDenganPembayaran,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                            ),
                            child: const Text('Bayar & Cetak Nota',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
