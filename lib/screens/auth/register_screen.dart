import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/app_store.dart';
import '../../services/supabase_service.dart';
import '../../widgets/hutech_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();

    try {
      if (SupabaseService.instance.isConfigured &&
          SupabaseService.instance.isInitialized) {
        await SupabaseService.instance.signUp(
          email: email,
          password: password,
          fullName: fullName,
        );
        if (!mounted) return;
        setState(() {
          _successMessage =
              'Đăng ký thành công! Vui lòng kiểm tra hộp thư email để kích hoạt tài khoản.';
        });
      } else {
        // Chế độ phát triển cục bộ
        final store = context.read<AppStore>();
        await store.registerLocalStudent(
          name: fullName,
          email: email,
          studentId: studentId,
          password: password,
        );
        if (!mounted) return;
        setState(() {
          _successMessage = 'Tạo tài khoản thành công! Bạn có thể đăng nhập ngay.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: HutechLogoMark(size: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đăng ký tài khoản',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cổng Sự kiện & Hoạt động Sinh viên HUTECH',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Đến trang Đăng nhập'),
                              ),
                            ],
                          ),
                        ),
                      if (_successMessage == null) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập họ và tên'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _studentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Mã số sinh viên (MSSV) *',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập MSSV'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            hintText: 'vidu@hutech.edu.vn',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Định dạng email chưa hợp lệ';
                            }
                            if (SupabaseConfig.enforceHutechDomain &&
                                !SupabaseConfig.isValidHutechEmail(v)) {
                              return 'Vui lòng nhập email có đuôi @hutech.edu.vn';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mật khẩu tối thiểu 6 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            labelText: 'Xác nhận mật khẩu *',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Đăng ký tài khoản'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản?',
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Đăng nhập'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
