import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSetupPage extends StatefulWidget {
  @override
  _PrinterSetupPageState createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  bool isScanning = false;
  List<BluetoothDevice> devices = [];
  String? connectedPrinterName;
  String? connectedPrinterAddress;

  @override
  void initState() {
    super.initState();
    _loadConnectedPrinter();
  }

  Future<void> _loadConnectedPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      connectedPrinterAddress = prefs.getString('connected_printer_address');
      connectedPrinterName = prefs.getString('connected_printer_name');
    });
  }

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

  Future<void> _scanForBluetoothDevices() async {
    setState(() {
      isScanning = true;
    });

    try {
      final FlutterBlue flutterBlue = FlutterBlue.instance;
      flutterBlue.startScan(timeout: const Duration(seconds: 10));

      flutterBlue.scanResults.listen((results) {
        setState(() {
          devices = results.map((r) => r.device).toList();
        });
      }).onDone(() {
        setState(() {
          isScanning = false;
        });
        flutterBlue.stopScan();
        _showBluetoothDevicesDialog(context);
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

  void _showBluetoothDevicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn máy in Bluetooth'),
          content: devices.isEmpty
              ? const Text('Không tìm thấy thiết bị Bluetooth')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: devices.map((device) {
                    return ListTile(
                      title: Text(device.name ?? device.id.toString()),
                      subtitle: Text(device.id.id),
                      onTap: () {
                        Navigator.pop(context);
                        _saveConnectedPrinter(
                            device.name ?? 'Không tên', device.id.id);
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
        title: const Text('Thiết lập máy in Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quét và chọn máy in Bluetooth',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 16.0),
            if (connectedPrinterName != null)
              Row(
                children: [
                  const Text(
                    'Máy in đã kết nối:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connectedPrinterName!,
                    style: const TextStyle(fontSize: 16, color: Colors.teal),
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
            if (isScanning)
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 16.0),
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
