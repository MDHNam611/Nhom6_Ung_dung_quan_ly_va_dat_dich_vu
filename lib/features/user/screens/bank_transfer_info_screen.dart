import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:intl/intl.dart'; // Import để format số tiền

class BankTransferInfoScreen extends StatelessWidget {
  final List<ServiceModel> services;
  final String address;
  final DateTime selectedDateTime;
  final double finalPrice; // Nhận giá cuối cùng từ PaymentScreen

  const BankTransferInfoScreen({
    super.key,
    required this.services,
    required this.address,
    required this.selectedDateTime,
    required this.finalPrice, // Thêm vào constructor
  });

  // Hàm xử lý khi người dùng xác nhận đã chuyển khoản
  Future<void> _confirmPayment(BuildContext context) async {
    // Hiển thị loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final dbService = DatabaseService();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (context.mounted) Navigator.of(context).pop(); // Đóng loading dialog
      return;
    }

    try {
      // Xác định xem có voucher nào đã được áp dụng không (dựa vào việc finalPrice < originalTotal)
      double originalTotal = services.fold(0.0, (sum, item) => sum + item.price);
      double totalDiscount = 0.0;
      String? appliedVoucherCode;
      if (finalPrice < originalTotal) {
         totalDiscount = originalTotal - finalPrice;
      }

      for (int i = 0; i < services.length; i++) {
         final service = services[i];
        final newOrder = OrderModel(
          id: '',
          userId: currentUser.uid,
          userName: currentUser.displayName ?? currentUser.email ?? 'Không rõ',
          userEmail: currentUser.email ?? 'Không rõ',
          serviceId: service.id,
          serviceName: service.name,
          servicePrice: service.price, // Lưu giá gốc
          bookingDate: selectedDateTime.toIso8601String(),
          orderTimestamp: DateTime.now().millisecondsSinceEpoch,
          address: address,
          status: 'pending_payment', // Trạng thái chờ xác nhận thanh toán
          paymentMethod: 'bank_transfer',
          // Lưu mã voucher và tổng giảm giá vào đơn hàng đầu tiên (hoặc logic khác)
          voucherCode: i == 0 ? appliedVoucherCode : null,
          discountAmount: i == 0 ? totalDiscount : 0.0,
        );
        await dbService.placeOrder(newOrder);
      }
      
      // Xóa giỏ hàng nếu đặt từ giỏ hàng
      if (services.length > 1) {
        await dbService.clearCart();
      }

       if (!context.mounted) return;
      Navigator.of(context).pop(); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu. Vui lòng chờ Admin xác nhận thanh toán.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
       if (!context.mounted) return;
       Navigator.of(context).pop(); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tạo đơn hàng: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tạo nội dung chuyển khoản
    final String paymentContent = 'TTDV ${FirebaseAuth.instance.currentUser?.uid.substring(0, 6)}';
    // Format số tiền
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');
    // Tạo URL QR Code với số tiền cuối cùng
    final String qrCodeUrl = 'https://api.vietqr.io/image/970415-06112004-1x0x1.jpg?accountName=MAI DUC HOANG NAM&amount=${finalPrice.toInt()}&addInfo=$paymentContent';

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin Chuyển khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Vui lòng chuyển khoản chính xác theo thông tin dưới đây để đơn hàng được xác nhận nhanh nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            
            // Hiển thị mã QR
            Image.network(
              qrCodeUrl,
              height: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              },
              errorBuilder: (context, error, stackTrace) {
                print("Lỗi tải ảnh QR: $error");
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[400]), // Đổi icon
                        const SizedBox(height: 8),
                        const Text('Không thể tải mã QR', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // **QUAN TRỌNG:** Thay thế bằng thông tin tài khoản thật của bạn
                    _buildInfoRow(context, 'Ngân hàng:', 'Vietinbank'),
                    const Divider(),
                    _buildInfoRow(context, 'Số tài khoản:', '06112004'),
                    const Divider(),
                    _buildInfoRow(context, 'Chủ tài khoản:', 'MAI DUC HOANG NAM'),
                    const Divider(),
                    // Hiển thị số tiền cuối cùng (đã giảm giá)
                    _buildInfoRow(context, 'Số tiền:', '${currencyFormatter.format(finalPrice)} VNĐ'),
                    const Divider(),
                    _buildInfoRow(context, 'Nội dung:', paymentContent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            onPressed: () => _confirmPayment(context),
            child: const Text('Tôi đã chuyển khoản'),
          ),
        ),
      ),
    );
  }

  // Widget helper để hiển thị một dòng thông tin và nút copy
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép "$value"'), duration: const Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.copy, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}