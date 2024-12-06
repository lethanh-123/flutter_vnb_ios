import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'preferences.dart';
import 'api_service.dart';

class CustomerListScreen extends StatefulWidget {
  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<dynamic> customerList = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  // Function to fetch customer data from API
  Future<void> fetchCustomers(String phone) async {
    setState(() {
      isLoading = true;
      customerList.clear();
    });

    String? keyChiNhanh = await Preferences.getKeyChiNhanh();
    String? userKeyApp = await Preferences.get_user_info("user_key_app");

    final response = await ApiService.callApi(
      'tim_khach_hang',
      {
        'key_chi_nhanh': keyChiNhanh!,
        'user_key_app': userKeyApp!,
        'so_dt': phone,
      },
    );
    setState(() {
      isLoading = false;

      if (response != null && response['list'] != null) {
        final List<Map<String, dynamic>> customersList =
            List<Map<String, dynamic>>.from(response['list']);

        if (customersList.isEmpty) {
          // No data available
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy khách hàng nào.')),
          );
        } else {
          // Add fetched data to customer list
          customerList.addAll(customersList.map((customer) {
            return {
              'id': customer['id']?.toString() ?? '',
              'ten': customer['ten']?.toString() ?? '',
              'so_dt': customer['so_dt']?.toString() ?? '',
              'email': customer['email']?.toString() ?? '',
              'dia_chi': customer['dia_chi']?.toString() ?? '',
              'ten_cn': customer['ten_cn']?.toString() ?? '',
            };
          }).toList());
        }
        debugPrint("respaaa: $customerList.toString()");
      } else {
        // No data or API error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy dữ liệu hoặc lỗi API')),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCustomers("");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách khách hàng"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back to previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Tìm khách hàng',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    // Navigate to Add Customer Screen
                    Navigator.pushNamed(context, '/them_khach_hang');
                  },
                ),
              ),
              onChanged: (text) {
                fetchCustomers(text);
              },
            ),
            SizedBox(height: 10),
            isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: customerList.length,
                      itemBuilder: (context, index) {
                        var customer = customerList[index];
                        return ListTile(
                          title: Text(customer['ten']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer['so_dt']),
                              if (customer['ten_cn'] != null)
                                Text('CN: ${customer['ten_cn']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              // Navigate to the edit customer screen
                              final updatedCustomer = await Navigator.pushNamed(
                                context,
                                '/edit_khach_hang',
                                arguments: {
                                  'id': customer['id'],
                                  'ten': customer['ten'],
                                  'so_dt': customer['so_dt'],
                                  'email': customer['email'],
                                  'dia_chi': customer['dia_chi'],
                                  'ten_cn': customer['ten_cn'],
                                },
                              );

                              // If a customer was updated, refresh the list
                              if (updatedCustomer != null) {
                                setState(() {
                                  // Update the specific customer in the list
                                  customerList[index] = updatedCustomer;
                                });
                              }
                            },
                          ),
                          onTap: () {
                            // Handle customer selection
                            Navigator.pop(context, {
                              'ten': customer['ten'],
                              'so_dt': customer['so_dt'],
                              'id': customer['id']
                            });
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
