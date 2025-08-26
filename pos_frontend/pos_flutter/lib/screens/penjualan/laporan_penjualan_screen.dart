import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/penjualan.dart';
import '../../services/penjualan_service.dart';

class LaporanPenjualanScreen extends StatefulWidget {
  const LaporanPenjualanScreen({super.key});

  @override
  State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
}

class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
  DateTimeRange? selectedDateRange;
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');

  DateTime? _tanggalMulai;
  DateTime? _tanggalAkhir;
  List<Penjualan> _penjualanList = [];
  bool _isLoading = false;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await PenjualanService()
          .getLaporanPenjualan(_tanggalMulai, _tanggalAkhir);
      setState(() => _penjualanList = data);
    } catch (e) {
      debugPrint('Gagal memuat data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _tanggalMulai != null && _tanggalAkhir != null
          ? DateTimeRange(start: _tanggalMulai!, end: _tanggalAkhir!)
          : null,
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
      });
      await _loadData();
    }
  }

  void _loadHariIni() {
    final now = DateTime.now();
    final hariIniMulai = DateTime(now.year, now.month, now.day);
    final hariIniAkhir = hariIniMulai
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    setState(() {
      _tanggalMulai = hariIniMulai;
      _tanggalAkhir = hariIniAkhir;
    });

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _penjualanList.fold<double>(
      0.0,
      (sum, item) => sum + (item.totalHarga ?? 0.0),
    );

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
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Muat Ulang Hari Ini',
            onPressed: _loadHariIni,
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.black),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _penjualanList.isEmpty
              ? const Center(
                  child: Text('Tidak ada data penjualan.',
                      style: TextStyle(color: Colors.white)),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: const [
                          Icon(Icons.assessment,
                              color: Colors.yellow, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Laporan Penjualan',
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Periode: ${dateFormat.format(_tanggalMulai!)} - ${dateFormat.format(_tanggalAkhir!)}',
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
                                minWidth: MediaQuery.of(context).size.width,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade900),
                                dataRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade800),
                                columnSpacing: 16.0,
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow),
                                dataTextStyle:
                                    const TextStyle(color: Colors.white),
                                columns: const [
                                  DataColumn(label: Text('No Nota')),
                                  DataColumn(label: Text('Tanggal')),
                                  DataColumn(label: Text('Pembayaran')),
                                  DataColumn(label: Text('Kembalian')),
                                  DataColumn(label: Text('Total Harga')),
                                ],
                                rows: _penjualanList.map((penjualan) {
                                  return DataRow(cells: [
                                    DataCell(Text(penjualan.nomorNota ?? '-')),
                                    DataCell(Text(penjualan.tanggal != null
                                        ? dateFormat.format(
                                            DateTime.parse(penjualan.tanggal!))
                                        : 'Tanggal Tidak Tersedia')),
                                    DataCell(Text(currencyFormat
                                        .format(penjualan.pembayaran ?? 0.0))),
                                    DataCell(Text(currencyFormat
                                        .format(penjualan.kembalian ?? 0.0))),
                                    DataCell(Text(currencyFormat
                                        .format(penjualan.totalHarga ?? 0.0))),
                                  ]);
                                }).toList(),
                              ),
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
                ),
    );
  }
}
