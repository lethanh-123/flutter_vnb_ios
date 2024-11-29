
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

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfo = prefs.getString('user_info');
    if (userInfo != null) {
      return json.decode(userInfo) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('admin_id');
  }

  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
