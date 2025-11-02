import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';

// Enum để quản lý khoảng thời gian
enum TimePeriod { week, month, year }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final dbService = DatabaseService();
  TimePeriod _selectedPeriod = TimePeriod.month; // Mặc định hiển thị theo tháng
  final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  // Hàm lọc đơn hàng theo thời gian
  List<OrderModel> _filterOrdersByPeriod(List<OrderModel> allOrders, TimePeriod period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case TimePeriod.week:
        // Lấy ngày đầu tuần (Thứ 2)
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day); // Bỏ giờ phút giây
        break;
      case TimePeriod.month:
        startDate = DateTime(now.year, now.month, 1); // Ngày đầu tháng
        break;
      case TimePeriod.year:
        startDate = DateTime(now.year, 1, 1); // Ngày đầu năm
        break;
    }

    final startTimestamp = startDate.millisecondsSinceEpoch;

    return allOrders.where((order) {
      // Chỉ tính các đơn đã hoàn thành ('completed')
      return order.status == 'completed' && order.orderTimestamp >= startTimestamp;
    }).toList();
  }

  // Hàm tính tổng doanh thu
  double _calculateRevenue(List<OrderModel> orders) {
    double total = 0.0;
    for (var order in orders) {
      // Lấy giá dịch vụ trừ đi giảm giá (nếu có)
      total += order.servicePrice - (order.discountAmount ?? 0.0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Doanh thu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Phần chọn khoảng thời gian
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SegmentedButton<TimePeriod>(
              segments: const <ButtonSegment<TimePeriod>>[
                ButtonSegment<TimePeriod>(value: TimePeriod.week, label: Text('Tuần này')),
                ButtonSegment<TimePeriod>(value: TimePeriod.month, label: Text('Tháng này')),
                ButtonSegment<TimePeriod>(value: TimePeriod.year, label: Text('Năm nay')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<TimePeriod> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                 backgroundColor: Colors.white,
                 foregroundColor: Colors.grey,
                 selectedForegroundColor: Colors.white,
                 selectedBackgroundColor: Colors.blue,
              ),
            ),
          ),

          // Phần hiển thị thống kê
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: dbService.getAllOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Chưa có dữ liệu đơn hàng."));
                }

                final ordersMap = snapshot.data!.snapshot.value as Map;
                final allOrders = ordersMap.entries.map((e) {
                  if (e.value is Map) return OrderModel.fromMap(e.key, e.value);
                  return null;
                }).whereType<OrderModel>().toList();

                // Lọc đơn hàng theo trạng thái 'completed' và thời gian đã chọn
                final filteredCompletedOrders = _filterOrdersByPeriod(allOrders, _selectedPeriod);
                // Tính toán doanh thu
                final totalRevenue = _calculateRevenue(filteredCompletedOrders);
                final numberOfCompletedOrders = filteredCompletedOrders.length;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildRevenueCard(
                        title: 'Tổng Doanh thu (${_getPeriodLabel()})',
                        amount: totalRevenue,
                        orderCount: numberOfCompletedOrders,
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                      // Bạn có thể thêm các thẻ thống kê khác ở đây (ví dụ: đơn hàng mới, khách hàng mới...)
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Lấy nhãn cho khoảng thời gian
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case TimePeriod.week: return 'Tuần này';
      case TimePeriod.month: return 'Tháng này';
      case TimePeriod.year: return 'Năm nay';
    }
  }

  // Widget con để hiển thị thẻ doanh thu
  Widget _buildRevenueCard({required String title, required double amount, required int orderCount, required IconData icon, required Color color}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${currencyFormatter.format(amount)} VNĐ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 8),
             Center(
              child: Text(
                'Từ $orderCount đơn hàng đã hoàn thành',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}