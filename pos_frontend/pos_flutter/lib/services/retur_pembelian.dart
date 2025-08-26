import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_flutter/models/produk_retur_pembelian.dart';
import 'package:pos_flutter/models/riwayat_retur.dart';
import 'package:pos_flutter/models/retur_pembelian.dart';

//const String baseUrl = 'http://localhost:8000/api';
const String baseUrl = 'http://100.96.226.112:8000/api';

// Ambil data produk pembelian berdasarkan nomor BTB
Future<List<ProdukReturPembelian>> fetchDetailReturPembelian(
    String nomorBTB) async {
  try {
    final safeNomorBTB = nomorBTB.replaceAll('/', '-');
    final response = await http.get(
      Uri.parse('$baseUrl/pembelian/$safeNomorBTB/detail-retur/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => ProdukReturPembelian.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil data retur pembelian: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error koneksi: $e');
  }
}

// Kirim data retur pembelian ke backend
Future<void> kirimSemuaReturPembelian({
  required String nomorBTB,
  required List<ProdukReturPembelian> items,
}) async {
  final url = Uri.parse('$baseUrl/retur-pembelian/');

  final data = {
    "nomor_btb": nomorBTB,
    "items": items
        .map((item) => {
              "detail_pembelian_id": item.detailPembelianId,
              "jumlah": item.jumlahRetur,
              "keterangan": item.keterangan ?? "-",
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
    throw Exception('Gagal kirim retur pembelian: ${response.body}');
  }
}

// Ambil riwayat retur pembelian
Future<List<RiwayatRetur>> fetchRiwayatReturPembelian() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/retur-pembelian/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => RiwayatRetur.fromJson(json)).toList();
    } else {
      throw Exception(
          'Gagal mengambil riwayat retur pembelian: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error koneksi saat ambil riwayat: $e');
  }
}

// Ambil daftar retur pembelian dengan filter tanggal
Future<List<ReturPembelian>> fetchReturPembelianList({
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

  final uri = Uri.parse('$baseUrl/retur-pembelian-list/')
      .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    return jsonData.map((e) => ReturPembelian.fromJson(e)).toList();
  } else {
    throw Exception('Gagal memuat data retur pembelian');
  }
}
