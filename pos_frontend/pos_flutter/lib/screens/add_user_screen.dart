import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'kasir';

  void submit() async {
    final newUser = User(
      name: nameController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text,
      role: role,
    );

    try {
      await ApiService.addUser(newUser);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal tambah user: $e'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.yellow.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.yellow.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.yellow[700],
          title: const Text(
            'Kidz Electrical',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.account_box_sharp, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Tambah User',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nama'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Username'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Password'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft, // Menyelaraskan ke kiri
                  child: SizedBox(
                    width: 200, // Tentukan lebar dropdown
                    child: DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: Colors.grey[900],
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[850],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.yellow.shade700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.yellow.shade700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      iconEnabledColor: Colors.yellow,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      isDense: true, // Memperkecil padding item dropdown
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                        DropdownMenuItem(
                          value: 'kasir',
                          child: Text('Kasir'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => role = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.save, color: Colors.black),
                    label: const Text(
                      'Simpan',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ]));
  }
}
