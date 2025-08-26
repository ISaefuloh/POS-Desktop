import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pembelian.dart';
import '../../services/pembelian_service.dart';

class LaporanPembelianScreen extends StatefulWidget {
  const LaporanPembelianScreen({super.key});

  @override
  _LaporanPembelianScreenState createState() => _LaporanPembelianScreenState();
}

class _LaporanPembelianScreenState extends State<LaporanPembelianScreen> {
  DateTimeRange? selectedDateRange;
  final dateFormat = DateFormat('dd MMM yyyy');
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Set default ke hari ini
    selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        selectedDateRange = pickedRange;
      });
    }
  }

  Future<List<Pembelian>> fetchPembelian() async {
    return await PembelianService.getAll();
  }

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
            icon: const Icon(Icons.date_range, color: Colors.black),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Identitas Layar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: const [
                Icon(Icons.assessment, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Laporan Pembelian',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Periode: ${dateFormat.format(selectedDateRange!.start)} - ${dateFormat.format(selectedDateRange!.end)}',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Expanded(
            child: FutureBuilder<List<Pembelian>>(
              future: fetchPembelian(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.yellow));
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada data pembelian.',
                          style: TextStyle(color: Colors.white)));
                }

                final pembelianList = snapshot.data!;
                final filtered = pembelianList.where((p) {
                  DateTime tgl = DateTime.parse(p.tanggal);
                  if (selectedDateRange != null &&
                      (tgl.isBefore(selectedDateRange!.start) ||
                          tgl.isAfter(selectedDateRange!.end))) {
                    return false;
                  }
                  return true;
                }).toList();

                double grandTotal = 0;
                for (var pembelian in filtered) {
                  double total = pembelian.detailPembelian.fold(
                      0.0,
                      (sum, item) =>
                          sum + (item.hargaBeli.toDouble() * item.jumlah));
                  grandTotal += total;
                }

                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(
                            12.0), // ✅ Tambahkan padding di sini
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade900),
                              dataRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade800),
                              columnSpacing: 16.0,
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow),
                              dataTextStyle:
                                  const TextStyle(color: Colors.white),
                              columns: const [
                                DataColumn(label: Text('No BTB')),
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Supplier')),
                                DataColumn(label: Text('Total Harga')),
                              ],
                              rows: filtered.map((pembelian) {
                                final total = pembelian.detailPembelian.fold(
                                  0.0,
                                  (sum, item) =>
                                      sum +
                                      (item.hargaBeli.toDouble() * item.jumlah),
                                );
                                return DataRow(cells: [
                                  DataCell(Text(pembelian.nomorBtb ?? '-')),
                                  DataCell(Text(dateFormat.format(
                                      DateTime.parse(pembelian.tanggal)))),
                                  DataCell(Text(pembelian.supplier ?? '-')),
                                  DataCell(Text(currencyFormat.format(total))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(color: Colors.yellow),
                    // Grand total
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Grand Total: ${currencyFormat.format(grandTotal)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
