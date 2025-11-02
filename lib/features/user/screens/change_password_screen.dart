import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      if (user == null || user.email == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy người dùng.')));
         if(mounted) setState(() => _isLoading = false);
         return;
      }

      try {
        // 1. Xác thực lại người dùng bằng mật khẩu cũ
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        // Dòng này sẽ ném ra FirebaseAuthException với code 'wrong-password' nếu sai
        await user.reauthenticateWithCredential(credential);
        // 2. Nếu xác thực thành công, cập nhật mật khẩu mới
        await user.updatePassword(newPassword);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
        Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
         String errorMessage = 'Đã có lỗi xảy ra.';
         if (e.code == 'wrong-password' || e.message?.contains('incorrect') == true) { // Thêm kiểm tra message dự phòng
           errorMessage = 'Mật khẩu hiện tại không đúng.';
         } else if (e.code == 'weak-password') {
           errorMessage = 'Mật khẩu mới quá yếu (cần ít nhất 6 ký tự).';
         } else {
           errorMessage = 'Lỗi: ${e.message ?? e.code}';
         }
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi không xác định: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                   suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                obscureText: _obscureCurrent,
                validator: (value) => (value == null || value.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.lock_person_outlined),
                   suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                obscureText: _obscureNew,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Không được để trống';
                  if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.lock_person_outlined),
                   suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.blue,
                   minimumSize: const Size(double.infinity, 50),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                 ),
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Xác nhận'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}