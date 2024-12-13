import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSetupPage extends StatefulWidget {
  @override
  _PrinterSetupPageState createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  bool isScanning = false;
  List<BluetoothDevice> devices = [];
  String? connectedPrinterName; // Tên máy in đã kết nối
  String? connectedPrinterAddress; // Địa chỉ máy in đã kết nối

  @override
  void initState() {
    super.initState();
    _loadConnectedPrinter();
  }

  // Hàm tải máy in đã kết nối từ SharedPreferences
  Future<void> _loadConnectedPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      connectedPrinterAddress = prefs.getString('connected_printer_address');
      connectedPrinterName = prefs.getString('connected_printer_name');
    });
  }

  // Hàm lưu máy in vào SharedPreferences
  Future<void> _saveConnectedPrinter(
      String printerName, String printerAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('connected_printer_address', printerAddress);
    await prefs.setString('connected_printer_name', printerName);
    setState(() {
      connectedPrinterName = printerName;
      connectedPrinterAddress = printerAddress;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu máy in: $printerName')),
    );
  }

  // Hàm quét các thiết bị Bluetooth
  Future<void> _scanForBluetoothDevices() async {
    setState(() {
      isScanning = true;
    });

    try {
      List<BluetoothDevice> foundDevices = [];
      // Quét các thiết bị Bluetooth
      await FlutterBluetoothSerial.instance.startDiscovery().listen((event) {
        foundDevices.add(event.device);
      }).asFuture();

      setState(() {
        devices = foundDevices;
        isScanning = false;
      });

      if (devices.isNotEmpty) {
        _showBluetoothDevicesDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thiết bị Bluetooth')),
        );
      }
    } catch (e) {
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi quét thiết bị: $e')),
      );
    }
  }

  // Hàm hiển thị danh sách thiết bị Bluetooth trong hộp thoại
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
                      title: Text(device.name ?? device.address),
                      subtitle: Text(device.address),
                      onTap: () {
                        Navigator.pop(context);
                        _saveConnectedPrinter(
                            device.name ?? 'Không tên', device.address);
                      },
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quét Máy In Bluetooth'),
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
            if (connectedPrinterName != null)
              Row(
                children: [
                  Text(
                    'Máy in đã kết nối:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text(
                    connectedPrinterName!,
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
          ],
        ),
      ),
    );
  }
}
