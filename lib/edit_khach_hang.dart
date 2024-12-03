import 'package:flutter/material.dart';
import 'api_service.dart';
import 'preferences.dart';

class EditCustomerScreen extends StatefulWidget {
  @override
  _EditCustomerScreenState createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController idController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    idController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Retrieve customer data safely after context is available
    final Map<String, dynamic> customer =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    nameController.text = customer['ten'];
    idController.text = customer['id'];
    phoneController.text = customer['so_dt']; // Display phone number here
    addressController.text = customer['dia_chi'];
  }

  Future<void> _saveEditCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String name = nameController.text.trim();
      final String id = idController.text.trim();
      final String phone = phoneController.text.trim();
      final String address = addressController.text.trim();

      String? keyChiNhanh = await Preferences.getKeyChiNhanh();
      String? userKeyApp = await Preferences.get_user_info("user_key_app");

      final Map<String, dynamic> requestData = {
        'ten': name,
        'id': id,
        'dia_chi': address,
        'key_chi_nhanh': keyChiNhanh,
        'user_key_app': userKeyApp,
      };
      debugPrint("requestDatavxxvxv $requestData");
      try {
        final response =
            await ApiService.callApi('sua_khach_hang', requestData);

        if (response != null && response['loi'] > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['txt_loi'] ?? 'Unknown error')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Khách hàng đã được sửa thành công!')),
          );
          Navigator.pop(context, {
            'id': id,
            'ten': name,
            'so_dt': phone,
            'dia_chi': address,
          });
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
        title: Text('Chỉnh sửa khách hàng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Tên khách hàng'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Số điện thoại'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Địa chỉ'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEditCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
