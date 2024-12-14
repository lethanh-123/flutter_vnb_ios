import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'functions.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;
  final String? customerId; // Thêm khach_id
  final String employeeName;
  final String selectedCustomer;
  final String selectedEmployeeId;
  final int selectedEmployeeIdInt;
  final void Function(List<Map<String, dynamic>>) onUpdatedProducts;
  const PaymentPage({
    Key? key,
    required this.employeeName,
    required this.selectedCustomer,
    required this.selectedProducts,
    required this.selectedEmployeeId,
    required this.selectedEmployeeIdInt,
    required this.onUpdatedProducts,
    this.customerId, // Nhận khach_id từ constructor
  }) : super(key: key);

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
  Map<String, String> productNotes =
      {}; // Lưu trữ ghi chú của sản phẩm theo ma_vach
  bool _isEmployeeSelected = false;
  List<dynamic> _employeeList = [];
  bool _showEmployeeDropdown = false;
  List<dynamic> _bankList = [];
  Map<String, dynamic> selectedGift = {};
  @override
  void initState() {
    super.initState();
    fetchAppInfo();
    _calculateTotalAmount();
  }

  void handleGiftSelection(String productId, dynamic gift) {
    setState(() {
      selectedGift[productId] = gift; // Cập nhật quà tặng đã chọn
    });
  }

  void showGiftList(
      BuildContext context, List<dynamic> giftList, String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Danh sách quà tặng'),
          content: SingleChildScrollView(
            child: ListBody(
              children: giftList.map((gift) {
                return ListTile(
                  title: Text(gift['ten_sp'] ?? 'Không xác định'),
                  subtitle: Text('SL: ${gift['ton_kho'] ?? 0}'),
                  onTap: () {
                    // Xử lý khi chọn quà tặng
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _calculateTotalAmount() {
    setState(() {
      totalAmount = widget.selectedProducts.fold(0.0, (sum, product) {
        double productTotal = (product['so_luong'] as num).toDouble() *
            (product['don_gia'] as num).toDouble();

        // Trừ tiền giảm giá nếu có
        if (product.containsKey('discountAmount')) {
          productTotal -= (product['discountAmount'] as num)
              .toDouble(); // Ensure discount is double
        }

        return sum + productTotal;
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

    // Chuyển đổi danh sách sản phẩm đã chọn thành JSON array
    List<Map<String, dynamic>> selectedProducts = widget.selectedProducts;
    List<Map<String, dynamic>> productsJsonArray =
        selectedProducts.map((product) {
      return {
        'ma_vach': product['ma_vach'],
        'gia': product['gia'],
        'so_luong': product['so_luong'],
        'qua_tang': product['qua_tang'] ?? '',
        'tien_giam_gia': product['tien_giam_gia'] ?? 0,
      };
    }).toList();

    final request = {
      'key_chi_nhanh': keyChiNhanh,
      'user_key_app': userKeyApp,
      'ma_giam_gia': discountCode,
      'khach_id': widget.customerId,
      'chi_tiet': productsJsonArray, // Thêm chi_tiet vào request
    };

    final response = await ApiService.callApi('ap_dung_ma_giam_gia', request);
    debugPrint("rrequestfasf " + request.toString());
    debugPrint("responsefasf " + response.toString());
    if (response != null) {
      setState(() {
        discountAmount = response['giam_gia_list'][0]['tien_giam_gia'] ??
            0; // Default to 0 if null
        totalAmount -= discountAmount;

        // Cập nhật ghi chú giảm giá cho sản phẩm mà không thay đổi ghi chú cũ
        for (var product in widget.selectedProducts) {
          String maGiamGia = response['giam_gia_list'][0]['ma_vach'] ?? '';
          String tienGiamGia =
              response['giam_gia_list'][0]['tien_giam_gia_format'] ?? '';
          String mucGiamGia =
              response['giam_gia_list'][0]['muc_giam_gia'].toString() ?? '';

          // Thêm trường ghi chú giảm giá mới vào sản phẩm
          product['discountNote'] =
              '${maGiamGia} - Giảm ${tienGiamGia} (${mucGiamGia}%)';
        }

        // Tính lại tổng tiền sau khi giảm giá
        _calculateTotalAmount();
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
      final nhanVienId = widget.selectedEmployeeIdInt != 0
          ? widget.selectedEmployeeIdInt
          : (widget.selectedEmployeeId.isNotEmpty
              ? int.tryParse(widget.selectedEmployeeId) ?? 0
              : 0);
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
        "nhan_vien_id": nhanVienId,
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
        centerTitle: true,
        backgroundColor: Colors.black, // Nền màu đen
        iconTheme: const IconThemeData(color: Colors.white), // Icon màu trắng
        titleTextStyle: const TextStyle(
          color: Colors.white, // Chữ màu trắng
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back
            widget.onUpdatedProducts(widget.selectedProducts);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị tên nhân viên
              _buildHeader('Nhân viên: ${widget.employeeName}', Colors.green),

              const SizedBox(height: 10),
              _buildHeader(widget.selectedCustomer, Colors.deepOrange),
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
                'Tổng tiền: ${formatCurrency(totalAmount - discountAmount)}',
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
      children: widget.selectedProducts.map((product) {
        String productId = product['ma_vach'] ?? '';
        String ghiChu = product['ghi_chu'] ?? ''; // Ghi chú hiện tại
        String discountNote = product['discountNote'] ?? ''; // Ghi chú giảm giá
        bool isGift = (product['qua_tang'] ?? '').isNotEmpty;

        // Truy xuất dữ liệu giftData

        var listTangKem = product['list_tang_kem'] != null
            ? product['list_tang_kem'] as List
            : [];

        var qua_tang_list = product['qua_tang_list'] != null
            ? product['qua_tang_list'] as List
            : [];
        // Lấy giá trị data_length
        int doi_qua_tang = product['doi_qua_tang'] ?? 0;
        debugPrint(product['ten_sp'] + "- " + doi_qua_tang.toString());
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị tên sản phẩm
                Text(
                  product['ten_sp'] ?? 'Tên sản phẩm không xác định',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Hiển thị mã vạch
                Text(
                  productId,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Xử lý số lượng và giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      color: isGift ? Colors.grey : Colors.black,
                      onPressed: isGift
                          ? null
                          : () {
                              setState(() {
                                if (product['so_luong'] > 1) {
                                  product['so_luong']--;
                                  _calculateTotalAmount();
                                } else if (product['so_luong'] == 1) {
                                  // Nếu số lượng sản phẩm chính về 0, xóa quà tặng
                                  showConfirmDialog(
                                      context, product['ma_vach']);
                                }
                              });
                            },
                    ),
                    Text(
                      '${product['so_luong'] ?? 1}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: isGift ? Colors.grey : Colors.black,
                      onPressed: isGift
                          ? null
                          : () {
                              setState(() {
                                product['so_luong']++;
                                _calculateTotalAmount();
                              });
                            },
                    ),
                    Text(
                      formatCurrency(product['so_luong'] * product['don_gia']),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Hiển thị ghi chú hiện tại (nếu có)
                if (ghiChu.isNotEmpty)
                  Text(
                    'Ghi chú: $ghiChu',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 8),
                // Hiển thị ghi chú giảm giá (nếu có)
                if (discountNote.isNotEmpty)
                  Text(
                    'Giảm giá: $discountNote',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 8),
                // Hiển thị nút Quà tặng
                if (doi_qua_tang > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          doi_qua_tang > 1 ? Colors.green : Colors.deepOrange,
                    ),
                    onPressed: () async {
                      if (doi_qua_tang > 1) {
                        await _showGiftSelectionDialog(
                          product,
                          listTangKem,
                          doi_qua_tang > 1 ? 'Đổi quà tặng' : 'Chọn quà tặng',
                        );
                      } else {
                        await _showQuaTangDialog(
                          product,
                          qua_tang_list,
                          doi_qua_tang > 1 ? 'Đổi quà tặng' : 'Chọn quà tặng',
                        );
                      }
                    },
                    child: Text(
                      doi_qua_tang > 1 ? 'Đổi quà tặng' : 'Chọn quà tặng',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void removeGiftProducts(String mainProductCode) {
    setState(() {
      widget.selectedProducts.removeWhere((product) {
        // Kiểm tra nếu `qua_tang` là mã của sản phẩm chính
        return product['qua_tang'] != null &&
            product['qua_tang'] == mainProductCode;
      });
    });
  }

  Future<void> showConfirmDialog(
      BuildContext context, String productCode) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận"),
          content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
          actions: [
            TextButton(
              child: const Text("Không"),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
            ),
            TextButton(
              child: const Text("Có"),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                removeProductAndNavigateBack(context, productCode);
              },
            ),
          ],
        );
      },
    );
  }

  void removeProductAndNavigateBack(BuildContext context, String productCode) {
    setState(() {
      // Xóa quà tặng liên quan
      removeGiftProducts(productCode);
      // Xóa sản phẩm chính
      widget.selectedProducts
          .removeWhere((product) => product['ma_vach'] == productCode);
      _calculateTotalAmount();

      // Nếu không còn sản phẩm nào, quay lại trang trước
      if (widget.selectedProducts.isEmpty) {
        Navigator.pop(context); // Quay về trang banhang.dart
        widget.onUpdatedProducts(widget.selectedProducts);
      }
    });
  }

  Future<void> _showGiftSelectionDialog(
      dynamic product, List<dynamic> giftList, String title) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: giftList.length,
              itemBuilder: (context, index) {
                final gift = giftList[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      // Cập nhật thông tin sản phẩm với quà tặng đã chọn
                      product['ten_sp'] = gift['ten_sp'];
                      product['ma_vach'] = gift['ma_vach'];
                      product['don_gia'] = gift['gia'];
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, // Nền trắng
                      border: Border.all(
                        color: Colors.grey.shade300, // Màu viền
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8), // Bo góc
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2), // Đổ bóng
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Hình ảnh quà tặng nếu có
                        gift['image_url'] != null
                            ? Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(gift['image_url']),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            : const SizedBox.shrink(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift['ten_sp'] ?? 'Tên quà tặng',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gift['ma_vach'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCurrency(gift['gia']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQuaTangDialog(
      dynamic product, List<dynamic> giftList, String title) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: giftList.length,
              itemBuilder: (context, index) {
                var gift = giftList[index];
                debugPrint("giftList[$index]" + gift.toString());
                gift['ten_sp'] = gift['qua_tang_list']['ten_sp'];
                gift['ma_vach'] = gift['qua_tang_list']['ma_vach'];
                gift['don_gia'] = gift['qua_tang_list']['gia'];
                gift['gia'] = gift['qua_tang_list']['gia'];
                gift['so_luong'] = gift['qua_tang_list']['so_luong'];
                gift['list_tang_kem'] = gift['qua_tang_list']['list_tang_kem'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      for (var product_qua_tang in widget.selectedProducts) {
                        if (product_qua_tang['qua_tang'] ==
                                product['ma_vach'] &&
                            (product_qua_tang['qua_tang'] != null &&
                                product_qua_tang['qua_tang'].isNotEmpty &&
                                product_qua_tang['doi_qua_tang'] == 2)) {
                          product_qua_tang['ten_sp'] = gift['ten_sp'];
                          product_qua_tang['ma_vach'] = gift['ma_vach'];
                          product_qua_tang['don_gia'] = gift['gia'];
                          product_qua_tang['so_luong'] =
                              gift['so_luong'] * product['so_luong'];

                          break; // Thoát vòng lặp nếu tìm thấy
                        }
                        product['list_tang_kem'] = gift['list_tang_kem'];
                      }
                      // Cập nhật thông tin sản phẩm với quà tặng đã chọn
                      /*
                      product['ten_sp'] = gift['ten_sp'];
                      product['ma_vach'] = gift['ma_vach'];
                      product['don_gia'] = gift['gia'];
                      product['so_luong'] = gift['so_luong'];
                      */
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, // Nền trắng
                      border: Border.all(
                        color: Colors.grey.shade300, // Màu viền
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8), // Bo góc
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2), // Đổ bóng
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Hình ảnh quà tặng nếu có
                        gift['image_url'] != null
                            ? Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(gift['image_url']),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            : const SizedBox.shrink(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift['ten'] ?? 'Tên quà tặng',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gift['ma_vach'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCurrency(gift['gia']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
