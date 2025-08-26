import 'package:flutter/material.dart';
import 'package:pos_flutter/models/penjualan.dart';
import 'package:pos_flutter/screens/penjualan/nota_printer.dart';
import 'package:pos_flutter/screens/penjualan/kasir/kasir_controller.dart';
import 'package:pos_flutter/screens/penjualan/kasir/keranjang_list.dart';
import 'package:pos_flutter/screens/penjualan/kasir/pembayaran_dialog.dart';
import 'package:pos_flutter/screens/penjualan/kasir/produk_selector.dart';
import 'package:collection/collection.dart';
import 'package:marquee/marquee.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({Key? key}) : super(key: key);

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final KasirController controller = KasirController();
  final TextEditingController jumlahController =
      TextEditingController(text: '1');
  final TextEditingController scannerController = TextEditingController();
  final FocusNode scannerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    controller.loadProduk();
    scannerFocus.requestFocus();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    scannerController.dispose();
    scannerFocus.dispose();
    super.dispose();
  }

  void _showSnack(String message,
      {Color color = Colors.green, Color textColor = Colors.white}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onTambah() {
    try {
      if (controller.selectedProduk != null &&
          controller.selectedProduk!.stokTersedia == 0) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.yellow[600],
            title: const Text(
              '⚠ Stok Habis',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Produk ini stoknya habis dan tidak bisa ditambahkan ke keranjang.',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: Colors.black),
                child: const Text('OK', style: TextStyle(color: Colors.yellow)),
              )
            ],
          ),
        );
        return; // hentikan proses
      }

      controller.tambahKeKeranjang();
      jumlahController.text = controller.jumlah.toString();
      _showSnack('Produk ditambahkan');
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.yellow[600],
          title: const Text(
            '⚠ Perhatian',
            style: TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('OK', style: TextStyle(color: Colors.yellow)),
            )
          ],
        ),
      );
    }
    scannerFocus.requestFocus();
  }

  void _onScanSubmitted(String barcode) {
    final produk = controller.produkList.firstWhereOrNull(
      (p) => p.kode == barcode,
    );

    // Produk tidak ditemukan
    if (produk == null) {
      _showSnack('Produk tidak ditemukan', color: Colors.red);
      scannerController.clear();
      scannerFocus.requestFocus();
      return;
    }

    // Stok habis
    if (produk.stokTersedia == 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.yellow[600],
          title: const Text(
            '⚠ Stok Habis',
            style: TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Produk ini stoknya habis dan tidak bisa ditambahkan ke keranjang.',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('OK', style: TextStyle(color: Colors.yellow)),
            )
          ],
        ),
      );
      scannerController.clear();
      scannerFocus.requestFocus();
      return;
    }

    // Cek apakah produk sudah ada di keranjang
    final index =
        controller.keranjang.indexWhere((i) => i.produkKode == produk.kode);

    if (index != -1) {
      final existing = controller.keranjang[index];

      // Produk sudah ada → popup konfirmasi
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.yellow,
          title: const Text(
            'Produk Sudah Ada',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Produk "${produk.nama}" sudah ada di keranjang.\nMau tambah qty?',
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnack('Tidak ada perubahan qty',
                    color: Colors.yellow, textColor: Colors.black);
                scannerController.clear();
                scannerFocus.requestFocus();
              },
              style: TextButton.styleFrom(backgroundColor: Colors.grey[300]),
              child: const Text('Tidak', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // Validasi stok sebelum tambah
                if (existing.jumlah + 1 > produk.stokTersedia) {
                  _showSnack(
                    'Stok tidak cukup (tersedia: ${produk.stokTersedia})',
                    color: Colors.red,
                  );
                  controller.updateQty(index, produk.stokTersedia);
                } else {
                  controller.updateQty(index, existing.jumlah + 1);
                  _showSnack('Qty berhasil ditambah', color: Colors.green);
                }

                scannerController.clear();
                scannerFocus.requestFocus();
              },
              style: TextButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Ya', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Produk baru → tambahkan langsung jika stok mencukupi
      if (produk.stokTersedia < 1) {
        _showSnack('Stok tidak cukup', color: Colors.red);
      } else {
        setState(() {
          controller.keranjang.add(DetailPenjualan(
            produkId: produk.id ?? 0,
            produkKode: produk.kode,
            produkNama: produk.nama,
            jumlah: 1,
            hargaJual: produk.hargaJual,
            subtotal: produk.hargaJual,
          ));
        });
        _showSnack('Produk berhasil ditambahkan', color: Colors.green);
      }
      scannerController.clear();
      scannerFocus.requestFocus();
    }
  }

  Future<void> _onBayar(double pembayaran) async {
    try {
      final penjualan =
          await controller.simpanPenjualan(pembayaran: pembayaran);
      final salinan = List<DetailPenjualan>.from(controller.keranjang);

      NotaPrinter.cetakNota(
        context,
        penjualan.nomorNota!,
        salinan,
        controller.totalHarga,
        pembayaran,
        pembayaran - controller.totalHarga,
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.grey[900],
          title: const Text('✅ Sukses',
              style: TextStyle(color: Colors.greenAccent, fontSize: 20)),
          content: Text(
            'Penjualan ${penjualan.nomorNota} berhasil',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.yellow)),
            )
          ],
        ),
      ).then((_) {
        setState(() {
          controller.clearKeranjang();
        });
      });
    } catch (e) {
      _showSnack('Gagal memproses pembayaran', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.yellow,
        title: const Text(
          'Kidz Electrical',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner',
            onPressed: () {
              scannerFocus.requestFocus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scanner Siap Digunakan'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
          ),
          // Indikator scanner focus
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: AnimatedBuilder(
              animation: scannerFocus,
              builder: (_, __) {
                return Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: scannerFocus.hasFocus ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.yellow, width: 1),
                  ),
                );
              },
            ),
          ),
        ],
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            color: Colors.black,
            height: 36,
            width: double.infinity,
            child: Marquee(
              text:
                  'KIDZ ELECTRICAL - Jl. Daeng Sutigna, Kaduagung, Kec. Sindangagung, Kab. Kuningan - WA : 085161905031.',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 50.0,
              velocity: 80.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Kiri - Input Produk
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Scanner Hidden
                    Offstage(
                      offstage: true,
                      child: TextField(
                        focusNode: scannerFocus,
                        controller: scannerController,
                        decoration: const InputDecoration(
                          hintText: 'Scan barcode di sini',
                        ),
                        onSubmitted: _onScanSubmitted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header Kasir
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.point_of_sale,
                            color: Colors.yellow, size: 36),
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
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) => ProdukSelector(
                        controller: controller,
                        jumlahController: jumlahController,
                        onTambah: _onTambah,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Total Harga & Bayar
                    AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) => Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    controller
                                        .formatRupiah(controller.totalHarga),
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.keranjang.isEmpty
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => PembayaranDialog(
                                              controller: controller,
                                              onConfirm: (p) => _onBayar(p),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (controller.keranjang.isNotEmpty)
                                        const Icon(Icons.receipt_long,
                                            color: Colors.black),
                                      if (controller.keranjang.isNotEmpty)
                                        const SizedBox(width: 8),
                                      const Text(
                                        'Bayar & Cetak Nota',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Kanan - Keranjang
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛒 Keranjang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) => Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: KeranjangList(controller: controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
