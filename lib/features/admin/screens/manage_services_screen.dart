import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/features/admin/widgets/service_form.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  _ManageServicesScreenState createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final DatabaseService dbService = DatabaseService();
  Map<String, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryNames();
  }

  // Tải tên của tất cả danh mục một lần để hiển thị, tránh gọi Firebase liên tục
  Future<void> _loadCategoryNames() async {
    final snapshot = await dbService.getCategoriesStream().first;
    if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map;
      final names = <String, String>{};
      data.forEach((key, value) {
        if (value is Map) {
          names[key] = value['name'] ?? 'Không tên';
        }
      });
      if (mounted) {
        setState(() {
          _categoryNames = names;
        });
      }
    }
  }

  void _showServiceForm([ServiceModel? service]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ServiceForm(service: service),
    );
  }

  void _showDeleteConfirmation(ServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa dịch vụ "${service.name}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
            onPressed: () {
              dbService.deleteService(service.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa dịch vụ thành công!')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Dịch vụ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "Chưa có dịch vụ nào.\nHãy nhấn nút '+' để thêm mới.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          final servicesMap = snapshot.data!.snapshot.value as Map;
          final services = servicesMap.entries.map((e) {
            return ServiceModel.fromMap(e.key, e.value as Map);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final categoryName = _categoryNames[service.categoryId] ?? 'Chưa phân loại';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần hình ảnh
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: service.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Phần thông tin
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(
                            label: Text(categoryName),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide.none,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${service.price.toStringAsFixed(0)} VNĐ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${service.estimatedDuration} phút',
                                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                           Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    // Phần nút hành động
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            label: const Text('Sửa', style: TextStyle(color: Colors.blue)),
                            onPressed: () => _showServiceForm(service),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            onPressed: () => _showDeleteConfirmation(service),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceForm(),
        label: const Text('Thêm Dịch vụ'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}