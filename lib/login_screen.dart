import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController =
      TextEditingController(text: "nv_quan10");
  final TextEditingController passwordController =
      TextEditingController(text: "123456@@");
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeUsername();
  }

  Future<void> _initializeUsername() async {
    // Lấy tên đăng nhập đã lưu từ Preferences và hiển thị
    final savedUsername = await Preferences.getUser();
    if (savedUsername != null) {
      final userInfo = json.decode(savedUsername);
      setState(() {
        usernameController.text = userInfo['user'] ?? '';
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng nhập không thành công"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      showErrorDialog("Thiếu tên đăng nhập");
      return;
    }
    if (password.isEmpty) {
      showErrorDialog("Thiếu mật khẩu");
      return;
    }

    final response = await ApiService.callApi('dang_nhap', {
      'user': username,
      'pass': password,
    });

    if (response != null &&
        response['tv_id'] != null &&
        response['tv_id'] > 0) {
      await Preferences.saveUserInfo(response);

      // Lưu tên đăng nhập
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('saved_username', username);

      navigateToHomeScreen();
    } else {
      showErrorDialog("Thông tin đăng nhập không đúng");
      passwordController.clear();
      passwordFocusNode.requestFocus();
    }
  }

  void navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/tonkho');
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon_vnb.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 32),
                const Text(
                  "Đăng Nhập Để Sử Dụng",
                  style: TextStyle(fontSize: 24, color: Colors.deepOrange),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: "Tên đăng nhập",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => passwordFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  focusNode: passwordFocusNode,
                  decoration: InputDecoration(
                    hintText: "Mật khẩu",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      "Đăng nhập",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _getAppVersion(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? "Đang tải thông tin phiên bản...",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getAppVersion() async {
    // Lấy thông tin phiên bản từ Android
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version; // This is the app version

    return "Phần mềm kiểm hàng - phiên bản: $version";
  }
}
