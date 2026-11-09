import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/hutech_logo.dart';

class LoginScreen extends StatefulWidget {
  final String? returnTo;
  const LoginScreen({super.key, this.returnTo});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true, _remember = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final email = prefs.getString('login_email');
    if (email != null) {
      setState(() {
        _email.text = email;
        _remember = true;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final store = context.read<AppStore>();
    try {
      await store.login(_email.text.trim(), _password.text);
      final prefs = await SharedPreferences.getInstance();
      if (_remember) {
        await prefs.setString('login_email', _email.text.trim());
      } else {
        await prefs.remove('login_email');
      }
      if (!mounted) return;
      final target = _roleSafeReturnTarget(widget.returnTo, store.isAdmin);
      context.go(target ?? (store.isAdmin ? '/admin' : '/'));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _roleSafeReturnTarget(String? target, bool isAdmin) {
    if (target == null ||
        !target.startsWith('/') ||
        target.startsWith('//') ||
        target.startsWith('/login')) {
      return null;
    }
    final uri = Uri.tryParse(target);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final path = uri.path;
    final adminRoute = path == '/admin' || path.startsWith('/admin/');
    final studentRoute =
        const {
          '/profile',
          '/schedule',
          '/development',
          '/my-events',
          '/favorites',
          '/calendar',
        }.contains(path) ||
        path.startsWith('/ticket/');
    if (isAdmin && (path == '/' || studentRoute)) return '/admin';
    if (!isAdmin && adminRoute) return '/';
    return target;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 950;
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const EventImage('assets/images/community.png'),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x14022A52), Color(0xED053B68)],
                              stops: [.25, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 35,
                          left: 35,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.blue,
                                  size: 17,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'HUTECH EVENT INTELLIGENCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 44,
                          right: 40,
                          bottom: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tuổi trẻ là những\ntrải nghiệm đáng nhớ.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(height: 22),
                              Text(
                                'Kết nối cộng đồng. Khám phá tiềm năng.\nViết tiếp hành trình sinh viên theo cách của bạn.',
                                style: TextStyle(
                                  color: Color(0xFFD2E8F7),
                                  fontSize: 16,
                                  height: 1.8,
                                ),
                              ),
                              SizedBox(height: 30),
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: AppColors.yellow,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'KHÁM PHÁ  /  KẾT NỐI  /  TRƯỞNG THÀNH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      letterSpacing: 1.7,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 10,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 45 : 25,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 410),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HutechLogoMark(size: 112),
                          const SizedBox(height: 28),
                          const Text(
                            'Chào mừng bạn trở lại!',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                            ),
                          ),
                          const SizedBox(height: 11),
                          const Text(
                            'Đăng nhập để khám phá những sự kiện phù hợp\nvà tiếp tục hành trình của bạn.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Địa chỉ email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Nhập email của bạn',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                              ),
                            ),
                            validator: (v) =>
                                v == null ||
                                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v.trim())
                                ? 'Vui lòng nhập email hợp lệ'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Mật khẩu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _busy ? null : _submit(),
                            decoration: InputDecoration(
                              hintText: 'Nhập mật khẩu',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Vui lòng nhập mật khẩu'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 25,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (v) =>
                                      setState(() => _remember = v!),
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Expanded(
                                child: Text(
                                  'Ghi nhớ email',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: const Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Đăng nhập'),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 23),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Chưa có tài khoản?',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: const Text(
                                    'Tạo tài khoản',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(
                                Icons.explore_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Khám phá sự kiện trước',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 38),
                          const Center(
                            child: Text(
                              'Kết nối trải nghiệm. Kiến tạo tương lai.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountInfoScreen extends StatelessWidget {
  final bool recovery;
  const AccountInfoScreen({super.key, this.recovery = false});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: EmptyPanel(
            icon: recovery
                ? Icons.mark_email_unread_outlined
                : Icons.person_add_alt_1_outlined,
            title: recovery ? 'Khôi phục tài khoản' : 'Tạo tài khoản sinh viên',
            message: recovery
                ? 'Dịch vụ gửi email khôi phục chưa được kết nối. Bạn có thể quay lại đăng nhập bằng tài khoản đã được cấp.'
                : 'Đăng ký tài khoản mới sẽ được mở sau khi hệ thống xác thực Supabase được cấu hình. Hiện bạn có thể khám phá sự kiện hoặc đăng nhập bằng tài khoản đã được cấp.',
            action: FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Về trang đăng nhập'),
            ),
          ),
        ),
      ),
    ),
  );
}
