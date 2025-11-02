import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/features/user/widgets/service_list_item.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ yêu thích'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100], // Nền xám nhạt đồng bộ
      body: StreamBuilder<List<String>>(
        stream: dbService.getFavoriteServiceIdsStream(),
        builder: (context, snapshot) {
          // Trạng thái đang tải dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Trạng thái trống (chưa có dịch vụ yêu thích nào)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa yêu thích dịch vụ nào cả.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                   SizedBox(height: 8),
                   Text(
                    'Hãy nhấn ❤️ để thêm vào đây nhé!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              )
            );
          }
          
          final favoriteIds = snapshot.data!;
          
          // Hiển thị danh sách các dịch vụ yêu thích
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favoriteIds.length,
            itemBuilder: (context, index) {
              final serviceId = favoriteIds[index];
              // Dùng FutureBuilder để lấy chi tiết của từng dịch vụ
              return FutureBuilder<DataSnapshot>(
                future: FirebaseDatabase.instance.ref('services/$serviceId').get(),
                builder: (context, serviceSnapshot) {
                  // Trong khi chờ tải thông tin chi tiết của 1 item
                  if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(height: 106, child: const Center(child: CircularProgressIndicator())),
                    );
                  }

                  // Xử lý trường hợp dịch vụ đã bị xóa khỏi hệ thống
                  if (serviceSnapshot.data == null || serviceSnapshot.data!.value == null) {
                    return Card(
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.error_outline, color: Colors.red),
                        title: const Text('Dịch vụ này không còn tồn tại'),
                        trailing: IconButton(
                          tooltip: 'Gỡ khỏi danh sách',
                          icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                          onPressed: () {
                            dbService.toggleFavoriteStatus(serviceId);
                          },
                        ),
                      ),
                    );
                  }

                  // Nếu dữ liệu tồn tại, hiển thị bằng widget ServiceListItem đã được thiết kế lại
                  final serviceData = serviceSnapshot.data!.value as Map;
                  final service = ServiceModel.fromMap(serviceId, serviceData);
                  return ServiceListItem(service: service);
                },
              );
            },
          );
        },
      ),
    );
  }
}