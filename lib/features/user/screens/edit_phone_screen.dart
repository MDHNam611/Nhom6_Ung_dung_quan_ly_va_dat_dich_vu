import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/database_service.dart';

class EditPhoneScreen extends StatefulWidget {
  final String? currentPhoneNumber;
  const EditPhoneScreen({super.key, this.currentPhoneNumber});

  @override
  _EditPhoneScreenState createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentPhoneNumber ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      final newPhone = _phoneController.text.trim();
      if (user == null || widget.currentPhoneNumber == newPhone) {
         if(mounted) setState(() => _isLoading = false);
         Navigator.pop(context); 
         return;
      }

      try {
        await dbService.updateUserProfile(user.uid, {'phoneNumber': newPhone});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật số điện thoại thành công!')));
        Navigator.pop(context, newPhone); // Trả về SĐT mới để cập nhật UI
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật SĐT: $e')));
      } finally {
         if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật Số điện thoại')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại mới', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                 validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Không được để trống';
                  if (!RegExp(r'^0[0-9]{9}$').hasMatch(value.trim())) {
                     return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue,
                   minimumSize: const Size(double.infinity, 50),
                 ),
                onPressed: _isLoading ? null : _savePhoneNumber,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}