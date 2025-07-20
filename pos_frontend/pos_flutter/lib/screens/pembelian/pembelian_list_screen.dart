import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pembelian.dart';
import '../../services/pembelian_service.dart';
import 'pembelian_detail_screen.dart';
import 'laporan_pembelian_screen.dart';
import 'add_pembelian_screen.dart';

class PembelianListScreen extends StatefulWidget {
  const PembelianListScreen({Key? key}) : super(key: key);

  @override
  State<PembelianListScreen> createState() => _PembelianListScreenState();
}

class _PembelianListScreenState extends State<PembelianListScreen> {
  List<Pembelian> pembelianList = [];
  List<Pembelian> filteredList = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    loadPembelian();
  }

  Future<void> loadPembelian() async {
    setState(() => isLoading = true);
    try {
      pembelianList = await PembelianService.getAll();
      applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat pembelian: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredList = pembelianList.where((p) {
        final matchesSearch = (p.nomorBtb ?? '').toLowerCase().contains(
              searchController.text.toLowerCase(),
            );

        final tanggal = DateTime.parse(p.tanggal);
        final matchesDate = (startDate == null ||
                tanggal
                    .isAfter(startDate!.subtract(const Duration(days: 1)))) &&
            (endDate == null ||
                tanggal.isBefore(endDate!.add(const Duration(days: 1))));

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow, // Warna highlight (misal tanggal dipilih)
              onPrimary: Colors.black, // Warna teks di atas warna primary
              surface: Colors.grey, // Warna latar dialog
              onSurface: Colors.white, // Warna teks default
            ),
            dialogBackgroundColor: Colors.black, // Latar belakang kalender
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
      applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

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
            icon: const Icon(Icons.assessment, color: Colors.black),
            tooltip: 'Laporan Pembelian',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LaporanPembelianScreen(),
                  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              searchController.clear();
              startDate = null;
              endDate = null;
              loadPembelian();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahPembelianScreen()),
          );
          if (result == true) loadPembelian();
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identitas Layar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.shopping_cart, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Daftar Pembelian',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search + Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => applyFilters(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari BTB...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow.shade700),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow.shade700),
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
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Isi Data
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  )
                : filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada data yang cocok',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final p = filteredList[index];
                          final tanggal = DateTime.parse(p.tanggal);

                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.yellow.shade700),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              title: Text(
                                'BTB: ${p.nomorBtb}',
                                style: const TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Tanggal: ${dateFormat.format(tanggal)}\nSupplier: ${p.supplier ?? "-"}',
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.4),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.white),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPembelianScreen(
                                        pembelianId: p.id!),
                                  ),
                                );
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
