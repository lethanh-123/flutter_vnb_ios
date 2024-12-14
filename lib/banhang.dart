import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'thanh_toan.dart';
import 'danh_sach_khach_hang.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Đọc giọng nói
import 'package:audioplayers/audioplayers.dart'; // Phát âm thanh
import 'package:shared_preferences/shared_preferences.dart'; // Lưu cài đặt

class BanHangScreen extends StatefulWidget {
  const BanHangScreen({super.key});

  @override
  State<BanHangScreen> createState() => _BanHangScreenState();
}

class _BanHangScreenState extends State<BanHangScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _selectedProducts = [];
  String? _selectedEmployeeId;
  bool _isFetchingProducts = false;
  bool _isScanning = false;
  String _selectedCustomer = 'Chọn khách hàng';
  String? _selectedCustomerId;
  String _selectedEmployee = 'Chọn nhân viên bán hàng';
  String _scanStatus = 'Scan status';
  final int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  int trang_tim_kiem = 1;
  bool dung_tim_kiem = false;
  bool _isLoading = false;
  int? _selectedEmployeeIdInt;
  List<Map<String, dynamic>> gifts = [];
  List<dynamic> _employeeList = [];
  bool _showEmployeeDropdown = false;
  List<dynamic> _bankList = [];
  int notificationType = 0;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  String employeeName = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearch();
    });
    //checkQuaTang();
    fetchAppInfo();
    _loadNotificationType();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingProducts &&
        !dung_tim_kiem) {
      _onSearch(page: trang_tim_kiem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Bán Hàng'),
        centerTitle: true,
        backgroundColor: Colors.black, // Nền màu đen
        iconTheme: const IconThemeData(color: Colors.white), // Icon màu trắng
        titleTextStyle: const TextStyle(
            color: Colors.white, // Chữ màu trắng
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildEmployeeAndCustomerSection(),
          _buildProductList(),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30), // Thêm margin-top 20px
      child: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Tồn kho'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tonkho');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Bán hàng'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/banhang');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Danh sách hóa đơn'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/invoices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cai_dat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Đăng xuất'),
              onTap: _logout,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Phiên bản: 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationType() async {
    final prefs = await SharedPreferences.getInstance();
    notificationType = prefs.getInt('notificationType') ?? 0;
  }

  Future<void> _playNotification(String productName) async {
    switch (notificationType) {
      case 0: // Tiếng bíp
        await audioPlayer
            .play(AssetSource('beep.mp3')); // Đường dẫn file âm thanh
        break;
      case 1: // Giọng nói
        await flutterTts.speak("Sản phẩm: $productName");
        break;
      case 2: // Không âm thanh
      default:
        // Không làm gì
        break;
    }
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Nhập tên sản phẩm',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _onSearch(page: 1),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _startBarcodeScanning(false),
          ),
        ],
      ),
    );
  }

  Future<void> fetchAppInfo() async {
    try {
      dynamic keyChiNhanh = await Preferences.getKeyChiNhanh();
      dynamic userKeyApp = await Preferences.getUserKeyApp();

      final response = await ApiService.callApi('get_info_app', {
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
      });

      debugPrint("Response: ${response.toString()}");

      if (response != null && response['loi'] == 0) {
        setState(() {
          // Lưu danh sách ngân hàng từ response
          _bankList = response['ngan_hang_list'] ?? [];

          int chonNhanVien = response['chon_nhan_vien'] ?? 0; // Mặc định là 0
          debugPrint("Danh sách nhân viên: ${response['nv_list']}");

          if (chonNhanVien == 1) {
            // Hiển thị danh sách nhân viên
            _showEmployeeDropdown = true;

            // Đảm bảo response['nv_list'] là danh sách
            if (response['nv_list'] is List) {
              _employeeList = response['nv_list'] as List<dynamic>;

              // Thêm mục "Chọn nhân viên" vào đầu danh sách
              _employeeList.insert(0, {'id': '', 'ten': 'Chọn nhân viên'});

              // Cập nhật giao diện để hiển thị giá trị mặc định
              setState(() {
                _selectedEmployeeId = ''; // ID của "Chọn nhân viên"
                _selectedEmployee = 'Chọn nhân viên'; // Tên hiển thị mặc định
              });
            } else {
              // Nếu danh sách không hợp lệ, tạo danh sách chỉ có "Chọn nhân viên"
              _employeeList = [
                {'id': '', 'ten': 'Chọn nhân viên'}
              ];
              setState(() {
                _selectedEmployeeId = ''; // ID mặc định
                _selectedEmployee = 'Chọn nhân viên';
              });
            }
          } else if (chonNhanVien == 2) {
          } else if (chonNhanVien == 0) {
            // Hiển thị luôn nhân viên đăng nhập
            _showEmployeeDropdown = false;
            employeeName = response['ten_thanh_vien'] ?? '';
            _selectedEmployee = "Nhân viên bán hàng: $employeeName";
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

  void _handleEmployeeSelection() {
    _startBarcodeScanning(true); // Quét mã QR trước
  }

  void _navigateToPaymentPage() {
    debugPrint("_selectedCustomerId $_selectedCustomerId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          employeeName: _selectedEmployee,
          selectedProducts: List<Map<String, dynamic>>.from(_selectedProducts
              .where((product) => (product['so_luong'] ?? 0) > 0)
              .toList()),
          onUpdatedProducts: (updatedProducts) {
            setState(() {
              // Cập nhật danh sách sản phẩm được chọn sau khi quay lại
              _selectedProducts.clear();
              _selectedProducts.addAll(updatedProducts);
              debugPrint(
                  "Updated products in banhang.dart: $_selectedProducts");
            });
          },
          customerId: _selectedCustomerId, // Truyền khach_id
          selectedEmployeeId: _selectedEmployeeId ?? '',
          selectedEmployeeIdInt: _selectedEmployeeIdInt ?? 0,
          selectedCustomer: _selectedCustomer,
        ),
      ),
    );
  }

  Future<void> checkQuaTang(dynamic product) async {
    if (product['so_luong'] > 0) {
      String? keyChiNhanh = await Preferences.getKeyChiNhanh();
      String productId = product['ma_vach'];
      int quantity = product['so_luong'];
      final requestData = {
        'key_chi_nhanh': keyChiNhanh,
        'ma_vach': productId,
        'so_luong': quantity,
      };
      final response = await ApiService.callApi('check_qua_tang', requestData);
      debugPrint("Request data: $requestData");
      if (response != null && response['loi'] == 0) {
        var data = response['data'];
        if (data is List && data.isNotEmpty) {
          // Xử lý từng phần tử của `data`
          dynamic quaTang = data[0]['qua_tang_list'];

          quaTang['don_gia'] = quaTang['gia'] ?? 0;
          quaTang['qua_tang'] = product['ma_vach'];
          quaTang['doi_qua_tang'] = quaTang['doi_qua_tang'] ?? 0;
          debugPrint("qua_tang_info: " + quaTang.toString());
          _selectedProducts.add(quaTang);
          //Nếu data.length>1 thì sẽ edit chon_qua_tang hiện tại của product chính =1
          if (data.length > 1) {
            for (var product_chinh in _selectedProducts) {
              if (product_chinh['ma_vach'] == product['ma_vach'] &&
                  (product_chinh['qua_tang'] == null ||
                      product_chinh['qua_tang'].isEmpty)) {
                product_chinh['doi_qua_tang'] = 1; // Cập nhật giá trị
                product_chinh['qua_tang_list'] = data; // Cập nhật giá trị
                break; // Thoát vòng lặp nếu tìm thấy
              }
            }
          }
        }
        var data_tang_kem = response['data_tang_kem'];
        if (data_tang_kem != null && data_tang_kem.isNotEmpty) {
          // Xử lý từng phần tử của `data`
          dynamic quaTang_kem = data_tang_kem;
          quaTang_kem['don_gia'] = quaTang_kem['gia'] ?? 0;
          quaTang_kem['qua_tang'] = product['ma_vach'];
          quaTang_kem['doi_qua_tang'] = quaTang_kem['doi_qua_tang'] ?? 0;
          _selectedProducts.add(quaTang_kem);
        }
      } else {
        debugPrint("Phản hồi từ API không hợp lệ hoặc có lỗi.");
      }

      setState(() {}); // Cập nhật giao diện
    }
  }

  Widget _buildEmployeeAndCustomerSection() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showEmployeeDropdown && _employeeList.isNotEmpty) ...[
            DropdownButton<String>(
              value: _selectedEmployeeId,
              items: _employeeList.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee['id'].toString(),
                  child: Text(employee['ten']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEmployeeId = value!;
                  _selectedEmployee = _employeeList.firstWhere(
                      (employee) => employee['id'].toString() == value)['ten'];
                });
                debugPrint("_selectedEmployee" + _selectedEmployee);
              },
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _handleEmployeeSelection,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                _selectedEmployee.isNotEmpty
                    ? _selectedEmployee
                    : 'Nhân viên bán hàng',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
          const SizedBox(height: 3.0),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _selectCustomer,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text(
                _selectedCustomer.isNotEmpty
                    ? _selectedCustomer
                    : 'Chọn khách hàng',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerListScreen()),
    );
    debugPrint("fsdfsafasf" + result['id']);
    if (result != null) {
      setState(() {
        _selectedCustomer =
            "Khách hàng: ${result['ten']} - ${result['so_dt']}"; // Gộp tên và số điện thoại
        _selectedCustomerId = result['id'];
      });
    }
  }

  void _selectEmployee() {
    setState(() {
      _selectedEmployee = employeeName;
    });
  }

  String? _scannedCode; // Biến lưu mã QR quét được
  Widget _buildProductList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + 1, // Add 1 for the loading indicator
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return dung_tim_kiem
                ? const SizedBox.shrink()
                : const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
          }

          var product = _products[index];
          if (product['qua_tang'] == null) product['qua_tang'] = "";
          var isSelected = false;
          var index_select;
          for (int i = 0; i < _selectedProducts.length; i++) {
            var san_pham = _selectedProducts[i];
            if (san_pham['qua_tang'] == null) san_pham['qua_tang'] = "";
            if (san_pham['ma_vach'] == product['ma_vach'] &&
                san_pham['qua_tang'] == product['qua_tang']) {
              isSelected = true;
              index_select = i;

              break;
            }
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedProducts.removeAt(index_select);

                  product['so_luong'] = 0; // Đặt lại số lượng khi bỏ chọn
                } else {
                  product['so_luong'] = 0; // Khởi tạo số lượng là 0
                  _selectedProducts.add(product);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.withOpacity(0.3)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  product['photo'] != null
                      ? Stack(
                          children: [
                            Image.network(
                              product['photo'] ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                          ],
                        )
                      : const Icon(Icons.image, size: 50),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['ten_sp'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text('${product['ma_vach']}'),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giá: ${formatCurrency(product['don_gia'])}',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                            if (isSelected)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    iconSize: 30,
                                    onPressed: () {
                                      setState(() {
                                        product['so_luong'] =
                                            (product['so_luong'] ?? 1) - 1;
                                        if (product['so_luong'] < 0) {
                                          product['so_luong'] = 0;
                                        }
                                        if (product['so_luong'] == 0) {
                                          // Xóa sản phẩm chính và quà tặng liên quan
                                          removeGiftProducts(
                                              product['ma_vach']);
                                          _selectedProducts.removeWhere((sp) =>
                                              sp['ma_vach'] ==
                                              product['ma_vach']);
                                          _products.removeWhere((sp) =>
                                              sp['ma_vach'] ==
                                              product['ma_vach']);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    '${product['so_luong'] ?? 0}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    iconSize: 30,
                                    onPressed: () {
                                      setState(() {
                                        product['so_luong'] =
                                            (product['so_luong'] ?? 0) + 1;
                                        for (var sp in _selectedProducts) {
                                          if (sp['ma_vach'] ==
                                                  product['ma_vach'] &&
                                              sp['qua_tang'] ==
                                                  product['qua_tang']) {
                                            sp['so_luong'] = product[
                                                'so_luong']; // Set the quantity to 0
                                            checkQuaTang(
                                                sp); // Re-check gifts after adding
                                            break; // Exit the loop once the gift is updated
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    debugPrint("_selectedEmployeeIdInt $_selectedEmployeeIdInt");
    return SizedBox(
      width: double.infinity, // Chiều rộng full màn hình
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange, // Màu nền của nút
          padding:
              const EdgeInsets.symmetric(vertical: 5), // Padding để nút đẹp hơn
        ),
        onPressed: () {
          num totalQuantity = 0;

          for (var product in _products) {
            totalQuantity += product['so_luong'] ?? 0;
          }

          // Kiểm tra các điều kiện
          if ((_selectedCustomerId ?? '').isEmpty) {
            // Hiển thị thông báo nếu chưa chọn khách hàng
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Thông báo'),
                  content: const Text('Vui lòng chọn khách hàng.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else if ((_selectedEmployeeId ?? '').isEmpty &&
              _selectedEmployeeIdInt == 0) {
            // Hiển thị thông báo nếu chưa chọn nhân viên
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Thông báo'),
                  content: const Text('Vui lòng chọn nhân viên bán hàng.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else if (totalQuantity == 0) {
            // Hiển thị thông báo nếu không có sản phẩm nào được chọn
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Thông báo'),
                  content: const Text('Vui lòng chọn ít nhất một sản phẩm.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            // Điều hướng qua trang thanh toán nếu tất cả điều kiện đều đúng
            _navigateToPaymentPage();
          }
        },
        child: const Text(
          'Tiếp tục',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _onSearch({int page = 1}) async {
    if (page < 1) page = 1; // Ensure page number starts at 1

    setState(() {
      _isFetchingProducts = true;
      if (page == 1) {
        _products.clear(); // Clear old data for the first page
        dung_tim_kiem = false; // Reset the flag to allow fetching
      }
    });

    if (dung_tim_kiem) {
      // Stop loading if no more data is available
      setState(() => _isFetchingProducts = false);
      return;
    }

    try {
      // Get shared preferences values
      final key_chi_nhanh = await Preferences.getKeyChiNhanh();
      final user_key_app = await Preferences.getUserKeyApp();

      // Prepare request data
      final Map<String, String> requestData = {
        'tu_khoa': _searchController.text.trim(),
        'page': page.toString(),
        'key_chi_nhanh': key_chi_nhanh ?? '',
        'user_key_app': user_key_app ?? '',
      };

      debugPrint('Request data: $requestData');

      // API call
      final response = await ApiService.callApi('list_sp_xuat', requestData);

      setState(() {
        _isFetchingProducts = false;

        if (response != null && response['list'] != null) {
          final List<Map<String, dynamic>> productList =
              List<Map<String, dynamic>>.from(response['list']);

          if (productList.isEmpty) {
            // No more data available
            dung_tim_kiem = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không còn dữ liệu để tải thêm.')),
            );
          } else {
            _products.addAll(productList);
            trang_tim_kiem = page + 1; // Increment the page number
          }
        } else {
          // No data or API error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy dữ liệu hoặc lỗi API')),
          );
        }
      });
    } catch (error) {
      setState(() => _isFetchingProducts = false);

      // Handle API error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      debugPrint('API error: $error');
    }
  }

  void _startBarcodeScanning(bool isEmployeeScan) async {
    final barcode = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Hủy",
      false,
      ScanMode.BARCODE,
    );
    debugPrint('Scanned barcode: $barcode');
    if (barcode != "-1") {
      setState(() => _isScanning = true);

      try {
        if (isEmployeeScan) {
          // Employee scanning logic
          final String? userKeyApp =
              await Preferences.get_user_info("user_key_app");
          final String? branchKey = await Preferences.getKeyChiNhanh();

          if (userKeyApp == null || branchKey == null) {
            throw Exception('Thông tin không đầy đủ.');
          }

          final header = {
            'key_chi_nhanh': branchKey,
            'user_key_app': userKeyApp,
            'ma_vach': barcode,
          };

          final response =
              await ApiService.callApi('check_ma_nhan_vien', header);

          if (response != null && response['loi'] == 0) {
            setState(() {
              employeeName = response['ho_ten'] ?? '';
              _selectedEmployee = employeeName;
              _selectedEmployeeId = response['id'];
              _selectedEmployeeIdInt = response['tv_id'];
            });
          } else {
            throw Exception(response?['txt_loi'] ?? 'Lỗi không xác định.');
          }
        } else {
          // Product scanning logic
          final String? userKeyApp =
              await Preferences.get_user_info("user_key_app");
          final String? branchKey = await Preferences.getKeyChiNhanh();

          if (userKeyApp == null || branchKey == null) {
            throw Exception('Thông tin không đầy đủ.');
          }

          final requestData = {
            'user_key_app': userKeyApp,
            'key_chi_nhanh': branchKey,
            'ma_code': '',
            'ma_vach': barcode,
          };

          final response =
              await ApiService.callApi('get_chip_code', requestData);
          if (response != null && response['loi'] == 0) {
            final productName = response['ten_sp'] ?? 'Sản phẩm';
            setState(() {
              _scanStatus = 'Đã quét thành công: $productName';
              _selectedProducts.add(response);
            });
            debugPrint("requestDataxvxv" + requestData.toString());
            debugPrint("responsevxvxv" + response.toString());
            await _playNotification(productName); // Play sound or read name
          } else {
            setState(() {
              _scanStatus = 'Không tìm thấy sản phẩm: $barcode';
            });
          }
        }
      } catch (error) {
        debugPrint('Error during scanning: $error');
      } finally {
        setState(() => _isScanning = false);
      }
    }
  }

  void removeGiftProducts(String mainProductCode) {
    setState(() {
      _selectedProducts.removeWhere((product) {
        return product['qua_tang'] != null &&
            product['qua_tang'] == mainProductCode;
      });
      _products.removeWhere((product) {
        return product['qua_tang'] != null &&
            product['qua_tang'] == mainProductCode;
      });
    });
  }

  void _onContinue() {
    if (_selectedCustomer == 'Chọn khách hàng') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng')),
      );
    } else {
      Navigator.pushNamed(context, '/invoice');
    }
  }

  void _logout() async {
    await Preferences.clearPreferences();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
