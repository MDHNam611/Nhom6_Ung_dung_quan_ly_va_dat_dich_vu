import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/order_detail_screen.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/service_detail_screen.dart';


class OrderListTab extends StatelessWidget {
  final String status; 
  const OrderListTab({super.key, required this.status});


  Color _getStatusColor(String statusKey) {
    switch (statusKey) {
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled':
      case 'awaiting_cancellation':
        return Colors.red;
      case 'pending_payment':
      case 'pending':
      default:
        return Colors.orange;
    }
  }


  String _getStatusText(String statusKey) {
      switch (statusKey) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'completed': return 'Đã hoàn thành';
      case 'cancelled': return 'Đã huỷ';
      case 'awaiting_cancellation': return 'Chờ huỷ';
      case 'pending_payment': return 'Chờ thanh toán';
      default: return 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getUserOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             print("Lỗi Stream getUserOrdersStream: ${snapshot.error}");
             return Center(child: Text("Lỗi tải dữ liệu. Vui lòng kiểm tra lại Firebase Rules."));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState(_getStatusText(status)); 
          }

          final ordersMap = snapshot.data!.snapshot.value as Map;
          final allUserOrders = ordersMap.entries
              .map((e) {
                  if (e.value is Map) {
                     return OrderModel.fromMap(e.key, e.value);
                  }
                  return null;
              })
              .whereType<OrderModel>() 
              .toList();

          final orders = allUserOrders.where((order) {
            if (status == 'pending') {
              return order.status == 'pending' || order.status == 'pending_payment';
            }
            return order.status == status;
          }).toList();

          if (orders.isEmpty) {
            return _buildEmptyState(_getStatusText(status)); 
          }
          orders.sort((a, b) => b.orderTimestamp.compareTo(a.orderTimestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.parse(order.bookingDate));
              final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mã đơn: ...${order.id.substring(order.id.length - 6)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Chip(
                              label: Text(
                                _getStatusText(order.status), 
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: _getStatusColor(order.status),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          order.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Ngày hẹn:', formattedDate),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.sell_outlined, 'Tổng tiền:', '${currencyFormatter.format(order.servicePrice)} VNĐ'),
                        // Hiển thị thông tin giảm giá nếu có
                        if (order.discountAmount != null && order.discountAmount! > 0)
                          _buildInfoRow(Icons.local_offer_outlined, 'Giảm giá:', '- ${currencyFormatter.format(order.discountAmount)} VNĐ'),

                        if (status == 'completed') ...[
                          const Divider(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () async {
                                showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                                try {
                                  final serviceSnapshot = await FirebaseDatabase.instance
                                      .ref('services/${order.serviceId}')
                                      .get();
                                  Navigator.pop(context); 
                                  if (serviceSnapshot.exists && serviceSnapshot.value != null) {
                                    final service = ServiceModel.fromMap(order.serviceId, serviceSnapshot.value as Map);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)));
                                  } else {
                                     if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Không tìm thấy thông tin dịch vụ này nữa.')),
                                    );
                                  }
                                } catch (e) {
                                   if (!context.mounted) return;
                                   Navigator.pop(context); // Tắt loading
                                   ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi khi lấy thông tin dịch vụ: $e')),
                                    );
                                }
                              },
                              child: const Text('Đặt lại'),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget hiển thị khi không có đơn hàng
  Widget _buildEmptyState([String? specificStatusLabel]) {
     String message = "Không có đơn hàng nào.";
     if (specificStatusLabel != null) {
       message = "Không có đơn hàng nào trong mục '$specificStatusLabel'.";
     }
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        )
      );
  }

  // Widget helper để hiển thị thông tin theo hàng
  Widget _buildInfoRow(IconData icon, String label, String value) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}