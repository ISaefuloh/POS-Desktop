import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_flutter/models/retur_pembelian.dart';
import 'package:pos_flutter/services/retur_pembelian.dart';

class ReturPembelianListScreen extends StatefulWidget {
  const ReturPembelianListScreen({super.key});

  @override
  State<ReturPembelianListScreen> createState() =>
      _ReturPembelianListScreenState();
}

class _ReturPembelianListScreenState extends State<ReturPembelianListScreen> {
  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;
  Future<List<ReturPembelian>>? _returListFuture;

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _loadHariIni();
  }

  void _loadHariIni() {
    final now = DateTime.now();
    final mulai = DateTime(now.year, now.month, now.day);
    final akhir =
        mulai.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    setState(() {
      _tanggalMulai = mulai;
      _tanggalAkhir = akhir;
      _returListFuture = fetchReturPembelianList(
        tanggalMulai: _tanggalMulai,
        tanggalAkhir: _tanggalAkhir,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow,
              onPrimary: Colors.black,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalMulai = picked.start;
        _tanggalAkhir = picked.end;
        _returListFuture = fetchReturPembelianList(
          tanggalMulai: _tanggalMulai,
          tanggalAkhir: _tanggalAkhir,
        );
      });
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Hari Ini',
            onPressed: _loadHariIni,
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.black),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _returListFuture == null
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : FutureBuilder<List<ReturPembelian>>(
              future: _returListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white)),
                  );
                } else {
                  final data = snapshot.data!;
                  final allRows = <DataRow>[];
                  double totalHarga = 0;

                  for (var retur in data) {
                    for (var detail in retur.detailRetur) {
                      totalHarga += detail.jumlah * detail.hargaBeli;
                      allRows.add(DataRow(cells: [
                        DataCell(Text(
                            dateFormat.format(DateTime.parse(retur.tanggal)))),
                        DataCell(Text(retur.nomorBTB)),
                        DataCell(Text(detail.namaProduk)),
                        DataCell(Text(detail.jumlah.toString())),
                        DataCell(Text(currencyFormat.format(detail.hargaBeli))),
                        DataCell(Text(detail.keterangan?.isNotEmpty == true
                            ? detail.keterangan!
                            : '-')),
                      ]));
                    }
                  }

                  if (allRows.isEmpty) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: const [
                              Icon(Icons.upload_outlined,
                                  color: Colors.yellow, size: 26),
                              SizedBox(width: 8),
                              Text(
                                'Laporan Retur Pembelian',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_tanggalMulai != null && _tanggalAkhir != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Periode: ${dateFormat.format(_tanggalMulai!)} - ${dateFormat.format(_tanggalAkhir!)}',
                              style: const TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                          ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Tidak ada data retur.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: const [
                            Icon(Icons.upload_outlined,
                                color: Colors.yellow, size: 26),
                            SizedBox(width: 8),
                            Text(
                              'Laporan Retur Pembelian',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_tanggalMulai != null && _tanggalAkhir != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'Periode: ${dateFormat.format(_tanggalMulai!)} - ${dateFormat.format(_tanggalAkhir!)}',
                            style: const TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade900),
                                dataRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade800),
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow),
                                dataTextStyle:
                                    const TextStyle(color: Colors.white),
                                columnSpacing: 16.0,
                                columns: const [
                                  DataColumn(label: Text('Tanggal')),
                                  DataColumn(label: Text('Nota')),
                                  DataColumn(label: Text('Produk')),
                                  DataColumn(label: Text('Jumlah')),
                                  DataColumn(label: Text('Harga')),
                                  DataColumn(label: Text('Keterangan')),
                                ],
                                rows: allRows,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.yellow),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Total Harga: ${currencyFormat.format(totalHarga)}',
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
                }
              },
            ),
    );
  }
}
