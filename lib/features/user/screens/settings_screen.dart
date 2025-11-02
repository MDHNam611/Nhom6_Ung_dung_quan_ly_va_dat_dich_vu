import 'package:flutter/material.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/user_info_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/address_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined, color: Colors.blue),
                  title: const Text('Thông tin Người dùng'), // Lựa chọn 1
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Điều hướng đến màn hình thông tin người dùng
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInfoScreen()));
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
                  title: const Text('Cài đặt địa chỉ'), // Lựa chọn 2
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                     // Điều hướng đến màn hình quản lý địa chỉ
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen()));
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}