import 'package:flutter/material.dart';

class AddCustomerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm khách hàng"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back to previous screen
          },
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Logic to add customer here
          },
          child: Text("Thêm khách hàng mới"),
        ),
      ),
    );
  }
}
