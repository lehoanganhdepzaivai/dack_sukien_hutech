import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/hutech_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
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

    try {
      if (SupabaseService.instance.isConfigured &&
          SupabaseService.instance.isInitialized) {
        await SupabaseService.instance.sendPasswordResetEmail(email);
        if (!mounted) return;
        setState(() {
          _successMessage =
              'Đã gửi liên kết khôi phục mật khẩu đến $email. Vui lòng kiểm tra hộp thư của bạn.';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _successMessage =
              'Yêu cầu khôi phục mật khẩu cho $email đã được ghi nhận. Vui lòng liên hệ ban quản trị để được hỗ trợ cấp lại mật khẩu.';
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
                        'Quên mật khẩu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập email của bạn để nhận liên kết đặt lại mật khẩu.',
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
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Về trang Đăng nhập'),
                              ),
                            ],
                          ),
                        ),
                      if (_successMessage == null) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ Email *',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty || !v.contains('@')
                                  ? 'Vui lòng nhập địa chỉ email hợp lệ'
                                  : null,
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
                              : const Text('Gửi yêu cầu khôi phục'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Quay lại đăng nhập'),
                        ),
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
