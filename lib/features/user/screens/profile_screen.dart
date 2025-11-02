import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_lap_trinh_android/core/auth_service.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/cart_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/filtered_orders_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/order_history_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/settings_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/help_center_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, 
              alignment: Alignment.center,
              children: [
                _buildProfileHeader(context),
                Positioned(
                  top: 100,
                  child: _buildUserInfoCard(user),
                ),
              ],
            ),
            const SizedBox(height: 80), 
            _buildMyOrdersSection(context),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  // Widget con cho header màu xanh
  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: IconButton(
            tooltip: 'Giỏ hàng',
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
      ),
    );
  }

  // Widget con cho thẻ thông tin người dùng
  Widget _buildUserInfoCard(User? user) {
    final String? photoUrl = user?.photoURL;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(photoUrl),
              )
            else
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            const SizedBox(height: 12),
            Text(
              user?.displayName ?? user?.email ?? 'Người dùng',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Logic chỉnh sửa hồ sơ
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget con cho khu vực quản lý đơn hàng
  Widget _buildMyOrdersSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Đơn của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                    child: const Text('Xem lịch sử >'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusIcon(context, icon: Icons.pending_actions_outlined, label: 'Chờ xác nhận', status: 'pending'),
                  _buildStatusIcon(context, icon: Icons.local_shipping_outlined, label: 'Đã xác nhận', status: 'confirmed'),
                  _buildStatusIcon(context, icon: Icons.task_alt_outlined, label: 'Đã hoàn thành', status: 'completed'),
                  _buildStatusIcon(context, icon: Icons.cancel_outlined, label: 'Đã huỷ', status: 'cancelled'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con cho các icon trạng thái
  Widget _buildStatusIcon(BuildContext context, {required IconData icon, required String label, required String status}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredOrdersScreen(status: status, statusLabel: label))),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Widget con cho phần cài đặt và đăng xuất
  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.blue),
              title: const Text('Cài đặt tài khoản'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: const Text('Trung tâm trợ giúp'),
              trailing: const Icon(Icons.chevron_right),
              // ================== CẬP NHẬT Ở ĐÂY ==================
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
              },
              // ================================================
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          AuthService().signOut();
                        },
                        child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}