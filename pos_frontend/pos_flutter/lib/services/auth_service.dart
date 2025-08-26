import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/login_request.dart';

class AuthService {
  //final String baseUrl = 'http://10.0.2.2:8000/api/users';
  //final String baseUrl = 'http://127.0.0.1:8000/api/users';
  //final String baseUrl = 'http://192.168.5.103:8000/api/users';
  final String baseUrl = 'http://100.96.226.112:8000/api/users';

  Future<User?> login(LoginRequest request) async {
    final url = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final user = User.fromJson(json);

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(user.toJson()));

      return user;
    } else {
      print('Login failed: ${response.body}');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
  }

  Future<User?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> json = jsonDecode(userJson);
      return User.fromJson(json);
    }
    return null;
  }
}
