import 'package:flutter/material.dart';
import 'api_service.dart';
import 'preferences.dart';

class AddCustomerScreen extends StatefulWidget {
  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Hàm giả lập gọi API
  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String name = _nameController.text.trim();
      final String phone = _phoneController.text.trim();
      final String address = _addressController.text.trim();

      String? keyChiNhanh = await Preferences.getKeyChiNhanh();
      String? userKeyApp = await Preferences.get_user_info("user_key_app");
      String? str_user_info = await Preferences.getUser();
      // Dữ liệu gửi đi
      final Map<String, dynamic> requestData = {
        'ten': name,
        'so_dt': phone,
        'dia_chi': address,
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
      };

      try {
        final response =
            await ApiService.callApi('them_khach_hang', requestData);

        if (response != null && response['loi'] > 0) {
          // Thông báo lỗi từ API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['txt_loi'] ?? 'Unknown error')),
          );
        } else {
          // Thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Khách hàng đã được thêm thành công!')),
          );
          Navigator.pop(context);
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm khách hàng"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        // Wrap the entire body in a scrollable view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tên khách hàng*",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Tên khách hàng",
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập tên khách hàng";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Số điện thoại*",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: "Số điện thoại",
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập số điện thoại";
                    } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return "Số điện thoại không hợp lệ (10 chữ số)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Địa chỉ",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "Địa chỉ",
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.streetAddress,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    "Lưu khách hàng",
                    style: TextStyle(
                      color: Colors.white, // Màu chữ trắng
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    "Quay lại",
                    style: TextStyle(
                      color: Colors.white, // Màu chữ trắng
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
