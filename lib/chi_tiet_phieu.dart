import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:html/parser.dart';
import 'api_service.dart';
import 'preferences.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
      final FlutterBlue flutterBlue = FlutterBlue.instance;

      String? connectedPrinter = await Preferences.getMayin();
      if (connectedPrinter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có máy in nào được kết nối')),
        );
        return;
      }

      List<BluetoothDevice> devices = await flutterBlue.connectedDevices;
      BluetoothDevice? printerDevice = devices.firstWhere(
          (device) => device.id.id == connectedPrinter,
          orElse: () => throw Exception('Printer device not found'));

      if (printerDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy máy in được kết nối')),
        );
        return;
      }

      // Parse HTML content and send to printer
      final document = parse(_contentHtml);
      final plainText = document.body?.text ?? "";

      // Add logic to print plainText via Bluetooth connection
      debugPrint("Printing content: $plainText");
      // Implement your printer-specific print method here

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
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            color: Colors.white,
          ),
        ],
      ),
      body: _contentHtml.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController),
    );
  }
}
