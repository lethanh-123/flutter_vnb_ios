import 'package:flutter/material.dart';
import 'preferences.dart';
import 'printer_setup.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isPrinterEnabled = false;
  int notificationType = 0;
  int powerLevel = 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        centerTitle: true,
        backgroundColor: Colors.black, // Nền màu đen
        iconTheme: const IconThemeData(color: Colors.white), // Icon màu trắng
        titleTextStyle: const TextStyle(
            color: Colors.white, // Chữ màu trắng
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Âm báo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              DropdownButton<int>(
                value: notificationType,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Tiếng bíp')),
                  DropdownMenuItem(value: 1, child: Text('Giọng nói')),
                  DropdownMenuItem(value: 2, child: Text('Không âm thanh')),
                ],
                onChanged: (value) {
                  setState(() {
                    notificationType = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  showToast(
                      'Đã chọn: ${_getNotificationLabel(notificationType)}');
                },
                child: Text('Cập nhật'),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrinterSetupPage()),
              );
            },
            child: Text('Chọn Máy In'),
          ),
        ],
      ),
    );
  }

// Hàm bổ trợ để lấy nhãn của giá trị đã chọn
  String _getNotificationLabel(int type) {
    switch (type) {
      case 0:
        return 'Tiếng bíp';
      case 1:
        return 'Giọng nói';
      case 2:
        return 'Không âm thanh';
      default:
        return 'Không xác định';
    }
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() async {
    await Preferences.clearPreferences();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
