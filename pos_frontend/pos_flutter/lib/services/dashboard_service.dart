//import 'dart:convert';
//import 'package:http/http.dart' as http;
//
//class DashboardService {
//  static const String baseUrl =
//      "http://127.0.0.1:8000"; // ganti sesuai server kamu
//
//  static Future<Map<String, dynamic>> fetchDashboardSummary() async {
//    final response = await http.get(Uri.parse("$baseUrl/dashboard-summary/"));
//
//    if (response.statusCode == 200) {
//      return json.decode(response.body);
//    } else {
//      throw Exception("Gagal mengambil data dashboard");
//    }
//  }
//}

import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  //static const String baseUrl = "http://127.0.0.1:8000/api/dashboard-summary/";
  static const String baseUrl =
      "http://100.96.226.112:8000/api/dashboard-summary/";

  /// Ambil data dashboard dari API
  static Future<Map<String, dynamic>?> fetchDashboard() async {
    try {
      final url = Uri.parse(baseUrl);
      final res = await http.get(url);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("Error DashboardService.fetchDashboard: $e");
      return null;
    }
  }
}
