import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';

class KasirHomeScreen extends StatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  State<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends State<KasirHomeScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();

    // Auto refresh tiap 30 detik
    _autoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadDashboard();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final result = await DashboardService.fetchDashboard();
    if (mounted) {
      setState(() {
        data = result;
        loading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (mounted) {
      context.go('/login');
    }
  }

  // ----------------- UI Components -----------------
  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow),
      title: Text(label, style: const TextStyle(color: Colors.yellow)),
      hoverColor: Colors.yellow.withOpacity(0.1),
      onTap: () => context.push(route),
    );
  }

  Widget buildStatCard(
      String title, String value, IconData? icon, Color color) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.2),
              child: icon != null
                  ? Icon(icon, color: color, size: 28)
                  : Text(
                      "Rp",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildChart() {
    final produkTerjual = (data?['produk_terjual'] ?? []) as List;

    if (produkTerjual.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Belum ada data produk terjual",
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Produk Terjual",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    produkTerjual.length,
                    (i) {
                      final p = produkTerjual[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (p['total_terjual'] as num).toDouble(),
                            color: Colors.yellow,
                            width: 20,
                            borderRadius: BorderRadius.circular(6),
                          )
                        ],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= produkTerjual.length) {
                            return const SizedBox.shrink();
                          }
                          final p = produkTerjual[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              p['produk__nama'],
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- MAIN BUILD -----------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.yellow),
        ),
      );
    }

    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dynamic rawOmzet = data?['omzet_today'] ?? 0;
    final num omzetNum =
        (rawOmzet is num) ? rawOmzet : num.tryParse('$rawOmzet') ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: Colors.grey[900],
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Kidz Electrical",
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.yellow, thickness: 1),
                _buildSidebarItem(
                    context, Icons.point_of_sale, "Kasir V2", '/kasirv2'),
                //_buildSidebarItem(
                //    context, Icons.account_box, "Users", '/users'),
                //_buildSidebarItem(
                //    context, Icons.inventory, "Produk", '/produk'),
                _buildSidebarItem(
                    context, Icons.receipt_long, "Pembelian", '/pembelian'),
                _buildSidebarItem(
                    context, Icons.sell, "Penjualan", '/penjualan'),
                //_buildSidebarItem(
                //    context, Icons.point_of_sale, "Kasir V1", '/kasirv1'),
                _buildSidebarItem(
                    context, Icons.undo, "Retur Penjualan", '/retur-penjualan'),
                _buildSidebarItem(
                    context, Icons.redo, "Retur Pembelian", '/retur-pembelian'),
                _buildSidebarItem(
                    context, Icons.assessment, "Laporan Stok", '/laporanstok'),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.yellow),
                  title: const Text("Logout",
                      style: TextStyle(color: Colors.yellow)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      const Text("Dashboard Laporan",
                          style: TextStyle(
                              fontSize: 28,
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.yellow),
                        onPressed: _loadDashboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      buildStatCard(
                        "Omzet Hari Ini",
                        rupiah.format(omzetNum),
                        null, // null supaya ganti ke Rp text
                        Colors.greenAccent,
                      ),
                      buildStatCard(
                        "Transaksi Hari Ini",
                        "${data?['transaksi_today'] ?? 0}",
                        Icons.shopping_cart,
                        Colors.blueAccent,
                      ),
                      buildStatCard(
                        "Retur Hari Ini",
                        "${data?['retur_today'] ?? 0}",
                        Icons.refresh,
                        Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  buildChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
