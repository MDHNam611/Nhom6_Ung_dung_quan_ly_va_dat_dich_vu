import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Để tạo mã ngẫu nhiên
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/voucher_model.dart';

class ManageVouchersScreen extends StatelessWidget {
  const ManageVouchersScreen({super.key});

  // Hàm tạo mã ngẫu nhiên (ví dụ: SALE10-ABCXYZ)
  String _generateVoucherCode(int percentage) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final codeSuffix = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return 'GIAM$percentage-$codeSuffix';
  }

  // Hiển thị form thêm/sửa mã
  void _showVoucherForm(BuildContext context, DatabaseService dbService, [VoucherModel? voucher]) {
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final percentageController = TextEditingController(text: voucher?.discountPercentage.toString() ?? '10'); // Mặc định 10%
    final formKey = GlobalKey<FormState>();

    // Nếu là tạo mới, tự động tạo mã
    if (voucher == null) {
      codeController.text = _generateVoucherCode(int.tryParse(percentageController.text) ?? 10);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(voucher == null ? 'Tạo Mã Giảm Giá Mới' : 'Cập nhật Mã Giảm Giá'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã Code', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: percentageController,
                decoration: const InputDecoration(labelText: 'Phần trăm giảm (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final percent = int.tryParse(value ?? '');
                  if (percent == null || percent <= 0 || percent > 100) {
                    return 'Nhập số từ 1-100';
                  }
                  return null;
                },
                // Tự động cập nhật mã code nếu phần trăm thay đổi (khi tạo mới)
                onChanged: (value) {
                  if (voucher == null) {
                     codeController.text = _generateVoucherCode(int.tryParse(value) ?? 10);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Lưu'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final now = DateTime.now();
                final expiry = now.add(const Duration(days: 3));
                final newVoucher = VoucherModel(
                  id: voucher?.id ?? '', // Giữ ID cũ nếu là sửa
                  code: codeController.text.trim(),
                  discountPercentage: int.parse(percentageController.text),
                  createdAt: voucher?.createdAt ?? now.millisecondsSinceEpoch, // Giữ ngày tạo cũ nếu sửa
                  expiryAt: voucher?.expiryAt ?? expiry.millisecondsSinceEpoch, // Giữ hạn cũ nếu sửa
                  ownerId: voucher?.ownerId, // Không thay đổi chủ sở hữu khi sửa
                  isUsed: voucher?.isUsed ?? false, // Không thay đổi trạng thái sử dụng khi sửa
                );
                dbService.addOrUpdateVoucher(newVoucher);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  // Dialog xác nhận xóa
  void _showDeleteConfirmation(BuildContext context, DatabaseService dbService, VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc muốn xóa mã "${voucher.code}" không? Mã này sẽ không thể sử dụng được nữa.'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
            onPressed: () {
              dbService.deleteVoucher(voucher.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Mã Giảm Giá'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getAllVouchersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Chưa có mã giảm giá nào."));
          }
          final vouchersMap = snapshot.data!.snapshot.value as Map;
          final vouchers = vouchersMap.entries.map((e) {
            return VoucherModel.fromMap(e.key, e.value);
          }).toList();
          // Sắp xếp mã mới nhất lên đầu
          vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              final expiryDate = DateTime.fromMillisecondsSinceEpoch(voucher.expiryAt);
              final isExpired = DateTime.now().isAfter(expiryDate);
              final statusText = voucher.isUsed
                  ? 'Đã sử dụng'
                  : isExpired
                      ? 'Đã hết hạn'
                      : voucher.ownerId != null
                          ? 'Đã có chủ'
                          : 'Có thể sử dụng';
              final statusColor = voucher.isUsed || isExpired ? Colors.red : (voucher.ownerId != null ? Colors.orange : Colors.green);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                            voucher.code,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          Chip(
                            label: Text(
                              statusText,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text('Giảm giá: ${voucher.discountPercentage}%'),
                      Text('Hạn sử dụng: ${DateFormat('dd/MM/yyyy HH:mm').format(expiryDate)}'),
                      if (voucher.ownerId != null) Text('Người sở hữu: ${voucher.ownerId}'), // Có thể thay bằng tên user sau này
                      const SizedBox(height: 8),
                      // Nút Sửa/Xóa chỉ hiển thị cho mã chưa sử dụng và chưa hết hạn
                      if (!voucher.isUsed && !isExpired)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                              label: const Text('Sửa', style: TextStyle(color: Colors.blue)),
                              onPressed: () => _showVoucherForm(context, dbService, voucher),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              onPressed: () => _showDeleteConfirmation(context, dbService, voucher),
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherForm(context, dbService),
        label: const Text('Tạo mã mới'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}