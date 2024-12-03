import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/ton_kho.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      initialRoute: '/tonkho', // Đổi initialRoute
      routes: {
        '/banhang': (context) =>
            const BanHangScreen(), // Đổi route này thành banhang.dart
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class BanHangScreen extends StatefulWidget {
  const BanHangScreen({super.key});

  @override
  State<BanHangScreen> createState() => _BanHangScreenState();
}

class _BanHangScreenState extends State<BanHangScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _products = [];
  final List<int> _selectedProducts = [];
  bool _isFetchingProducts = false;
  bool _isScanning = false;
  String _selectedCustomer = 'Chọn khách hàng';
  String _selectedEmployee = 'Chọn nhân viên bán hàng';
  String _scanStatus = 'Scan status';
  final int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  int trang_tim_kiem = 1;
  bool dung_tim_kiem = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onSearch();
    });
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
        title: const Text('Bán hàng'),
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
            onPressed: () => _onSearch(page: trang_tim_kiem),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _startBarcodeScanning,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeAndCustomerSection() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align all widgets to the start (left)
        children: [
          Align(
            alignment: Alignment.centerLeft, // Align button to the left
            child: ElevatedButton(
              onPressed: _selectEmployee,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(_selectedEmployee,
                  style: const TextStyle(
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(height: 3.0),
          Align(
            alignment: Alignment.centerLeft, // Align button to the left
            child: ElevatedButton(
              onPressed: _selectCustomer,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text(_selectedCustomer,
                  style: const TextStyle(
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

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

          final product = _products[index];
          final isSelected = _selectedProducts.contains(index);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedProducts.remove(index);
                } else {
                  _selectedProducts.add(index);
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
                              width: 50,
                              height: 50,
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
                        Text(
                          'Giá: ${formatCurrency(product['don_gia'])}',
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              product['so_luong'] =
                                  (product['so_luong'] ?? 1) - 1;
                              if (product['so_luong'] < 1) {
                                product['so_luong'] = 1;
                              }
                            });
                          },
                        ),
                        Text('${product['so_luong'] ?? 1}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              product['so_luong'] =
                                  (product['so_luong'] ?? 1) + 1;
                            });
                          },
                        ),
                      ],
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
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8.0), // Add padding if needed
      child: SizedBox(
        width: double.infinity, // Make the button take up the full width
        child: ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
          child: const Text('Tiếp tục',
              style: TextStyle(
                color: Colors.white,
              )),
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

  void _startBarcodeScanning() async {
    final barcode = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Hủy",
      false,
      ScanMode.BARCODE,
    );

    if (barcode != "-1") {
      setState(() => _isScanning = true);
      final response =
          await ApiService.callApi('get_chip_code', {'ma_code': barcode});
      setState(() {
        _isScanning = false;
        if (response != null && response['success'] == true) {
          _scanStatus = 'Đã quét thành công: ${response['product']['name']}';
        } else {
          _scanStatus = 'Không tìm thấy sản phẩm: $barcode';
        }
      });
    }
  }

  void _selectCustomer() {
    setState(() => _selectedCustomer = 'Khách hàng A');
  }

  void _selectEmployee() {
    setState(() => _selectedEmployee = 'Nhân viên A');
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
