import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';
import 'package:do_an_lap_trinh_android/models/service_model.dart';
import 'package:do_an_lap_trinh_android/models/category_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServiceForm extends StatefulWidget {
  final ServiceModel? service;
  const ServiceForm({super.key, this.service});

  @override
  _ServiceFormState createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _imageUrlController;
  String? _selectedCategoryId;
  
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(text: widget.service?.price.toString() ?? '');
    _durationController = TextEditingController(text: widget.service?.estimatedDuration.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.service?.imageUrl ?? '');
    _selectedCategoryId = widget.service?.categoryId;

    _imageUrlController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final newService = ServiceModel(
        id: widget.service?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        imageUrl: _imageUrlController.text.trim(),
        categoryId: _selectedCategoryId!,
        estimatedDuration: int.tryParse(_durationController.text) ?? 0,
      );

      try {
        await _databaseService.addOrUpdateService(newService);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu dịch vụ thành công!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.service == null ? 'Thêm Dịch vụ mới' : 'Cập nhật Dịch vụ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên dịch vụ', border: OutlineInputBorder()),
              validator: (value) => value!.trim().isEmpty ? 'Không được để trống' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
              maxLines: 3,
              validator: (value) => value!.trim().isEmpty ? 'Không được để trống' : null,
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Giá (VNĐ)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Giá không hợp lệ' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Phút', hintText: 'VD: 60', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || int.tryParse(value) == null) ? 'Lỗi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<DatabaseEvent>(
              stream: _databaseService.getCategoriesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = <CategoryModel>[];
                final data = snapshot.data!.snapshot.value as Map?;
                if (data != null) {
                  data.forEach((key, value) {
                    categories.add(CategoryModel.fromMap(key, value));
                  });
                }
                
                if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                    _selectedCategoryId = null;
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: const Text('Chọn mục'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  isExpanded: true,
                  items: categories.map((CategoryModel category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoryId = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'URL Hình ảnh', border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập URL ảnh' : null,
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imageUrlController.text.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _imageUrlController.text.trim(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Text('URL ảnh không hợp lệ')),
                    )
                  : const Center(child: Text('Xem trước ảnh')),
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Lưu lại'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}