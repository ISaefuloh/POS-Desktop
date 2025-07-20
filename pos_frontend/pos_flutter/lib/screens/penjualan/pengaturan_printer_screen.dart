/*
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pos_flutter/screens/penjualan/nota_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  String? selectedPrinterName;

  @override
  void initState() {
    super.initState();
    if (NotaPrinter.selectedDevice != null) {
      selectedPrinterName = NotaPrinter.selectedDevice!.name ?? 'Unknown';
    }
  }

  Future<void> _choosePrinter() async {
    List<BluetoothDevice> devices =
        await NotaPrinter.printer.getBondedDevices();

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak ada printer terpasang.'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Pilih Printer Baru',
          style: TextStyle(color: Colors.yellow),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(
                  device.name ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  device.address ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    selectedPrinterName = device.name ?? 'Unknown';
                  });

                  NotaPrinter.selectedDevice = device;
                  await NotaPrinter.printer.disconnect();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('printer_address', device.address!);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Printer ${device.name} dipilih'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPrinter() async {
    await NotaPrinter.resetPrinterSelection();
    setState(() {
      selectedPrinterName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pilihan printer dihapus'),
        backgroundColor: Colors.orange[700],
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
          'Pengaturan Printer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Printer Saat Ini:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow),
            ),
            const SizedBox(height: 8),
            Text(
              selectedPrinterName ?? 'Belum ada printer dipilih',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _choosePrinter,
              icon: const Icon(Icons.print, color: Colors.yellow),
              label: const Text('Pilih Printer Baru',
                  style: TextStyle(color: Colors.yellow)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetPrinter,
              icon: const Icon(Icons.refresh, color: Colors.yellow),
              label: const Text('Hapus Pilihan Printer',
                  style: TextStyle(color: Colors.yellow)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
