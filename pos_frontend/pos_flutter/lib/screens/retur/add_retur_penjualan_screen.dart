import 'package:flutter/material.dart';
import 'package:pos_flutter/models/produk_retur_penjualan.dart';
import 'package:pos_flutter/services/retur_penjualan.dart';
import 'retur_penjualan_list_screen.dart';

class ReturPenjualanScreen extends StatefulWidget {
  const ReturPenjualanScreen({super.key});

  @override
  State<ReturPenjualanScreen> createState() => _ReturPenjualanScreenState();
}

class _ReturPenjualanScreenState extends State<ReturPenjualanScreen> {
  final TextEditingController _notaController = TextEditingController();
  List<ProdukRetur> _produkList = [];
  bool _loading = false;

  Future<void> _ambilProduk() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await fetchDetailReturPenjualan(_notaController.text);
      setState(() {
        _produkList = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _kirimSemuaRetur() async {
    final adaYangTidakValid = _produkList.any(
      (item) => item.jumlahRetur > item.jumlahTersisa,
    );

    if (adaYangTidakValid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Validasi Gagal',
              style: TextStyle(color: Colors.yellow)),
          content: const Text(
            'Ada jumlah retur yang melebihi sisa barang. Periksa kembali input Anda.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.yellow)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await kirimSemuaReturPenjualan(
        nomorNota: _notaController.text,
        items: _produkList,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retur berhasil dikirim')),
      );

      setState(() {
        _produkList.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim retur: $e')),
      );
    }
  }

  bool get _adaReturValid => _produkList.any((item) => item.jumlahRetur > 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          'Kidz Electrical',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.black),
            tooltip: 'Daftar Retur Penjualan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReturPenjualanListScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.download_outlined, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Retur Penjualan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _notaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nomor Nota',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.yellow),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _ambilProduk,
                  icon: const Icon(Icons.search),
                  label: const Text('Cek'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow, //[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.yellow))
            else if (_produkList.isEmpty)
              const Center(
                child: Text('Belum ada data produk retur',
                    style: TextStyle(color: Colors.white70)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _produkList.length,
                  itemBuilder: (context, index) {
                    final produk = _produkList[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.yellow),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              produk.namaProduk,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jumlah Transaksi: ${produk.jumlahTransaksi}, Tersisa: ${produk.jumlahTersisa}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: produk.jumlahRetur.toString(),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Jumlah Retur',
                                      labelStyle: const TextStyle(
                                          color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.grey[850],
                                      errorText: produk.jumlahRetur >
                                              produk.jumlahTersisa
                                          ? 'Maks: ${produk.jumlahTersisa}'
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: Colors.yellow),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final input = int.tryParse(val) ?? 0;
                                      setState(() {
                                        produk.jumlahRetur = input;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: produk.keterangan ?? '',
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Keterangan',
                                      labelStyle: const TextStyle(
                                          color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.grey[850],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: Colors.yellow),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        produk.keterangan = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_produkList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _adaReturValid ? _kirimSemuaRetur : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Retur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
