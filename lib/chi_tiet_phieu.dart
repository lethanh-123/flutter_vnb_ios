import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'api_service.dart';
import 'preferences.dart';

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

        // Load content vào WebView
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

  void _printInvoice() {
    // Thực hiện in hóa đơn (tùy theo tích hợp với máy in Bluetooth)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("In hóa đơn"),
        content: Text("Bạn có muốn in hóa đơn ${widget.maPhieu}?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Thêm logic gọi in hóa đơn tại đây
            },
            child: Text("In"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Hủy"),
          ),
        ],
      ),
    );
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
          : WebViewWidget(
              controller: WebViewController()
                ..loadHtmlString(Uri.dataFromString(
                  _contentHtml,
                  mimeType: 'text/html',
                  encoding: utf8,
                ).toString()),
            ),
    );
  }
}
