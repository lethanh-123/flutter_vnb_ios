import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/banhang.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const TonKhoApp());
}

class TonKhoApp extends StatelessWidget {
  const TonKhoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tồn Kho',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/tonkho',
      routes: {
        '/': (context) => const TonKhoScreen(),
        '/tonkho': (context) => const TonKhoScreen(),
        '/banhang': (context) => const BanHangScreen(),
      },
    );
  }
}

class TonKhoScreen extends StatefulWidget {
  const TonKhoScreen({super.key});

  @override
  State<TonKhoScreen> createState() => _TonKhoScreenState();
}

class _TonKhoScreenState extends State<TonKhoScreen> {
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final List<Map<String, String>> _productList = [];
  bool _isLoading = false;
  final List<Map<String, String>> _categoryList = [];
  final List<Map<String, String>> _branchList = [];
  String? _selectedCategory;
  String? _selectedBranch;
  int page = 1;
  @override
  void initState() {
    super.initState();
    fetchBranches();
    fetchCategories();
  }

  Future<void> fetchBranches() async {
    dynamic key_chi_nhanh = await Preferences.getKeyChiNhanh();
    dynamic cn_id = await Preferences.get_user_info("cn_id");

    dynamic ten_chi_nhanh = await Preferences.get_user_info("ten_cn");
    debugPrint(cn_id);
    try {
      final response = await ApiService.callApi('get_chi_nhanh_list', {
        'key_chi_nhanh': key_chi_nhanh,
      });
      debugPrint("response + $response");
      debugPrint("ten_chi_nhanh + $ten_chi_nhanh");
      if (response != null && response['list'] != null) {
        final List<Map<String, String>> branches =
            List<Map<String, String>>.from(
          response['list']
              .where((item) => item['id'].toString() != '1')
              .map((item) => {
                    'id': item['id'].toString(),
                    'name': item['ten'].toString(),
                  }),
        );

        setState(() {
          _branchList.clear();
          _branchList.add({"id": "0", "name": "Tất cả"});
          _branchList.add({"id": cn_id, "name": ten_chi_nhanh});
          _selectedBranch = cn_id;
          _branchController.text = ten_chi_nhanh;
          _branchList.addAll(branches);
          //SelectTextInController(_branchController,0, 5);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được danh mục')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi API danh mục: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy danh mục: $e')),
      );
    }
  }

  // Function to fetch branch data
  Future<void> fetchCategories() async {
    final key_chi_nhanh = await Preferences.getKeyChiNhanh();
    try {
      final response = await ApiService.callApi('danh_muc_list', {
        'key_chi_nhanh': key_chi_nhanh,
      });
      debugPrint("response + $response");
      if (response != null && response['list'] != null) {
        final List<Map<String, String>> categories =
            List<Map<String, String>>.from(
          response['list'].map((item) => {
                'id': item['id'].toString(),
                'name': item['ten'].toString(),
              }),
        );

        setState(() {
          _categoryList.clear();
          _categoryList.add({"id": "0", "name": "Tất cả"});
          _categoryList.addAll(categories);
          _selectedCategory = "0";
          _searchProducts();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được danh mục')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi API danh mục: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy danh mục: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tồn Kho'),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          ] else ...[
            _buildProductList(),
          ],
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
      padding: const EdgeInsets.all(0.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown chọn chi nhánh
            DropdownButtonFormField<String>(
              value: _selectedBranch,
              onChanged: (String? value) {
                setState(() {
                  _selectedBranch = value;
                });
              },
              items: _branchList.map((branch) {
                return DropdownMenuItem<String>(
                  value: branch['id'],
                  child: Text(branch['name'] ?? ''),
                );
              }).toList(),
              decoration: const InputDecoration(
                hintText: 'Chọn chi nhánh',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 6.0),

            // Dropdown chọn danh mục
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (String? value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              items: _categoryList.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(category['name'] ?? ''),
                );
              }).toList(),
              decoration: const InputDecoration(
                hintText: 'Chọn danh mục',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 6.0),

            // TextField tìm theo tên sản phẩm
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                hintText: 'Tên sản phẩm',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 6.0),

            // TextField tìm theo size
            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(
                hintText: 'Size',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 10.0),

            // Nút tìm kiếm
            SizedBox(
              height: 40.0,
              child: ElevatedButton(
                onPressed: _searchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: const Text(
                  'Tìm kiếm',
                  style: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Expanded(
      child: _productList.isEmpty
          ? const Center(child: Text('Không có sản phẩm nào'))
          : ListView.builder(
              itemCount: _productList.length,
              itemBuilder: (context, index) {
                final product = _productList[index];
                return ListTile(
                  leading: product['thumb'] != null
                      ? Image.network(
                          product['thumb'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(product['ten_sp'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product['size'] != null &&
                          product['size']!.isNotEmpty)
                        Text('Size: ${product['size']}'),
                      Text('Giá: ${product['gia']}'),
                      Text('Tồn kho: ${product['ton_kho']}'),
                    ],
                  ),
                  onTap: () =>
                      _showProductDetails(product), // Hiển thị chi tiết
                );
              },
            ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    final TextEditingController searchController = TextEditingController();

    // Initialize branchStocks
    List<Map<String, dynamic>> branchStocks = [];

    if (product['cn_list'] is String) {
      try {
        String jsonString = product['cn_list'];

        // Ensure all keys and string values are properly quoted
        jsonString = jsonString.replaceAllMapped(
          RegExp(r'(\w+):'), // Match unquoted keys
          (match) => '"${match.group(1)}":',
        );
        jsonString = jsonString.replaceAllMapped(
          RegExp(r'(:\s?)([^",{}\[\]]+)(?=\s*[,\}])'), // Match unquoted values
          (match) => '${match.group(1)}"${match.group(2)}"',
        );

        debugPrint('Chuỗi JSON sau khi chuẩn hóa: $jsonString');

        // Parse the corrected JSON string
        branchStocks = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      } catch (e) {
        debugPrint('Lỗi khi parse JSON: $e');
      }
    } else if (product['cn_list'] is Iterable) {
      branchStocks = List<Map<String, dynamic>>.from(product['cn_list']);
    } else {
      debugPrint('Dữ liệu cn_list không hợp lệ: ${product['cn_list']}');
    }

    // Filtered list initialization
    List<Map<String, dynamic>> filteredBranchStocks = List.from(branchStocks);

    // Display dialog
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chi tiết tồn kho'),
              content: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(
                      minWidth: 400), // Giới hạn chiều rộng
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm chi nhánh',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (query) {
                          setState(() {
                            filteredBranchStocks = branchStocks.where((branch) {
                              final branchName =
                                  (branch['ten'] ?? '').toLowerCase();
                              final stock =
                                  branch['ton_kho']?.toString() ?? '0';
                              return branchName.contains(query.toLowerCase()) ||
                                  stock.contains(query);
                            }).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      filteredBranchStocks.isEmpty
                          ? const Text('Không tìm thấy kết quả nào')
                          : Column(
                              children: filteredBranchStocks.map((branch) {
                                return _buildBranchDetails(branch);
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Cập nhật hàm để hiển thị chi tiết tồn kho
  Widget _buildBranchDetails(Map<String, dynamic> branch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch['ten'] ?? 'Không có tên chi nhánh',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Tồn kho: ${branch['ton_kho'] ?? 0}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchProducts() async {
    setState(() {
      _isLoading = true;
    });

    // Get branch key from shared preferences
    final key_chi_nhanh = await Preferences.getKeyChiNhanh();
    final user_key_app = await Preferences.getUserKeyApp();
    // Prepare request data
    final String searchName = _productNameController.text.trim();
    final String searchSize = _sizeController.text.trim();
    final String branch = _selectedBranch.toString();
    final String category = _selectedCategory.toString();

    // Request parameters
    final Map<String, String> requestData = {
      'tu_khoa': searchName.isEmpty
          ? ''
          : searchName, // Use empty string if null or empty
      'size': searchSize.isEmpty ? '' : searchSize,
      'chi_nhanh': branch.isEmpty ? '' : branch,
      'danh_muc': category.isEmpty ? '' : category,
      'page': page.toString(), // Specify the page number (1 in this case)
      'key_chi_nhanh': key_chi_nhanh ?? '', // Ensure non-null value
      'user_key_app': user_key_app ?? '',
    };
    debugPrint('debugPrintdasdf,$requestData');
    try {
      // Call the API using ApiService
      final response =
          await ApiService.callApi('get_ton_kho_chung', requestData);

      setState(() {
        _isLoading = false;

        if (response != null && response['list'] != null) {
          // Convert the dynamic list into List<Map<String, dynamic>>
          final List<Map<String, dynamic>> productList =
              List<Map<String, dynamic>>.from(response['list']);

          // Log the product list
          debugPrint('Danh sách sản phẩm tồn kho: $productList');
          final NumberFormat currencyFormat =
              NumberFormat.simpleCurrency(locale: 'vi_VN');
          // Clear old products and add new ones
          _productList.clear();
          _productList.addAll(productList.map((product) {
            return {
              'ten_sp': product['ten_sp']?.toString() ?? '',
              'size': product['size']?.toString() ?? '',
              'ton_kho': product['total']?.toString() ?? '',
              'thumb': product['thumb']?.toString() ?? '',
              'gia': product['gia'] != null
                  ? currencyFormat.format(
                      double.tryParse(product['gia']?.toString() ?? '0') ?? 0)
                  : '',
              'cn_list': product['cn_list']?.toString() ?? '',
            };
          }).toList());
          page++;
        } else {
          // Show message if no products found or API error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy dữ liệu hoặc lỗi API')),
          );
        }
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Show error dialog if API call fails
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
      debugPrint('Lỗi khi gọi API: $error');
    }
  }

  void _logout() async {
    await Preferences.clearPreferences();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
