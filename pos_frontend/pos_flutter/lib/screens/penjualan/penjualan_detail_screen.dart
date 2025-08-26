import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_flutter/models/penjualan.dart';
import 'package:pos_flutter/services/penjualan_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PenjualanDetailScreen extends StatefulWidget {
  final int penjualanId;

  const PenjualanDetailScreen({Key? key, required this.penjualanId})
      : super(key: key);

  @override
  State<PenjualanDetailScreen> createState() => _PenjualanDetailScreenState();
}

class _PenjualanDetailScreenState extends State<PenjualanDetailScreen> {
  late Future<Penjualan> _penjualanFuture;

  @override
  void initState() {
    super.initState();
    _penjualanFuture =
        PenjualanService().getPenjualanDetail(widget.penjualanId);
  }

  double hitungTotalHarga(Penjualan penjualan) {
    return (penjualan.detailPenjualan ?? [])
        .map((d) => d.jumlah * d.hargaJual)
        .fold(0.0, (a, b) => a + b);
  }

  String formatRupiah(double number) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(number);
  }

  void _cetakNota(Penjualan penjualan) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoExtraBold();

    final nomorNota = penjualan.nomorNota;
    final totalHarga = hitungTotalHarga(penjualan);

    final pageFormat = PdfPageFormat(50 * PdfPageFormat.mm, double.infinity);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Center(
                child: pw.Text('KIDZ ELECTRICAL',
                    style: pw.TextStyle(font: fontBold, fontSize: 10)),
              ),
              pw.Center(
                child: pw.Text('Jl. Daeng Sutigna, Kaduagung,',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ),
              pw.Center(
                child: pw.Text('Kec. Sindangagung, Kab. Kuningan.',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ),
              pw.Center(
                child: pw.Text('WA : 085161905031',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.Text(
                'Tanggal : ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: fontRegular, fontSize: 8),
              ),
              pw.Text(
                'No Nota : $nomorNota',
                style: pw.TextStyle(font: fontRegular, fontSize: 8),
              ),
              pw.Divider(thickness: 1),
              ...penjualan.detailPenjualan!.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.produkNama ?? '[Tanpa Nama Produk]',
                        style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            '${item.jumlah} x ${formatRupiah(item.hargaJual)}',
                            style:
                                pw.TextStyle(font: fontRegular, fontSize: 8)),
                        pw.Text(formatRupiah(item.jumlah * item.hargaJual),
                            style:
                                pw.TextStyle(font: fontRegular, fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }).toList(),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total',
                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                  pw.Text(formatRupiah(totalHarga),
                      style: pw.TextStyle(font: fontBold, fontSize: 8)),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Terima Kasih Telah Berbelanja!',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text('Detail Penjualan',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final penjualan = await _penjualanFuture;
              _cetakNota(penjualan);
            },
          ),
        ],
      ),
      body: FutureBuilder<Penjualan>(
        future: _penjualanFuture,
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

          final penjualan = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor Nota: ${penjualan.nomorNota}',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                Text('Tanggal: ${penjualan.tanggal}',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
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
                    itemCount: penjualan.detailPenjualan?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = penjualan.detailPenjualan![index];
                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            '${item.produkKode} - ${item.produkNama}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Jumlah: ${item.jumlah} | Harga: ${formatRupiah(item.hargaJual)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            '${formatRupiah(item.jumlah * item.hargaJual)}',
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
                    'Total Harga: ${formatRupiah(hitungTotalHarga(penjualan))}',
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
