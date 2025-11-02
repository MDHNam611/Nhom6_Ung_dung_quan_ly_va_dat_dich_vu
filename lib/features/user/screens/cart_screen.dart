import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/features/user/screens/cart_booking_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<List<String>>(
        stream: dbService.getCartServiceIdsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Giỏ hàng của bạn đang trống.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              )
            );
          }
          final cartIds = snapshot.data!;
          
          return FutureBuilder<List<ServiceModel>>(
            future: Future.wait(cartIds.map((id) async {
              final serviceSnapshot = await FirebaseDatabase.instance.ref('services/$id').get();
              if (serviceSnapshot.exists) {
                return ServiceModel.fromMap(id, serviceSnapshot.value as Map);
              }
              // Trả về một service giả để xử lý trường hợp service đã bị xóa
              return ServiceModel(id: id, name: 'Dịch vụ đã bị xóa', description: '', price: 0, categoryId: '', imageUrl: '', estimatedDuration: 0);
            })),
            builder: (context, servicesSnapshot) {
              if (servicesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!servicesSnapshot.hasData) {
                return const Center(child: Text('Không thể tải giỏ hàng.'));
              }

              final cartServices = servicesSnapshot.data!;
              final validServices = cartServices.where((s) => s.price > 0).toList(); // Lọc ra các dịch vụ hợp lệ
              final totalPrice = validServices.fold(0.0, (sum, item) => sum + item.price);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: cartServices.length,
                      itemBuilder: (context, index) {
                        final service = cartServices[index];
                        // Nếu dịch vụ không còn tồn tại
                        if (service.price == 0) {
                          return Card(
                            color: Colors.grey.shade200,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.error_outline, color: Colors.red),
                              title: Text(service.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                                onPressed: () => dbService.removeFromCart(service.id),
                              ),
                            ),
                          );
                        }
                        // Hiển thị dịch vụ bình thường
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: service.imageUrl,
                                width: 50, height: 50, fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(service.name),
                            subtitle: Text('${service.price.toStringAsFixed(0)} VNĐ'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => dbService.removeFromCart(service.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Phần tổng kết và đặt lịch
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '${totalPrice.toStringAsFixed(0)} VNĐ',
                              style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: validServices.isEmpty ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CartBookingScreen(
                                services: validServices,
                                totalPrice: totalPrice,
                              )),
                            );
                          },
                          child: const Text('Tiến hành Đặt lịch'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}