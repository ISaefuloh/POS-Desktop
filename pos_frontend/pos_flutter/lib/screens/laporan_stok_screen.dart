import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/laporan_stok_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
//import 'package:path_provider/path_provider.dart';
//import 'dart:io';

class LaporanStokScreen extends StatefulWidget {
  const LaporanStokScreen({super.key});

  @override
  State<LaporanStokScreen> createState() => _LaporanStokScreenState();
}

class _LaporanStokScreenState extends State<LaporanStokScreen> {
  late Future<List<Map<String, dynamic>>> _laporanFuture;
  late DateTimeRange _selectedRange;

  final dateFormat = DateFormat('yyyy-MM-dd');
  String _searchKeyword = '';
  bool _hanyaYangAdaStok = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(today.year, today.month, today.day),
      end: DateTime(today.year, today.month, today.day),
    );
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _laporanFuture = fetchLaporanStok(
        start: dateFormat.format(_selectedRange.start),
        end: dateFormat.format(_selectedRange.end),
      );
    });
  }

  void _filterLaporan(String keyword) {
    setState(() {
      _searchKeyword = keyword.toLowerCase();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
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
        _selectedRange = picked;
      });
      _fetchData();
    }
  }

  List<Map<String, dynamic>> _getFilteredData(List<Map<String, dynamic>> data) {
    return data.where((item) {
      final stokAkhir = item['stok_akhir'] ?? 0;

      if (_hanyaYangAdaStok && stokAkhir <= 0) return false;

      if (_searchKeyword.isEmpty) return true;

      final kode = item['kode'].toString().toLowerCase();
      final nama = item['nama'].toString().toLowerCase();
      return kode.contains(_searchKeyword) || nama.contains(_searchKeyword);
    }).toList();
  }

  Future<void> _printLaporanStok(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Stok - Kidz Electrical',
                  style: pw.TextStyle(font: font, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Periode: ${dateFormat.format(_selectedRange.start)} - ${dateFormat.format(_selectedRange.end)}',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Kode', 'Nama', 'Awal', 'Masuk', 'Keluar', 'Akhir'],
                data: data.map((item) {
                  return [
                    item['kode'].toString(),
                    item['nama'].toString(),
                    item['stok_awal'].toString(),
                    item['stok_masuk'].toString(),
                    item['stok_keluar'].toString(),
                    item['stok_akhir'].toString(),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, font: font, fontSize: 10),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    // Tampilkan preview dan print
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            icon: Icon(
              _hanyaYangAdaStok ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            tooltip: _hanyaYangAdaStok
                ? 'Tampilkan semua (termasuk stok kosong)'
                : 'Hanya tampilkan yang ada stok',
            onPressed: () {
              setState(() {
                _hanyaYangAdaStok = !_hanyaYangAdaStok;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.black),
            tooltip: 'Pilih Periode',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.black),
            tooltip: 'Cetak PDF',
            onPressed: () async {
              final snapshot = await _laporanFuture;
              final filteredData = _getFilteredData(snapshot);
              await _printLaporanStok(filteredData);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _laporanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final laporan = _getFilteredData(snapshot.data ?? []);
          if (laporan.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data stok.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: const [
                    Icon(Icons.inventory, color: Colors.yellow, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Laporan Stok',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  style: const TextStyle(color: Colors.yellow),
                  decoration: InputDecoration(
                    hintText: 'Cari kode atau nama produk...',
                    hintStyle: const TextStyle(color: Colors.yellow),
                    prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.yellow),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.yellow),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _filterLaporan,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Periode: ${dateFormat.format(_selectedRange.start)} - ${dateFormat.format(_selectedRange.end)}',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: screenWidth,
                        ),
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(Colors.grey.shade900),
                          dataRowColor:
                              WidgetStateProperty.all(Colors.grey.shade800),
                          columnSpacing: 16.0,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                          dataTextStyle: const TextStyle(color: Colors.white),
                          columns: const [
                            DataColumn(label: Text('Kode')),
                            DataColumn(label: Text('Nama')),
                            DataColumn(label: Text('Awal')),
                            DataColumn(label: Text('Masuk')),
                            DataColumn(label: Text('Keluar')),
                            DataColumn(label: Text('Akhir')),
                          ],
                          rows: laporan.map((item) {
                            return DataRow(cells: [
                              DataCell(Text(item['kode'])),
                              DataCell(Text(item['nama'])),
                              DataCell(Text(item['stok_awal'].toString())),
                              DataCell(Text(item['stok_masuk'].toString())),
                              DataCell(Text(item['stok_keluar'].toString())),
                              DataCell(Text(item['stok_akhir'].toString())),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
