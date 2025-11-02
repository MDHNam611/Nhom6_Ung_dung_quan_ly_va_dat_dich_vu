import 'package:flutter/material.dart';
import 'package:do_an_lap_trinh_android/features/user/widgets/order_list_tab.dart';

class FilteredOrdersScreen extends StatelessWidget {
  final String status;
  final String statusLabel;

  // Constructor để nhận trạng thái và tiêu đề từ ProfileScreen
  const FilteredOrdersScreen({
    super.key, 
    required this.status, 
    required this.statusLabel
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Hiển thị tiêu đề tương ứng (ví dụ: "Chờ xác nhận")
        title: Text(statusLabel)
      ),
      // Tái sử dụng widget OrderListTab đã tạo trước đó để hiển thị danh sách
      // đơn hàng đã được lọc theo trạng thái
      body: OrderListTab(status: status),
    );
  }
}