// keranjang_list.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_flutter/screens/penjualan/kasir/kasir_controller.dart';
import 'package:pos_flutter/models/product.dart';

class KeranjangList extends StatefulWidget {
  final KasirController controller;

  const KeranjangList({Key? key, required this.controller}) : super(key: key);

  @override
  State<KeranjangList> createState() => _KeranjangListState();
}

class _KeranjangListState extends State<KeranjangList> {
  // map keyed by produkId
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.removeListener(
          () {}); // safe remove (listeners created below are closures; removal not necessary here)
      f.dispose();
    }
    super.dispose();
  }

  void _ensureControllerForItem(int index) {
    if (index < 0 || index >= widget.controller.keranjang.length) return;
    final item = widget.controller.keranjang[index];
    final key = item.produkId;

    if (!_qtyControllers.containsKey(key)) {
      final c = TextEditingController(text: item.jumlah.toString());
      final f = FocusNode();

      // listener => ketika focus hilang, jalankan validasi
      f.addListener(() {
        if (!f.hasFocus) {
          _validateAndApplyQty(index);
        }
      });

      _qtyControllers[key] = c;
      _focusNodes[key] = f;
    } else {
      // sinkronkan text (mis. setelah rebuild karena update dari controller)
      final c = _qtyControllers[key]!;
      final currentText = c.text;
      final expected = widget.controller.keranjang.length > index
          ? widget.controller.keranjang[index].jumlah.toString()
          : null;
      if (expected != null && currentText != expected) {
        // update tanpa memindahkan caret ke akhir yang mengganggu
        c.value = TextEditingValue(
          text: expected,
          selection: TextSelection.collapsed(offset: expected.length),
        );
      }
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _validateAndApplyQty(int index) {
    if (index < 0 || index >= widget.controller.keranjang.length) return;
    final item = widget.controller.keranjang[index];
    final key = item.produkId;
    final controller = _qtyControllers[key];
    if (controller == null) return;

    final raw = controller.text.trim();
    final parsed = int.tryParse(raw);
    final newQty = parsed ?? item.jumlah;

    // cari produk (gunakan orElse dummy sama seperti controller)
    final produk = widget.controller.produkList.firstWhere(
      (p) => p.id == item.produkId,
      orElse: () => Product(
        id: 0,
        kode: '',
        nama: '',
        satuan: '',
        hargaJual: 0,
        stokTersedia: 0,
      ),
    );

    final stok = produk.stokTersedia;

    if (stok <= 0) {
      _showErrorSnack('Stok habis, tidak bisa mengubah qty');
      // kembalikan ke nilai sebelumnya
      controller.text = item.jumlah.toString();
      return;
    }

    if (newQty < 1) {
      // minimal 1
      try {
        widget.controller.updateQty(index, 1);
      } catch (e) {
        _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
      }
      controller.text = widget.controller.keranjang[index].jumlah.toString();
      return;
    }

    if (newQty > stok) {
      _showErrorSnack('Stok tidak cukup (tersedia: $stok)');
      try {
        widget.controller.updateQty(index, stok);
      } catch (e) {
        _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
      }
      controller.text = widget.controller.keranjang[index].jumlah.toString();
      return;
    }

    // valid, apply
    try {
      widget.controller.updateQty(index, newQty);
      // sinkronkan text ke nilai yang berhasil disimpan
      controller.text = widget.controller.keranjang[index].jumlah.toString();
    } catch (e) {
      _showErrorSnack(e.toString().replaceAll('Exception: ', ''));
      // kembalikan ke nilai sebelumnya jika gagal
      controller.text = item.jumlah.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.keranjang.isEmpty) {
      return Center(
          child: Text('Keranjang masih kosong',
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.controller.keranjang.length,
      itemBuilder: (context, index) {
        final item = widget.controller.keranjang[index];

        // pastikan controller & focus node ada untuk item ini
        _ensureControllerForItem(index);
        final qtyController = _qtyControllers[item.produkId]!;
        final focusNode = _focusNodes[item.produkId]!;

        return Card(
          color: Colors.grey.shade800,
          child: ListTile(
            title: Text('${item.produkKode} - ${item.produkNama}',
                style: TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Qty: ',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: qtyController,
                        focusNode: focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          _validateAndApplyQty(index);
                          // unfocus supaya listener focus hilang juga terpicu
                          focusNode.unfocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        'x ${widget.controller.formatRupiah(item.hargaJual)} = ${widget.controller.formatRupiah(item.subtotal)}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() {
                widget.controller.hapusItem(index);
                // optional: remove controllers for removed item
                _qtyControllers.remove(item.produkId)?.dispose();
                _focusNodes.remove(item.produkId)?.dispose();
              }),
            ),
          ),
        );
      },
    );
  }
}
