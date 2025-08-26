import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/penjualan.dart';
import '../../services/penjualan_service.dart';
import './penjualan_detail_screen.dart';
import './laporan_penjualan_screen.dart';

class PenjualanListScreen extends StatefulWidget {
  const PenjualanListScreen({Key? key}) : super(key: key);

  @override
  State<PenjualanListScreen> createState() => _PenjualanListScreenState();
}

class _PenjualanListScreenState extends State<PenjualanListScreen> {
  final PenjualanService _service = PenjualanService();

  List<Penjualan> penjualanList = [];
  List<Penjualan> filteredList = [];

  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Atur default filter: hanya hari ini
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day); // hari ini jam 00:00
    endDate = DateTime(
        now.year, now.month, now.day, 23, 59, 59); // hari ini jam 23:59

    loadPenjualan();
  }

  Future<void> loadPenjualan() async {
    setState(() => isLoading = true);
    try {
      penjualanList = await _service.getLaporanPenjualan(startDate, endDate);
      applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat penjualan: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredList = penjualanList.where((p) {
        final matchesSearch = (p.nomorNota ?? '')
            .toLowerCase()
            .contains(searchController.text.toLowerCase());

        return matchesSearch;
      }).toList();
    });
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
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
        startDate = picked.start;
        endDate = picked.end;
      });
      await loadPenjualan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

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
            icon: const Icon(Icons.analytics, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LaporanPenjualanScreen()),
              );
            },
            tooltip: 'Laporan Penjualan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              searchController.clear();

              final now = DateTime.now();
              startDate =
                  DateTime(now.year, now.month, now.day); // 00:00 hari ini
              endDate =
                  DateTime(now.year, now.month, now.day, 23, 59, 59); // 23:59

              loadPenjualan();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.point_of_sale, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Daftar Penjualan',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => applyFilters(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari Nomor Nota...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        startDate != null && endDate != null
                            ? 'Periode: ${dateFormat.format(startDate!)} - ${dateFormat.format(endDate!)}'
                            : 'Filter tanggal',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: selectDateRange,
                      icon: const Icon(Icons.date_range, color: Colors.yellow),
                      label: const Text('Pilih Periode',
                          style: TextStyle(color: Colors.yellow)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  )
                : filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum Ada Penjualan Hari Ini',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final p = filteredList[index];
                          final tanggal = DateTime.tryParse(p.tanggal ?? '');
                          //final tanggal = DateTime.tryParse(p.tanggal ?? '') ??DateTime(2000, 1, 1);
                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.yellow),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              title: Text(
                                'Nota: ${p.nomorNota}',
                                style: const TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Tanggal: ${tanggal != null ? DateFormat('dd MMM yyyy').format(tanggal) : 'Tanggal tidak tersedia'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.white),
                              onTap: () {
                                if (p.id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PenjualanDetailScreen(
                                          penjualanId: p.id!),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "ID penjualan tidak tersedia")),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
