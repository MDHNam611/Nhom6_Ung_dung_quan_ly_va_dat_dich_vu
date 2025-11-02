import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/category_model.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    // Form thêm/sửa danh mục
    void _showCategoryForm([CategoryModel? category]) {
      final nameController = TextEditingController(text: category?.name ?? '');
      final descController = TextEditingController(text: category?.description ?? '');
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(category == null ? 'Thêm Danh mục mới' : 'Cập nhật Danh mục'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên danh mục', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả ngắn', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Không được để trống' : null,
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
                  final newCategory = CategoryModel(
                    id: category?.id ?? '',
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                  );
                  dbService.addOrUpdateCategory(newCategory);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      );
    }
    
    // Dialog xác nhận xóa
    void _showDeleteConfirmation(CategoryModel category) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc muốn xóa danh mục "${category.name}" không?'),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                dbService.deleteCategory(category.id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }


    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbService.getCategoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Chưa có danh mục nào."));
          }
          final categoriesMap = snapshot.data!.snapshot.value as Map;
          final categories = categoriesMap.entries.map((e) {
            return CategoryModel.fromMap(e.key, e.value);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.category_outlined, color: Colors.blue.shade700),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa',
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showCategoryForm(category),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(),
        label: const Text('Thêm Danh mục'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}