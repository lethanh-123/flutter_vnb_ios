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
import 'package:logging/logging.dart';
import 'edit_khach_hang.dart';

final Logger logger = Logger('MyApp'); //  Khai báo logger

void configureLogging() {
  Logger.root.level = Level.ALL; // Hiển thị tất cả các cấp độ log

  logger.onRecord.listen((record) {
    final logMessage =
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}';

    //  Chia log thành các đoạn nhỏ hơn (3000 ký tự)
    const chunkSize = 3000; // Gấp 3 lần kích thước hiện tại
    for (int i = 0; i < logMessage.length; i += chunkSize) {
      debugPrint(
        logMessage.substring(
            i,
            i + chunkSize > logMessage.length
                ? logMessage.length
                : i + chunkSize),
        wrapWidth: 3000, //  Tăng wrapWidth để log không bị cắt
      );
    }
  });
}

void main() {
  configureLogging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    logger.info('Ứng dụng MyApp đã khởi chạy');
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
