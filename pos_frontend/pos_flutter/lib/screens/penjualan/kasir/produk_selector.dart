// -----------------------------
// produk_selector.dart
// -----------------------------

import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Import model & services dari projectmu (sesuaikan path jika perlu)
import 'package:pos_flutter/models/product.dart';
//import 'package:pos_flutter/models/penjualan.dart';
//import 'package:pos_flutter/services/product_service.dart';
//import 'package:pos_flutter/services/penjualan_service.dart';
//import 'package:pos_flutter/services/nota_service.dart';
//import '../nota_printer.dart';
//import 'package:pos_flutter/screens/penjualan/nota_printer.dart';
import 'package:pos_flutter/screens/penjualan/kasir/kasir_controller.dart';

class ProdukSelector extends StatelessWidget {
  final KasirController controller;
  final TextEditingController jumlahController;
  final VoidCallback onTambah;

  const ProdukSelector(
      {Key? key,
      required this.controller,
      required this.jumlahController,
      required this.onTambah})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[900], //grey.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Produk',
                style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownSearch<Product>(
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cari Produk...',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.yellow)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.yellow)),
                ),
                baseStyle: TextStyle(color: Colors.white),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Cari Produk...',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Ketik kode atau nama produk...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.yellow.withOpacity(0.2)
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${item.kode} - ${item.nama}',
                        style: const TextStyle(color: Colors.white)),
                  );
                },
                menuProps: MenuProps(
                  backgroundColor: Colors.grey.shade800,
                ),
              ),
              items: controller.produkList,
              itemAsString: (p) => '${p.kode} - ${p.nama}',
              selectedItem: controller.selectedProduk,
              onChanged: (p) => controller.pilihProduk(p),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.yellow)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.yellow)),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? 1;
                      controller.setJumlah(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: Icon(Icons.add_circle_outline,
                            color: Colors.yellow),
                        onPressed: () {
                          controller.setJumlah(controller.jumlah + 1);
                          jumlahController.text = controller.jumlah.toString();
                        }),
                    IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.yellow),
                        onPressed: () {
                          if (controller.jumlah > 1)
                            controller.setJumlah(controller.jumlah - 1);
                          jumlahController.text = controller.jumlah.toString();
                        }),
                  ],
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                    onPressed: onTambah,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.yellow),
                    child: const Text('Tambah'))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
