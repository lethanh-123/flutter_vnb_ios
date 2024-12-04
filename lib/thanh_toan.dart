import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';

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
  List<Map<String, dynamic>> gifts = [];
  Map<String, String> productNotes =
      {}; // Lưu trữ ghi chú của sản phẩm theo ma_vach
  bool _isEmployeeSelected = false;
  List<dynamic> _employeeList = [];
  bool _showEmployeeDropdown = false;
  List<dynamic> _bankList = [];
  @override
  void initState() {
    super.initState();
    // checkQuaTang();
    fetchAppInfo();
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    setState(() {
      totalAmount = widget.selectedProducts.fold(0, (sum, product) {
        return sum + (product['so_luong'] * product['don_gia']);
      });
    });
  }

  Future<void> fetchAppInfo() async {
    try {
      dynamic keyChiNhanh = await Preferences.getKeyChiNhanh();
      dynamic userKeyApp = await Preferences.getUserKeyApp();

      final response = await ApiService.callApi('get_info_app', {
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
      });

      if (response != null && response['loi'] == 0) {
        setState(() {
          // Lưu danh sách ngân hàng từ response
          _bankList = response['ngan_hang_list'] ?? [];
          if (response['chon_nhan_vien'] == 1) {
            _showEmployeeDropdown = true;
            _employeeList = response['nv_list'] as List<dynamic>;
          } else {
            _showEmployeeDropdown = false;
          }
        });
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy thông tin ứng dụng: $e')),
      );
    }
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

    if (response != null) {
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

  Future<void> checkQuaTang() async {
    debugPrint("checkQuaTang 1");
    try {
      String? keyChiNhanh = await Preferences.getKeyChiNhanh();

      for (var product in widget.selectedProducts) {
        String productId = product['ma_vach']; // Lấy mã vạch của sản phẩm
        int quantity = product['so_luong']; // Lấy số lượng của sản phẩm

        final response = await ApiService.callApi('check_qua_tang', {
          'key_chi_nhanh': keyChiNhanh,
          'ma_vach': productId,
          'so_luong': quantity,
        });

        if (response != null) {
          int loi = response['loi'] ?? -1;
          String txtLoi = response['txt_loi'] ?? '';
          var data = response['data'];

          if (loi == 0 && data is List && data.isNotEmpty) {
            for (var item in data) {
              var quaTangList = item['qua_tang_list'];
              if (quaTangList != null && quaTangList is Map) {
                String ghiChu = quaTangList['ghi_chu'] ?? '';
                productNotes[productId] = ghiChu; // Lưu ghi chú theo mã vạch
              }
            }
          } else {}
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể kết nối tới server.')),
          );
        }
      }
      setState(() {}); // Cập nhật UI sau khi xử lý xong
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  Future<void> _completePayment() async {
    // Lấy thông tin từ Preferences
    String? keyChiNhanh = await Preferences.getKeyChiNhanh();
    String? userKeyApp = await Preferences.get_user_info("user_key_app");
    String? strKhachInfo = await Preferences.getKhach();
    String? strUserInfo = await Preferences.getUser();

    if (keyChiNhanh == null ||
        userKeyApp == null ||
        strKhachInfo == null ||
        strUserInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đủ thông tin để thanh toán')),
      );
      return;
    }

    try {
      // Parse dữ liệu khách hàng và người dùng
      Map<String, dynamic> khachInfo = jsonDecode(strKhachInfo);
      Map<String, dynamic> userInfo = jsonDecode(strUserInfo);

      // Lấy các giá trị từ thông tin khách hàng và người dùng
      int khachId = khachInfo['id'];
      String keyChiNhanh = userInfo['key_chi_nhanh'];
      String userKeyApp = userInfo['user_key_app'];

      // Chuẩn bị dữ liệu sản phẩm
      List<Map<String, dynamic>> productsJsonArray = widget.selectedProducts;
      // Tạo requestData
      final requestData = {
        "khach_id": khachId,
        "MaGiamGia":
            discountCodeController.text.trim(), // Mã giảm giá từ TextField
        "chi_tiet": productsJsonArray, // Danh sách sản phẩm
        "user_key_app": userKeyApp,
        "chuyen_khoan":
            transferController.text.trim(), // Tiền chuyển khoản từ TextField
        "ngan_hang": selectedBank, // Ngân hàng được chọn từ Dropdown
        "tien_mat": cashController.text.trim(),
        // "nhan_vien_id": nhanVienId,
        "ghi_chu": noteController.text.trim(),
        "key_chi_nhanh": keyChiNhanh, // Key chi nhánh
      };

      // Gửi request API
      final response = await ApiService.callApi('xuat_hang', requestData);

      if (response != null && response['status'] == 'success') {
        // Thanh toán thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán thành công!')),
        );
        Navigator.pop(context);
      } else {
        // Hiển thị lỗi nếu thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Lỗi thanh toán: ${response?['message'] ?? 'Không xác định'}'),
          ),
        );
      }
    } catch (e) {
      // Xử lý lỗi ngoại lệ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    value: null, // null đại diện cho "Chọn ngân hàng"
                    child: Text('Chọn ngân hàng'),
                  ),
                  ..._bankList.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank['id'].toString(), // Đảm bảo giá trị là String
                      child: Text(bank['ten'] ?? ''), // Hiển thị tên ngân hàng
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
      children: widget.selectedProducts.map(
        (product) {
          String productId = product['ma_vach']; // Lấy mã vạch của sản phẩm
          String ghiChu = productNotes[productId] ?? ''; // Lấy ghi chú từ Map

          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    product['ten_sp'] ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product['ma_vach'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  // Số lượng và giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (product['so_luong'] > 1) {
                              product['so_luong']--;
                              _calculateTotalAmount();
                            }
                          });
                        },
                      ),
                      Text(
                        '${product['so_luong']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            product['so_luong']++;
                            _calculateTotalAmount();
                          });
                        },
                      ),
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

                  // Hiển thị ghi chú
                  if (ghiChu.isNotEmpty) ...[
                    Text(
                      'Ghi chú: $ghiChu',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  String _formatCurrency(num value) {
    return '${value.toStringAsFixed(0)} VNĐ';
  }
}
