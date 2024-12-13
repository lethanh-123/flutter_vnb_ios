import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:html/parser.dart';
import 'api_service.dart';
import 'preferences.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String maPhieu;

  const InvoiceDetailScreen({Key? key, required this.maPhieu}) : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late WebViewController _webViewController;
  String _contentHtml = "";
  final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _availablePrinters = [];
  PrinterBluetooth? _selectedPrinter;

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

  Future<void> _startPrinterScan() async {
    _printerManager.startScan(Duration(seconds: 4));
    _printerManager.scanResults.listen((printers) {
      setState(() {
        _availablePrinters = printers;
      });
    });
  }

  Future<void> _printInvoice() async {
    try {
      if (_selectedPrinter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn máy in trước khi in')),
        );
        return;
      }

      _printerManager.selectPrinter(_selectedPrinter!);

      // Parse HTML to plain text
      final document = parse(_contentHtml);
      final plainText = document.body?.text ?? "";

      // Create ticket for printing
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      final List<int> ticket = [];

      ticket.addAll(generator.text('Chi tiết hóa đơn', styles: const PosStyles(align: PosAlign.center, bold: true)));
      ticket.addAll(generator.hr());
      ticket.addAll(generator.text(plainText));
      ticket.addAll(generator.cut());

      final PosPrintResult res = await _printerManager.printTicket(ticket);

      if (res == PosPrintResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In hóa đơn thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi in hóa đơn: ${res.msg}')),
        );
      }
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
            onPressed: () async {
              await _startPrinterScan();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Chọn máy in'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: _availablePrinters.length,
                      itemBuilder: (context, index) {
                        final printer = _availablePrinters[index];
                        return ListTile(
                          title: Text(printer.name ?? 'Unknown'),
                          subtitle: Text(printer.address ?? 'No Address'),
                          onTap: () {
                            setState(() {
                              _selectedPrinter = printer;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _contentHtml.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController),
      floatingActionButton: FloatingActionButton(
        onPressed: _printInvoice,
        child: const Icon(Icons.print),
      ),
    );
  }
}
