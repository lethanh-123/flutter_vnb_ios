import 'package:flutter/material.dart';

class PrinterSetupPage extends StatefulWidget {
  @override
  _PrinterSetupPageState createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  bool isScanning = false;

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
            if (isScanning)
              Center(
                child: CircularProgressIndicator(),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: isScanning
                  ? null
                  : () {
                      setState(() {
                        isScanning = true;
                      });

                      // Giả lập quá trình quét
                      Future.delayed(Duration(seconds: 3), () {
                        setState(() {
                          isScanning = false;
                        });

                        // Hiển thị danh sách thiết bị sau khi quét
                        _showBluetoothDevicesDialog(context);
                      });
                    },
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

  void _showBluetoothDevicesDialog(BuildContext context) {
    final devices = [
      'Printer 1',
      'Printer 2',
      'Printer 3',
    ]; // Dữ liệu giả lập, thay bằng dữ liệu thực tế từ Bluetooth

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn máy in Bluetooth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) {
              return ListTile(
                title: Text(device),
                onTap: () {
                  Navigator.pop(context);
                  _saveSelectedPrinter(device);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _saveSelectedPrinter(String printerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã chọn máy in: $printerName')),
    );

    // TODO: Lưu vào SharedPreferences nếu cần thiết
  }
}
