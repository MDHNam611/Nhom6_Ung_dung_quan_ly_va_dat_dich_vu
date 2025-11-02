import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';

class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  _EditNameScreenState createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      final newName = _nameController.text.trim();
      if (user == null || user.displayName == newName) {
         if(mounted) setState(() => _isLoading = false);
         Navigator.pop(context); // Không có gì thay đổi, quay lại
         return;
      }

      try {
        await user.updateDisplayName(newName);
        await dbService.updateUserProfile(user.uid, {'name': newName});
        await user.reload(); // Tải lại thông tin user
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật tên thành công!')));
        Navigator.pop(context); // Quay lại trang trước
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật tên: $e')));
      } finally {
         if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật Tên')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị mới', border: OutlineInputBorder()),
                validator: (value) => value!.trim().isEmpty ? 'Tên không được để trống' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue,
                   minimumSize: const Size(double.infinity, 50),
                 ),
                onPressed: _isLoading ? null : _saveName,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}