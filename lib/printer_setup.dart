import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrinterSetupPage extends StatefulWidget {
  @override
  _PrinterSetupPageState createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  BluetoothManager bluetoothManager = BluetoothManager.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadConnectedPrinter();
  }

  // Load connected printer info from SharedPreferences
  Future<void> _loadConnectedPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString('connected_printer_name');
    String? deviceAddress = prefs.getString('connected_printer_address');

    if (deviceName != null && deviceAddress != null) {
      setState(() {
        connectedDevice = BluetoothDevice();
        connectedDevice!.name = deviceName;
        connectedDevice!.address = deviceAddress;
      });
    }
  }

  Future<void> _saveConnectedPrinter(BluetoothDevice device) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String deviceJson = jsonEncode({
      'name': device.name,
      'address': device.address,
    });

    await prefs.setString('connected_printer', deviceJson);

    setState(() {
      connectedDevice = device;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu máy in: ${device.name}')),
    );
  }

  // Scan for Bluetooth devices
  Future<void> _scanForBluetoothDevices() async {
    setState(() {
      isScanning = true;
    });

    try {
      // Bắt đầu quét
      await bluetoothManager.startScan(timeout: Duration(seconds: 4));

      // Lắng nghe kết quả quét
      bluetoothManager.scanResults
          .listen((List<BluetoothDevice> scannedDevices) {
        setState(() {
          devices = scannedDevices;
          isScanning = false;
        });

        if (devices.isNotEmpty) {
          _showBluetoothDevicesDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tìm thấy thiết bị Bluetooth')),
          );
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi quét thiết bị: $e')),
      );
    }
  }

  // Show available Bluetooth devices in a dialog
  void _showBluetoothDevicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn máy in Bluetooth'),
          content: devices.isEmpty
              ? Text('Không tìm thấy thiết bị Bluetooth')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: devices.map((device) {
                    return ListTile(
                      title: Text(device.name ?? device.address ?? 'Không tên'),
                      subtitle: Text(device.address ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        _saveConnectedPrinter(device);
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  // Connect to the selected printer
  Future<void> _connectToPrinter() async {
    if (connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có máy in để kết nối')),
      );
      return;
    }

    try {
      await bluetoothManager.connect(connectedDevice!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kết nối tới: ${connectedDevice!.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kết nối thất bại: $e')),
      );
    }
  }

  // Disconnect from the printer
  Future<void> _disconnectPrinter() async {
    try {
      await bluetoothManager.disconnect();
      setState(() {
        connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ngắt kết nối máy in')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ngắt kết nối thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài Đặt Máy In Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quét và chọn máy in Bluetooth',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            SizedBox(height: 16.0),
            if (connectedDevice != null)
              Row(
                children: [
                  Text(
                    'Máy in đã kết nối:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text(
                    connectedDevice!.name ?? 'Không tên',
                    style: TextStyle(fontSize: 16, color: Colors.teal),
                  ),
                ],
              ),
            SizedBox(height: 16.0),
            if (isScanning)
              Center(
                child: CircularProgressIndicator(),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: isScanning ? null : _scanForBluetoothDevices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: EdgeInsets.all(12.0),
              ),
              child: Text(
                'Quét Máy In Bluetooth',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _connectToPrinter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.all(12.0),
              ),
              child: Text('Kết Nối Máy In'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _disconnectPrinter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.all(12.0),
              ),
              child: Text('Ngắt Kết Nối Máy In'),
            ),
          ],
        ),
      ),
    );
  }
}
