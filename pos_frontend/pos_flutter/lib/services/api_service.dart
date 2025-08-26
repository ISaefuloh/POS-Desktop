import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  //static const String baseUrl = 'http://10.0.2.2:8000/api';
  //static const String baseUrl = 'http://127.0.0.1:8000/api';
  //static const String baseUrl = 'http://192.168.5.103:8000/api';
  static const String baseUrl = 'http://100.96.226.112:8000/api';

  static Future<List<User>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users/'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Gagal ambil data user');
    }
  }

  static Future<User?> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    } else {
      return null;
    }
  }

  static Future<void> addUser(User user) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (res.statusCode != 201) {
      print(res.body); // debug output
      throw Exception('Gagal menambah user');
    }
  }

  static Future<void> deleteUser(int userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/users/delete/$userId/'));

    if (res.statusCode != 204) {
      print(res.body); // debug output
      throw Exception('Gagal menghapus user');
    }
  }
}
