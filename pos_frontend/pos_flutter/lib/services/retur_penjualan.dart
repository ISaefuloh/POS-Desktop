import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_flutter/models/produk_retur_penjualan.dart';
import 'package:pos_flutter/models/riwayat_retur.dart';
import 'package:pos_flutter/models/retur_penjualan.dart';
//import 'package:intl/intl.dart';

// Ganti dengan base URL server kamu
const String baseUrl = 'http://localhost:8000/api';

// Ambil data produk berdasarkan nomor nota penjualan
Future<List<ProdukRetur>> fetchDetailReturPenjualan(String nomorNota) async {
  try {
    final safeNomorNota = nomorNota.replaceAll('/', '-');
    final response = await http.get(
      Uri.parse('$baseUrl/penjualan/$safeNomorNota/detail-retur/'),
    );
    //final response = await http
    //    .get(Uri.parse('$baseUrl/penjualan/$nomorNota/detail-retur/'))
    //    .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => ProdukRetur.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil data retur: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error koneksi: $e');
  }
}

// Kirim data retur ke backend
Future<void> kirimSemuaReturPenjualan({
  required String nomorNota,
  required List<ProdukRetur> items,
}) async {
  final url = Uri.parse('$baseUrl/retur-penjualan/');

  final data = {
    "nomor_nota": nomorNota,
    "items": items
        .map((item) => {
              "detail_penjualan_id": item.detailPenjualanId,
              "jumlah": item.jumlahRetur,
              "keterangan": item.keterangan ?? "-", // ⬅️ per-item
            })
        .toList(),
  };

  print('DATA DIKIRIM: ${jsonEncode(data)}');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(response.body);
  }
}
//Future<void> kirimReturPenjualan({
//  required int detailPenjualanId,
//  required int jumlah,
//  required String keterangan,
//}) async {
//  try {
//    final response = await http
//        .post(
//          Uri.parse('$baseUrl/retur-penjualan/'),
//          headers: {'Content-Type': 'application/json'},
//          body: jsonEncode({
//            'detail_penjualan': detailPenjualanId,
//            'jumlah': jumlah,
//            'keterangan': keterangan,
//          }),
//        )
//        .timeout(const Duration(seconds: 10));
//
//    if (response.statusCode == 201) {
//      print('✅ Retur berhasil dikirim');
//    } else {
//      print('❌ Gagal kirim retur: ${response.body}');
//      throw Exception('Gagal kirim retur');
//    }
//  } catch (e) {
//    throw Exception('Error koneksi saat kirim retur: $e');
//  }
//}

// Ambil riwayat retur penjualan
Future<List<RiwayatRetur>> fetchRiwayatReturPenjualan() async {
  try {
    final response = await http
        .get(Uri.parse('$baseUrl/retur-penjualan/'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => RiwayatRetur.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil riwayat: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error koneksi saat ambil riwayat: $e');
  }
}

Future<List<ReturPenjualan>> fetchReturPenjualanList({
  DateTime? tanggalMulai,
  DateTime? tanggalAkhir,
}) async {
  final queryParams = <String, String>{};

  if (tanggalMulai != null) {
    queryParams['tanggal_mulai'] =
        tanggalMulai.toIso8601String().substring(0, 10);
  }
  if (tanggalAkhir != null) {
    queryParams['tanggal_akhir'] =
        tanggalAkhir.toIso8601String().substring(0, 10);
  }

  final uri = Uri.parse('http://localhost:8000/api/retur-penjualan-list/')
      .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((e) => ReturPenjualan.fromJson(e)).toList();
  } else {
    throw Exception('Gagal memuat data retur penjualan');
  }
}
