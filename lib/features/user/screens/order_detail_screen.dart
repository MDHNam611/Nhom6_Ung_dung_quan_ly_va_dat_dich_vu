import 'package:flutter/material.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/review_model.dart'; // Import ReviewModel
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/features/user/widgets/add_review_sheet.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  // Hàm helper để lấy màu sắc trạng thái
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

  // Hàm helper để lấy tên trạng thái tiếng Việt
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

  void _openReviewSheet(BuildContext context, DatabaseService dbService, bool isEditing) async {
    ReviewModel? existingReview;
    
    if (isEditing) {
      // Hiển thị vòng quay loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator())
      );
      try {
        existingReview = await dbService.getReviewForOrder(order.serviceId, order.id);
      } catch (e) {
         print("Lỗi khi tải đánh giá cũ: $e");
      }
      Navigator.pop(context); // Đóng loading
    }
    
    if (!context.mounted) return;
    
    // Mở Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Quan trọng để không bị che bởi bàn phím
      shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddReviewSheet(
        order: order,
        existingReview: existingReview, // Truyền đánh giá cũ vào (sẽ là null nếu viết mới)
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';
    final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.parse(order.bookingDate));
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

    // Cập nhật điều kiện
    bool canCancel = order.status == 'pending' || order.status == 'confirmed';
    bool isAwaiting = order.status == 'awaiting_cancellation';
    // Đã hoàn thành VÀ chưa đánh giá
    bool canReview = order.status == 'completed' && !order.isReviewed;
    // Đã hoàn thành VÀ đã đánh giá
    bool canEditReview = order.status == 'completed' && order.isReviewed; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Thông tin chính
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    const Divider(height: 20),
                    Text(
                      order.serviceName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                     _buildInfoRow(Icons.calendar_today_outlined, 'Ngày hẹn:', formattedDate),
                     const SizedBox(height: 8),
                     _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ:', order.address),
                     const SizedBox(height: 8),
                     _buildInfoRow(Icons.payment_outlined, 'Thanh toán:', order.paymentMethod == 'cod' ? 'Tiền mặt' : 'Chuyển khoản'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thẻ Chi tiết Thanh toán
            Card(
               elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text('Chi tiết Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                      _buildPriceRow('Giá dịch vụ:', '${currencyFormatter.format(order.servicePrice)} VNĐ'),
                      if (order.discountAmount != null && order.discountAmount! > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Giảm giá (${order.voucherCode ?? ''}):', '- ${currencyFormatter.format(order.discountAmount)} VNĐ', color: Colors.green),
                      ],
                       const Divider(height: 20),
                       _buildPriceRow(
                        'Thành tiền:',
                        '${currencyFormatter.format(order.servicePrice - (order.discountAmount ?? 0))} VNĐ',
                        isTotal: true
                      ),
                   ],
                 ),
               ),
            ),
          ],
        ),
      ),
      // --- CẬP NHẬT BOTTOMNAVIGATIONBAR ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: 
              // 1. Hiển thị "Viết đánh giá"
              canReview
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Viết đánh giá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openReviewSheet(context, dbService, false), // isEditing: false
                )
              // 2. HIỂN THỊ NÚT "SỬA ĐÁNH GIÁ"
              : canEditReview
              ? ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Sửa đánh giá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300, // Màu khác
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openReviewSheet(context, dbService, true), // isEditing: true
                )
              // 3. Hiển thị nút "Hủy"
              : canCancel
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận Hủy'),
                            content: const Text('Bạn có chắc muốn gửi yêu cầu hủy dịch vụ này không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Không')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  dbService.requestOrderCancellation(order.id, order.status);
                                  Navigator.of(ctx).pop(); 
                                  Navigator.of(context).pop();
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã gửi yêu cầu hủy. Vui lòng chờ Admin duyệt.')),
                                  );
                                },
                                child: const Text('Gửi yêu cầu'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Gửi yêu cầu Hủy dịch vụ'),
                    )
                  // 4. Hiển thị text "Chờ hủy"
                  : isAwaiting
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'Yêu cầu hủy của bạn đã được gửi và đang chờ Admin duyệt.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox.shrink(), // Không hiển thị gì cả
        ),
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
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper cho các dòng trong phần Chi tiết Thanh toán
  Widget _buildPriceRow(String label, String value, {Color? color, bool isTotal = false}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color ?? (isTotal ? Colors.black : Colors.grey), fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(color: color ?? (isTotal ? Colors.blue : Colors.black), fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14),
          ),
        ],
      ),
    );
  }
}