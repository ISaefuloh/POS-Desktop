import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchLaporanStok({
  required String start,
  required String end,
}) async {
  final response = await http.get(
    Uri.parse(
        'http://100.96.226.112:8000/api/laporan-stok/?start=$start&end=$end'),
    //'http://192.168.5.103:8000/api/laporan-stok/?start=$start&end=$end'),
    //'http://10.0.2.2:8000/api/laporan-stok/?start=$start&end=$end'),
    //'http://127.0.0.1:8000/api/laporan-stok/?start=$start&end=$end',),
  );

  if (response.statusCode == 200) {
    List data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Gagal load laporan stok');
  }
}
