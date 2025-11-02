import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/auth_service.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_services_screen.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_categories_screen.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_orders_screen.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_users_screen.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_vouchers_screen.dart';
import 'package:do_an_lap_trinh_android/features/admin/screens/statistics_screen.dart';
// THÊM IMPORT NÀY
import 'package:do_an_lap_trinh_android/features/admin/screens/manage_reviews_screen.dart'; 

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Chào mừng
              Text(
                'Xin chào, ${user?.displayName ?? 'Admin'}!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Đây là tổng quan hệ thống của bạn.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Phần Thống kê
              Row(
                children: [
                  Expanded(child: _buildStatCard(dbService.getUserCountStream(), 'Người dùng', Icons.people_outline, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(dbService.getOrderCountStream(), 'Đơn hàng', Icons.shopping_cart_outlined, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(dbService.getServiceCountStream(), 'Dịch vụ', Icons.design_services_outlined, Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Quản lý Chức năng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Lưới Chức năng
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: <Widget>[
                  _buildDashboardItem(
                    context,
                    icon: Icons.design_services_outlined,
                    label: 'Quản lý Dịch vụ',
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageServicesScreen())),
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.category_outlined,
                    label: 'Quản lý Danh mục',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.shopping_cart_outlined,
                    label: 'Quản lý Đơn hàng',
                    color: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageOrdersScreen())),
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.people_outline,
                    label: 'Quản lý Người dùng',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.local_offer_outlined,
                    label: 'Quản lý Mã giảm giá',
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageVouchersScreen())),
                  ),
                   _buildDashboardItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    label: 'Thống kê Doanh thu',
                    color: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                  ),
                  // --- THẺ MỚI CHO ĐÁNH GIÁ ---
                  _buildDashboardItem(
                    context,
                    icon: Icons.star_half_outlined,
                    label: 'Quản lý Đánh giá',
                    color: Colors.amber,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageReviewsScreen())),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con để xây dựng thẻ thống kê
  Widget _buildStatCard(Stream<int> stream, String label, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                return Text(
                  snapshot.data?.toString() ?? '0',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                );
              },
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Widget con để xây dựng thẻ chức năng trong GridView
  Widget _buildDashboardItem(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 40.0, color: color),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}