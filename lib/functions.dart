import 'package:intl/intl.dart';

String formatCurrency(num amount, {String locale = 'vi_VN', String symbol = '₫'}) {
  final formatter = NumberFormat.currency(
    locale: locale, // Locale mặc định là 'vi_VN' (Việt Nam)
    symbol: symbol, // Ký hiệu tiền tệ mặc định là '₫'
    decimalDigits: 0, // Không hiển thị phần thập phân
  );
  return formatter.format(amount);
}