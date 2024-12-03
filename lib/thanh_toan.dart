import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const PaymentPage({Key? key, required this.selectedProducts})
      : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController discountCodeController = TextEditingController();
  final TextEditingController cashController = TextEditingController();
  final TextEditingController transferController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String? selectedBank;
  num totalAmount = 0;
  num discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    setState(() {
      totalAmount = widget.selectedProducts.fold(0, (sum, product) {
        return sum + (product['so_luong'] * product['don_gia']);
      });
    });
  }

  Future<void> _applyDiscount() async {
    String? keyChiNhanh = await Preferences.getKeyChiNhanh();
    String? userKeyApp = await Preferences.get_user_info("user_key_app");
    String discountCode = discountCodeController.text;

    final response = await ApiService.callApi('ap_dung_ma_giam_gia', {
      'key_chi_nhanh': keyChiNhanh,
      'user_key_app': userKeyApp,
      'discount_code': discountCode,
      'total_amount': totalAmount,
    });

    if (response != null && response['status'] == 'success') {
      setState(() {
        discountAmount =
            response['discount_amount'] ?? 0; // Default to 0 if null
        totalAmount -= discountAmount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Mã giảm giá áp dụng thành công: -${discountAmount} VNĐ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mã giảm giá không hợp lệ!')),
      );
    }
  }

  Future<void> _completePayment() async {
    String? keyChiNhanh = await Preferences.getKeyChiNhanh();
    String? userKeyApp = await Preferences.get_user_info("user_key_app");

    final response = await ApiService.callApi('xuat_hang', {
      'key_chi_nhanh': keyChiNhanh,
      'user_key_app': userKeyApp,
      'products': widget.selectedProducts,
      'cash_amount': cashController.text,
      'transfer_amount': transferController.text,
      'selected_bank': selectedBank,
      'note': noteController.text,
      'total_amount': totalAmount,
    });

    if (response != null && response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Lỗi thanh toán: ${response?['message'] ?? 'Không xác định'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> bankList = _getBankList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa Đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Thông tin khách hàng', Colors.deepOrange),
              const SizedBox(height: 16),
              _buildProductList(),

              // Discount Section
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountCodeController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã giảm giá',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _applyDiscount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: Colors.white, // Set the text color to white
                      ),
                    ),
                  ),
                ],
              ),

              // Payment Inputs
              const SizedBox(height: 16),
              TextField(
                controller: cashController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền mặt',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: transferController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền chuyển khoản',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedBank,
                items: [
                  const DropdownMenuItem<String>(
                    value: null, // null represents "Chọn ngân hàng"
                    child: Text('Chọn ngân hàng'),
                  ),
                  ...bankList.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank['id'],
                      child: Text(bank['name'] ?? ''),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedBank = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Chọn ngân hàng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Invoice Notes
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ghi chú cho hóa đơn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Total Amount
              const SizedBox(height: 16),
              Text(
                'Tổng tiền: ${totalAmount - discountAmount} VNĐ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Complete Payment Button
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _completePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Hoàn Thành Thanh Toán',
                    style: TextStyle(
                      color: Colors.white, // Set the text color to white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getBankList() {
    // Sample static data to simulate fetching bank data from the API/Preferences
    // Replace this with your actual API or preferences call
    List<Map<String, String>> bankList = [
      {"id": "bank1", "name": "Ngân hàng A"},
      {"id": "bank2", "name": "Ngân hàng B"},
      // Add more banks here from your JSONArray
    ];

    return bankList;
  }

  Widget _buildHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: widget.selectedProducts
          .map(
            (product) => Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product['ten_sp'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã sản phẩm: ${product['code'] ?? ''}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),

                    // Quantity and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decrease Button
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (product['so_luong'] > 1) {
                                product['so_luong']--;
                                _calculateTotalAmount(); // Update total after quantity change
                              }
                            });
                          },
                        ),
                        // Quantity Text
                        Text(
                          '${product['so_luong']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        // Increase Button
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              product['so_luong']++;
                              _calculateTotalAmount(); // Update total after quantity change
                            });
                          },
                        ),
                        // Price Text
                        Text(
                          _formatCurrency(
                            product['so_luong'] * product['don_gia'],
                          ),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Invoice Note Input
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          product['note'] = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Ghi chú cho sản phẩm',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Change Gift Button (Hidden by default)
                    Visibility(
                      visible:
                          false, // Can be set to true based on your condition
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('Đổi quà tặng'),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.green),
                        ),
                      ),
                    ),

                    // Gift Information (Hidden by default)
                    const Visibility(
                      visible:
                          false, // Can be set to true based on your condition
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Quà tặng',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatCurrency(num value) {
    return '${value.toStringAsFixed(0)} VNĐ';
  }
}
