// -----------------------------
// pembayaran_dialog.dart
// -----------------------------

import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
//import 'package:dropdown_search/dropdown_search.dart';

// Import model & services dari projectmu (sesuaikan path jika perlu)
//import 'package:pos_flutter/models/product.dart';
//import 'package:pos_flutter/models/penjualan.dart';
//import 'package:pos_flutter/services/product_service.dart';
//import 'package:pos_flutter/services/penjualan_service.dart';
//import 'package:pos_flutter/services/nota_service.dart';
//import '../nota_printer.dart';
//import 'package:pos_flutter/screens/penjualan/nota_printer.dart';
import 'package:pos_flutter/screens/penjualan/kasir/kasir_controller.dart';

class PembayaranDialog extends StatefulWidget {
  final KasirController controller;
  final Future<void> Function(double pembayaran) onConfirm;

  const PembayaranDialog({
    Key? key,
    required this.controller,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PembayaranDialog> createState() => _PembayaranDialogState();
}

class _PembayaranDialogState extends State<PembayaranDialog> {
  final pembayaranController = TextEditingController();
  final kembalianController = TextEditingController();
  final _focusPembayaran = FocusNode();
  bool isCukup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusPembayaran);
    });
  }

  @override
  void dispose() {
    pembayaranController.dispose();
    kembalianController.dispose();
    _focusPembayaran.dispose();
    super.dispose();
  }

  void _onPembayaranChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) {
      kembalianController.text = '';
      setState(() => isCukup = false);
      return;
    }

    final pembayaran = double.tryParse(cleaned) ?? 0;
    final total = widget.controller.totalHarga;
    final kembalian = pembayaran - total;

    setState(() => isCukup = kembalian >= 0);

    kembalianController.text = kembalian >= 0
        ? widget.controller.formatRupiah(kembalian)
        : 'Kurang Bayar';

    // Format tampilan rupiah
    final formatted = widget.controller.formatRupiah(pembayaran);
    if (pembayaranController.text != formatted) {
      pembayaranController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: Text('Pembayaran', style: TextStyle(color: Colors.yellow)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(color: Colors.white70)),
              Text(
                widget.controller.formatRupiah(widget.controller.totalHarga),
                style: TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Input pembayaran
          TextField(
            focusNode: _focusPembayaran,
            controller: pembayaranController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Pembayaran',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            style: TextStyle(color: Colors.white),
            onChanged: _onPembayaranChanged,
            onSubmitted: (_) {
              if (isCukup) _prosesBayar();
            },
          ),
          const SizedBox(height: 8),

          // Kembalian
          TextField(
            controller: kembalianController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Kembalian',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            style: TextStyle(
                color: isCukup ? Colors.greenAccent : Colors.redAccent),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isCukup ? Colors.yellow : Colors.grey,
            foregroundColor: Colors.black,
          ),
          onPressed: isCukup ? _prosesBayar : null,
          child: Text('Bayar & Cetak'),
        ),
      ],
    );
  }

  void _prosesBayar() async {
    final cleaned = pembayaranController.text.replaceAll(RegExp(r'[^\d]'), '');
    final pembayaran = double.tryParse(cleaned) ?? 0;

    // Tutup dialog langsung supaya UI terasa cepat
    Navigator.of(context).pop();

    // Lanjutkan proses di background
    Future.microtask(() async {
      try {
        await widget.onConfirm(pembayaran);
        // ✅ Opsional: mainkan suara sukses
        // AudioPlayer().play(AssetSource('sounds/success.mp3'));
      } catch (e) {
        // ✅ Tampilkan error di halaman utama jika perlu
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.yellow,
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      }
    });
  }
}
