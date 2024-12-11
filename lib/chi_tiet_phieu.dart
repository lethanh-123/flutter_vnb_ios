import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'api_service.dart';
import 'preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; // Import BlueThermalPrinter
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as bluetooth_serial; // Alias flutter_bluetooth_serial
import 'package:html/parser.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String maPhieu;

  const InvoiceDetailScreen({Key? key, required this.maPhieu})
      : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late WebViewController _webViewController;
  String _contentHtml = "";

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
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
        debugPrint("_contentHtml $_contentHtml");
        _webViewController.loadHtmlString(_contentHtml);
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
      // Lấy máy in đã lưu
      String? connectedPrinter = await Preferences.getMayin();
      if (connectedPrinter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có máy in nào được kết nối')),
        );
        return;
      }

      // Khởi tạo BlueThermalPrinter
      final bluetooth = BlueThermalPrinter.instance;
      bool? isConnected = await bluetooth.isConnected;

      if (isConnected != true) {
        // Lấy danh sách các thiết bị đã ghép nối từ flutter_bluetooth_serial
        List<bluetooth_serial.BluetoothDevice> devices = await bluetooth_serial
            .FlutterBluetoothSerial.instance
            .getBondedDevices();
        debugPrint("device $connectedPrinter");

        // Tìm thiết bị khớp với địa chỉ đã lưu
        bluetooth_serial.BluetoothDevice? device;
        try {
          device = devices.firstWhere((d) => d.address == connectedPrinter);
        } catch (e) {
          debugPrint("Error finding device: $e");
          device = null;
        }

        if (device == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy máy in Bluetooth')),
          );
        } else {
          debugPrint("Found device: ${device.name} - ${device.address}");
          // Tiến hành kết nối với máy in
          if (device != null) {
            // Chuyển đổi sang BluetoothDevice của BlueThermalPrinter
            final printerDevice = BluetoothDevice(
              device.name ?? 'Unknown',
              device.address,
            );

            // Kết nối với máy in
            await bluetooth.connect(printerDevice);
          }
        }
      }

      // Parse và in nội dung HTML
      final document = parse(_contentHtml);
      final plainText = document.body?.text ?? "";

      bluetooth.printNewLine();
      bluetooth.printCustom("Chi tiết hóa đơn", 1, 1); // Header
      bluetooth.printNewLine();
      bluetooth.printCustom(plainText, 0, 0); // Content
      bluetooth.printNewLine();
      bluetooth.paperCut(); // Paper cut nếu được hỗ trợ

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In hóa đơn thành công!')),
      );
    } catch (e) {
      debugPrint('Lỗi khi in hóa đơn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi in hóa đơn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        centerTitle: true,
        backgroundColor: Colors.black, // Nền màu đen
        iconTheme: const IconThemeData(color: Colors.white), // Icon màu trắng
        titleTextStyle: const TextStyle(
          color: Colors.white, // Chữ màu trắng
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            color: Colors.white, // Màu icon in
          ),
        ],
      ),
      body: _contentHtml.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController),
    );
  }
}
