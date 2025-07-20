import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final TextEditingController kodeController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController satuanController = TextEditingController();
  final TextEditingController hargaJualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    kodeController.text = product.kode;
    namaController.text = product.nama;
    satuanController.text = product.satuan;
    hargaJualController.text = product.hargaJual % 1 == 0
        ? product.hargaJual.toInt().toString()
        : product.hargaJual.toString();
  }

  void submitUpdate() async {
    final updatedProduct = Product(
      id: widget.product.id,
      kode: kodeController.text,
      nama: namaController.text,
      satuan: satuanController.text,
      hargaJual: double.tryParse(hargaJualController.text) ?? 0.0,
    );

    final success = await ProductService.updateProduct(updatedProduct);

    if (success && mounted) {
      Navigator.pop(context, true); // kembali dan trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui produk')),
      );
    }
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    satuanController.dispose();
    hargaJualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          'Kidz Electrical',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black, // Latar belakang hitam
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: const [
              Icon(Icons.edit, color: Colors.yellow, size: 26),
              SizedBox(width: 8),
              Text(
                'Edit Master Produk',
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
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextFormField(kodeController, 'Kode Produk'),
                const SizedBox(height: 10),
                _buildTextFormField(namaController, 'Nama Produk'),
                const SizedBox(height: 10),
                _buildTextFormField(satuanController, 'Satuan'),
                const SizedBox(height: 10),
                _buildTextFormField(hargaJualController, 'Harga Jual',
                    isNumber: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                        color: Colors.black), // Teks tombol berwarna hitam
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[850], // Warna latar belakang input field
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow.shade700),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow.shade700),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }
}
