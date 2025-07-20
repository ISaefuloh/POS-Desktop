import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Product> products = [];
  bool isLoading = true;
  String sortBy = 'nama';
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await ProductService.getAllProducts();
    setState(() {
      products = data;
      isLoading = false;
    });
  }

  void goToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (result == true) {
      loadProducts(); // refresh after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Kidz Electrical',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: goToAddProduct,
            icon: const Icon(Icons.add_circle, color: Colors.black),
            tooltip: 'Tambah Produk',
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  //padding: const EdgeInsets.fromLTRB(5, 20, 16, 10),
                  child: Row(
                    children: const [
                      Icon(Icons.data_usage, color: Colors.yellow, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Master Produk',
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
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: 'Cari produk...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.yellow),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: sortBy,
                        dropdownColor: Colors.grey[900],
                        iconEnabledColor: Colors.yellow,
                        style: const TextStyle(color: Colors.yellow),
                        underline: Container(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => sortBy = value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'nama', child: Text('Nama')),
                          DropdownMenuItem(
                              value: 'harga', child: Text('Harga')),
                        ],
                      ),
                      IconButton(
                        onPressed: () => setState(() => ascending = !ascending),
                        icon: Icon(
                          ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.yellow,
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(
                        12.0), // Atur padding sesuai kebutuhan
                    child: ListView.separated(
                      itemCount: products
                          .where((p) =>
                              p.nama.toLowerCase().contains(searchQuery) ||
                              p.kode.toLowerCase().contains(searchQuery))
                          .length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.grey),
                      itemBuilder: (context, index) {
                        final filtered = products
                            .where((p) =>
                                p.nama.toLowerCase().contains(searchQuery) ||
                                p.kode.toLowerCase().contains(searchQuery))
                            .toList();

                        // Sorting
                        filtered.sort((a, b) {
                          int cmp;
                          if (sortBy == 'nama') {
                            cmp = a.nama.compareTo(b.nama);
                          } else {
                            cmp = a.hargaJual.compareTo(b.hargaJual);
                          }
                          return ascending ? cmp : -cmp;
                        });

                        final p = filtered[index];
                        return ListTile(
                          tileColor: Colors.grey[900],
                          title: Text(p.nama,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            'Kode: ${p.kode} | Satuan: ${p.satuan}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rp ${p.hargaJual.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.yellow),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.yellow),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProductScreen(product: p),
                                    ),
                                  );
                                  if (result == true) loadProducts();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Text('Konfirmasi',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      content: Text('Hapus produk "${p.nama}"?',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Hapus',
                                              style: TextStyle(
                                                  color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success =
                                        await ProductService.deleteProduct(
                                            p.id!);
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.yellow[700],
                                          content: Text(
                                            'Produk "${p.nama}" berhasil dihapus',
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        ),
                                      );
                                      loadProducts();
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content:
                                              Text('Gagal menghapus produk'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
