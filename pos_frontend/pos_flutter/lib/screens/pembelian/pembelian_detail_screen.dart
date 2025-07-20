import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl untuk NumberFormat
import 'package:pos_flutter/models/pembelian.dart';
import 'package:pos_flutter/services/pembelian_service.dart';

class DetailPembelianScreen extends StatefulWidget {
  final int pembelianId;

  const DetailPembelianScreen({super.key, required this.pembelianId});

  @override
  State<DetailPembelianScreen> createState() => _DetailPembelianScreenState();
}

class _DetailPembelianScreenState extends State<DetailPembelianScreen> {
  late Future<Pembelian?> _pembelianFuture;

  @override
  void initState() {
    super.initState();
    _pembelianFuture = PembelianService.getDetail(widget.pembelianId);
  }

  double hitungTotalHarga(Pembelian pembelian) {
    return pembelian.detailPembelian
        .map((d) => d.jumlah * d.hargaBeli)
        .fold(0.0, (a, b) => a + b);
  }

  // Fungsi untuk memformat angka ke format Rupiah
  String formatRupiah(double number) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 251, 192, 45),
        title: const Text('Detail Pembelian',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      ),
      body: FutureBuilder<Pembelian?>(
        future: _pembelianFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.yellow));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Data tidak ditemukan',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final pembelian = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor BTB: ${pembelian.nomorBtb}',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                Text('Tanggal: ${pembelian.tanggal}',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                if (pembelian.supplier != null)
                  Text('Supplier: ${pembelian.supplier}',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 20),
                const Text(
                  'Detail Produk:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: pembelian.detailPembelian.length,
                    itemBuilder: (context, index) {
                      final item = pembelian.detailPembelian[index];
                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            '${item.produkKode} - ${item.produkNama}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Jumlah: ${item.jumlah} | Harga: ${formatRupiah(item.hargaBeli)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            '${formatRupiah(item.jumlah * item.hargaBeli)}',
                            style: const TextStyle(color: Colors.yellow),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.yellow),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total Harga: ${formatRupiah(hitungTotalHarga(pembelian))}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
