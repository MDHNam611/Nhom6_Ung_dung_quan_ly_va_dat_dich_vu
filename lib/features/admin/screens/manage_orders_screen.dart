import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
// KHÔNG CẦN import order_status.dart

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    // Bản đồ để "dịch" trạng thái tiếng Anh (key) sang tiếng Việt (value) cho hiển thị
    final Map<String, String> statusDisplayNames = {
      'pending': 'Chờ xác nhận',
      'confirmed': 'Đã xác nhận',
      'completed': 'Đã hoàn thành',
      'cancelled': 'Đã huỷ',
      'awaiting_cancellation': 'Chờ huỷ',
      'pending_payment': 'Chờ thanh toán',
    };

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Chưa có đơn hàng nào."));
          }
          final ordersMap = snapshot.data!.snapshot.value as Map;
          final orders = ordersMap.entries.map((e) {
            if (e.value is Map) {
              return OrderModel.fromMap(e.key, e.value);
            }
            return null;
          }).whereType<OrderModel>().toList();

          orders.sort((a, b) => b.orderTimestamp.compareTo(a.orderTimestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.parse(order.bookingDate));
              final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

              // Giao diện cho đơn hàng chờ hủy (so sánh bằng key tiếng Anh)
              if (order.status == 'awaiting_cancellation') {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Yêu cầu hủy từ: ${order.userName}',
                          style: TextStyle(color: Colors.red.shade700, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: const Text('Từ chối'),
                              onPressed: () {
                                // Gửi trạng thái tiếng Anh lên DB
                                dbService.denyCancellation(order.id, order.originalStatus ?? 'pending');
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Duyệt Hủy'),
                              onPressed: () {
                                // Gửi trạng thái tiếng Anh lên DB
                                dbService.approveCancellation(order.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                );
              }

              // Giao diện cho đơn hàng chờ thanh toán (so sánh bằng key tiếng Anh)
              if (order.status == 'pending_payment') {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade300, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Chờ xác nhận thanh toán từ: ${order.userName}',
                          style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: const Text('Thất bại', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                // Gửi trạng thái tiếng Anh lên DB
                                dbService.updateOrderStatus(order.id, 'cancelled');
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Xác nhận'),
                              onPressed: () {
                                // Gửi trạng thái tiếng Anh lên DB
                                dbService.updateOrderStatus(order.id, 'confirmed');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                );
              }

              // Giao diện thẻ đơn hàng thông thường
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.serviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(height: 16),
                      _buildInfoRow(Icons.person_outline, 'Khách hàng', order.userName),
                      _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', order.address),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Thời gian', formattedDate),
                      _buildInfoRow(Icons.payment_outlined, 'Thanh toán', order.paymentMethod == 'cod' ? 'Tiền mặt' : 'Chuyển khoản'),
                      if(order.discountAmount != null && order.discountAmount! > 0)
                         _buildInfoRow(Icons.local_offer_outlined, 'Giảm giá', '- ${currencyFormatter.format(order.discountAmount)} VNĐ (${order.voucherCode ?? ''})'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
                          // ================== SỬA LỖI Ở ĐÂY ==================
                          DropdownButton<String>(
                            // Value là key tiếng Anh từ order.status (ví dụ: 'pending')
                            value: order.status,
                            // Tạo các mục Dropdown từ keys tiếng Anh của bản đồ
                            items: statusDisplayNames.keys.map((String statusKey) {
                              return DropdownMenuItem<String>(
                                value: statusKey, // Giá trị của mục là key tiếng Anh
                                child: Text(statusDisplayNames[statusKey]!), // Hiển thị tên tiếng Việt
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null && newStatus != order.status) {
                                // Gửi key tiếng Anh lên DB khi admin chọn
                                dbService.updateOrderStatus(order.id, newStatus);
                              }
                            },
                            underline: const SizedBox(),
                            isDense: true,
                          ),
                          // ================================================
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}