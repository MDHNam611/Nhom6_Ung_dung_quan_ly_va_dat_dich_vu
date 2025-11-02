import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart'; // Cần để lấy SĐT
import 'package:do_an_lap_trinh_android/features/user/screens/edit_name_screen.dart'; // Sẽ tạo
import 'package:do_an_lap_trinh_android/features/user/screens/edit_phone_screen.dart'; // Sẽ tạo
import 'package:do_an_lap_trinh_android/features/user/screens/change_password_screen.dart'; // Sẽ tạo

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final dbService = DatabaseService();
  String? phoneNumber; // Biến để lưu SĐT lấy từ DB

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
     if (user != null) {
       try {
         final phoneSnapshot = await dbService.getUserProfileField(user!.uid, 'phoneNumber');
         if (phoneSnapshot.exists && phoneSnapshot.value != null && mounted) {
           setState(() {
             phoneNumber = phoneSnapshot.value.toString();
           });
         }
       } catch (e) {
         print("Lỗi khi tải số điện thoại: $e");
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ Auth (ví dụ sau khi đổi tên)
    final updatedUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin Người dùng'),
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
                _buildInfoTile(
                  icon: Icons.person_outline,
                  label: 'Tên hiển thị',
                  value: updatedUser?.displayName ?? 'Chưa cập nhật',
                  onTap: () async {
                    // Chờ kết quả trả về từ màn hình sửa tên để cập nhật lại UI
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditNameScreen()));
                    setState(() {}); // Build lại để hiển thị tên mới
                  }
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: updatedUser?.email ?? 'Không có',
                  // Không cho sửa email
                ),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  value: phoneNumber ?? 'Chưa cập nhật',
                  onTap: () async {
                    // Chờ kết quả trả về từ màn hình sửa SĐT
                    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => EditPhoneScreen(currentPhoneNumber: phoneNumber)));
                    // Cập nhật lại UI nếu có SĐT mới
                    if (result != null && mounted) {
                      setState(() { phoneNumber = result; });
                    }
                  }
                ),
                _buildInfoTile(
                  icon: Icons.lock_outline,
                  label: 'Đổi mật khẩu',
                  value: '********', // Hiển thị ẩn
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                  }
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget helper cho từng dòng thông tin
  Widget _buildInfoTile({required IconData icon, required String label, required String value, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(label),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        ),
         const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}