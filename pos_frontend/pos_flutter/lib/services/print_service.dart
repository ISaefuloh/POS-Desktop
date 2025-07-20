import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrintService {
  final BlueThermalPrinter printer;

  PrintService(this.printer);

  void printNota(
      String noNota, List<Map<String, dynamic>> items, double total) {
    printer.printNewLine();
    printer.printCustom("TOKO ALAT LISTRIK", 3, 1);
    printer.printCustom("Nota: $noNota", 1, 0);
    printer.printNewLine();

    for (var item in items) {
      printer.printCustom("${item['nama']} x${item['jumlah']}", 1, 0);
      printer.printCustom("Rp ${item['total']}", 1, 2);
    }

    printer.printNewLine();
    printer.printCustom("Total: Rp ${total.toStringAsFixed(0)}", 2, 2);
    printer.printNewLine();
    printer.printNewLine();
  }
}
