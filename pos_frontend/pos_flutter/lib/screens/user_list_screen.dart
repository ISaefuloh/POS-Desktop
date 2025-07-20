import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'add_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<User>> usersFuture;
  List<User> allUsers = [];
  List<User> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    usersFuture = ApiService.getUsers();
    final users = await usersFuture;
    setState(() {
      allUsers = users;
      filteredUsers = users;
    });
  }

  //void _loadUsers() {
  //  usersFuture = ApiService.getUsers();
  //  usersFuture.then((users) {
  //    setState(() {
  //      allUsers = users;
  //      filteredUsers = users;
  //    });
  //  });
  //}

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
            user.username.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.red;
        break;
      case 'kasir':
        color = Colors.blue;
        break;
      case 'staff':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.account_box_outlined,
                    color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Daftar User',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari user...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[850],
                prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow.shade700),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow.shade700),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (filteredUsers.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada user yang cocok.',
                          style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, i) {
                    final user = filteredUsers[i];
                    return Card(
                      color: const Color.fromARGB(52, 158, 158, 158),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.yellow,
                          child: Text(user.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.black)),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              _buildRoleBadge(user.role),
                            ],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username: ${user.username}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Role: ${user.role}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    //TextButton.icon(
                                    //  onPressed: () {
                                    //    // TODO: Aksi edit
                                    //  },
                                    //  icon: const Icon(Icons.edit,
                                    //      size: 18, color: Colors.white),
                                    //  label: const Text(
                                    //    'Edit',
                                    //    style: TextStyle(color: Colors.white),
                                    //  ),
                                    //),
                                    TextButton.icon(
                                      onPressed: () async {
                                        if (user.id == null) return;

                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: Colors.yellow,
                                            title: const Text('Konfirmasi'),
                                            content: const Text(
                                                'Yakin ingin menghapus user ini?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors
                                                      .black, // Mengubah warna teks tombol menjadi merah
                                                ),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors
                                                      .red, // Mengubah warna teks tombol menjadi merah
                                                ),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          try {
                                            await ApiService.deleteUser(
                                                user.id!);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'User berhasil dihapus')),
                                            );
                                            await _loadUsers(); // ini ganti refreshUsers
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Gagal menghapus user: $e')),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      label: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if (result == true) {
            _loadUsers();
          }
        },
      ),
    );
  }
}
