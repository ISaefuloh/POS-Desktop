import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final kodeController = TextEditingController();
  final namaController = TextEditingController();
  final satuanController = TextEditingController();
  final hargaJualController = TextEditingController();

  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    hargaJualController.addListener(_formatHarga);
  }

  void _formatHarga() {
    final text = hargaJualController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return;

    final number = int.parse(text);
    final newText = formatter.format(number);

    if (hargaJualController.text != newText) {
      hargaJualController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void submit() async {
    final product = Product(
      kode: kodeController.text,
      nama: namaController.text,
      satuan: satuanController.text,
      hargaJual: double.tryParse(
              hargaJualController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0.0,
    );

    final success = await ProductService.createProduct(product);
    if (success) {
      if (context.mounted) {
        context.pop(true); // Refresh list produk
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan produk')),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.yellow),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.yellow),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.yellow, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.yellow,
          title: const Text(
            'Kidz Electrical',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 20, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.edit_document, color: Colors.yellow, size: 26),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: kodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Kode Produk'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nama Produk'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: satuanController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Satuan'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hargaJualController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Harga Jual'),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                    onPressed: submit,
                  ),
                ),
              ],
            ),
          ),
        ]));
  }
}
