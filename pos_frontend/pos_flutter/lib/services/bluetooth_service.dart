import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class BluetoothService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> scanBondedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _bluetooth.connect(device);
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  Future<bool> isConnected() async {
    return await _bluetooth.isConnected ?? false;
  }

  BlueThermalPrinter get instance => _bluetooth;
}
