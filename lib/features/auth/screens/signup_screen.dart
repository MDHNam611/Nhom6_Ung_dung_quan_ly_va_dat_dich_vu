import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_lap_trinh_android/core/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _signUp() async {
    // Kiểm tra xem widget có còn trên cây widget không trước khi thực hiện
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
        // AuthWrapper sẽ tự động điều hướng nếu đăng ký thành công.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công!')),
          );
        }

      } on FirebaseAuthException catch (e) {
        // IN RA MÃ LỖI CỤ THỂ ĐỂ DEBUG
        print('Firebase Auth Error Code: ${e.code}');

        String message = 'Đã có lỗi xảy ra.'; // Thông báo mặc định

        // THÊM CÁC TRƯỜNG HỢP LỖI KHÁC
        switch (e.code) {
          case 'weak-password':
            message = 'Mật khẩu quá yếu, vui lòng chọn mật khẩu khác.';
            break;
          case 'email-already-in-use':
            message = 'Email này đã được sử dụng cho một tài khoản khác.';
            break;
          case 'invalid-email':
            message = 'Địa chỉ email không hợp lệ.';
            break;
          case 'operation-not-allowed':
            message = 'Lỗi máy chủ, vui lòng thử lại sau.';
            break;
          default:
            // Hiển thị mã lỗi để dễ dàng xác định vấn đề
            message = 'Lỗi đăng ký: ${e.code}';
        }

        // Hiển thị thông báo lỗi cho người dùng
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
        
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Họ và Tên', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email không hợp lệ' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Mật khẩu phải có ít nhất 6 ký tự' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Xác nhận Mật khẩu', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text('Đăng ký'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}