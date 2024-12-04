import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Preferences {
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_info', json.encode(userInfo));
    await prefs.setInt('admin_id', userInfo['tv_id']);
    await prefs.setString('user_key_app', userInfo['user_key_app']);
    await prefs.setString('key_chi_nhanh', userInfo['key_chi_nhanh']);
  }

  static Future<void> saveAppInfo(Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();

   
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfo = prefs.getString('user_info');
    if (userInfo != null) {
      return json.decode(userInfo) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_info');
  }

  static Future<String?> getKhach() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('khach_info');
  }

  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('admin_id');
  }

  static Future<String?> getMayin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('connected_printer_address');
  }

  static Future<String?> getKeyChiNhanh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('key_chi_nhanh');
  }

  static Future<String?> getUserKeyApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_key_app');
  }

  static Future<String?> get_user_info(String key) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic user_info = prefs.getString('user_info');
    dynamic user_info_arr = json.decode(user_info);
    return user_info_arr[key].toString();
  }

  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
