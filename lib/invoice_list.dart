import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'preferences.dart';
import 'package:flutter_vnb_ios/chi_tiet_phieu.dart';
import 'package:flutter_vnb_ios/api_service.dart';

class InvoiceListScreen extends StatefulWidget {
  @override
  _InvoiceListScreenState createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Map<String, dynamic>> _invoices = [];
  String fromDate = "";
  String toDate = "";
  String filterPhone = "";

  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setTodayDate();
    _fetchInvoices();
  }

  void _setTodayDate() {
    final now = DateTime.now();
    setState(() {
      fromDate = "${now.day}/${now.month}/${now.year}";
      toDate = "${now.day}/${now.month}/${now.year}";
    });
  }

  Future<void> _fetchInvoices() async {
    try {
      String? keyChiNhanh = await Preferences.getKeyChiNhanh();
      String? userKeyApp = await Preferences.get_user_info("user_key_app");

      if (keyChiNhanh == null || userKeyApp == null) return;

      final response = await ApiService.callApi('xuat_hang_list', {
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
        'tu_ngay': fromDate,
        'den_ngay': toDate,
        'so_dt': filterPhone,
        'ma_phieu': '',
        'sdt_khach': '',
      });

      if (response != null && response['list'] != null) {
        final List<Map<String, dynamic>> invoiceList = [];
        final list = response['list'] as List<dynamic>;

        for (final obj in list) {
          final xuatHangList = obj['XuatHangList'] as List<dynamic>?;
          if (xuatHangList != null) {
            for (final invoiceData in xuatHangList) {
              final invoice = {
                'ma_phieu': invoiceData['ma_phieu'] ?? '',
                'ten': invoiceData['ten'] ?? 'Không rõ',
                'so_dt': invoiceData['so_dt'] ?? '',
                'ngay_xuat': invoiceData['ngay_xuat'] ?? '',
                'thanh_tien': invoiceData['thanh_tien'] ?? '0 ₫',
                'ten_nv': invoiceData['ten_nv'] ?? 'Không rõ',
              };
              invoiceList.add(invoice);
            }
          }
        }

        setState(() {
          _invoices = invoiceList;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được danh sách hóa đơn')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi API hóa đơn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu hóa đơn: $e')),
      );
    }
  }

  void _showDatePicker(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
        if (isFromDate) {
          fromDate = formattedDate;
        } else {
          toDate = formattedDate;
        }
      });
      _fetchInvoices();
    }
  }

  void _logout() async {
    await Preferences.clearPreferences();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildDrawer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 30),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hóa đơn'),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Date Picker Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nhập số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    filterPhone = value;
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDatePicker(context, true),
                        child: Text('Từ ngày: $fromDate'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDatePicker(context, false),
                        child: Text('Đến ngày: $toDate'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity, // Chiều rộng toàn màn hình
                  child: ElevatedButton(
                    onPressed: _fetchInvoices,
                    child: const Text('Tìm kiếm'),
                  ),
                ),
              ],
            ),
          ),
          // Invoice List Section
          Expanded(
            child: ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return Card(
                  child: ListTile(
                    title: Text(invoice['ten'] ?? "Không rõ"),
                    subtitle: Text("SĐT: ${invoice['so_dt']}"),
                    trailing: Text(invoice['thanh_tien'] ?? "0 ₫"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvoiceDetailScreen(maPhieu: invoice['ma_phieu']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
