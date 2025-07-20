import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_flutter/models/penjualan.dart';
import 'package:intl/intl.dart';

class PenjualanService {
  //final String baseUrl = 'http://10.0.2.2:8000/api/';
  final String baseUrl = 'http://localhost:8000/api/';
  //final String baseUrl = 'http://192.168.5.103:8000/api/';
  //final String baseUrl = 'http://100.96.226.112:8000/api/';

  Future<Penjualan> createPenjualan(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${baseUrl}penjualan/create/'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    print('Status Code (Create Penjualan): ${response.statusCode}');
    print('Response Body (Create Penjualan): ${response.body}');

    if (response.statusCode == 201) {
      try {
        return Penjualan.fromJson(json.decode(response.body));
      } catch (e) {
        print('Error parsing JSON di createPenjualan: $e');
        throw Exception('Gagal memproses respons penjualan: $e');
      }
    } else {
      try {
        final body = json.decode(response.body);
        if (body is Map<String, dynamic>) {
          if (body.containsKey('non_field_errors')) {
            // ✅ throw langsung keluar dari fungsi
            throw Exception(body['non_field_errors'][0]);
          }

          // ✅ Tangani error field lain juga
          final errors = body.entries
              .map((e) => "${e.key}: ${e.value}")
              .join('\n');
          throw Exception(errors);
        }
      } catch (e) {
        // ✅ Biarkan ini melempar ulang isi error-nya
        rethrow;
      }

      // ⚠️ Jangan sampai baris ini dieksekusi kalau sudah throw di atas
      throw Exception(
        'Gagal membuat penjualan dengan status: ${response.statusCode}',
      );
    }
  }

  Future<List<Penjualan>> getLaporanPenjualan(
    DateTime? tanggalMulai,
    DateTime? tanggalAkhir,
  ) async {
    String laporanUrl =
        '${baseUrl}penjualan/'; // Endpoint untuk mendapatkan daftar penjualan

    if (tanggalMulai != null && tanggalAkhir != null) {
      final formatter = DateFormat('yyyy-MM-dd'); // Asumsi format tanggal API
      final startDate = formatter.format(tanggalMulai);
      final endDate = formatter.format(tanggalAkhir);
      laporanUrl += '?tanggal_mulai=$startDate&tanggal_akhir=$endDate';
    }

    final response = await http.get(Uri.parse(laporanUrl));

    if (response.statusCode == 200) {
      try {
        final List data = json.decode(response.body);
        return data.map((json) => Penjualan.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing JSON di getLaporanPenjualan: $e');
        throw Exception('Gagal memproses respons laporan penjualan: $e');
      }
    } else {
      print(
        'Gagal memuat laporan penjualan dengan status: ${response.statusCode}, body: ${response.body}',
      );
      throw Exception(
        'Gagal memuat laporan penjualan dengan status: ${response.statusCode}',
      );
    }
  }

  // Metode ini untuk mengambil detail penjualan berdasarkan ID
  Future<Penjualan> getPenjualanDetail(int id) async {
    final response = await http.get(Uri.parse('${baseUrl}penjualan/$id/'));

    if (response.statusCode == 200) {
      try {
        return Penjualan.fromJson(json.decode(response.body));
      } catch (e) {
        print('Error parsing JSON di getPenjualanDetail: $e');
        throw Exception('Gagal memproses respons penjualan: $e');
      }
    } else {
      print(
        'Gagal memuat penjualan dengan status: ${response.statusCode}, body: ${response.body}',
      );
      throw Exception(
        'Gagal memuat penjualan dengan status: ${response.statusCode}',
      );
    }
  }
}
