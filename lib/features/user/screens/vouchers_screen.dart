import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/voucher_model.dart';
import 'package:flutter/services.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Voucher'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getUserVouchersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa có mã giảm giá nào.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                   SizedBox(height: 8),
                   Text(
                    'Hãy vào trang chủ để nhận mã nhé!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              )
            );
          }
          final vouchersMap = snapshot.data!.snapshot.value as Map;
          final vouchers = vouchersMap.entries.map((e) {
            return VoucherModel.fromMap(e.key, e.value);
          }).toList();

          // Lọc ra các mã chưa sử dụng và chưa hết hạn
          final validVouchers = vouchers.where((v) {
            final expiryDate = DateTime.fromMillisecondsSinceEpoch(v.expiryAt);
            return !v.isUsed && DateTime.now().isBefore(expiryDate);
          }).toList();

          if (validVouchers.isEmpty) {
             return const Center(
              child: Text(
                'Bạn không có mã giảm giá nào có thể sử dụng.',
                 style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Sắp xếp mã mới nhất lên đầu
          validVouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: validVouchers.length,
            itemBuilder: (context, index) {
              final voucher = validVouchers[index];
              final expiryDate = DateTime.fromMillisecondsSinceEpoch(voucher.expiryAt);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.blue, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giảm ${voucher.discountPercentage}%',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Mã: ${voucher.code}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                             Text(
                              'HSD: ${DateFormat('dd/MM/yyyy HH:mm').format(expiryDate)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: voucher.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Đã sao chép mã: ${voucher.code}'),
                                duration: const Duration(seconds: 1)),
                          );
                        },
                        child: const Text('Sao chép'),
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
}