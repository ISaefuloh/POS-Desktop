import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart'; // pastikan ada file AuthService

class KasirHomeScreen extends StatelessWidget {
  const KasirHomeScreen({super.key});

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Kasir Dashboard',
          style: TextStyle(color: Colors.yellow),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.yellow),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Kidz Electrical',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMenuCard(
                      icon: Icons.receipt_long,
                      label: 'Pembelian',
                      onTap: () => context.push('/pembelian'),
                    ),
                    _buildMenuCard(
                      icon: Icons.sell,
                      label: 'Penjualan',
                      onTap: () => context.push('/penjualan'),
                    ),
                    _buildMenuCard(
                      icon: Icons.assessment,
                      label: 'Laporan Stok',
                      onTap: () => context.push('/laporanstok'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.yellow),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.yellow, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
