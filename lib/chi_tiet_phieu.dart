import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'api_service.dart';
import 'preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as bluetooth_serial; // Alias flutter_bluetooth_serial
import 'package:html/parser.dart';

import 'dart:async';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:another_brother/label_info.dart';

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:another_brother/printer_info.dart' as brother;
import 'package:another_brother/label_info.dart';
import 'package:html/parser.dart'; // For parsing HTML
import 'preferences.dart';
import 'api_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String maPhieu;

  const InvoiceDetailScreen({Key? key, required this.maPhieu}) : super(key: key);

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
      // Parse the content into plain text for printing
      final document = parse(_contentHtml);
      final plainText = document.body?.text ?? "";

      // Configure printer
      brother.Printer printer = brother.Printer();
      brother.PrinterInfo printInfo = brother.PrinterInfo();

      printInfo.printerModel = brother.Model.QL_1110NWB;
      printInfo.printMode = brother.PrintMode.FIT_TO_PAGE;
      printInfo.isAutoCut = true;
      printInfo.orientation = brother.Orientation.PORTRAIT;
      printInfo.port = brother.Port.BLUETOOTH;
      printInfo.align = brother.Align.CENTER;

      // Set label type
      printInfo.labelNameIndex = QL1100.ordinalFromID(QL1100.W103H164.getId());

      await printer.setPrinterInfo(printInfo);

      // Discover available printers
      List<brother.BluetoothPrinter> printers = await printer
          .getBluetoothPrinters([brother.Model.QL_1110NWB.getName()]);

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy máy in Bluetooth')),
        );
        return;
      }

      // Use the first discovered printer
      printInfo.macAddress = printers.first.macAddress;
      await printer.setPrinterInfo(printInfo);

      // Convert plainText to Paragraph for printing
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 14.0,
        ),
      )..addText(plainText);

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 300));

      // Print the Paragraph
      await printer.printText(paragraph);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
          ),
        ],
      ),
      body: _contentHtml.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController),
    );
  }
}
