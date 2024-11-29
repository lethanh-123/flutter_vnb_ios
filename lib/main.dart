import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer(); // Open the drawer when the menu button is clicked
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Chi nhánh'),
              onTap: () {
                // Handle menu item click
                Navigator.pushNamed(
                    context, '/branch'); // Example of navigation
              },
              contentPadding: const EdgeInsets.only(
                  top: 20.0, left: 15.0), // Adds margin on top
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Bán hàng'),
              onTap: () {
                // Handle menu item click
                Navigator.pushNamed(context, '/sales'); // Example of navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Báo cáo'),
              onTap: () {
                // Handle menu item click
                Navigator.pushNamed(
                    context, '/reports'); // Example of navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử đơn hàng'),
              onTap: () {
                // Handle menu item click
                Navigator.pushNamed(
                    context, '/order-history'); // Example of navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                // Handle menu item click
                Navigator.pushNamed(
                    context, '/settings'); // Example of navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Đăng xuất'),
              onTap: () {
                // Handle logout
                Navigator.pushReplacementNamed(
                    context, '/'); // Redirect to login screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Phiên bản: 1.0'),
              onTap: () {
                // Handle version info
              },
            ),
          ],
        ),
      ),
      body: const Center(child: Text("Welcome to Home Screen!")),
    );
  }
}
