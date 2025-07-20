import 'dart:convert';
import 'package:http/http.dart' as http;

class NotaService {
  //final String baseUrl = 'http://10.0.2.2:8000/api/';
  final String baseUrl = 'http://localhost:8000/api/';
  //final String baseUrl = 'http://100.96.226.112:8000/api/';
  //final String baseUrl = 'http://192.168.5.103:8000/api/';

  // ... fungsi createPenjualan yang sudah ada ...

  Future<String> getNomorNotaBaru() async {
    final response = await http.get(
      Uri.parse('${baseUrl}penjualan/nomor_nota_baru/'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['nomor_nota'];
    } else {
      throw Exception('Gagal mendapatkan nomor nota baru');
    }
  }
}
