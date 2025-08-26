import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/services/product_service.dart';
import 'package:pos_flutter/services/pembelian_service.dart';
import 'package:pos_flutter/models/pembelian.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }

    String digitsOnly =
        newValue.text.replaceAll('Rp', '').replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final number = int.parse(digitsOnly);
    final newText = _formatter.format(number).trim();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class TambahPembelianScreen extends StatefulWidget {
  const TambahPembelianScreen({super.key});

  @override
  State<TambahPembelianScreen> createState() => _TambahPembelianScreenState();
}

class _TambahPembelianScreenState extends State<TambahPembelianScreen> {
  final supplierController = TextEditingController();
  final jumlahController = TextEditingController();
  final hargaBeliController = TextEditingController();

  List<Product> allProducts = [];
  Product? selectedProduct;
  List<Map<String, dynamic>> detailList = [];
  bool isSaving = false;

  final formatRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProduk();
  }

  Future<void> _loadProduk() async {
    final result = await ProductService.getAllProducts();
    setState(() {
      allProducts = result;
    });
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

  void _tambahDetail() {
    if (selectedProduct == null ||
        jumlahController.text.isEmpty ||
        hargaBeliController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk, jumlah, dan harga beli harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alreadyExists =
        detailList.any((item) => item['produk_id'] == selectedProduct!.id);

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${selectedProduct!.nama}" sudah ditambahkan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final hargaText =
        hargaBeliController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final harga = double.tryParse(hargaText) ?? 0.0;
    final jumlah = int.tryParse(jumlahController.text) ?? 0;

    detailList.add({
      'produk_id': selectedProduct!.id,
      'nama': selectedProduct!.nama,
      'jumlah': jumlah,
      'harga_beli': harga,
    });

    setState(() {
      selectedProduct = null;
      jumlahController.clear();
      hargaBeliController.clear();
    });
  }

  void _hapusDetail(int index) {
    setState(() {
      detailList.removeAt(index);
    });
  }

  void _simpanPembelian() async {
    if (detailList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 1 barang harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final pembelian = Pembelian(
      nomorBtb: null,
      tanggal: DateTime.now().toIso8601String(),
      supplier: supplierController.text,
      detailPembelian:
          detailList.map((e) => DetailPembelian.fromJson(e)).toList(),
    );

    final hasil = await PembelianService.createPembelian(pembelian);

    setState(() {
      isSaving = false;
    });

    if (hasil != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Berhasil disimpan. Nomor BTB: ${hasil.nomorBtb ?? '-'}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan pembelian')),
      );
    }
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Judul halaman
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: const [
                Icon(Icons.add_shopping_cart, color: Colors.yellow, size: 26),
                SizedBox(width: 8),
                Text(
                  'Tambah Pembelian',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Supplier
          TextField(
            controller: supplierController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Supplier (opsional)'),
          ),
          const SizedBox(height: 16),

          // Dropdown Produk
          DropdownSearch<Product>(
            items: allProducts,
            itemAsString: (item) => '${item.kode} - ${item.nama}',
            selectedItem: selectedProduct,
            onChanged: (value) {
              setState(() => selectedProduct = value);
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: const OutlineInputBorder(),
                ),
              ),
              menuProps: MenuProps(
                backgroundColor: Colors.grey.shade900,
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.grey.shade700 : Colors.transparent,
                  ),
                  child: Text(
                    '${item.kode} - ${item.nama}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: _inputDecoration('Pilih Produk'),
              baseStyle: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // Jumlah
          TextField(
            controller: jumlahController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Jumlah'),
          ),
          const SizedBox(height: 16),

          // Harga Beli
          TextField(
            controller: hargaBeliController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Harga Beli (Rp)'),
          ),
          const SizedBox(height: 16),

          // Tombol Tambah Detail
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _tambahDetail,
            icon: const Icon(Icons.add),
            label: const Text('Tambah ke Daftar'),
          ),
          const SizedBox(height: 20),

          // Daftar Barang
          const Text(
            'Daftar Barang:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          ...detailList.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item['nama']} (x${item['jumlah']})\n${formatRupiah.format(item['harga_beli'])}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _hapusDetail(index),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 30),

          // Tombol Simpan
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
              label: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text('Simpan Pembelian'),
              onPressed: isSaving ? null : _simpanPembelian,
            ),
          ),
        ],
      ),
    );
  }
}
