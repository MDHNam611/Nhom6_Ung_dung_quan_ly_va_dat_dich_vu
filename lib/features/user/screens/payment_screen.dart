import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/order_model.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/voucher_model.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/bank_transfer_info_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<ServiceModel> services;
  final String address;
  final DateTime selectedDateTime;

  const PaymentScreen({
    super.key,
    required this.services,
    required this.address,
    required this.selectedDateTime,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _voucherController = TextEditingController();
  final dbService = DatabaseService();
  String _selectedMethod = 'cod';
  bool _isLoading = false;
  bool _isCheckingVoucher = false;

  VoucherModel? _appliedVoucher; 
  double _discountAmount = 0.0;
  double _originalTotalPrice = 0.0;
  double _finalPrice = 0.0;
  String? _voucherStatusMessage; 

  @override
  void initState() {
    super.initState();
    _originalTotalPrice = widget.services.fold(0.0, (sum, item) => sum + item.price);
    _finalPrice = _originalTotalPrice; 
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  // --- Mở BottomSheet để chọn Voucher ---
  void _showVoucherSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn mã giảm giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<DatabaseEvent>(
                  stream: dbService.getUserVouchersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('Bạn không có voucher nào khả dụng.'));
                    }
                    final vouchersMap = snapshot.data!.snapshot.value as Map;
                    final vouchers = vouchersMap.entries.map((e) {
                      return VoucherModel.fromMap(e.key, e.value);
                    }).toList();

                    final validVouchers = vouchers.where((v) {
                      final expiryDate = DateTime.fromMillisecondsSinceEpoch(v.expiryAt);
                      return !v.isUsed && DateTime.now().isBefore(expiryDate);
                    }).toList();

                    if (validVouchers.isEmpty) {
                      return const Center(child: Text('Bạn không có voucher nào khả dụng.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: validVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = validVouchers[index];
                        return ListTile(
                          leading: const Icon(Icons.local_offer_outlined, color: Colors.orange),
                          title: Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Giảm ${voucher.discountPercentage}%, HSD: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(voucher.expiryAt))}'),
                          onTap: () {
                            _applyVoucher(voucher);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Kiểm tra và áp dụng mã nhập tay ---
  Future<void> _validateAndApplyManualVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isCheckingVoucher = true;
      _voucherStatusMessage = null;
    });

    try {
      final voucher = await dbService.validateAndGetVoucher(code);
      _applyVoucher(voucher);
    } catch (e) {
      setState(() {
        _appliedVoucher = null;
        _discountAmount = 0.0;
        _finalPrice = _originalTotalPrice;
        _voucherStatusMessage = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_voucherStatusMessage!), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isCheckingVoucher = false; });
      }
    }
  }

  // Hàm áp dụng voucher
  void _applyVoucher(VoucherModel voucher) {
    final discount = (_originalTotalPrice * voucher.discountPercentage) / 100;
    setState(() {
      _appliedVoucher = voucher;
      _discountAmount = discount;
      _finalPrice = _originalTotalPrice - _discountAmount;
      _voucherStatusMessage = '✓ Áp dụng thành công!';
      _voucherController.text = voucher.code;
    });
  }

  // Hàm gỡ bỏ voucher
  void _removeVoucher() {
     setState(() {
        _appliedVoucher = null;
        _discountAmount = 0.0;
        _finalPrice = _originalTotalPrice;
        _voucherController.clear();
        _voucherStatusMessage = null;
     });
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Đã gỡ mã giảm giá')),
     );
  }

  // Hàm hoàn tất đặt lịch
  Future<void> _completeBooking() async {
    // Luồng giả lập thanh toán thẻ
    if (_selectedMethod == 'card') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chức năng thanh toán bằng thẻ sẽ sớm được ra mắt!'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Luồng chuyển khoản ngân hàng - TRUYỀN GIÁ CUỐI CÙNG (_finalPrice)
    if (_selectedMethod == 'bank_transfer') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BankTransferInfoScreen(
            services: widget.services,
            address: widget.address,
            selectedDateTime: widget.selectedDateTime,
            finalPrice: _finalPrice, // Truyền giá đã giảm
          ),
        ),
      );
      return;
    }

    // Luồng thanh toán COD
    setState(() { _isLoading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      String? usedVoucherId;

      for (int i = 0; i < widget.services.length; i++) {
        final service = widget.services[i];
        double itemDiscount = 0.0;
        String? itemVoucherCode;

        if (_appliedVoucher != null && i == 0) {
           itemDiscount = _discountAmount;
           itemVoucherCode = _appliedVoucher!.code;
           usedVoucherId = _appliedVoucher!.id;
        }

        final newOrder = OrderModel(
          id: '',
          userId: currentUser.uid,
          userName: currentUser.displayName ?? currentUser.email ?? 'Không rõ',
          userEmail: currentUser.email ?? 'Không rõ',
          serviceId: service.id,
          serviceName: service.name,
          servicePrice: service.price,
          bookingDate: widget.selectedDateTime.toIso8601String(),
          orderTimestamp: DateTime.now().millisecondsSinceEpoch,
          address: widget.address,
          status: 'pending', // Trạng thái tiếng Anh
          paymentMethod: _selectedMethod,
          voucherCode: itemVoucherCode,
          discountAmount: itemDiscount,
        );
        await dbService.placeOrder(newOrder);
      }

      if (usedVoucherId != null) {
        await dbService.markVoucherAsUsed(usedVoucherId);
      }

      if (widget.services.length > 1) {
        await dbService.clearCart();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt lịch thành công!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi đặt lịch: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(widget.selectedDateTime);
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận & Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Địa chỉ & Thời gian
            _buildInfoCard(
              title: 'Địa chỉ & Thời gian',
              icon: Icons.location_on_outlined,
              children: [
                Text('Địa chỉ: ${widget.address}', style: const TextStyle(height: 1.5)),
                Text('Thời gian: $formattedDate'),
              ],
            ),
            const SizedBox(height: 16),

            // Thẻ Dịch vụ đã chọn
            _buildInfoCard(
              title: 'Dịch vụ đã chọn',
              icon: Icons.design_services_outlined,
              children: widget.services.map((service) => ListTile(
                title: Text(service.name),
                trailing: Text('${currencyFormatter.format(service.price)} VNĐ'),
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Thẻ Mã giảm giá
            _buildInfoCard(
              title: 'Mã giảm giá',
              icon: Icons.local_offer_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          errorText: _voucherStatusMessage != null && _appliedVoucher == null ? _voucherStatusMessage : null,
                          suffixIcon: TextButton(
                            child: const Text('Chọn mã'),
                            onPressed: _showVoucherSelectionSheet,
                          ),
                        ),
                        enabled: !_isLoading && _appliedVoucher == null,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      onPressed: _isCheckingVoucher || _isLoading || _appliedVoucher != null ? null : _validateAndApplyManualVoucher,
                      child: _isCheckingVoucher
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Áp dụng'),
                    ),
                  ],
                ),
                if (_appliedVoucher != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_appliedVoucher!.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Giảm ${_appliedVoucher!.discountPercentage}%'),
                      trailing: TextButton(
                        child: const Text('Gỡ', style: TextStyle(color: Colors.red)),
                        onPressed: _removeVoucher,
                      ),
                      tileColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 16),

            // Thẻ Phương thức thanh toán
            _buildInfoCard(
              title: 'Phương thức thanh toán',
              icon: Icons.payment_outlined,
              children: [
                 RadioListTile<String>(
                  title: const Text('Thanh toán khi nhận dịch vụ'),
                  value: 'cod',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value!),
                  activeColor: Colors.teal,
                ),
                RadioListTile<String>(
                  title: const Text('Chuyển khoản Ngân hàng'),
                  value: 'bank_transfer',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value!),
                  activeColor: Colors.teal,
                ),
                RadioListTile<String>(
                  title: const Text('Thẻ Tín dụng/Ghi nợ'),
                  subtitle: const Text('Sắp ra mắt', style: TextStyle(fontStyle: FontStyle.italic)),
                  value: 'card',
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value!),
                  activeColor: Colors.teal,
                ),
              ],
            ),
             const SizedBox(height: 16),
            // Thẻ Tổng kết giá
            _buildPriceSummary(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            onPressed: _isLoading ? null : _completeBooking,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                // Hiển thị giá cuối cùng trên nút
                : Text('Hoàn tất - ${currencyFormatter.format(_finalPrice)} VNĐ'),
          ),
        ),
      ),
    );
  }

  // Widget helper để tạo các thẻ thông tin
  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Widget helper cho phần tổng kết giá
   Widget _buildPriceSummary() {
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền dịch vụ:', style: TextStyle(color: Colors.grey)),
                Text('${currencyFormatter.format(_originalTotalPrice)} VNĐ'),
              ],
            ),
            if (_discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Giảm giá (${_appliedVoucher?.code ?? ''}):', style: const TextStyle(color: Colors.green)),
                  Text('- ${currencyFormatter.format(_discountAmount)} VNĐ', style: const TextStyle(color: Colors.green)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thành tiền:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '${currencyFormatter.format(_finalPrice)} VNĐ',
                  style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}