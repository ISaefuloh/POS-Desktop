import 'package:flutter/material.dart';
import 'router/router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart'; // Untuk platform check
import 'dart:io'; // Untuk Platform check

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cek apakah aplikasi berjalan di mobile (Android/iOS)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await initializeDateFormatting(
        'id_ID', null); // Inisialisasi locale Indonesia hanya di mobile
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, // Menyembunyikan banner debug
      routerConfig: router, // Menghubungkan dengan router yang sudah ada
    );
  }
}
