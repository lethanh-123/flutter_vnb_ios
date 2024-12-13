import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrinterSetupPage extends StatefulWidget {
  @override
  _PrinterSetupPageState createState() => _PrinterSetupPageState();
}

class _PrinterSetupPageState extends State<PrinterSetupPage> {
  bool isScanning = false;
  List<brother.BluetoothPrinter> printers = [];
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

  Future<void> _scanForPrinters() async {
    setState(() {
      isScanning = true;
    });

    try {
      brother.Printer printer = brother.Printer();
      brother.PrinterInfo printInfo = brother.PrinterInfo();
      printInfo.printerModel = brother.Model.QL_1110NWB;
      await printer.setPrinterInfo(printInfo);

      // Scan for printers.
      printers = await printer
          .getBluetoothPrinters([brother.Model.QL_1110NWB.getName()]);

      setState(() {
        isScanning = false;
      });

      if (printers.isNotEmpty) {
        _showPrintersDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy máy in')),
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

  void _showPrintersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn máy in'),
          content: printers.isEmpty
              ? Text('Không tìm thấy máy in')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: printers.map((printer) {
                    return ListTile(
                      title: Text(printer.modelName ?? 'Unknown'),
                      subtitle: Text(printer.macAddress),
                      onTap: () {
                        Navigator.pop(context);
                        _saveConnectedPrinter(
                          printer.modelName ?? 'Unknown',
                          printer.macAddress,
                        );
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
        title: const Text('Quét Máy In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quét và chọn máy in',
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
              onPressed: isScanning ? null : _scanForPrinters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                padding: const EdgeInsets.all(12.0),
              ),
              child: const Text(
                'Quét Máy In',
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
