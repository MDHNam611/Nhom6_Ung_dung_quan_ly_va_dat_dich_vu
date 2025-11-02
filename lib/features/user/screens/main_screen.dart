import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/user_home_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/favorites_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/cart_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/profile_screen.dart';
// THÊM IMPORT NÀY
import 'package:do_an_lap_trinh_android/features/user/screens/vouchers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Bắt đầu từ trang chủ

  // Cập nhật danh sách màn hình
  final List<Widget> _pages = [
    const UserHomeScreen(),
    const FavoritesScreen(),
    const VouchersScreen(), // Thêm màn hình Ưu đãi
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: Colors.blue,
        activeColor: Colors.white,
        color: Colors.white70,
        // Cập nhật danh sách tab
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Trang chủ'),
          TabItem(icon: Icons.favorite_border, title: 'Yêu thích'),
          TabItem(icon: Icons.local_offer_outlined, title: 'Ưu đãi'), // Thêm tab Ưu đãi
          TabItem(icon: Icons.shopping_cart_outlined, title: 'Giỏ hàng'),
          TabItem(icon: Icons.person_outline, title: 'Cá nhân'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}