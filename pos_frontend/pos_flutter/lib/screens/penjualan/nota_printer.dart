import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pos_flutter/models/penjualan.dart';
import 'package:flutter/services.dart' show rootBundle;

class NotaPrinter {
  static Future<void> cetakNota(
    BuildContext context,
    String nomorNota,
    List<DetailPenjualan> keranjang,
    double totalHarga,
    double? pembayaran,
    double? kembalian,
  ) async {
    print('Keranjang berisi ${keranjang.length} item');
    for (var item in keranjang) {
      print('Item: ${item.produkNama}, Jumlah: ${item.jumlah}');
    }

    final rupiah =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final doc = pw.Document();

    final fontRegular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

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

                // 🧾 Daftar Item
                ...keranjang.map((item) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.produkNama ?? '[Tanpa Nama Produk]',
                          style: pw.TextStyle(font: fontBold, fontSize: 8)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                              '${item.jumlah} x ${rupiah.format(item.hargaJual)}',
                              style:
                                  pw.TextStyle(font: fontRegular, fontSize: 8)),
                          pw.Text(rupiah.format(item.subtotal),
                              style:
                                  pw.TextStyle(font: fontRegular, fontSize: 8)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }).toList(),

                pw.Divider(thickness: 1),
                // 💰 Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total',
                        style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    pw.Text(rupiah.format(totalHarga),
                        style: pw.TextStyle(font: fontBold, fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bayar',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                    pw.Text(rupiah.format(pembayaran ?? 0),
                        style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                    pw.Text(rupiah.format(kembalian ?? 0),
                        style: pw.TextStyle(font: fontRegular, fontSize: 8)),
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
          }),
    );

    try {
      //await Printing.sharePdf(
      //bytes: await doc.save(), filename: 'nota_debug.pdf');
      await Printing.layoutPdf(onLayout: (format) async => doc.save());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cetak berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
