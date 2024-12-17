import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:typed_data';
import 'api_service.dart';
import 'preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; // Import BlueThermalPrinter
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as bluetooth_serial; // Alias flutter_bluetooth_serial
import 'package:html/parser.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String maPhieu;

  const InvoiceDetailScreen({Key? key, required this.maPhieu})
      : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InAppWebViewController? _webViewController;
  String _contentHtml = "";

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    try {
      String? keyChiNhanh = await Preferences.getKeyChiNhanh();
      String? userKeyApp = await Preferences.get_user_info("user_key_app");

      if (keyChiNhanh == null || userKeyApp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy thông tin người dùng')),
        );
        return;
      }

      final response = await ApiService.callApi('in_phieu_xuat', {
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
        'ma_phieu': widget.maPhieu,
      });

      if (response != null && response['content'] != null) {
        setState(() {
          _contentHtml = response['content'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được chi tiết hóa đơn')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi tải chi tiết hóa đơn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _printInvoice() async {
    try {
      String? connectedPrinter = await Preferences.getMayin();
      debugPrint("connectedPrinter: $connectedPrinter");

      if (connectedPrinter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có máy in nào được kết nối')),
        );
        return;
      }

      final bluetooth = BlueThermalPrinter.instance;
      bool? isConnected = await bluetooth.isConnected;

      if (isConnected != true) {
        await _connectPrinter(connectedPrinter, bluetooth);
      }

      // Chụp hình ảnh từ WebView
      Uint8List? imageBytes = await _captureImageFromWebView();
      if (imageBytes != null) {
        debugPrint("Ảnh chụp từ WebView đã sẵn sàng.");

        // Gửi ảnh tới máy in Bluetooth
        bluetooth.printImageBytes(imageBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In hóa đơn thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chụp ảnh hóa đơn để in')),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi in hóa đơn: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi in hóa đơn: $e')),
      );
    }
  }

  Future<Uint8List?> _captureImageFromWebView() async {
    try {
      if (_webViewController != null) {
        Uint8List? imageBytes = await _webViewController!.takeScreenshot();
        return imageBytes;
      }
    } catch (e) {
      debugPrint("Lỗi khi chụp ảnh từ WebView: $e");
    }
    return null;
  }

  Future<void> _connectPrinter(
      String connectedPrinter, BlueThermalPrinter bluetooth) async {
    List<bluetooth_serial.BluetoothDevice> devices = await bluetooth_serial
        .FlutterBluetoothSerial.instance
        .getBondedDevices();

    try {
      bluetooth_serial.BluetoothDevice device =
          devices.firstWhere((d) => d.address == connectedPrinter);

      final printerDevice = BluetoothDevice(
        name: device.name ?? 'Unknown',
        address: device.address ?? '',
      );

      await bluetooth.connect(printerDevice);
      debugPrint("Kết nối thành công với máy in: ${device.name}");
    } catch (e) {
      debugPrint("Không tìm thấy hoặc kết nối máy in thất bại: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không tìm thấy máy in hoặc kết nối thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
          ),
        ],
      ),
      body: _contentHtml.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : InAppWebView(
              initialData: InAppWebViewInitialData(data: _contentHtml),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
            ),
    );
  }
}
