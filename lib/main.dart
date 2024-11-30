import 'package:flutter/material.dart';
import 'ton_kho.dart';
import 'login_screen.dart';
import 'banhang.dart'; // Ensure this import is included
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
      initialRoute: '/tonkho', // Start with the 'Bán hàng' screen
      routes: {
        '/tonkho': (context) =>
            const TonKhoScreen(), // Ensure this route is correct
        '/banhang': (context) => const BanHangScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
