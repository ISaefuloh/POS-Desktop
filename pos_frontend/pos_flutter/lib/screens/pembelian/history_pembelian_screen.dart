import 'package:flutter/material.dart';
import 'package:pos_flutter/models/pembelian.dart';
import 'package:pos_flutter/services/pembelian_service.dart';

class HistoryPembelianScreen extends StatefulWidget {
  @override
  State<HistoryPembelianScreen> createState() => _HistoryPembelianScreenState();
}

class _HistoryPembelianScreenState extends State<HistoryPembelianScreen> {
  late Future<List<Pembelian>> _futurePembelian;

  @override
  void initState() {
    super.initState();
    _futurePembelian = PembelianService.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Riwayat Pembelian")),
      body: FutureBuilder<List<Pembelian>>(
        future: _futurePembelian,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          final pembelianList = snapshot.data!;
          return ListView.builder(
            itemCount: pembelianList.length,
            itemBuilder: (context, index) {
              final p = pembelianList[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text("BTB: ${p.nomorBtb}"),
                  subtitle: Text(
                      "Tanggal: ${p.tanggal} • Supplier: ${p.supplier ?? '-'}"),
                  children: p.detailPembelian.map((d) {
                    return ListTile(
                      title: Text(d.produkNama),
                      subtitle: Text(
                          "Jumlah: ${d.jumlah} • Harga: Rp ${d.hargaBeli.toStringAsFixed(0)}"),
                      trailing: Text(
                          "Subtotal: Rp ${(d.jumlah * d.hargaBeli).toStringAsFixed(0)}"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
