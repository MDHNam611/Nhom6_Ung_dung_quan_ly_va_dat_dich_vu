import 'package:flutter/material.dart';
import 'package:do_an_lap_trinh_android/features/user/widgets/order_list_tab.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng đã hoàn thành'), 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // Sử dụng OrderListTab và truyền vào trạng thái 'completed'
      body: const OrderListTab(status: 'completed'),
    );
  }
}