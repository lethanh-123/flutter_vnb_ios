import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class PaymentPage extends StatelessWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const PaymentPage({Key? key, required this.selectedProducts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa Đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Quay về trang trước
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: selectedProducts.length,
                itemBuilder: (context, index) {
                  final product = selectedProducts[index];
                  return ListTile(
                    title: Text(product['ten_sp'] ?? ''),
                    subtitle: Text(
                        'Số lượng: ${product['so_luong']} - Giá: ${formatCurrency(product['don_gia'])}'),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Thêm logic thanh toán tại đây
              },
              child: const Text('Hoàn tất Thanh Toán'),
            ),
          ],
        ),
      ),
    );
  }
}
