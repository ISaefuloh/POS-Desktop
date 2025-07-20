import 'package:go_router/go_router.dart';
import 'package:pos_flutter/screens/laporan_stok_screen.dart';
import 'package:pos_flutter/screens/login_screen.dart';
import 'package:pos_flutter/screens/splash_screen.dart';
import 'package:pos_flutter/screens/admin_home_screen.dart';
import 'package:pos_flutter/screens/kasir_home_screen.dart';
import 'package:pos_flutter/screens/product_list_screen.dart';
import 'package:pos_flutter/screens/pembelian/pembelian_list_screen.dart';
import 'package:pos_flutter/screens/penjualan/keranjang_screen.dart';
import 'package:pos_flutter/screens/user_list_screen.dart';
import '../services/auth_service.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final user = await AuthService().getLoggedInUser();
    final isLoggingIn = state.uri.path == '/login';

    if (user == null) {
      return isLoggingIn ? null : '/login';
    }

    // Jika sudah login, arahkan ke halaman sesuai role
    if (isLoggingIn || state.uri.path == '/splash') {
      if (user.role == 'admin') return '/admin';
      if (user.role == 'kasir') return '/kasir';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),
    GoRoute(
      path: '/kasir',
      builder: (context, state) => const KasirHomeScreen(),
    ),
    GoRoute(
      path: '/produk',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/pembelian',
      builder: (context, state) => const PembelianListScreen(),
    ),
    GoRoute(
      path: '/penjualan',
      builder: (context, state) => KeranjangScreen(),
    ),
    GoRoute(
      path: '/laporanstok',
      builder: (context, state) => LaporanStokScreen(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => UserListScreen(),
    ),
  ],
);
