import 'dart:convert';
//import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/pembelian.dart';

class PembelianService {
  //static const String baseUrl = 'http://10.0.2.2:8000/api/pembelian';
  //static const String baseUrl = 'http://localhost:8000/api/pembelian';
  //static const String baseUrl = 'http://192.168.5.103:8000/api/pembelian';
  static const String baseUrl = 'http://100.96.226.112:8000/api/pembelian';

  // Otomatis sesuaikan base URL tergantung platform
  //static String get baseUrl {
  //  if (Platform.isAndroid) {
  //    return 'http://10.0.2.2:8000/api/pembelian';
  //  } else {
  //    //return 'http://localhost:8000/api/pembelian';
  //    return 'http://100.96.226.112:8000/api/pembelian';
  //
  //  }
  //}

  // Ambil semua pembelian
  static Future<List<Pembelian>> getAll() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Pembelian.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data pembelian');
    }
  }

  // Buat pembelian baru, dan kembalikan object pembelian (dengan nomor_btb dari backend)
  static Future<Pembelian?> createPembelian(Pembelian pembelian) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pembelian.toJson()),
    );

    if (response.statusCode == 201) {
      return Pembelian.fromJson(jsonDecode(response.body));
    } else {
      print('Gagal membuat pembelian: ${response.body}');
      return null;
    }
  }

  // Ambil detail pembelian berdasarkan ID
  static Future<Pembelian?> getDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id/'));
    if (response.statusCode == 200) {
      return Pembelian.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}
