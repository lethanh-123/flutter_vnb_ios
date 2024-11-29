import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const MainActivity(),
      },
    );
  }
}

class MainActivity extends StatefulWidget {
  const MainActivity({super.key});

  @override
  State<MainActivity> createState() => _MainActivityState();
}

class _MainActivityState extends State<MainActivity> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _products = [];
  bool _isFetchingProducts = false;
  bool _isScanning = false;
  String _selectedCustomer = 'Chọn khách hàng';
  String _selectedEmployee = 'Chọn nhân viên bán hàng';
  String _scanStatus = 'Scan status';
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter App'),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildEmployeeAndCustomerSection(),
          Visibility(
            visible: _scanStatus != '',
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _scanStatus,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),
          _buildProductList(),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Chi nhánh'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Bán hàng'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Báo cáo'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài đặt'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Đăng xuất'),
            onTap: _logout,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child:
                Text('Phiên bản: 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
            onPressed: _onSearch,
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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _selectCustomer,
            child: Text(_selectedCustomer),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          ElevatedButton(
            onPressed: _selectEmployee,
            child: Text(_selectedEmployee),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Expanded(
      child: _isFetchingProducts
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text('Giá: ${product['price']} VNĐ'),
                  onTap: () {},
                );
              },
            ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _onContinue,
      child: const Text('Tiếp tục'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
    );
  }

  void _onSearch() async {
    try {
      setState(() => _isFetchingProducts = true);

      final response = await ApiService.callApi('list_sp_xuat', {
        'tu_khoa': _searchController.text,
        'page': _currentPage,
      });

      setState(() {
        _isFetchingProducts = false;

        if (response != null && response['list'] != null) {
          // Ép kiểu danh sách động thành List<Map<String, dynamic>>

          final List<Map<String, dynamic>> productList =
              List<Map<String, dynamic>>.from(response['list']);
          // Log danh sách productList
          _products.addAll(productList);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy dữ liệu hoặc lỗi API')),
          );
        }
      });
    } catch (error) {
      setState(() => _isFetchingProducts = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm kiếm: $error')),
      );
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
    Navigator.pushReplacementNamed(context, '/');
  }
}
