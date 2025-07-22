import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  //static const String baseUrl = 'http://10.0.2.2:8000/api/produk/';
  //static const String createUrl = 'http://10.0.2.2:8000/api/produk/create/';

  //static const String baseUrl = 'http://127.0.0.1:8000/api/produk/';
  //static const String createUrl = 'http://127.0.0.1:8000/api/produk/create/';

  //static const String baseUrl = 'http://192.168.5.103:8000/api/produk/';
  //static const String createUrl = 'http://192.168.5.103:8000/api/produk/create/';

  static const String baseUrl = 'http://100.96.226.112:8000/api/produk/';
  static const String createUrl =
      'http://100.96.226.112:8000/api/produk/create/';

  // GET: Ambil semua produk
  static Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat produk');
    }
  }

  // POST: Tambah produk
  static Future<bool> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse(createUrl), // pakai createUrl di sini
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    return response.statusCode == 201;
  }

  // PUT: Edit produk
  static Future<bool> updateProduct(Product product) async {
    final url = Uri.parse('$baseUrl${product.id}/');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );
    return response.statusCode == 200;
  }

  // Hapus Produk
  static Future<bool> deleteProduct(int id) async {
    final url = Uri.parse('$baseUrl$id/');
    final response = await http.delete(url);
    return response.statusCode == 204;
  }
}
