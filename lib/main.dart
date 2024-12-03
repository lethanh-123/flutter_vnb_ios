import 'package:flutter/material.dart';
import 'package:flutter_vnb_ios/cai_dat.dart';
import 'ton_kho.dart';
import 'login_screen.dart';
import 'banhang.dart'; // Ensure this import is included
import 'invoice_list.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'functions.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'them_khach_hang.dart';
import 'edit_khach_hang.dart';
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
      initialRoute: '/tonkho', // Start with the 'Bán hàng' screen
      routes: {
        '/tonkho': (context) =>
            const TonKhoScreen(), // Ensure this route is correct
        '/banhang': (context) => const BanHangScreen(),
        '/invoices': (context) => InvoiceListScreen(),
        '/cai_dat': (context) => SettingsScreen(),
        '/login': (context) => const LoginScreen(),
        '/them_khach_hang': (context) => AddCustomerScreen(),
         '/edit_khach_hang': (context) => EditCustomerScreen(),
      },
    );
  }
}
