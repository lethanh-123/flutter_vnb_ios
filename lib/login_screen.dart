import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vnb_ios/api_service.dart';
import 'preferences.dart'; // Import the Preferences class

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode(); // Add this line
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
      // Use Preferences.saveUserInfo instead of SharedPreferences.saveUserInfo
      await Preferences.saveUserInfo(response);
      navigateToHomeScreen();
    } else {
      showErrorDialog("Thông tin đăng nhập không đúng");
      passwordController.clear();
      passwordFocusNode.requestFocus(); // Use FocusNode to request focus
    }
  }

  void navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    passwordFocusNode.dispose(); // Don't forget to dispose FocusNode
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  focusNode: passwordFocusNode, // Set the focus node here
                  decoration: InputDecoration(
                    hintText: "Mật khẩu",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                const Text(
                  "Phần mềm kiểm hàng - phiên bản: 1.0",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
